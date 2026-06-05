-- Phase 2: account-based trainer assignment (alongside legacy EAV).
--
-- Going forward, the per-course approved trainer list and run assignments use
-- real operator accounts (admin_user with the 'trainer' role) instead of EAV
-- options. Legacy columns/data are left intact as a fallback so previously
-- assigned trainers are never touched.
--
--   course_runs.trainer_user_id                 — account-based run assignment
--   course_run_trainer_invitations.trainer_user_id — account the invite is for
--   mmd_product_trainer                         — per-course approved accounts

ALTER TABLE `course_runs`
    ADD COLUMN `trainer_user_id` INT UNSIGNED NULL AFTER `trainer_option_id`;

ALTER TABLE `course_run_trainer_invitations`
    ADD COLUMN `trainer_user_id` INT UNSIGNED NULL AFTER `trainer_option_id`;

CREATE TABLE IF NOT EXISTS `mmd_product_trainer` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` INT UNSIGNED NOT NULL,
    `user_id`    INT UNSIGNED NOT NULL  COMMENT 'admin_user.user_id (trainer role)',
    `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_product_user` (`product_id`, `user_id`),
    KEY `idx_product` (`product_id`),
    KEY `idx_user`    (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
