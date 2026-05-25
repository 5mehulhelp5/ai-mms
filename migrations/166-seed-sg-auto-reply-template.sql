-- Seed a Singapore-specific lead auto-reply Transactional Email and point
-- the SG store at it. Two templates now exist:
--
--   * mmd_leads_auto_reply       — default for MY/GH/NG/BT/IN (existing)
--   * mmd_leads_auto_reply_sg    — Singapore-only, hardcodes "Tertiary
--                                  Courses Singapore" brand + the SG
--                                  hotline / WhatsApp + the "Hi," greeting
--                                  and the WSQ funding wording in the body.
--
-- MMD_Leads_Helper_Data::sendAutoReply reads
-- mmd_leads/auto_reply/email_template at the lead's store scope, so once
-- this migration writes the SG-scope override the SG template is selected
-- automatically — no code switch needed.
--
-- One physical SQL line for the long INSERT (apply.php splits on ';\s*$').
-- Idempotent: NOT EXISTS guard on the template row, ON DUPLICATE KEY UPDATE
-- on the config pointer.

INSERT INTO core_email_template (template_code, template_text, template_styles, template_type, template_subject, added_at, modified_at, orig_template_code, orig_template_variables) SELECT 'Lead Auto-Reply — Singapore (WSQ)', '<body style="margin:0; padding:0; font-family: Arial, sans-serif; color:#0f172a; background:#f8fafc;"><table cellspacing="0" cellpadding="0" border="0" width="100%" style="background:#f8fafc;">  <tr><td align="center" style="padding:24px 12px;">    <table cellspacing="0" cellpadding="0" border="0" width="600" style="max-width:600px; background:#ffffff; border-radius:10px; overflow:hidden; box-shadow:0 4px 14px rgba(15,23,42,.06);">      <tr><td style="padding:24px 28px 8px; background:linear-gradient(135deg,#1e3a8a 0%,#2563eb 100%); color:#fff;">        <div style="font-size:13px; letter-spacing:.3px; text-transform:uppercase; opacity:.85; margin-bottom:4px;">Tertiary Courses Singapore</div>        <div style="font-size:22px; font-weight:700;">Thank you for your enquiry</div>      </td></tr>      <tr><td style="padding:24px 28px; font-size:15px; line-height:1.55;">        <p style="margin:0 0 14px;">Hi,</p>        <p style="margin:0 0 14px;">Thank you for your interest in our course. I hope this message finds you well.</p>        {{var course_info_html}}        <p style="margin:0 0 14px;">If you have any questions or need assistance on course registration, please don''t hesitate to reach out to us at <a href="tel:+6561000613" style="color:#2563eb;">61000613</a> or whatsapp us at <a href="https://wa.me/6588666375" style="color:#2563eb;">https://wa.me/6588666375</a>.</p>        <p style="margin:18px 0 0;">Yours Sincerely,<br/>          <strong>Tertiary Courses Singapore</strong>        </p>      </td></tr>      <tr><td style="padding:14px 28px 22px; font-size:12px; color:#64748b; border-top:1px solid #e2e8f0;">        This is an automated acknowledgement of your contact-form enquiry on        <a href="{{store url=""}}" style="color:#2563eb; text-decoration:none;">{{store url=""}}</a>.      </td></tr>    </table>  </td></tr></table></body>', NULL, 2, 'Thank you for your enquiry — Tertiary Courses Singapore', NOW(), NOW(), 'mmd_leads_auto_reply_sg', '{"var course_info_html":"Course Recommendation HTML"}' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM core_email_template WHERE template_code = 'Lead Auto-Reply — Singapore (WSQ)');

SET @sg_tid := (SELECT template_id FROM core_email_template WHERE template_code = 'Lead Auto-Reply — Singapore (WSQ)' ORDER BY template_id DESC LIMIT 1);

SET @sg_store := (SELECT store_id FROM core_store WHERE code = 'singapore' LIMIT 1);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', @sg_store, 'mmd_leads/auto_reply/email_template', @sg_tid
WHERE @sg_store IS NOT NULL AND @sg_tid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
