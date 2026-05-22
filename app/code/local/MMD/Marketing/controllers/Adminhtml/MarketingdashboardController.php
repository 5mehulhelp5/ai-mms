<?php
/**
 * Renders the Marketing Dashboard at /<adminFrontName>/marketingdashboard/.
 *
 * Single action — the template is monolithic (matches the existing admin
 * dashboard pattern). All SQL runs in the .phtml using $read; no Block
 * abstraction yet.
 *
 * Class / file name is intentionally flat (MarketingdashboardController)
 * rather than namespaced (Mmd/Marketing/DashboardController) so the URL
 * helper key `adminhtml/marketingdashboard` resolves correctly. Magento's
 * adminhtml routing maps `adminhtml/<key>` → `_Adminhtml_<UCFirst>Controller`.
 */
class MMD_Marketing_Adminhtml_MarketingdashboardController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/mmd_marketing');
    }

    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('admin/mmd_marketing');
        $this->_addContent($this->getLayout()->createBlock('mmd_marketing/adminhtml_dashboard'));
        $this->renderLayout();
    }
}
