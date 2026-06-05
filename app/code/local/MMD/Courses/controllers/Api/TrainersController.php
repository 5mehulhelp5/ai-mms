<?php
/**
 * Public read-only API: trainer roster.
 *
 * GET /courses/api_trainers              → list of active trainers
 * GET /courses/api_trainers?id=<id>      → one trainer's profile
 * GET /courses/api_trainers?course=<sku> → trainers eligible for that course
 *
 * Auth: X-API-Key (same key as the other /courses/api_* endpoints).
 *
 * Data source: courses_trainers table (270+ rows, status=1 = active).
 * Trainer ↔ course eligibility comes from the product's `trainer_ids`
 * attribute (CSV of trainers_id values managed via CoursesaveController).
 *
 * CRITICAL: read-only. No outbound emails, no WhatsApp messages, no cron.
 * MMS does not initiate any contact with trainers via this controller —
 * any reminder/notification logic lives on the consumer's side (e.g. the
 * WhatsApp bot pulls this data and decides what to do with it).
 *
 * PII note: trainer email + telephone are included because the bot needs
 * them to send reminders / contact trainers. Endpoint is API-key gated;
 * do NOT make this public-facing without removing PII fields first.
 */
class MMD_Courses_Api_TrainersController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_PATH_API_KEY = 'courses/general/wsq_schedule_api_key';
    const SG_STORE_ID         = 1;

    public function indexAction()
    {
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        if ($expected === '') {
            return $this->_json(503, $this->_errEnvelope('api_disabled', 'API key not configured.'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, $this->_errEnvelope('unauthorized', 'Invalid or missing X-API-Key.'));
        }

        $id         = (int)    $this->getRequest()->getParam('id', 0);
        $courseSku  = trim((string) $this->getRequest()->getParam('course', ''));

        try {
            if ($id > 0) {
                return $this->_singleTrainer($id);
            }
            if ($courseSku !== '') {
                return $this->_trainersForCourse($courseSku);
            }
            return $this->_allTrainers();
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, $this->_errEnvelope('internal_error', $e->getMessage()));
        }
    }

    /**
     * Full active-trainer roster. Returned compact (no upcoming classes per
     * trainer — too expensive at list scale; bot can call ?id=X for that).
     */
    private function _allTrainers()
    {
        $rows = $this->_db()->fetchAll(
            "SELECT trainers_id, title, email, telephone, country_id, city,
                    trainer_type, area_of_expertise, linkedin_url
               FROM courses_trainers
              WHERE status = 1
              ORDER BY title ASC
              LIMIT 500"
        );
        $out = array();
        foreach ($rows as $r) {
            $out[] = $this->_compactTrainer($r);
        }
        return $this->_json(200, array(
            'source_url'   => 'https://www.tertiarycourses.com.sg/about',
            'last_updated' => gmdate('c'),
            'confidence'   => 'high',
            'data'         => array(
                'count'    => count($out),
                'trainers' => $out,
            ),
        ));
    }

    /**
     * Single trainer profile + their upcoming class schedule (joined via
     * course_run_trainer_invitations.latest-by-run because course_runs only
     * stores the accepted option_id, not the trainer_id directly).
     */
    private function _singleTrainer($id)
    {
        $row = $this->_db()->fetchRow(
            "SELECT trainers_id, title, email, telephone, address, city, zip,
                    country_id, region, description, trainer_type,
                    area_of_expertise, linkedin_url, profile_image, status
               FROM courses_trainers
              WHERE trainers_id = ?
              LIMIT 1",
            array($id)
        );
        if (!$row) {
            return $this->_json(404, $this->_errEnvelope('not_found',
                'No trainer with id=' . $id . ' in the trainer roster.'));
        }

        $upcoming = $this->_db()->fetchAll(
            "SELECT cr.run_id, cr.class_id, cr.course_sku, cr.course_start_date,
                    cr.course_end_date, cr.course_start_time, cr.course_end_time,
                    cr.mode_of_training, cr.venue_building
               FROM course_runs cr
         INNER JOIN course_run_trainer_invitations i
                 ON i.run_id = cr.run_id
                AND i.trainer_email = ?
                AND i.status IN ('accepted')
              WHERE cr.course_start_date >= CURDATE()
                AND cr.trainer_option_id IS NOT NULL
              ORDER BY cr.course_start_date ASC
              LIMIT 50",
            array((string) $row['email'])
        );

        return $this->_json(200, array(
            'source_url'   => 'https://www.tertiarycourses.com.sg/about',
            'last_updated' => gmdate('c'),
            'confidence'   => 'high',
            'data'         => array(
                'trainer' => $this->_fullTrainer($row),
                'upcoming_classes' => array_map(array($this, '_classRow'), $upcoming),
                'upcoming_classes_count' => count($upcoming),
            ),
        ));
    }

    /**
     * Trainers eligible to teach a specific course. Reads the product's
     * `trainer_ids` attribute (comma-separated trainers_id list, managed
     * via CoursesaveController). Empty/missing attribute → empty array.
     */
    private function _trainersForCourse($sku)
    {
        $product = Mage::getModel('catalog/product')->setStoreId(self::SG_STORE_ID)
            ->loadByAttribute('sku', $sku);
        if (!$product || !$product->getId()) {
            return $this->_json(404, $this->_errEnvelope('not_found',
                'No course with sku=' . $sku . ' in the SG catalog.'));
        }
        $ids = trim((string) $product->getData('trainer_ids'));
        if ($ids === '') {
            return $this->_json(200, array(
                'source_url'   => 'https://www.tertiarycourses.com.sg/',
                'last_updated' => gmdate('c'),
                'confidence'   => 'low',
                'data'         => array(
                    'course_sku'   => $sku,
                    'course_title' => (string) $product->getName(),
                    'count'        => 0,
                    'trainers'     => array(),
                    'message'      => 'No trainers are currently tagged as eligible for this course in the admin.',
                ),
            ));
        }
        $idList = array_filter(array_map('intval', explode(',', $ids)));
        if (empty($idList)) {
            $idList = array(0); // forces empty result rather than malformed SQL
        }
        $place = implode(',', $idList);
        $rows = $this->_db()->fetchAll(
            "SELECT trainers_id, title, email, telephone, country_id, city,
                    trainer_type, area_of_expertise, linkedin_url
               FROM courses_trainers
              WHERE trainers_id IN ($place)
                AND status = 1
              ORDER BY FIELD(trainers_id, $place)"
        );
        $out = array();
        foreach ($rows as $r) {
            $out[] = $this->_compactTrainer($r);
        }
        return $this->_json(200, array(
            'source_url'   => 'https://www.tertiarycourses.com.sg/',
            'last_updated' => gmdate('c'),
            'confidence'   => 'high',
            'data'         => array(
                'course_sku'   => $sku,
                'course_title' => (string) $product->getName(),
                'count'        => count($out),
                'trainers'     => $out,
            ),
        ));
    }

    private function _compactTrainer($r)
    {
        return array(
            'id'                => (int)    $r['trainers_id'],
            'name'              => (string) $r['title'],
            'email'             => (string) $r['email'],
            'telephone'         => (string) ($r['telephone'] ?? ''),
            'country'           => (string) ($r['country_id'] ?? ''),
            'city'              => (string) ($r['city'] ?? ''),
            'trainer_type'      => (string) ($r['trainer_type'] ?? ''),
            'area_of_expertise' => (string) ($r['area_of_expertise'] ?? ''),
            'linkedin'          => (string) ($r['linkedin_url'] ?? ''),
        );
    }

    private function _fullTrainer($r)
    {
        $out = $this->_compactTrainer($r);
        $out['address']     = trim((string) ($r['address'] ?? ''));
        $out['city']        = (string) ($r['city'] ?? '');
        $out['zip']         = (string) ($r['zip'] ?? '');
        $out['region']      = (string) ($r['region'] ?? '');
        $out['description'] = trim(strip_tags((string) ($r['description'] ?? '')));
        $out['active']      = (int) ($r['status'] ?? 0) === 1;
        $img = trim((string) ($r['profile_image'] ?? ''));
        $out['profile_image_url'] = $img !== '' ? 'https://www.tertiarycourses.com.sg/media/trainers/' . $img : '';
        return $out;
    }

    private function _classRow($r)
    {
        return array(
            'run_id'      => (int) $r['run_id'],
            'class_id'    => (string) ($r['class_id'] ?? ''),
            'course_sku'  => (string) $r['course_sku'],
            'start_date'  => $r['course_start_date'] ?: null,
            'end_date'    => $r['course_end_date']   ?: null,
            'start_time'  => $r['course_start_time'] ?: null,
            'end_time'    => $r['course_end_time']   ?: null,
            'mode'        => $this->_modeLabel($r['mode_of_training']),
            'venue'       => trim((string) ($r['venue_building'] ?? '')) ?: null,
        );
    }

    private function _modeLabel($v)
    {
        switch ((int) $v) {
            case 2: return 'Live Online';
            case 3: return 'Hybrid (Classroom + Online)';
            default: return 'Classroom';
        }
    }

    private function _db()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_read');
    }

    private function _errEnvelope($code, $message)
    {
        return array(
            'source_url'   => null,
            'last_updated' => gmdate('c'),
            'confidence'   => 'error',
            'error'        => $code,
            'message'      => $message,
        );
    }

    private function _json($status, array $body)
    {
        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setHeader('Cache-Control', 'public, max-age=300', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $this;
    }
}
