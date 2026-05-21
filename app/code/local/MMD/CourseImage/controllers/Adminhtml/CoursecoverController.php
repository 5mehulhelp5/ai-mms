<?php

/**
 * Generate a branded course-cover image and upload it to Cloudflare R2.
 *
 * Endpoints (admin-only):
 *
 *   GET  tigerdragon/coursecover/preview?title=...&sku=...
 *     Renders a PNG inline with no upload. Useful for tuning the layout.
 *
 *   POST tigerdragon/coursecover/generate  course_id=<int>
 *     Renders the cover for the given product, uploads it to R2, and
 *     returns JSON { ok, url, bytes }. Does NOT mutate the product —
 *     the caller drops the returned URL into the "Image URL Link" field
 *     and persists via the existing CoursesaveController save flow,
 *     which maps that field to the `course_image_url` attribute.
 *
 *   URL slug chosen as `coursecover` (not `courseimage`) to avoid the
 *   collision with the existing MMD_RoleManager CourseimageController
 *   that already owns /tigerdragon/courseimage/upload.
 */
class MMD_CourseImage_Adminhtml_CoursecoverController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isLoggedIn();
    }

    public function generateAction()
    {
        try {
            $productId = (int) ($this->getRequest()->getParam('course_id')
                ?: $this->getRequest()->getParam('product_id'));
            if ($productId <= 0) {
                throw new Exception('Missing course_id');
            }

            /** @var Mage_Catalog_Model_Product $product */
            $product = Mage::getModel('catalog/product')->load($productId);
            if (!$product->getId()) {
                throw new Exception("Product {$productId} not found");
            }

            $title = (string) $product->getName();
            $sku   = (string) $product->getSku();

            // Whitelist badge names so a malicious POST can't inject arbitrary
            // text into the rendered PNG. Order from the request is preserved
            // so the admin can control left-to-right placement by tick order.
            $allowedBadges = ['WSQ', 'SkillsFuture Credit', 'PSEA', 'UTAP', 'IBF', 'HRDF'];
            $rawBadges = (array) $this->getRequest()->getParam('badges', []);
            $badges = [];
            foreach ($rawBadges as $b) {
                $b = is_string($b) ? trim($b) : '';
                if ($b !== '' && in_array($b, $allowedBadges, true) && !in_array($b, $badges, true)) {
                    $badges[] = $b;
                }
            }

            /** @var MMD_CourseImage_Model_Cover $renderer */
            $renderer = Mage::getModel('mmd_courseimage/cover');
            $png = $renderer->render($title, $sku, $badges);

            $safeSku = preg_replace('/[^a-z0-9\-]+/i', '-', $sku) ?: ('product-' . $productId);
            $stamp   = gmdate('Ymd-His');
            $key     = "course-covers/{$safeSku}-{$stamp}.png";

            /** @var MMD_CourseImage_Helper_R2 $r2 */
            $r2 = Mage::helper('mmd_courseimage/r2');
            $upload = $r2->putObject($key, $png, 'image/png');

            $this->getResponse()
                ->setHeader('Content-Type', 'application/json', true)
                ->setBody(json_encode([
                    'ok'    => true,
                    'url'   => $upload['url'],
                    'bytes' => $upload['bytes'],
                    'sku'   => $sku,
                    'wsq'   => Mage::helper('mmd_courseimage')->isWsqCourse($sku),
                ]));
        } catch (Throwable $e) {
            Mage::logException($e);
            $this->getResponse()
                ->setHttpResponseCode(500)
                ->setHeader('Content-Type', 'application/json', true)
                ->setBody(json_encode([
                    'ok'    => false,
                    'error' => $e->getMessage(),
                ]));
        }
    }

    public function previewAction()
    {
        try {
            $title = (string) $this->getRequest()->getParam('title', 'Sample Course Title');
            $sku   = (string) $this->getRequest()->getParam('sku', 'TGS-EXAMPLE-001');
            /** @var MMD_CourseImage_Model_Cover $renderer */
            $renderer = Mage::getModel('mmd_courseimage/cover');
            $png = $renderer->render($title, $sku);
            $this->getResponse()
                ->setHeader('Content-Type', 'image/png', true)
                ->setHeader('Cache-Control', 'no-store', true)
                ->setBody($png);
        } catch (Throwable $e) {
            Mage::logException($e);
            $this->getResponse()
                ->setHttpResponseCode(500)
                ->setBody('Render error: ' . $e->getMessage());
        }
    }
}
