-- C8 (Basic Hydroponics Course for Urban Farming) -- copy the storefront
-- overview + course topics from its WSQ parent TGS-2025053916 (WSQ - Basic Urban
-- Farming with Hydroponics), so both catalogue entries describe the same course.
--
-- Part of the C8 non-WSQ courseware conversion (2026-09-21). The courseware (deck,
-- Lesson Plan, Learner Guide, activities) is a replication of the parent's, so the
-- product page must present the parent's syllabus too. C8 previously carried its own
-- 6-topic list; the parent's canonical 4 topics replace it.
--
-- Both attributes are catalog_product_entity_text at store 0:
--   short_description -> "What's This Course About"
--   description       -> the course-topics list (carries the LSN_DATA topic JSON)
--
-- De-WSQ'd before embedding (the copy is NOT verbatim):
--   * overview opener "The WSQ Basic Urban Farming with Hydroponics course
--     introduces" -> "This course introduces"
--   * the two "LU1"/"LU2" learning-unit wrapper entries (WSQ competency framing)
--     are dropped from LSN_DATA; all 4 Topic entries and their sub-points are kept
--     in the parent's order
--   * NBSP (U+00A0) normalised to plain spaces -> the embedded text is pure ASCII,
--     so apply.php's utf8 connection cannot hit error 1366
--
-- Day-count safety: neither value states a day or hour count, so nothing here can
-- contradict C8's own tiles (Sessions 1 day / Duration 7.5 hrs). Verified by the
-- generator and re-asserted by the guard below.
--
-- Funding safety: no WSQ / SSG / SkillsFuture / funding wording survives the scrub
-- (the only "fund" is inside "fundamentals"). Guarded below on the same principle.
--
-- Venue: the parent's overview names MEOD Farm, which is the venue the converted
-- courseware states (confirmed 2026-09-21).
--
-- Idempotent: re-running writes the same values.
--
-- AFTER DEPLOY: reindex catalog_product_flat + flush cache, or the page keeps
-- serving the old copy -> /reindex/api/run?flush=1&token=<mmd_reindex/api/token>

SET @a_short := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'short_description' AND entity_type_id = 4 LIMIT 1);
SET @a_desc  := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'description' AND entity_type_id = 4 LIMIT 1);

SET @dst := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C8' LIMIT 1);

SET @v_short := '<p>This course introduces participants to the fundamentals of hydroponic systems, plant nutrition, and urban farming practices. Gain insights into the history and advantages of hydroponics, understand various hydroponic systems, and learn how to set up and maintain these systems effectively. Participants will explore different types of growing media, nutrient solutions, and the importance of monitoring pH and EC levels for optimal plant growth.</p>\n<p>This course also covers indoor farming techniques, including lighting, temperature, and humidity control, with practical application during a guided tour of a commercial hydroponics farm. Additionally, participants will learn about urban farming regulations in Singapore, good agriculture practices, and workplace safety. This hands-on training equips learners with the skills needed to perform farming activities according to standard operating procedures and regulatory requirements.</p>\n<h2>Farm Tour @ Meod Farm - 13 Neo Tiew Harvest Lane, Singapore&nbsp;719838 &amp; Practice with Hydroponics Kit</h2>';
SET @v_desc  := '<!-- LSN_DATA: [{"title": "Topic 1: Introduction to Hydroponics and Systems", "subsecs": [{"title": "Definition and history of hydroponics", "links": []}, {"title": "Advantages and disadvantages of hydroponics", "links": []}, {"title": "Basic components of a hydroponic system", "links": []}, {"title": "Different types of hydroponic systems (e.g., NFT, DWC, Ebb and Flow)", "links": []}, {"title": "Selecting the right system for specific crops", "links": []}, {"title": "Setting up and maintaining hydroponic systems", "links": []}]}, {"title": "Topic 2: Growing Media, Plant Nutrition, and Practical Application", "subsecs": [{"title": "Types of growing media used in hydroponics", "links": []}, {"title": "Nutrient solutions and their preparation", "links": []}, {"title": "Monitoring and adjusting pH and EC levels", "links": []}, {"title": "Assembling a basic hydroponic system", "links": []}, {"title": "Planting and caring for crops in a hydroponic system", "links": []}, {"title": "Maintenance and troubleshooting of hydroponic setups ", "links": []}]}, {"title": "Topic 3: Basic Techniques of Hydroponics Farming", "subsecs": [{"title": "Principles of indoor farming", "links": []}, {"title": "Lighting, temperature, and humidity control", "links": []}, {"title": "Integration of hydroponics into indoor farming setups", "links": []}, {"title": "Guided hydroponics farm tour", "links": []}, {"title": "Real-world application of hydroponic techniques", "links": []}, {"title": "Observation of commercial hydroponic operations", "links": []}, {"title": "Understanding farm management and maintenance practices", "links": []}]}, {"title": "Topic 4: Urban Farming Practices in Singapore", "subsecs": [{"title": "Basics of aquaponics and its benefits", "links": []}, {"title": "Setting up an aquaponics system", "links": []}, {"title": "Regulatory considerations and best practices for urban farming in Singapore", "links": []}, {"title": "Performing farming activities in compliance with prevailing regulations", "links": []}, {"title": "Good Agriculture Practices (GAPs) and Workplace Safety and Health (WSH) practices", "links": []}, {"title": "Equipment cleaning and maintenance techniques", "links": []}]}] -->\n<h3>Topic 1: Introduction to Hydroponics and Systems</h3>\n<ul><li>Definition and history of hydroponics</li><li>Advantages and disadvantages of hydroponics</li><li>Basic components of a hydroponic system</li><li>Different types of hydroponic systems (e.g., NFT, DWC, Ebb and Flow)</li><li>Selecting the right system for specific crops</li><li>Setting up and maintaining hydroponic systems</li></ul>\n<h3>Topic 2: Growing Media, Plant Nutrition, and Practical Application</h3>\n<ul><li>Types of growing media used in hydroponics</li><li>Nutrient solutions and their preparation</li><li>Monitoring and adjusting pH and EC levels</li><li>Assembling a basic hydroponic system</li><li>Planting and caring for crops in a hydroponic system</li><li>Maintenance and troubleshooting of hydroponic setups</li></ul>\n<h3>Topic 3: Basic Techniques of Hydroponics Farming</h3>\n<ul><li>Principles of indoor farming</li><li>Lighting, temperature, and humidity control</li><li>Integration of hydroponics into indoor farming setups</li><li>Guided hydroponics farm tour</li><li>Real-world application of hydroponic techniques</li><li>Observation of commercial hydroponic operations</li><li>Understanding farm management and maintenance practices</li></ul>\n<h3>Topic 4: Urban Farming Practices in Singapore</h3>\n<ul><li>Basics of aquaponics and its benefits</li><li>Setting up an aquaponics system</li><li>Regulatory considerations and best practices for urban farming in Singapore</li><li>Performing farming activities in compliance with prevailing regulations</li><li>Good Agriculture Practices (GAPs) and Workplace Safety and Health (WSH) practices</li><li>Equipment cleaning and maintenance techniques</li></ul>';

-- Guard: refuse the write if the prepared text ever grows a day/hour count or a
-- funding term. NULLing the value makes every UPDATE below a no-op.
SET @bad := (
  CONCAT(@v_short, ' ', @v_desc) REGEXP
  '(2-day|2 day|two-day|1-day|one-day|16 hours|15 hours|7\\.5 hours|WSQ|SSG|SkillsFuture|subsid)'
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

-- Partner servers (MY/GH) hold no C8 row, so @dst is NULL there and both
-- statements above are no-ops.
