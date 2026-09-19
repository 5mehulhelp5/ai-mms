-- Same recycled-entity problem in meta_description: C169 still carried the retired
-- C-Programming course's copy ("Learn C programming with AI vibe coding ... 1-day
-- course"). Replace with the interviewing copy, minus the WSQ funding claim the
-- parent carries (a non-WSQ course has no funding) and minus any day count.
-- varchar(255) cap; this string is 242 chars.

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity e ON e.entity_id = v.entity_id
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
                      AND a.attribute_code = 'meta_description'
                      AND a.entity_type_id = 4
   SET v.value = 'Use Generative AI across the interviewing process - plan structured interviews, generate role-specific questions, evaluate candidate responses and support fair, evidence-based hiring decisions. Hands-on training at Tertiary Courses Singapore.'
 WHERE e.sku = 'C169' AND v.store_id = 0;
