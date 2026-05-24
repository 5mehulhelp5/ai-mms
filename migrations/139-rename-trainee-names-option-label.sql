-- Rename the custom-option title shown on WSQ courses:
--   "Add your company trainee names or additional message below"
--   →
--   "Add your company trainee names (Optional)"
-- Covers both the clean variant and the corrupted-NBSP variant
-- ("message<U+00A0>below") seen on ~half of the 304 affected rows.
-- Idempotent: re-running matches nothing once normalized.

UPDATE catalog_product_option_title SET title = 'Add your company trainee names (Optional)' WHERE title LIKE 'Add your company trainee names%' AND title <> 'Add your company trainee names (Optional)';
