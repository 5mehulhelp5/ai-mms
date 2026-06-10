<?php
/**
 * MMD_Proforma helper.
 *
 * Required so Mage::helper('proforma') resolves; also the conventional
 * place for module-wide helpers if the pro forma flow grows.
 */
class MMD_Proforma_Helper_Data extends Mage_Core_Helper_Abstract
{
    /**
     * Is this order eligible for a Pro Forma Invoice?
     *
     * Only SELF-sponsored registrations are. Employer/company-sponsored
     * registrations are billed by company invoice and never use SkillsFuture
     * Credit, so they get no pro forma — the email link is hidden and the
     * /pdf/ endpoint refuses to generate one.
     *
     * The signal is the order item's "Sponsorship" custom option, whose only
     * values are "Self-Sponsored" and "Employer-Sponsored". Returns true only
     * when at least one item is self-sponsored AND none is employer-sponsored;
     * an order with no Sponsorship option (e.g. a non-WSQ purchase) returns
     * false — it has no SFC pro forma to claim against.
     *
     * @param  Mage_Sales_Model_Order|null $order
     * @return bool
     */
    public function isOrderSelfSponsored($order)
    {
        if (!$order || !$order->getId()) {
            return false;
        }

        $sawSelf = false;
        foreach ($order->getAllVisibleItems() as $item) {
            $sponsorship = $this->getItemSponsorship($item);
            if ($sponsorship === '') {
                continue;
            }
            if (stripos($sponsorship, 'employer') !== false || stripos($sponsorship, 'company') !== false) {
                return false;
            }
            if (stripos($sponsorship, 'self') !== false) {
                $sawSelf = true;
            }
        }

        return $sawSelf;
    }

    /**
     * Pull the "Sponsorship" custom-option value off an order item (or '').
     */
    public function getItemSponsorship($item)
    {
        $opts = $item->getProductOptions();
        if (is_array($opts) && !empty($opts['options'])) {
            foreach ($opts['options'] as $o) {
                if (isset($o['label']) && stripos((string) $o['label'], 'Sponsorship') !== false) {
                    return isset($o['value']) ? trim((string) $o['value']) : '';
                }
            }
        }
        return '';
    }
}
