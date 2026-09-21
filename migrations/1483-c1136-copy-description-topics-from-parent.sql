-- C1136 (CompTIA PenTest+ Training) — copy the storefront overview + course
-- topics from its funded parent TGS-2026064471 (CASL - CompTIA PenTest+ Training).
--
-- Why: the non-WSQ twin is a replication of the parent, so both catalogue entries
-- must describe the same course. C1136 carried its own overview and had NO
-- structured topics at all (`description` held a prose blurb, 0 `Topic N:`
-- headings) while the parent carries all 5. Courseware scans never catch this —
-- they read artifacts, not the storefront.
--
-- Both attributes are catalog_product_entity_text at store 0:
--   short_description -> "What's This Course About"
--   description       -> the course-topics list
--
-- Day-count safety: the parent's text states NO day or hour count (verified
-- 2026-09-21), so nothing here can contradict C1136's own tiles
-- (Sessions 5 days / Duration 37.5 hrs). The copy is guarded below anyway: the
-- UPDATE is a no-op if the source text ever grows a day count.
--
-- Funding safety: the parent's overview and topics contain no CASL/WSQ/
-- SkillsFuture/funding wording, so none rides along onto the non-WSQ course.
-- Guarded below on the same principle.
--
-- Idempotent: re-running writes the same values.
--
-- AFTER DEPLOY: reindex catalog_product_flat + flush cache, or the page keeps
-- serving the old copy -> /reindex/api/run?flush=1&token=<mmd_reindex/api/token>

SET @a_short := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'short_description' AND entity_type_id = 4 LIMIT 1);
SET @a_desc  := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'description' AND entity_type_id = 4 LIMIT 1);

SET @src := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064471' LIMIT 1);
SET @dst := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1136' LIMIT 1);

SET @v_short := (SELECT value FROM catalog_product_entity_text
                  WHERE entity_id = @src AND attribute_id = @a_short AND store_id = 0 LIMIT 1);
SET @v_desc  := (SELECT value FROM catalog_product_entity_text
                  WHERE entity_id = @src AND attribute_id = @a_desc  AND store_id = 0 LIMIT 1);

-- Guard: refuse the copy if the parent text ever grows a day/hour count or a
-- funding term. NULLing the value makes every UPDATE below a no-op.
SET @bad := (
  CONCAT(COALESCE(@v_short,''), ' ', COALESCE(@v_desc,'')) REGEXP
  '(2-day|2 day|two-day|1-day|one-day|5-day|5 day|five-day|16 hours|15 hours|40 hours|CASL|WSQ|SkillsFuture|funding|subsid)'
);
SET @v_short := IF(@bad, NULL, @v_short);
SET @v_desc  := IF(@bad, NULL, @v_desc);

UPDATE catalog_product_entity_text
   SET value = @v_short
 WHERE entity_id = @dst AND attribute_id = @a_short AND store_id = 0
   AND @v_short IS NOT NULL AND @dst IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = @v_desc
 WHERE entity_id = @dst AND attribute_id = @a_desc AND store_id = 0
   AND @v_desc IS NOT NULL AND @dst IS NOT NULL;

-- Partner servers (MY/GH) hold no C1136 / TGS-2026064471 rows, so @src/@dst are
-- NULL there and every statement above is a no-op.
