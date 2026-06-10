<?php
/**
 * Thin rewrite of sales/order that exposes pro-forma eligibility to the
 * New Order email template.
 *
 * The template gates the "Download Pro Forma Invoice" block with
 * {{if order.getIsSelfSponsored()}} — the email filter resolves that to this
 * method on the order object. A pro forma is only for self-sponsored
 * SkillsFuture Credit claims; employer/company-sponsored registrations are
 * company-invoiced and must not get one.
 *
 * No other active module rewrites sales/order (the legacy MMD_Checkoutoptions
 * module that used to is not declared / not active), so this rewrite is
 * conflict-free. Logic lives in MMD_Proforma_Helper_Data so the controller and
 * the order share one source of truth.
 */
class MMD_Proforma_Model_Order extends Mage_Sales_Model_Order
{
    /**
     * @return bool true when the registration is self-sponsored.
     */
    public function getIsSelfSponsored()
    {
        return Mage::helper('proforma')->isOrderSelfSponsored($this);
    }
}
