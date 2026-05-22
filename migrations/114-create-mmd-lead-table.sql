-- MMD_Leads: persistent storage for storefront contact-form submissions.
--
-- One row per /contacts/index/post that passes Turnstile + field validation.
-- The admin grid (Tertiary → Leads) lists these and lets operators send a
-- prefilled course-info reply via the existing Gmail OAuth transport.
--
-- Indexed on status + created_at so the "new leads today" view is cheap,
-- and on store_id for per-country filtering.
--
-- Idempotent: IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS `mmd_lead` (
    `lead_id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `store_id`            SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `store_code`          VARCHAR(32)  NOT NULL DEFAULT '',
    `name`                VARCHAR(255) NOT NULL DEFAULT '',
    `email`               VARCHAR(255) NOT NULL DEFAULT '',
    `telephone`           VARCHAR(64)  NOT NULL DEFAULT '',
    `company`             VARCHAR(255) NOT NULL DEFAULT '',
    `courses_interested`  VARCHAR(512) NOT NULL DEFAULT '',
    `comment`             TEXT         NOT NULL,
    `ip`                  VARCHAR(64)  NOT NULL DEFAULT '',
    `user_agent`          VARCHAR(255) NOT NULL DEFAULT '',
    `status`              VARCHAR(16)  NOT NULL DEFAULT 'new',
    `replied_at`          DATETIME     NULL DEFAULT NULL,
    `replied_by`          INT UNSIGNED NULL DEFAULT NULL,
    `replied_message`     TEXT         NULL,
    `created_at`          DATETIME     NOT NULL,
    `updated_at`          DATETIME     NOT NULL,
    PRIMARY KEY (`lead_id`),
    KEY `IDX_MMD_LEAD_STATUS_CREATED` (`status`, `created_at`),
    KEY `IDX_MMD_LEAD_STORE`          (`store_id`),
    KEY `IDX_MMD_LEAD_EMAIL`          (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Storefront contact-form leads';
