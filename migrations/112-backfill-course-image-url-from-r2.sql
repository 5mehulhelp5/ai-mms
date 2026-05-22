-- Backfill course_image_url with R2 URLs that were generated on localhost.
-- The Bulk AI Covers run on local successfully uploaded 299 PNGs to the
-- shared R2 bucket but the URLs were saved only to the LOCAL DB; live
-- never got them. R2 holds the source of truth for the file paths, so
-- copying the saved mapping into live avoids re-rendering and re-uploading.
--
-- Strategy:
--   1. Look up attribute_id for course_image_url at runtime (avoids
--      hardcoding 203 in case the live install assigned a different id).
--   2. Look up entity_type_id for catalog_product the same way.
--   3. For each SKU we know about, INSERT … ON DUPLICATE KEY UPDATE
--      into catalog_product_entity_varchar at store_id=0 (global scope,
--      matches the attribute's is_global=1 setting).
--
-- Re-runnable: ON DUPLICATE KEY UPDATE makes the second run a no-op.
-- After applying, run "Bulk AI Covers → Refresh storefront" on live to
-- rebuild the flat catalog index and flush block_html / FPC caches.

SET @attr  := (SELECT attribute_id FROM eav_attribute
                WHERE attribute_code='course_image_url' LIMIT 1);
SET @etype := (SELECT entity_type_id FROM eav_entity_type
                WHERE entity_type_code='catalog_product' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2019503161-20260522-041433.png'
  FROM catalog_product_entity WHERE sku='TGS-2019503161'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2019503343-20260522-041434.png'
  FROM catalog_product_entity WHERE sku='TGS-2019503343'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2019504058-20260522-041441.png'
  FROM catalog_product_entity WHERE sku='TGS-2019504058'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2019504591-20260522-041443.png'
  FROM catalog_product_entity WHERE sku='TGS-2019504591'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2019504643-20260522-041445.png'
  FROM catalog_product_entity WHERE sku='TGS-2019504643'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2019504744-20260522-041448.png'
  FROM catalog_product_entity WHERE sku='TGS-2019504744'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503109-20260522-041450.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503109'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503177-20260522-041452.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503177'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503207-20260522-041453.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503207'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503264-20260522-041454.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503264'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503395-20260522-041454.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503395'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503487-20260522-041455.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503487'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503501-20260522-041456.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503501'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503531-20260522-041457.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503531'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503626-20260522-041458.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503626'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503676-20260522-041459.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503676'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503771-20260522-041502.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503771'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503869-20260522-041504.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503869'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020503940-20260522-041504.png'
  FROM catalog_product_entity WHERE sku='TGS-2020503940'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504020-20260522-041506.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504020'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504082-20260522-041506.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504082'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504142-20260522-041507.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504142'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504192-20260522-041508.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504192'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504243-20260522-041510.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504243'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504357-20260522-041516.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504357'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504413-20260522-041517.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504413'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504518-20260522-041519.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504518'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504540-20260522-041520.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504540'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504665-20260522-041521.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504665'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504706-20260522-041522.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504706'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504808-20260522-041522.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504808'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020504974-20260522-041523.png'
  FROM catalog_product_entity WHERE sku='TGS-2020504974'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505042-20260522-041524.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505042'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505109-20260522-041525.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505109'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505113-20260522-041526.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505113'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505315-20260522-041527.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505315'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505317-20260522-041527.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505317'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505433-20260522-041528.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505433'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505444-20260522-041529.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505444'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505545-20260522-041530.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505545'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505550-20260522-041530.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505550'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505561-20260522-041531.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505561'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505790-20260522-041532.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505790'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505815-20260522-041533.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505815'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505925-20260522-041533.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505925'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505996-20260522-041534.png'
  FROM catalog_product_entity WHERE sku='TGS-2020505996'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020506075-20260522-041536.png'
  FROM catalog_product_entity WHERE sku='TGS-2020506075'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020513213-20260522-041539.png'
  FROM catalog_product_entity WHERE sku='TGS-2020513213'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021002336-20260522-041540.png'
  FROM catalog_product_entity WHERE sku='TGS-2021002336'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021002504-20260522-041542.png'
  FROM catalog_product_entity WHERE sku='TGS-2021002504'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021002619-20260522-041543.png'
  FROM catalog_product_entity WHERE sku='TGS-2021002619'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021003023-20260522-041543.png'
  FROM catalog_product_entity WHERE sku='TGS-2021003023'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021003160-20260522-041548.png'
  FROM catalog_product_entity WHERE sku='TGS-2021003160'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021003585-20260522-041546.png'
  FROM catalog_product_entity WHERE sku='TGS-2021003585'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021004287-20260522-041548.png'
  FROM catalog_product_entity WHERE sku='TGS-2021004287'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021005538-20260522-041547.png'
  FROM catalog_product_entity WHERE sku='TGS-2021005538'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021005539-20260522-041554.png'
  FROM catalog_product_entity WHERE sku='TGS-2021005539'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021005540-20260522-041550.png'
  FROM catalog_product_entity WHERE sku='TGS-2021005540'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021006714-20260522-041556.png'
  FROM catalog_product_entity WHERE sku='TGS-2021006714'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021006715-20260522-041557.png'
  FROM catalog_product_entity WHERE sku='TGS-2021006715'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021007827-20260522-041559.png'
  FROM catalog_product_entity WHERE sku='TGS-2021007827'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021008635-20260522-041558.png'
  FROM catalog_product_entity WHERE sku='TGS-2021008635'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021008700-20260522-041557.png'
  FROM catalog_product_entity WHERE sku='TGS-2021008700'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021009031-20260522-041610.png'
  FROM catalog_product_entity WHERE sku='TGS-2021009031'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021009334-20260522-041616.png'
  FROM catalog_product_entity WHERE sku='TGS-2021009334'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021009337-20260522-041614.png'
  FROM catalog_product_entity WHERE sku='TGS-2021009337'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021009338-20260522-041612.png'
  FROM catalog_product_entity WHERE sku='TGS-2021009338'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021010046-20260522-041620.png'
  FROM catalog_product_entity WHERE sku='TGS-2021010046'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021010185-20260522-041623.png'
  FROM catalog_product_entity WHERE sku='TGS-2021010185'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021010195-20260522-041623.png'
  FROM catalog_product_entity WHERE sku='TGS-2021010195'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021010365-20260522-041618.png'
  FROM catalog_product_entity WHERE sku='TGS-2021010365'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021010366-20260522-041621.png'
  FROM catalog_product_entity WHERE sku='TGS-2021010366'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2021010367-20260522-041621.png'
  FROM catalog_product_entity WHERE sku='TGS-2021010367'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022014976-20260522-041624.png'
  FROM catalog_product_entity WHERE sku='TGS-2022014976'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022014977-20260522-041622.png'
  FROM catalog_product_entity WHERE sku='TGS-2022014977'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022014978-20260522-041426.png'
  FROM catalog_product_entity WHERE sku='TGS-2022014978'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022014979-20260522-041629.png'
  FROM catalog_product_entity WHERE sku='TGS-2022014979'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022014980-20260522-041627.png'
  FROM catalog_product_entity WHERE sku='TGS-2022014980'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022014981-20260522-041628.png'
  FROM catalog_product_entity WHERE sku='TGS-2022014981'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022014982-20260522-041613.png'
  FROM catalog_product_entity WHERE sku='TGS-2022014982'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022015227-20260522-041624.png'
  FROM catalog_product_entity WHERE sku='TGS-2022015227'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022015365-20260522-041625.png'
  FROM catalog_product_entity WHERE sku='TGS-2022015365'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022015367-20260522-041626.png'
  FROM catalog_product_entity WHERE sku='TGS-2022015367'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022015368-20260522-041626.png'
  FROM catalog_product_entity WHERE sku='TGS-2022015368'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022015370-20260522-041437.png'
  FROM catalog_product_entity WHERE sku='TGS-2022015370'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022015374-20260522-041634.png'
  FROM catalog_product_entity WHERE sku='TGS-2022015374'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022015539-20260522-041430.png'
  FROM catalog_product_entity WHERE sku='TGS-2022015539'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022017519-20260522-041413.png'
  FROM catalog_product_entity WHERE sku='TGS-2022017519'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022017520-20260522-041512.png'
  FROM catalog_product_entity WHERE sku='TGS-2022017520'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022017524-20260522-041347.png'
  FROM catalog_product_entity WHERE sku='TGS-2022017524'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022017589-20260522-041414.png'
  FROM catalog_product_entity WHERE sku='TGS-2022017589'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022017591-20260522-041328.png'
  FROM catalog_product_entity WHERE sku='TGS-2022017591'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022017597-20260522-041345.png'
  FROM catalog_product_entity WHERE sku='TGS-2022017597'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022601648-20260522-041431.png'
  FROM catalog_product_entity WHERE sku='TGS-2022601648'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022601875-20260522-041617.png'
  FROM catalog_product_entity WHERE sku='TGS-2022601875'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022602057-20260522-041632.png'
  FROM catalog_product_entity WHERE sku='TGS-2022602057'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022602569-20260522-041415.png'
  FROM catalog_product_entity WHERE sku='TGS-2022602569'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023017892-20260522-041515.png'
  FROM catalog_product_entity WHERE sku='TGS-2023017892'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023018262-20260522-041513.png'
  FROM catalog_product_entity WHERE sku='TGS-2023018262'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023018659-20260522-041411.png'
  FROM catalog_product_entity WHERE sku='TGS-2023018659'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023018794-20260522-041334.png'
  FROM catalog_product_entity WHERE sku='TGS-2023018794'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023018967-20260522-041642.png'
  FROM catalog_product_entity WHERE sku='TGS-2023018967'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023018987-20260522-041639.png'
  FROM catalog_product_entity WHERE sku='TGS-2023018987'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023018988-20260522-041417.png'
  FROM catalog_product_entity WHERE sku='TGS-2023018988'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023018989-20260522-041640.png'
  FROM catalog_product_entity WHERE sku='TGS-2023018989'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023018990-20260522-041643.png'
  FROM catalog_product_entity WHERE sku='TGS-2023018990'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023020425-20260522-041640.png'
  FROM catalog_product_entity WHERE sku='TGS-2023020425'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023020563-20260522-041647.png'
  FROM catalog_product_entity WHERE sku='TGS-2023020563'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023020565-20260522-041647.png'
  FROM catalog_product_entity WHERE sku='TGS-2023020565'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023020567-20260522-041649.png'
  FROM catalog_product_entity WHERE sku='TGS-2023020567'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023021099-20260522-041644.png'
  FROM catalog_product_entity WHERE sku='TGS-2023021099'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023021100-20260522-041648.png'
  FROM catalog_product_entity WHERE sku='TGS-2023021100'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023021102-20260522-041650.png'
  FROM catalog_product_entity WHERE sku='TGS-2023021102'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023021752-20260522-041326.png'
  FROM catalog_product_entity WHERE sku='TGS-2023021752'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023035977-20260522-041432.png'
  FROM catalog_product_entity WHERE sku='TGS-2023035977'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036004-20260522-041700.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036004'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036088-20260522-041659.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036088'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036153-20260522-041656.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036153'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036449-20260522-041651.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036449'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036640-20260522-041701.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036640'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036641-20260522-041343.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036641'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036642-20260522-041701.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036642'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036644-20260522-041704.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036644'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036646-20260522-041703.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036646'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036648-20260522-041704.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036648'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036651-20260522-041702.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036651'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036653-20260522-041641.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036653'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036656-20260522-041652.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036656'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036657-20260522-041650.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036657'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036661-20260522-041659.png'
  FROM catalog_product_entity WHERE sku='TGS-2023036661'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037466-20260522-041657.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037466'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037467-20260522-041655.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037467'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037468-20260522-041655.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037468'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037469-20260522-041653.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037469'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037472-20260522-041657.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037472'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037544-20260522-041708.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037544'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037545-20260522-041535.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037545'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037587-20260522-041658.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037587'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037589-20260522-041656.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037589'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037592-20260522-041503.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037592'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037829-20260522-041616.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037829'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037830-20260522-041706.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037830'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037843-20260522-041705.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037843'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023037854-20260522-041707.png'
  FROM catalog_product_entity WHERE sku='TGS-2023037854'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023038152-20260522-041427.png'
  FROM catalog_product_entity WHERE sku='TGS-2023038152'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039177-20260522-041357.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039177'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039178-20260522-041600.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039178'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039179-20260522-041404.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039179'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039180-20260522-041706.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039180'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039181-20260522-041709.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039181'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039182-20260522-041709.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039182'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039183-20260522-041357.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039183'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039340-20260522-041710.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039340'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039341-20260522-041711.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039341'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039342-20260522-041711.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039342'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039343-20260522-041715.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039343'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039344-20260522-041710.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039344'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039835-20260522-041702.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039835'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039923-20260522-041632.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039923'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039924-20260522-041631.png'
  FROM catalog_product_entity WHERE sku='TGS-2023039924'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023040472-20260522-041603.png'
  FROM catalog_product_entity WHERE sku='TGS-2023040472'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023040473-20260522-041715.png'
  FROM catalog_product_entity WHERE sku='TGS-2023040473'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023040474-20260522-041630.png'
  FROM catalog_product_entity WHERE sku='TGS-2023040474'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023040476-20260522-041551.png'
  FROM catalog_product_entity WHERE sku='TGS-2023040476'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023040477-20260522-041712.png'
  FROM catalog_product_entity WHERE sku='TGS-2023040477'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023040479-20260522-041714.png'
  FROM catalog_product_entity WHERE sku='TGS-2023040479'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023040481-20260522-041713.png'
  FROM catalog_product_entity WHERE sku='TGS-2023040481'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023041022-20260522-041629.png'
  FROM catalog_product_entity WHERE sku='TGS-2023041022'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023041024-20260522-041405.png'
  FROM catalog_product_entity WHERE sku='TGS-2023041024'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023041080-20260522-041630.png'
  FROM catalog_product_entity WHERE sku='TGS-2023041080'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023041081-20260522-041353.png'
  FROM catalog_product_entity WHERE sku='TGS-2023041081'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042306-20260522-041428.png'
  FROM catalog_product_entity WHERE sku='TGS-2024042306'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042307-20260522-041356.png'
  FROM catalog_product_entity WHERE sku='TGS-2024042307'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042308-20260522-041450.png'
  FROM catalog_product_entity WHERE sku='TGS-2024042308'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042309-20260522-041653.png'
  FROM catalog_product_entity WHERE sku='TGS-2024042309'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042310-20260522-041654.png'
  FROM catalog_product_entity WHERE sku='TGS-2024042310'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042369-20260522-041429.png'
  FROM catalog_product_entity WHERE sku='TGS-2024042369'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042588-20260522-041716.png'
  FROM catalog_product_entity WHERE sku='TGS-2024042588'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042602-20260522-041358.png'
  FROM catalog_product_entity WHERE sku='TGS-2024042602'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042603-20260522-041332.png'
  FROM catalog_product_entity WHERE sku='TGS-2024042603'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042604-20260522-041328.png'
  FROM catalog_product_entity WHERE sku='TGS-2024042604'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042605-20260522-041400.png'
  FROM catalog_product_entity WHERE sku='TGS-2024042605'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042961-20260522-041545.png'
  FROM catalog_product_entity WHERE sku='TGS-2024042961'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024043392-20260522-041417.png'
  FROM catalog_product_entity WHERE sku='TGS-2024043392'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024043419-20260522-041634.png'
  FROM catalog_product_entity WHERE sku='TGS-2024043419'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024043420-20260522-041431.png'
  FROM catalog_product_entity WHERE sku='TGS-2024043420'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024043854-20260522-041627.png'
  FROM catalog_product_entity WHERE sku='TGS-2024043854'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024043855--20260522-041546.png'
  FROM catalog_product_entity WHERE sku='TGS-2024043855	'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024043856-20260522-041638.png'
  FROM catalog_product_entity WHERE sku='TGS-2024043856'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024044051-20260522-041639.png'
  FROM catalog_product_entity WHERE sku='TGS-2024044051'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024044052-20260522-041717.png'
  FROM catalog_product_entity WHERE sku='TGS-2024044052'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024044563-20260522-041536.png'
  FROM catalog_product_entity WHERE sku='TGS-2024044563'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045220-20260522-041537.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045220'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045221-20260522-041538.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045221'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045222-20260522-041544.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045222'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045795-20260522-041402.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045795'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045797-20260522-041549.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045797'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045798-20260522-041501.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045798'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045799-20260522-041549.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045799'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045800-20260522-041355.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045800'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045801-20260522-041330.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045801'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045802-20260522-041402.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045802'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045803-20260522-041717.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045803'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045805-20260522-041351.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045805'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045806-20260522-041350.png'
  FROM catalog_product_entity WHERE sku='TGS-2024045806'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024046112-20260522-041505.png'
  FROM catalog_product_entity WHERE sku='TGS-2024046112'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024047021-20260522-041718.png'
  FROM catalog_product_entity WHERE sku='TGS-2024047021'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024048310-20260522-041356.png'
  FROM catalog_product_entity WHERE sku='TGS-2024048310'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024048311-20260522-041440.png'
  FROM catalog_product_entity WHERE sku='TGS-2024048311'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024048312-20260522-041340.png'
  FROM catalog_product_entity WHERE sku='TGS-2024048312'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024048313-20260522-041401.png'
  FROM catalog_product_entity WHERE sku='TGS-2024048313'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024048314-20260522-041401.png'
  FROM catalog_product_entity WHERE sku='TGS-2024048314'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024048315-20260522-041339.png'
  FROM catalog_product_entity WHERE sku='TGS-2024048315'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024048316-20260522-041345.png'
  FROM catalog_product_entity WHERE sku='TGS-2024048316'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024048317-20260522-041344.png'
  FROM catalog_product_entity WHERE sku='TGS-2024048317'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024048318-20260522-041327.png'
  FROM catalog_product_entity WHERE sku='TGS-2024048318'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024048319-20260522-041719.png'
  FROM catalog_product_entity WHERE sku='TGS-2024048319'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049182-20260522-041416.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049182'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049183-20260522-041330.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049183'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049184-20260522-041458.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049184'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049211-20260522-041430.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049211'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049212-20260522-041420.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049212'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049213-20260522-041635.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049213'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049214-20260522-041329.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049214'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049215-20260522-041720.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049215'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049338-20260522-041351.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049338'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049339-20260522-041637.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049339'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049340-20260522-041636.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049340'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049350-20260522-041553.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049350'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049780-20260522-041341.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049780'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024049781-20260522-041342.png'
  FROM catalog_product_entity WHERE sku='TGS-2024049781'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024051248-20260522-041646.png'
  FROM catalog_product_entity WHERE sku='TGS-2024051248'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024051249-20260522-041403.png'
  FROM catalog_product_entity WHERE sku='TGS-2024051249'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024051250-20260522-041645.png'
  FROM catalog_product_entity WHERE sku='TGS-2024051250'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024051412-20260522-041500.png'
  FROM catalog_product_entity WHERE sku='TGS-2024051412'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024051413-20260522-041359.png'
  FROM catalog_product_entity WHERE sku='TGS-2024051413'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024051414-20260522-041412.png'
  FROM catalog_product_entity WHERE sku='TGS-2024051414'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024051421-20260522-041359.png'
  FROM catalog_product_entity WHERE sku='TGS-2024051421'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024051519-20260522-041403.png'
  FROM catalog_product_entity WHERE sku='TGS-2024051519'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024051900-20260522-041720.png'
  FROM catalog_product_entity WHERE sku='TGS-2024051900'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024052076-20260522-041346.png'
  FROM catalog_product_entity WHERE sku='TGS-2024052076'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024052081-20260522-041540.png'
  FROM catalog_product_entity WHERE sku='TGS-2024052081'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024052084-20260522-041541.png'
  FROM catalog_product_entity WHERE sku='TGS-2024052084'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025052277-20260522-041331.png'
  FROM catalog_product_entity WHERE sku='TGS-2025052277'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025052341-20260522-041354.png'
  FROM catalog_product_entity WHERE sku='TGS-2025052341'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025052342-20260522-041407.png'
  FROM catalog_product_entity WHERE sku='TGS-2025052342'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025052343-20260522-041337.png'
  FROM catalog_product_entity WHERE sku='TGS-2025052343'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025052344-20260522-041354.png'
  FROM catalog_product_entity WHERE sku='TGS-2025052344'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025052468-20260522-041526.png'
  FROM catalog_product_entity WHERE sku='TGS-2025052468'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025052659-20260522-041338.png'
  FROM catalog_product_entity WHERE sku='TGS-2025052659'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025052674-20260522-041406.png'
  FROM catalog_product_entity WHERE sku='TGS-2025052674'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025052675-20260522-041633.png'
  FROM catalog_product_entity WHERE sku='TGS-2025052675'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053174-20260522-041411.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053174'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053175-20260522-041348.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053175'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053206-20260522-041353.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053206'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053207-20260522-041641.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053207'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053209-20260522-041335.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053209'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053210-20260522-041333.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053210'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053212-20260522-041335.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053212'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053228-20260522-041340.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053228'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053916-20260522-041456.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053916'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053922-20260522-041439.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053922'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053923-20260522-041552.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053923'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053924-20260522-041423.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053924'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053926-20260522-041352.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053926'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053927-20260522-041442.png'
  FROM catalog_product_entity WHERE sku='TGS-2025053927'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025054471-20260522-041438.png'
  FROM catalog_product_entity WHERE sku='TGS-2025054471'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025054472-20260522-041336.png'
  FROM catalog_product_entity WHERE sku='TGS-2025054472'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025054479-20260522-041349.png'
  FROM catalog_product_entity WHERE sku='TGS-2025054479'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025054484-20260522-041332.png'
  FROM catalog_product_entity WHERE sku='TGS-2025054484'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025054485-20260522-041635.png'
  FROM catalog_product_entity WHERE sku='TGS-2025054485'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025054612-20260522-041722.png'
  FROM catalog_product_entity WHERE sku='TGS-2025054612'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025054613-20260522-041721.png'
  FROM catalog_product_entity WHERE sku='TGS-2025054613'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025054815-20260522-041722.png'
  FROM catalog_product_entity WHERE sku='TGS-2025054815'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025055502-20260522-041723.png'
  FROM catalog_product_entity WHERE sku='TGS-2025055502'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025055523-20260522-041338.png'
  FROM catalog_product_entity WHERE sku='TGS-2025055523'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025055775-20260522-041559.png'
  FROM catalog_product_entity WHERE sku='TGS-2025055775'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025056191-20260522-041644.png'
  FROM catalog_product_entity WHERE sku='TGS-2025056191'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025056357-20260522-041342.png'
  FROM catalog_product_entity WHERE sku='TGS-2025056357'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025056362-20260522-041724.png'
  FROM catalog_product_entity WHERE sku='TGS-2025056362'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025056983-20260522-041727.png'
  FROM catalog_product_entity WHERE sku='TGS-2025056983'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025056988-20260522-041727.png'
  FROM catalog_product_entity WHERE sku='TGS-2025056988'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025059025-20260522-041724.png'
  FROM catalog_product_entity WHERE sku='TGS-2025059025'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025059028-20260522-041728.png'
  FROM catalog_product_entity WHERE sku='TGS-2025059028'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025060471-20260522-041730.png'
  FROM catalog_product_entity WHERE sku='TGS-2025060471'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025060472-20260522-041731.png'
  FROM catalog_product_entity WHERE sku='TGS-2025060472'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025060473-20260522-041737.png'
  FROM catalog_product_entity WHERE sku='TGS-2025060473'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025060519-20260522-041451.png'
  FROM catalog_product_entity WHERE sku='TGS-2025060519'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025060552-20260522-041731.png'
  FROM catalog_product_entity WHERE sku='TGS-2025060552'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026061312-20260522-041732.png'
  FROM catalog_product_entity WHERE sku='TGS-2026061312'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026061321-20260522-041726.png'
  FROM catalog_product_entity WHERE sku='TGS-2026061321'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026061325-20260522-041734.png'
  FROM catalog_product_entity WHERE sku='TGS-2026061325'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026061328-20260522-041734.png'
  FROM catalog_product_entity WHERE sku='TGS-2026061328'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026061329-20260522-041735.png'
  FROM catalog_product_entity WHERE sku='TGS-2026061329'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026061330-20260522-041725.png'
  FROM catalog_product_entity WHERE sku='TGS-2026061330'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026061581-20260522-041733.png'
  FROM catalog_product_entity WHERE sku='TGS-2026061581'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026061582-20260522-041735.png'
  FROM catalog_product_entity WHERE sku='TGS-2026061582'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026061583-20260522-041736.png'
  FROM catalog_product_entity WHERE sku='TGS-2026061583'
ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026062147-20260522-041729.png'
  FROM catalog_product_entity WHERE sku='TGS-2026062147'
ON DUPLICATE KEY UPDATE value=VALUES(value);
