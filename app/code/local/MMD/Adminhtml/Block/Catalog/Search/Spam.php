<?php
/**
 * Search-Spam cleanup preview block. Renders bucket cards with live
 * row counts + sample query_texts pulled from catalogsearch_query.
 *
 * All counts respect the same store-filter session key used by the
 * Search Terms grid (MMD_Adminhtml_Block_Catalog_Search::SESSION_KEY).
 */
class MMD_Adminhtml_Block_Catalog_Search_Spam extends Mage_Adminhtml_Block_Template
{
    public const SAMPLE_LIMIT = 8;

    public function __construct()
    {
        parent::__construct();
        $this->setTemplate('mmd/catalog_search/spam.phtml');
    }

    /** @return MMD_Adminhtml_Helper_SearchSpam */
    public function getSpamHelper()
    {
        return Mage::helper('mmd/searchSpam');
    }

    /** @return int */
    public function getActiveStoreFilter()
    {
        return (int) Mage::getSingleton('adminhtml/session')
            ->getData(MMD_Adminhtml_Block_Catalog_Search::SESSION_KEY);
    }

    /**
     * @return array<int, array{id:int,label:string}>
     */
    public function getStoreTabs()
    {
        $tabs = array(array('id' => 0, 'label' => 'All Branches'));
        foreach (Mage::app()->getStores() as $store) {
            $label = preg_replace('/\s*Store View\s*$/i', '', $store->getName());
            $tabs[] = array('id' => (int) $store->getId(), 'label' => $label);
        }
        return $tabs;
    }

    public function getStoreTabUrl($storeId)
    {
        return $this->getUrl('*/catalog_search_spam/index', array(
            MMD_Adminhtml_Block_Catalog_Search::REQUEST_PARAM => (int) $storeId,
        ));
    }

    public function getBackUrl()
    {
        return $this->getUrl('adminhtml/catalog_search/index');
    }

    public function getDeleteUrl()
    {
        return $this->getUrl('*/catalog_search_spam/delete');
    }

    /**
     * Capture store filter from the request (mirrors the Search Terms grid).
     */
    protected function _beforeToHtml()
    {
        $req = Mage::app()->getRequest();
        $param = MMD_Adminhtml_Block_Catalog_Search::REQUEST_PARAM;
        if ($req->getParam($param, null) !== null) {
            Mage::getSingleton('adminhtml/session')->setData(
                MMD_Adminhtml_Block_Catalog_Search::SESSION_KEY,
                (int) $req->getParam($param)
            );
        }
        return parent::_beforeToHtml();
    }

    /**
     * Row count + sample query_texts for one bucket.
     *
     * @return array{count:int, samples:array<int,array{query_text:string,num_results:int,popularity:int}>}
     */
    public function getBucketStats($bucket)
    {
        $resource = Mage::getSingleton('core/resource');
        $db       = $resource->getConnection('core_read');
        $table    = $resource->getTableName('catalogsearch/search_query');

        $where = '(' . $bucket['where'] . ') AND ' . $this->getSpamHelper()->curatedGuard();
        $storeId = $this->getActiveStoreFilter();
        if ($storeId > 0) {
            $where .= ' AND store_id = ' . (int) $storeId;
        }

        $count = (int) $db->fetchOne(
            "SELECT COUNT(*) FROM $table WHERE $where"
        );

        $samples = $db->fetchAll(
            "SELECT query_text, num_results, popularity FROM $table "
            . "WHERE $where ORDER BY popularity DESC LIMIT " . self::SAMPLE_LIMIT
        );

        return array('count' => $count, 'samples' => $samples ?: array());
    }

    /** Total rows currently in catalogsearch_query (respecting store filter). */
    public function getTotalRows()
    {
        $resource = Mage::getSingleton('core/resource');
        $db       = $resource->getConnection('core_read');
        $table    = $resource->getTableName('catalogsearch/search_query');
        $where = '1=1';
        $storeId = $this->getActiveStoreFilter();
        if ($storeId > 0) {
            $where = 'store_id = ' . (int) $storeId;
        }
        return (int) $db->fetchOne("SELECT COUNT(*) FROM $table WHERE $where");
    }
}
