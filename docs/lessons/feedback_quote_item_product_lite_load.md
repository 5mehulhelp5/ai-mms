---
name: quote-item-product-lite-load
description: Quote/cart line-item product proxies omit custom EAV attributes; re-fetch via getAttributeRawValue
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a47fe3c5-7e9c-4451-a851-69e39d720c48
---

In cart/checkout templates, `$_item->getProduct()` (where `$_item` is a
`Mage_Sales_Model_Quote_Item`) returns a "lite" product object that only
exposes the columns the quote loads — name, sku, price, qty, options,
and the standard image attributes. Custom EAV attributes registered
outside the quote item's attribute list (e.g. `course_image_url` from
[[funding-badges-via-tags]]'s neighbour module CourseImage) come back as
NULL even when set in the database.

**Why:** Burned in the Course Booking Review (cart) page — the AI
course cover lives in `course_image_url`, but the cart line item kept
showing the legacy `thumbnail`. `getData('course_image_url')` on the
quote-item product returned `''`, while a fresh
`Mage::getModel('catalog/product')->loadByAttribute('sku', ...)` from
the CLI returned the correct R2 URL. The quote-item proxy is the bug,
not the data.

**How to apply:** When you need a custom product attribute in a cart /
quote / order context, never trust `$item->getProduct()->getData($attr)`
alone. Either:

1. `Mage::getResourceModel('catalog/product')->getAttributeRawValue($productId, $attrCode, Mage::app()->getStore())` — single-query, cheap, no full reload.
2. Or `Mage::getModel('catalog/product')->load($productId)` — heavy, only if you need multiple custom attrs.

Working pattern in
`app/design/frontend/ultimo/default/template/checkout/cart/item/default.phtml`
around the `<td>` that renders the cover image — `getData()` first,
fall back to `getAttributeRawValue` if empty.

Same trap applies to sales/order item products, wishlist item products,
and any other quote-driven proxy.
