<?php
/**
 * Admin: look up an order by number, verify the course, then download its
 * Pro Forma Invoice PDF.
 *
 * Routes:
 *   adminhtml/proforma/index?order_no=<increment>  → form + matching-order list
 *   adminhtml/proforma/print/order_id/<entity_id>   → generate + download (one order)
 *
 * Why a look-up step (not type → straight download): order numbers are not
 * guaranteed unique on production (a data-import collision can leave two orders
 * sharing one increment_id — e.g. #100041182 mapping to BOTH an OpenClaw and a
 * six-sigma course). loadByIncrementId() would then return an arbitrary one and
 * silently produce the wrong PDF. Listing every match with its course lets the
 * operator pick the right order; downloading is always keyed on the unambiguous
 * entity id (order_id). The order-view button also passes order_id, so it is
 * unaffected.
 *
 * The PDF is generated fresh from the live order each time — there is no stored
 * copy — so this IS the "regenerate" action.
 */
class MMD_Proforma_Adminhtml_ProformaController extends Mage_Adminhtml_Controller_Action
{
    /**
     * Entry page: "Order Number" field + the list of orders matching it.
     */
    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('sales/sales_order');
        $this->_title($this->__('Pro Forma Invoice'));

        $orderNo = trim((string) $this->getRequest()->getParam('order_no'));
        $results = array();
        foreach ($this->_ordersByIncrementId($orderNo) as $o) {
            $courses = array();
            foreach ($o->getAllVisibleItems() as $it) {
                $courses[] = $it->getName();
            }
            $results[] = array(
                'order_id'  => $o->getId(),
                'increment' => $o->getIncrementId(),
                'created'   => Mage::helper('core')->formatDate($o->getCreatedAtStoreDate(), 'medium', false),
                'customer'  => $o->getCustomerName(),
                // Plain text — formatPrice() returns <span class="price">…</span>
                // markup which the template (correctly) escapes, so it would
                // print the raw tags.
                'grand'     => $o->getOrderCurrencyCode() . ' ' . number_format((float) $o->getGrandTotal(), 2),
                'courses'   => $courses,
                'print_url' => $this->getUrl('*/*/print', array('order_id' => $o->getId())),
            );
        }

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('proforma/generate.phtml')
            ->setData('form_action', $this->getUrl('*/*/index'))
            ->setData('searched_no', $orderNo)
            ->setData('results', $results);

        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    /**
     * Generate + download for ONE order, keyed on the unambiguous entity id.
     * Falls back to a number look-up (order-view button always sends order_id).
     */
    public function printAction()
    {
        $orderId = (int) $this->getRequest()->getParam('order_id');
        $orderNo = trim((string) $this->getRequest()->getParam('order_no'));

        /** @var Mage_Sales_Model_Order $order */
        if ($orderId > 0) {
            $order = Mage::getModel('sales/order')->load($orderId);
        } elseif ($orderNo !== '') {
            // Only download straight off a number when it is unambiguous;
            // otherwise bounce to the list so the operator picks.
            $matches = $this->_ordersByIncrementId($orderNo);
            if (count($matches) !== 1) {
                $this->_redirect('*/*/index', array('order_no' => $orderNo));
                return;
            }
            $order = reset($matches);
        } else {
            $this->_redirect('*/*/index');
            return;
        }

        if (!$order->getId()) {
            Mage::getSingleton('adminhtml/session')->addError($this->__('That order could not be found.'));
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
     * Every order carrying a given increment_id, loaded in full (newest first).
     * Returns array<entity_id, Mage_Sales_Model_Order>. Empty for a blank input.
     */
    protected function _ordersByIncrementId($incrementId)
    {
        $incrementId = trim((string) $incrementId);
        if ($incrementId === '') {
            return array();
        }
        $ids = Mage::getResourceModel('sales/order_collection')
            ->addFieldToFilter('increment_id', $incrementId)
            ->setOrder('entity_id', 'DESC')
            ->getAllIds();

        $orders = array();
        foreach ($ids as $id) {
            $orders[$id] = Mage::getModel('sales/order')->load($id);
        }
        return $orders;
    }

    /**
     * Gate on the standard sales-order ACL resource so the page, the look-up,
     * and the order-view button share one permission.
     */
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('sales/order');
    }
}
