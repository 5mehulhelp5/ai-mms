-- 1545: C1311 - copy description + topics from its WSQ parent
--
-- C1311 "Generative AI for Sustainability Reporting" is the non-WSQ twin of
-- TGS-2023036644 "AI for Sustainability Reporting", so both catalogue entries
-- must describe the same course. This entity was recycled and still carried the
-- PREVIOUS course's marketing copy, which reads plausibly and survives every
-- courseware scan (those read artifacts, not the storefront):
--   * 4 topics against the parent's 3 (an invented syllabus)
--   * a "hands-on 2-day course" opener and a "2-day course" meta_description
--
-- Fixed here by copying the parent's own short_description (About This Course)
-- and description (course topics) verbatim, and rewriting meta_description
-- without a day count. Both copied blobs were asserted free of any day-count
-- phrase before shipping, so nothing contradicts the Duration tile.
--
-- NOT touched: duration (15) and sessions (2) are already correct for the
-- 2-day course, and the parent carries no LSN_DATA header to preserve.
--
-- After deploy the flat catalog must be reindexed or the page keeps serving the
-- old copy (see memory feedback_flat_catalog_reindex).
--
-- SG production only; keyed by SKU so a partner site without it no-ops.
-- Idempotent: plain UPDATEs.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1311' LIMIT 1);
SET @et  := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ------------------------------------------------- short_description (About)
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = '<p>Enhance your expertise in Sustainability Reporting with Artificial Intelligence (AI) through this practical course designed to help professionals streamline and strengthen the sustainability reporting process. Learn how AI and Generative AI tools can support the collection and analysis of sustainability data, identify reporting gaps, and transform verified information into clear and structured sustainability disclosures.</p><p>Participants will gain hands-on experience using AI to support key reporting activities, including data preparation, framework mapping, gap analysis, narrative drafting, compliance checking, and evidence management. The course also explores effective prompt engineering techniques to generate accurate, relevant, and source-based reporting content while reducing the risks of hallucinations and unsupported claims.</p><p>Through practical exercises and real-world reporting scenarios, participants will learn how to integrate AI into sustainability reporting workflows while maintaining human oversight, data accuracy, traceability, and responsible AI practices. By the end of the course, participants will be equipped to use AI effectively to produce more efficient, consistent, and audit-ready sustainability reports aligned with recognised sustainability reporting requirements.</p>'
 WHERE attribute_id = @a_sd AND entity_id = @pid AND @pid IS NOT NULL;

-- ------------------------------------------------- description (topics)
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1: Introduction to AI for Sustainability Reporting</h3><ul><li>Overview of sustainability reporting and ESG disclosure requirements</li><li>Objectives of sustainability reports and organisational reporting procedures</li><li>How AI and Generative AI support the sustainability reporting process</li><li>AI tools and capabilities across the reporting workflow</li><li>Prompt engineering for accurate, source-based reporting content</li><li>Managing hallucinations, unsupported claims and responsible AI use</li></ul><h3 class="course-topic-h3">Topic 2: AI-Assisted Sustainability Data Analysis and Report Development</h3><ul><li>Preparing and structuring sustainability data for AI analysis</li><li>Using AI to analyse sustainability data and surface insights</li><li>Mapping disclosures to GRI standards and reporting frameworks</li><li>AI-assisted gap analysis to identify missing or incomplete disclosures</li><li>Drafting sustainability report narratives with Generative AI</li><li>Collaborating with stakeholders on AI-assisted report development</li></ul><h3 class="course-topic-h3">Topic 3: AI-Assisted Report Review, Compliance and Presentation</h3><ul><li>Using AI to proofread and refine sustainability reports</li><li>AI-assisted compliance checking against reporting requirements</li><li>Evidence management, traceability and audit readiness</li><li>Displaying sustainability data effectively with AI support</li><li>Human oversight, verification and data accuracy safeguards</li><li>Submitting and presenting reports to relevant stakeholders</li></ul>'
 WHERE attribute_id = @a_desc AND entity_id = @pid AND @pid IS NOT NULL;

-- ------------------------------------------------- meta_description (<=255)
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'Produce audit-ready sustainability reports with AI. Learn to use AI and Generative AI for ESG data analysis, GRI framework mapping, gap analysis, narrative drafting and compliance checks at Tertiary Courses Singapore.'
 WHERE attribute_id = @a_md AND entity_id = @pid AND @pid IS NOT NULL;
