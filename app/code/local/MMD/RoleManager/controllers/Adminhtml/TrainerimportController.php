<?php
/**
 * Admin actions for importing trainers from LMS:
 *  - pull            : manual import now (JSON summary)
 *  - setAutoEnabled  : toggle the daily auto-pull fail-safe flag
 *  - saveConfig      : store LMS URL + API key
 */
class MMD_RoleManager_Adminhtml_TrainerimportController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array('admin', 'training_provider', 'developer'));
    }

    public function pullAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            /** @var MMD_RoleManager_Model_TrainerImportService $svc */
            $svc = Mage::getModel('mmd_rolemanager/trainerImportService');
            if (!$svc->isConfigured()) throw new Exception('Set the LMS URL and API key first.');

            $user  = Mage::getSingleton('admin/session')->getUser();
            $who   = $user ? (string)$user->getEmail() : 'admin';
            $res   = $svc->pull($who);
            $this->_json(array_merge(array('success' => $res['success']), $res));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    public function setAutoEnabledAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();
            $value = (int) $this->getRequest()->getParam('value') ? 1 : 0;
            Mage::getConfig()->saveConfig('mmd/trainer_import/auto_enabled', $value, 'default', 0);
            Mage::getConfig()->reinit();
            $this->_json(array('success' => true, 'value' => $value,
                'message' => $value ? 'Daily LMS trainer pull enabled.' : 'Daily LMS trainer pull disabled.'));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    public function saveConfigAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();
            $url = trim((string)$this->getRequest()->getParam('lms_url'));
            $key = trim((string)$this->getRequest()->getParam('api_key'));
            Mage::getConfig()->saveConfig('mmd/trainer_import/lms_url', $url, 'default', 0);
            // Only overwrite the key if a non-empty value was supplied (so the
            // field can be left blank to keep the existing key).
            if ($key !== '') {
                Mage::getConfig()->saveConfig('mmd/trainer_import/api_key', $key, 'default', 0);
            }
            Mage::getConfig()->reinit();
            $this->_json(array('success' => true, 'message' => 'LMS connection settings saved.'));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    protected function _json(array $data)
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json', true)->setBody(json_encode($data));
    }
}
