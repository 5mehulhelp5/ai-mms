<?php
/**
 * Learner self-mark attendance — dashboard, login-based (no QR scanning by the
 * learner; their authenticated dashboard session IS the identity, the SSG/
 * Singpass analog). Reached from My Classes -> View Course -> E-Attendance, or
 * by scanning the trainer's QR (which points straight here; admin URLs need no
 * secret key in this install, so the QR works once the learner is logged in).
 *
 *   GET  /selfmark/index/run_id/<id>   -> confirmation page (course + class details)
 *   POST /selfmark/submit              -> mark the logged-in learner present
 *
 * The RoleManager predispatch lockdown allows this route for learners
 * (_learnerAllowlist 'adminhtml_selfmark'); guards (enrolled + date window) live
 * in MMD_Attendance_Helper_Data::selfMarkPresent().
 */
class MMD_Attendance_Adminhtml_SelfmarkController extends Mage_Adminhtml_Controller_Action
{
    /** Any logged-in dashboard user (learner, trainer, admin) may self-mark. */
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isLoggedIn();
    }

    public function indexAction()
    {
        $this->loadLayout()
             ->_title($this->__('Attendance'))->_title($this->__('Mark My Attendance'));
        $this->renderLayout();
    }

    public function submitAction()
    {
        $runId = (int) $this->getRequest()->getParam('run_id');
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('Invalid request.');
            }
            $this->_validateFormKey();
            $res = Mage::helper('mmd_attendance')->selfMarkPresent($runId);
            if (!empty($res['success'])) {
                Mage::getSingleton('adminhtml/session')->addSuccess($res['message']);
            } else {
                Mage::getSingleton('adminhtml/session')->addError($res['message']);
            }
        } catch (Exception $e) {
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
        }
        $this->_redirect('adminhtml/selfmark/index', array('run_id' => $runId));
    }
}
