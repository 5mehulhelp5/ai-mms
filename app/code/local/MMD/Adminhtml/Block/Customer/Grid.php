<?php
/**
 * Customer grid — wire ?store=N from the global Store View bar to the
 * customer collection so each country pill narrows the rows.
 *
 * See backend-design skill "Filtering contract (MANDATORY)".
 */
class MMD_Adminhtml_Block_Customer_Grid extends Mage_Adminhtml_Block_Customer_Grid
{
    protected function _beforeLoadCollection()
    {
        parent::_beforeLoadCollection();
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        if ($storeId > 0 && $this->getCollection()) {
            $this->getCollection()->addFieldToFilter('store_id', $storeId);
        }
        return $this;
    }
}
