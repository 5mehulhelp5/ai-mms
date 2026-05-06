<?php
class MMD_RoleManager_Adminhtml_AttendanceController extends Mage_Adminhtml_Controller_Action
{
    protected function _validateFormKey()
    {
        return true;
    }

    /**
     * Fetch the list of enrolled learners for a given (course, session) and their
     * current attendance status.
     *
     * GET: course_id, option_type_id
     * Returns JSON:
     *   {
     *     success: true,
     *     session_label: "27 April 2026 (Mon)",
     *     learners: [ { customer_id, name, email, status } ],
     *   }
     */
    public function listAction()
    {
        $result = array('success' => false);
        try {
            $courseId     = (int) $this->getRequest()->getParam('course_id');
            $optionTypeId = (int) $this->getRequest()->getParam('option_type_id');
            if (!$courseId || !$optionTypeId) {
                throw new Exception('course_id and option_type_id are required');
            }

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            // Verify session belongs to course
            $sessionLabel = $read->fetchOne(
                "SELECT ott.title FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 JOIN catalog_product_option_type_title ott ON ott.option_type_id = ov.option_type_id AND ott.store_id = 0
                 WHERE ov.option_type_id = ? AND o.product_id = ?",
                array($optionTypeId, $courseId)
            );
            if (!$sessionLabel) {
                throw new Exception('Session not found for this course');
            }

            // Find all customers who ordered this course WITH this specific session selected.
            // Magento 1 customer_entity is EAV — firstname/lastname live in customer_entity_varchar.
            $fnAttr = (int) $read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=1 AND attribute_code='firstname'");
            $lnAttr = (int) $read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=1 AND attribute_code='lastname'");

            $nameJoinsSql =
                " LEFT JOIN customer_entity_varchar fn ON fn.entity_id = c.entity_id AND fn.attribute_id = ?"
              . " LEFT JOIN customer_entity_varchar ln ON ln.entity_id = c.entity_id AND ln.attribute_id = ?";

            $rows = $read->fetchAll(
                "SELECT DISTINCT o.customer_id, c.email,
                        CONCAT(TRIM(COALESCE(fn.value,'')), ' ', TRIM(COALESCE(ln.value,''))) AS name
                 FROM sales_flat_order_item oi
                 JOIN sales_flat_order o ON o.entity_id = oi.order_id
                 JOIN customer_entity c ON c.entity_id = o.customer_id
                 {$nameJoinsSql}
                 WHERE oi.product_id = ?
                   AND o.customer_id IS NOT NULL
                   AND (oi.product_options LIKE ? OR oi.product_options LIKE ?)
                 ORDER BY name",
                array($fnAttr, $lnAttr, $courseId, '%i:' . $optionTypeId . ';%', '%"option_value";s:%"' . $optionTypeId . '"%')
            );

            // Also include any previously-marked attendance rows (keeps record if enrolment data changed)
            $marked = $read->fetchPairs(
                "SELECT customer_id, status FROM course_attendance WHERE option_type_id = ?",
                array($optionTypeId)
            );

            // No fallback to "all customers who ordered this course" — that was showing
            // the same learner on every session of a course regardless of which session
            // they were actually booked into. An empty list is the correct answer when
            // nobody picked this particular option_type_id.

            $learners = array();
            foreach ($rows as $r) {
                $cid = (int) $r['customer_id'];
                if (!$cid) continue;
                $learners[] = array(
                    'customer_id' => $cid,
                    'name'        => trim($r['name']) ?: $r['email'],
                    'email'       => $r['email'],
                    'status'      => isset($marked[$cid]) ? $marked[$cid] : '',
                );
            }

            $result['success']       = true;
            $result['session_label'] = $sessionLabel;
            $result['learners']      = $learners;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Upsert one or more (customer_id, status) rows for a given session.
     * POST: course_id, option_type_id, attendance (JSON: { customer_id: "present"|"absent", … })
     */
    public function saveAction()
    {
        $result = array('success' => false, 'updated' => 0);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $req = $this->getRequest();
            $courseId     = (int) $req->getParam('course_id');
            $optionTypeId = (int) $req->getParam('option_type_id');
            $attendanceIn = $req->getParam('attendance');
            if (!$courseId || !$optionTypeId) {
                throw new Exception('course_id and option_type_id are required');
            }
            if (is_string($attendanceIn)) {
                $attendance = json_decode($attendanceIn, true);
            } else {
                $attendance = $attendanceIn;
            }
            if (!is_array($attendance)) {
                throw new Exception('attendance must be an object of customer_id => status');
            }

            $resource = Mage::getSingleton('core/resource');
            $read  = $resource->getConnection('core_read');
            $write = $resource->getConnection('core_write');

            // Verify session belongs to course
            $belongs = $read->fetchOne(
                "SELECT 1 FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 WHERE ov.option_type_id = ? AND o.product_id = ?",
                array($optionTypeId, $courseId)
            );
            if (!$belongs) {
                throw new Exception('Session not found for this course');
            }

            $markedById = 0;
            try {
                $u = Mage::getSingleton('admin/session')->getUser();
                if ($u) $markedById = (int) $u->getId();
            } catch (Exception $e) {}

            $updated = 0;
            foreach ($attendance as $cid => $status) {
                $cid    = (int) $cid;
                $status = in_array($status, array('present', 'absent'), true) ? $status : 'absent';
                if (!$cid) continue;

                $existing = $read->fetchOne(
                    "SELECT id FROM course_attendance WHERE option_type_id = ? AND customer_id = ?",
                    array($optionTypeId, $cid)
                );
                if ($existing) {
                    $write->update('course_attendance', array(
                        'status'             => $status,
                        'marked_by_admin_id' => $markedById ?: null,
                    ), array('id = ?' => (int) $existing));
                } else {
                    $write->insert('course_attendance', array(
                        'option_type_id'     => $optionTypeId,
                        'customer_id'        => $cid,
                        'status'             => $status,
                        'marked_by_admin_id' => $markedById ?: null,
                    ));
                }
                $updated++;
            }

            $result['success'] = true;
            $result['updated'] = $updated;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    // generateTokenAction (E-Attendance link generator) and checkinAction
    // (the learner-side check-in endpoint hit by the QR code) were removed
    // 2026-05-06 along with the E-Attendance UI section. course_attendance_tokens
    // is dropped by migration 048-drop-attendance-tokens.sql in the same
    // change. The Manual Attendance flow (listAction / saveAction above)
    // and the course_attendance table it writes to are unaffected.

    protected function _sendJson(array $data)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($data));
    }

    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array(
            'training_provider', 'admin', 'trainer',
        ));
    }
}
