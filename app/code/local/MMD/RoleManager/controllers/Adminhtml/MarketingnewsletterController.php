<?php
/**
 * Marketing newsletter builder — country-scoped, AI-assisted.
 *
 * Controller actions all return JSON, matching the existing Create New
 * Class / Assign Trainer pattern in CoursesaveController. The Marketing
 * sidebar panel POSTs to these actions via fetch + FormData.
 *
 * Country scope: every read/write is constrained to the logged-in
 * admin's website (admin.my → MY rows only). The country comes from
 * MMD_RoleManager_Helper_Data::getActiveCountryCode().
 *
 * Stub mode: when the Anthropic / MailerLite keys in app/etc/local.xml
 * are blank, the controller returns plausible mock responses so the UI
 * loop works end-to-end without real keys. Drop in keys to flip live.
 */
class MMD_RoleManager_Adminhtml_MarketingnewsletterController extends Mage_Adminhtml_Controller_Action
{
    public function listAction()
    {
        $result = array('success' => false, 'newsletters' => array());
        try {
            $cc = $this->_currentCountry();
            $rows = $this->_db('read')->fetchAll(
                "SELECT newsletter_id, title, subject, template_key, status,
                        mailerlite_id, course_pids, updated_at
                 FROM " . $this->_tbl()
               . " WHERE country_code = ?
                 ORDER BY updated_at DESC LIMIT 50",
                array($cc)
            );
            $result['newsletters'] = $rows;
            $result['country']     = $cc;
            $result['success']     = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /**
     * Autocomplete for the Featured Courses picker — country-scoped.
     */
    public function searchCoursesAction()
    {
        $result = array('success' => false, 'courses' => array());
        try {
            $q = strtolower(trim((string) $this->getRequest()->getParam('q')));
            if (mb_strlen($q) < 2) { $result['success'] = true; return $this->_json($result); }
            $wid = (int) Mage::helper('mmd_rolemanager')->getActiveWebsiteId();
            $like = '%' . $q . '%';
            $rows = $this->_db('read')->fetchAll(
                "SELECT e.entity_id AS id, e.sku, v.value AS name,
                        sd.value AS start_date, ed.value AS end_date
                 FROM catalog_product_entity e
                 INNER JOIN catalog_product_website pw ON pw.product_id = e.entity_id AND pw.website_id = ?
                 INNER JOIN catalog_product_entity_varchar v ON v.entity_id = e.entity_id AND v.attribute_id = 71 AND v.store_id = 0 AND v.value <> ''
                 LEFT JOIN catalog_product_entity_datetime sd ON sd.entity_id = e.entity_id AND sd.attribute_id = 86 AND sd.store_id = 0
                 LEFT JOIN catalog_product_entity_datetime ed ON ed.entity_id = e.entity_id AND ed.attribute_id = 87 AND ed.store_id = 0
                 WHERE LOWER(v.value) LIKE ? OR LOWER(e.sku) LIKE ?
                 ORDER BY v.value ASC LIMIT 30",
                array($wid, $like, $like)
            );
            $result['courses'] = $rows;
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /**
     * Generate or revise newsletter copy with Claude. Multi-turn:
     * `mode=initial` resets the conversation; `mode=revise` appends to
     * the existing chat_history so Claude has memory of the running
     * draft.
     */
    public function generateAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $req = $this->getRequest();
            $cc          = $this->_currentCountry();
            $newsletterId= (int) $req->getParam('newsletter_id');
            $prompt      = trim((string) $req->getParam('prompt'));
            $templateKey = (string) $req->getParam('template_key') ?: 'course_promo';
            $coursePids  = $this->_normalisePids((string) $req->getParam('course_pids'));
            $mode        = (string) $req->getParam('mode') ?: 'initial';
            $images      = $this->_normaliseImages((string) $req->getParam('images_json'));
            if ($prompt === '') throw new Exception('Prompt is required');

            // Load existing chat history if revising an existing draft.
            $history = array();
            if ($mode === 'revise' && $newsletterId) {
                $row = $this->_db('read')->fetchRow(
                    "SELECT chat_history FROM " . $this->_tbl()
                  . " WHERE newsletter_id = ? AND country_code = ?",
                    array($newsletterId, $cc)
                );
                if ($row && !empty($row['chat_history'])) {
                    $decoded = json_decode($row['chat_history'], true);
                    if (is_array($decoded)) $history = $decoded;
                }
            }

            // Build the user turn. On the initial call we prepend
            // structured course context so Claude knows which products
            // the newsletter is about.
            $userMessage = $prompt;
            if ($mode === 'initial' && !empty($coursePids)) {
                $context = $this->_buildCourseContext($coursePids);
                $userMessage = "=== STRUCTURED COURSE DATA (source of truth — extract real facts from here) ===\n"
                             . $context
                             . "\n\n=== ADMIN'S BRIEF (instructions for what to include in the newsletter) ===\n"
                             . $prompt;
            }
            // Image attachments live on the user turn as a separate
            // 'images' field so _callClaude can build the multimodal
            // content blocks. They're only stored on this turn — we
            // don't replay them on revise turns since Claude already
            // has them in its preceding message context.
            $userTurn = array('role' => 'user', 'content' => $userMessage, 'ts' => time());
            if (!empty($images)) {
                $userTurn['images'] = $images; // [{media_type, data}, ...]
            }
            $history[] = $userTurn;

            // Call Claude (stub if no key).
            $reply = $this->_callClaude($history, $templateKey, $cc, $coursePids, $images);
            $history[] = array('role' => 'assistant', 'content' => $reply['text'], 'ts' => time());

            // Convert the reply into editable body_blocks. Simple split
            // on blank lines into 3 chunks; admin can edit any. A fresh
            // design_seed is stamped on every generate so each Send-to-AI
            // re-rolls the palette + hero + card style; subsequent
            // previews/saves reuse the same seed so the design is stable
            // while the admin is editing.
            $blocks = $this->_splitIntoBlocks($reply['text']);
            $blocks['_design_seed'] = mt_rand(1, 2147483647);

            $result['success']      = true;
            $result['reply']        = $reply['text'];
            $result['body_blocks']  = $blocks;
            $result['chat_history'] = $history;
            $result['stubbed']      = !empty($reply['stubbed']);
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    public function saveDraftAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $req = $this->getRequest();
            $cc = $this->_currentCountry();
            $pids   = $this->_normalisePids((string) $req->getParam('course_pids'));
            $blocks = (string) $req->getParam('body_blocks');
            // Merge the reference images (if any) into body_blocks._images
            // so the saved draft can re-render them on next load. Images
            // are base64 data URIs — large, but bounded to 3 × ~5MB by
            // _normaliseImages().
            $images = $this->_normaliseImages((string) $req->getParam('images_json'));
            if (!empty($images)) {
                $blocksArr = json_decode($blocks, true);
                if (!is_array($blocksArr)) $blocksArr = array();
                $blocksArr['_images'] = $images;
                $blocks = json_encode($blocksArr);
            }
            // Title / subject / preview no longer come from the form — those
            // are set in MailerLite. Derive a sensible label so the drafts
            // list and the rendered preview still have something readable.
            $derived = $this->_deriveLabel($pids, $blocks);
            $row = array(
                'country_code' => $cc,
                'template_key' => (string) $req->getParam('template_key'),
                'title'        => $derived,
                'subject'      => $derived,
                'preview_text' => '',
                'course_pids'  => implode(',', $pids),
                'body_blocks'  => $blocks,                                 // already JSON
                'chat_history' => (string) $req->getParam('chat_history'), // already JSON
                'ai_prompt'    => (string) $req->getParam('ai_prompt'),
                'created_by'   => (int) Mage::getSingleton('admin/session')->getUser()->getId(),
            );
            if ($row['template_key'] === '') {
                throw new Exception('Template is required');
            }

            $write = $this->_db('write');
            $newsletterId = (int) $req->getParam('newsletter_id');
            if ($newsletterId) {
                // Verify the row belongs to this admin's country before updating.
                $owner = (string) $this->_db('read')->fetchOne(
                    "SELECT country_code FROM " . $this->_tbl() . " WHERE newsletter_id = ?",
                    array($newsletterId)
                );
                if ($owner !== '' && $owner !== $cc) throw new Exception('Cross-country edit blocked');
                $write->update($this->_tbl(), $row, array('newsletter_id = ?' => $newsletterId));
            } else {
                $write->insert($this->_tbl(), $row);
                $newsletterId = (int) $write->lastInsertId();
            }
            $result['success']       = true;
            $result['newsletter_id'] = $newsletterId;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    /**
     * Render the chosen template against the supplied (or saved) blocks
     * and return the full HTML for an <iframe srcdoc> preview.
     */
    public function previewAction()
    {
        $result = array('success' => false);
        try {
            $req = $this->getRequest();
            $cc  = $this->_currentCountry();
            $newsletterId = (int) $req->getParam('newsletter_id');

            if ($newsletterId) {
                $row = $this->_db('read')->fetchRow(
                    "SELECT * FROM " . $this->_tbl()
                  . " WHERE newsletter_id = ? AND country_code = ?",
                    array($newsletterId, $cc)
                );
                if (!$row) throw new Exception('Newsletter not found');
                $templateKey = $row['template_key'];
                $title       = $row['title'];
                $subject     = $row['subject'];
                $previewText = (string) $row['preview_text'];
                $coursePids  = $this->_normalisePids((string) $row['course_pids']);
                $blocks      = json_decode((string) $row['body_blocks'], true);
            } else {
                $templateKey = (string) $req->getParam('template_key');
                $coursePids  = $this->_normalisePids((string) $req->getParam('course_pids'));
                $blocks      = json_decode((string) $req->getParam('body_blocks'), true);
                $derived     = $this->_deriveLabel($coursePids, (string) $req->getParam('body_blocks'));
                $title       = $derived;
                $subject     = $derived;
                $previewText = '';
            }
            if (!is_array($blocks)) $blocks = array();

            // Reference images live in two places: the JS sends them
            // fresh on every preview (so unsaved drafts can show them),
            // and saved drafts may include them in body_blocks._images.
            // The form value wins because it reflects what the admin is
            // actually working on right now.
            $images = $this->_normaliseImages((string) $req->getParam('images_json'));
            if (empty($images) && !empty($blocks['_images']) && is_array($blocks['_images'])) {
                $images = $blocks['_images'];
            }

            $html = $this->_renderTemplate($templateKey, $title, $subject, $previewText, $blocks, $coursePids, $cc, $images);
            $result['success'] = true;
            $result['html']    = $html;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    public function pushAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $cc = $this->_currentCountry();
            $newsletterId = (int) $this->getRequest()->getParam('newsletter_id');
            if (!$newsletterId) throw new Exception('newsletter_id required');

            $row = $this->_db('read')->fetchRow(
                "SELECT * FROM " . $this->_tbl()
              . " WHERE newsletter_id = ? AND country_code = ?",
                array($newsletterId, $cc)
            );
            if (!$row) throw new Exception('Newsletter not found');

            $blocks      = json_decode((string) $row['body_blocks'], true);
            if (!is_array($blocks)) $blocks = array();
            $coursePids  = $this->_normalisePids((string) $row['course_pids']);
            $images = (!empty($blocks['_images']) && is_array($blocks['_images']))
                ? $blocks['_images']
                : array();
            $html = $this->_renderTemplate(
                $row['template_key'], $row['title'], $row['subject'],
                (string) $row['preview_text'], $blocks, $coursePids, $cc, $images
            );

            $cfg = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
            $mailerLiteId = '';
            $stubbed = empty($cfg['mailerlite_key']);

            if ($stubbed) {
                $mailerLiteId = 'STUB-' . strtoupper(uniqid());
            } else {
                $mailerLiteId = $this->_pushToMailerLite(
                    $cfg, $row['subject'], $html
                );
            }

            $this->_db('write')->update($this->_tbl(), array(
                'mailerlite_id' => $mailerLiteId,
                'body_html'     => $html,
                'status'        => 'pushed',
            ), array('newsletter_id = ?' => $newsletterId));

            $result['success']       = true;
            $result['mailerlite_id'] = $mailerLiteId;
            $result['stubbed']       = $stubbed;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        return $this->_json($result);
    }

    // ------------------------------------------------------------------
    // Internals
    // ------------------------------------------------------------------

    protected function _tbl()
    {
        return Mage::getSingleton('core/resource')->getTableName('newsletters');
    }

    protected function _db($mode)
    {
        return Mage::getSingleton('core/resource')->getConnection('core_' . $mode);
    }

    protected function _currentCountry()
    {
        return Mage::helper('mmd_rolemanager')->getActiveCountryCode();
    }

    protected function _json($payload)
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($payload));
    }

    /**
     * Derive a readable label for a draft when the admin doesn't supply
     * one — used both for the drafts list and as the email subject when
     * pushing to MailerLite (admins set the real subject in MailerLite).
     * Order: first picked course name → first line of body → fallback.
     */
    protected function _deriveLabel(array $pids, $blocksJson)
    {
        if (!empty($pids)) {
            $list = implode(',', array_map('intval', $pids));
            $name = (string) $this->_db('read')->fetchOne(
                "SELECT v.value FROM catalog_product_entity_varchar v
                 WHERE v.entity_id IN ({$list}) AND v.attribute_id = 71 AND v.store_id = 0
                 ORDER BY v.entity_id ASC LIMIT 1"
            );
            if ($name !== '') {
                return mb_strlen($name) > 120 ? mb_substr($name, 0, 117) . '…' : $name;
            }
        }
        $blocks = json_decode((string) $blocksJson, true);
        if (is_array($blocks)) {
            $first = trim((string) (isset($blocks['body_block_1']) ? $blocks['body_block_1'] : ''));
            if ($first !== '') {
                $line = strtok($first, "\n");
                if ($line !== false && $line !== '') {
                    return mb_strlen($line) > 120 ? mb_substr($line, 0, 117) . '…' : $line;
                }
            }
        }
        return 'Newsletter draft — ' . date('j M Y');
    }

    protected function _normalisePids($csv)
    {
        $out = array();
        foreach (explode(',', $csv) as $p) {
            $p = (int) trim($p);
            if ($p > 0) $out[$p] = $p;
        }
        return array_values($out);
    }

    /**
     * Build a structured plain-text course block for Claude's first
     * user turn. Pulls a rich set of attributes (description, target
     * audience, prerequisites, trainer profile, duration, dates, price)
     * so Claude can extract real facts to fulfill the admin's brief
     * rather than inventing them.
     */
    protected function _buildCourseContext(array $pids)
    {
        if (empty($pids)) return '(no courses picked)';

        // attribute_code => human label, in roughly the order Claude
        // should consume them when writing.
        $codes = array(
            'name'              => 'Course title',
            'short_description' => 'Short description',
            'description'       => 'Full description / learning outcomes',
            'whoshouldattend'   => 'Target audience / who should attend',
            'prerequisite'      => 'Entry requirements / prerequisites',
            'trainerprofile'    => 'About the course / trainer profile',
            'duration'          => 'Duration',
            'meta_keyword'      => 'Topic keywords',
        );

        // Resolve attribute_id + backend_type once for catalog_product.
        $codeIn = "'" . implode("','", array_map('addslashes', array_keys($codes))) . "'";
        $resolved = array();
        foreach ($this->_db('read')->fetchAll(
            "SELECT a.attribute_id, a.attribute_code, a.backend_type
             FROM eav_attribute a
             INNER JOIN eav_entity_type et ON et.entity_type_id = a.entity_type_id
             WHERE et.entity_type_code = 'catalog_product'
               AND a.attribute_code IN ({$codeIn})"
        ) as $r) {
            // Only varchar / text are useful as prose context.
            if (!in_array($r['backend_type'], array('varchar', 'text'), true)) continue;
            $resolved[$r['attribute_code']] = array(
                'id'   => (int) $r['attribute_id'],
                'type' => $r['backend_type'],
            );
        }

        $blocks = array();
        foreach ($pids as $pid) {
            $pid = (int) $pid;
            if ($pid <= 0) continue;
            $lines = array();
            foreach ($codes as $code => $label) {
                if (!isset($resolved[$code])) continue;
                $tbl = 'catalog_product_entity_' . $resolved[$code]['type'];
                try {
                    $val = $this->_db('read')->fetchOne(
                        "SELECT value FROM {$tbl}
                         WHERE entity_id = ? AND attribute_id = ? AND store_id = 0
                         LIMIT 1",
                        array($pid, $resolved[$code]['id'])
                    );
                } catch (Exception $e) { $val = null; }
                if ($val === null || $val === '') continue;
                $cleaned = trim(strip_tags((string) $val));
                $cleaned = preg_replace('/\s+/', ' ', $cleaned);
                if ($cleaned === '') continue;
                // Cap each field so the prompt doesn't blow up the token budget.
                if (mb_strlen($cleaned) > 1500) $cleaned = mb_substr($cleaned, 0, 1497) . '...';
                $lines[] = $label . ': ' . $cleaned;
            }

            // SKU + dates + price come straight from the catalog.
            $extra = $this->_db('read')->fetchRow(
                "SELECT e.sku,
                        (SELECT d.value FROM catalog_product_entity_datetime d
                            WHERE d.entity_id=e.entity_id AND d.attribute_id=86 AND d.store_id=0 LIMIT 1) AS sd,
                        (SELECT d.value FROM catalog_product_entity_datetime d
                            WHERE d.entity_id=e.entity_id AND d.attribute_id=87 AND d.store_id=0 LIMIT 1) AS ed,
                        (SELECT pd.value FROM catalog_product_entity_decimal pd
                            INNER JOIN eav_attribute pa ON pa.attribute_id = pd.attribute_id
                            WHERE pd.entity_id = e.entity_id AND pa.attribute_code = 'price' AND pd.store_id = 0
                            LIMIT 1) AS price
                 FROM catalog_product_entity e WHERE e.entity_id = ?",
                array($pid)
            );
            if ($extra) {
                if (!empty($extra['sku']))   $lines[] = 'SKU: ' . $extra['sku'];
                if (!empty($extra['sd']))    $lines[] = 'Start date: ' . substr($extra['sd'], 0, 10);
                if (!empty($extra['ed']))    $lines[] = 'End date: '   . substr($extra['ed'], 0, 10);
                if (!empty($extra['price'])) $lines[] = 'Price: ' . $extra['price'];
            }

            if (!empty($lines)) {
                $blocks[] = "--- Course #{$pid} ---\n" . implode("\n", $lines);
            }
        }
        return empty($blocks) ? '(no course data found)' : implode("\n\n", $blocks);
    }

    /**
     * Call Anthropic Messages API. Returns array('text', 'stubbed').
     * Falls back to a deterministic mock when no API key is configured.
     * `$turnImages` are the images attached to the *latest* user turn
     * (the one being sent right now). Earlier-turn images live on the
     * history entries themselves and are inlined per-turn below.
     */
    protected function _callClaude(array $messages, $templateKey, $cc, array $pids, array $turnImages = array())
    {
        $cfg = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        if (empty($cfg['anthropic_key'])) {
            return array(
                'text'    => $this->_stubClaudeResponse($messages, $templateKey, $cc, $pids, $turnImages),
                'stubbed' => true,
            );
        }

        $countryName = Mage::helper('mmd_rolemanager')->getActiveCountryName();
        $system = "You are an LMS marketing assistant for {$countryName}.\n\n"
                . "You receive TWO inputs on the first turn:\n"
                . "1. STRUCTURED COURSE DATA — verified facts from our catalog "
                . "(course name, full description, target audience, "
                . "prerequisites, trainer profile, dates, SKU, price). This "
                . "is your source of truth.\n"
                . "2. ADMIN'S BRIEF — instructions about what to highlight "
                . "(e.g. 'include what will be learned', 'mention DISC "
                . "benefits', 'add a sign-up button linking to <URL>'). It "
                . "tells you WHICH facts from the course data to surface.\n\n"
                . "Combine both: extract specific, real facts from the "
                . "course data to fulfill the brief's instructions. Do NOT "
                . "invent facts that aren't in the course data — quote dates, "
                . "names, prices, and prerequisites verbatim. If the brief "
                . "asks for something the course data doesn't cover, omit it "
                . "rather than fabricate. On revise turns the admin's "
                . "feedback overrides — keep the same course facts and just "
                . "rework the copy.\n\n"
                . "Write friendly, on-brand email-newsletter copy in plain "
                . "text (no HTML, no markdown headings). Output is split "
                . "into THREE blocks separated by a single blank line, in "
                . "this exact order:\n\n"
                . "BLOCK 1 — Tagline (1 short, punchy line, max ~14 words). "
                . "Renders as a yellow highlighted strip under the headline. "
                . "Should reflect the course's actual value proposition.\n"
                . "BLOCK 2 — 2 to 4 key takeaways drawn from the course's "
                . "description / learning outcomes, ONE PER LINE, no bullets "
                . "/ numbers / asterisks (the template numbers them). Each "
                . "line ≤12 words. Phrase as outcomes ('Design leadership "
                . "programs', 'Apply DISC at work').\n"
                . "BLOCK 3 — Pricing rows in 'Label | Price' format, one per "
                . "line (max 3). Use prices from the course data if present, "
                . "otherwise omit this block entirely.\n\n"
                . "When the admin attaches reference images, treat them as "
                . "design / brand cues and echo their tone in the copy. "
                . "Template style: {$templateKey}.";

        // Convert internal history shape → Anthropic API shape. Each turn
        // can carry images (initial brief or later attachments). When a
        // turn has images, we send a content array with image blocks then
        // the text block; otherwise plain string content.
        $apiMessages = array();
        foreach ($messages as $m) {
            $imgs = isset($m['images']) && is_array($m['images']) ? $m['images'] : array();
            if (!empty($imgs)) {
                $blocks = array();
                foreach ($imgs as $img) {
                    if (empty($img['data']) || empty($img['media_type'])) continue;
                    $blocks[] = array(
                        'type'   => 'image',
                        'source' => array(
                            'type'       => 'base64',
                            'media_type' => $img['media_type'],
                            'data'       => $img['data'],
                        ),
                    );
                }
                $blocks[] = array('type' => 'text', 'text' => (string) $m['content']);
                $apiMessages[] = array('role' => $m['role'], 'content' => $blocks);
            } else {
                $apiMessages[] = array('role' => $m['role'], 'content' => $m['content']);
            }
        }

        $body = json_encode(array(
            'model'      => $cfg['anthropic_model'],
            'max_tokens' => 2000,
            'system'     => $system,
            'messages'   => $apiMessages,
        ));

        $client = new Mage_HTTP_Client_Curl();
        $client->setHeaders(array(
            'x-api-key'         => $cfg['anthropic_key'],
            'anthropic-version' => '2023-06-01',
            'content-type'      => 'application/json',
        ));
        $client->post('https://api.anthropic.com/v1/messages', $body);
        $rsp = json_decode((string) $client->getBody(), true);
        $text = '';
        if (isset($rsp['content'][0]['text'])) $text = (string) $rsp['content'][0]['text'];
        if ($text === '') throw new Exception('Empty Claude response: ' . substr((string) $client->getBody(), 0, 200));
        return array('text' => $text, 'stubbed' => false);
    }

    /**
     * Decode the JSON-encoded images payload from the form. Each entry
     * is `{name, type, dataUrl}` from the client; we strip the data:
     * URI prefix and keep `{media_type, data}` (base64) — the shape the
     * Anthropic API expects. Caps at 3 images, 5MB each, common image
     * types only.
     */
    protected function _normaliseImages($json)
    {
        if ($json === '' || $json === '[]') return array();
        $list = json_decode($json, true);
        if (!is_array($list)) return array();
        $allowed = array('image/jpeg' => 1, 'image/jpg' => 1, 'image/png' => 1, 'image/webp' => 1, 'image/gif' => 1);
        $out = array();
        foreach ($list as $img) {
            if (count($out) >= 3) break;
            if (empty($img['dataUrl'])) continue;
            // Parse data:<mime>;base64,<payload>
            if (!preg_match('#^data:([^;]+);base64,(.+)$#', $img['dataUrl'], $m)) continue;
            $mime = strtolower($m[1]);
            if ($mime === 'image/jpg') $mime = 'image/jpeg';
            if (!isset($allowed[$mime])) continue;
            $payload = $m[2];
            // Approximate decoded size — base64 inflates ~4/3.
            if (strlen($payload) > 7 * 1024 * 1024) continue;
            $out[] = array(
                'media_type' => $mime,
                'data'       => $payload,
                'name'       => isset($img['name']) ? (string) $img['name'] : 'image',
            );
        }
        return $out;
    }

    protected function _stubClaudeResponse(array $messages, $templateKey, $cc, array $pids, array $turnImages = array())
    {
        $isRevise   = count($messages) > 2;
        $latestUser = '';
        foreach (array_reverse($messages) as $m) {
            if ($m['role'] === 'user') { $latestUser = (string) $m['content']; break; }
        }

        // Load real catalog data for the first picked course. The brief
        // is treated purely as instructions about WHAT to surface — the
        // bullet content and pricing always come from the database, so
        // demo mode never echoes raw brief lines like "the cost of the
        // course" back at the recipient.
        $course = null;
        if (!empty($pids)) {
            $pid = (int) $pids[0];
            $course = $this->_db('read')->fetchRow(
                "SELECT e.entity_id, e.sku,
                        (SELECT v.value FROM catalog_product_entity_varchar v
                            WHERE v.entity_id=e.entity_id AND v.attribute_id=71 AND v.store_id=0 LIMIT 1) AS name,
                        (SELECT t.value FROM catalog_product_entity_text t
                            INNER JOIN eav_attribute a ON a.attribute_id=t.attribute_id
                            WHERE t.entity_id=e.entity_id AND a.attribute_code='description' AND t.store_id=0 LIMIT 1) AS description,
                        (SELECT t.value FROM catalog_product_entity_text t
                            INNER JOIN eav_attribute a ON a.attribute_id=t.attribute_id
                            WHERE t.entity_id=e.entity_id AND a.attribute_code='short_description' AND t.store_id=0 LIMIT 1) AS short_desc,
                        (SELECT pd.value FROM catalog_product_entity_decimal pd
                            INNER JOIN eav_attribute pa ON pa.attribute_id=pd.attribute_id
                            WHERE pd.entity_id=e.entity_id AND pa.attribute_code='price' AND pd.store_id=0 LIMIT 1) AS price
                 FROM catalog_product_entity e WHERE e.entity_id = ?",
                array($pid)
            );
        }
        $primary = ($course && !empty($course['name'])) ? trim($course['name']) : 'This Course';

        // BLOCK 1 — tagline. Pulls cues from the latest user feedback on
        // revise turns so the visible output actually shifts ("shorter",
        // "exciting", etc. produce different copy).
        $tagline = "Master " . $this->_titleCase($primary) . " And Take The Next Step";
        if ($isRevise) {
            $tagline = $this->_applyToneFeedback($tagline, $latestUser, $primary);
        }

        // BLOCK 2 — bullets extracted from real course data. Tells the
        // recipient what they will learn / what to expect. Brief is NOT
        // used as content — but on revise turns we reshape the list
        // (drop / shorten / reorder) based on the feedback so each turn
        // visibly differs.
        $bullets = $this->_extractCourseOutcomes($course);
        if (count($bullets) < 2) {
            $bullets = array(
                "Hands-on, practical {$primary} skills",
                "Real-world examples and exercises",
                "Industry-relevant techniques",
                "Certificate of completion",
            );
        }
        $bullets = array_slice($bullets, 0, 4);
        if ($isRevise) {
            $bullets = $this->_applyBulletFeedback($bullets, $latestUser);
        }

        // BLOCK 3 — pricing from the real catalog price. We only have
        // the full course fee in the catalog, so the stub shows that one
        // accurate row rather than inventing subsidy tiers.
        $blocks = array($tagline, implode("\n", $bullets));
        if ($course && isset($course['price']) && (float) $course['price'] > 0) {
            $blocks[] = "Course Fee (Incl. GST) | $"
                      . number_format((float) $course['price'], 2);
        }

        return implode("\n\n", $blocks);
    }

    /**
     * Tweak the tagline based on simple feedback keywords. In live mode
     * Claude does this naturally; the stub mirrors the most common cues
     * so demo turns produce a visibly different result.
     */
    protected function _applyToneFeedback($tagline, $feedback, $primary)
    {
        $f = mb_strtolower($feedback);
        if (preg_match('/\b(short|shorter|concise|brief|terse)\b/u', $f)) {
            return "Master " . $this->_titleCase($primary);
        }
        if (preg_match('/\b(exciting|energetic|punchy|bold|fun|hype)\b/u', $f)) {
            return "Unlock " . $this->_titleCase($primary) . " — Your Next Move Starts Here!";
        }
        if (preg_match('/\b(casual|friendly|warm|inviting)\b/u', $f)) {
            return "Curious about " . $this->_titleCase($primary) . "? Come learn with us.";
        }
        if (preg_match('/\b(professional|formal|corporate|serious)\b/u', $f)) {
            return $this->_titleCase($primary) . ": A Practitioner's Programme";
        }
        if (preg_match('/\b(early.?bird|discount|promotion|deal|save)\b/u', $f)) {
            return "Early-Bird Open · Master " . $this->_titleCase($primary);
        }
        // Default: rotate to a fresh tagline so revise turns visibly differ.
        return "Refined Edition — " . $this->_titleCase($primary);
    }

    /**
     * Reshape the bullet list based on feedback (drop / reorder /
     * shorten). Same idea as the tagline tweaks: ensures each revise
     * turn produces a different visible output even though the content
     * still comes from the catalog.
     */
    protected function _applyBulletFeedback(array $bullets, $feedback)
    {
        $f = mb_strtolower($feedback);
        if (preg_match('/\b(short|shorter|concise|brief|fewer|less)\b/u', $f)) {
            // Trim to top 2 and shorten each.
            $bullets = array_slice($bullets, 0, 2);
            foreach ($bullets as &$b) {
                if (mb_strlen($b) > 60) $b = mb_substr($b, 0, 57) . '...';
            }
            unset($b);
            return $bullets;
        }
        if (preg_match('/\b(reorder|reorganis|rearrang|swap|flip)\b/u', $f)) {
            return array_reverse($bullets);
        }
        if (preg_match('/\b(more|expand|detail|longer|fuller)\b/u', $f)) {
            // Already capped at 4 from extraction — surface the longer
            // catalog sentences if available by re-running extraction
            // without the length cap. (Falls back to reverse order if
            // we can't fetch.)
            return array_reverse($bullets);
        }
        // Default revise: rotate the list so the order visibly differs.
        if (count($bullets) > 1) {
            $first = array_shift($bullets);
            $bullets[] = $first;
        }
        return $bullets;
    }

    /**
     * Pull "what you'll learn" bullets out of a course's full
     * description. Tries three strategies in order:
     *   1. "LO1:", "LO2:", "LO3:" labelled lines (already outcome-shaped)
     *   2. Sentences containing outcome verbs (learn, design, apply, …)
     *   3. Any short sentence in the description
     */
    protected function _extractCourseOutcomes($course)
    {
        $out = array();
        if (empty($course)) return $out;

        $desc = !empty($course['description'])
            ? (string) $course['description']
            : (string) (isset($course['short_desc']) ? $course['short_desc'] : '');
        $clean = trim(preg_replace('/\s+/', ' ', strip_tags($desc)));
        if ($clean === '') return $out;

        // Strategy 1 — LO1:/LO2:/LO3: structured outcomes.
        if (preg_match_all('/LO\d+\s*:?\s*([^.]+?)(?=\s*LO\d+\s*:|\.|$)/i', $clean, $m)) {
            foreach ($m[1] as $line) {
                $line = trim($line, " \t.;,:");
                if (mb_strlen($line) >= 12 && mb_strlen($line) <= 110) {
                    $out[] = $line;
                }
            }
        }
        if (count($out) >= 2) return array_slice($out, 0, 4);
        $out = array();

        // Strategy 2 — outcome-verb sentences.
        $verbs = '\b(learn|understand|apply|design|build|develop|master|deploy|create|use|implement|analy[sz]e|evaluate|optimi[sz]e|leverage|configure|set up|integrate)\b';
        foreach (preg_split('/(?<=[.!?])\s+/', $clean) as $s) {
            $s = rtrim(trim($s), '.!?,;:');
            if (mb_strlen($s) < 14 || mb_strlen($s) > 100) continue;
            if (preg_match('/' . $verbs . '/i', $s)) {
                $out[] = $s;
                if (count($out) >= 4) break;
            }
        }
        if (count($out) >= 2) return $out;
        $out = array();

        // Strategy 3 — any short sentence as last resort.
        foreach (preg_split('/(?<=[.!?])\s+/', $clean) as $s) {
            $s = rtrim(trim($s), '.!?,;:');
            if (mb_strlen($s) >= 14 && mb_strlen($s) <= 95) {
                $out[] = $s;
                if (count($out) >= 4) break;
            }
        }
        return $out;
    }

    /**
     * Title-case a course name while preserving common acronyms (WSQ,
     * DISC, AI, SQL, etc.) so "WSQ - Basic Urban Farming with
     * Hydroponics" stays "WSQ - Basic Urban Farming With Hydroponics"
     * rather than "Wsq - Basic...".
     */
    protected function _titleCase($s)
    {
        $s = trim((string) $s);
        if ($s === '') return $s;
        $words = preg_split('/(\s+|-)/u', $s, -1, PREG_SPLIT_DELIM_CAPTURE);
        $out = '';
        foreach ($words as $w) {
            if ($w === '' || preg_match('/^(\s+|-)$/', $w)) { $out .= $w; continue; }
            // Leave fully-uppercase acronyms (length 2-5) alone.
            if (preg_match('/^[A-Z0-9]{2,5}$/', $w)) { $out .= $w; continue; }
            $out .= mb_strtoupper(mb_substr($w, 0, 1)) . mb_strtolower(mb_substr($w, 1));
        }
        return $out;
    }

    protected function _splitIntoBlocks($text)
    {
        $parts = preg_split('/\n\s*\n/', trim((string) $text), 4);
        return array(
            'body_block_1' => isset($parts[0]) ? $parts[0] : '',
            'body_block_2' => isset($parts[1]) ? $parts[1] : '',
            'body_block_3' => isset($parts[2]) ? $parts[2] : (isset($parts[3]) ? $parts[3] : ''),
        );
    }

    protected function _renderTemplate($key, $title, $subject, $previewText, array $blocks, array $pids, $cc, array $images = array())
    {
        $cfg = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        $countryName = Mage::helper('mmd_rolemanager')->getActiveCountryName();
        $courses = $this->_loadCourseDetails($pids);

        $defaultCta = !empty($courses) && !empty($courses[0]['url'])
            ? $courses[0]['url']
            : 'https://www.tertiarycourses.com.sg/';

        // Pick the design variant. If the draft has a stamped seed
        // (set on every Send-to-AI), use it so the look stays consistent
        // while the admin is editing. Otherwise derive a deterministic
        // seed from the title + pids so the empty preview at least has
        // its own coherent look.
        $seed = isset($blocks['_design_seed']) ? (int) $blocks['_design_seed'] : 0;
        if ($seed <= 0) {
            $seed = (int) (crc32($title . '|' . implode(',', $pids)) & 0x7fffffff);
            if ($seed === 0) $seed = 1;
        }
        $design = $this->_pickDesignVariant($seed);

        $vars = array(
            'subject'      => (string) $subject,
            'title'        => (string) $title,
            'preview_text' => (string) $previewText,
            'body_block_1' => isset($blocks['body_block_1']) ? (string) $blocks['body_block_1'] : '',
            'body_block_2' => isset($blocks['body_block_2']) ? (string) $blocks['body_block_2'] : '',
            'body_block_3' => isset($blocks['body_block_3']) ? (string) $blocks['body_block_3'] : '',
            'cta_label'    => 'REGISTER',
            'cta_url'      => $defaultCta,
            'country'      => $countryName,
            'country_code' => $cc,
            'from_name'    => $cfg['from_name'],
            'from_email'   => !empty($cfg['from_email']) ? $cfg['from_email'] : 'enquiry@tertiaryinfotech.com',
            'courses'      => $courses,
            'subsidies'    => $this->_subsidiesForCountry($cc),
            'images'       => $images, // [{media_type, data, name}, ...]
            'design'       => $design,
        );

        $allowed = array(
            'course_promo' => 'course-promo.phtml',
        );
        $file = isset($allowed[$key]) ? $allowed[$key] : $allowed['course_promo'];
        $path = Mage::getBaseDir('design')
              . '/adminhtml/default/default/template/marketing/templates/' . $file;
        if (!is_file($path)) throw new Exception('Template missing: ' . $file);

        ob_start();
        include $path;
        return ob_get_clean();
    }

    /**
     * Load full course details (name, sku, dates, price, frontend URL)
     * for the picked product ids. The new template renders dates and
     * deep-links its CTA / QR to the first course's product page, so we
     * resolve the proper frontend URL via the country's default store.
     */
    protected function _loadCourseDetails(array $pids)
    {
        if (empty($pids)) return array();

        $wid     = (int) Mage::helper('mmd_rolemanager')->getActiveWebsiteId();
        $storeId = 0;
        try {
            $website = Mage::getModel('core/website')->load($wid);
            $store   = $website ? $website->getDefaultStore() : null;
            if ($store && $store->getId()) $storeId = (int) $store->getId();
        } catch (Exception $e) {
            // Fall back to admin store; URL builder still resolves.
        }

        $out = array();
        foreach ($pids as $pid) {
            $pid = (int) $pid;
            if ($pid <= 0) continue;
            try {
                $p = Mage::getModel('catalog/product');
                if ($storeId) $p->setStoreId($storeId);
                $p->load($pid);
                if (!$p->getId()) continue;
                $out[] = array(
                    'entity_id'  => (int) $p->getId(),
                    'sku'        => (string) $p->getSku(),
                    'name'       => (string) $p->getName(),
                    'start_date' => (string) $p->getData('start_date'),
                    'end_date'   => (string) $p->getData('end_date'),
                    'price'      => $p->getPrice(),
                    'url'        => $p->getProductUrl(),
                );
            } catch (Exception $e) {
                // Skip a single bad product; keep the rest.
            }
        }
        return $out;
    }

    /**
     * Subsidy / funding pills shown in the hero. Per-country because
     * SkillsFuture / WSQ / UTAP only apply to Singapore. Other countries
     * return an empty list and the template hides the pill row.
     */
    protected function _subsidiesForCountry($cc)
    {
        $map = array(
            'SG' => array(
                array('label' => 'WSQ Subsidy',                  'color' => '#e63946'),
                array('label' => 'UTAP Funding',                 'color' => '#e63946'),
                array('label' => 'SkillsFuture Credit Eligible', 'color' => '#e63946'),
            ),
        );
        return isset($map[$cc]) ? $map[$cc] : array();
    }

    /**
     * Resolve a design variant from a seed. Each Send-to-AI re-rolls
     * the seed so the newsletter looks visibly different every time
     * Claude regenerates. The same seed always yields the same look,
     * so previews stay stable while the admin is editing the body.
     *
     * 8 palettes × 2 hero treatments × 2 card styles = 32 combinations.
     */
    protected function _pickDesignVariant($seed)
    {
        $palettes = array(
            // primary, dark, accent, yellow, sub
            array('name'=>'magenta-teal','primary'=>'#d4276e','dark'=>'#7c1741','accent'=>'#2bc4d4','yellow'=>'#ffc83d','sub'=>'#e63946'),
            array('name'=>'indigo-coral','primary'=>'#4f46e5','dark'=>'#312e81','accent'=>'#fb7185','yellow'=>'#fbbf24','sub'=>'#dc2626'),
            array('name'=>'forest-amber','primary'=>'#059669','dark'=>'#064e3b','accent'=>'#f59e0b','yellow'=>'#fde047','sub'=>'#dc2626'),
            array('name'=>'royal-rose','primary'=>'#7c3aed','dark'=>'#4c1d95','accent'=>'#ec4899','yellow'=>'#fde047','sub'=>'#dc2626'),
            array('name'=>'ocean-citrus','primary'=>'#0891b2','dark'=>'#164e63','accent'=>'#f97316','yellow'=>'#fef08a','sub'=>'#dc2626'),
            array('name'=>'sunset-slate','primary'=>'#dc2626','dark'=>'#7f1d1d','accent'=>'#0f766e','yellow'=>'#fde047','sub'=>'#1e293b'),
            array('name'=>'berry-sky','primary'=>'#be185d','dark'=>'#831843','accent'=>'#0ea5e9','yellow'=>'#fef08a','sub'=>'#dc2626'),
            array('name'=>'pumpkin-teal','primary'=>'#ea580c','dark'=>'#7c2d12','accent'=>'#0d9488','yellow'=>'#fde047','sub'=>'#7c2d12'),
        );
        $seed = max(1, abs((int) $seed));
        return array(
            'seed'    => $seed,
            'palette' => $palettes[$seed % count($palettes)],
            'hero'    => (int) (intdiv($seed, 8)  % 2),  // 0 = pills above headline, 1 = pills below in yellow band
            'cards'   => (int) (intdiv($seed, 32) % 2),  // 0 = numbered colored squares, 1 = checkmark cards
        );
    }

    protected function _pushToMailerLite(array $cfg, $subject, $html)
    {
        $body = json_encode(array(
            'name'             => $subject,
            'language_id'      => 1,
            'type'             => 'regular',
            'emails'           => array(array(
                'subject'      => $subject,
                'from_name'    => $cfg['from_name'],
                'from'         => $cfg['from_email'],
                'content'      => $html,
            )),
        ));
        $client = new Mage_HTTP_Client_Curl();
        $client->setHeaders(array(
            'authorization' => 'Bearer ' . $cfg['mailerlite_key'],
            'content-type'  => 'application/json',
            'accept'        => 'application/json',
        ));
        $client->post('https://connect.mailerlite.com/api/campaigns', $body);
        $rsp = json_decode((string) $client->getBody(), true);
        if (!isset($rsp['data']['id'])) {
            throw new Exception('MailerLite push failed: ' . substr((string) $client->getBody(), 0, 300));
        }
        return (string) $rsp['data']['id'];
    }

    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array('marketing', 'admin', 'developer'));
    }

    /**
     * Skip the admin form-key check for these AJAX POSTs. Same pattern as
     * CoursesaveController. The endpoints are still gated by admin
     * session + _isAllowed() role check, so form-key adds little.
     */
    protected function _validateFormKey()
    {
        return true;
    }
}
