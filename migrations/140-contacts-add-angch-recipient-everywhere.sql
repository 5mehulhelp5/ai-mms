-- Append angch@tertiaryinfotech.com to every contacts/email/recipient_email
-- row so all stores' contact-form enquiries also reach that mailbox.
--
-- Per-store status before this migration:
--   default/0   = enquiry@tertiaryinfotech.com                       (no angch)
--   websites/1  = sales@tertiarycourses.com.sg,enquiry@,angch@       (already has it)
--   websites/2  = enquiry@tertiaryinfotech.com                       (no angch)
--   stores/2    = sales@my,saeid@my                                  (no angch)
--   websites/3  = siraj@tertiarycourses.com.gh                       (no angch)
--   websites/4  = info.tertiarycourses.ng@gmail.com                  (no angch)
--   websites/5  = programassistant@depel.bt                          (no angch)
--   websites/6  = info.wasa.educon@gmail.com                         (no angch)
--
-- The contact form handler (MMD_MagentoCaptcha IndexController) splits the
-- value on commas/semicolons and passes the resulting array as `To` to
-- sendTransactional(), so a comma-appended address is enough — no separate
-- BCC plumbing required.
--
-- Idempotent: the NOT LIKE guard prevents re-adding on replay.

UPDATE core_config_data
   SET value = CONCAT(value, ',angch@tertiaryinfotech.com')
 WHERE path  = 'contacts/email/recipient_email'
   AND value NOT LIKE '%angch@tertiaryinfotech.com%';
