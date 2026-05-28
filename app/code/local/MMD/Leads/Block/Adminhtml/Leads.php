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

    /**
     * Wrap the standard content-header + grid pair in a single card so
     * "Leads" reads as the container title of the table beneath it
     * rather than a free-floating page header above an unrelated panel.
     */
    protected function _toHtml()
    {
        return '<div class="mmd-leads-card">' . parent::_toHtml() . '</div>';
    }
}
