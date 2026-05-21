-- Restyle the numbered `<span class="icon i-char">N</span>` badges used as
-- list bullets in every country's footer column 5 (Authorised Training
-- Partners / Regional Training Centers / Authorized Testing Centers etc.)
-- to match the consistent 40x40 navy rounded-square icon style used by
-- migration 098 for the Contact Us section icons. The badge keeps its
-- digit as text but drops the legacy `i-char` class, so its background,
-- size, and corner radius can no longer be overridden by Ultimo's
-- per-position CSS (which was rendering the "last" item in a lighter
-- shade).
--
-- Applies to blocks 7 (SG), 34 (MY), 57 (GH), 73 (NG), 85 (BT), 99 (IN).
-- Digits 1-9 cover all observed values.
--
-- Idempotent: REPLACE() on already-restyled content is a no-op.

SET @badge_style := 'display:inline-flex;align-items:center;justify-content:center;width:40px;height:40px;background:#1e3a8a;border-radius:8px;color:#fff;flex-shrink:0;font-weight:700;font-size:15px;line-height:1;';

UPDATE cms_block SET content = REPLACE(content, '<span class="icon i-char">1</span>', CONCAT('<span class="icon" style="', @badge_style, '">1</span>')) WHERE block_id IN (7,34,57,73,85,99);
UPDATE cms_block SET content = REPLACE(content, '<span class="icon i-char">2</span>', CONCAT('<span class="icon" style="', @badge_style, '">2</span>')) WHERE block_id IN (7,34,57,73,85,99);
UPDATE cms_block SET content = REPLACE(content, '<span class="icon i-char">3</span>', CONCAT('<span class="icon" style="', @badge_style, '">3</span>')) WHERE block_id IN (7,34,57,73,85,99);
UPDATE cms_block SET content = REPLACE(content, '<span class="icon i-char">4</span>', CONCAT('<span class="icon" style="', @badge_style, '">4</span>')) WHERE block_id IN (7,34,57,73,85,99);
UPDATE cms_block SET content = REPLACE(content, '<span class="icon i-char">5</span>', CONCAT('<span class="icon" style="', @badge_style, '">5</span>')) WHERE block_id IN (7,34,57,73,85,99);
UPDATE cms_block SET content = REPLACE(content, '<span class="icon i-char">6</span>', CONCAT('<span class="icon" style="', @badge_style, '">6</span>')) WHERE block_id IN (7,34,57,73,85,99);
UPDATE cms_block SET content = REPLACE(content, '<span class="icon i-char">7</span>', CONCAT('<span class="icon" style="', @badge_style, '">7</span>')) WHERE block_id IN (7,34,57,73,85,99);
UPDATE cms_block SET content = REPLACE(content, '<span class="icon i-char">8</span>', CONCAT('<span class="icon" style="', @badge_style, '">8</span>')) WHERE block_id IN (7,34,57,73,85,99);
UPDATE cms_block SET content = REPLACE(content, '<span class="icon i-char">9</span>', CONCAT('<span class="icon" style="', @badge_style, '">9</span>')) WHERE block_id IN (7,34,57,73,85,99);
