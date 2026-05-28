<?php
/**
 * CMS Static Blocks grid — wire ?store=N from the global Store View bar.
 */
class MMD_Adminhtml_Block_Cms_Block_Grid extends Mage_Adminhtml_Block_Cms_Block_Grid
{
    protected function _beforeLoadCollection()
    {
        parent::_beforeLoadCollection();
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        if ($storeId > 0 && $this->getCollection()) {
            $this->getCollection()->addStoreFilter($storeId);
        }
        return $this;
    }
}
