<?php
/**
 * Tax Rate column — derives the effective rate from the row's
 * tax_amount / subtotal. The grid collection has tax_amount (the
 * column index) and base subtotal available; we compute a rounded
 * percentage for display, e.g. "9%". Falls back to "—" when subtotal
 * is zero/missing (e.g. fully-funded $0 orders).
 *
 * This class was referenced by Grid.php's tax_rate column since
 * fa54ea44 but the file was never committed, so createBlock() returned
 * false and the whole Registrations grid fataled
 * ("setColumn() on bool" in Widget/Grid/Column.php). Adding the
 * missing renderer restores the grid.
 */
class MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Taxrate
    extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
{
    public function render(Varien_Object $row)
    {
        $tax = (float) $row->getData('tax_amount');
        if ($tax <= 0) {
            $tax = (float) $row->getData('base_tax_amount');
        }

        $subtotal = (float) $row->getData('subtotal');
        if ($subtotal <= 0) {
            $subtotal = (float) $row->getData('base_subtotal');
        }

        if ($subtotal <= 0 || $tax <= 0) {
            return '<span style="color:#94a3b8;">&mdash;</span>';
        }

        $rate = ($tax / $subtotal) * 100;
        // Round to a whole percent (SG GST is a flat rate); keep one
        // decimal only if it isn't effectively an integer.
        $rounded = round($rate);
        if (abs($rate - $rounded) < 0.05) {
            return (int) $rounded . '%';
        }
        return number_format($rate, 1) . '%';
    }
}
