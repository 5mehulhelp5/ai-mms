<?php
/**
 * Global icon-button renderer for the admin grid Actions column.
 *
 * Replaces the stock dropdown / text-link output of
 * Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Action with side-by-side
 * rounded-square icon buttons for the common View / Edit / Delete actions.
 * Anything whose caption we don't recognise falls back to a plain text
 * link in the same row, so unfamiliar grids still work.
 *
 * Styling lives in skin/adminhtml/default/default/dark-theme.css under the
 * .mmd-grid-actions / .mmd-grid-action[--view|--edit|--delete] classes.
 */
class MMD_Adminhtml_Block_Widget_Grid_Column_Renderer_Action
    extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Action
{
    /** @var array<string,string> */
    protected $_icons = array(
        'view'   => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>',
        'edit'   => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>',
        'delete' => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-2 14a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/></svg>',
    );

    public function render(Varien_Object $row)
    {
        $actions = $this->getColumn()->getActions();
        if (empty($actions) || !is_array($actions)) {
            return '&nbsp;';
        }

        $parts = array();
        foreach ($actions as $action) {
            if (!is_array($action)) {
                continue;
            }
            $a       = $action;
            $caption = '';
            $this->_transformActionData($a, $caption, $row);
            $key = $this->_iconKey($caption);

            if (isset($a['confirm'])) {
                $a['onclick'] = 'return window.confirm(\''
                              . addslashes($this->escapeHtml($a['confirm'])) . '\')';
                unset($a['confirm']);
            }
            $a['title'] = $caption;
            $cls = isset($a['class']) ? trim($a['class']) : '';
            $cls = trim($cls . ' mmd-grid-action' . ($key ? ' mmd-grid-action--' . $key : ''));
            $a['class'] = $cls;

            $attrs   = new Varien_Object();
            $attrs->setData($a);
            $inner   = $key ? $this->_icons[$key] : $caption;
            $parts[] = '<a ' . $attrs->serialize() . '>' . $inner . '</a>';
        }

        if (!$parts) {
            return '&nbsp;';
        }
        return '<div class="mmd-grid-actions">' . implode('', $parts) . '</div>';
    }

    /**
     * Map an action caption to one of our known icon keys, or null when
     * the caption doesn't match any of them.
     */
    protected function _iconKey($caption)
    {
        $c = strtolower(trim(strip_tags((string) $caption)));
        if ($c === '') {
            return null;
        }
        if (strpos($c, 'view') !== false || strpos($c, 'show') !== false) {
            return 'view';
        }
        if (strpos($c, 'edit') !== false) {
            return 'edit';
        }
        if (strpos($c, 'delete') !== false || strpos($c, 'remove') !== false) {
            return 'delete';
        }
        return null;
    }
}
