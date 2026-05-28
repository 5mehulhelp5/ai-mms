<?php
/**
 * Leads container — renders via custom template that mirrors the
 * Edit Course page chrome: fixed left sidebar (.dcf-edit-sidebar)
 * + .dcf-wrap with header action bar + filter pill banner +
 * the grid block. Standard Grid_Container output is bypassed.
 */
class MMD_Leads_Block_Adminhtml_Leads extends Mage_Adminhtml_Block_Template
{
    public function __construct()
    {
        parent::__construct();
        $this->setTemplate('mmd_leads/index.phtml');
    }

    public function getGridHtml()
    {
        return $this->getLayout()->createBlock('mmd_leads/adminhtml_leads_grid')->toHtml();
    }

    /**
     * Sidebar items. Each entry is [key, label, count]. The active
     * key comes from ?filter_status; the grid honors the same param.
     */
    public function getSidebarItems()
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $table    = $resource->getTableName('mmd_leads/lead');

        $counts = array(
            'all'              => (int) $read->fetchOne("SELECT COUNT(*) FROM {$table}"),
            'new'              => (int) $read->fetchOne(
                "SELECT COUNT(*) FROM {$table} WHERE status = ?",
                MMD_Leads_Model_Lead::STATUS_NEW
            ),
            'replied'          => (int) $read->fetchOne(
                "SELECT COUNT(*) FROM {$table} WHERE status = ?",
                MMD_Leads_Model_Lead::STATUS_REPLIED
            ),
            'auto_reply_failed' => (int) $read->fetchOne(
                "SELECT COUNT(*) FROM {$table} WHERE auto_reply_status = ?",
                MMD_Leads_Model_Lead::AUTO_REPLY_FAILED
            ),
        );

        return array(
            array('key' => 'all',               'label' => 'All Leads',         'count' => $counts['all']),
            array('key' => 'new',               'label' => 'New',               'count' => $counts['new']),
            array('key' => 'replied',           'label' => 'Replied',           'count' => $counts['replied']),
            array('key' => 'auto_reply_failed', 'label' => 'Auto-Reply Failed', 'count' => $counts['auto_reply_failed']),
        );
    }

    public function getActiveFilter()
    {
        $f = (string) $this->getRequest()->getParam('filter_status', 'all');
        return $f !== '' ? $f : 'all';
    }

    public function getFilterUrl($key)
    {
        $params = ($key === 'all') ? array() : array('filter_status' => $key);
        return $this->getUrl('*/*/index', $params);
    }

    public function getBackUrl()
    {
        return $this->getUrl('adminhtml/dashboard');
    }
}
