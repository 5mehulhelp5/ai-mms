<?php
/**
 * MMD_SingaporePrice_Model_Observer
 *
 * On product save, if `enable_sg_funding` is set, makes sure the
 * standard Magento custom option "Funding Eligibility (Subject to
 * Verification)" exists on the product with the five canonical
 * radio values. The percentages themselves live in Company Settings
 * (mmd_company/sg_funding/*) and are read by the storefront JS and
 * the price model — so per-product editing is no longer needed and
 * the third-party "option templates" feature can be retired.
 *
 * Behaviour:
 *   - enable_sg_funding=1 + funding option missing → create it (5 values)
 *   - enable_sg_funding=1 + funding option present → no-op (idempotent)
 *   - enable_sg_funding=0 → no-op (does NOT delete; admin can prune)
 */
class MMD_SingaporePrice_Model_Observer
{
    /** Title of the canonical funding option created on products. */
    const OPTION_TITLE = 'Funding Eligibility (Subject to Verification)';

    /** Canonical value labels — match the keys in helper::getFundingDiscountMap(). */
    protected $_values = array(
        'Singaporean above 40 yrs old',
        'Singaporean below 40 yrs old',
        'Singapore PR',
        'non Singaporean',
        'SME (Singaporean/PR Direct Hire)',
    );

    /** catalog_product_save_after observer entry point. */
    public function onProductSaveAfter($observer)
    {
        try {
            /** @var Mage_Catalog_Model_Product $product */
            $product = $observer->getProduct();
            if (!$product || !$product->getId()) return;

            // Use the raw attribute value rather than getEnableSgFunding()
            // because not every load path hydrates EAV magic getters.
            $enabled = (int) $product->getData('enable_sg_funding');
            if ($enabled !== 1) return;

            if ($this->_hasFundingOption($product)) return;

            $this->_createFundingOption($product);
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /** True when the product already carries any option titled like funding. */
    protected function _hasFundingOption(Mage_Catalog_Model_Product $product)
    {
        foreach ($product->getOptions() as $option) {
            $title = trim((string) $option->getTitle());
            if (strcasecmp($title, self::OPTION_TITLE) === 0) {
                return true;
            }
        }
        // Re-load options from DB in case the in-memory model is stale.
        $coll = Mage::getModel('catalog/product_option')->getCollection()
            ->addProductToFilter($product->getId())
            ->addTitleToResult($product->getStoreId());
        foreach ($coll as $option) {
            $title = trim((string) $option->getTitle());
            if (strcasecmp($title, self::OPTION_TITLE) === 0) {
                return true;
            }
        }
        return false;
    }

    /** Create the radio option with the 5 canonical values. */
    protected function _createFundingOption(Mage_Catalog_Model_Product $product)
    {
        $optionData = array(
            'title'      => self::OPTION_TITLE,
            'type'       => 'radio',
            'is_require' => 0,
            'sort_order' => 100,
            'values'     => array(),
        );
        $sortOrder = 1;
        foreach ($this->_values as $label) {
            $optionData['values'][] = array(
                'title'      => $label,
                'price'      => 0,
                'price_type' => 'fixed',
                'sku'        => '',
                'sort_order' => $sortOrder++,
            );
        }

        $option = Mage::getModel('catalog/product_option')
            ->setProductId($product->getId())
            ->setStoreId($product->getStoreId())
            ->addData($optionData);
        $option->save();
    }
}
