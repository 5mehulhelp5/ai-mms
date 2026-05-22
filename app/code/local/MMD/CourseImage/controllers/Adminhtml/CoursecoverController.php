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
            $allowedBadges = Mage::helper('mmd_courseimage')->getAllBadges();
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

    /**
     * Bulk regenerate landing page. Renders a form with store selector +
     * badge checkboxes + product picker. Does NOT trigger any rendering on
     * its own — every cover is generated only when the admin explicitly
     * clicks "Run on selected" and the frontend posts product_ids to
     * bulkRunAction one at a time.
     */
    public function bulkAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('dashboard');
        $this->_title('Bulk AI Covers');

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('mmd/coursecover/bulk.phtml');
        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    /**
     * Returns a JSON list of products matching the requested store + filter.
     * Used by the bulk page to populate the candidate list before any cover
     * is rendered. Read-only; never mutates a product.
     */
    public function bulkListAction()
    {
        try {
            $storeId  = (int) $this->getRequest()->getParam('store_id', 0);
            $wsqOnly  = (int) $this->getRequest()->getParam('wsq_only', 1) === 1;
            $missingOnly = (int) $this->getRequest()->getParam('missing_only', 0) === 1;
            $skuPrefix = trim((string) $this->getRequest()->getParam('sku_prefix', ''));
            $keyword   = trim((string) $this->getRequest()->getParam('keyword', ''));

            if ($storeId <= 0) {
                throw new Exception('Missing store_id');
            }
            $store    = Mage::app()->getStore($storeId);
            $websiteId = (int) $store->getWebsiteId();

            $collection = Mage::getResourceModel('catalog/product_collection')
                ->addAttributeToSelect(['sku', 'name', 'course_image_url', 'image'])
                ->setStore($store)
                ->addWebsiteFilter($websiteId)
                ->addFieldToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED);

            // SKU prefix takes precedence over the WSQ-only shortcut so the
            // admin can target other code patterns (e.g. "C-" for non-WSQ
            // catalog SKUs) without untangling the WSQ filter first.
            if ($skuPrefix !== '') {
                $safe = str_replace(['%', '_'], ['\\%', '\\_'], $skuPrefix);
                $collection->addFieldToFilter('sku', ['like' => $safe . '%']);
            } elseif ($wsqOnly) {
                $collection->addFieldToFilter('sku', ['like' => 'TGS-%']);
            }

            // Keyword matches against either SKU or product name so the admin
            // can grep by topic ("python", "agentic") or partial SKU at once.
            if ($keyword !== '') {
                $safe = str_replace(['%', '_'], ['\\%', '\\_'], $keyword);
                $collection->addFieldToFilter([
                    ['attribute' => 'sku',  'like' => '%' . $safe . '%'],
                    ['attribute' => 'name', 'like' => '%' . $safe . '%'],
                ]);
            }

            $items = [];
            foreach ($collection as $p) {
                $img = (string) $p->getCourseImageUrl();
                if ($missingOnly && $img !== '') {
                    continue;
                }
                $items[] = [
                    'id'    => (int) $p->getId(),
                    'sku'   => (string) $p->getSku(),
                    'name'  => (string) $p->getName(),
                    'image' => $img,
                ];
            }

            $this->getResponse()
                ->setHeader('Content-Type', 'application/json', true)
                ->setBody(json_encode(['ok' => true, 'count' => count($items), 'items' => $items]));
        } catch (Throwable $e) {
            Mage::logException($e);
            $this->getResponse()
                ->setHttpResponseCode(500)
                ->setHeader('Content-Type', 'application/json', true)
                ->setBody(json_encode(['ok' => false, 'error' => $e->getMessage()]));
        }
    }

    /**
     * Process ONE product: render cover, upload to R2, write the URL into
     * course_image_url, and return JSON. The bulk UI loops this endpoint
     * sequentially so each call stays short and the user gets per-row
     * progress. Throwing on one product never blocks the rest because the
     * frontend treats each call independently.
     */
    public function bulkRunAction()
    {
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $productId = (int) $this->getRequest()->getParam('product_id');
            if ($productId <= 0) {
                throw new Exception('Missing product_id');
            }

            $allowedBadges = Mage::helper('mmd_courseimage')->getAllBadges();
            $rawBadges = (array) $this->getRequest()->getParam('badges', []);
            $badges = [];
            foreach ($rawBadges as $b) {
                $b = is_string($b) ? trim($b) : '';
                if ($b !== '' && in_array($b, $allowedBadges, true) && !in_array($b, $badges, true)) {
                    $badges[] = $b;
                }
            }

            /** @var Mage_Catalog_Model_Product $product */
            $product = Mage::getModel('catalog/product')->load($productId);
            if (!$product->getId()) {
                throw new Exception("Product {$productId} not found");
            }

            $title = (string) $product->getName();
            $sku   = (string) $product->getSku();

            /** @var MMD_CourseImage_Model_Cover $renderer */
            $renderer = Mage::getModel('mmd_courseimage/cover');
            $png = $renderer->render($title, $sku, $badges);

            $safeSku = preg_replace('/[^a-z0-9\-]+/i', '-', $sku) ?: ('product-' . $productId);
            $stamp   = gmdate('Ymd-His');
            $key     = "course-covers/{$safeSku}-{$stamp}.png";

            /** @var MMD_CourseImage_Helper_R2 $r2 */
            $r2 = Mage::helper('mmd_courseimage/r2');
            $upload = $r2->putObject($key, $png, 'image/png');

            // Persist the URL onto course_image_url at the global (admin)
            // scope so every store view reads it. saveAttribute is a single
            // attribute write — far lighter than a full product save and
            // skips re-indexing the rest of the product.
            $product->setStoreId(0);
            $product->setData('course_image_url', $upload['url']);
            $product->getResource()->saveAttribute($product, 'course_image_url');

            $this->getResponse()
                ->setHeader('Content-Type', 'application/json', true)
                ->setBody(json_encode([
                    'ok'    => true,
                    'id'    => $productId,
                    'sku'   => $sku,
                    'url'   => $upload['url'],
                    'bytes' => $upload['bytes'],
                ]));
        } catch (Throwable $e) {
            Mage::logException($e);
            $this->getResponse()
                ->setHttpResponseCode(500)
                ->setHeader('Content-Type', 'application/json', true)
                ->setBody(json_encode([
                    'ok'    => false,
                    'id'    => (int) $this->getRequest()->getParam('product_id'),
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
