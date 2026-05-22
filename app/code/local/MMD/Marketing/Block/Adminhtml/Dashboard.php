<?php
/**
 * Thin block — its only job is to point at the dashboard template.
 * All data + markup lives in the .phtml (matches the master admin
 * dashboard pattern this page was extracted from).
 */
class MMD_Marketing_Block_Adminhtml_Dashboard extends Mage_Adminhtml_Block_Template
{
    public function __construct()
    {
        parent::__construct();
        $this->setTemplate('mmd_marketing/dashboard.phtml');
    }
}
