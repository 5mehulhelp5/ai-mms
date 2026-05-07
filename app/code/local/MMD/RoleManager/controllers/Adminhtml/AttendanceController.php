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

    /**
     * Aggregate endpoint for the trainer's E-Attendance dashboard. Given a
     * course_id, returns the list of sessions (custom-option dropdowns) and
     * the list of enrolments (orders for that course). Used by the
     * standalone E-Attendance page reachable from the trainer top bar.
     *
     * GET: course_id
     * Returns JSON:
     *   {
     *     success: true,
     *     sessions:   [ { option_type_id, title } ],
     *     enrolments: [ {
     *       no, order_id, order_no, run_id, start_date, end_date,
     *       trainee_name, nric, contact, email, sponsorship,
     *       employer, status
     *     } ],
     *   }
     */
    public function classInfoAction()
    {
        $result = array('success' => false, 'sessions' => array(), 'enrolments' => array());
        try {
            $courseId = (int) $this->getRequest()->getParam('course_id');
            if (!$courseId) throw new Exception('course_id is required');

            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');

            // Sessions: catalog custom options of type 'Course Date' (or any
            // option title containing 'Date') — these are the per-run
            // dropdown values learners pick when they enrol.
            $sessions = $read->fetchAll(
                "SELECT ov.option_type_id, ott.title
                 FROM catalog_product_option o
                 JOIN catalog_product_option_title ot       ON ot.option_id = o.option_id  AND ot.store_id = 0
                 JOIN catalog_product_option_type_value ov  ON ov.option_id = o.option_id
                 JOIN catalog_product_option_type_title ott ON ott.option_type_id = ov.option_type_id AND ott.store_id = 0
                 WHERE o.product_id = ? AND (ot.title = 'Course Date' OR ot.title LIKE '%Date%')
                 ORDER BY ott.title",
                array($courseId)
            );
            foreach ($sessions as $s) {
                $result['sessions'][] = array(
                    'option_type_id' => (int)$s['option_type_id'],
                    'title'          => (string)$s['title'],
                );
            }

            // Enrolments: every order line for this product. Customer EAV
            // stores firstname/lastname/telephone separately; NRIC and
            // sponsorship/employer are custom attributes on the order item
            // (varies per project — best effort, fall back to em-dashes).
            $fnAttr = (int) $read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=1 AND attribute_code='firstname'");
            $lnAttr = (int) $read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=1 AND attribute_code='lastname'");
            $phAttr = (int) $read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=1 AND attribute_code='telephone'");
            $nricAttr = (int) $read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=1 AND attribute_code='nric'");
            $sponAttr = (int) $read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=1 AND attribute_code='sponsorship'");
            $emplAttr = (int) $read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE entity_type_id=1 AND attribute_code='employer'");

            $orderTbl = $resource->getTableName('sales/order');
            $itemTbl  = $resource->getTableName('sales/order_item');
            $custVc   = $resource->getTableName('customer/entity_varchar');
            $custEnt  = $resource->getTableName('customer/entity');

            $rows = $read->fetchAll(
                "SELECT o.entity_id AS order_id, o.increment_id, o.created_at, o.status,
                        o.customer_id, o.customer_email, o.customer_firstname, o.customer_lastname,
                        oi.item_id, oi.product_options
                 FROM {$itemTbl} oi
                 JOIN {$orderTbl} o ON o.entity_id = oi.order_id
                 WHERE oi.product_id = ?
                 ORDER BY o.created_at DESC",
                array($courseId)
            );

            // Lookup dates from course_runs (for run_id + start/end dates)
            $runs = $read->fetchAll("SELECT * FROM course_runs WHERE product_id = ?", array($courseId));
            $runByDate = array();
            foreach ($runs as $r) $runByDate[$r['run_id']] = $r;

            $no = 0;
            foreach ($rows as $r) {
                $no++;
                $custId = (int)$r['customer_id'];
                $first = $r['customer_firstname']; $last = $r['customer_lastname'];
                $phone = $nric = $spon = $empl = '';
                if ($custId) {
                    if (!$first || !$last) {
                        if ($fnAttr) $first = (string)$read->fetchOne("SELECT value FROM {$custVc} WHERE entity_id=? AND attribute_id=?", array($custId, $fnAttr));
                        if ($lnAttr) $last  = (string)$read->fetchOne("SELECT value FROM {$custVc} WHERE entity_id=? AND attribute_id=?", array($custId, $lnAttr));
                    }
                    if ($phAttr)   $phone = (string)$read->fetchOne("SELECT value FROM {$custVc} WHERE entity_id=? AND attribute_id=?", array($custId, $phAttr));
                    if ($nricAttr) $nric  = (string)$read->fetchOne("SELECT value FROM {$custVc} WHERE entity_id=? AND attribute_id=?", array($custId, $nricAttr));
                    if ($sponAttr) $spon  = (string)$read->fetchOne("SELECT value FROM {$custVc} WHERE entity_id=? AND attribute_id=?", array($custId, $sponAttr));
                    if ($emplAttr) $empl  = (string)$read->fetchOne("SELECT value FROM {$custVc} WHERE entity_id=? AND attribute_id=?", array($custId, $emplAttr));
                }
                $name = trim($first . ' ' . $last);
                if ($name === '') $name = (string)$r['customer_email'];

                $result['enrolments'][] = array(
                    'no'           => $no,
                    'order_id'     => (int)$r['order_id'],
                    'order_no'     => (string)$r['increment_id'],
                    'run_id'       => '',
                    'start_date'   => '',
                    'end_date'     => '',
                    'enrolment_ref'=> 'EN-' . str_pad((string)$r['item_id'], 6, '0', STR_PAD_LEFT),
                    'trainee_name' => $name,
                    'nric'         => $nric ?: '—',
                    'contact'      => $phone ?: '—',
                    'email'        => (string)$r['customer_email'],
                    'sponsorship'  => $spon ?: '—',
                    'employer'     => $empl ?: '—',
                    'status'       => ucwords(str_replace('_', ' ', (string)$r['status'])),
                );
            }

            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

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
