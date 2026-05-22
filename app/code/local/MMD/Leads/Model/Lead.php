<?php
/**
 * Active-record model for a single contact-form lead.
 *
 * Created from MMD_MagentoCaptcha_IndexController on every successful
 * /contacts/index/post submission. Fields are written verbatim from the
 * form; the store_id / store_code / ip are filled in at insert time so
 * we know which country site the lead came from and can resolve the
 * right registration URL when an operator replies.
 *
 * Status lifecycle: new → replied. (No "spam" status because Turnstile
 * already filters bots — the rows here are real human submissions.)
 */
class MMD_Leads_Model_Lead extends Mage_Core_Model_Abstract
{
    const STATUS_NEW     = 'new';
    const STATUS_REPLIED = 'replied';

    protected function _construct()
    {
        $this->_init('mmd_leads/lead');
    }

    protected function _beforeSave()
    {
        if (!$this->getId()) {
            if (!$this->getCreatedAt()) {
                $this->setCreatedAt(Varien_Date::now());
            }
            if (!$this->getStatus()) {
                $this->setStatus(self::STATUS_NEW);
            }
        }
        $this->setUpdatedAt(Varien_Date::now());
        return parent::_beforeSave();
    }

    public function markReplied($replyBody, $adminUserId = null)
    {
        $this->setStatus(self::STATUS_REPLIED);
        $this->setRepliedAt(Varien_Date::now());
        $this->setRepliedBy((int) $adminUserId);
        $this->setRepliedMessage((string) $replyBody);
        return $this->save();
    }
}
