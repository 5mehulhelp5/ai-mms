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

        // Resolve the order by increment_id AND token together. We do NOT use
        // loadByIncrementId(): a number can map to more than one order (a data
        // collision left e.g. #100041182 on both an OpenClaw and a six-sigma
        // order), and loadByIncrementId() would return an arbitrary one — the
        // wrong PDF. Matching the per-order protect_code as well pins the exact
        // order the email link was issued for, and keeps the anti-enumeration
        // guarantee (you still need that order's token).
        $order      = null;
        $candidates = Mage::getResourceModel('sales/order_collection')
            ->addFieldToFilter('increment_id', $incrementId);
        foreach ($candidates as $candidate) {
            $pc = (string) $candidate->getProtectCode();
            if ($pc !== '' && hash_equals($pc, $token)) {
                $order = Mage::getModel('sales/order')->load($candidate->getId());
                break;
            }
        }

        // Generic 404 so the endpoint never reveals whether an order id exists.
        if (!$order || !$order->getId()) {
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
