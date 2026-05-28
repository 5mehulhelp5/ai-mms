<?php
/**
 * Search-Spam cleanup preview block. Renders bucket cards with live
 * row counts + sample query_texts pulled from catalogsearch_query.
 *
 * Store scope follows the universal Store View bar's ?store=N — same
 * mechanism as every other admin grid (see backend-design skill,
 * "Filtering contract").
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

    /** @return int Active store id from the universal Store View bar (0 = all). */
    public function getActiveStoreFilter()
    {
        return (int) Mage::app()->getRequest()->getParam('store', 0);
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
