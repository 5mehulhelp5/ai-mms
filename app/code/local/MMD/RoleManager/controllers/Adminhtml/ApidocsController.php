<?php
/**
 * Super-Admin-only API documentation page.
 *
 * Single screen at adminhtml/apidocs/index listing every public/integration
 * API this LMS exposes. Today it documents the WSQ Schedule API consumed by
 * the TMS. Future integrations (e.g. Leads webhook, R2 image manifest)
 * should append to template/rolemanager/apidocs.phtml as new <section>s
 * rather than spawning new pages — one stop for all integration specs.
 *
 * Gated to the Super Admin role only (training_provider) because the page
 * surfaces the live API key value for copy/paste.
 */
class MMD_RoleManager_Adminhtml_ApidocsController extends Mage_Adminhtml_Controller_Action
{
    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('system');
        $this->_title('API Documentation');

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('rolemanager/apidocs.phtml');
        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    protected function _isAllowed()
    {
        $helper = Mage::helper('mmd_rolemanager');
        if (!$helper) return false;
        return (string) $helper->getActiveRoleCode() === 'training_provider';
    }
}
