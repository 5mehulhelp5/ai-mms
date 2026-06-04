<?php
class MMD_FeedbackForm_Model_Resource_Response_Collection extends Mage_Core_Model_Resource_Db_Collection_Abstract
{
    protected function _construct()
    {
        $this->_init('mmd_feedbackform/response');
    }
}
