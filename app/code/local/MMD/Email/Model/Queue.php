<?php
/**
 * Queue rewrite that flushes synchronously after each addMessageToQueue().
 *
 * The container has no cron daemon, so the standard "queue + cron flush"
 * cycle never completes and order/invoice/shipment emails sit unsent.
 * We still write the row (preserving the audit trail in core_email_queue
 * and the wasEmailQueued() de-dup), then immediately call the inherited
 * send() — which iterates pending messages and delivers each via
 * Zend_Mail::send(). Zend_Mail's default transport is set to our Gmail
 * OAuth2 transport at controller_front_init_before (see
 * MMD_Email_Model_Observer::installDefaultTransport), so the queue path
 * doesn't depend on SMTPPro being loaded.
 */
class MMD_Email_Model_Queue extends Mage_Core_Model_Email_Queue
{
    public function addMessageToQueue()
    {
        parent::addMessageToQueue();

        try {
            $this->send();
        } catch (Exception $e) {
            Mage::logException($e);
        }

        return $this;
    }
}
