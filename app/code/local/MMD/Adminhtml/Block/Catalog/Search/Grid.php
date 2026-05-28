<?php
/**
 * Compact override of the Search Terms grid. Replaces the stock multi-line
 * Store column (website / group / store-view stacked) with a single-line
 * Branch column ("Singapore", "Malaysia", ...) so each search term renders
 * on one row. Filters by the global Store View bar's ?store=N (universal
 * pattern — see backend-design skill, "Filtering contract").
 */
class MMD_Adminhtml_Block_Catalog_Search_Grid
    extends Mage_Adminhtml_Block_Catalog_Search_Grid
{
    protected function _prepareCollection()
    {
        $collection = Mage::getModel('catalogsearch/query')->getResourceCollection();
        $this->setCollection($collection);
        return Mage_Adminhtml_Block_Widget_Grid::_prepareCollection();
    }

    protected function _beforeLoadCollection()
    {
        parent::_beforeLoadCollection();
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        if ($storeId > 0 && $this->getCollection()) {
            $this->getCollection()->addStoreFilter($storeId);
        }
        return $this;
    }

    protected function _prepareColumns()
    {
        parent::_prepareColumns();

        if ($this->getColumn('store_id')) {
            $this->removeColumn('store_id');
        }

        if (!Mage::app()->isSingleStoreMode()) {
            $this->addColumnAfter('store_id', array(
                'header'   => Mage::helper('catalog')->__('Branch'),
                'index'    => 'store_id',
                'renderer' => 'MMD_Adminhtml_Block_Widget_Grid_Column_Renderer_Branch',
                'sortable' => false,
            ), 'search_query');
        }

        return $this;
    }
}
