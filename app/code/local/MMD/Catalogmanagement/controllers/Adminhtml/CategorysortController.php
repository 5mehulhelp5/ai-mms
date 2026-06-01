<?php
/**
 * Sort Courses for a category — recomputes catalog_category_product.position
 * in steps of 10 using the project's ranking rules:
 *
 *   Rule 1: SG store — WSQ courses first (SKU prefix "TGS-"), then non-WSQ.
 *   Rule 2: Within each group, highest product views first, then shortest
 *           duration (hours, ascending), then product name (A→Z) as a stable
 *           tiebreaker.
 *   Rule 3: Other stores — same Rule-2 sort applied to all courses (those
 *           catalogues have no TGS- prefix so Rule 1 is a no-op).
 *
 * Returns JSON: { product_id: new_position, ... } so the front-end can patch
 * the position inputs in the category-products grid and let the user click
 * "Save Category" to persist.
 */
class MMD_Catalogmanagement_Adminhtml_CategorysortController extends Mage_Adminhtml_Controller_Action
{
    public function indexAction()
    {
        try {
            $categoryId = (int) $this->getRequest()->getParam('category_id');
            if ($categoryId <= 0) {
                throw new Exception('category_id is required');
            }
            $storeId = (int) $this->getRequest()->getParam('store', 0);

            $res   = Mage::getSingleton('core/resource');
            $read  = $res->getConnection('core_read');
            $tCcp  = $res->getTableName('catalog/category_product');
            $tEvt  = $res->getTableName('reports/event');
            $tProd = $res->getTableName('catalog/product');
            $tCpw  = $res->getTableName('catalog/product_website');

            $select = $read->select()
                ->from(array('ccp' => $tCcp), array('product_id'))
                ->where('ccp.category_id = ?', $categoryId);

            // Scope to the active branch's website so M-prefix courses
            // never leak into a Singapore sort (and vice versa). store=0
            // ("All") skips this filter and sorts across the whole catalog.
            if ($storeId > 0) {
                $websiteId = (int) Mage::app()->getStore($storeId)->getWebsiteId();
                if ($websiteId > 0) {
                    $select->join(
                        array('cpw' => $tCpw),
                        'cpw.product_id = ccp.product_id AND cpw.website_id = ' . (int) $websiteId,
                        array()
                    );
                }
            }
            $productIds = $read->fetchCol($select);

            if (!$productIds) {
                $this->getResponse()
                    ->setHeader('Content-Type', 'application/json')
                    ->setBody(Zend_Json::encode(array('positions' => new stdClass(), 'count' => 0)));
                return;
            }

            $skuByPid = $read->fetchPairs(
                $read->select()->from($tProd, array('entity_id', 'sku'))->where('entity_id IN (?)', $productIds)
            );

            $nameAttr     = Mage::getSingleton('eav/config')->getAttribute('catalog_product', 'name');
            $durationAttr = Mage::getSingleton('eav/config')->getAttribute('catalog_product', 'duration');

            $namesByPid = array();
            if ($nameAttr && $nameAttr->getId()) {
                $namesByPid = $read->fetchPairs(
                    $read->select()
                        ->from($nameAttr->getBackendTable(), array('entity_id', 'value'))
                        ->where('attribute_id = ?', $nameAttr->getId())
                        ->where('store_id = 0')
                        ->where('entity_id IN (?)', $productIds)
                );
            }

            $durationByPid = array();
            if ($durationAttr && $durationAttr->getId()) {
                $durationByPid = $read->fetchPairs(
                    $read->select()
                        ->from($durationAttr->getBackendTable(), array('entity_id', 'value'))
                        ->where('attribute_id = ?', $durationAttr->getId())
                        ->where('store_id = 0')
                        ->where('entity_id IN (?)', $productIds)
                );
            }

            $viewEventTypeId = (int) $read->fetchOne(
                $read->select()
                    ->from($res->getTableName('reports/event_type'), 'event_type_id')
                    ->where('event_name = ?', 'catalog_product_view')
            );
            $viewsByPid = array();
            if ($viewEventTypeId > 0) {
                $vSelect = $read->select()
                    ->from($tEvt, array('object_id', new Zend_Db_Expr('COUNT(*)')))
                    ->where('event_type_id = ?', $viewEventTypeId)
                    ->where('object_id IN (?)', $productIds)
                    ->group('object_id');
                // Scope views to the active store so country-specific
                // traffic actually drives the ranking (SG views shouldn't
                // boost a MY course or vice versa).
                if ($storeId > 0) {
                    $vSelect->where('store_id = ?', $storeId);
                }
                $viewsByPid = $read->fetchPairs($vSelect);
            }

            $rows = array();
            foreach ($productIds as $pid) {
                $sku   = (string)(isset($skuByPid[$pid]) ? $skuByPid[$pid] : '');
                $isWsq = (stripos($sku, 'TGS-') === 0);
                $rows[] = array(
                    'pid'      => (int) $pid,
                    'is_wsq'   => $isWsq ? 1 : 0,
                    'views'    => (int)(isset($viewsByPid[$pid]) ? $viewsByPid[$pid] : 0),
                    'duration' => (float)(isset($durationByPid[$pid]) ? $durationByPid[$pid] : 0),
                    'name'     => (string)(isset($namesByPid[$pid]) ? $namesByPid[$pid] : ''),
                );
            }

            usort($rows, function ($a, $b) {
                // Rule 1: WSQ group first (1 before 0)
                if ($a['is_wsq'] !== $b['is_wsq']) {
                    return $b['is_wsq'] - $a['is_wsq'];
                }
                // Rule 2a: Views desc
                if ($a['views'] !== $b['views']) {
                    return $b['views'] - $a['views'];
                }
                // Rule 2b: Duration asc — courses with no duration sink to the bottom
                $da = $a['duration'] > 0 ? $a['duration'] : PHP_INT_MAX;
                $db = $b['duration'] > 0 ? $b['duration'] : PHP_INT_MAX;
                if ($da != $db) {
                    return ($da < $db) ? -1 : 1;
                }
                // Stable tiebreaker: name asc
                return strnatcasecmp($a['name'], $b['name']);
            });

            $positions = array();
            $step = 10;
            foreach ($rows as $i => $r) {
                $positions[(int)$r['pid']] = ($i + 1) * $step;
            }

            $this->getResponse()
                ->setHeader('Content-Type', 'application/json')
                ->setBody(Zend_Json::encode(array(
                    'positions' => $positions,
                    'count'     => count($positions),
                    'store_id'  => $storeId,
                )));
        } catch (Exception $e) {
            $this->getResponse()
                ->setHttpResponseCode(500)
                ->setHeader('Content-Type', 'application/json')
                ->setBody(Zend_Json::encode(array('error' => $e->getMessage())));
        }
    }

    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('catalog/categories');
    }
}
