-- Replace hardcoded year in design/footer/copyright with the {{year}} token.
-- The Ultimo footer template substitutes {{year}} with the current year at
-- render time, so the copyright stays correct without a manual DB edit every
-- January. MySQL 5.7 has no REGEXP_REPLACE; spell each year out, scoped to
-- the "Copyright (c) YYYY." prefix so unrelated occurrences of the year
-- elsewhere in the value are left alone.
UPDATE core_config_data SET value = REPLACE(value, '© 2023.', '© {{year}}.') WHERE path = 'design/footer/copyright';
UPDATE core_config_data SET value = REPLACE(value, '© 2024.', '© {{year}}.') WHERE path = 'design/footer/copyright';
UPDATE core_config_data SET value = REPLACE(value, '© 2025.', '© {{year}}.') WHERE path = 'design/footer/copyright';
UPDATE core_config_data SET value = REPLACE(value, '© 2026.', '© {{year}}.') WHERE path = 'design/footer/copyright';
