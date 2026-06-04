<?php
class MMD_FeedbackForm_Model_Resource_Response extends Mage_Core_Model_Resource_Db_Abstract
{
    protected function _construct()
    {
        $this->_init('mmd_feedbackform/response', 'response_id');
    }
}
