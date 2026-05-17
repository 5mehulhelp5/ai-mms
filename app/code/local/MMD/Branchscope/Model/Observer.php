<?php
/**
 * Two hooks:
 *   - admin_user_authenticate_after: seed the admin session with the
 *     default branch (Singapore) on every fresh login.
 *   - controller_action_predispatch (adminhtml): persist any ?store=N
 *     URL param to the admin session so the choice follows the user
 *     across navigation.
 */
class MMD_Branchscope_Model_Observer
{
    /**
     * Seed Singapore on login. Role-aware override (admin.my@... → MY) is
     * layered on top in Phase 3 by reading MMD_RoleManager_Helper_Data.
     */
    public function onAdminLogin(Varien_Event_Observer $observer)
    {
        $session = Mage::getSingleton('admin/session');
        if (!$session) {
            return;
        }
        $existing = $session->getData(MMD_Branchscope_Helper_Data::SESSION_KEY);
        if ($existing !== null && ctype_digit((string) $existing)) {
            return; // already seeded earlier this session
        }

        $defaultId = MMD_Branchscope_Helper_Data::DEFAULT_STORE_ID;

        // Role-aware default: if the admin email encodes a country (admin.my@,
        // admin.gh@, …) prefer that store. Falls back to Singapore.
        try {
            /** @var MMD_RoleManager_Helper_Data $roleHelper */
            $roleHelper = Mage::helper('mmd_rolemanager');
            if ($roleHelper && method_exists($roleHelper, 'getActiveWebsiteId')) {
                $websiteId = (int) $roleHelper->getActiveWebsiteId();
                if ($websiteId > 0) {
                    $defaultId = $websiteId;
                }
            }
        } catch (Exception $e) {
            // Leave defaultId as Singapore.
        }

        $session->setData(MMD_Branchscope_Helper_Data::SESSION_KEY, $defaultId);
    }

    /**
     * Persist URL ?store= into the admin session on every adminhtml request.
     */
    public function onPredispatch(Varien_Event_Observer $observer)
    {
        Mage::helper('branchscope')->persistFromRequest();
    }
}
