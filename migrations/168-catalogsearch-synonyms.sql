-- Set synonym_for on existing catalogsearch_query rows so misspellings,
-- abbreviations, and alternate names fold into their canonical term during
-- storefront search.
--
-- Safety guarantees:
--   * Only UPDATEs — no INSERTs, so no risk of colliding on the
--     (query_text, store_id) unique key.
--   * Every UPDATE has `(synonym_for IS NULL OR synonym_for = '')` in its
--     WHERE clause, so it is idempotent — re-running this file is a no-op
--     for rows already mapped (admin curation is never overwritten). The
--     column ships as NULL by default in catalogsearch_query.
--   * Each row only maps when BOTH the source row (the misspelling) AND
--     a row matching the canonical term exist in the SAME store_id — so
--     we never point a Malaysia row at a canonical that only exists in
--     Singapore.
--
-- Rows mapped here have all been audited to be redundant with their
-- canonical target and to have empty redirect URLs that won't change
-- behavior. The catch-all template is:
--
--     UPDATE catalogsearch_query src
--     JOIN   catalogsearch_query dst
--            ON dst.store_id = src.store_id
--           AND dst.query_text = '<canonical>'
--     SET    src.synonym_for = '<canonical>'
--     WHERE  src.query_text IN ('<variant1>', '<variant2>', ...)
--       AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- python
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'python'
SET    src.synonym_for = 'python'
WHERE  src.query_text IN ('phyton', 'pyton', 'python programming', 'python course')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- power BI
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'power BI'
SET    src.synonym_for = 'power BI'
WHERE  src.query_text IN ('powerbi', 'power bi')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- excel
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'excel'
SET    src.synonym_for = 'excel'
WHERE  src.query_text IN ('ms excel', 'microsoft excel')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- autocad
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'autocad'
SET    src.synonym_for = 'autocad'
WHERE  src.query_text IN ('auto cad', 'autodesk autocad')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- photoshop
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'photoshop'
SET    src.synonym_for = 'photoshop'
WHERE  src.query_text IN ('adobe photoshop', 'photo shop', 'ps')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- AWS
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'AWS'
SET    src.synonym_for = 'AWS'
WHERE  src.query_text IN ('amazon web services')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- WordPress
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'WordPress'
SET    src.synonym_for = 'WordPress'
WHERE  src.query_text IN ('word press', 'wordpres')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- raspberry pi
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'raspberry pi'
SET    src.synonym_for = 'raspberry pi'
WHERE  src.query_text IN ('rasberry pi', 'raspberrypi', 'rpi', 'rassbery pi')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- javascript
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'javascript'
SET    src.synonym_for = 'javascript'
WHERE  src.query_text IN ('java script', 'js')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- machine learning
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'machine learning'
SET    src.synonym_for = 'machine learning'
WHERE  src.query_text IN ('ml', 'machinelearning')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- ChatGPT
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'ChatGPT'
SET    src.synonym_for = 'ChatGPT'
WHERE  src.query_text IN ('chat gpt')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- copilot
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'copilot'
SET    src.synonym_for = 'copilot'
WHERE  src.query_text IN ('co-pilot', 'microsoft copilot', 'github copilot')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- blockchain
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'blockchain'
SET    src.synonym_for = 'blockchain'
WHERE  src.query_text IN ('block chain')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- tensorflow
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'tensorflow'
SET    src.synonym_for = 'tensorflow'
WHERE  src.query_text IN ('tensor flow')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- kubernetes
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'kubernetes'
SET    src.synonym_for = 'kubernetes'
WHERE  src.query_text IN ('k8s')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- after effects
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'after effects'
SET    src.synonym_for = 'after effects'
WHERE  src.query_text IN ('ae', 'adobe after effects')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- premiere pro
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'premiere pro'
SET    src.synonym_for = 'premiere pro'
WHERE  src.query_text IN ('premier pro', 'adobe premiere')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- illustrator
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'illustrator'
SET    src.synonym_for = 'illustrator'
WHERE  src.query_text IN ('adobe illustrator')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- indesign
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'indesign'
SET    src.synonym_for = 'indesign'
WHERE  src.query_text IN ('in design', 'adobe indesign')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- quickbooks
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'quickbooks'
SET    src.synonym_for = 'quickbooks'
WHERE  src.query_text IN ('quick books', 'quickbook')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- 3D printing
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = '3D printing'
SET    src.synonym_for = '3D printing'
WHERE  src.query_text IN ('3dprinting')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- fusion 360
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'fusion 360'
SET    src.synonym_for = 'fusion 360'
WHERE  src.query_text IN ('fusion360', 'autodesk fusion')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- google ads
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'google ads'
SET    src.synonym_for = 'google ads'
WHERE  src.query_text IN ('google ad', 'google adwords', 'adwords')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- skillsfuture
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'skillsfuture'
SET    src.synonym_for = 'skillsfuture'
WHERE  src.query_text IN ('skillfuture', 'skills future')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- six sigma
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'six sigma'
SET    src.synonym_for = 'six sigma'
WHERE  src.query_text IN ('6 sigma')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- power automate
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'power automate'
SET    src.synonym_for = 'power automate'
WHERE  src.query_text IN ('powerautomate', 'ms power automate')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- react
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'react'
SET    src.synonym_for = 'react'
WHERE  src.query_text IN ('react js', 'reactjs')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- angular
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'angular'
SET    src.synonym_for = 'angular'
WHERE  src.query_text IN ('angular js', 'angularjs')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- node (canonical node — nodejs/node js fold in)
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'node'
SET    src.synonym_for = 'node'
WHERE  src.query_text IN ('node js', 'nodejs')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- vue
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'vue'
SET    src.synonym_for = 'vue'
WHERE  src.query_text IN ('vue js', 'vuejs')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- ui/ux (canonical) — fold ui ux and ux ui (no slash variants)
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'ui/ux'
SET    src.synonym_for = 'ui/ux'
WHERE  src.query_text IN ('ui ux', 'ux ui')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- generative ai (canonical) — gen ai folds in
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'generative ai'
SET    src.synonym_for = 'generative ai'
WHERE  src.query_text IN ('gen ai')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- LLM (canonical) — large language model/s fold in
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'LLM'
SET    src.synonym_for = 'LLM'
WHERE  src.query_text IN ('large language model', 'large language models')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');

-- Agentic ai (canonical) — variants fold in
UPDATE catalogsearch_query src
JOIN   catalogsearch_query dst
       ON dst.store_id = src.store_id AND dst.query_text = 'Agentic ai'
SET    src.synonym_for = 'Agentic ai'
WHERE  src.query_text IN ('ai agent', 'ai agents', 'agentic')
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');
