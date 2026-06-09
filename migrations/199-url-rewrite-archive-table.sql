-- =============================================================
-- 199-url-rewrite-archive-table.sql
-- =============================================================
-- Cold-storage table for manual core_url_rewrite rows that the
-- prune-bad-url-redirects.php maintenance script removes.
--
-- Why a separate archive table (vs. a flag column on the live
-- table): the live table is in the hot path of every storefront
-- page load — Magento joins it on every request. Keeping deleted
-- rows around with a "soft-delete" flag bloats those joins and
-- the (request_path, store_id) unique index. An archive table
-- lets us cheaply restore any row by INSERT-from-archive while
-- keeping the live table lean.
--
-- The actual archive + delete happens in
-- scripts/maintenance/prune-bad-url-redirects.php — NOT here.
-- apply.php just creates the schema; the operator runs the
-- script manually on prod with --dry-run then --confirm.
--
-- Idempotent: re-running this migration is a no-op (IF NOT EXISTS).
-- =============================================================

CREATE TABLE IF NOT EXISTS `core_url_rewrite_archive_2026_06` (
  `url_rewrite_id`     int(10) unsigned NOT NULL COMMENT 'Original Rewrite Id (from core_url_rewrite)',
  `store_id`           smallint(5) unsigned NOT NULL DEFAULT '0',
  `id_path`            varchar(255) DEFAULT NULL,
  `request_path`       varchar(255) DEFAULT NULL,
  `target_path`        varchar(255) DEFAULT NULL,
  `is_system`          smallint(5) unsigned DEFAULT '1',
  `options`            varchar(255) DEFAULT NULL,
  `description`        varchar(255) DEFAULT NULL,
  `category_id`        int(10) unsigned DEFAULT NULL,
  `product_id`         int(10) unsigned DEFAULT NULL,
  `archived_at`        timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the row was pruned',
  `archived_score`     decimal(4,3) DEFAULT NULL COMMENT 'Jaccard score at prune time (NULL = unscored / forced)',
  `archived_reason`    varchar(64)  DEFAULT NULL COMMENT 'e.g. "orphan-jaccard-lt-0.5"',
  PRIMARY KEY (`url_rewrite_id`),
  KEY `idx_arch_store_request` (`store_id`, `request_path`),
  KEY `idx_arch_reason`        (`archived_reason`),
  KEY `idx_arch_at`            (`archived_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
  COMMENT='Pruned manual redirects from core_url_rewrite (see scripts/maintenance/prune-bad-url-redirects.php)';
