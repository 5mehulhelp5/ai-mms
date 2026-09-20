-- C923 (CompTIA Data+ Training) — copy the course description and topics from the
-- WSQ parent TGS-2024049212, so both catalogue entries describe the same course.
--
-- Part of the WSQ -> non-WSQ courseware conversion. A recycled product entity
-- otherwise keeps the previous course's marketing copy, which reads plausibly and
-- survives every courseware scan (those read artifacts, not the storefront).
--
-- Guarded on the source text stating NO day count (checked before generating this
-- file); the non-WSQ twin's own Duration tile (37.5 hrs) and Sessions tile (5 days)
-- are already correct and are deliberately NOT touched here.
--
-- store_id = 0 (default scope), both attributes on catalog_product_entity_text.
-- Idempotent: re-running writes the same values. SG production; on partner sites
-- the C923 SKU does not exist and every statement is a no-op.

SET @eid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C923' LIMIT 1);
SET @a_short := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'short_description' AND entity_type_id = 4 LIMIT 1);
SET @a_desc  := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'description' AND entity_type_id = 4 LIMIT 1);

UPDATE catalog_product_entity_text
   SET value = '<p>The CompTIA Data+ Training equips participants with essential skills in data management, including integrating datasets, conducting data mining, and performing statistical analysis to uncover trends and insights. Learn to apply various data manipulation techniques and optimize data usage for efficient processing. Participants will also understand how to interpret sequential patterns and establish meaningful linkages between variables, supporting effective business decision-making.</p>
\\n<p>Additionally, the course covers techniques for presenting data visually and communicating analytical outputs effectively. Topics include designing reports and dashboards, applying quality control measures, and understanding the principles of data governance. This training is ideal for professionals seeking to enhance their data analytics capabilities and drive data-informed decisions.</p>
\\n<h3><span style="color: #ff0000;">We are Authorized CompTIA Delivery Partner</span></h3>'
 WHERE @eid IS NOT NULL AND entity_id = @eid AND store_id = 0 AND attribute_id = @a_short;

UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Data Concepts and Environments ","subsecs":[{"title":"Identifying Basic Concepts and Data Schemas","links":[]},{"title":"Understanding Different Data Systems","links":[]},{"title":"Understanding Types of Characteristics of Data","links":[]},{"title":"Comparing and Constructing Different Data Structures, Formats, and Markup Languages","links":[]}]},{"title":"Topic 2: Data Mining","subsecs":[{"title":"Explaining Data Integration and Collection Methods","links":[]},{"title":"Identifying Common Reasons for Cleansing and Profiling Data","links":[]},{"title":"Executing Different Data Manipulation Techniques","links":[]},{"title":"Explaining Common Techniques for Data Manipulation and Optimization","links":[]}]},{"title":"Topic 3: Data Analysis","subsecs":[{"title":"Applying Descriptive Statistical Methods","links":[]},{"title":"Describing Key Analysis Techniques","links":[]},{"title":"Understanding the Use of Different Statistical Methods","links":[]}]},{"title":"Topic 4: Visualization","subsecs":[{"title":"Using the Appropriate Type of Visualization","links":[]},{"title":"Expressing Business Requirements in a Report Format","links":[]},{"title":"Designing Components for Reports and Dashboards","links":[]},{"title":"Distinguishing Different Report Types","links":[]}]},{"title":"Topic 5: Data Governance, Quality, and Controls","subsecs":[{"title":"Summarizing the Importance of Data Governance","links":[]},{"title":"Applying Quality Control to Data","links":[]},{"title":"Explaining Master Data Management Concepts","links":[]}]}] -->
\\n<p><strong>Topic 1: Data Concepts and Environments </strong></p>
\\n<p><em>Identifying Basic Concepts and Data Schemas</em></p>
\\n<p><em>Understanding Different Data Systems</em></p>
\\n<p><em>Understanding Types of Characteristics of Data</em></p>
\\n<p><em>Comparing and Constructing Different Data Structures, Formats, and Markup Languages</em></p>
\\n<p><strong>Topic 2: Data Mining</strong></p>
\\n<p><em>Explaining Data Integration and Collection Methods</em></p>
\\n<p><em>Identifying Common Reasons for Cleansing and Profiling Data</em></p>
\\n<p><em>Executing Different Data Manipulation Techniques</em></p>
\\n<p><em>Explaining Common Techniques for Data Manipulation and Optimization</em></p>
\\n<p><strong>Topic 3: Data Analysis</strong></p>
\\n<p><em>Applying Descriptive Statistical Methods</em></p>
\\n<p><em>Describing Key Analysis Techniques</em></p>
\\n<p><em>Understanding the Use of Different Statistical Methods</em></p>
\\n<p><strong>Topic 4: Visualization</strong></p>
\\n<p><em>Using the Appropriate Type of Visualization</em></p>
\\n<p><em>Expressing Business Requirements in a Report Format</em></p>
\\n<p><em>Designing Components for Reports and Dashboards</em></p>
\\n<p><em>Distinguishing Different Report Types</em></p>
\\n<p><strong>Topic 5: Data Governance, Quality, and Controls</strong></p>
\\n<p><em>Summarizing the Importance of Data Governance</em></p>
\\n<p><em>Applying Quality Control to Data</em></p>
\\n<p><em>Explaining Master Data Management Concepts</em></p>
\\n'
 WHERE @eid IS NOT NULL AND entity_id = @eid AND store_id = 0 AND attribute_id = @a_desc;
