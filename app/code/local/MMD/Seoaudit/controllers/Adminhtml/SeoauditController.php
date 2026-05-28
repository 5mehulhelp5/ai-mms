<?php
/**
 * Renders the SEO Audit panel at /<adminFrontName>/adminhtml/seoaudit/.
 *
 * Single action — uses the global Branchscope Store View bar (auto-injected
 * by the <default> layout handle) so the active store is `?store=N`.
 *
 * The class name is intentionally flat (SeoauditController) so the URL
 * helper key `adminhtml/seoaudit` resolves correctly under Magento's
 * adminhtml router. Same pattern as MarketingdashboardController.
 */
class MMD_Seoaudit_Adminhtml_SeoauditController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/mmd_seoaudit');
    }

    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('admin/mmd_seoaudit');
        $this->_addContent($this->getLayout()->createBlock('mmd_seoaudit/adminhtml_audit'));
        $this->renderLayout();
    }
}
