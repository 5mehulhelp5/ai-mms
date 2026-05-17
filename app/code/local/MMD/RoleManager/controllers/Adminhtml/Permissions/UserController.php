<?php
require_once Mage::getModuleDir('controllers', 'Mage_Adminhtml') . DS . 'Permissions' . DS . 'UserController.php';

/**
 * Override of the core admin user controller. The only behavioral change is
 * in saveAction(): the core method takes array_slice($roles, 0, 1) which
 * forces single-role assignment. Here we keep the full role array so admin
 * users can be assigned multiple ACL groups (matches the chip multi-toggle
 * UI in Block/Permissions/User/Edit/Tab/Main.php).
 */
class MMD_RoleManager_Adminhtml_Permissions_UserController extends Mage_Adminhtml_Permissions_UserController
{
    public function saveAction()
    {
        if ($data = $this->getRequest()->getPost()) {
            $id = $this->getRequest()->getParam('user_id');
            $model = Mage::getModel('admin/user')->load($id);
            $isNew = !$model->getId();
            if (!$model->getId() && $id) {
                Mage::getSingleton('adminhtml/session')->addError($this->__('This user no longer exists.'));
                $this->_redirect('*/*/');
                return;
            }

            $currentPassword = $this->getRequest()->getParam('current_password', null);
            $this->getRequest()->setParam('current_password', null);
            unset($data['current_password']);
            $result = $this->_validateCurrentPassword($currentPassword);

            $model->setData($data);

            if ($model->hasNewPassword() && $model->getNewPassword() === '') {
                $model->unsNewPassword();
            }
            if ($model->hasPasswordConfirmation() && $model->getPasswordConfirmation() === '') {
                $model->unsPasswordConfirmation();
            }

            if (!is_array($result)) {
                $result = $model->validate();
            }
            if (is_array($result)) {
                Mage::getSingleton('adminhtml/session')->setUserData($data);
                foreach ($result as $message) {
                    Mage::getSingleton('adminhtml/session')->addError($message);
                }
                $this->_redirect('*/*/edit', ['_current' => true]);
                return $this;
            }

            try {
                $model->save();
                if (Mage::getStoreConfigFlag('admin/security/crate_admin_user_notification') && $isNew) {
                    Mage::getModel('admin/user')->sendAdminNotification($model);
                }

                // Multi-role assignment — keep ALL submitted role IDs (no array_slice).
                $uRoles = $this->getRequest()->getParam('roles', []);
                if (!is_array($uRoles)) {
                    $uRoles = [];
                }
                $uRoles = array_values(array_filter(array_map('intval', $uRoles)));
                $model->setRoleIds($uRoles)
                    ->setRoleUserId($model->getUserId())
                    ->saveRelations();

                Mage::getSingleton('adminhtml/session')->addSuccess($this->__('The user has been saved.'));
                Mage::getSingleton('adminhtml/session')->setUserData(false);
                $this->_redirect('*/*/');
                return;
            } catch (Mage_Core_Exception $e) {
                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
                Mage::getSingleton('adminhtml/session')->setUserData($data);
                $this->_redirect('*/*/edit', ['user_id' => $model->getUserId()]);
                return;
            }
        }
        $this->_redirect('*/*/');
    }
}
