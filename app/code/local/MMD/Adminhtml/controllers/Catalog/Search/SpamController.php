<?php
/**
 * Bulk-delete spam from catalogsearch_query.
 *
 * Reachable at: <admin>/mmd/catalog_search_spam/index
 *
 * Buckets are defined in MMD_Adminhtml_Helper_SearchSpam. The delete action
 * never touches rows where synonym_for or redirect is set (admin-curated).
 */
class MMD_Adminhtml_Catalog_Search_SpamController extends Mage_Adminhtml_Controller_Action
{
    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('catalog/search');
        $this->_addContent(
            $this->getLayout()->createBlock('mmd/catalog_search_spam')
        );
        $this->renderLayout();
    }

    public function deleteAction()
    {
        if (!$this->getRequest()->isPost()) {
            $this->_redirect('*/*/');
            return;
        }

        $bucketIds = (array) $this->getRequest()->getParam('buckets', array());
        $storeId   = (int) $this->getRequest()->getParam('store_id', 0);

        /** @var MMD_Adminhtml_Helper_SearchSpam $helper */
        $helper = Mage::helper('mmd/searchSpam');
        $where  = $helper->buildWhereForBuckets($bucketIds, $storeId);

        $session = Mage::getSingleton('adminhtml/session');
        if ($where === null) {
            $session->addError($this->__('Select at least one spam category before deleting.'));
            $this->_redirect('*/*/');
            return;
        }

        try {
            $resource = Mage::getSingleton('core/resource');
            $db       = $resource->getConnection('core_write');
            $table    = $resource->getTableName('catalogsearch/search_query');
            $deleted  = (int) $db->delete($table, $where);
            $session->addSuccess($this->__(
                'Deleted %d spam search term(s) across %d bucket(s).',
                $deleted,
                count($bucketIds)
            ));
        } catch (Exception $e) {
            Mage::logException($e);
            $session->addError($this->__('Spam delete failed: %s', $e->getMessage()));
        }

        $this->_redirect('*/*/');
    }

    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('catalog/search');
    }
}
