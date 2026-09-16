-- 1413: rename the perk badge "Free AI Tools Subscription" -> "Free AI Subscription".
--
-- The tag NAME is the canonical key every consumer matches on by string:
-- the storefront pill, the perk card above WSQ Funding, the red cover chip
-- (MMD_CourseImage_Model_Cover::AI_TOOLS_BADGE) and the newsletter flyer
-- bonus band. Renaming the existing row keeps all tag_relation rows intact,
-- so every tagged course keeps its badge — no re-tagging required.
--
-- `tag` has no unique key on `name` (PK is tag_id only), so a straight UPDATE
-- cannot collide. Guarded anyway: if a row with the new name somehow already
-- exists, the UPDATE is skipped rather than creating a duplicate vocabulary
-- entry that would split the badge across two tag_ids.
--
-- Idempotent: re-running finds no old-named row and does nothing.
-- Partner-safe: MY/GH never had this badge, so @old is NULL => no-op.

SET @old := (SELECT tag_id FROM tag WHERE name = 'Free AI Tools Subscription' LIMIT 1);
SET @new := (SELECT tag_id FROM tag WHERE name = 'Free AI Subscription' LIMIT 1);

UPDATE tag
   SET name = 'Free AI Subscription'
 WHERE tag_id = @old
   AND @old IS NOT NULL
   AND @new IS NULL;

-- tag_summary is keyed on tag_id, not name, so the rename carries over with
-- no recompute needed. Left untouched deliberately.
