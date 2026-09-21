-- C525 "Finance for Non-Finance Managers" — non-WSQ twin of TGS-2022602569
-- ("Financial Analysis for Non-Finance Managers", IBF-STS).
--
-- Courseware was converted from the parent (GitHub + Drive + LMS links pushed
-- separately). This migration aligns the storefront record:
--   * 2 days / 15 instructional hours  (was 1 day / 7.5 hrs)
--   * $700                             (was $350; 2 x the $350/day band)
--   * description + topics copied from the WSQ parent, IBF/WSQ wording removed
--   * meta_description rewritten without a day count
--   * funding block repointed at the parent it was duplicated from
--
-- SG production only. Idempotent: every statement is a guarded UPDATE keyed on
-- the C525 entity, so a re-run is a no-op. No TGS-/M- course is touched.

-- 1) Fee: 2 days at the $350/day band. Updates EVERY scope row.
UPDATE catalog_product_entity_decimal d
  JOIN catalog_product_entity p ON p.entity_id = d.entity_id
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id
   AND a.entity_type_id = 4 AND a.attribute_code = 'price'
   SET d.value = 700.0000
 WHERE p.sku = 'C525' AND p.sku LIKE 'C%' AND p.sku NOT LIKE 'CASL%';

-- 2) Duration tile: 2 x 7.5 instructional hours.
UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity p ON p.entity_id = v.entity_id
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 4 AND a.attribute_code = 'duration'
   SET v.value = '15'
 WHERE p.sku = 'C525';

-- 3) Sessions tile: 2 days.
UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity p ON p.entity_id = v.entity_id
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 4 AND a.attribute_code = 'sessions'
   SET v.value = '2'
 WHERE p.sku = 'C525';

-- 4) meta_description — no day count, <= 255 chars, no WSQ/IBF wording.
UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity p ON p.entity_id = v.entity_id
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 4 AND a.attribute_code = 'meta_description'
   SET v.value = 'Read financial statements, apply ratio and cash-flow analysis, benchmark performance and evaluate investments. A hands-on finance course for managers without a finance background at Tertiary Courses Singapore.'
 WHERE p.sku = 'C525';

-- 5) "What's This Course About" — copied from the WSQ parent, with the IBF-STS
--    programme reference removed (a non-WSQ course carries no programme).
UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity p ON p.entity_id = t.entity_id
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id
   AND a.entity_type_id = 4 AND a.attribute_code = 'short_description'
   SET t.value = '<p>Unlock the secrets of financial management with our Finance for Non-Finance Managers course. Designed for professionals without a financial background, this course breaks down complex financial concepts into manageable insights. You will learn how to interpret financial statements, understand budgeting principles, and analyze cash flows, enabling you to make data-driven decisions. Acquire the skills to assess the financial health of projects and departments, and communicate effectively with financial teams, enhancing your overall managerial effectiveness.</p>\n<p>Take your managerial role to the next level by mastering key financial metrics and ratio analysis, and gain an introduction to forecasting techniques. This course combines theoretical knowledge with practical case studies and real-world scenarios, preparing you to apply your skills immediately in a managerial context. Ideal for team leaders, department heads, and project managers, this course equips you with the financial tools you need to contribute to your organization''s success and profitability.</p>'
 WHERE p.sku = 'C525';

-- 6) Course topics — the parent's 11 topics, same titles and order (LSN_DATA
--    JSON drives the topic tiles).
UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity p ON p.entity_id = t.entity_id
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id
   AND a.entity_type_id = 4 AND a.attribute_code = 'description'
   SET t.value = '<!-- LSN_DATA: [{"title":"The different financial ratios","subsecs":[]},{"title":"Profitability Analysis","subsecs":[]},{"title":"Cash Flow Analysis","subsecs":[]},{"title":"Projected financial and cash-flow statements","subsecs":[]},{"title":"The process of financial statements analysis","subsecs":[]},{"title":"Use financial analysis to determine the health of an organisation","subsecs":[]},{"title":"Evaluate organisation’s historical financial performance","subsecs":[]},{"title":"Investment suitability based on financial analysis","subsecs":[]},{"title":"Analysis for the financial services industry","subsecs":[]},{"title":"Benchmarking of financial performance against industry","subsecs":[]},{"title":"Use Capital Budgeting to evaluate potential investment returns","subsecs":[]}] -->\n<p><strong>The different financial ratios</strong></p>\n<p><strong>Profitability Analysis</strong></p>\n<p><strong>Cash Flow Analysis</strong></p>\n<p><strong>Projected financial and cash-flow statements</strong></p>\n<p><strong>The process of financial statements analysis</strong></p>\n<p><strong>Use financial analysis to determine the health of an organisation</strong></p>\n<p><strong>Evaluate organisation’s historical financial performance</strong></p>\n<p><strong>Investment suitability based on financial analysis</strong></p>\n<p><strong>Analysis for the financial services industry</strong></p>\n<p><strong>Benchmarking of financial performance against industry</strong></p>\n<p><strong>Use Capital Budgeting to evaluate potential investment returns</strong></p>'
 WHERE p.sku = 'C525';

-- 7) Funding block -> the course this one was duplicated from. Content-only
--    UPDATE: never save a cms/block model (it wipes cms_block_store).
UPDATE cms_block
   SET content = '<p class="p1">No funding is available for this course.</p>\n<p>For IBF funding, please checkout the details at <span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/ibf-financial-analysis-for-non-finance-managers.html" title="IBF - Financial Analysis for Non-Finance Managers" target="_self">IBF - Financial Analysis for Non-Finance Managers</a></span></p>'
 WHERE identifier = 'course_C525_funding_and_grant';
