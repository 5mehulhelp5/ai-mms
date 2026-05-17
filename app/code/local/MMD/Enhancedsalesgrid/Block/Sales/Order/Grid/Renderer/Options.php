<?php 
class MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Options extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
{ 
    /**
    * Render product details
    *
    * @param   Varien_Object $row
    * @return  string
    */
    public function render(Varien_Object $row)
    {
        $raw = $row->getProduct_options();
        $arr = is_string($raw) && $raw !== '' ? @unserialize($raw) : false;

        if (is_array($arr) && !empty($arr['options']) && is_array($arr['options'])) {
            $dates = array();
            foreach ($arr['options'] as $opt) {
                $label = isset($opt['label']) ? (string) $opt['label'] : '';
                if (stripos($label, 'date') !== false) {
                    $dates[] = $this->escapeHtml($opt['value']);
                }
            }
            if (!empty($dates)) {
                return implode('<br/>', $dates);
            }
        }
        return '------';
    }
}