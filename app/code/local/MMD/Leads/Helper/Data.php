<?php
/**
 * Helpers for the Leads module:
 *
 *   - matchCourses($text, $storeId): turn a free-text "courses interested"
 *     string into a list of matched catalog products scoped to the lead's
 *     source store. Used by the reply form to pre-fill course title / SKU /
 *     next schedule / registration URL. If no match, returns [].
 *
 *   - buildReplyPlaceholders($lead): assemble the {{var ...}} payload that
 *     the mmd_leads_course_reply email template renders.
 *
 * Matching is intentionally simple — token-LIKE against catalog_product_entity
 * name + sku, capped at 3 results. Good enough for the typical lead message
 * ("Python and ChatGPT") without dragging in a full-text index.
 */
class MMD_Leads_Helper_Data extends Mage_Core_Helper_Abstract
{
    const MAX_MATCHES = 3;
    const MIN_TOKEN_LEN = 3;

    /**
     * @param string $text     Lead's "courses_interested" + "comment" payload
     * @param int    $storeId  Source store id (so URLs resolve to the right domain)
     * @return Mage_Catalog_Model_Resource_Product_Collection|null
     */
    public function matchCourses($text, $storeId)
    {
        $tokens = $this->_tokenize((string) $text);
        if (empty($tokens)) {
            return null;
        }

        $collection = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId($storeId ?: Mage::app()->getStore()->getId())
            ->addAttributeToSelect(array('name', 'sku', 'url_key', 'status', 'visibility'))
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)
            ->addAttributeToFilter('visibility', array('neq' => Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE))
            ->setPageSize(self::MAX_MATCHES);

        // OR across name / sku for any token. Plenty of false positives possible —
        // operator reviews + edits before sending, so precision > recall.
        $orWhere = array();
        foreach ($tokens as $t) {
            $like = '%' . $t . '%';
            $collection->addAttributeToFilter(array(
                array('attribute' => 'name', 'like' => $like),
                array('attribute' => 'sku',  'like' => $like),
            ));
        }

        return $collection;
    }

    /**
     * @return array{course_title:string, course_code:string, course_schedule:string, course_url:string}
     */
    public function buildCourseSnippet($product, $storeId)
    {
        $title = (string) $product->getName();
        $code  = (string) $product->getSku();
        $url   = $product->getProductUrl();

        // Next schedule = next future special_from_date OR custom event_date,
        // depending on what the catalog uses. We try a few likely attribute
        // codes and fall back to "Contact us for upcoming dates" so the
        // operator can fill it in.
        $schedule = '';
        foreach (array('event_date', 'next_schedule', 'course_date', 'special_from_date') as $attr) {
            $val = $product->getData($attr);
            if ($val && $val !== '0000-00-00 00:00:00') {
                $ts = strtotime($val);
                if ($ts && $ts >= strtotime('today')) {
                    $schedule = date('D, j M Y', $ts);
                    break;
                }
            }
        }
        if ($schedule === '') {
            $schedule = $this->__('Please contact us for upcoming dates.');
        }

        return array(
            'course_title'    => $title,
            'course_code'     => $code,
            'course_schedule' => $schedule,
            'course_url'      => $url,
        );
    }

    /**
     * Pretty store label for the grid + reply email.
     */
    public function getStoreLabel($storeId)
    {
        if (!$storeId) {
            return $this->__('Admin');
        }
        try {
            $store = Mage::app()->getStore($storeId);
            return $store->getName() . ' (' . $store->getCode() . ')';
        } catch (Exception $e) {
            return '#' . $storeId;
        }
    }

    /**
     * Resolve recipient + sender for the auto-reply. We send FROM the
     * source store's "General Contact" identity (the Reply-To observer in
     * MMD_Email also kicks in here, so customer replies route correctly).
     */
    public function getReplySender($storeId)
    {
        return Mage::getStoreConfig('contacts/email/sender_email_identity', $storeId)
            ?: 'general';
    }

    /**
     * Tokenize lead text into LIKE-friendly fragments. Strips stop words,
     * collapses whitespace, lowercases. Drops anything shorter than 3 chars
     * to avoid matching e.g. "AI" against every product name.
     */
    protected function _tokenize($text)
    {
        $text = strtolower(preg_replace('/[^a-z0-9\s\-]/i', ' ', $text));
        $parts = preg_split('/\s+/', $text) ?: array();
        $stop = array(
            'and', 'the', 'for', 'with', 'how', 'can', 'you', 'are',
            'please', 'course', 'courses', 'class', 'classes', 'training',
            'about', 'info', 'information', 'interested', 'want', 'would',
            'like', 'know', 'more', 'this', 'that',
        );
        $out = array();
        foreach ($parts as $p) {
            $p = trim($p);
            if (strlen($p) < self::MIN_TOKEN_LEN) continue;
            if (in_array($p, $stop, true)) continue;
            $out[$p] = $p;
        }
        return array_values($out);
    }
}
