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
}
