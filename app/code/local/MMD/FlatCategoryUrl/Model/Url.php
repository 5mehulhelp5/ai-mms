<?php
/**
 * Flat category URLs: every category resolves at /<url_key>.html, no parent
 * path. Overrides Mage_Catalog_Model_Url::getCategoryRequestPath() — the one
 * method that builds parent/child/grandchild paths during catalog_url reindex.
 *
 * Collision handling is delegated to the stock getUnusedPathByUrlKey(), so
 * sibling categories with the same url_key auto-append -1, -2, etc.
 *
 * HARD RULE — accessibility + no collision (do NOT regress):
 *   Every ACTIVE category MUST resolve at the clean `<url_key>.html` and
 *   return HTTP 200. A canonical request_path that carries a numeric suffix
 *   (`aws-practice-exams-33.html`) on a live category is a BUG: it means the
 *   clean base path is squatted by a STALE rewrite and repeated reindex/
 *   force-flatten runs kept bumping the suffix (-1 -> -2 -> ... -> -33).
 *
 *   The legitimate `-N` suffix case is ONLY two *live* sibling categories
 *   that genuinely share a url_key — fix that by renaming one url_key, not by
 *   shipping a suffixed canonical. Everything else is rewrite-table debt:
 *     - Orphan / former-url_key save-history 301s that squat a base path an
 *       active category needs MUST yield (delete or re-point the squatter) so
 *       the live category reclaims `<url_key>.html`. (This is the documented
 *       exception to the seo-audit "never delete redirects" rule — deep-path
 *       -> flat redirects are kept; base-key squatters of a live category are
 *       not.)
 *     - Temporary `XXXXXXXX_TIMESTAMP` id_path save-history rows accumulate in
 *       the thousands across reindexes and each one bumps the next canonical
 *       suffix. Purge the stale chain so the canonical falls back to the base.
 *   See [[feedback_flat_url_collision_suffix_explosion]] in memory and the
 *   seo-audit skill invariant #3 for the detection queries + remediation.
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
