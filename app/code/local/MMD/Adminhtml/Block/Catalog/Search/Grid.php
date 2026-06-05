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

        // Free-text search via ?q= — driven by the custom search input
        // injected into .dcf-mag-bar (see catalog_search block in
        // sidebar-nav-v2.js). Matches against query_text, synonym_for
        // and redirect so a single search reaches every column the user
        // can scan visually. Wildcards both ends so partial matches
        // ("photo" hits "photoshop") work.
        $q = trim((string) $this->getRequest()->getParam('q', ''));
        if ($q !== '' && $this->getCollection()) {
            $like = '%' . $q . '%';
            // OpenMage / Magento 1 OR-filter syntax: parallel arrays —
            // first arg is the list of column names, second arg is the
            // matching list of condition specs. Generates
            // `WHERE (query_text LIKE ? OR synonym_for LIKE ? OR redirect LIKE ?)`.
            $this->getCollection()->addFieldToFilter(
                array('query_text', 'synonym_for', 'redirect'),
                array(
                    array('like' => $like),
                    array('like' => $like),
                    array('like' => $like),
                )
            );
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
