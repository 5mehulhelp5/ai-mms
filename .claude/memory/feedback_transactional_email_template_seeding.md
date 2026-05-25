---
name: feedback_transactional_email_template_seeding
description: A config.xml-registered file email template does NOT appear as a row in System → Transactional Emails — seed core_email_template to make it admin-manageable
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 8a0f7db0-9547-4970-b49f-b601272a18a9
---

To make a custom email template **manageable in the admin** (System → Transactional Emails grid), registering a `<global><template><email>` file template in config.xml is NOT enough.

**Why:** A config-registered file template only surfaces in the *"Add New Template" → Template* dropdown as a loadable default. It never appears as an editable row in the Transactional Emails grid — that grid lists only `core_email_template` DB rows. Users who ask for a template "in the Email template section" mean the grid.

**How to apply:** When a custom feature sends a transactional email the client must be able to edit:
1. Ship the file default: `app/locale/en_US/template/email/<module>/<name>.html` with `<!--@subject-->` / `<!--@vars-->` headers, registered in config.xml `<global><template><email>`.
2. Seed a `core_email_template` row in a migration — `template_text` = the file body with the `@subject`/`@vars` comment blocks **stripped** (Magento stores those in `template_subject` / `orig_template_variables`), `template_type` = 2 for HTML, `orig_template_code` = the registered file code.
3. Point a config path (e.g. `<module>/<feature>/email_template`) at the seeded row's `template_id` via `core_config_data` in the **same** migration (`SET @tid := (SELECT ... )` then INSERT). The sender reads that config path so edits to the DB row take effect.
4. `sendTransactional($templateId, ...)`: numeric id → loads the DB row; string code → loads the file default. Keep the string code as the `?:` fallback.

Working example: [[none]] — `migrations/119-seed-lead-auto-reply-email-template.sql` + `MMD_Leads/etc/config.xml` `<default><mmd_leads><auto_reply>` + `MMD_Leads_Helper_Data::sendAutoReply()`.

Gotcha: migration SQL with an inline HTML blob — the runner splits statements on `preg_split('/;\s*$/m')`, so ensure no HTML line ends with `;`. Escape single quotes as `''`. Related: [[feedback_db_sync_via_migration]].
