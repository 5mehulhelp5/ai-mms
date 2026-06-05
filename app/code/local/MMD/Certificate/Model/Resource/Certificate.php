<?php
class MMD_Certificate_Model_Resource_Certificate extends Mage_Core_Model_Resource_Db_Abstract
{
    protected function _construct()
    {
        $this->_init('mmd_certificate/certificate', 'certificate_id');
    }
}
