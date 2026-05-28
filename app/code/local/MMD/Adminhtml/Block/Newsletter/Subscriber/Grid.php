<?php
/**
 * Newsletter Subscribers grid — wire ?store=N filter.
 *
 * The collection's addFieldFilter accepts subscriber.store_id directly.
 */
class MMD_Adminhtml_Block_Newsletter_Subscriber_Grid extends Mage_Adminhtml_Block_Newsletter_Subscriber_Grid
{
    protected function _beforeLoadCollection()
    {
        parent::_beforeLoadCollection();
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        if ($storeId > 0 && $this->getCollection()) {
            $this->getCollection()->addFieldToFilter('main_table.store_id', $storeId);
        }
        return $this;
    }
}
