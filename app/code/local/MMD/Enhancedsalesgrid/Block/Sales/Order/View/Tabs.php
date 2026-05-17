<?php
/**
 * Counterpart to MMD_Enhancedsalesgrid_Block_Sales_Order_View: config.xml
 * also rewrites `sales_order_view_tabs` to this class, which likewise was
 * never committed. The missing class made the order-view tabs block (the
 * "left" reference holding Information / Invoices / Credit Memos / …) fail
 * to render, contributing to the blank Order View page.
 *
 * Passthrough subclass — restores stock tab behaviour, keeps the hook.
 */
class MMD_Enhancedsalesgrid_Block_Sales_Order_View_Tabs extends Mage_Adminhtml_Block_Sales_Order_View_Tabs
{
}
