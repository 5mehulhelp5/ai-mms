-- 1515: C135 Basic Accounting for Non-Finance Managers -> 2-day non-WSQ twin of TGS-2023038152
--
-- Converted from the WSQ parent (TGS-2023038152) by /non-wsq-courseware-duplication.
-- SG only. Idempotent: every UPDATE is value-setting and guarded on the C135 entity.
--
-- NOTE: the schedule option template switch (A18 -> B17, gid 189) is a CODE path
-- (CoursesaveController::switchScheduleTemplateAction) and was applied separately.
-- It is deliberately NOT expressed as SQL: custom_options_relation is per-option_id
-- and a DELETE+INSERT wipes the schedule.

SET @eid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C135' LIMIT 1);

-- ---- price: 2-day band, $700 -------------------------------------------------
SET @a_price := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'price' AND entity_type_id = 4 LIMIT 1);
UPDATE catalog_product_entity_decimal
   SET value = 700.0000
 WHERE entity_id = @eid AND attribute_id = @a_price;

-- ---- duration / sessions: 2 days, 15 instructional hours ---------------------
SET @a_dur := (SELECT attribute_id FROM eav_attribute
                WHERE attribute_code = 'duration' AND entity_type_id = 4 LIMIT 1);
UPDATE catalog_product_entity_varchar
   SET value = '15'
 WHERE entity_id = @eid AND attribute_id = @a_dur;

SET @a_ses := (SELECT attribute_id FROM eav_attribute
                WHERE attribute_code = 'sessions' AND entity_type_id = 4 LIMIT 1);
UPDATE catalog_product_entity_varchar
   SET value = '2'
 WHERE entity_id = @eid AND attribute_id = @a_ses;

-- ---- description + topics copied from the WSQ parent -------------------------
-- Both verified free of any day count, WSQ/SkillsFuture/funding wording and TGS ref.
SET @a_short := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'short_description' AND entity_type_id = 4 LIMIT 1);
UPDATE catalog_product_entity_text
   SET value = '<p>Delve deep into the realm of accounting tailored explicitly for professionals outside of the finance domain. "Accounting for Non-Finance Managers" equips learners with the expertise to input data into accounting systems accurately, ensuring all transactions align with pertinent regulatory frameworks. Whether you\'re a seasoned manager or an industry newbie, this course provides comprehensive insights into the intricate financial processes that drive businesses.</p>\n<p>Beyond mere data entry, participants will cultivate a keen awareness of evolving managerial accounting standards, preparing them to navigate the dynamic financial landscape with ease. The course further extends its coverage to highlight significant accounting and income tax issues, enabling learners to identify and address potential financial challenges promptly. Elevate your managerial capabilities and gain a competitive edge in today\'s fast-paced business world.</p>'
 WHERE entity_id = @eid AND attribute_id = @a_short;

SET @a_desc := (SELECT attribute_id FROM eav_attribute
                 WHERE attribute_code = 'description' AND entity_type_id = 4 LIMIT 1);
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Basics of Financial Accounting","subsecs":[{"title":"What is accounting?","links":[]},{"title":"Bookkeeping","links":[]},{"title":"Regulatory framework for financial reporting ","links":[]},{"title":"Balance sheets ","links":[]},{"title":"Income statement","links":[]},{"title":"Cash flow statement","links":[]},{"title":"Real life examples of financial accouting","links":[]}]},{"title":"Topic 2: Basics of Managerial Accounting","subsecs":[{"title":"Overview of accounting standards","links":[]},{"title":"Overview of managerial accounting","links":[]},{"title":"Budgeting ","links":[]},{"title":"Real life examples of managerial accounting","links":[]}]},{"title":"Topic 3: Accounting Issues and Income Taxes","subsecs":[{"title":"Identify accounting issues","links":[]},{"title":"Income tax issues","links":[]},{"title":"Capital gains vs. ordinary income","links":[]}]}] -->\n<p><strong>Topic 1: Basics of Financial Accounting</strong></p>\n<p><em>What is accounting?</em></p>\n<p><em>Bookkeeping</em></p>\n<p><em>Regulatory framework for financial reporting </em></p>\n<p><em>Balance sheets </em></p>\n<p><em>Income statement</em></p>\n<p><em>Cash flow statement</em></p>\n<p><em>Real life examples of financial accouting</em></p>\n<p><strong>Topic 2: Basics of Managerial Accounting</strong></p>\n<p><em>Overview of accounting standards</em></p>\n<p><em>Overview of managerial accounting</em></p>\n<p><em>Budgeting </em></p>\n<p><em>Real life examples of managerial accounting</em></p>\n<p><strong>Topic 3: Accounting Issues and Income Taxes</strong></p>\n<p><em>Identify accounting issues</em></p>\n<p><em>Income tax issues</em></p>\n<p><em>Capital gains vs. ordinary income</em></p>\n'
 WHERE entity_id = @eid AND attribute_id = @a_desc;
