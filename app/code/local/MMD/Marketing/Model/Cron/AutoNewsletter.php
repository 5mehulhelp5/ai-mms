<?php
/**
 * Weekly auto-newsletter cron job (SG only for v1).
 *
 * Picks a random Singapore course, asks Claude to write 3 short paragraphs
 * about it, renders an email-safe HTML template, pushes the campaign to
 * MailerLite, and schedules it to send `send_delay_hours` after creation.
 *
 * Wired by app/code/local/MMD/Marketing/etc/config.xml:
 *   <crontab><jobs>
 *     <mmd_marketing_auto_newsletter>
 *       <schedule><cron_expr>*‍/5 * * * *</cron_expr></schedule>
 *       <run><model>mmd_marketing/cron_autoNewsletter::run</model></run>
 *
 * Self-contained: doesn't depend on the user-facing MarketingnewsletterController.
 * Reuses the same Anthropic + MailerLite curl patterns but the implementations
 * are minimal so the cron stays small and easy to debug. When we naturally need
 * to dedupe these calls we can consolidate.
 *
 * Schedule config (seeded by migration 186):
 *   mmd_marketing/auto_newsletter/enabled           — kill-switch
 *   mmd_marketing/auto_newsletter/day_of_week       — 1-7 ISO (Mon=1)
 *   mmd_marketing/auto_newsletter/hour              — 0-23, server-local
 *   mmd_marketing/auto_newsletter/send_delay_hours  — hours after push before send
 *   mmd_marketing/auto_newsletter/country_code      — SG only for v1
 */
class MMD_Marketing_Model_Cron_AutoNewsletter
{
    const LOG_FILE = 'auto-newsletter.log';

    /**
     * Called by Magento cron every 5 min. Gated to fire only in the
     * configured day-of-week + hour, and at most once per day.
     *
     * Pass $force=true (from the "Fire scheduler now" admin button) to
     * bypass the day/hour gate for end-to-end testing.
     */
    public function run($force = false)
    {
        try {
            $cfg = $this->_loadScheduleConfig();
            if (!$force && !$this->_shouldFire($cfg)) {
                return; // silent — gate said "not today"
            }
            if ($cfg['country_code'] !== 'SG') {
                $this->_log('skip: country_code ' . $cfg['country_code'] . ' not enabled in v1 (SG-only)');
                return;
            }
            $this->_log('---- AutoNewsletter fire ' . ($force ? '(forced)' : '(scheduled)') . ' ----');

            $course = $this->_pickRandomCourse();
            if (!$course) {
                $this->_log('skip: no eligible Singapore course found');
                return;
            }
            $this->_log('picked course pid=' . $course['pid'] . ' sku=' . $course['sku'] . ' name=' . $course['name']);

            // Alternate course_promo / visual_showcase based on the count
            // of previously auto-generated rows. Gives the recipient
            // variety without any A/B test machinery.
            $rotationN  = $this->_countAutoNewsletters();
            $templateKey = ($rotationN % 2 === 0) ? 'course_promo' : 'visual_showcase';
            $this->_log('template rotation N=' . $rotationN . ' chose=' . $templateKey);

            $copy = $this->_generateCopy($course, $templateKey);
            $this->_log('copy ' . ($copy['stubbed'] ? '(STUB)' : '(LIVE)') . ' subject=' . $copy['subject']);

            $html = $this->_renderHtml($course, $copy, $templateKey);

            $newsletterId = $this->_insertDraft($course, $copy, $templateKey, $html);
            $this->_log('inserted newsletter_id=' . $newsletterId);

            // Push to MailerLite + schedule send if a key is configured.
            $apiCfg = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
            if (empty($apiCfg['mailerlite_key'])) {
                $this->_log('no MailerLite key — leaving draft un-pushed (stub mode)');
                return $newsletterId;
            }

            $mlid = $this->_pushToMailerLite($apiCfg, $copy['subject'], $html);
            $sendAt = $this->_computeSendAt($cfg['send_delay_hours']);
            $this->_log('pushed mailerlite_id=' . $mlid . ' scheduled for=' . $sendAt);

            $scheduled = Mage::helper('mmd_marketing/mailerlite')->scheduleCampaign($mlid, $sendAt);
            $this->_log('schedule result=' . ($scheduled ? 'ok' : 'failed (manual send in MailerLite required)'));

            $this->_db('write')->update($this->_tbl(), array(
                'mailerlite_id'     => $mlid,
                'body_html'         => $html,
                'status'            => 'pushed',
                'scheduled_send_at' => $sendAt,
            ), array('newsletter_id = ?' => $newsletterId));

            return $newsletterId;
        } catch (Exception $e) {
            $this->_log('FATAL: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
        }
    }

    // ------------------------------------------------------------------
    // Gating
    // ------------------------------------------------------------------

    protected function _loadScheduleConfig()
    {
        return array(
            'enabled'          => (int)    Mage::getStoreConfig('mmd_marketing/auto_newsletter/enabled'),
            'day_of_week'      => (int)    Mage::getStoreConfig('mmd_marketing/auto_newsletter/day_of_week'),
            'hour'             => (int)    Mage::getStoreConfig('mmd_marketing/auto_newsletter/hour'),
            'send_delay_hours' => (int)    Mage::getStoreConfig('mmd_marketing/auto_newsletter/send_delay_hours'),
            'country_code'     => (string) Mage::getStoreConfig('mmd_marketing/auto_newsletter/country_code'),
        );
    }

    protected function _shouldFire(array $cfg)
    {
        if ($cfg['enabled'] !== 1) return false;
        // PHP's date('N') returns 1 (Mon) - 7 (Sun) — matches our config.
        $nowDay  = (int) date('N');
        $nowHour = (int) date('G');
        if ($nowDay  !== $cfg['day_of_week']) return false;
        if ($nowHour !== $cfg['hour'])        return false;
        // Idempotency: only fire once per day.
        $todayCount = (int) $this->_db('read')->fetchOne(
            "SELECT COUNT(*) FROM " . $this->_tbl()
          . " WHERE is_auto = 1 AND DATE(created_at) = CURDATE()"
        );
        return $todayCount === 0;
    }

    // ------------------------------------------------------------------
    // Course selection
    // ------------------------------------------------------------------

    /**
     * Random enabled, visible Singapore course not auto-promoted in the
     * last 30 days. NULL when there's nothing left to pick.
     */
    protected function _pickRandomCourse()
    {
        $r = $this->_db('read');
        $nameAttr  = (int) $r->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=4");
        $shortAttr = (int) $r->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=4");
        // url_key drives the storefront slug — without it the CTA button
        // lands on a 404 page. Built into the email as
        // https://www.tertiarycourses.com.sg/<url_key>.html
        $urlKeyAttr = (int) $r->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=4");

        // 30-day exclusion list: courses previously auto-promoted.
        $recent = $r->fetchCol(
            "SELECT course_pids FROM " . $this->_tbl()
          . " WHERE is_auto = 1 AND created_at > NOW() - INTERVAL 30 DAY"
        );
        $excluded = array();
        foreach ($recent as $csv) {
            foreach (explode(',', (string) $csv) as $pid) {
                $pid = (int) trim($pid);
                if ($pid > 0) $excluded[$pid] = true;
            }
        }
        $excludeSql = $excluded ? 'AND p.entity_id NOT IN (' . implode(',', array_keys($excluded)) . ')' : '';

        $row = $r->fetchRow(
            "SELECT p.entity_id AS pid, p.sku,
                    COALESCE(NULLIF(n1.value,''), n0.value, '') AS name,
                    COALESCE(NULLIF(sd1.value,''), sd0.value, '') AS short_desc,
                    COALESCE(NULLIF(uk1.value,''), uk0.value, '') AS url_key
               FROM catalog_product_entity p
               JOIN catalog_product_website pw ON pw.product_id = p.entity_id AND pw.website_id = 1
               LEFT JOIN catalog_product_entity_int s
                 ON s.entity_id = p.entity_id
                AND s.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code='status' AND entity_type_id=4)
                AND s.store_id = 0
               LEFT JOIN catalog_product_entity_varchar n0 ON n0.entity_id=p.entity_id AND n0.attribute_id={$nameAttr} AND n0.store_id=0
               LEFT JOIN catalog_product_entity_varchar n1 ON n1.entity_id=p.entity_id AND n1.attribute_id={$nameAttr} AND n1.store_id=1
               LEFT JOIN catalog_product_entity_text sd0 ON sd0.entity_id=p.entity_id AND sd0.attribute_id={$shortAttr} AND sd0.store_id=0
               LEFT JOIN catalog_product_entity_text sd1 ON sd1.entity_id=p.entity_id AND sd1.attribute_id={$shortAttr} AND sd1.store_id=1
               LEFT JOIN catalog_product_entity_varchar uk0 ON uk0.entity_id=p.entity_id AND uk0.attribute_id={$urlKeyAttr} AND uk0.store_id=0
               LEFT JOIN catalog_product_entity_varchar uk1 ON uk1.entity_id=p.entity_id AND uk1.attribute_id={$urlKeyAttr} AND uk1.store_id=1
              WHERE (s.value IS NULL OR s.value = 1)
                AND p.sku NOT LIKE 'K%'
                {$excludeSql}
           ORDER BY RAND()
              LIMIT 1"
        );
        if (!$row) return null;
        return array(
            'pid'        => (int) $row['pid'],
            'sku'        => (string) $row['sku'],
            'name'       => (string) $row['name'],
            'short_desc' => trim(strip_tags((string) $row['short_desc'])),
            'url_key'    => (string) $row['url_key'],
        );
    }

    protected function _countAutoNewsletters()
    {
        return (int) $this->_db('read')->fetchOne(
            "SELECT COUNT(*) FROM " . $this->_tbl() . " WHERE is_auto = 1"
        );
    }

    // ------------------------------------------------------------------
    // Copy generation — Claude with stub fallback
    // ------------------------------------------------------------------

    /**
     * Ask Claude for { subject, preview_text, intro, body, cta } as JSON.
     * Falls back to a deterministic stub if no API key, on any error, or
     * if the response can't be parsed.
     */
    protected function _generateCopy(array $course, $templateKey)
    {
        $apiCfg = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        $apiKey = trim((string) ($apiCfg['anthropic_key']   ?? ''));
        $model  = trim((string) ($apiCfg['anthropic_model'] ?? '')) ?: 'claude-sonnet-4-6';

        if ($apiKey === '' || stripos($apiKey, 'sk-ant-oat') === 0) {
            // OAuth tokens rate-limit aggressively on /v1/messages; we
            // skip them here for predictability. Stub instead.
            return $this->_stubCopy($course);
        }

        $system = 'You are an SEO + email copywriter for Tertiary Courses Singapore, a training provider. '
                . 'Output JSON only. No preamble, no markdown fences.';
        $userMsg = "Write a short marketing email about this course in JSON form.\n\n"
                 . "Course: " . $course['name'] . "\n"
                 . "SKU: "    . $course['sku']  . "\n"
                 . "Short description: " . ($course['short_desc'] ?: '(none)') . "\n\n"
                 . "Required JSON keys:\n"
                 . "  subject       — punchy email subject line (≤ 70 chars)\n"
                 . "  preview_text  — inbox preview line (≤ 90 chars)\n"
                 . "  tagline       — 1 short tagline / hook sentence\n"
                 . "  bullets       — array of 3-4 short learning-outcome strings (max 90 chars each, no leading dashes)\n"
                 . "  cta           — call-to-action button label (≤ 30 chars)\n\n"
                 . "Tone: confident, friendly, professional. Avoid hyperbole.\n"
                 . "Output: a single JSON object, no other text.";

        try {
            $body = json_encode(array(
                'model'      => $model,
                'max_tokens' => 1500,
                'system'     => $system,
                'messages'   => array(array('role' => 'user', 'content' => $userMsg)),
            ));
            $ch = curl_init('https://api.anthropic.com/v1/messages');
            curl_setopt_array($ch, array(
                CURLOPT_POST           => true,
                CURLOPT_POSTFIELDS     => $body,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT        => 60,
                CURLOPT_HTTPHEADER     => array(
                    'anthropic-version: 2023-06-01',
                    'content-type: application/json',
                    'x-api-key: ' . $apiKey,
                ),
            ));
            $raw  = curl_exec($ch);
            $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            if ($code >= 400 || !$raw) {
                throw new Exception('Anthropic HTTP ' . $code);
            }
            $rsp  = json_decode($raw, true);
            $text = isset($rsp['content'][0]['text']) ? (string) $rsp['content'][0]['text'] : '';
            $json = $this->_extractJson($text);
            if (!$json) throw new Exception('no JSON in response');
            $bullets = isset($json['bullets']) && is_array($json['bullets']) ? $json['bullets'] : array();
            $bullets = array_values(array_filter(array_map(function ($b) {
                return $this->_clip(preg_replace('/^[-*\x{2022}]\s*/u', '', trim((string) $b)), 90);
            }, $bullets)));
            $bullets = array_slice($bullets, 0, 4);
            return array(
                'subject'      => $this->_clip($json['subject']      ?? '', 90),
                'preview_text' => $this->_clip($json['preview_text'] ?? '', 90),
                'tagline'      => trim((string) ($json['tagline']    ?? '')),
                'bullets'      => $bullets,
                'cta'          => $this->_clip($json['cta']          ?? 'Learn more', 30),
                'stubbed'      => false,
            );
        } catch (Exception $e) {
            $this->_log('Claude call failed (' . $e->getMessage() . '), falling back to stub');
            return $this->_stubCopy($course);
        }
    }

    protected function _stubCopy(array $course)
    {
        $name = $course['name'] ?: 'this course';
        $sd   = $course['short_desc'] ?: 'Hands-on training designed for working professionals in Singapore.';
        if (strlen($sd) > 180) $sd = substr($sd, 0, 177) . '...';
        // 3 generic-but-tailored bullets so the visual-showcase / course-promo
        // templates have something to render in their "What You'll Learn"
        // cards even when no Claude key is configured.
        $bullets = array(
            'Master the core concepts of ' . $this->_clip($name, 50) . ' through guided practice',
            'Apply real-world techniques you can use on day one',
            'Build a portfolio-ready project to demonstrate your skills',
        );
        return array(
            'subject'      => 'Course Spotlight: ' . $this->_clip($name, 50),
            'preview_text' => 'Featured this week — ' . $this->_clip($name, 60),
            'tagline'      => 'Looking to upskill in ' . $name . '? This course gives you the hands-on practice and certifications that move careers forward.',
            'bullets'      => $bullets,
            'cta'          => 'View Course',
            'stubbed'      => true,
        );
    }

    protected function _extractJson($text)
    {
        $text = trim($text);
        if ($text === '') return null;
        // Tolerate the occasional ```json fence Claude adds.
        if (strpos($text, '```') !== false) {
            $text = preg_replace('/^```(?:json)?\s*/i', '', $text);
            $text = preg_replace('/```$/', '', $text);
            $text = trim($text);
        }
        $j = json_decode($text, true);
        if (is_array($j)) return $j;
        if (preg_match('/\{.*\}/s', $text, $m)) {
            $j = json_decode($m[0], true);
            return is_array($j) ? $j : null;
        }
        return null;
    }

    protected function _clip($s, $n)
    {
        $s = trim((string) $s);
        return strlen($s) > $n ? substr($s, 0, $n - 3) . '...' : $s;
    }

    // ------------------------------------------------------------------
    // HTML rendering — minimal email-safe template
    // ------------------------------------------------------------------

    protected function _renderHtml(array $course, array $copy, $templateKey)
    {
        $accent = ($templateKey === 'visual_showcase') ? '#258bb6' : '#22d3ee';
        $courseUrl = $this->_buildCourseUrl($course);
        $h = function($s) { return htmlspecialchars((string) $s, ENT_QUOTES | ENT_HTML5, 'UTF-8'); };
        $tagline = $h($copy['tagline']);

        // Bullets as a "What You'll Learn" card grid — visually matches
        // the marketing/templates/course-promo.phtml layout so the cron
        // output and Newsletter Builder preview agree.
        $bulletsHtml = '';
        if (!empty($copy['bullets'])) {
            $bulletsHtml = '<div style="margin:20px 0;">'
                         . '<div style="font-size:11px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:' . $accent . ';margin-bottom:10px;">What You\'ll Learn</div>'
                         . '<ul style="margin:0;padding:0;list-style:none;font-size:14px;line-height:1.6;color:#374151;">';
            foreach ($copy['bullets'] as $b) {
                $bulletsHtml .= '<li style="padding:6px 0;border-bottom:1px solid #f3f4f6;">'
                              . '<span style="color:' . $accent . ';font-weight:700;margin-right:8px;">&#10003;</span>'
                              . $h($b) . '</li>';
            }
            $bulletsHtml .= '</ul></div>';
        }

        return '<!DOCTYPE html><html><head><meta charset="utf-8"><title>' . $h($copy['subject']) . '</title></head>'
            . '<body style="margin:0;padding:0;background:#f5f7fb;font-family:Arial,Helvetica,sans-serif;color:#1f2937;">'
            . '<div style="display:none;max-height:0;overflow:hidden;font-size:1px;line-height:1px;color:#f5f7fb;">'
            . $h($copy['preview_text']) . '</div>'
            . '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f5f7fb;padding:24px 0;"><tr><td align="center">'
            . '<table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:12px;overflow:hidden;border:1px solid #e5e7eb;">'
            . '<tr><td style="background:' . $accent . ';color:#ffffff;padding:24px 32px;font-size:13px;font-weight:600;letter-spacing:1px;text-transform:uppercase;">Tertiary Infotech Academy</td></tr>'
            . '<tr><td style="padding:32px;">'
            .   '<h1 style="margin:0 0 12px;font-size:24px;line-height:1.3;color:#111827;">' . $h($course['name']) . '</h1>'
            .   '<p style="margin:0 0 20px;font-size:14px;color:#6b7280;">Course code: ' . $h($course['sku']) . '</p>'
            .   '<div style="font-size:15px;line-height:1.6;color:#374151;">'
            .     '<p>' . $tagline . '</p>'
            .   '</div>'
            .   $bulletsHtml
            .   '<div style="margin:32px 0 0;text-align:center;">'
            .     '<a href="' . $h($courseUrl) . '" target="_blank" rel="noopener" style="display:inline-block;background:' . $accent . ';color:#ffffff;text-decoration:none;padding:14px 32px;border-radius:8px;font-weight:600;font-size:14px;">' . $h($copy['cta']) . '</a>'
            .   '</div>'
            . '</td></tr>'
            . '<tr><td style="background:#f9fafb;padding:20px 32px;font-size:12px;color:#6b7280;text-align:center;border-top:1px solid #e5e7eb;">'
            .   'Tertiary Infotech Academy · Singapore<br>'
            .   '<a href="{$unsubscribe}" style="color:#6b7280;">Unsubscribe</a> · '
            .   '<a href="{$url}" style="color:#6b7280;">View in browser</a>'
            . '</td></tr>'
            . '</table>'
            . '</td></tr></table>'
            . '</body></html>';
    }

    // ------------------------------------------------------------------
    // DB write
    // ------------------------------------------------------------------

    protected function _insertDraft(array $course, array $copy, $templateKey, $html)
    {
        // The marketing/templates/*.phtml templates expect body_block_1
        // (tagline) and body_block_2 as newline-separated bullets. Match
        // those keys so that opening this cron-generated draft in the
        // Newsletter Builder UI renders correctly (not the placeholder
        // "Bullet points appear here" copy).
        $bulletsText = implode("\n", $copy['bullets']);
        $blocks = array(
            'body_block_1' => $copy['tagline'],
            'body_block_2' => $bulletsText,
            'body_block_3' => '', // pricing block — left empty for v1
            'cta'          => $copy['cta'],
            '_auto'        => 1,
        );
        $this->_db('write')->insert($this->_tbl(), array(
            'country_code' => 'SG',
            'template_key' => $templateKey,
            'title'        => 'Auto: ' . $this->_clip($course['name'], 80),
            'subject'      => $copy['subject'],
            'preview_text' => $copy['preview_text'],
            'course_pids'  => (string) $course['pid'],
            'body_blocks'  => json_encode($blocks),
            'ai_prompt'    => '(auto-newsletter cron)',
            'body_html'    => $html,
            'status'       => 'draft',
            'is_auto'      => 1,
            'created_at'   => date('Y-m-d H:i:s'),
            'updated_at'   => date('Y-m-d H:i:s'),
        ));
        return (int) $this->_db('write')->lastInsertId();
    }

    // ------------------------------------------------------------------
    // MailerLite push — same 2-step POST + PUT pattern as the controller
    // ------------------------------------------------------------------

    protected function _pushToMailerLite(array $cfg, $subject, $html)
    {
        // Inject the legally-required unsubscribe footer if missing.
        if (stripos($html, '{$unsubscribe}') === false) {
            $footer = '<div style="text-align:center;font-size:11px;color:#94a3b8;padding:24px 16px;font-family:Arial,sans-serif;">'
                    . 'You\'re receiving this because you signed up for updates.<br>'
                    . '<a href="{$unsubscribe}" style="color:#94a3b8;">Unsubscribe</a> &middot; '
                    . '<a href="{$url}" style="color:#94a3b8;">View in browser</a>'
                    . '</div>';
            $html = (stripos($html, '</body>') !== false)
                ? str_ireplace('</body>', $footer . '</body>', $html)
                : $html . $footer;
        }

        $payload = array(
            'name'        => $subject,
            'language_id' => 1,
            'type'        => 'regular',
            'emails'      => array(array(
                'subject'   => $subject,
                'from_name' => $cfg['from_name']  ?? 'Tertiary Infotech Academy',
                'from'      => $cfg['from_email'] ?? 'noreply@tertiaryinfotech.com',
                'content'   => $html,
            )),
        );
        $hdrs = array(
            'authorization: Bearer ' . $cfg['mailerlite_key'],
            'content-type: application/json',
            'accept: application/json',
        );

        // Step 1: create the campaign shell.
        $ch = curl_init('https://connect.mailerlite.com/api/campaigns');
        curl_setopt_array($ch, array(
            CURLOPT_POST => true, CURLOPT_POSTFIELDS => json_encode($payload),
            CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 60,
            CURLOPT_HTTPHEADER => $hdrs,
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        $this->_log('MailerLite create HTTP ' . $code . ' body=' . substr((string) $raw, 0, 400));
        $rsp = json_decode((string) $raw, true);
        if (!isset($rsp['data']['id'])) {
            throw new Exception('MailerLite create failed (' . $code . '): ' . substr((string) $raw, 0, 300));
        }
        $campaignId = (string) $rsp['data']['id'];

        // Step 2: PUT the full payload back (forces content to stick).
        $ch2 = curl_init('https://connect.mailerlite.com/api/campaigns/' . urlencode($campaignId));
        curl_setopt_array($ch2, array(
            CURLOPT_CUSTOMREQUEST => 'PUT', CURLOPT_POSTFIELDS => json_encode($payload),
            CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 60,
            CURLOPT_HTTPHEADER => $hdrs,
        ));
        $raw2  = curl_exec($ch2);
        $code2 = (int) curl_getinfo($ch2, CURLINFO_HTTP_CODE);
        curl_close($ch2);
        $this->_log('MailerLite PUT HTTP ' . $code2 . ' body=' . substr((string) $raw2, 0, 400));

        return $campaignId;
    }

    /**
     * Build the storefront URL for a course. Magento's catalog URL
     * rewrite is `<url_key>.html` at the SG storefront root. If the
     * product is missing a url_key (rare), fall back to the SG
     * storefront homepage so the CTA still lands on a real page.
     */
    protected function _buildCourseUrl(array $course)
    {
        $slug = trim((string) ($course['url_key'] ?? ''));
        if ($slug === '') {
            return 'https://www.tertiarycourses.com.sg/';
        }
        return 'https://www.tertiarycourses.com.sg/' . rawurlencode($slug) . '.html';
    }

    protected function _computeSendAt($delayHours)
    {
        $ts = time() + max(1, (int) $delayHours) * 3600;
        // Round up to the next 5-minute mark for tidiness.
        $ts = ((int) ceil($ts / 300)) * 300;
        return date('Y-m-d H:i:s', $ts);
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    protected function _tbl()
    {
        return Mage::getSingleton('core/resource')->getTableName('newsletters');
    }

    protected function _db($mode)
    {
        return Mage::getSingleton('core/resource')->getConnection('core_' . $mode);
    }

    protected function _log($msg)
    {
        // OpenMage's Mage::log() silently drops writes when
        // dev/log/allowedFileExtensions is empty (which it is in this
        // install). Write directly so log lines never go missing.
        $line = '[' . date('Y-m-d H:i:s') . '] ' . $msg . "\n";
        @file_put_contents(
            Mage::getBaseDir('var') . '/log/' . self::LOG_FILE,
            $line, FILE_APPEND
        );
    }
}
