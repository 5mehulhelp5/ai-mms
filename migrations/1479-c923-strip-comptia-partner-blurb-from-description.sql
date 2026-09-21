-- C923 — remove the "We are Authorized CompTIA Delivery Partner" blurb from the
-- stored course description.
--
-- The blurb is ALREADY invisible on the storefront: view.phtml (5b) strips it at
-- render, and the "CompTIA Authorised Delivery Partner" card (5d), driven by the
-- atc_partners attribute (C923 = comptia_adp), carries the canonical copy. But
-- the text was still sitting in short_description, so it kept showing up in the
-- admin Course Description editor. This removes it from the DATA too, so the
-- editor and the storefront agree.
--
-- The canonical wording now lives in exactly one place:
--   MMD_CourseImage_Helper_Data::getAtcPartners()['comptia_adp']
-- Do NOT re-add the blurb to any description; tick the ATC checkbox instead
-- (Edit Course -> ATC partners), which is what renders the card.
--
-- Guarded: the UPDATE only fires when the blurb is actually present, so a
-- re-run is a no-op. The new value is byte-identical to the old one minus the
-- <h3><span style="color:#ff0000">...</h3> block. CR/LF written as \r\n escape
-- sequences because .gitattributes forces migrations/*.sql to LF.
--
-- SG production; on partner sites the C923 SKU does not exist and this is a no-op.

SET @eid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C923' LIMIT 1);
SET @a_short := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'short_description' AND entity_type_id = 4 LIMIT 1);

UPDATE catalog_product_entity_text
   SET value = '<p>The CompTIA Data+ Training equips participants with essential skills in data management, including integrating datasets, conducting data mining, and performing statistical analysis to uncover trends and insights. Learn to apply various data manipulation techniques and optimize data usage for efficient processing. Participants will also understand how to interpret sequential patterns and establish meaningful linkages between variables, supporting effective business decision-making.</p>\n<p>Additionally, the course covers techniques for presenting data visually and communicating analytical outputs effectively. Topics include designing reports and dashboards, applying quality control measures, and understanding the principles of data governance. This training is ideal for professionals seeking to enhance their data analytics capabilities and drive data-informed decisions.</p>\n'
 WHERE @eid IS NOT NULL AND entity_id = @eid AND store_id = 0 AND attribute_id = @a_short
   AND value LIKE '%CompTIA Delivery Partner%';
