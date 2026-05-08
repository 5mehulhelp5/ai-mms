<?php
/**
 * Email validity guard. Format check is already handled on the front-end
 * via Prototype's `validate-email` class and HTML5 type="email"; this
 * observer adds the deliverability piece by requiring the email's domain
 * to publish at least one MX record. Catches typos like @gnail.com,
 * @gmial.com, @yhoo.com that pass a regex but bounce on first send.
 */
class MMD_Email_Model_Observer
{
    /**
     * @param Varien_Event_Observer $observer
     * @throws Mage_Core_Exception
     */
    public function validateCustomerEmail($observer)
    {
        $customer = $observer->getEvent()->getCustomer();
        if (!$customer) {
            return;
        }

        $email = trim((string) $customer->getEmail());
        if ($email === '') {
            return;
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            Mage::throwException(
                Mage::helper('customer')->__('"%s" is not a valid email address.', $email)
            );
        }

        $domain = substr(strrchr($email, '@'), 1);
        if ($domain === false || $domain === '') {
            Mage::throwException(
                Mage::helper('customer')->__('"%s" is not a valid email address.', $email)
            );
        }

        // checkdnsrr returns true if the domain has at least one MX record.
        // Fall back to A record (some valid mail domains expose only A records
        // and the SMTP RFC says servers should still try A on MX miss).
        $hasMx = @checkdnsrr($domain, 'MX') || @checkdnsrr($domain, 'A');
        if (!$hasMx) {
            Mage::throwException(
                Mage::helper('customer')->__(
                    'The email address "%s" does not appear to be deliverable — the domain "%s" has no mail server. Please check for typos.',
                    $email,
                    $domain
                )
            );
        }
    }
}
