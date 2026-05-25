-- Migration 153: tighten the vertical gap between the "AWS Skill Builder"
-- label and its body paragraph inside the per-course additional_note.
--
-- Migration 152 (and the AWS Skill Builder mover that preceded it) stored
-- the block as two <p> tags separated by a literal newline:
--   <p><strong>AWS Skill Builder</strong></p>\n<p>We are authorised…</p>
-- view.phtml renders additional_note through nl2br(), so the \n becomes
-- a <br> that stacks on top of the paragraph margins and visually doubles
-- the gap. Stripping the newline collapses the gap back to a single
-- paragraph margin, which matches the surrounding spacing.
--
-- Idempotent: REPLACE() no-ops on rows that don't contain the source string.

UPDATE catalog_product_entity_text
SET value = REPLACE(
        value,
        '<p><strong>AWS Skill Builder</strong></p>\n<p>We are authorised',
        '<p><strong>AWS Skill Builder</strong></p><p>We are authorised'
    )
WHERE attribute_id = 158;
