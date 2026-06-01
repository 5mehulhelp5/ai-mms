---
name: admin-grid-store-filter-before-load
description: "Wiring ?store= filtering on admin grids — addStoreFilter must run in _beforeLoadCollection, not after parent::_prepareCollection"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f65ef2d9-8a7f-423c-8c09-4a66c0d88c96
---

When adding `?store=N` filtering to an admin grid that stock Magento
doesn't filter natively (Reviews, Search Terms, Tag, Newsletter Problem,
several reports), call `$collection->addStoreFilter($storeId)` from
`_beforeLoadCollection()` — NOT from `_prepareCollection()` after the
parent call.

**Why:** `Mage_Adminhtml_Block_Widget_Grid::_prepareCollection()` calls
`$collection->load()` itself. That triggers the collection's
`_beforeLoad` → `_applyStoresFilterToSelect()`, which bakes the SQL join
with `store.store_id = 0` because `_storesIds` is still empty. By the
time the override runs `addStoreFilter()` after `parent::_prepareCollection()`,
the SQL has already been built and the result rows are cached on the
collection. Zend_Db_Select also dedupes the `store` join alias, so a
second pass can't override the bad join. Verified in 2026-05 fix to
Reviews grid: log showed `_storesIds=[3]` but SQL still emitted
`store.store_id = 0` until the call was moved into
`_beforeLoadCollection`.

**How to apply:** in the MMD override for any review/search/tag/etc.
admin grid that's wired to the global Store View bar
([[backend-design]] Filtering contract):

```php
protected function _beforeLoadCollection()
{
    parent::_beforeLoadCollection();
    $storeId = (int) $this->getRequest()->getParam('store', 0);
    if ($storeId > 0 && $this->getCollection()) {
        $this->getCollection()->addStoreFilter($storeId);
    }
    return $this;
}
```

Reference fix: `app/code/local/MMD/Adminhtml/Block/Review/Grid.php`.
Skill rules: [[backend-design]] "Filtering contract (MANDATORY)" and
[[add-country-store]] "Admin Store View bar — must filter grid data".
