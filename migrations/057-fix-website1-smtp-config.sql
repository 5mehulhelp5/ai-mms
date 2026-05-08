-- Order-confirmation emails were silently failing on the live site.
-- Root cause: website 1 had core_config_data overrides forcing the SMTP
-- transport onto port 25 with no SSL and no auth — a config that only
-- works with a same-host SMTP relay. The Coolify-hosted environment
-- has no such relay, so SMTPPro's connect to mail.tertiarycourses.com.sg:25
-- failed every time. The default scope already had the correct settings
-- (587 / TLS / login) for the same host, so the cleanest fix is to
-- delete the website-1 overrides and let the connection inherit them.
--
-- Other websites (2 = MY, 3 = GH, 4 = NG, 5 = BT, 6 = IN) keep their
-- existing overrides — they each point at a different SMTP host and
-- may legitimately use port 25, so we don't touch them here.

DELETE FROM core_config_data
WHERE scope = 'websites'
  AND scope_id = 1
  AND path IN (
      'smtppro/general/smtp_port',
      'smtppro/general/smtp_ssl',
      'smtppro/general/smtp_authentication'
  );
