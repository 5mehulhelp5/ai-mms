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
            // Strict per-country filter — see Cms_Page_Grid for rationale.
            $select = $this->getCollection()->getSelect();
            $table  = Mage::getSingleton('core/resource')->getTableName('cms/block_store');
            $select->join(
                array('mmd_cbs' => $table),
                'mmd_cbs.block_id = main_table.block_id',
                array()
            )->where('mmd_cbs.store_id = ?', $storeId)
             ->group('main_table.block_id');
        }
        return $this;
    }
}
