<?php
class MMD_Attendance_Model_Resource_Attendance_Collection extends Mage_Core_Model_Resource_Db_Collection_Abstract
{
    protected function _construct()
    {
        $this->_init('mmd_attendance/attendance');
    }
}
