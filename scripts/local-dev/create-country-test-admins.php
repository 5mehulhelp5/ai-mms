<?php
/**
 * Local-dev fixture — creates 6 country-scoped admin accounts for
 * simulating the LMS from each market's perspective.
 *
 *   admin.sg@example.com  → Singapore
 *   admin.my@example.com  → Malaysia
 *   admin.gh@example.com  → Ghana
 *   admin.ng@example.com  → Nigeria
 *   admin.bt@example.com  → Bhutan
 *   admin.in@example.com  → India
 *
 * Password for all six: admin123 (matches the other dev test accounts).
 *
 * Idempotent — re-runnable. Existing accounts are left alone; missing
 * ones get created. Each account is granted every role (admin /
 * trainer / learner / marketing / developer / training_provider) with
 * "admin" as primary so the role-switcher works out of the box.
 *
 * Usage (host):
 *     docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/create-country-test-admins.php
 *
 * Never run on production — these are throwaway test accounts and
 * scripts/local-dev/ is excluded from the deploy migration runner.
 */

$cfg = simplexml_load_file(__DIR__ . '/../../app/etc/local.xml');
$db  = $cfg->global->resources->default_setup->connection;
$pdo = new PDO(
    "mysql:host={$db->host};dbname={$db->dbname};charset=utf8",
    (string) $db->username,
    (string) $db->password,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$pwd  = 'admin123';
$salt = 'NW';
$hash = hash('sha256', $salt . $pwd) . ':' . $salt;

$accounts = [
    ['SG', 'admin.sg@example.com', 'Singapore Admin'],
    ['MY', 'admin.my@example.com', 'Malaysia Admin'],
    ['GH', 'admin.gh@example.com', 'Ghana Admin'],
    ['NG', 'admin.ng@example.com', 'Nigeria Admin'],
    ['BT', 'admin.bt@example.com', 'Bhutan Admin'],
    ['IN', 'admin.in@example.com', 'India Admin'],
];

$roles = ['admin', 'trainer', 'learner', 'marketing', 'developer', 'training_provider'];

echo "=== Country test admin seed ===\n";

foreach ($accounts as [$cc, $email, $fullName]) {
    [$first, $last] = explode(' ', $fullName, 2);

    $existing = (int) $pdo->prepare(
        "SELECT user_id FROM admin_user WHERE email = ? OR username = ? LIMIT 1"
    )->execute([$email, $email]) ? null : null;

    $stmt = $pdo->prepare("SELECT user_id FROM admin_user WHERE email = ? OR username = ? LIMIT 1");
    $stmt->execute([$email, $email]);
    $userId = (int) ($stmt->fetchColumn() ?: 0);

    if ($userId) {
        echo "[$cc] EXISTS  user_id=$userId  $email\n";
    } else {
        $pdo->prepare(
            "INSERT INTO admin_user
                (firstname, lastname, email, username, password, created, modified, logdate, lognum, reload_acl_flag, is_active, extra)
             VALUES (?, ?, ?, ?, ?, NOW(), NOW(), NULL, 0, 0, 1, NULL)"
        )->execute([$first, $last, $email, $email, $hash]);
        $userId = (int) $pdo->lastInsertId();
        echo "[$cc] CREATED user_id=$userId  $email  password=$pwd\n";
    }

    // Wire all six roles, with admin marked primary. INSERT IGNORE
    // skips existing role rows so re-runs are no-ops.
    foreach ($roles as $role) {
        $isPrimary = ($role === 'admin') ? 1 : 0;
        $pdo->prepare(
            "INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
             VALUES (?, ?, ?, NOW())"
        )->execute([$userId, $role, $isPrimary]);
    }

    // Link the user into Magento's admin_role tree so the admin login
    // bouncer (hasAssigned2Role) is happy. parent_id=1 = Administrators
    // (full access), matching the catch-all group existing real admins
    // already use.
    $stmt = $pdo->prepare("SELECT role_id FROM admin_role WHERE user_id = ? AND role_type = 'U' LIMIT 1");
    $stmt->execute([$userId]);
    if (!$stmt->fetchColumn()) {
        $pdo->prepare(
            "INSERT INTO admin_role (parent_id, tree_level, sort_order, role_type, user_id, role_name)
             VALUES (1, 2, 0, 'U', ?, ?)"
        )->execute([$userId, $fullName]);
    }
}

// LOCAL-DEV ONLY: matching trainer options so each country admin can be
// picked as the trainer in Create New Class and see the class on their
// own View As: Trainer view (the trainer-match logic uses full-name).
// These are testing-only values — never seed them on production.
$attrId = (int) $pdo->query("SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainers' AND entity_type_id=4")->fetchColumn();
if ($attrId) {
    foreach ($accounts as [, , $fullName]) {
        $stmt = $pdo->prepare(
            "SELECT v.option_id FROM eav_attribute_option_value v
              JOIN eav_attribute_option o ON o.option_id=v.option_id
              WHERE o.attribute_id=? AND v.store_id=0 AND v.value=? LIMIT 1"
        );
        $stmt->execute([$attrId, $fullName]);
        if ($stmt->fetchColumn()) continue;
        $pdo->prepare("INSERT INTO eav_attribute_option (attribute_id, sort_order) VALUES (?, 0)")->execute([$attrId]);
        $oid = (int) $pdo->lastInsertId();
        $pdo->prepare("INSERT INTO eav_attribute_option_value (option_id, store_id, value) VALUES (?, 0, ?)")->execute([$oid, $fullName]);
        echo "trainer option created: $fullName → option_id=$oid\n";
    }
}

echo "\nLogin via the admin panel:\n";
echo "  http://localhost:8080/tigerdragon/\n";
echo "  password for all six accounts: $pwd\n";
