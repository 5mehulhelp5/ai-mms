-- Remove the "AWS Skill Builder" and "Certification Exam at Pearson Vue"
-- sections from the short_description of course TGS-2025052468
-- (entity_id 1118, "WSQ - Agentic AI Applications with Claude Code",
-- attribute_id 73 = short_description).
--
-- These two sections are AWS-cloud-certification boilerplate that does
-- not apply to this Claude Code course and were requested removed.
--
-- Surgical REPLACE() rather than a full-value overwrite: it only strips
-- the two exact HTML blocks and leaves the rest of the description
-- (Learning Outcomes, Skills Framework, Certification, WSQ Funding
-- tables, SFEC/SFC/UTAP/PSEA) untouched even if production's copy has
-- drifted from local. Applied to every store row (store_id 0/1/2) --
-- on rows that no longer contain the blocks it is a harmless no-op.
--
-- Idempotent: rerunning finds nothing to replace.

UPDATE catalog_product_entity_text
SET value = REPLACE(
  REPLACE(
    value,
    '<h2>AWS Skill Builder</h2>\r\n<p>We are authorised AWS reseller of AWS Skill Builder. If you would like to subscribe to AWS Skill Builder, please register you interest&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/aws-skill-builder-individual-yearly-subscription.html" title="AWS Skills Builder" target="_blank">here</a></span>.</p>\r\n',
    ''
  ),
  '<h2>Certification Exam at Pearson Vue</h2>\r\n<p>Once you are prepared for the exam, you can register for the <a href="https://aws.amazon.com/certification/certified-cloud-practitioner/" title="AWS Certified Cloud Practitioner" target="_blank"><span style="text-decoration: underline;">CLF-C02 AWS Certified Cloud Practitioner Exam here</span></a>. We are Authorised Pearson Vue Testing Center. You can take the certification exam at our test center.&nbsp;Note that the course fee does not include the certification exam fee.</p>\r\n<p>You can purchase the exam voucher (one of the lowest prices in Singapore) at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/aws-foundational-certification-exam-vouchers.html" title="AWS Foundational Certification Exam Voucher" target="_blank">AWS Foundational Certification Exam Voucher</a></span></p>\r\n',
  ''
)
WHERE entity_id = 1118
  AND attribute_id = 73;
