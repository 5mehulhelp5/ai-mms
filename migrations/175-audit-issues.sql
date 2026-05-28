-- 175-audit-issues.sql
-- Persistent log of audit findings (seo-auditor, auto-fixer, manual).
-- Drives the admin "Audit Issues" page and the global notification banner.

CREATE TABLE IF NOT EXISTS mmd_audit_issues (
  issue_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  source        VARCHAR(64)  NOT NULL DEFAULT 'manual',
  category      VARCHAR(64)  NOT NULL DEFAULT 'seo',
  severity      VARCHAR(16)  NOT NULL DEFAULT 'low',
  title         VARCHAR(255) NOT NULL,
  detail        TEXT NULL,
  entity_type   VARCHAR(64)  NULL,
  entity_id     INT UNSIGNED NULL,
  store_id      SMALLINT UNSIGNED NULL,
  status        VARCHAR(16)  NOT NULL DEFAULT 'open',
  fix_summary   VARCHAR(512) NULL,
  found_at      DATETIME     NOT NULL,
  fixed_at      DATETIME     NULL,
  PRIMARY KEY (issue_id),
  KEY idx_status   (status),
  KEY idx_severity (severity),
  KEY idx_category (category),
  KEY idx_entity   (entity_type, entity_id),
  KEY idx_found_at (found_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
