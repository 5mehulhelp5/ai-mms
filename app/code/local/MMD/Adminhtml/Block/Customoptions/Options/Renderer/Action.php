<?php
/**
 * Inline Edit + Delete icon actions for the Course Manager grid.
 * Replaces the default <select> dropdown (whose JS was broken in this
 * theme) with two clickable icon links per row.
 */
class MMD_Adminhtml_Block_Customoptions_Options_Renderer_Action
    extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
{
    public function render(Varien_Object $row)
    {
        $id = $row->getGroupId();
        $storeId = (int) $this->getColumn()->getStoreId();

        $editUrl = $this->getUrl('*/*/edit', array(
            'group_id' => $id,
            'store'    => $storeId,
        ));
        $deleteUrl = $this->getUrl('*/*/delete', array(
            'group_id' => $id,
            'store'    => $storeId,
        ));

        $editIcon = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
        $deleteIcon = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-2 14a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/></svg>';

        $confirm = Mage::helper('customoptions')->__('Delete this options template?');

        return sprintf(
            '<div class="mmd-grid-actions">'
                . '<a href="%s" class="mmd-grid-action mmd-grid-action--edit" title="%s">%s</a>'
                . '<a href="%s" class="mmd-grid-action mmd-grid-action--delete" title="%s" '
                . 'onclick="return confirm(\'%s\');">%s</a>'
            . '</div>',
            $editUrl,
            Mage::helper('customoptions')->__('Edit'),
            $editIcon,
            $deleteUrl,
            Mage::helper('customoptions')->__('Delete'),
            addslashes($confirm),
            $deleteIcon
        );
    }
}
