-- newsletters — Marketing-role newsletter drafts.
--
-- One row per newsletter the marketing admin builds. The workflow is:
--   1. Admin picks a template (course_promo / announcement / weekly_digest)
--      and a list of catalog course product_ids to feature.
--   2. They open a multi-turn chat with Claude to draft and revise the
--      copy. The full conversation is persisted in `chat_history` so the
--      iterate loop has memory across page reloads.
--   3. Admin clicks Push to MailerLite, which renders the template,
--      submits to MailerLite as a draft campaign, stores the returned
--      campaign id in `mailerlite_id` and flips status to 'pushed'.
--
-- Country-scoped via `country_code` so admin.<cc>@example.com only
-- ever sees their own market's drafts (mirrors the same pattern that
-- Assign Trainer / Learner / Enroll Learner already use).
--
-- Idempotent — safe to re-run.

CREATE TABLE IF NOT EXISTS `newsletters` (
    `newsletter_id`  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `country_code`   CHAR(2)      NOT NULL,
    `template_key`   VARCHAR(64)  NOT NULL,
    `title`          VARCHAR(255) NOT NULL,
    `subject`        VARCHAR(255) NOT NULL,
    `preview_text`   VARCHAR(255) NULL,
    `course_pids`    VARCHAR(255) NULL,
    `body_html`      MEDIUMTEXT   NULL,
    `body_blocks`    MEDIUMTEXT   NULL,
    `chat_history`   MEDIUMTEXT   NULL,
    `ai_prompt`      TEXT         NULL,
    `mailerlite_id`  VARCHAR(64)  NULL,
    `status`         ENUM('draft','pushed','sent') NOT NULL DEFAULT 'draft',
    `created_by`     INT UNSIGNED NULL,
    `created_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`newsletter_id`),
    KEY `idx_country` (`country_code`),
    KEY `idx_status`  (`status`),
    KEY `idx_country_status` (`country_code`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
