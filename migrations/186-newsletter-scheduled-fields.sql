-- 186-newsletter-scheduled-fields.sql
--
-- Extends the `newsletters` table with fields needed for the weekly
-- auto-fire scheduler + MailerLite campaign analytics caching.
--
-- New columns:
--   is_auto              — 1 when the cron created the row (vs human draft)
--   scheduled_send_at    — DATETIME MailerLite was told to send the campaign
--   analytics_*          — cached open/click counts + rates from MailerLite
--                          (avoids hitting MailerLite on every dashboard render)
--
-- Plus a small set of `core_config_data` rows seeding the schedule:
--   mmd_marketing/auto_newsletter/enabled         = 0 (kill-switch, off by default)
--   mmd_marketing/auto_newsletter/day_of_week     = 1 (Monday, ISO 1-7)
--   mmd_marketing/auto_newsletter/hour            = 9 (server-local hour)
--   mmd_marketing/auto_newsletter/send_delay_hours = 4
--   mmd_marketing/auto_newsletter/country_code    = SG
--
-- Idempotent on re-run: each ALTER probes information_schema first so the
-- migration is safe to re-apply on a partially-migrated DB. MySQL 5.7
-- doesn't support `ADD COLUMN IF NOT EXISTS` and apply.php runs through
-- PDO (no DELIMITER support, no stored procs) — so each column gets its
-- own SET / IF / PREPARE / EXECUTE triple.

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='newsletters' AND column_name='is_auto');
SET @s := IF(@c=0, 'ALTER TABLE `newsletters` ADD COLUMN `is_auto` TINYINT(1) NOT NULL DEFAULT 0', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='newsletters' AND column_name='scheduled_send_at');
SET @s := IF(@c=0, 'ALTER TABLE `newsletters` ADD COLUMN `scheduled_send_at` DATETIME NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='newsletters' AND column_name='analytics_opens');
SET @s := IF(@c=0, 'ALTER TABLE `newsletters` ADD COLUMN `analytics_opens` INT UNSIGNED NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='newsletters' AND column_name='analytics_clicks');
SET @s := IF(@c=0, 'ALTER TABLE `newsletters` ADD COLUMN `analytics_clicks` INT UNSIGNED NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='newsletters' AND column_name='analytics_open_rate');
SET @s := IF(@c=0, 'ALTER TABLE `newsletters` ADD COLUMN `analytics_open_rate` VARCHAR(16) NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='newsletters' AND column_name='analytics_click_rate');
SET @s := IF(@c=0, 'ALTER TABLE `newsletters` ADD COLUMN `analytics_click_rate` VARCHAR(16) NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='newsletters' AND column_name='analytics_synced_at');
SET @s := IF(@c=0, 'ALTER TABLE `newsletters` ADD COLUMN `analytics_synced_at` DATETIME NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='newsletters' AND index_name='idx_is_auto');
SET @s := IF(@c=0, 'ALTER TABLE `newsletters` ADD INDEX `idx_is_auto` (`is_auto`)', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

INSERT IGNORE INTO `core_config_data` (`scope`, `scope_id`, `path`, `value`) VALUES
    ('default', 0, 'mmd_marketing/auto_newsletter/enabled',          '0'),
    ('default', 0, 'mmd_marketing/auto_newsletter/day_of_week',      '1'),
    ('default', 0, 'mmd_marketing/auto_newsletter/hour',             '9'),
    ('default', 0, 'mmd_marketing/auto_newsletter/send_delay_hours', '4'),
    ('default', 0, 'mmd_marketing/auto_newsletter/country_code',     'SG');
