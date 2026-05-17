-- Ensure the same 7 admin users exist across environments.
-- Adds user_id=31 (Tan Yong Huat) if missing. INSERT IGNORE skips if present.
INSERT IGNORE INTO admin_user (user_id, firstname, lastname, username, email, password, created, is_active, extra, lognum, reload_acl_flag)
VALUES (
  31,
  'Tan',
  'Yong Huat',
  'yhtestmail25@gmail.com',
  'yhtestmail25@gmail.com',
  '94a779b552bc685d33eb1e9ad13788d453d7ed94d519064cb0e6c0b20a566117:NM9dbmJZ5cZIuwjGbobphm2n1XdqEZmE',
  NOW(),
  1,
  'N;',
  0,
  0
);

-- Align every admin's username with their email (since login uses email).
-- Username column is UNIQUE; email is also effectively unique, so no conflicts.
UPDATE admin_user SET username = email WHERE email IS NOT NULL AND email <> '' AND username <> email;
