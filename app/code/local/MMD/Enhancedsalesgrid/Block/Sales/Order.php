<?php
class MMD_Enhancedsalesgrid_Block_Sales_Order extends Mage_Adminhtml_Block_Sales_Order
{
    public function __construct()
    {
        parent::__construct();

        $this->_blockGroup = 'enhancedsalesgrid';
        $this->_headerText = Mage::helper('sales')->__('Registrations');
        $this->_addButtonLabel = Mage::helper('sales')->__('Create New Registration');
    }
}
