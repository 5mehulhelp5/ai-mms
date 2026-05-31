<?php
/**
 * Public read-only API: WSQ course schedules.
 *
 * GET /courses/api_schedule
 *   Header:  X-API-Key: <shared secret>
 *   Returns: JSON list of every enabled TGS- product in the SG store with its
 *            "Course Date" custom-option values, parsed to ISO start/end dates.
 *
 * Auth: X-API-Key header compared against System Config
 *       courses/general/wsq_schedule_api_key (admin scope). Mismatch → 401.
 *       Blank stored key disables the endpoint (503) so a misconfigured
 *       prod cannot leak silently.
 *
 * Scope: SG store (store_id=1). WSQ is SG-only per CLAUDE.md.
 */
class MMD_Courses_Api_ScheduleController extends Mage_Core_Controller_Front_Action
{
    const SG_STORE_ID = 1;
    const CONFIG_PATH_API_KEY = 'courses/general/wsq_schedule_api_key';
    const COURSE_DATE_OPTION_TITLE = 'Course Date';

    public function indexAction()
    {
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        if ($expected === '') {
            return $this->_json(503, array('error' => 'api_disabled'));
        }

        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, array('error' => 'unauthorized'));
        }

        try {
            $courses = $this->_collectCourses();
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, array('error' => 'internal_error'));
        }

        return $this->_json(200, array(
            'generated_at' => gmdate('c'),
            'store'        => 'singapore',
            'count'        => count($courses),
            'courses'      => $courses,
        ));
    }

    private function _collectCourses()
    {
        $parser = Mage::getModel('mmd_rolemanager/courseRunEnrolmentService');
        if (!$parser) {
            Mage::throwException('CourseRunEnrolmentService model not available');
        }

        $collection = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId(self::SG_STORE_ID)
            ->addStoreFilter(self::SG_STORE_ID)
            ->addAttributeToSelect(array('name', 'sku'))
            ->addAttributeToFilter('sku', array('like' => 'TGS-%'))
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED);

        $out = array();
        foreach ($collection as $product) {
            $product->setStoreId(self::SG_STORE_ID);
            $schedules = $this->_extractSchedules($product, $parser);
            $out[] = array(
                'course_code'  => $product->getSku(),
                'course_title' => $product->getName(),
                'schedules'    => $schedules,
            );
        }
        return $out;
    }

    private function _extractSchedules($product, $parser)
    {
        $options = Mage::getModel('catalog/product_option')->getCollection()
            ->addProductToFilter($product->getId())
            ->addTitleToResult(self::SG_STORE_ID)
            ->addValuesToResult(self::SG_STORE_ID);

        $schedules = array();
        foreach ($options as $option) {
            if (strcasecmp(trim((string) $option->getTitle()), self::COURSE_DATE_OPTION_TITLE) !== 0) {
                continue;
            }
            foreach ($option->getValues() as $value) {
                $label = trim((string) $value->getTitle());
                if ($label === '') {
                    continue;
                }
                $entry = array(
                    'raw'               => $label,
                    'course_start_date' => null,
                    'course_end_date'   => null,
                );
                $parsed = $parser->_parseDate($label);
                if (!is_array($parsed) || empty($parsed[0]) || empty($parsed[1])) {
                    $parsed = $this->_parseCrossMonthRange($label);
                }
                if (is_array($parsed) && !empty($parsed[0]) && !empty($parsed[1])) {
                    $entry['course_start_date'] = $parsed[0];
                    $entry['course_end_date']   = $parsed[1];
                }
                $schedules[] = $entry;
            }
        }
        return $schedules;
    }

    /**
     * Fallback parser for "DD Mon - DD Mon YYYY" cross-month hyphen ranges
     * (e.g. "29 Jun - 3 Jul 2026"). Upstream _parseDate handles only same-month
     * hyphen ranges, so this catches the most common remaining WSQ label shape.
     * Strips trailing "(...)" annotations before matching.
     */
    private function _parseCrossMonthRange($raw)
    {
        $s = trim(preg_replace('/\s*\([^)]*\)?\s*$/', '', (string) $raw));
        if (!preg_match('/^(\d{1,2})\s+([A-Za-z]+)\s*-\s*(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$/', $s, $m)) {
            return null;
        }
        $months = array(
            'jan'=>1,'feb'=>2,'mar'=>3,'apr'=>4,'may'=>5,'jun'=>6,'june'=>6,
            'jul'=>7,'july'=>7,'aug'=>8,'sep'=>9,'sept'=>9,'oct'=>10,'nov'=>11,'dec'=>12,
        );
        $ms = $months[strtolower(substr($m[2], 0, 4))] ?? $months[strtolower(substr($m[2], 0, 3))] ?? null;
        $me = $months[strtolower(substr($m[4], 0, 4))] ?? $months[strtolower(substr($m[4], 0, 3))] ?? null;
        if (!$ms || !$me) return null;
        $year = (int) $m[5];
        $startYear = ($me < $ms) ? $year - 1 : $year;  // crosses Jan boundary
        $start = sprintf('%04d-%02d-%02d', $startYear, $ms, (int) $m[1]);
        $end   = sprintf('%04d-%02d-%02d', $year,      $me, (int) $m[3]);
        return array($start, $end);
    }

    private function _json($status, array $body)
    {
        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setHeader('Cache-Control', 'no-store', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $this;
    }
}
