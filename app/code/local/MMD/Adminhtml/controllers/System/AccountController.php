<?php
require_once Mage::getModuleDir('controllers', 'Mage_Adminhtml') . '/System/AccountController.php';

class MMD_Adminhtml_System_AccountController extends Mage_Adminhtml_System_AccountController
{
    /**
     * The parent gates My Account behind the `system/myaccount` ACL
     * resource, which only Super Admin / Administrators groups grant.
     * That's wrong for this LMS — a Learner / Trainer / Marketing user
     * still has to be able to view and edit their own profile (name,
     * email, password, profile image). Allow any authenticated admin
     * regardless of role group; this only exposes their OWN record,
     * not other users'.
     *
     * @return bool
     */
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isLoggedIn();
    }

    /**
     * Save account without requiring current password.
     * Handles profile fields + image upload.
     */
    public function saveAction()
    {
        $userId = Mage::getSingleton('admin/session')->getUser()->getId();
        $user = Mage::getModel('admin/user')->load($userId);

        $user->setId($userId)
            ->setUsername($this->getRequest()->getParam('username', $user->getUsername()))
            ->setFirstname($this->getRequest()->getParam('firstname', false))
            ->setLastname($this->getRequest()->getParam('lastname', false))
            ->setEmail(strtolower($this->getRequest()->getParam('email', false)));

        // Profile fields — saved directly via SQL since core model
        // _beforeSave() only persists a whitelist of fields
        $profileData = array();
        $profileFields = array('tel', 'gender', 'race', 'dob', 'nric_fin', 'linkedin_url', 'trainer_description');
        foreach ($profileFields as $field) {
            $value = $this->getRequest()->getParam($field, null);
            $profileData[$field] = ($value !== '' && $value !== null) ? $value : null;
        }

        // Profile image upload
        if (isset($_FILES['profile_image']) && $_FILES['profile_image']['name']) {
            try {
                $path = Mage::getBaseDir('media') . DS . 'admin' . DS . 'profile';

                // Ensure the target directory exists. .dockerignore keeps the
                // whole media/ tree out of the image, so on a fresh container
                // (or a Coolify volume mount that didn't seed media/admin/),
                // this path doesn't exist until the first upload — and
                // Varien_File_Uploader::save() throws "Destination folder is
                // not writable or does not exist." rather than mkdir for us.
                // Create it on demand with www-data-writable perms.
                if (!is_dir($path)) {
                    if (!@mkdir($path, 0775, true) && !is_dir($path)) {
                        throw new Exception('Could not create upload directory: ' . $path);
                    }
                }

                $uploader = new Varien_File_Uploader('profile_image');
                $uploader->setAllowedExtensions(array('jpg', 'jpeg', 'png', 'gif'));
                $uploader->setAllowRenameFiles(true);
                $uploader->setFilesDispersion(false);

                $ext = strtolower(pathinfo($_FILES['profile_image']['name'], PATHINFO_EXTENSION));
                $filename = 'user_' . $userId . '_' . time() . '.' . $ext;
                $result = $uploader->save($path, $filename);

                // Varien_File_Uploader::save returns an array with the
                // actual saved file (renamed when collisions occur). Use
                // that, not the input filename — otherwise a renamed
                // upload would persist the wrong name to the DB.
                $savedName = isset($result['file']) ? ltrim($result['file'], '/\\') : $filename;

                // Delete old image
                $resource = Mage::getSingleton('core/resource');
                $oldImage = $resource->getConnection('core_read')->fetchOne(
                    'SELECT profile_image FROM ' . $resource->getTableName('admin/user') . ' WHERE user_id = ?',
                    array($userId)
                );
                if ($oldImage && $oldImage !== $savedName) {
                    $oldPath = $path . DS . $oldImage;
                    if (file_exists($oldPath)) {
                        @unlink($oldPath);
                    }
                }

                $profileData['profile_image'] = $savedName;
            } catch (Exception $e) {
                Mage::logException($e);
                Mage::getSingleton('adminhtml/session')->addError('Image upload failed: ' . $e->getMessage());
            }
        }

        if ($this->getRequest()->getParam('new_password', false)) {
            $user->setNewPassword($this->getRequest()->getParam('new_password', false));
        }
        if ($this->getRequest()->getParam('password_confirmation', false)) {
            $user->setPasswordConfirmation($this->getRequest()->getParam('password_confirmation', false));
        }

        // Skip current password validation
        $result = $user->validate();
        if (is_array($result)) {
            foreach ($result as $error) {
                Mage::getSingleton('adminhtml/session')->addError($error);
            }
            $this->getResponse()->setRedirect($this->getUrl('*/*/'));
            return;
        }

        try {
            $user->save();

            // Save profile fields directly (bypasses model whitelist)
            $resource = Mage::getSingleton('core/resource');
            $write = $resource->getConnection('core_write');
            $write->update(
                $resource->getTableName('admin/user'),
                $profileData,
                'user_id = ' . (int)$userId
            );

            // Mirror trainer_description into courses_trainers.description
            // for the trainer row that shares this user's email — keeps
            // the View Trainers grid in sync with what the trainer just
            // saved on their My Profile page. Silent no-op if no match.
            if (array_key_exists('trainer_description', $profileData)) {
                try {
                    $write->update(
                        $resource->getTableName('courses_trainers'),
                        ['description' => $profileData['trainer_description']],
                        ['email = ?' => $user->getEmail()]
                    );
                } catch (Exception $_syncEx) {
                    Mage::logException($_syncEx);
                }
            }

            Mage::getSingleton('adminhtml/session')->addSuccess(
                Mage::helper('adminhtml')->__('The account has been saved.')
            );
        } catch (Mage_Core_Exception $e) {
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
        } catch (Exception $e) {
            // Log the real exception — the user-facing message is
            // intentionally generic, but a swallowed trace makes
            // prod-only failures (e.g. admin_user schema drift)
            // impossible to diagnose. See var/log/exception.log.
            Mage::logException($e);
            Mage::getSingleton('adminhtml/session')->addError(
                Mage::helper('adminhtml')->__('An error occurred while saving account.')
            );
        }
        $this->getResponse()->setRedirect($this->getUrl('*/*/'));
    }
}
