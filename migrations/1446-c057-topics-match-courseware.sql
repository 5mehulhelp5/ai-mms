-- 1446: C057 "Microsoft Copilot for Finance" -- align the product page with the
--       courseware that was duplicated from the WSQ parent TGS-2026065050.
--
-- Migration 1435 renamed C057 and copied the CASL twin's STOREFRONT copy, which
-- carries a FIVE-topic outline. The courseware duplication (GitHub
-- C057-Microsoft-Copilot-for-Finance, commit 43e4fd0) is built from the WSQ
-- parent's DECK, whose syllabus is SIX topics. Admin decision: the page follows
-- the courseware, so the topic list below replaces the five-topic version.
--
-- Topics are the WSQ parent's six, verbatim from the deck's topic slides. The
-- course is 2 days / 15 hrs (unchanged), so the labs are a subset: 8 of the 12
-- run in class and the rest ship as self-paced extension work -- that is a
-- courseware-side fact and is NOT stated in the topic list.
--
-- sessions: live holds 4 (inherited from the retired course and never corrected
-- by 1435). The course runs over 2 days, so this becomes 2. duration is already
-- 15 and price 700 -- neither is touched.
--
-- meta_description already reads "Hands-on 2-day course", which is CORRECT for
-- C057 (it really is 2 days) -- deliberately left alone. The
-- feedback_rename_migration_leaves_stale_body_copy sweep for a WRONG day count
-- found none: 15 hrs / 2 days / $700 agree across duration, the page copy and
-- the Lesson Plan.
--
-- short_description is NOT rewritten: 1435 already set the adopted overview and
-- it describes this same syllabus (Excel Copilot FP&A, agentic automation, risk
-- and fraud, governance). Rewriting it would be churn and risks the legacy
-- funding-card fallback (memory feedback_conversion_drops_legacy_funding_fallback).
--
-- SG-only via @mms_instance. ASCII-only payload (memory
-- feedback_migration_applyphp_utf8_outage). Flat catalog must be reindexed and
-- cache flushed after this applies (memory feedback_flat_catalog_reindex).

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C057');

SET @a_desc     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_sessions := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='sessions');

-- ---------------------------------------------------------------------------
-- 1. description -- the courseware's six topics
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<h3 class="course-topic-h3">Topic 1: Generative AI, Agentic AI and AI Agents in Finance</h3>
<ul>
<li>How Generative AI, Agentic AI and AI Agents differ</li>
<li>Finance and fintech use cases for each AI type</li>
<li>Copilot in Word and PowerPoint for finance reporting</li>
<li>Build a no-code Microsoft 365 finance agent</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Excel Copilot for Financial Analysis and Dashboards</h3>
<ul>
<li>Data readiness and workbook structure for Copilot</li>
<li>Auditing Copilot-generated formulas</li>
<li>Variance analysis, visualisation and dashboards</li>
<li>Driver-based forecasting</li>
</ul>
<h3 class="course-topic-h3">Topic 3: SharePoint for Finance and Grounded Finance Agents</h3>
<ul>
<li>Finance sites, typed lists and approved libraries</li>
<li>Permissions and the approved-content boundary</li>
<li>Agents grounded on approved content that refuse rather than guess</li>
</ul>
<h3 class="course-topic-h3">Topic 4: Copilot Studio Workflows and Agents for Finance Automation</h3>
<ul>
<li>Environments, agent flows, skills and tools</li>
<li>Connecting an agent to finance data in SharePoint</li>
<li>A blocking human approval gate that fails safe</li>
</ul>
<h3 class="course-topic-h3">Topic 5: Multi-Agent Orchestration of Financial Work Processes</h3>
<ul>
<li>Supervisor and specialist agents</li>
<li>Handoff contracts between agents</li>
<li>Month-end close orchestration and where orchestration breaks</li>
</ul>
<h3 class="course-topic-h3">Topic 6: AI Security, PDPA and Human Oversight in Finance</h3>
<ul>
<li>PDPA obligations and data classification for finance data</li>
<li>Data leakage, ownership and prompt injection</li>
<li>Copilot Studio security settings and agent governance</li>
<li>Human oversight models that are real rather than decorative</li>
</ul>'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_desc;

-- ---------------------------------------------------------------------------
-- 2. sessions -- 2 days, not the inherited 4
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = '2'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_sessions;
