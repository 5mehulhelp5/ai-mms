<?php
/**
 * Invoices grid — adds a Branch column and filters by the active
 * Branchscope store on every render.
 */
class MMD_Enhancedsalesgrid_Block_Sales_Invoice_Grid extends Mage_Adminhtml_Block_Sales_Invoice_Grid
{
    protected function _prepareCollection()
    {
        parent::_prepareCollection();
        $collection = $this->getCollection();
        if (!$collection) {
            return $this;
        }
        $storeId = (int) Mage::helper('branchscope')->getActiveStoreId();
        if ($storeId > 0) {
            $collection->getSelect()->where('main_table.store_id = ?', $storeId);
        }
        return $this;
    }

    protected function _prepareColumns()
    {
        parent::_prepareColumns();

        // Build branch options from real stores (store_id => name).
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
            'filter_index' => 'main_table.store_id',
        ), 'billing_name');

        return $this;
    }
}
