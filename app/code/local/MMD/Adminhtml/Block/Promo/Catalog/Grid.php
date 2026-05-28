<?php
/**
 * Catalog Price Rules grid — wire ?store=N. Promo rules are
 * website-scoped, not store-scoped, so map store id → website id then
 * filter on website membership via catalogrule_website join.
 */
class MMD_Adminhtml_Block_Promo_Catalog_Grid extends Mage_Adminhtml_Block_Promo_Catalog_Grid
{
    protected function _beforeLoadCollection()
    {
        parent::_beforeLoadCollection();
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        if ($storeId > 0 && $this->getCollection()) {
            try {
                $websiteId = (int) Mage::app()->getStore($storeId)->getWebsiteId();
                if ($websiteId > 0) {
                    $select = $this->getCollection()->getSelect();
                    $conn   = $this->getCollection()->getConnection();
                    $table  = Mage::getSingleton('core/resource')->getTableName('catalogrule/website');
                    $select->join(
                        array('mmd_crw' => $table),
                        'mmd_crw.rule_id = main_table.rule_id',
                        array()
                    )->where('mmd_crw.website_id = ?', $websiteId)
                     ->group('main_table.rule_id');
                }
            } catch (Exception $e) {
                Mage::logException($e);
            }
        }
        return $this;
    }
}
