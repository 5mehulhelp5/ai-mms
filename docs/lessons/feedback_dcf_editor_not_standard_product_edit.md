---
name: dcf-editor-not-standard-product-edit
description: "The \"Edit Course\" admin page is a custom dcf editor, NOT Mage_Adminhtml_Block_Catalog_Product_Edit_Tabs — EAV attributes do not auto-surface here"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b4ea1c17-6ff3-43d1-95f7-d3be98effa1f
---

The admin "Edit Course" page (with the "Course Information" sidebar showing
General / Course Details / Course Schedule / Lesson Details / Trainer Details
/ …) is NOT Magento's stock `catalog_product/edit`. It is a custom
hand-rendered form ("dcf editor") served by the **dashboard controller**:

- Template: `app/design/adminhtml/default/default/template/dashboard/index.phtml` (~13k lines)
- Save handler: `app/code/local/MMD/RoleManager/controllers/Adminhtml/CoursesaveController.php`
- CSS classes: `dcf-tab-panel`, `dcf-row`, `dcf-section-title`, `dcf-edit-sidebar`
- JS host: `skin/adminhtml/default/default/js/product-edit-tools.js`
- Body class: `adminhtml-dashboard-index` (NOT `adminhtml-catalog-product-edit`)

The sidebar tabs are hand-coded `<div class="dcf-tab-panel">` sections, not
Magento attribute-group tabs.

**Why:** When asked to add the `assessment_duration` attribute, I created an
EAV select via migration 159, attached it to the Course Details group, and
moved its sort_order to render right after `duration`. The standard
`catalog_product/edit` page rendered it correctly — but the user kept saying
"I can't see it on the General tab in Edit Course". Multiple rounds of
"scroll further" / "check the right tab" failed because the user wasn't on
the stock product-edit page at all. The clue was a comment in
`product-edit-tools.js` line 10-13: *"the earlier version targeted
catalog_product/edit (.side-col / body.adminhtml-catalog-product-edit) —
that is NOT the page developers use; the 'Edit Course' flow is this dcf
editor on the dashboard controller."* I had spent ~6 rounds debugging an
EAV attribute that was rendering correctly on a page nobody uses.

**How to apply:** When asked to add/remove/modify any field that admins see
on the "Edit Course" page:

1. The EAV migration is necessary but NOT sufficient.
2. Add a `<div class="dcf-row">…</div>` to the appropriate `dcf-tab-panel`
   in `dashboard/index.phtml` (search for nearby fields like
   `name="training_hours"` or `name="course_type_select"` to find the right
   tab).
3. Add a corresponding `if (($v = $req->getParam('<field>')) !== null)
   $product->setData('<field>', …)` line in `CoursesaveController.php`
   `saveAction()`.
4. Worked example committed at:
   - `app/design/adminhtml/default/default/template/dashboard/index.phtml`
     lines ~2645-2671 (assessment_duration select)
   - `app/code/local/MMD/RoleManager/controllers/Adminhtml/CoursesaveController.php`
     line ~122 (assessment_duration save)

**Quick check:** If the user's screenshot has the "Course Information" header
in the sidebar and CSS classes prefixed with `dcf-`, you're on the dcf
editor. If the URL is `/catalog_product/edit/id/<n>/`, you're on stock
product-edit. The two pages render completely different forms from the same
underlying product data.
