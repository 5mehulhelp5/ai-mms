<?php
/**
 * Flat category URLs: every category resolves at /<url_key>.html, no parent
 * path. Overrides Mage_Catalog_Model_Url::getCategoryRequestPath() — the one
 * method that builds parent/child/grandchild paths during catalog_url reindex.
 *
 * Collision handling is delegated to the stock getUnusedPathByUrlKey(), so
 * sibling categories with the same url_key auto-append -1, -2, etc.
 */
class MMD_FlatCategoryUrl_Model_Url extends Mage_Catalog_Model_Url
{
    public function getCategoryRequestPath($category, $parentPath)
    {
        $storeId = $category->getStoreId();
        $idPath  = $this->generatePath('id', null, $category);

        $existingRequestPath = null;
        if (isset($this->_rewrites[$idPath])) {
            $this->_rewrite = $this->_rewrites[$idPath];
            $existingRequestPath = $this->_rewrites[$idPath]->getRequestPath();
        }

        $locale = Mage::getStoreConfig(Mage_Core_Model_Locale::XML_PATH_DEFAULT_LOCALE, $storeId);
        $urlKey = $category->getUrlKey() == '' ? $category->getName() : $category->getUrlKey();
        $urlKey = $this->getCategoryModel()->setLocale($locale)->formatUrlKey($urlKey);

        $suffix   = $this->getCategoryUrlSuffix($storeId);
        $fullPath = $urlKey . $suffix;

        $regexp = '/^' . preg_quote($urlKey, '/') . '(\-[0-9]+)?' . preg_quote($suffix, '/') . '$/i';
        if ($existingRequestPath !== null && preg_match($regexp, $existingRequestPath)) {
            return $existingRequestPath;
        }

        // Intentionally do NOT call _deleteOldTargetPath() here: in stock
        // Magento it strips the suffix and returns $requestPath unsuffixed,
        // which is masked by the per-category deep path. With flat URLs the
        // same branch corrupts rewrites by writing `wsq-foo` (no .html) on
        // re-indexes. getUnusedPathByUrlKey is idempotent for our id_path and
        // appends -1/-2 only on genuine sibling collisions.
        return $this->getUnusedPathByUrlKey($storeId, $fullPath, $idPath, $urlKey);
    }
}
