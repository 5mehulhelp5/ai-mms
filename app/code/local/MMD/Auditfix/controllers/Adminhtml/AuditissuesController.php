<?php
/**
 * MMD_Auditfix_Adminhtml_AuditissuesController
 *
 * Admin landing for the unified audit-issues log.
 *
 * Routes (all under /tigerdragon/auditissues/):
 *   indexAction       — main grid (Open / Fixed / Dismissed tabs).
 *   fixAction         — POST. Applies the registered handler for one issue.
 *   markAction        — POST. Sets status (open|fixed|dismissed|wont_fix).
 *   runScanAction     — POST. Triggers a scanner immediately (seo|security|code_review).
 */
class MMD_Auditfix_Adminhtml_AuditissuesController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        // Anyone with the ACL resource gets in. Sidebar gates by super-admin
        // role (see header.phtml / menu.phtml); the page enforces ACL.
        return Mage::getSingleton('admin/session')->isAllowed('admin/mmd_auditfix');
    }

    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('system');
        $this->_title('Audit Issues');

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('auditfix/issues.phtml');
        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    public function fixAction()
    {
        if (!$this->getRequest()->isPost()) {
            return $this->_json(array('ok' => false, 'msg' => 'POST required'));
        }
        $id  = (int)$this->getRequest()->getParam('issue_id');
        if (!$id) return $this->_json(array('ok' => false, 'msg' => 'missing issue_id'));

        $read = Mage::getSingleton('core/resource')->getConnection('core_read');
        $tbl  = Mage::getSingleton('core/resource')->getTableName('mmd_audit_issues');
        $row  = $read->fetchRow("SELECT * FROM {$tbl} WHERE issue_id = ?", $id);
        if (!$row) return $this->_json(array('ok' => false, 'msg' => 'issue not found'));
        if ($row['status'] === MMD_Auditfix_Helper_Data::STATUS_FIXED) {
            return $this->_json(array('ok' => true, 'msg' => 'already fixed'));
        }

        $fixer = Mage::getModel('mmd_auditfix/fixer');
        $res   = $fixer->fix($row);
        if (!empty($res['ok'])) {
            Mage::helper('mmd_auditfix')->markFixed($id, $res['summary']);
        }
        return $this->_json(array('ok' => !empty($res['ok']), 'msg' => $res['summary']));
    }

    public function markAction()
    {
        if (!$this->getRequest()->isPost()) {
            return $this->_json(array('ok' => false, 'msg' => 'POST required'));
        }
        $id     = (int)$this->getRequest()->getParam('issue_id');
        $status = (string)$this->getRequest()->getParam('status');
        $valid  = array('open', 'fixed', 'dismissed', 'wont_fix');
        if (!$id || !in_array($status, $valid, true)) {
            return $this->_json(array('ok' => false, 'msg' => 'invalid params'));
        }
        Mage::helper('mmd_auditfix')->setStatus($id, $status);
        return $this->_json(array('ok' => true, 'msg' => "status → {$status}"));
    }

    public function runScanAction()
    {
        if (!$this->getRequest()->isPost()) {
            return $this->_json(array('ok' => false, 'msg' => 'POST required'));
        }
        $which = (string)$this->getRequest()->getParam('which');
        $map = array(
            'seo'         => 'mmd_auditfix/cron_scanSeo',
            'security'    => 'mmd_auditfix/cron_scanSecurity',
            'code_review' => 'mmd_auditfix/cron_scanCodeReview',
        );
        if (!isset($map[$which])) return $this->_json(array('ok' => false, 'msg' => 'unknown scanner'));
        try {
            Mage::getModel($map[$which])->run();
            return $this->_json(array('ok' => true, 'msg' => "Ran {$which} scanner."));
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(array('ok' => false, 'msg' => $e->getMessage()));
        }
    }

    protected function _json(array $payload)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json')
            ->setBody(json_encode($payload));
    }
}
