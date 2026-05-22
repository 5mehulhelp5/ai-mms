-- Defensive re-add of the admin_user profile columns.
--
-- Migration 008-add-admin-user-profile-fields.sql added tel / gender /
-- race / dob / nric_fin / linkedin_url / profile_image to admin_user.
-- On production the migration ledger was bootstrapped (apply.php
-- --bootstrap marked all pre-existing files as applied WITHOUT running
-- them), so 008 never actually executed there and those 7 columns are
-- missing. The /system_account/ save action does a raw
--   UPDATE admin_user SET tel=?, gender=?, race=?, dob=?, nric_fin=?,
--   linkedin_url=? ...
-- which throws "Unknown column" on prod -> "An error occurred while
-- saving account." It works locally because 008 ran here.
--
-- Each column is guarded by an information_schema existence check +
-- a prepared statement, so this migration is fully idempotent and
-- safe on both MySQL 5.7 (local) and 8.x (prod): it adds only the
-- columns that are actually missing and is a no-op for the rest.
-- apply.php splits on ";" at end-of-line and runs each statement on
-- the same PDO connection, so the session vars / prepared statement
-- persist across the split.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'admin_user' AND COLUMN_NAME = 'tel');
SET @s := IF(@c = 0, 'ALTER TABLE admin_user ADD COLUMN tel VARCHAR(20) DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'admin_user' AND COLUMN_NAME = 'gender');
SET @s := IF(@c = 0, 'ALTER TABLE admin_user ADD COLUMN gender VARCHAR(10) DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'admin_user' AND COLUMN_NAME = 'race');
SET @s := IF(@c = 0, 'ALTER TABLE admin_user ADD COLUMN race VARCHAR(50) DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'admin_user' AND COLUMN_NAME = 'dob');
SET @s := IF(@c = 0, 'ALTER TABLE admin_user ADD COLUMN dob DATE DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'admin_user' AND COLUMN_NAME = 'nric_fin');
SET @s := IF(@c = 0, 'ALTER TABLE admin_user ADD COLUMN nric_fin VARCHAR(20) DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'admin_user' AND COLUMN_NAME = 'linkedin_url');
SET @s := IF(@c = 0, 'ALTER TABLE admin_user ADD COLUMN linkedin_url VARCHAR(255) DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'admin_user' AND COLUMN_NAME = 'profile_image');
SET @s := IF(@c = 0, 'ALTER TABLE admin_user ADD COLUMN profile_image VARCHAR(255) DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;
