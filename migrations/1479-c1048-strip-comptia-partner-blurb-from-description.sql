-- C1048 CompTIA Server+ Training — remove the inline "We are Authorized CompTIA
-- Delivery Partner" heading from short_description.
--
-- Why: the partner accreditation card is rebuilt from the `atc_partners`
-- checkboxes (C1048 already has `comptia_adp` set), NOT from the description and
-- NOT from a per-course cms/block. Migration 1407 stripped this blurb out of every
-- description for exactly that reason; C1048 re-acquired it when its description
-- was copied from the WSQ parent TGS-2024048318 after 1407 had run.
--
-- The storefront already hides it at render time (view.phtml step 5b), so the live
-- page is correct today — but the raw value still shows in admin Edit Course, and
-- relying on a render-time regex to mask stored content is the drift 1407 removed.
-- Deliberately creates NO cms/block: see the note in 1407 and in view.phtml (5d).
--
-- Idempotent: keyed on the exact trailing markup, so a re-run matches nothing.
-- NOTE: the separator before the <h3> is a real CRLF; CHAR(13),CHAR(10) states
-- that explicitly rather than relying on escape handling in a string literal.
-- SG production only; guard no-ops on partner sites (MY/GH).

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity e ON e.entity_id = t.entity_id
  JOIN eav_attribute a
       ON a.attribute_id = t.attribute_id
      AND a.attribute_code = 'short_description'
      AND a.entity_type_id = e.entity_type_id
   SET t.value = REPLACE(t.value,
         CONCAT(CHAR(13), CHAR(10),
                '<h3><span style="color: #ff0000;">We are Authorized CompTIA Delivery Partner</span></h3>'),
         '')
 WHERE e.sku = 'C1048'
   AND t.store_id = 0
   AND t.value LIKE '%We are Authorized CompTIA Delivery Partner%'
   AND EXISTS (SELECT 1 FROM core_config_data
                WHERE path = 'web/unsecure/base_url'
                  AND value LIKE '%tertiarycourses.com.sg%');
