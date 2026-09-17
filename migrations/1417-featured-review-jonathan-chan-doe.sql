-- 1417: Featured review — Jonathan Chan Kai Bin's LinkedIn recommendation for
-- Dr Alvin Ang's Practical Design of Experiment (DoE) class.
--
-- Seeds one LinkedIn recommendation (14 Sep 2026, "Jonathan was Dr. Alvin's
-- client") as an approved product review flagged `is_featured = 1` (same
-- pattern as 1324/1305/1303/1096), so it shows on the homepage "What our
-- learners say" strip, /testimonials, and the course's own review list.
--
--   * Jonathan Chan Kai Bin (5*, 2026-09-14) -> TGS-2024051249 "WSQ - Practical
--     Design of Experiment (DoE) for Engineers and Researchers". The
--     recommendation names the course title verbatim ("Practical Design of
--     Experiment (DoE) for Engineers and Researchers") and the trainer (Dr.
--     Alvin Ang) explicitly, so no inference is needed. The only other DoE
--     course, C950 "Design of Experiment (DOE) Masterclass", does not match
--     the quoted title.
--
-- Review text is the reviewer's own wording, with the closing summary line
-- ("Overall, Dr. Ang is a strong communicator...") kept and the paragraphs
-- joined into flowing sentences. ASCII-only throughout (apply.php connects
-- utf8, NOT utf8mb4 -- emoji/smart quotes would abort the whole chain and 502
-- the site).
--
-- Also rebuilds the course's `review_entity_summary` row from the live
-- review/vote data -- raw-SQL seeds bypass Magento's aggregate().
--
-- Partner safety: every statement is gated on @sg (store_id 1 = 'singapore'),
-- which is false on partner servers, so the whole file no-ops there. Tested
-- `> 0`. `@rid` is derived from ROW_COUNT() so a skipped seed can never attach
-- detail/votes to an unrelated review. The NOT EXISTS guard keys on
-- nickname + title (not nickname alone). Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- ═══ Review — Jonathan Chan Kai Bin (WSQ Practical DoE, 5*) ═════════════════
INSERT INTO review (created_at, entity_id, entity_pk_value, status_id, is_featured)
SELECT '2026-09-14 12:00:00',
       (SELECT entity_id FROM review_entity WHERE entity_code = 'product'),
       e.entity_id, 1, 1
FROM catalog_product_entity e
WHERE @sg > 0
  AND e.sku = 'TGS-2024051249'
  AND NOT EXISTS (
      SELECT 1 FROM review r
      JOIN review_detail d ON d.review_id = r.review_id
      WHERE d.nickname = 'Jonathan Chan Kai Bin'
        AND d.title = 'A resourceful trainer who makes DoE easy to understand'
        AND r.entity_pk_value = e.entity_id
  );
SET @rid1 := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), 0);
INSERT INTO review_detail (review_id, store_id, title, detail, nickname, customer_id)
SELECT @rid1, 1,
       'A resourceful trainer who makes DoE easy to understand',
       'I have attended the course "Practical Design of Experiment (DoE) for Engineers and Researchers" taught by Dr. Alvin Ang at the Tertiary Infotech Academy. Dr. Ang uses a wide variety of examples to illustrate Taguchi designs, mixture designs, full and fractional factorial designs, Plackett-Burman designs, Box-Behnken designs, Response Surface Methodology, and other experimental optimization techniques. He demonstrated how Minitab can be used to generate these experimental designs, analyze the data, and generate various plots to visualize the results. Dr. Ang is a very resourceful trainer and has included many personal experiences to make the course engaging. He explains all concepts clearly and in a manner that is easy to understand. He has also demonstrated how generative artificial intelligence tools can assist in DoE. Dr. Ang is very experienced in his field of work; he has worked on Procter and Gamble''s Supply Chain Redesign and has helped the Research Director of The Logistics Institute Asia Pacific to prepare a proposal for Singapore General Hospital''s home delivery of medication. Furthermore, Dr. Ang has five publications on the topic of Kanban Systems and Operations Research. Overall, Dr. Ang is a strong communicator and I enjoyed being taught by him.',
       'Jonathan Chan Kai Bin', NULL
FROM dual WHERE @rid1 > 0;
INSERT INTO review_store (review_id, store_id)
SELECT @rid1, s.store_id FROM core_store s
WHERE s.store_id IN (0, 1) AND @rid1 > 0
ON DUPLICATE KEY UPDATE review_store.store_id = review_store.store_id;

-- ═══ Star rating — 5 stars ══════════════════════════════════════════════
INSERT INTO rating_option_vote
    (option_id, remote_ip, remote_ip_long, customer_id, entity_pk_value, rating_id, review_id, percent, value)
SELECT ro.option_id, '', 0, NULL, r.entity_pk_value, ro.rating_id, r.review_id, 100, 5
FROM review r
JOIN review_detail d ON d.review_id = r.review_id
JOIN catalog_product_entity e ON e.entity_id = r.entity_pk_value
JOIN rating rt ON rt.entity_id = (SELECT entity_id FROM review_entity WHERE entity_code = 'product')
JOIN rating_option ro ON ro.rating_id = rt.rating_id AND ro.value = 5
WHERE @sg > 0
  AND r.is_featured = 1
  AND d.nickname = 'Jonathan Chan Kai Bin'
  AND d.title = 'A resourceful trainer who makes DoE easy to understand'
  AND e.sku = 'TGS-2024051249'
  AND NOT EXISTS (
      SELECT 1 FROM rating_option_vote v
      WHERE v.review_id = r.review_id AND v.rating_id = ro.rating_id
  );

-- ═══ Rebuild review_entity_summary for the affected course ══════════════
SET @p1 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024051249');
UPDATE review_entity_summary res
JOIN (
    SELECT COUNT(DISTINCT r.review_id) AS cnt, ROUND(AVG(v.percent)) AS avg_pct
    FROM review r
    LEFT JOIN rating_option_vote v ON v.review_id = r.review_id
    WHERE r.entity_pk_value = @p1 AND r.status_id = 1
) agg
SET res.reviews_count  = agg.cnt,
    res.rating_summary = COALESCE(agg.avg_pct, res.rating_summary)
WHERE @sg > 0
  AND res.entity_pk_value = @p1
  AND res.entity_type = (SELECT entity_id FROM review_entity WHERE entity_code = 'product');
