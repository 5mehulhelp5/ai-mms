-- Add a `trainer_description` TEXT column on admin_user so trainer-role
-- admins can save a free-form bio that surfaces on their My Profile page
-- (system_account/edit). Visible read-only on the profile between the
-- Bio Data and Login Details cards; editable via a <textarea> in the
-- Edit Profile form. Saved directly by MMD_Adminhtml_System_AccountController
-- whitelist (the core admin_user model only persists Magento's own fields).
--
-- Idempotent: only adds the column when it isn't already present.

SET @col_exists := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'admin_user'
      AND COLUMN_NAME  = 'trainer_description'
);
SET @ddl := IF(@col_exists = 0,
    'ALTER TABLE admin_user ADD COLUMN trainer_description TEXT NULL AFTER linkedin_url',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
