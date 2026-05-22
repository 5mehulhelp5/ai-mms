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

    /** Auto-reply config paths + file-template fallback code. */
    const XML_PATH_AUTO_REPLY_ENABLED  = 'mmd_leads/auto_reply/enabled';
    const XML_PATH_AUTO_REPLY_TEMPLATE = 'mmd_leads/auto_reply/email_template';
    const XML_PATH_AUTO_REPLY_CC       = 'mmd_leads/auto_reply/cc';
    const AUTO_REPLY_TEMPLATE_FALLBACK = 'mmd_leads_auto_reply';

    /**
     * WSQ course recommender. WSQ/SkillsFuture courses carry a TGS code as
     * their SKU (e.g. TGS-2024045801); the recommendation pool is exactly
     * those. MIN_RECOMMEND_SCORE is the minimum keyword score a course must
     * reach to be recommended — below it the auto-reply shows the generic
     * catalogue fallback instead of a weak guess.
     */
    const WSQ_SKU_PREFIX          = 'TGS-';
    const MIN_RECOMMEND_SCORE     = 3;
    const MYSKILLSFUTURE_COURSE_URL = 'https://www.myskillsfuture.gov.sg/content/portal/en/training-exchange/course-directory/course-detail.html?courseReference=';

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
     * Send the automatic acknowledgement email to a freshly-captured lead
     * and record the outcome on the lead row (auto_reply_status /
     * auto_replied_at). Called from MMD_MagentoCaptcha_IndexController right
     * after the lead is saved.
     *
     * Never throws — a delivery problem must not break the contact-form
     * flow (the visitor already saw the success message and the staff
     * notification already went out). Failures are logged and surface in
     * the Tertiary -> Leads grid as auto_reply_status = 'failed'.
     *
     * @param  MMD_Leads_Model_Lead $lead
     * @return bool  true when the acknowledgement was sent
     */
    public function sendAutoReply(MMD_Leads_Model_Lead $lead)
    {
        if (!$lead->getId()) {
            return false;
        }

        $storeId = (int) $lead->getStoreId();

        // Per-store kill-switch — lets ops disable auto-replies without a deploy.
        if (!Mage::getStoreConfigFlag(self::XML_PATH_AUTO_REPLY_ENABLED, $storeId)) {
            $this->_setAutoReplyStatus($lead, MMD_Leads_Model_Lead::AUTO_REPLY_SKIPPED);
            return false;
        }

        try {
            $template = Mage::getStoreConfig(self::XML_PATH_AUTO_REPLY_TEMPLATE, $storeId)
                ?: self::AUTO_REPLY_TEMPLATE_FALLBACK;

            $mail = Mage::getModel('core/email_template');
            /** @var Mage_Core_Model_Email_Template $mail */
            $mail->setDesignConfig(array('area' => 'frontend', 'store' => $storeId));

            // CC the training team on every auto-reply so they see exactly
            // what the visitor was sent. addCc() on the underlying Zend_Mail
            // is set before send() — which only re-adds To/Bcc and never
            // clears Cc — so the header survives into the dispatched message.
            foreach ($this->_getAutoReplyCc($storeId) as $cc) {
                $mail->getMail()->addCc($cc);
            }

            $mail->sendTransactional(
                $template,
                $this->getReplySender($storeId),
                $lead->getEmail(),
                $lead->getName(),
                array(
                    'lead_name'        => $this->getFirstName($lead->getName()),
                    'course_info_html' => $this->buildCourseInfoHtml($lead),
                    'contact_html'     => $this->buildContactHtml($lead),
                ),
                $storeId
            );

            if (!$mail->getSentSuccess()) {
                Mage::throwException('Auto-reply send returned no success flag.');
            }

            $lead->setAutoReplyStatus(MMD_Leads_Model_Lead::AUTO_REPLY_SENT)
                 ->setAutoRepliedAt(Varien_Date::now())
                 ->save();
            return true;
        } catch (Exception $e) {
            Mage::logException($e);
            $this->_setAutoReplyStatus($lead, MMD_Leads_Model_Lead::AUTO_REPLY_FAILED);
            return false;
        }
    }

    /**
     * Build the {{var course_info_html}} block for the auto-reply.
     *
     * When the recommender finds a WSQ course, renders the structured
     * recommendation (title / code / link / MySkillsFuture portal) plus the
     * WSQ subsidy note. Otherwise (no confident match, or a non-Singapore
     * store) returns the generic catalogue fallback.
     *
     * @param  MMD_Leads_Model_Lead $lead
     * @return string  HTML fragment
     */
    public function buildCourseInfoHtml(MMD_Leads_Model_Lead $lead)
    {
        $rec = $this->recommendCourse($lead);

        if (!$rec) {
            $storeId    = (int) $lead->getStoreId();
            $catalogUrl = Mage::app()->getStore($storeId ?: null)->getBaseUrl();
            return '<p style="margin:0 0 14px;">Our training consultants will personally follow up to '
                . 'recommend the best-fit course for your goals. In the meantime, you are welcome to '
                . 'browse our full course catalogue here: '
                . '<a href="' . $catalogUrl . '" style="color:#2563eb;">' . $catalogUrl . '</a></p>';
        }

        $title = $this->escapeHtml($rec['title']);
        $code  = $this->escapeHtml($rec['code']);
        $url   = $this->escapeHtml($rec['url']);
        $msf   = $this->escapeHtml($rec['myskillsfuture_url']);

        return '<p style="margin:0 0 12px;">We recommend the following WSQ course based on your query:</p>'
            . '<table cellpadding="0" cellspacing="0" border="0" width="100%" '
            . 'style="margin:0 0 14px; border:1px solid #e2e8f0; border-radius:8px; background:#f8fafc;">'
            . '<tr><td style="padding:16px 18px; font-size:14px; line-height:1.6; color:#0f172a;">'
            . '<div style="margin-bottom:4px;"><strong>Course Title:</strong> ' . $title . '</div>'
            . '<div style="margin-bottom:4px;"><strong>Course Code:</strong> ' . $code . '</div>'
            . '<div style="margin-bottom:4px;"><strong>Course Link:</strong> '
            . '<a href="' . $url . '" style="color:#2563eb;">' . $url . '</a></div>'
            . '<div><strong>Apply now at MySkillsFuture Portal:</strong> '
            . '<a href="' . $msf . '" style="color:#2563eb;">' . $msf . '</a></div>'
            . '</td></tr></table>'
            . '<p style="margin:0 0 12px;">You can find more information about the course, such as the '
            . 'course info and available course run dates, on the link above.</p>'
            . '<p style="margin:0 0 14px;">No upfront payment is required when registering. We will apply '
            . 'the Workforce Skills Qualifications (WSQ) subsidy on your behalf, and you may use your '
            . 'SkillsFuture Singapore Credit to offset the remaining course fee.</p>';
    }

    /**
     * Build the {{var contact_html}} closing block. Singapore leads get the
     * SG hotline + WhatsApp; other stores get a generic "reply to this email".
     *
     * @param  MMD_Leads_Model_Lead $lead
     * @return string  HTML fragment
     */
    public function buildContactHtml(MMD_Leads_Model_Lead $lead)
    {
        if ($this->_isSingaporeStore((int) $lead->getStoreId())) {
            return '<p style="margin:0 0 14px;">If you have any questions or need assistance on course '
                . 'registration, please don\'t hesitate to reach out to us at '
                . '<a href="tel:+6561000613" style="color:#2563eb;">6100 0613</a> or WhatsApp us at '
                . '<a href="https://wa.me/6588666375" style="color:#2563eb;">https://wa.me/6588666375</a>.</p>';
        }

        return '<p style="margin:0 0 14px;">If you have any questions or need assistance on course '
            . 'registration, simply reply to this email and our training consultants will be glad to help.</p>';
    }

    /**
     * Recommend the single most relevant WSQ course for a lead.
     *
     * WSQ recommendations are Singapore-only (TGS codes / SkillsFuture
     * portal). Strategy:
     *   1. An explicit Course Code on the form is an exact SKU match — wins.
     *   2. Otherwise score the WSQ catalogue by keyword/synonym relevance
     *      against the interested-course text + message.
     *
     * @param  MMD_Leads_Model_Lead $lead
     * @return array|null  {title, code, url, myskillsfuture_url} or null
     */
    public function recommendCourse(MMD_Leads_Model_Lead $lead)
    {
        $storeId = (int) $lead->getStoreId();
        if (!$this->_isSingaporeStore($storeId)) {
            return null;
        }

        $code = trim((string) $lead->getCourseCode());
        if ($code !== '') {
            $product = $this->_findWsqByCode($code, $storeId);
            if ($product) {
                return $this->_buildRecommendation($product);
            }
        }

        $text    = trim($lead->getCoursesInterested() . ' ' . $lead->getComment() . ' ' . $code);
        $product = $this->_scoreWsqCourses($text, $storeId);
        return $product ? $this->_buildRecommendation($product) : null;
    }

    /**
     * Shape a catalog product into the recommendation payload. For WSQ
     * courses the SKU *is* the SkillsFuture TGS course reference.
     */
    protected function _buildRecommendation($product)
    {
        $sku = (string) $product->getSku();
        return array(
            'title'              => (string) $product->getName(),
            'code'               => $sku,
            'url'                => $product->getProductUrl(),
            'myskillsfuture_url' => self::MYSKILLSFUTURE_COURSE_URL . rawurlencode($sku),
        );
    }

    /**
     * Exact-ish WSQ lookup by course code. Matches the code anywhere in a
     * TGS- SKU, so "TGS-2024045801" and the bare "2024045801" both resolve.
     *
     * @return Mage_Catalog_Model_Product|null
     */
    protected function _findWsqByCode($code, $storeId)
    {
        $code = strtoupper(trim($code));
        if ($code === '') {
            return null;
        }

        $collection = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId($storeId)
            ->addAttributeToSelect(array('name', 'sku', 'url_key'))
            ->addAttributeToFilter('sku', array('like' => self::WSQ_SKU_PREFIX . '%'))
            ->addAttributeToFilter('sku', array('like' => '%' . $code . '%'))
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)
            ->addAttributeToFilter('visibility', array('neq' => Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE))
            ->setPageSize(1);

        foreach ($collection as $product) {
            return $product;
        }
        return null;
    }

    /**
     * Score the whole WSQ catalogue against an enquiry and return the best
     * match, or null when nothing clears MIN_RECOMMEND_SCORE.
     *
     * Scoring: a raw enquiry word matched as a whole word in the course name
     * scores 3; a synonym-expanded concept keyword matched as a substring
     * scores 1. So "Claude Code" (no literal catalogue hit) still resolves
     * via its expansions {ai, agentic, coding, vibe} to an Agentic AI course.
     *
     * @return Mage_Catalog_Model_Product|null
     */
    protected function _scoreWsqCourses($text, $storeId)
    {
        $keywords = $this->_extractKeywords($text);
        if (empty($keywords['raw']) && empty($keywords['expanded'])) {
            return null;
        }

        $collection = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId($storeId)
            ->addAttributeToSelect(array('name', 'sku', 'url_key'))
            ->addAttributeToFilter('sku', array('like' => self::WSQ_SKU_PREFIX . '%'))
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)
            ->addAttributeToFilter('visibility', array('neq' => Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE));

        $best = null;
        $bestScore = 0;
        foreach ($collection as $product) {
            $name  = strtolower((string) $product->getName());
            $score = 0;
            foreach ($keywords['raw'] as $word) {
                if (preg_match('/\b' . preg_quote($word, '/') . '\b/', $name)) {
                    $score += 3;
                }
            }
            foreach ($keywords['expanded'] as $concept) {
                if (strpos($name, $concept) !== false) {
                    $score += 1;
                }
            }
            if ($score > $bestScore) {
                $bestScore = $score;
                $best = $product;
            }
        }

        return ($bestScore >= self::MIN_RECOMMEND_SCORE) ? $best : null;
    }

    /**
     * Turn enquiry text into matchable keywords: cleaned raw words plus
     * synonym-expanded concept keywords (see _synonymMap).
     *
     * @return array{raw:string[], expanded:string[]}
     */
    protected function _extractKeywords($text)
    {
        $parts = preg_split('/[^a-z0-9]+/', strtolower((string) $text)) ?: array();
        $keepShort = array('ai', 'ml', 'ux', 'ui', 'vr', 'ar', 'bi', '3d');
        $stop = array(
            'and', 'the', 'for', 'with', 'how', 'can', 'you', 'are', 'our', 'your',
            'please', 'course', 'courses', 'class', 'classes', 'training', 'trainings',
            'about', 'info', 'information', 'interested', 'interest', 'want', 'would',
            'like', 'know', 'more', 'this', 'that', 'need', 'looking', 'learn', 'learning',
            'enquiry', 'enquire', 'register', 'registration', 'have', 'any', 'some',
            'will', 'from', 'into', 'what', 'when', 'where', 'which', 'pls', 'kindly',
        );

        $raw = array();
        foreach ($parts as $word) {
            $word = trim($word);
            if ($word === '' || $word === 'wsq' || $word === 'tgs') {
                continue;
            }
            if (strlen($word) < self::MIN_TOKEN_LEN && !in_array($word, $keepShort, true)) {
                continue;
            }
            if (in_array($word, $stop, true)) {
                continue;
            }
            $raw[$word] = $word;
        }

        $map = $this->_synonymMap();
        $expanded = array();
        foreach ($raw as $word) {
            if (isset($map[$word])) {
                foreach ($map[$word] as $concept) {
                    $expanded[$concept] = $concept;
                }
            }
        }

        return array('raw' => array_values($raw), 'expanded' => array_values($expanded));
    }

    /**
     * Synonym map: an enquiry word -> concept keywords that actually appear
     * in WSQ course names. Lets the recommender bridge tool/brand names
     * (Claude, Copilot, ChatGPT, n8n, …) to the courses that teach them.
     */
    protected function _synonymMap()
    {
        return array(
            // AI assistants / LLM tools -> AI + agentic + vibe coding
            'claude'      => array('ai', 'agentic', 'coding', 'vibe'),
            'chatgpt'     => array('ai', 'chatgpt', 'generative', 'prompt'),
            'gpt'         => array('ai', 'generative'),
            'openai'      => array('ai', 'generative'),
            'copilot'     => array('ai', 'coding', 'vibe'),
            'cursor'      => array('ai', 'coding', 'vibe'),
            'codex'       => array('ai', 'coding', 'vibe'),
            'gemini'      => array('ai', 'generative'),
            'llm'         => array('ai', 'generative', 'nlp'),
            'genai'       => array('ai', 'generative'),
            'chatbot'     => array('ai', 'chatbot', 'agent'),
            'bot'         => array('agent', 'automation'),
            'prompt'      => array('prompt', 'generative', 'ai'),
            // Agents / automation
            'agent'       => array('agentic', 'ai', 'automation'),
            'agents'      => array('agentic', 'ai', 'automation'),
            'agentic'     => array('agentic', 'ai'),
            'automation'  => array('automation', 'agentic', 'workflow'),
            'automate'    => array('automation', 'agentic'),
            'workflow'    => array('workflow', 'automation', 'agentic'),
            'workflows'   => array('workflow', 'automation', 'agentic'),
            'n8n'         => array('n8n', 'automation', 'agentic'),
            'zapier'      => array('automation', 'agentic'),
            'rpa'         => array('automation'),
            'langflow'    => array('agentic', 'ai', 'langflow'),
            'flowise'     => array('agentic', 'ai', 'flowise'),
            // Coding
            'vibe'        => array('vibe', 'coding'),
            'coding'      => array('coding', 'vibe', 'programming'),
            'code'        => array('coding', 'programming'),
            'program'     => array('programming', 'coding'),
            'programming' => array('programming', 'coding'),
            'developer'   => array('coding', 'web', 'app'),
            'fullstack'   => array('full stack', 'web', 'coding'),
            'python'      => array('python', 'programming'),
            'javascript'  => array('javascript', 'web', 'coding'),
            'react'       => array('react', 'web', 'app'),
            'flutter'     => array('flutter', 'app', 'mobile'),
            // Data / ML
            'machine'     => array('machine learning', 'ai'),
            'learning'    => array('machine learning'),
            'ml'          => array('machine learning', 'ai'),
            'deep'        => array('deep learning', 'ai'),
            'data'        => array('data', 'analytics'),
            'analytics'   => array('analytics', 'data'),
            'analysis'    => array('analytics', 'data'),
            'tensorflow'  => array('tensorflow', 'machine learning'),
            'pytorch'     => array('pytorch', 'machine learning'),
            'powerbi'     => array('power bi', 'analytics'),
            'tableau'     => array('tableau', 'analytics'),
            'excel'       => array('excel', 'spreadsheet'),
            'sql'         => array('sql', 'database'),
            'statistics'  => array('statistics', 'data'),
            // Web / app / cloud
            'web'         => array('web', 'app'),
            'website'     => array('web'),
            'app'         => array('app', 'web'),
            'apps'        => array('app', 'web'),
            'mobile'      => array('app', 'mobile'),
            'cloud'       => array('cloud', 'aws'),
            'aws'         => array('aws', 'cloud'),
            'bedrock'     => array('aws', 'ai', 'generative'),
            // Security
            'cyber'         => array('cybersecurity', 'security'),
            'cybersecurity' => array('cybersecurity', 'security'),
            'security'      => array('cybersecurity', 'security'),
            // Marketing
            'marketing'   => array('marketing', 'digital marketing'),
            'digital'     => array('digital marketing', 'marketing'),
            'seo'         => array('seo', 'marketing'),
            'social'      => array('social media', 'marketing'),
            'ads'         => array('ads', 'marketing'),
            'ppc'         => array('ppc', 'ads', 'marketing'),
            // Design / media
            'design'      => array('design', 'ui'),
            'ui'          => array('ui', 'design'),
            'ux'          => array('ux', 'design'),
            'image'       => array('image', 'generative'),
            'video'       => array('video', 'generative'),
            'graphic'     => array('design', 'graphic'),
            // Emerging tech
            'blockchain'  => array('blockchain', 'web3'),
            'web3'        => array('web3', 'blockchain'),
            'crypto'      => array('blockchain', 'web3'),
        );
    }

    /**
     * Whether a store id is the Singapore storefront (WSQ recommendations
     * and the SG contact block are Singapore-only).
     */
    protected function _isSingaporeStore($storeId)
    {
        try {
            return Mage::app()->getStore($storeId)->getCode() === 'singapore';
        } catch (Exception $e) {
            return false;
        }
    }

    /**
     * First word of a name, for an informal "Dear <first name>," greeting.
     */
    public function getFirstName($name)
    {
        $name = trim((string) $name);
        if ($name === '') {
            return $this->__('Learner');
        }
        $parts = preg_split('/\s+/', $name) ?: array($name);
        return $parts[0];
    }

    /**
     * Persist an auto_reply_status onto the lead without letting a save
     * error bubble up into the contact-form flow.
     */
    protected function _setAutoReplyStatus(MMD_Leads_Model_Lead $lead, $status)
    {
        try {
            $lead->setAutoReplyStatus($status)->save();
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /**
     * CC addresses for the auto-reply, from mmd_leads/auto_reply/cc
     * (comma/semicolon-separated). The training team is copied so they see
     * what each visitor was sent.
     *
     * @return string[]
     */
    protected function _getAutoReplyCc($storeId)
    {
        $raw = (string) Mage::getStoreConfig(self::XML_PATH_AUTO_REPLY_CC, $storeId);
        if (trim($raw) === '') {
            return array();
        }
        return array_values(array_unique(array_filter(array_map(
            'trim',
            preg_split('/[,;]+/', $raw) ?: array()
        ))));
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
