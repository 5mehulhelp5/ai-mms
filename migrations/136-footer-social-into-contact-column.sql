-- migration 136: move social media icons from the footer-primary-bottom-left
-- row INTO the Contact Us column of each store's block_footer_column5, then
-- clear the now-unused block_footer_primary_bottom_left blocks so that the
-- empty bottom row collapses. This reduces the gap between footer row 1 and
-- footer row 2.
--
-- Strategy: for each store, take the social-links HTML from
-- block_footer_primary_bottom_left and insert it before the LAST </div> of
-- block_footer_column5 (which closes the third grid12-4 column — the one
-- containing the "Contact Us Information" collapsible).
--
-- Idempotent via "content NOT LIKE '%social-links ib-wrapper--square%'" guard
-- on the column blocks. Single-line statements per memory/feedback_apply_php_sql_splitter.md.

-- MY (block_id=34): strip stray Google Translate runtime widget that lives outside the column wrappers, so TRIM + last-</div> lands on the actual column close.
UPDATE cms_block SET content = REPLACE(content, '<div id="gtx-trans" style="position: absolute; left: 47px; top: 962.688px;"><div class="gtx-trans-icon"></div></div>', '') WHERE block_id = 34 AND content LIKE '%gtx-trans%';

-- SG (col=7, social=2)
UPDATE cms_block c SET c.content = CONCAT(SUBSTRING(TRIM(c.content), 1, CHAR_LENGTH(TRIM(c.content)) - 6), (SELECT content FROM (SELECT content FROM cms_block WHERE block_id = 2) AS s), '</div>') WHERE c.block_id = 7 AND c.content NOT LIKE '%social-links ib-wrapper--square%';

-- MY (col=34, social=43)
UPDATE cms_block c SET c.content = CONCAT(SUBSTRING(TRIM(c.content), 1, CHAR_LENGTH(TRIM(c.content)) - 6), (SELECT content FROM (SELECT content FROM cms_block WHERE block_id = 43) AS s), '</div>') WHERE c.block_id = 34 AND c.content NOT LIKE '%social-links ib-wrapper--square%';

-- GH (col=57, social=63)
UPDATE cms_block c SET c.content = CONCAT(SUBSTRING(TRIM(c.content), 1, CHAR_LENGTH(TRIM(c.content)) - 6), (SELECT content FROM (SELECT content FROM cms_block WHERE block_id = 63) AS s), '</div>') WHERE c.block_id = 57 AND c.content NOT LIKE '%social-links ib-wrapper--square%';

-- NG (col=73, social=68)
UPDATE cms_block c SET c.content = CONCAT(SUBSTRING(TRIM(c.content), 1, CHAR_LENGTH(TRIM(c.content)) - 6), (SELECT content FROM (SELECT content FROM cms_block WHERE block_id = 68) AS s), '</div>') WHERE c.block_id = 73 AND c.content NOT LIKE '%social-links ib-wrapper--square%';

-- BT (col=85, social=80)
UPDATE cms_block c SET c.content = CONCAT(SUBSTRING(TRIM(c.content), 1, CHAR_LENGTH(TRIM(c.content)) - 6), (SELECT content FROM (SELECT content FROM cms_block WHERE block_id = 80) AS s), '</div>') WHERE c.block_id = 85 AND c.content NOT LIKE '%social-links ib-wrapper--square%';

-- IN (col=99, social=96)
UPDATE cms_block c SET c.content = CONCAT(SUBSTRING(TRIM(c.content), 1, CHAR_LENGTH(TRIM(c.content)) - 6), (SELECT content FROM (SELECT content FROM cms_block WHERE block_id = 96) AS s), '</div>') WHERE c.block_id = 99 AND c.content NOT LIKE '%social-links ib-wrapper--square%';

-- Clear the bottom-left social blocks so the footer-primary-bottom row renders empty (and is collapsed by the !empty($b['primary_bottom']) check in footer.phtml).
UPDATE cms_block SET content = '' WHERE identifier = 'block_footer_primary_bottom_left';
