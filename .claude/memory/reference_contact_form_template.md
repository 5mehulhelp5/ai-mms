---
name: reference_contact_form_template
description: The live storefront Contact Us form template is recaptcha/contacts/form.phtml — NOT the ultimo contacts/form.phtml
metadata: 
  node_type: memory
  type: reference
  originSessionId: 8a0f7db0-9547-4970-b49f-b601272a18a9
---

The live storefront **Contact Us form** renders from:
`app/design/frontend/ultimo/default/template/recaptcha/contacts/form.phtml`

**Traps when editing the "contact form":**
- `app/design/frontend/ultimo/default/template/contacts/form.phtml` is a **decoy** — its native form is commented out and it only shows a Google Forms iframe. It is NOT used.
- `app/design/frontend/ultimo/default/layout/contacts.xml` points `contactForm` at `contacts/form.phtml`, but `recaptcha.xml` re-points it to `recaptcha/contacts/form.phtml` — that override wins.
- `MMD_MagentoCaptcha`'s `magentocaptcha.xml` `<contacts_index_index>` block is also commented out.

The form posts to `/contacts/index/post/`, handled by `MMD_MagentoCaptcha_IndexController::postAction` (Cloudflare Turnstile verify → staff email → `mmd_lead` row → auto-reply via [[feedback_transactional_email_template_seeding]]). Field names: `name, email, company, telephone, courses, course_code, comment`. Keep those names — the "Tertiary Courses Contact Form" email template resolves `{{var data.*}}` off them.

To confirm which template is live: `curl /contacts/` and grep for a distinctive class (e.g. `tc-submit`).
