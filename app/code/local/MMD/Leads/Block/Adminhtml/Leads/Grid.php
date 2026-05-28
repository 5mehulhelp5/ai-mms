<?php
/**
 * Minimalist one-row-per-lead grid. Columns:
 *   Date | Name | Email | Tel | Course Interested | Store | Message (≤80c) | Status
 * Plus an Action column (View → opens the reply form).
 */
class MMD_Leads_Block_Adminhtml_Leads_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct()
    {
        parent::__construct();
        $this->setId('mmdLeadsGrid');
        $this->setDefaultSort('created_at');
        $this->setDefaultDir('DESC');
        $this->setSaveParametersInSession(true);
        $this->setUseAjax(true);
    }

    protected function _prepareCollection()
    {
        $collection = Mage::getModel('mmd_leads/lead')->getCollection();

        // Scope rows to the country pill picked in the global Store View bar
        // (.dcf-store-switcher → ?store=N). 0 = All; >0 = single country.
        // Without this the pills change the URL but the grid keeps showing
        // every lead, contradicting the "Viewing: <Country>" notice band.
        try {
            $activeStoreId = (int) Mage::helper('branchscope')->getActiveStoreId();
            if ($activeStoreId > 0) {
                $collection->addFieldToFilter('store_id', $activeStoreId);
            }
        } catch (Exception $e) { /* helper unavailable — show unfiltered */ }

        // Sidebar filter (new / replied / auto_reply_failed) — keys match
        // MMD_Leads_Block_Adminhtml_Leads::getSidebarItems().
        $filter = (string) $this->getRequest()->getParam('filter_status', '');
        if ($filter === 'new') {
            $collection->addFieldToFilter('status', MMD_Leads_Model_Lead::STATUS_NEW);
        } elseif ($filter === 'replied') {
            $collection->addFieldToFilter('status', MMD_Leads_Model_Lead::STATUS_REPLIED);
        } elseif ($filter === 'auto_reply_failed') {
            $collection->addFieldToFilter('auto_reply_status', MMD_Leads_Model_Lead::AUTO_REPLY_FAILED);
        }

        $this->setCollection($collection);
        return parent::_prepareCollection();
    }

    protected function _prepareColumns()
    {
        $helper = Mage::helper('mmd_leads');

        $this->addColumn('created_at', array(
            'header' => $helper->__('Date'),
            'index'  => 'created_at',
            'type'   => 'datetime',
            'width'  => '140px',
        ));

        $this->addColumn('name', array(
            'header' => $helper->__('Name'),
            'index'  => 'name',
            'width'  => '160px',
        ));

        $this->addColumn('email', array(
            'header' => $helper->__('Email'),
            'index'  => 'email',
            'width'  => '220px',
        ));

        $this->addColumn('telephone', array(
            'header' => $helper->__('Tel'),
            'index'  => 'telephone',
            'width'  => '130px',
        ));

        $this->addColumn('courses_interested', array(
            'header' => $helper->__('Course Interested'),
            'index'  => 'courses_interested',
        ));

        $this->addColumn('store_code', array(
            'header'  => $helper->__('Store'),
            'index'   => 'store_code',
            'type'    => 'options',
            'options' => $this->_getStoreOptions(),
            'width'   => '110px',
        ));

        $this->addColumn('comment', array(
            'header' => $helper->__('Message'),
            'index'  => 'comment',
            'renderer' => 'MMD_Leads_Block_Adminhtml_Leads_Grid_Renderer_Truncate',
        ));

        $this->addColumn('status', array(
            'header'  => $helper->__('Status'),
            'index'   => 'status',
            'type'    => 'options',
            'width'   => '90px',
            'options' => array(
                MMD_Leads_Model_Lead::STATUS_NEW     => 'New',
                MMD_Leads_Model_Lead::STATUS_REPLIED => 'Replied',
            ),
        ));

        $this->addColumn('auto_reply_status', array(
            'header'  => $helper->__('Auto-Reply'),
            'index'   => 'auto_reply_status',
            'type'    => 'options',
            'width'   => '100px',
            'options' => array(
                MMD_Leads_Model_Lead::AUTO_REPLY_PENDING => $helper->__('Pending'),
                MMD_Leads_Model_Lead::AUTO_REPLY_SENT    => $helper->__('Sent'),
                MMD_Leads_Model_Lead::AUTO_REPLY_FAILED  => $helper->__('Failed'),
                MMD_Leads_Model_Lead::AUTO_REPLY_SKIPPED => $helper->__('Skipped'),
            ),
        ));

        $this->addColumn('action', array(
            'header'  => $helper->__('Action'),
            'width'   => '140px',
            'type'    => 'action',
            'getter'  => 'getId',
            'actions' => array(
                array(
                    'caption' => $helper->__('View / Reply'),
                    'url'     => array('base' => '*/*/view'),
                    'field'   => 'id',
                ),
                array(
                    'caption' => $helper->__('Delete'),
                    'url'     => array('base' => '*/*/delete'),
                    'field'   => 'id',
                    'confirm' => $helper->__('Delete this lead?'),
                ),
            ),
            'filter'    => false,
            'sortable'  => false,
            'is_system' => true,
        ));

        return parent::_prepareColumns();
    }

    protected function _prepareMassaction()
    {
        $this->setMassactionIdField('lead_id');
        $this->getMassactionBlock()->setFormFieldName('leads');
        $this->getMassactionBlock()->addItem('delete', array(
            'label'   => Mage::helper('mmd_leads')->__('Delete'),
            'url'     => $this->getUrl('*/*/massDelete'),
            'confirm' => Mage::helper('mmd_leads')->__('Delete the selected leads?'),
        ));
        return $this;
    }

    /**
     * Widen the auto-injected checkbox column. The default 20px col
     * blends into the table edge under the dark theme — bump to 44px
     * so the checkbox is unambiguously visible.
     */
    protected function _prepareMassactionColumn()
    {
        parent::_prepareMassactionColumn();
        if (isset($this->_columns['massaction'])) {
            $this->_columns['massaction']->setData('width', '44px');
        }
        return $this;
    }

    public function getGridUrl()
    {
        // Preserve the sidebar filter_status across AJAX grid reloads
        // (sort/page) so the filtered scope sticks.
        $params = array('_current' => true);
        $f = (string) $this->getRequest()->getParam('filter_status', '');
        if ($f !== '') {
            $params['filter_status'] = $f;
        }
        return $this->getUrl('*/*/grid', $params);
    }

    public function getRowUrl($row)
    {
        return $this->getUrl('*/*/view', array('id' => $row->getId()));
    }

    protected function _getStoreOptions()
    {
        $opts = array();
        foreach (Mage::app()->getStores(true) as $store) {
            $opts[$store->getCode()] = $store->getCode();
        }
        return $opts;
    }
}
