<?php
/**
 * Thin block — runs the audit and exposes the result to its template.
 * The audit work lives in mmd_seoaudit/data so the block stays presentation-only.
 */
class MMD_Seoaudit_Block_Adminhtml_Audit extends Mage_Adminhtml_Block_Template
{
    /** @var array|null */
    protected $_result;

    public function __construct()
    {
        parent::__construct();
        $this->setTemplate('mmd_seoaudit/audit.phtml');
    }

    public function getResult()
    {
        if ($this->_result === null) {
            $storeId = (int) Mage::app()->getRequest()->getParam('store', 1);
            if ($storeId <= 0) { $storeId = 1; }
            $this->_result = Mage::helper('mmd_seoaudit')->run($storeId);
        }
        return $this->_result;
    }
}
