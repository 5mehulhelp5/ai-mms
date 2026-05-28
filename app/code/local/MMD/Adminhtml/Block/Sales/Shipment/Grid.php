<?php
/**
 * Sales Shipments grid — wire ?store=N filter. The collection backs
 * sales_flat_shipment_grid which carries store_id on main_table.
 */
class MMD_Adminhtml_Block_Sales_Shipment_Grid extends Mage_Adminhtml_Block_Sales_Shipment_Grid
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
