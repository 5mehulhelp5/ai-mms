<?php
/**
 * Queue rewrite that flushes synchronously after each addMessageToQueue().
 *
 * The container has no cron daemon, so the standard "queue + cron flush"
 * cycle never completes and order/invoice/shipment emails sit unsent.
 * We still write the row (preserving the audit trail in core_email_queue
 * and the wasEmailQueued() de-dup), then immediately call the parent
 * send() which routes through SMTPPro's transport via the
 * `aschroder_smtppro_queue_before_send` event.
 *
 * Extending the SMTPPro queue rather than core's keeps SMTPPro's
 * per-cron page size, pause, and logging behaviour intact.
 */
class MMD_Email_Model_Queue extends Aschroder_SMTPPro_Model_Email_Queue
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
