<?php

class MMD_Whatsapp_Helper_Data extends Mage_Core_Helper_Abstract
{
    public function isEnabled()
    {
        return (bool) Mage::getStoreConfig('mmd_whatsapp/general/enabled') && $this->getNumber() !== '';
    }

    public function getNumber()
    {
        // Prefer per-store number configured in admin Company Setting
        // (mmd_company/whatsapp/<store_code>). Falls back to the legacy
        // System Configuration field if not set.
        $code = Mage::app()->getStore()->getCode();
        $raw  = (string) Mage::getStoreConfig('mmd_company/whatsapp/' . $code);
        if (trim($raw) === '') {
            $raw = (string) Mage::getStoreConfig('mmd_whatsapp/general/number');
        }
        return preg_replace('/\D+/', '', $raw);
    }

    public function getLink()
    {
        $n = $this->getNumber();
        return $n === '' ? '' : 'https://wa.me/' . $n;
    }

    /**
     * wa.me deep-link with a pre-filled message. Used by the chat popup so
     * each enquiry option lands in WhatsApp with context already typed.
     */
    public function getLinkWithText($text)
    {
        $base = $this->getLink();
        if ($base === '') {
            return '';
        }
        return $base . '?text=' . rawurlencode((string) $text);
    }

    /**
     * Per-store brand name shown in the popup header. Mirrors the auto-reply
     * branding (see MMD_Leads_Helper_Data::getStoreBrandName).
     */
    public function getBrandName()
    {
        if (Mage::helper('core')->isModuleEnabled('MMD_Leads')) {
            return Mage::helper('mmd_leads')->getStoreBrandName(Mage::app()->getStore()->getId());
        }
        $name = (string) Mage::app()->getStore()->getFrontendName();
        return $name !== '' ? $name : 'Tertiary Infotech Academy';
    }
}
