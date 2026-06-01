---
name: reference_contact_form_template
description: "The live storefront Contact Us form template is ultimo contacts/form.phtml (the former \"decoy\" — recaptcha override is gone)"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 4bf74962-44c2-49f1-a599-d41dd251badd
---

The live storefront **Contact Us form** renders from:
`app/design/frontend/ultimo/default/template/contacts/form.phtml`

**History trap:** an earlier memory claimed `recaptcha/contacts/form.phtml` was the live template and the ultimo one was a decoy. That is no longer true — `recaptcha/contacts/form.phtml` and the `recaptcha.xml` layout override have been removed. The ultimo `contacts/form.phtml` now contains the real, active form (look for `class="tc-submit"` / `id="tc-submit-btn"` to confirm).

**Still relevant:**
- `app/design/frontend/ultimo/default/layout/contacts.xml` points `contactForm` at `contacts/form.phtml` — and nothing overrides it anymore.
- `MMD_MagentoCaptcha`'s `magentocaptcha.xml` `<contacts_index_index>` block is still commented out.
- The form posts to `/contacts/index/post/`, handled by `MMD_MagentoCaptcha_IndexController::postAction` (Cloudflare Turnstile verify → staff email → `mmd_lead` row → auto-reply via [[feedback_transactional_email_template_seeding]]).
- Field names: `name, email, company, telephone, courses, course_code, comment`. Keep those names — the "Tertiary Courses Contact Form" email template resolves `{{var data.*}}` off them.

To confirm which template is live: `curl /contacts/` and grep for `tc-submit`.
