---
name: Index Management + Cache Management row checkboxes are hidden
description: The mass-action workflow on those pages does not work — provide a dedicated controller action instead
type: feedback
originSessionId: 9e4e7fca-2797-44ac-9734-21a6583d1d94
---
The custom admin theme hides per-row checkboxes globally on `adminhtml/cache` and `adminhtml/process/list` (Index Management). Clicking the per-row "Reindex Data" link triggers Magento's mass-action validator which alerts "Please select items" because no checkbox can be ticked.

**Why:** Commit `6c437f504` ("Admin: hide checkbox columns on Cache + Index Management") deliberately removed those checkboxes to prevent accidental bulk-reindex/bulk-cache-flush. Confirmed by user 2026-05-22.

**How to apply:**
- Never instruct the user to "select all and reindex" on Index Management — it won't work.
- When a feature needs flat reindex / cache flush, wire a dedicated POST controller action that runs `Mage::getModel('index/process')->load(<code>, 'indexer_code')->reindexEverything()` + `Mage::app()->getCacheInstance()->cleanType(<type>)`. See `MMD_CourseImage_Adminhtml_CoursecoverController::refreshStorefrontAction` for a working pattern.
- Surface it as a button on whatever admin page the feature lives on — don't send the user to Index Management.
