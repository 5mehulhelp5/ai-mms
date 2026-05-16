-- Update Malaysia store header welcome + logo alt text.
-- Old: "HRD Corp Approved Training Provider Malaysia - Industrial 4.0 Certification Training and Education"
-- New: "HRD Corp Approved Training Provider Malaysia - AI and Certification Trainings"
--
-- Lives at websites scope, scope_id=2 (Malaysia website), under design/header/{welcome,logo_alt}.
-- Mirrors migrations 060 (Nigeria welcome) and 063 (Ghana welcome).

UPDATE core_config_data
SET value = 'HRD Corp Approved Training Provider Malaysia - AI and Certification Trainings'
WHERE scope = 'websites'
  AND scope_id = 2
  AND path IN ('design/header/welcome', 'design/header/logo_alt');
