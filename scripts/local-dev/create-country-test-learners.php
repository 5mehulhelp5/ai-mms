<?php
/**
 * Local-dev fixture — creates one dummy learner per country so each
 * country admin can test the Enroll Learner search/add flow without
 * touching real customer data.
 *
 *   SG → Aileen Chong       (learner.sg@example.com)
 *   MY → Ahmad bin Abdullah (learner.my@example.com)
 *   GH → Kwame Asante       (learner.gh@example.com)
 *   NG → Adebayo Okonkwo    (learner.ng@example.com)
 *   BT → Tashi Wangmo       (learner.bt@example.com)
 *   IN → Priya Sharma       (learner.in@example.com)
 *
 * Each gets a minimal sales_flat_order row on its country's store,
 * with state="complete" so the searchLearners / loadLearners controller
 * actions pick them up. Increment IDs are prefixed DUMMY-LEARNER-<CC>
 * so they're easy to identify and clean up later.
 *
 * Idempotent — re-running skips accounts that already exist.
 *
 * Usage:
 *     docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/create-country-test-learners.php
 *
 * Never run on production — these accounts are throwaway and the
 * scripts/local-dev/ directory is excluded from the deploy migrations.
 */

$cfg = simplexml_load_file(__DIR__ . '/../../app/etc/local.xml');
$db  = $cfg->global->resources->default_setup->connection;
$pdo = new PDO(
    "mysql:host={$db->host};dbname={$db->dbname};charset=utf8",
    (string) $db->username,
    (string) $db->password,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$learners = [
    // Pre-named sample learners per country.
    ['SG', 1, 'learner.sg@example.com', 'Aileen',  'Chong',     '+65',  '98765432'],
    ['MY', 2, 'learner.my@example.com', 'Ahmad',   'Abdullah',  '+60',  '123456789'],
    ['GH', 3, 'learner.gh@example.com', 'Kwame',   'Asante',    '+233', '244123456'],
    ['NG', 4, 'learner.ng@example.com', 'Adebayo', 'Okonkwo',   '+234', '8012345678'],
    ['BT', 5, 'learner.bt@example.com', 'Tashi',   'Wangmo',    '+975', '17123456'],
    ['IN', 6, 'learner.in@example.com', 'Priya',   'Sharma',    '+91',  '9876543210'],
    // Country admin themselves, so they can self-enrol via the Enroll
    // Learner search and then switch View As: Learner to see the class.
    ['SG-SELF', 1, 'admin.sg@example.com', 'Singapore', 'Admin', '+65',  '98765432'],
    ['MY-SELF', 2, 'admin.my@example.com', 'Malaysia',  'Admin', '+60',  '123456789'],
    ['GH-SELF', 3, 'admin.gh@example.com', 'Ghana',     'Admin', '+233', '244123456'],
    ['NG-SELF', 4, 'admin.ng@example.com', 'Nigeria',   'Admin', '+234', '8012345678'],
    ['BT-SELF', 5, 'admin.bt@example.com', 'Bhutan',    'Admin', '+975', '17123456'],
    ['IN-SELF', 6, 'admin.in@example.com', 'India',     'Admin', '+91',  '9876543210'],
];

echo "=== Country test learner seed ===\n";

foreach ($learners as [$cc, $storeId, $email, $first, $last, $cCode, $phone]) {
    $incrementId = 'DUMMY-LEARNER-' . $cc;

    $stmt = $pdo->prepare("SELECT entity_id FROM sales_flat_order WHERE increment_id = ?");
    $stmt->execute([$incrementId]);
    if ($stmt->fetchColumn()) {
        echo "[$cc] EXISTS  $email (increment_id=$incrementId)\n";
        continue;
    }

    // Minimal sales_flat_order row — enough for search/load to find this
    // learner. state='complete' is required for loadLearnersAction's
    // (state IN 'complete','processing') filter.
    $pdo->prepare(
        "INSERT INTO sales_flat_order
            (state, status, store_id, customer_email, customer_firstname, customer_lastname,
             increment_id, created_at, updated_at,
             grand_total, base_grand_total, total_paid, base_total_paid,
             store_currency_code, base_currency_code, order_currency_code,
             customer_is_guest, is_virtual)
         VALUES
            ('complete', 'complete', ?, ?, ?, ?, ?, NOW(), NOW(),
             0.00, 0.00, 0.00, 0.00,
             'USD', 'USD', 'USD',
             1, 0)"
    )->execute([$storeId, $email, $first, $last, $incrementId]);

    echo "[$cc] CREATED $email  ($first $last)  store_id=$storeId\n";
}

echo "\nThese learners will appear in the Enroll Learner search dropdown for the\n";
echo "matching country admin (admin.<cc>@example.com).\n";
echo "\nTo wipe and re-seed, delete rows with:\n";
echo "  DELETE FROM sales_flat_order WHERE increment_id LIKE 'DUMMY-LEARNER-%';\n";
