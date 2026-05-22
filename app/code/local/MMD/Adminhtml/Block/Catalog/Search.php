<?php
/**
 * Catalog Search container override — adds a store/branch tab strip
 * above the grid so admins can filter the search-terms list by branch.
 * Active branch is persisted per admin session, so paging/sorting
 * preserves the selection.
 */
class MMD_Adminhtml_Block_Catalog_Search
    extends Mage_Adminhtml_Block_Catalog_Search
{
    public const SESSION_KEY = 'mmd_search_store_filter';
    public const REQUEST_PARAM = 'mmd_search_store';

    public function __construct()
    {
        parent::__construct();
        $this->setTemplate('mmd/catalog_search/container.phtml');
    }

    public function getStoreTabs()
    {
        $tabs = array(array('id' => 0, 'label' => Mage::helper('adminhtml')->__('All Branches')));
        foreach (Mage::app()->getStores() as $store) {
            $label = preg_replace('/\s*Store View\s*$/i', '', $store->getName());
            $tabs[] = array('id' => (int) $store->getId(), 'label' => $label);
        }
        return $tabs;
    }

    public function getActiveStoreFilter()
    {
        return (int) Mage::getSingleton('adminhtml/session')->getData(self::SESSION_KEY);
    }

    public function getStoreTabUrl($storeId)
    {
        return $this->getUrl('*/catalog_search/index', array(self::REQUEST_PARAM => (int) $storeId));
    }
}
