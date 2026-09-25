-- 1550: C695 "Agentic AI Applications with Codex" -> 2 days / 15 hrs / $700
--
-- C695 is the non-WSQ twin of TGS-2023041081 (same title). Its courseware is now
-- the converted WSQ set (github.com/tertiarycourses/C695-Agentic-AI-Applications-with-Codex):
-- the parent's 5 topics and 18 labs over two 9:30am-5:30pm days, 7.5 instructional
-- hours each. The product still sold it as a 1-day course, so the page contradicted
-- its own courseware.
--
-- PROBED on prod before writing (entity 695, sku 'C695'):
--   * price 350.0000, duration '7.5', sessions '1' -- store 0 rows only, no
--     store-scope overrides to chase.
--   * meta_description ends "...in this hands-on 1-day course in Singapore." --
--     rewritten WITHOUT a day count (it feeds <meta>, og:description, JSON-LD).
--   * short_description is already byte-identical to the WSQ parent's; description
--     carries the parent's 4 topics in the same order -- neither is touched.
--   * course_C695_funding_and_grant already links to the WSQ twin -- not touched.
--
-- $700 = the standard $350/day non-WSQ rate x 2 days.
--
-- SG production only in effect: partner sites have no 'C695' with this title, and
-- every statement is keyed by SKU + name so a diverged partner row no-ops.
-- Idempotent: re-running writes the same values.

UPDATE catalog_product_entity_decimal d
  JOIN catalog_product_entity e ON e.entity_id = d.entity_id
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id AND a.entity_type_id = 4
  JOIN catalog_product_entity_varchar n ON n.entity_id = e.entity_id AND n.store_id = 0
  JOIN eav_attribute na ON na.attribute_id = n.attribute_id AND na.entity_type_id = 4 AND na.attribute_code = 'name'
   SET d.value = 700.0000
 WHERE TRIM(e.sku) = 'C695'
   AND n.value = 'Agentic AI Applications with Codex'
   AND a.attribute_code = 'price';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity e ON e.entity_id = v.entity_id
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
  JOIN catalog_product_entity_varchar n ON n.entity_id = e.entity_id AND n.store_id = 0
  JOIN eav_attribute na ON na.attribute_id = n.attribute_id AND na.entity_type_id = 4 AND na.attribute_code = 'name'
   SET v.value = CASE a.attribute_code
                   WHEN 'duration' THEN '15'
                   WHEN 'sessions' THEN '2'
                   WHEN 'meta_description' THEN 'Build agentic AI applications with OpenAI Codex - plan, code, refactor and test with Codex Skills, MCP tools, RAG and multi-agent workflows in this hands-on course in Singapore.'
                 END
 WHERE TRIM(e.sku) = 'C695'
   AND n.value = 'Agentic AI Applications with Codex'
   AND a.attribute_code IN ('duration', 'sessions', 'meta_description');
