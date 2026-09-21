-- C1426 (AZ-900 Azure Fundamentals Training) — point the Funding block directly at
-- its WSQ twin TGS-2023036449, flattening the 301 chain.
--
-- The block previously linked to /wsq-azure-cloud-fundamentals.html, which 301s to
-- /wsq-microsoft-azure-fundamentals-az-900.html. Link to the live slug directly.
--
-- Content-only UPDATE: never ->save() a cms/block model (it wipes cms_block_store).
-- Idempotent: guarded on the stale slug, so a re-run is a no-op.

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-microsoft-azure-fundamentals-az-900.html" title="WSQ - Microsoft Azure Fundamentals (AZ-900)">WSQ - Microsoft Azure Fundamentals (AZ-900)</a></span></p>'
 WHERE identifier = 'course_C1426_funding_and_grant'
   AND content LIKE '%wsq-azure-cloud-fundamentals.html%';
