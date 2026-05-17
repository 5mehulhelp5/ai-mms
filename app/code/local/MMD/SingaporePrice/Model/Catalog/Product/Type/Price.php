<?php
/**
 * MMD_SingaporePrice_Model_Catalog_Product_Type_Price
 *
 * Persists the SG funding-discount math from quote → checkout → order.
 *
 * Why a class rewrite rather than an observer:
 *
 *   The standard final-price chain is
 *
 *       $finalPrice = parent::getFinalPrice($qty, $product);
 *       // dispatches catalog_product_get_final_price (observer slot)
 *       $finalPrice = $this->_applyOptionsPrice(...);
 *       $product->setFinalPrice($finalPrice);
 *
 *   The observer slot fires BEFORE _applyOptionsPrice, and the parent
 *   class's _applyOptionsPrice (the MMD_CustomOptions implementation)
 *   resets finalPrice to 0 and then re-adds basePrice when none of
 *   the selected options carry a $-price. That overwrites anything an
 *   observer would have set. So the only safe injection point is
 *   after _applyOptionsPrice returns — which means a class rewrite.
 *
 * Extension chain (least to most specific):
 *
 *   Mage_Catalog_Model_Product_Type_Price
 *     ↑ extends
 *   MMD_CustomOptions_Model_Catalog_Product_Type_Price   ← option-price math
 *     ↑ extends
 *   MMD_SingaporePrice_Model_Catalog_Product_Type_Price  ← this class
 *
 *   When MMD_CustomOptions is eventually retired:
 *     1. Change `extends MMD_CustomOptions_Model_…_Price` to
 *        `extends Mage_Catalog_Model_Product_Type_Price`.
 *     2. Remove the <depends>Mage_Catalog</depends> note in this
 *        module's module xml (no longer relevant).
 *     3. Delete the customoptions <rewrite> entry from its config.xml
 *        (already gone with the module).
 *   No other changes needed in this file.
 */
class MMD_SingaporePrice_Model_Catalog_Product_Type_Price
    extends MMD_CustomOptions_Model_Catalog_Product_Type_Price
{
    /**
     * After the parent has resolved the option-loaded final price,
     * apply the SG funding-discount percent if the buyer selected a
     * Funding-Eligibility radio whose label maps to a configured
     * percent in mmd_company/sg_funding/*.
     *
     * @param Mage_Catalog_Model_Product $product
     * @param float                       $qty
     * @param float                       $finalPrice
     * @return float
     */
    protected function _applyOptionsPrice($product, $qty, $finalPrice)
    {
        $finalPrice = parent::_applyOptionsPrice($product, $qty, $finalPrice);

        /** @var MMD_SingaporePrice_Helper_Data $helper */
        $helper = Mage::helper('mmd_singaporeprice');
        if (!$helper->isActive($product->getStoreId())) {
            return $finalPrice;
        }

        $percent = $this->_fundingDiscountPercent($product, $helper);
        if ($percent <= 0) {
            return $finalPrice;
        }

        // The "course fee" before tax = catalog list × (1 − y/100).
        // Tax (GST) is applied separately by Magento's tax engine on
        // the catalog list price (see Mage_Tax + SG GST override in
        // app/code/local/MMD/Branchscope), so we only need to return
        // the discounted fee here, not the GST-inclusive total.
        $catalogPrice = $helper->getCatalogPrice($product);
        $discounted   = $helper->computeFee($catalogPrice, $percent);

        return max(0, $discounted);
    }

    /**
     * Inspect every selected custom option on the buy request. For
     * each one, look up the chosen value's title and check whether
     * it maps to a configured SG funding row. Return the highest
     * matching percent — only one funding option should ever be
     * selected per product, but max() defends against duplicate
     * configurations.
     *
     * @param Mage_Catalog_Model_Product             $product
     * @param MMD_SingaporePrice_Helper_Data         $helper
     * @return float 0–100
     */
    protected function _fundingDiscountPercent($product, $helper)
    {
        $optionIdsOpt = $product->getCustomOption('option_ids');
        if (!$optionIdsOpt) {
            return 0.0;
        }

        $map = $helper->getFundingDiscountMap();
        if (empty($map)) {
            return 0.0;
        }

        $best = 0.0;
        foreach (explode(',', (string) $optionIdsOpt->getValue()) as $optionId) {
            $optionId = (int) $optionId;
            if (!$optionId) {
                continue;
            }
            $option = $product->getOptionById($optionId);
            if (!$option) {
                continue;
            }
            $selectedOpt = $product->getCustomOption('option_' . $optionId);
            if (!$selectedOpt) {
                continue;
            }
            $selectedValueId = (string) $selectedOpt->getValue();
            if ($selectedValueId === '') {
                continue;
            }

            foreach ($option->getValues() as $value) {
                if ((string) $value->getOptionTypeId() !== $selectedValueId) {
                    continue;
                }
                $key = strtolower(trim(preg_replace('/\s+/', ' ', (string) $value->getTitle())));
                if (isset($map[$key]) && (float) $map[$key] > $best) {
                    $best = (float) $map[$key];
                }
            }
        }

        return $best;
    }
}
