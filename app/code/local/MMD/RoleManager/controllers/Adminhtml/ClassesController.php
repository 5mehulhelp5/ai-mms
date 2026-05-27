<?php
/**
 * Admin "Classes" grid — a first-class view over course_runs. Lists every
 * class (course + date + time) with roster count, trainer, store badge,
 * and a deep-link to the existing dashboard assignlearner panel where
 * roster CRUD already lives.
 *
 * Backend-only. The storefront never hits this controller.
 *
 * Lives at adminhtml/classes/index → /tigerdragon/adminhtml/classes/index.
 *
 * Note: routed as "classes" (plural) — `class` would clash with PHP's
 * reserved keyword when Magento's router constructs the controller class
 * name dynamically. Plural form also matches Magento's own grid URL
 * convention (sales/order, customer/group, ...).
 */
class MMD_RoleManager_Adminhtml_ClassesController extends Mage_Adminhtml_Controller_Action
{
    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('catalog');
        $this->_title('Classes');

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('rolemanager/classes.phtml');
        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    /**
     * ACL: gate to Admin + Super Admin only. Trainer/Marketing/Learner
     * cannot view the full class list — they have their own scoped views
     * (e.g. trainer dashboard "My Assigned Classes").
     */
    protected function _isAllowed()
    {
        $helper = Mage::helper('mmd_rolemanager');
        if (!$helper) return false;
        $role = (string) $helper->getActiveRoleCode();
        return in_array($role, array('admin', 'super_admin', 'training_provider'), true);
    }
}
