<?php
/**
 * Keeps storefront customer accounts and dashboard admin_user accounts unified.
 * Thin event handlers — all logic lives in the helper. Bodies are wrapped so a
 * sync hiccup can never break a customer save or an admin save.
 */
class MMD_AccountSync_Model_Observer
{
    /** customer_save_after: ensure dashboard account + storefront->dashboard password sync. */
    public function onCustomerSaveAfter(Varien_Event_Observer $observer)
    {
        try {
            $customer = $observer->getEvent()->getCustomer();
            if ($customer instanceof Mage_Customer_Model_Customer) {
                Mage::helper('mmd_accountsync')->onCustomerSaved($customer);
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /** admin_user_save_after: dashboard->storefront password sync. */
    public function onAdminUserSaveAfter(Varien_Event_Observer $observer)
    {
        try {
            $user = $observer->getEvent()->getObject();
            if ($user instanceof Mage_Admin_Model_User) {
                Mage::helper('mmd_accountsync')->onAdminUserSaved($user);
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }
}
