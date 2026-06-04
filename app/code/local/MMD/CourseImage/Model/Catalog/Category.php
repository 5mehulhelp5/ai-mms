<?php

/**
 * Category model rewrite — serve banner images directly from Cloudflare R2.
 *
 * Stock Mage_Catalog_Model_Category::getImageUrl() returns
 *   <media base>/catalog/category/<image>
 * but media/catalog/category/ is excluded from the Docker image
 * (.dockerignore), so on prod that path is absent and only resolves via the
 * media/.htaccess 302 fallback to R2. Pointing getImageUrl() straight at the
 * R2 public URL removes the redirect hop and makes the storefront src visibly
 * R2-hosted. The banners are uploaded by
 * scripts/maintenance/upload-category-images-to-r2.php under the key
 * "catalog/category/<image>".
 *
 * Falls back to the stock behaviour when R2_PUBLIC_URL is not configured, so
 * the .htaccess redirect still covers any environment without the env var.
 */
class MMD_CourseImage_Model_Catalog_Category extends Mage_Catalog_Model_Category
{
    public function getImageUrl()
    {
        $image = $this->getImage();
        if (!$image) {
            return false;
        }

        $publicUrl = rtrim((string) Mage::helper('mmd_courseimage')->env('R2_PUBLIC_URL', ''), '/');
        if ($publicUrl !== '') {
            return $publicUrl . '/catalog/category/' . ltrim((string) $image, '/');
        }

        return parent::getImageUrl();
    }
}
