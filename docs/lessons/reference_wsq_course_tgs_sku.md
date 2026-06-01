---
name: reference_wsq_course_tgs_sku
description: "WSQ / SkillsFuture-funded courses are identified by a TGS- SKU prefix, and the SKU IS the SkillsFuture course reference"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 8a0f7db0-9547-4970-b49f-b601272a18a9
---

In this catalog, a **WSQ / SkillsFuture-funded course** is identified purely by its **SKU prefix `TGS-`** (e.g. `TGS-2024045801`). There is no `wsq` / `tgs` product attribute — only `enable_sg_funding` (int flag) exists.

Key facts:
- The product **SKU of a WSQ course IS its SkillsFuture (SSG) course reference** — the same `TGS-...` code used on the MySkillsFuture portal.
- MySkillsFuture course-detail URL: `https://www.myskillsfuture.gov.sg/content/portal/en/training-exchange/course-directory/course-detail.html?courseReference=<SKU>`
- Non-WSQ courses use other SKU schemes — `C###` (Singapore/classroom), `M###` (Malaysia variant).
- ~299 `TGS-` courses exist. WSQ recommendations are **Singapore-only** (other countries have no SkillsFuture scheme).

Used by `MMD_Leads_Helper_Data::recommendCourse()` — the contact-form auto-reply recommends the best-matching `TGS-` course via keyword/synonym scoring (`_synonymMap()`), restricted to `sku LIKE 'TGS-%'`, enabled + visible, store = singapore.
