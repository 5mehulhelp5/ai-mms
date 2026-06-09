<?php
/**
 * One-shot backfill: give every existing storefront customer (learner) a
 * matching INACTIVE dashboard admin_user with the 'learner' role, copying their
 * (EAV) password hash. Reuses the verified MMD_AccountSync helper, so behavior
 * is identical to the live observer. SILENT — no emails (raw inserts).
 *
 * Idempotent: skips customers whose email already has an admin_user (so it also
 * naturally dedupes multi-website customers sharing one email). Resumable via
 * core_config_data['mmd/account_sync/backfill_last_id'].
 *
 * Usage (inside the web container):
 *   php scripts/maintenance/backfill-learner-dashboard-accounts.php --dry
 *       -> no writes; prints scope (total emails, how many would be created)
 *   php scripts/maintenance/backfill-learner-dashboard-accounts.php --limit=50
 *       -> process only the next 50 customers (real, resumable)
 *   php scripts/maintenance/backfill-learner-dashboard-accounts.php
 *       -> process all remaining (batched, resumable)
 *   php scripts/maintenance/backfill-learner-dashboard-accounts.php --reset
 *       -> clear the resume pointer (start from the beginning)
 */

require_once dirname(__FILE__) . '/../../app/Mage.php';
Mage::app();

$CONFIG_PATH = 'mmd/account_sync/backfill_last_id';
$BATCH = 1000;

$args     = $argv;
$dry      = in_array('--dry', $args, true);
$reset    = in_array('--reset', $args, true);
$activate = in_array('--activate', $args, true);
$limit    = 0;
foreach ($args as $a) {
    if (strpos($a, '--limit=') === 0) { $limit = (int) substr($a, 8); }
}

$res   = Mage::getSingleton('core/resource');
$read  = $res->getConnection('core_read');
$auTbl = $res->getTableName('admin_user');
$ceTbl = $res->getTableName('customer/entity');

if ($reset) {
    Mage::getConfig()->saveConfig($CONFIG_PATH, '0', 'default', 0);
    Mage::getConfig()->reinit();
    echo "resume pointer reset to 0 (run again without --reset to backfill)\n";
    exit(0); // reset is a standalone action — never fall through into processing
}

// --activate: flip existing pure-learner shadow accounts to is_active=1.
// Run this ONLY after the learner-role ACL lockdown is deployed (it lets those
// accounts log into the dashboard, where the lockdown confines them). Standalone.
if ($activate) {
    $write = $res->getConnection('core_write');
    $map   = $res->getTableName('mmd_user_role_map');
    $arTbl = $res->getTableName('admin/role');
    $n = $write->query(
        "UPDATE `$auTbl` au
            SET au.is_active = 1
          WHERE au.is_active = 0
            AND EXISTS     (SELECT 1 FROM `$map` r  WHERE r.user_id = au.user_id AND r.role_code = 'learner')
            AND NOT EXISTS (SELECT 1 FROM `$map` r2 WHERE r2.user_id = au.user_id AND r2.role_code <> 'learner')"
    )->rowCount();
    echo "activated $n pure-learner shadow account(s)\n";

    // Assign the 'Learner' Magento ACL group to any pure-learner shadow missing
    // an admin_role 'U' row — without it Mage_Admin_Model_User::authenticate()
    // throws "Access denied". (CLI => applyRoleAcl skips the session-ACL reload.)
    $ids = $read->fetchCol(
        "SELECT au.user_id FROM `$auTbl` au
          WHERE EXISTS     (SELECT 1 FROM `$map` r  WHERE r.user_id = au.user_id AND r.role_code = 'learner')
            AND NOT EXISTS (SELECT 1 FROM `$map` r2 WHERE r2.user_id = au.user_id AND r2.role_code <> 'learner')
            AND NOT EXISTS (SELECT 1 FROM `$arTbl` ar WHERE ar.user_id = au.user_id AND ar.role_type = 'U')"
    );
    $h = Mage::helper('mmd_rolemanager');
    $applied = 0;
    foreach ($ids as $uid) {
        try { $h->applyRoleAcl((int) $uid, 'learner'); $applied++; } catch (Exception $e) {}
    }
    echo "assigned Learner ACL to $applied account(s)\n";
    exit(0);
}

// ---- DRY: report scope, write nothing ----
if ($dry) {
    $totalCustomers = (int) $read->fetchOne("SELECT COUNT(*) FROM `$ceTbl`");
    $distinctEmails = (int) $read->fetchOne("SELECT COUNT(DISTINCT LOWER(email)) FROM `$ceTbl`");
    $wouldCreate = (int) $read->fetchOne(
        "SELECT COUNT(*) FROM (
            SELECT LOWER(ce.email) e
              FROM `$ceTbl` ce
              LEFT JOIN `$auTbl` au ON LOWER(au.email) = LOWER(ce.email)
             WHERE au.user_id IS NULL AND ce.email IS NOT NULL AND ce.email <> ''
             GROUP BY LOWER(ce.email)
         ) x"
    );
    echo "DRY RUN — no changes made.\n";
    echo "customer_entity rows : $totalCustomers\n";
    echo "distinct emails      : $distinctEmails\n";
    echo "admin_user to CREATE : $wouldCreate (distinct emails with no dashboard account yet)\n";
    echo "already linked       : " . ($distinctEmails - $wouldCreate) . "\n";
    exit(0);
}

// ---- REAL: process in batches, resumable ----
$lastId    = (int) Mage::getStoreConfig($CONFIG_PATH);
$processed = 0; $created = 0; $linked = 0; $errors = 0;
$helper    = Mage::helper('mmd_accountsync');

echo "starting backfill from entity_id > $lastId" . ($limit ? " (limit $limit)" : '') . "\n";

do {
    $collection = Mage::getModel('customer/customer')->getCollection()
        ->addAttributeToSelect(array('firstname', 'lastname', 'password_hash'))
        ->addFieldToFilter('entity_id', array('gt' => $lastId))
        ->setOrder('entity_id', 'ASC')
        ->setPageSize($BATCH)->setCurPage(1);

    $items = $collection->getItems();
    if (!$items) { break; }

    foreach ($items as $cust) {
        $email = strtolower(trim((string) $cust->getEmail()));
        $existed = $email !== '' && (int) $read->fetchOne(
            "SELECT user_id FROM `$auTbl` WHERE LOWER(email) = ? LIMIT 1", array($email)
        ) > 0;
        try {
            $helper->onCustomerSaved($cust);
            if ($existed) { $linked++; } else { $created++; }
        } catch (Exception $e) {
            $errors++;
            Mage::log('backfill error for ' . $email . ': ' . $e->getMessage(), Zend_Log::ERR, 'accountsync.log');
        }
        $lastId = (int) $cust->getId();
        $processed++;
        if ($limit && $processed >= $limit) { break; }
    }

    Mage::getConfig()->saveConfig($CONFIG_PATH, (string) $lastId, 'default', 0);
    Mage::getConfig()->reinit();
    echo "  ...processed=$processed created=$created linked=$linked errors=$errors (lastId=$lastId)\n";

    if ($limit && $processed >= $limit) { break; }
} while (count($items) === $BATCH);

echo "DONE. processed=$processed created=$created linked=$linked errors=$errors lastId=$lastId\n";
