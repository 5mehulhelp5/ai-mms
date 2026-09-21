-- 1506: C926 — copy course copy from the WSQ parent (TGS-2023036651) and point the
-- funding block at that WSQ twin.
--
-- Per the non-wsq-courseware-duplication run sheet §8 + §9:
--   §9  short_description + description are copied from the WSQ parent so both
--       catalogue entries describe the same course. WSQ/funding wording and the
--       certification-exam claim are stripped; no day count appears in the text.
--   §8  the non-WSQ course carries no funding of its own, so its Funding block
--       redirects to the funded WSQ twin (verified 200, no redirect chain).
--
-- Content-only UPDATEs. NEVER ->save() a cms/block model (wipes cms_block_store).
-- Idempotent: re-running is a no-op. SG only — guarded on the C926 SKU, so no
-- TGS-/M- course and no partner site row is touched.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C926');

SET @a_short := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'short_description'
                    AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type
                                           WHERE entity_type_code = 'catalog_product'));
SET @a_desc  := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'description'
                    AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type
                                           WHERE entity_type_code = 'catalog_product'));
SET @a_meta  := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'meta_description'
                    AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type
                                           WHERE entity_type_code = 'catalog_product'));

-- short_description — every scope row, so no store override serves the old copy
UPDATE catalog_product_entity_text
   SET value = '<p>This Microsoft Certified Azure AI Engineer Associate (AI-102) Training provides learners with the expertise to design, build, and deploy AI-powered applications using Microsoft Azure AI Services. This course covers key areas, including computer vision, natural language processing, AI-powered search, document intelligence, and generative AI with Azure OpenAI. Participants will learn how to create, secure, and optimize AI services, enabling seamless integration into business applications. The curriculum also emphasizes responsible AI usage, content safety, and model monitoring to ensure ethical AI deployment.</p> <p>Through practical hands-on exercises, learners will develop intelligent applications that leverage Azure AI Vision for image analysis, Azure AI Language for NLP tasks, and Azure AI Search for knowledge mining. Participants will also work with Azure AI Document Intelligence for data extraction and explore generative AI applications using Azure OpenAI Service. By the end of this course, learners will be well-equipped to apply Azure AI solutions to real-world business challenges.</p>'
 WHERE entity_id = @pid AND attribute_id = @a_short AND @pid IS NOT NULL;

-- description (carries the LSN_DATA topic JSON)
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"LU1 Introduction to Microsoft Azure AI Applications","subsecs":[{"title":"Topic 1 Get started with Azure AI Services","links":[]},{"title":"Topic 2 Create computer vision solutions with Azure AI Vision","links":[]}]},{"title":"LU2 Evaluate Microsoft Azure AI Applications","subsecs":[{"title":"Topic 3 Develop natural language processing solutions with Azure AI Services","links":[]},{"title":"Topic 4 Implement knowledge mining with Azure AI Search","links":[]}]},{"title":"LU3 Develop Azure AI Solutions","subsecs":[{"title":"Topic 5 Develop solutions with Azure AI Document Intelligence","links":[]},{"title":"Topic 6 Develop Generative AI solutions with Azure OpenAI Service","links":[]}]}] -->\r\n<p><strong>LU1 Introduction to Microsoft Azure AI Applications</strong></p>\r\n<p><em>Topic 1 Get started with Azure AI Services</em></p>\r\n<p><em>Topic 2 Create computer vision solutions with Azure AI Vision</em></p>\r\n<p><strong>LU2 Evaluate Microsoft Azure AI Applications</strong></p>\r\n<p><em>Topic 3 Develop natural language processing solutions with Azure AI Services</em></p>\r\n<p><em>Topic 4 Implement knowledge mining with Azure AI Search</em></p>\r\n<p><strong>LU3 Develop Azure AI Solutions</strong></p>\r\n<p><em>Topic 5 Develop solutions with Azure AI Document Intelligence</em></p>\r\n<p><em>Topic 6 Develop Generative AI solutions with Azure OpenAI Service</em></p>'
 WHERE entity_id = @pid AND attribute_id = @a_desc AND @pid IS NOT NULL;

-- meta_description — parent's ended "Enjoy up to 70% WSQ funding subsidy"; a
-- non-WSQ course must not claim funding. varchar(255).
UPDATE catalog_product_entity_varchar
   SET value = 'Master Azure AI development with our Microsoft Certified Azure AI Engineer Associate (AI-102) course. Build computer vision, NLP, search and generative AI solutions at Tertiary Courses Singapore.'
 WHERE entity_id = @pid AND attribute_id = @a_meta AND @pid IS NOT NULL;

-- Funding block -> the funded WSQ twin
UPDATE cms_block
   SET content = '<p>This course is not eligible for funding. A funded WSQ version of this course is available: <a href="https://www.tertiarycourses.com.sg/wsq-microsoft-certified-azure-ai-engineer-associate-ai-102-training.html">WSQ Microsoft Certified Azure AI Engineer Associate (AI-102) Training</a>.</p>'
 WHERE identifier = 'course_C926_funding_and_grant';
