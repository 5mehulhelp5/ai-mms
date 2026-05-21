-- Sync product TGS-2024043854 (entity_id 1296) from the live SG storefront.
-- The remote (Coolify production) DB has updated `name`, `short_description`,
-- and `description` for this WSQ course (rebranded from "Mastering AI Agentic
-- RAG and Workflows with No Code" → "Build a Human–AI Workforce with
-- Autonomous AI Agents"). This migration syncs the same three EAV values
-- into the local dev DB so admins working against localhost see the same
-- content as the production storefront.
--
-- Scope: store_id = 0 (default scope used by the SG storefront) only.
-- The store_id=2 (Malaysia) override row on this entity is left untouched —
-- it carries a different, MY-specific course tied to a `google-drive-...`
-- url_key and must NOT be overwritten by SG content.
--
-- Idempotent: re-running the migration writes the same values; no row count
-- drift, no duplicate inserts (INSERT ... ON DUPLICATE KEY UPDATE).

SET @entity_id := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024043854');

SET @attr_name              := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @attr_short_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @attr_description       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- name (varchar)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_name, 0, @entity_id, 'WSQ - Build a Human–AI Workforce with Autonomous AI Agents')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- short_description (text)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_short_description, 0, @entity_id, '<p>This course introduces participants to the new paradigm of human and AI collaborative digital workforces powered by autonomous AI agents and multi-agent ecosystems. Participants will explore modern agentic AI platforms such as OpenClaw, Hermes Agent, OpenHands, Claude Code agents, OpenHuman, and other emerging AI agent operating systems that enable AI agents to autonomously perform tasks, collaborate with human users, orchestrate workflows, and interact with enterprise tools and APIs. The course covers the setup and deployment of autonomous AI agents, multi-agent collaboration, digital workforce orchestration, skill and sub-agent development, workflow automation, and real-world applications of AI-powered digital workers across business and operational environments.</p><p>Participants will also learn how to optimize, secure, and scale autonomous AI agent ecosystems for enterprise deployment. Topics include AI governance, permissions management, memory and context engineering, Agentic RAG, persistent memory systems, token and cost optimization, and secure deployment practices for AI agents operating in production environments. Learners will evaluate and improve the effectiveness of RAG and Agentic RAG approaches used in modern AI systems, including contextual retrieval and memory-driven workflows beyond traditional vector-based retrieval methods. By the end of the course, participants will be able to design, deploy, manage, and optimize AI-powered digital workforce solutions that support automation, operations, customer engagement, software development, and digital transformation initiatives across organizations.</p>
<h2>Learning Outcomes</h2>
<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Analyze LLM applications across a range of industries to identify their capabilities and limitations.</li>
<li>LO2:&nbsp;Establish the relationship between LLM design and Chatbot efficiency.</li>
<li>LO3:&nbsp;Evaluate and improve RAG application effectiveness in product.</li>
</ul>
<h2>Course Brochure</h2>
<p><span style="text-decoration: underline;"><a href="https://drive.google.com/file/d/1u30wzdYZcQz2tMvvUzLW8Ze3TNyW5ecQ/view?usp=sharing" title="WSQ - Mastering AI Agentic RAG and Workflows with No Code Brochure" target="_blank">Download WSQ - Mastering AI Agentic RAG and Workflows with No Code Brochure</a></span></p>
<h2>Skills Framework</h2>
<p>This course follows the guideline of<strong>&nbsp;Artificial Intelligence Application in Product Development ICT-TEM-4034-1.1</strong>&nbsp;under ICT Skills Framework</p>
<h2>Certification</h2>
<ul>
<li>
<p><strong>Certificate of Completion from Tertiary Infotech</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Completion from Tertiary Infotech.</p>
</li>
<li>
<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</p>
</li>
</ul>
<div style="background-color: #dddddd; width: 100%; padding: 10px; border-radius: 25px;">
<h2>WSQ Funding</h2>
<p>WSQ funding is only applicable to Singaporeans and PR. Subject to eligibility, the funding support is subjected to funding caps.</p>
<p></p>
<table border="1" style="width: 100%;">
<tbody>
<tr>
<td colspan="5" style="text-align: center;"><strong></strong><strong></strong><strong><span>Effective for courses starting from 1 Jan 2024</span></strong></td>
</tr>
<tr>
<td rowspan="2" style="text-align: center;"><strong>Full Fee</strong></td>
<td rowspan="2" style="text-align: center;"><strong>GST</strong></td>
<td colspan="3" style="text-align: center;"><strong>Nett Fee after Funding (Incl. GST)</strong></td>
</tr>
<tr>
<td style="text-align: center;"><span><strong>Baseline</strong></span></td>
<td style="text-align: center;"><strong>MCES / SME</strong></td>
</tr>
<tr>
<td style="text-align: center;">$900.00</td>
<td style="text-align: center;">$81.00</td>
<td style="text-align: center;">$531.00</td>
<td style="text-align: center;">$351.00</td>
</tr>
</tbody>
</table>
<p>Baseline: Singaporean/PR age 21 and above<br>MCES(Mid-Career Enhanced Subsidy): S''porean age 40 &amp; above</p>
<p>Upon registration, we will advise further on how to tap on the WSQ Training Subsidy.</p>
<hr>
<p>You can pay the nett fee (a<span>fter the WSQ training subsidy)&nbsp;</span>by the following :</p>
<h3>SkillsFuture Enterprise Credit (SFEC)</h3>
<p>Eligible Singapore-registered companies can tap on $10000 SFEC to cover out-of-pocket expenses.<a href="https://skillsfuture.gobusiness.gov.sg/course-directory/courses/TGS-2024043854" target="_blank"><span style="color: #ff0000; text-decoration-line: underline;">Click here to submit SkillsFuture Enterprise Credit</span></a></p>
<h3>SkillsFuture Credit (SFC)</h3>
<p>Eligible Singapore Citizens can use their SFC to offset course fee payable after funding but the $4,000 Additional SFC (Mid-Career Support) cannot be used. <a href="https://www.myskillsfuture.gov.sg/content/portal/en/training-exchange/course-directory/course-detail.html?courseReferenceNumber=TGS-2024043854" title="SkillsFuture Credit" target="_blank"><span style="color: #ff0000; text-decoration-line: underline;">Click here for SkillsFuture Credit submission</span></a></p>
<p></p>
<h3>UTAP</h3>
<p>Eligible NTUC members can apply for 50% of the unfunded fee from UTAP, capped up to $250/year and for members aged 40 and above, capped up to $500/year.&nbsp;<span style="text-decoration: underline;"><span style="color: #ff0000;"><a href="https://www.ntuc.org.sg/wps/portal/up2/home/eserviceslanding?id=6bc1ca2c-ce81-4acb-a28f-c0be586e185f" target="_blank"><span style="color: #ff0000; text-decoration: underline;">Click here to submit UTAP</span></a></span></span></p>
<p></p>
<h3>PSEA</h3>
<p>Eligible Singapore Citizens can use their PSEA funds to offset course fee payable after funding.</p>
To check for Post-Secondary Education Account (PSEA) eligibility for this course, <a href="https://www.myskillsfuture.gov.sg/content/portal/en/training-exchange/course-directory/course-detail.html?courseReferenceNumber=TGS-2024043854" title="SkillsFuture Credit" target="_blank"><span style="color: #ff0000; text-decoration-line: underline;">Visit SkillsFuture (course code: TGS-2024043854) </span></a>
<ul>
<li>Scroll down to “Keyword Tags” to verify for PSEA eligibility.</li>
<li>If there is “PSEA” under keyword tags, the course is eligible for PSEA.</li>
</ul>
<p>Once you are eligible for PSEA, please download and fill up the <a href="https://www.moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form.pdf" title="PSEA Withdrawal Form" target="_blank"><span style="text-decoration: underline; color: #ff0000;">PSEA Withdrawal Form</span></a> and email to us.&nbsp;</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- description (text)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_description, 0, @entity_id, '<!-- LSN_DATA: [{"title":"Topic 1: Overview of AI Agents and Agentic AI Workflows","subsecs":[{"title":"What is AI Agent and Agentic AI?","links":[]},{"title":"Agentic AI vs Generative AI","links":[]},{"title":"LLM Reasoning Frameworks","links":[]},{"title":"Use Cases of Agentic AI Workflows - APA and Computer Use","links":[]},{"title":"Introduction to Agentic AI platforms - n8n & Langflow","links":[]},{"title":"Create an AI Agent on Agentic AI Platforms","links":[]}]},{"title":"Topic 2: Build Agentic AI Chatbots on No-Code Platforms","subsecs":[{"title":"Introduction to AI Chatbot Platforms - Agentx, Promptly & Flowise","links":[]},{"title":"Create a Agentic AI Chatbot on AI Chatbot Platforms","links":[]},{"title":"Introduction to Digital Human Avatar powered by HeyGen","links":[]},{"title":"Create a Digital Human Avatar Chatbot with No Code","links":[]}]},{"title":"Topic 3: Build Retrieval Augmented Generation (RAG) Applications on No-Code Platforms","subsecs":[{"title":"Overview of Retrieval Augmented Generation (RAG)","links":[]},{"title":"Create Agentic RAG on No-Code Platforms","links":[]},{"title":"Introduction to Agentic Search and Deep Research","links":[]},{"title":"Create AI Agents and RAG on Microsoft Copilot Studio","links":[]},{"title":"Final Assessment ","links":[]},{"title":"Written Assessment - Short Answer Questions (WA-SAQ)","links":[]},{"title":"Practical Performance (PP)","links":[]}]}] -->
<p><strong>Topic 1: Overview of AI Agents and Agentic AI Workflows</strong></p>
<p><em>What is AI Agent and Agentic AI?</em></p>
<p><em>Agentic AI vs Generative AI</em></p>
<p><em>LLM Reasoning Frameworks</em></p>
<p><em>Use Cases of Agentic AI Workflows - APA and Computer Use</em></p>
<p><em>Introduction to Agentic AI platforms - n8n &amp; Langflow</em></p>
<p><em>Create an AI Agent on Agentic AI Platforms</em></p>
<p><strong>Topic 2: Build Agentic AI Chatbots on No-Code Platforms</strong></p>
<p><em>Introduction to AI Chatbot Platforms - Agentx, Promptly &amp; Flowise</em></p>
<p><em>Create a Agentic AI Chatbot on AI Chatbot Platforms</em></p>
<p><em>Introduction to Digital Human Avatar powered by HeyGen</em></p>
<p><em>Create a Digital Human Avatar Chatbot with No Code</em></p>
<p><strong>Topic 3: Build Retrieval Augmented Generation (RAG) Applications on No-Code Platforms</strong></p>
<p><em>Overview of Retrieval Augmented Generation (RAG)</em></p>
<p><em>Create Agentic RAG on No-Code Platforms</em></p>
<p><em>Introduction to Agentic Search and Deep Research</em></p>
<p><em>Create AI Agents and RAG on Microsoft Copilot Studio</em></p>
<p><em>Final Assessment </em></p>
<p><em>Written Assessment - Short Answer Questions (WA-SAQ)</em></p>
<p><em>Practical Performance (PP)</em></p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
