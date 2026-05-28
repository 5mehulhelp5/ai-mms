<?php
/**
 * Shopping Cart Price Rules (sales rules) grid — wire ?store=N.
 * Sales rules are website-scoped, so map store id → website id and
 * filter via salesrule_website membership.
 */
class MMD_Adminhtml_Block_Promo_Quote_Grid extends Mage_Adminhtml_Block_Promo_Quote_Grid
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
                    $table  = Mage::getSingleton('core/resource')->getTableName('salesrule/website');
                    $select->join(
                        array('mmd_srw' => $table),
                        'mmd_srw.rule_id = main_table.rule_id',
                        array()
                    )->where('mmd_srw.website_id = ?', $websiteId)
                     ->group('main_table.rule_id');
                }
            } catch (Exception $e) {
                Mage::logException($e);
            }
        }
        return $this;
    }
}
