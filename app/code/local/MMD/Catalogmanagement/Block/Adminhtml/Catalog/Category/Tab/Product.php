<?php
/**
 * @author MMD Team
 * @copyright Copyright (c) 2012-2011 MMD (http://magemobiledesign.com)
 * @package MMD_Catalogmanagement
 */
class MMD_Catalogmanagement_Block_Adminhtml_Catalog_Category_Tab_Product extends Mage_Adminhtml_Block_Catalog_Category_Tab_Product
{
    protected function _getStore()
    {
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        return Mage::app()->getStore($storeId);
    }

    protected function _prepareCollection()
    {
        parent::_prepareCollection();

        if (Mage::getStoreConfig('catalogmanagement/category/thumb'))
        {
            $this->getCollection()->joinAttribute('thumbnail', 'catalog_product/thumbnail', 'entity_id', null, 'left', $this->_getStore()->getId());
        }

        // Country pill filter: when the active branch is a specific store
        // (?store=N, N>0), restrict the grid to products that belong to
        // that store's website. Without this the shared course catalog
        // leaks Malaysia (M-prefix) / Ghana / Nigeria etc courses into the
        // Singapore view. store=0 ("All") falls through with no filter.
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        if ($storeId > 0) {
            try {
                $websiteId = (int) Mage::app()->getStore($storeId)->getWebsiteId();
                if ($websiteId > 0) {
                    $this->getCollection()->joinField(
                        '_branch_website_id',
                        'catalog/product_website',
                        'website_id',
                        'product_id=entity_id',
                        array('website_id' => $websiteId),
                        'inner'
                    );
                }
            } catch (Exception $e) {
                Mage::logException($e);
            }
        }

        return Mage_Adminhtml_Block_Widget_Grid::_prepareCollection();
    }

    protected function _prepareColumns()
    {
        if (Mage::getStoreConfig('catalogmanagement/additional/thumb'))
        {
            if (method_exists($this, "addColumnAfter"))
            {
                $this->addColumnAfter('thumb',
                    array(
                        'header'    => Mage::helper('catalog')->__('Thumbnail'),
                        'renderer'  => 'catalogmanagement/adminhtml_catalog_product_grid_renderer_thumb',
                        'index'		=> 'thumbnail',
                        'sortable'  => true,
                        'filter'    => false,
                        'width'     => 90,
                    ), 'entity_id');
            } else
            {
                // will add thumbnail column to be the first one
                $this->addColumn('thumb',
                    array(
                        'header'    => Mage::helper('catalog')->__('Thumbnail'),
                        'renderer'  => 'catalogmanagement/adminhtml_catalog_product_grid_renderer_thumb',
                        'index'		=> 'thumbnail',
                        'sortable'  => true,
                        'filter'    => false,
                        'width'     => 90,
                    ));
            }
        }

        parent::_prepareColumns();
        return Mage_Adminhtml_Block_Widget_Grid::_prepareColumns();
    }
}