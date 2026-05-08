<?php
/**
 * Email validity guard.
 *
 * The Magento default is a regex-only check, which lets typos like
 * @gnail.com or @gmial.com through. We layer two extra checks:
 *
 *   1. A typo blocklist for the major free-mail providers. Plain MX
 *      lookups can't catch these because squatters register the typo
 *      domains and host real mail servers on them.
 *   2. An MX-or-A record lookup for everything else. Catches truly
 *      unregistered domains while staying loose enough that a small
 *      company on an unusual mail setup still validates.
 */
class MMD_Email_Model_Observer
{
    /** @var array<string,string> typo => intended domain */
    private static $TYPO_DOMAINS = [
        // gmail
        'gnail.com'   => 'gmail.com',
        'gmial.com'   => 'gmail.com',
        'gamil.com'   => 'gmail.com',
        'gmali.com'   => 'gmail.com',
        'gmaill.com'  => 'gmail.com',
        'ggmail.com'  => 'gmail.com',
        'gemail.com'  => 'gmail.com',
        'gmail.co'    => 'gmail.com',
        'gmail.cm'    => 'gmail.com',
        'gmail.con'   => 'gmail.com',
        'gmaii.com'   => 'gmail.com',
        // yahoo
        'yhoo.com'    => 'yahoo.com',
        'yaho.com'    => 'yahoo.com',
        'yahooo.com'  => 'yahoo.com',
        'yaoo.com'    => 'yahoo.com',
        'yahoo.co'    => 'yahoo.com',
        'yahoo.cm'    => 'yahoo.com',
        // hotmail / outlook / live
        'hotnail.com'   => 'hotmail.com',
        'hotmial.com'   => 'hotmail.com',
        'hotmai.com'    => 'hotmail.com',
        'hotmal.com'    => 'hotmail.com',
        'hotmali.com'   => 'hotmail.com',
        'outloook.com'  => 'outlook.com',
        'outlok.com'    => 'outlook.com',
        'outloo.com'    => 'outlook.com',
        'liv.com'       => 'live.com',
        'livr.com'      => 'live.com',
        // icloud / aol
        'iclod.com'   => 'icloud.com',
        'icoud.com'   => 'icloud.com',
        'icould.com'  => 'icloud.com',
        'aoll.com'    => 'aol.com',
        'aol.co'      => 'aol.com',
    ];

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
        $this->_assertEmail((string) $customer->getEmail());
    }

    /**
     * Throws Mage_Core_Exception with a user-facing message if the email
     * is malformed, has a typo'd provider domain, or has no MX/A record.
     */
    private function _assertEmail($email)
    {
        $email = trim($email);
        if ($email === '') {
            return; // empty is handled by the form's required-entry rule
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            Mage::throwException(
                Mage::helper('customer')->__('"%s" is not a valid email address.', $email)
            );
        }

        $domain = strtolower(substr(strrchr($email, '@'), 1));
        if ($domain === '') {
            Mage::throwException(
                Mage::helper('customer')->__('"%s" is not a valid email address.', $email)
            );
        }

        if (isset(self::$TYPO_DOMAINS[$domain])) {
            $suggested = self::$TYPO_DOMAINS[$domain];
            Mage::throwException(
                Mage::helper('customer')->__(
                    'The email "%s" looks like a typo. Did you mean "@%s"? Please correct it and try again.',
                    $email,
                    $suggested
                )
            );
        }

        $hasMx = @checkdnsrr($domain, 'MX') || @checkdnsrr($domain, 'A');
        if (!$hasMx) {
            Mage::throwException(
                Mage::helper('customer')->__(
                    'The email "%s" does not appear to be deliverable — the domain "%s" has no mail server. Please check for typos.',
                    $email,
                    $domain
                )
            );
        }
    }
}
