<?php
/**
 * Renders grid action cells as side-by-side links instead of the default
 * single-select dropdown.
 */
class MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Actionlinks
    extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Action
{
    public function render(Varien_Object $row)
    {
        $actions = $this->getColumn()->getActions();
        if (empty($actions) || !is_array($actions)) {
            return '&nbsp;';
        }

        $links = array();
        foreach ($actions as $action) {
            if (is_array($action)) {
                $links[] = $this->_toLinkHtml($action, $row);
            }
        }
        return implode(' | ', $links);
    }
}
