<?php
/**
 * Streams a Pro Forma Invoice PDF for a single order.
 *
 * Route:  /pdf/?orderID=<increment_id>&token=<protect_code>
 *
 * The token is the order's protect_code (a random per-order hash Magento
 * already generates and stores on sales_flat_order). Requiring it stops
 * anyone from enumerating sequential increment_ids and harvesting other
 * learners' names / companies / addresses from the pro forma PDFs.
 */
class MMD_Proforma_IndexController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        $incrementId = trim((string) $this->getRequest()->getParam('orderID'));
        $token       = trim((string) $this->getRequest()->getParam('token'));

        if ($incrementId === '' || $token === '') {
            $this->_deny();
            return;
        }

        /** @var Mage_Sales_Model_Order $order */
        $order = Mage::getModel('sales/order')->loadByIncrementId($incrementId);

        // Constant-time token check; bail with a generic 404 either way so the
        // endpoint never reveals whether a given order id exists.
        $expected = (string) $order->getProtectCode();
        if (!$order->getId() || $expected === '' || !hash_equals($expected, $token)) {
            $this->_deny();
            return;
        }

        try {
            $pdf     = Mage::getModel('proforma/proforma')->getOrderPdf($order);
            $content = $pdf->render();
        } catch (Exception $e) {
            Mage::logException($e);
            $this->_deny();
            return;
        }

        $filename = 'ProForma-Invoice-' . $order->getIncrementId() . '.pdf';

        $this->getResponse()
            ->clearHeaders()
            ->setHeader('Content-Type', 'application/pdf', true)
            ->setHeader('Content-Disposition', 'inline; filename="' . $filename . '"', true)
            ->setHeader('Content-Length', strlen($content), true)
            ->setHeader('Cache-Control', 'private, max-age=0, must-revalidate', true)
            ->setHeader('X-Robots-Tag', 'noindex, nofollow', true)
            ->setBody($content);
    }

    /**
     * Generic 404 — used for missing order, missing/wrong token, and render
     * failure alike so the response never leaks order existence.
     */
    protected function _deny()
    {
        $this->getResponse()
            ->setHttpResponseCode(404)
            ->setHeader('Content-Type', 'text/plain; charset=utf-8', true)
            ->setBody('Pro forma invoice not available.');
    }
}
