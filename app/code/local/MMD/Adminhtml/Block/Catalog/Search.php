<?php
/**
 * Catalog Search container override — adds a "Clean Spam" page-level
 * button alongside "Add New Search Term". Country filtering is handled
 * by the global Store View bar (?store=N), so this block no longer
 * renders its own per-branch tab strip. See backend-design skill,
 * "Store View bar (canonical)".
 */
class MMD_Adminhtml_Block_Catalog_Search
    extends Mage_Adminhtml_Block_Catalog_Search
{
    public function __construct()
    {
        parent::__construct();
        $this->setTemplate('mmd/catalog_search/container.phtml');

        // Register "Clean Spam" alongside "Add New Search Term" so it
        // renders through Mage_Adminhtml_Block_Widget_Container's button
        // pipeline — same markup, padding, hover state.
        $this->_addButton('clean_spam', array(
            'label'   => Mage::helper('catalog')->__('Clean Spam'),
            'onclick' => "setLocation('" . $this->getUrl('mmd/catalog_search_spam/index') . "')",
            'class'   => '',
        ), 0, 5);
    }
}
