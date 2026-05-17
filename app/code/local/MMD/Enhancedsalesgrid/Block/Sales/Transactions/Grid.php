<?php
/**
 * Transactions grid — adds a Branch column (via joined store_id from
 * sales_flat_order) and filters by the active Branchscope store.
 */
class MMD_Enhancedsalesgrid_Block_Sales_Transactions_Grid extends Mage_Adminhtml_Block_Sales_Transactions_Grid
{
    protected function _prepareCollection()
    {
        parent::_prepareCollection();
        $collection = $this->getCollection();
        if (!$collection) {
            return $this;
        }

        // Native transactions collection doesn't include store_id. Pull
        // it from sales_flat_order via the addOrderInformation hook which
        // already joins the order table for the increment_id column.
        if (method_exists($collection, 'addOrderInformation')) {
            $collection->addOrderInformation(array('store_id'));
        }

        $storeId = (int) Mage::helper('branchscope')->getActiveStoreId();
        if ($storeId > 0) {
            $collection->getSelect()->where('order.store_id = ?', $storeId);
        }
        return $this;
    }

    protected function _prepareColumns()
    {
        parent::_prepareColumns();

        $branchOptions = array();
        foreach (Mage::getModel('core/store')->getCollection() as $_s) {
            if ((int) $_s->getId() === 0) { continue; }
            $branchOptions[(int) $_s->getId()] =
                preg_replace('/\s*Store View\s*$/i', '', $_s->getName());
        }

        $this->addColumnAfter('store_id', array(
            'header'       => Mage::helper('sales')->__('Branch'),
            'index'        => 'store_id',
            'type'         => 'options',
            'width'        => '110px',
            'options'      => $branchOptions,
            'filter_index' => 'order.store_id',
        ), 'increment_id');

        return $this;
    }
}
