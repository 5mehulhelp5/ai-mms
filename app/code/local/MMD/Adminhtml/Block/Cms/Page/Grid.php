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
            // Strict per-country filter — operators clicking the Malaysia
            // pill expect Malaysia-assigned pages only, not "All Store Views"
            // mixed in. Stock addStoreFilter would join store_id IN(0, N);
            // override the SQL to exact-match the selected store.
            $select = $this->getCollection()->getSelect();
            $table  = Mage::getSingleton('core/resource')->getTableName('cms/page_store');
            $select->join(
                array('mmd_cps' => $table),
                'mmd_cps.page_id = main_table.page_id',
                array()
            )->where('mmd_cps.store_id = ?', $storeId)
             ->group('main_table.page_id');
        }
        return $this;
    }
}
