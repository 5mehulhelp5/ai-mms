-- Override mmd_leads/auto_reply/cc for the Malaysia website so MY leads
-- CC the MY mailbox instead of the SG default inherited from config.xml.
-- Website scope: malaysia website_id = 2.
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('websites', 2, 'mmd_leads/auto_reply/cc',
        'angch@tertiaryinfotech.com,sales@tertiarycourses.com.my,saeid@tertiarycourses.com.my')
ON DUPLICATE KEY UPDATE
    value = VALUES(value);
