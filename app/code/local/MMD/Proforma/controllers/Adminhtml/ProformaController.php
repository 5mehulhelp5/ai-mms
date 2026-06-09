<?php
/**
 * Admin: regenerate + download a Pro Forma Invoice PDF for an order.
 *
 * Routes:
 *   adminhtml/proforma/index                      → entry form (type an order number)
 *   adminhtml/proforma/print/order_no/<increment> → generate + download (form target)
 *   adminhtml/proforma/print/order_id/<entity_id> → same, from the order-view button
 *
 * The PDF is generated fresh on every request from the live order — there is
 * no stored copy — so this IS the "regenerate" action; it simply streams the
 * regenerated document as a download.
 */
class MMD_Proforma_Adminhtml_ProformaController extends Mage_Adminhtml_Controller_Action
{
    /**
     * Entry page: a single "Order Number" field + Generate button.
     */
    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('sales/sales_order');
        $this->_title($this->__('Pro Forma Invoice'));

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('proforma/generate.phtml')
            ->setData('form_action', $this->getUrl('adminhtml/proforma/print'))
            ->setData('last_order_no', (string) $this->getRequest()->getParam('order_no'));

        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    /**
     * Generate the PDF and stream it as a download.
     *
     * Accepts either the human order number (increment_id, what the admin types
     * on the form) or the internal order_id (used by the order-view button).
     */
    public function printAction()
    {
        $orderNo = trim((string) $this->getRequest()->getParam('order_no'));
        $orderId = (int) $this->getRequest()->getParam('order_id');

        /** @var Mage_Sales_Model_Order $order */
        if ($orderNo !== '') {
            $order = Mage::getModel('sales/order')->loadByIncrementId($orderNo);
        } else {
            $order = Mage::getModel('sales/order')->load($orderId);
        }

        if (!$order->getId()) {
            Mage::getSingleton('adminhtml/session')->addError(
                $this->__('No order found for "%s". Check the order number and try again.', $orderNo !== '' ? $orderNo : $orderId)
            );
            $this->_redirect('*/*/index');
            return;
        }

        try {
            $pdf     = Mage::getModel('proforma/proforma')->getOrderPdf($order);
            $content = $pdf->render();
        } catch (Exception $e) {
            Mage::logException($e);
            Mage::getSingleton('adminhtml/session')->addError(
                $this->__('The pro forma invoice could not be generated for order %s.', $order->getIncrementId())
            );
            $this->_redirect('*/*/index');
            return;
        }

        $filename = 'ProForma-Invoice-' . $order->getIncrementId() . '.pdf';

        $this->_prepareDownloadResponse($filename, $content, 'application/pdf');
    }

    /**
     * Gate on the standard sales-order ACL resource so the page, the form, and
     * the order-view button share one permission. With the current "all roles
     * inherit Administrators" setup this is true for every operator who can
     * open an order.
     */
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('sales/order');
    }
}
