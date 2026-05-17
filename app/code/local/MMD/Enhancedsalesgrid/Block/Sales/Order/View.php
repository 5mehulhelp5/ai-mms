<?php
/**
 * Enhancedsalesgrid's config.xml rewrites the adminhtml `sales_order_view`
 * block to this class, but the class file was never committed (same gap as
 * the missing grid renderers fixed in d1e87b8d). With the rewrite pointing
 * at a non-existent class, the block fails to instantiate and the order
 * view "content" column renders empty — a completely blank Order View page.
 *
 * This passthrough subclass restores stock Magento order-view behaviour
 * while keeping the rewrite hook in place for any future customisation.
 */
class MMD_Enhancedsalesgrid_Block_Sales_Order_View extends Mage_Adminhtml_Block_Sales_Order_View
{
}
