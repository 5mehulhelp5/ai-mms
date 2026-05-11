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

    /**
     * Send a course-registration confirmation email after every order place.
     * Replaces Magento's generic order-confirmation email with one that
     * surfaces the course-specific details a learner cares about: course
     * title + code, the chosen date / time / mode, sponsorship, and the
     * order reference. Magento's default order email is disabled (see
     * migration 058) so the customer only receives this one.
     */
    public function sendCourseRegistrationEmail($observer)
    {
        try {
            $order = $observer->getEvent()->getOrder();
            if (!$order || !$order->getId()) return;
            if ($order->getEmailSent()) return;

            $email = trim((string) $order->getCustomerEmail());
            if ($email === '') return;
            if (!Mage::getStoreConfig('mmd_email/course_registration/enabled', $order->getStoreId())) return;

            $courses = $this->_buildCourseList($order);
            if (empty($courses)) return; // nothing meaningful to send

            $coursesHtml = $this->_renderCoursesHtml($courses);

            $customerName = trim((string) $order->getCustomerName());
            if ($customerName === '') {
                $customerName = trim($order->getCustomerFirstname() . ' ' . $order->getCustomerLastname());
            }
            if ($customerName === '') $customerName = $email;

            $storeId   = $order->getStoreId();
            $storeName = Mage::app()->getStore($storeId)->getFrontendName();
            $vars = array(
                'order'              => $order,
                'customer_name'      => $customerName,
                'first_course_name'  => $courses[0]['name'],
                'courses_html'       => $coursesHtml,
                'courses_count_plural' => count($courses) > 1 ? 1 : 0,
                'grand_total'        => Mage::helper('core')->currency($order->getGrandTotal(), true, false),
                'store_name'         => $storeName,
                'store_email'        => (string) Mage::getStoreConfig('trans_email/ident_sales/email', $storeId),
            );

            $templateCode = (string) Mage::getStoreConfig('mmd_email/course_registration/template', $storeId);
            if ($templateCode === '') $templateCode = 'mmd_email_course_registration';
            $identity = (string) Mage::getStoreConfig('mmd_email/course_registration/identity', $storeId);
            if ($identity === '') $identity = 'sales';

            // Prefer Gmail OAuth2 when the credentials page has been
            // filled in — that's our actual outbound mail path on the
            // live site. Falls back to Magento's standard mailer (SMTP
            // via SMTPPro) for environments where OAuth2 isn't set up.
            $gmail = Mage::helper('mmd_email/gmail');
            if ($gmail && $gmail->isConfigured()) {
                $tpl = Mage::getModel('core/email_template');
                $tpl->loadDefault($templateCode);
                // Magento processes both subject and body with the
                // template variables before we hand them to Gmail.
                $tpl->setDesignConfig(array('area' => 'frontend', 'store' => $storeId));
                $tpl->setSenderName(Mage::getStoreConfig('trans_email/ident_' . $identity . '/name', $storeId));
                $tpl->setSenderEmail(Mage::getStoreConfig('trans_email/ident_' . $identity . '/email', $storeId));
                $subject = $tpl->getProcessedTemplateSubject($vars);
                $body    = $tpl->getProcessedTemplate($vars);
                $fromName = (string) Mage::getStoreConfig('trans_email/ident_' . $identity . '/name', $storeId);
                $gmail->send($email, $subject, $body, $fromName);
            } else {
                $mailer = Mage::getModel('core/email_template_mailer');
                $emailInfo = Mage::getModel('core/email_info');
                $emailInfo->addTo($email, $customerName);
                $mailer->addEmailInfo($emailInfo);
                $mailer->setSender($identity);
                $mailer->setStoreId($storeId);
                $mailer->setTemplateId($templateCode);
                $mailer->setTemplateParams($vars);
                $mailer->send();
            }

            $order->setEmailSent(true)->save();
        } catch (Exception $e) {
            // Never block order placement on email failure.
            Mage::logException($e);
        }
    }

    /**
     * Walk the order's visible items and pull the human-readable
     * label/value pairs out of each item's product_options. Magento
     * already stashes a flat options list with `label` + `print_value`
     * keys, so we don't have to look up option IDs.
     */
    private function _buildCourseList($order)
    {
        $courses = array();
        foreach ($order->getAllVisibleItems() as $item) {
            $opts = $item->getProductOptions();
            if (!is_array($opts)) {
                $raw = (string) $item->getData('product_options');
                $opts = $raw !== '' ? @unserialize($raw) : array();
                if (!is_array($opts)) $opts = array();
            }
            $details = array();
            if (!empty($opts['options']) && is_array($opts['options'])) {
                foreach ($opts['options'] as $o) {
                    $label = isset($o['label']) ? trim((string) $o['label']) : '';
                    $value = isset($o['print_value']) ? trim((string) $o['print_value'])
                           : (isset($o['value'])      ? trim((string) $o['value']) : '');
                    if ($label === '' || $value === '') continue;
                    $details[] = array('label' => $label, 'value' => $value);
                }
            }
            $courses[] = array(
                'name'    => $item->getName(),
                'sku'     => $item->getSku(),
                'qty'     => (int) $item->getQtyOrdered(),
                'details' => $details,
            );
        }
        return $courses;
    }

    /**
     * Render the courses block as inline-styled HTML the email
     * template can drop in via {{var courses_html}}. Inline styles only
     * (Gmail/Outlook-friendly).
     */
    private function _renderCoursesHtml(array $courses)
    {
        $h = '';
        foreach ($courses as $c) {
            $h .= '<div style="border:1px solid #e2e8f0;border-radius:8px;padding:16px 18px;margin-bottom:14px;background:#f8fafc;">';
            $h .= '<div style="font-size:16px;font-weight:700;color:#0f172a;margin-bottom:4px;">' . htmlspecialchars($c['name']) . '</div>';
            $h .= '<div style="font-size:12px;color:#64748b;margin-bottom:12px;">Course Code: <span style="color:#0f172a;font-weight:600;">' . htmlspecialchars($c['sku']) . '</span></div>';
            if (!empty($c['details'])) {
                $h .= '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="font-size:13px;">';
                foreach ($c['details'] as $d) {
                    $h .= '<tr>'
                        .   '<td style="padding:4px 8px 4px 0;color:#64748b;width:38%;vertical-align:top;">' . htmlspecialchars($d['label']) . '</td>'
                        .   '<td style="padding:4px 0;color:#0f172a;font-weight:500;">' . htmlspecialchars(strip_tags((string) $d['value'])) . '</td>'
                        . '</tr>';
                }
                $h .= '</table>';
            }
            $h .= '</div>';
        }
        return $h;
    }
}
