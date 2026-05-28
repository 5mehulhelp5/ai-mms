<?php
/**
 * MMD_Auditfix_Model_Fixer
 *
 * Per-row Fix dispatcher invoked from the admin Issues page (Fix icon).
 * Reads an issue row, picks a handler based on (category, title pattern),
 * applies the DB-only change, marks the issue fixed, and returns a one-line
 * summary for the admin flash message.
 *
 * Adding a new fixer = add a case to dispatch(). Never put fixers here
 * that touch code/templates/layout XML — those go through PR review per
 * the user's "DB-only auto-fix" scope decision.
 */
class MMD_Auditfix_Model_Fixer
{
    /**
     * @return array{ok:bool,summary:string}
     */
    public function fix(array $issue)
    {
        $category = (string)($issue['category'] ?? '');
        $title    = (string)($issue['title']    ?? '');
        $type     = (string)($issue['entity_type'] ?? '');
        $id       = (int)   ($issue['entity_id']   ?? 0);

        try {
            // --- SEO -------------------------------------------------------
            // Per the seo-audit skill: product `name`, `meta_title`, and
            // `meta_description` are sacred. NO auto-fix here. Operators
            // edit them by hand in Catalog → Edit Course → SEO. SEO issues
            // are surfaced for awareness only; the Fix button is hidden.

            // --- Security --------------------------------------------------
            if ($category === 'security' && $type === 'admin_user' && $id > 0
                && stripos($title, 'username') !== false) {
                return $this->fixAdminUsername($id);
            }
        } catch (Exception $e) {
            Mage::logException($e);
            return array('ok' => false, 'summary' => 'Fix failed: ' . $e->getMessage());
        }

        return array('ok' => false, 'summary' => 'No fix handler for this issue type.');
    }

    private function fixAdminUsername($userId)
    {
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $tbl   = Mage::getSingleton('core/resource')->getTableName('admin/user');
        $row = $write->fetchRow("SELECT user_id, email, username FROM {$tbl} WHERE user_id = ?", $userId);
        if (!$row)            return array('ok' => false, 'summary' => 'User not found.');
        if (!$row['email'])   return array('ok' => false, 'summary' => 'User has no email; cannot derive username.');
        if ($row['username'] === $row['email']) return array('ok' => true, 'summary' => 'Already fixed.');

        $write->update($tbl, array('username' => $row['email']), $write->quoteInto('user_id = ?', (int)$userId));
        return array('ok' => true, 'summary' => "username ← {$row['email']}");
    }

    /** Whether a given issue row has a registered fix handler. */
    public function canFix(array $issue)
    {
        $cat   = (string)($issue['category'] ?? '');
        $title = (string)($issue['title']    ?? '');
        $type  = (string)($issue['entity_type'] ?? '');
        // SEO findings are intentionally NOT fixable from this UI — course
        // name and meta fields are sacred (see seo-audit skill).
        if ($cat === 'security' && $type === 'admin_user' && stripos($title, 'username') !== false) {
            return true;
        }
        return false;
    }
}
