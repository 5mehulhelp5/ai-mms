<?php
class MMD_Leads_Block_Adminhtml_Leads extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_leads';
        $this->_blockGroup = 'mmd_leads';
        $this->_headerText = Mage::helper('mmd_leads')->__('Leads');
        parent::__construct();
        // No "Add Lead" button — leads come from the storefront only.
        $this->_removeButton('add');
    }
}
