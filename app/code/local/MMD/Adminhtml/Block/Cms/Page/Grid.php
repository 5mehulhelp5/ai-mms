<?php
/**
 * CMS Pages grid — wire ?store=N from the global Store View bar.
 *
 * Stock has an in-grid Store View column dropdown filter; the global
 * pill bar's URL param needs its own hook.
 */
class MMD_Adminhtml_Block_Cms_Page_Grid extends Mage_Adminhtml_Block_Cms_Page_Grid
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
