<?php
/**
 * MMD_SingaporePrice_Block_Config
 *
 * Emits a single inline <script> that publishes the per-product
 * pricing config the storefront JS needs: catalog price, GST rate,
 * funding-discount map, and whether the SG behaviour is active. JSON
 * keeps the markup small and lets sg-pricing.js stay pure JS with no
 * template knowledge.
 */
class MMD_SingaporePrice_Block_Config extends Mage_Core_Block_Template
{
    public function getConfigJson()
    {
        /** @var MMD_SingaporePrice_Helper_Data $helper */
        $helper  = Mage::helper('mmd_singaporeprice');
        $product = Mage::registry('current_product');
        $price   = $product ? $helper->getCatalogPrice($product) : 0.0;

        return Mage::helper('core')->jsonEncode(array(
            'active'         => $helper->isActive(),
            'catalogPrice'   => $price,
            'gstRate'        => $helper->getGstRate(),
            'fundingMap'     => $helper->getFundingDiscountMap(),
            'currencySymbol' => Mage::app()->getLocale()
                ->currency(Mage::app()->getStore()->getCurrentCurrencyCode())
                ->getSymbol(),
        ));
    }
}
