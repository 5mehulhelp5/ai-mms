-- 1540: TGS-2024045220 -> "WSQ - Generative AI for Photoshop"
--
-- Retitles the WSQ Photoshop/Firefly course, re-slugs it with permanent 301s
-- from every live URL, rewrites the overview + topics + learning outcomes to
-- the new approved copy, and repoints course_image_url at the regenerated
-- cover.
--
-- Title keeps the "WSQ - " prefix (the SKU is TGS-, the course sits in 8
-- wsq-* categories, and every sibling WSQ course carries it). The COVER
-- deliberately does NOT: Cover.php::cleanTitle() strips the prefix, and the
-- WSQ chip is omitted from the badge set, so the rendered PNG shows no WSQ.
--
-- The cover is a PRE-RENDERED PNG on R2 with the title baked in, so the
-- retitle alone would keep serving a cover reading "Generative AI (GenAI)
-- Visuals in Photoshop and Firefly". The new object was rendered by
-- MMD_CourseImage_Model_Cover (same code path as the admin cover dialog) and
-- uploaded to shared R2 storage:
--   course-covers/TGS-2024045220-20260922-171715.png   (158201 bytes)
-- Badges passed: SkillsFuture Credit, PSEA, UTAP, SFEC, Absentee Payroll,
-- MCES -- the product's own tag set MINUS the WSQ chip. The tag rows are NOT
-- touched, so the storefront funding pills and the WSQ Funding card are
-- unchanged; this is an image-only omission.
-- The superseded object is left on R2 so reverting is just repointing the URL.
--
-- Pricing, duration, sessions and schedule are NOT touched.
--
-- SG production only; keyed by SKU so a partner site with no TGS-2024045220
-- no-ops. Idempotent: re-running converges (plain UPDATEs + INSERT IGNORE).

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024045220' LIMIT 1);
SET @etype := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product');

-- name
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=@etype);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Generative AI for Photoshop'
 WHERE attribute_id = @a_name AND entity_id = @pid AND @pid IS NOT NULL;

-- url_key
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=@etype);
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-generative-ai-for-photoshop'
 WHERE attribute_id = @a_url AND entity_id = @pid AND @pid IS NOT NULL;

-- meta_title
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title' AND entity_type_id=@etype);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ Generative AI for Photoshop Course | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @pid AND @pid IS NOT NULL;

-- meta_description (<= 255 chars)
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@etype);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ Generative AI for Photoshop course in Singapore. Create and refine visuals with Adobe Firefly and Photoshop Generative Fill, build storyboards and master AI prompting. Up to 70% WSQ funding subsidy.'
 WHERE attribute_id = @a_md AND entity_id = @pid AND @pid IS NOT NULL;

-- image labels: the product page renders these as the cover's alt/title text,
-- so a stale label would still read the old course name. Only rows holding
-- exactly the OLD title are rewritten, leaving any admin customisation alone.
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = @etype
   AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label')
   SET v.value = 'WSQ - Generative AI for Photoshop'
 WHERE v.entity_id = @pid AND @pid IS NOT NULL
   AND v.value = 'WSQ - Generative AI (GenAI) Visuals in Photoshop and Firefly';

-- cover image: repoint at the regenerated PNG (global scope; clear any
-- store-scoped row that would shadow it)
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@etype);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_ciu, 0, @pid,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045220-20260922-171715.png'
 WHERE @pid IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @pid AND attribute_id = @a_ciu AND store_id <> 0
   AND @pid IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Content: overview (short_description) + topics (description)
-- ---------------------------------------------------------------------------
-- The LSN_DATA JSON comment at the head of `description` is what the course
-- outline widget parses; it is rewritten in lockstep with the visible markup
-- so the two never disagree. The old copy also carried U+FFFD replacement
-- characters (mojibake from a latin1-era write) in three topic headings --
-- rewriting the whole blob clears them.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@etype);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<p>This course equips participants with practical skills to use Generative AI (GenAI) with Adobe Photoshop and Adobe Firefly to create, edit, and enhance professional visual content. Learners will explore the fundamentals of generative AI for image creation and develop effective prompting techniques to generate visuals that meet specific design and communication objectives.</p>\n',
'<p>Participants will learn to use Adobe Firefly to generate images, develop visual concepts, explore creative variations, and create storyboards for communicating ideas and visual narratives. Emphasis is placed on translating design requirements into effective prompts and evaluating AI-generated outputs for relevance, quality, and visual consistency.</p>\n',
'<p>Using Adobe Photoshop, learners will apply AI-powered features such as Generative Fill and Generative Expand to add, remove, replace, and extend image elements. They will also practise inpainting, outpainting, object manipulation, image composition, colour correction, and other enhancement techniques to refine AI-generated and existing images.</p>\n',
'<p>Through hands-on activities and practical projects, participants will develop end-to-end AI-assisted design workflows, from defining visual objectives and generating initial concepts to editing, refining, and producing final visual assets. The course also develops learners&rsquo; ability to evaluate visual quality, provide constructive design critiques, and propose improvements based on visual communication and design principles.</p>\n',
-- Learning outcomes live in short_description under an <h2> heading -- the
-- house pattern used by the other WSQ courses (cf. TGS-2020504142). There is
-- no separate learning-outcome EAV attribute; "What You'll Learn" on the
-- product page renders `description`, and the overview card renders this.
'<h2>Course Learning Outcomes</h2>\n',
'<p>After the end of this course, learners will be able to</p>\n',
'<ul>\n',
'<li>LO1: Initiate visual communication through GAI in Photoshop and Firefly.</li>\n',
'<li>LO2: Create storyboards using GAI in Firefly that communicate visual narratives and task flows for team collaboration.</li>\n',
'<li>LO3: Propose enhancements to visual design using GAI by assessing aesthetics and applying advanced critique techniques in Photoshop.</li>\n',
'<li>LO4: Formulate GAI strategies employing color fundamentals to enhance the appeal of visual outputs in Photoshop.</li>\n',
'</ul>'
)
 WHERE attribute_id = @a_sdesc AND entity_id = @pid AND @pid IS NOT NULL;

SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description' AND entity_type_id=@etype);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<!-- LSN_DATA: [',
'{"title":"Topic 1: Generative AI for Visual Communication","subsecs":[',
'{"title":"Introduction to Generative AI (GenAI)","links":[]},',
'{"title":"Popular GenAI tools for image creation","links":[]},',
'{"title":"Using text prompts to create images","links":[]},',
'{"title":"Text prompt best practices","links":[]},',
'{"title":"Elements of visual communication design","links":[]},',
'{"title":"Best practices of visual communication","links":[]}]},',
'{"title":"Topic 2: Generative AI with Adobe Firefly","subsecs":[',
'{"title":"Generating images with content types and styles","links":[]},',
'{"title":"Mixing images with Match Image","links":[]},',
'{"title":"Setting colours, lighting and composition","links":[]},',
'{"title":"Developing visual concepts and creative variations","links":[]},',
'{"title":"Creating storyboards for visual narratives and task flows","links":[]},',
'{"title":"Creating text effects","links":[]},',
'{"title":"Creating design templates with Text to Template","links":[]}]},',
'{"title":"Topic 3: Generative AI with Adobe Photoshop","subsecs":[',
'{"title":"Using Generative Fill in Photoshop","links":[]},',
'{"title":"Inserting objects and subjects","links":[]},',
'{"title":"Removing subjects from an image","links":[]},',
'{"title":"Selecting objects and people","links":[]},',
'{"title":"Replacing image backgrounds and skies","links":[]},',
'{"title":"Using multiple prompts","links":[]},',
'{"title":"Generative Expand","links":[]},',
'{"title":"Inpainting and outpainting","links":[]}]},',
'{"title":"Topic 4: Enhancing and Refining AI-Generated Images","subsecs":[',
'{"title":"Image composition and object manipulation","links":[]},',
'{"title":"Colour fundamentals and colour correction","links":[]},',
'{"title":"Modifying environments and fixing AI faces","links":[]},',
'{"title":"Evaluating visual quality and applying design critique","links":[]},',
'{"title":"Proposing enhancements to visual design","links":[]}]}] -->\n',
'<p><strong>Topic 1: Generative AI for Visual Communication</strong></p>\n',
'<p><em>Introduction to Generative AI (GenAI)</em></p>\n',
'<p><em>Popular GenAI tools for image creation</em></p>\n',
'<p><em>Using text prompts to create images</em></p>\n',
'<p><em>Text prompt best practices</em></p>\n',
'<p><em>Elements of visual communication design</em></p>\n',
'<p><em>Best practices of visual communication</em></p>\n',
'<p><strong>Topic 2: Generative AI with Adobe Firefly</strong></p>\n',
'<p><em>Generating images with content types and styles</em></p>\n',
'<p><em>Mixing images with Match Image</em></p>\n',
'<p><em>Setting colours, lighting and composition</em></p>\n',
'<p><em>Developing visual concepts and creative variations</em></p>\n',
'<p><em>Creating storyboards for visual narratives and task flows</em></p>\n',
'<p><em>Creating text effects</em></p>\n',
'<p><em>Creating design templates with Text to Template</em></p>\n',
'<p><strong>Topic 3: Generative AI with Adobe Photoshop</strong></p>\n',
'<p><em>Using Generative Fill in Photoshop</em></p>\n',
'<p><em>Inserting objects and subjects</em></p>\n',
'<p><em>Removing subjects from an image</em></p>\n',
'<p><em>Selecting objects and people</em></p>\n',
'<p><em>Replacing image backgrounds and skies</em></p>\n',
'<p><em>Using multiple prompts</em></p>\n',
'<p><em>Generative Expand</em></p>\n',
'<p><em>Inpainting and outpainting</em></p>\n',
'<p><strong>Topic 4: Enhancing and Refining AI-Generated Images</strong></p>\n',
'<p><em>Image composition and object manipulation</em></p>\n',
'<p><em>Colour fundamentals and colour correction</em></p>\n',
'<p><em>Modifying environments and fixing AI faces</em></p>\n',
'<p><em>Evaluating visual quality and applying design critique</em></p>\n',
'<p><em>Proposing enhancements to visual design</em></p>\n'
)
 WHERE attribute_id = @a_desc AND entity_id = @pid AND @pid IS NOT NULL;

-- meta_keyword: drop the retired "Visuals/Firefly-first" phrasing
SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword' AND entity_type_id=@etype);
UPDATE catalog_product_entity_text
   SET value = 'Generative AI for Photoshop, Generative AI, Photoshop, Adobe Firefly, Generative Fill, Generative Expand, Visual Communication, AI Storyboards, Visual Design, AI Image Creation, AI Photo Editing, Inpainting, Outpainting, Colour Correction, WSQ Course Singapore'
 WHERE attribute_id = @a_mk AND entity_id = @pid AND @pid IS NOT NULL AND @a_mk IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Permanent 301s: old slug -> new slug, for the bare URL and each of the 18
-- category-prefixed paths the product is reachable at.
-- ---------------------------------------------------------------------------
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);
SET @old := 'wsq-generative-ai-genai-visuals-in-photoshop-and-firefly.html';
SET @new := 'wsq-generative-ai-for-photoshop.html';

-- Bare + every category prefix, derived from the product's own system
-- rewrites so the set can never drift from the live category memberships.
--
-- NOTE ON ORDERING: when refreshProductRewrite() runs (post-deploy step 2
-- below), Magento itself converts each old system row into exactly these
-- 301s, and this INSERT IGNORE then no-ops on the unique key -- which is the
-- normal, correct outcome. This block only does real work on a DB where the
-- refresh has NOT run (e.g. a rebuild replaying the ledger), so the old URLs
-- still redirect rather than 404. Either way the end state is identical.
--
-- Rows whose request_path is still held by a live is_system=1 rewrite are
-- excluded: inserting those would collide, and the refresh converts them
-- anyway.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid,
       CONCAT('tgs2024045220-genai-photoshop-', MD5(r.request_path)),
       r.request_path,
       CONCAT(
         CASE WHEN LOCATE('/', r.request_path) > 0
              THEN LEFT(r.request_path, LOCATE('/', r.request_path))
              ELSE '' END,
         @new),
       0, 'RP',
       '1540: TGS-2024045220 retitled to WSQ - Generative AI for Photoshop'
  FROM (SELECT DISTINCT request_path FROM core_url_rewrite
         WHERE product_id = @pid AND is_system = 1
           AND request_path LIKE CONCAT('%', @old)) r
 WHERE @pid IS NOT NULL AND @sid IS NOT NULL;

-- Flatten the PRE-EXISTING 301s that still point at the OLD slug, so the
-- historical URLs redirect once to the new slug instead of chaining 301 -> 301.
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path, @old, @new)
 WHERE is_system = 0
   AND target_path LIKE CONCAT('%', @old)
   AND id_path NOT LIKE 'tgs2024045220-genai-photoshop-%';
