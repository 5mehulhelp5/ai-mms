<?php
/**
 * Truncates the message column to a short preview so each lead stays
 * one compact row. Full message is visible on the View page.
 */
class MMD_Leads_Block_Adminhtml_Leads_Grid_Renderer_Truncate
    extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
{
    const MAX_CHARS = 80;

    public function render(Varien_Object $row)
    {
        $val = trim((string) $row->getData($this->getColumn()->getIndex()));
        if ($val === '') {
            return '';
        }
        $val = preg_replace('/\s+/', ' ', $val);
        $escaped = $this->escapeHtml($val);
        if (mb_strlen($val) > self::MAX_CHARS) {
            $shortRaw = mb_substr($val, 0, self::MAX_CHARS) . '…';
            return '<span title="' . $escaped . '">' . $this->escapeHtml($shortRaw) . '</span>';
        }
        return $escaped;
    }
}
