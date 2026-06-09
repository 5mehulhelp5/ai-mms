<?php
/**
 * Renders a Pro Forma Invoice PDF directly from a Mage_Sales_Model_Order.
 *
 * Extends the core invoice PDF model purely to reuse its drawing
 * infrastructure (logo, store address, font helpers, page handling). It does
 * NOT render a real invoice — there is no sales/order_invoice involved. A pro
 * forma is produced from the registration (order) itself, before payment, so
 * self-sponsored SG learners can submit it to MySkillsFuture for their
 * SkillsFuture Credit (SFC) claim.
 *
 * Totals are taken verbatim from the stored order. In particular GST is
 * displayed from $order->getTaxAmount() and is NOT recomputed — SG GST is
 * deliberately settled on the pre-subsidy course list price, not the
 * discounted subtotal (see CLAUDE.md). Recomputing here would contradict the
 * tax the learner actually pays.
 */
class MMD_Proforma_Model_Proforma extends Mage_Sales_Model_Order_Pdf_Invoice
{
    /** Column x feeds (A4 content band is roughly 25..570pt). */
    protected $_colCourse   = 30;
    protected $_colSchedule = 250;
    protected $_colQty      = 400;   // right-aligned
    protected $_colPrice    = 485;   // right-aligned
    protected $_colAmount   = 565;   // right-aligned

    /**
     * @param  Mage_Sales_Model_Order $order
     * @return Zend_Pdf
     */
    public function getOrderPdf(Mage_Sales_Model_Order $order)
    {
        $this->_beforeGetPdf();

        $pdf = new Zend_Pdf();
        $this->_setPdf($pdf);

        $storeId = $order->getStoreId();
        if ($storeId) {
            Mage::app()->getLocale()->emulate($storeId);
            Mage::app()->setCurrentStore($storeId);
        }
        $store = $order->getStore();

        $page = $this->newPage();

        /* Header: store logo (left) + store identity address (right) */
        $this->insertLogo($page, $store);
        $this->insertAddress($page, $store);

        /* Title + meta */
        $this->y = 715;
        $this->_setFontBold($page, 18);
        $page->setFillColor(new Zend_Pdf_Color_Rgb(0.09, 0.12, 0.20));
        $page->drawText('PRO FORMA INVOICE', 25, $this->y, 'UTF-8');
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0));

        $metaY = $this->y;
        $this->_textRight($page, 'Pro Forma No: ' . $order->getIncrementId(), 570, $metaY, 10);
        $metaY -= 14;
        $date = Mage::helper('core')->formatDate($order->getCreatedAtStoreDate(), 'medium', false);
        $this->_textRight($page, 'Date: ' . $date, 570, $metaY, 10);

        /* Divider */
        $this->y -= 24;
        $page->setLineColor(new Zend_Pdf_Color_GrayScale(0.75));
        $page->setLineWidth(0.8);
        $page->drawLine(25, $this->y, 570, $this->y);
        $this->y -= 24;

        /* Bill To */
        $this->_setFontBold($page, 11);
        $page->drawText('Bill To', 25, $this->y, 'UTF-8');
        $this->y -= 16;
        $this->_setFontRegular($page, 10);
        foreach ($this->_billToLines($order) as $line) {
            foreach (Mage::helper('core/string')->str_split($line, 75, true, true) as $part) {
                $page->drawText(trim($part), 25, $this->y, 'UTF-8');
                $this->y -= 13;
            }
        }

        $this->y -= 16;

        /* Items table */
        $this->_drawTableHeader($page);
        foreach ($order->getAllVisibleItems() as $item) {
            if ($this->y < 160) {
                $page = $this->newPage();
                $this->y = 790;
                $this->_drawTableHeader($page);
            }
            $this->_drawItemRow($page, $order, $item);
        }

        /* Totals + notes */
        if ($this->y < 200) {
            $page = $this->newPage();
            $this->y = 790;
        }
        $this->_drawTotals($page, $order);
        $this->_drawNotes($page, $order);

        if ($storeId) {
            Mage::app()->getLocale()->revert();
        }

        $this->_afterGetPdf();
        return $pdf;
    }

    /* ------------------------------------------------------------------ */

    protected function _billToLines(Mage_Sales_Model_Order $order)
    {
        $lines   = array();
        $billing = $order->getBillingAddress();

        // Build from explicit fields rather than the address pdf template,
        // which bundles the recipient name and space-joins street lines —
        // that produced a duplicated name and a mashed street line.
        $name = trim((string) $order->getCustomerName());
        if ($name === '' && $billing) {
            $name = trim((string) $billing->getName());
        }
        if ($name !== '' && strcasecmp($name, 'Guest') !== 0) {
            $lines[] = $name;
        }

        if ($billing) {
            if (trim((string) $billing->getCompany()) !== '') {
                $lines[] = trim((string) $billing->getCompany());
            }
            foreach ((array) $billing->getStreet() as $street) {
                $street = trim((string) $street);
                if ($street !== '') {
                    $lines[] = $street;
                }
            }
            $cityParts = array(trim((string) $billing->getCity()));
            $region    = trim((string) $billing->getRegion());
            if ($region !== '' && strcasecmp($region, (string) $billing->getCity()) !== 0) {
                $cityParts[] = $region;
            }
            $cityParts[] = trim((string) $billing->getPostcode());
            $cityLine = trim(implode(' ', array_filter($cityParts)));
            if ($cityLine !== '') {
                $lines[] = $cityLine;
            }
            $countryModel = $billing->getCountryModel();
            $country = $countryModel ? trim((string) $countryModel->getName()) : '';
            if ($country !== '') {
                $lines[] = $country;
            }
            if (trim((string) $billing->getTelephone()) !== '') {
                $lines[] = 'Tel: ' . trim((string) $billing->getTelephone());
            }
        }

        $email = trim((string) $order->getCustomerEmail());
        if ($email !== '') {
            $lines[] = $email;
        }
        if (empty($lines)) {
            $lines[] = '-';
        }
        return $lines;
    }

    protected function _drawTableHeader(&$page)
    {
        $page->setFillColor(new Zend_Pdf_Color_Rgb(0.09, 0.12, 0.20));
        $page->drawRectangle(25, $this->y, 570, $this->y - 18, Zend_Pdf_Page::SHAPE_DRAW_FILL);
        $this->_setFontBold($page, 9);
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(1));

        $textY = $this->y - 12;
        $page->drawText('Course', $this->_colCourse, $textY, 'UTF-8');
        $page->drawText('Schedule', $this->_colSchedule, $textY, 'UTF-8');
        $this->_textRight($page, 'Qty', $this->_colQty, $textY, 9, true);
        $this->_textRight($page, 'Unit Price', $this->_colPrice, $textY, 9, true);
        $this->_textRight($page, 'Amount', $this->_colAmount, $textY, 9, true);

        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0));
        $this->y -= 26;
    }

    protected function _drawItemRow(&$page, Mage_Sales_Model_Order $order, $item)
    {
        $rowTop = $this->y;

        /* Course name (wrapped) */
        $this->_setFontRegular($page, 9);
        $nameLines = Mage::helper('core/string')->str_split(
            trim((string) $item->getName()), 46, true, true
        );
        $y = $rowTop;
        foreach ($nameLines as $nl) {
            $page->drawText(trim($nl), $this->_colCourse, $y, 'UTF-8');
            $y -= 11;
        }
        /* SKU under the name in grey */
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0.45));
        $this->_setFontRegular($page, 8);
        $page->drawText('SKU: ' . trim((string) $item->getSku()), $this->_colCourse, $y, 'UTF-8');
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0));
        $y -= 11;
        $courseBottom = $y;

        /* Schedule (Course Date + Course Time custom options) */
        $this->_setFontRegular($page, 9);
        $schedY = $rowTop;
        $courseDate = $this->_itemOption($item, 'Course Date');
        $courseTime = $this->_itemOption($item, 'Course Time');
        foreach (array($courseDate, $courseTime) as $piece) {
            if ($piece === '') {
                continue;
            }
            foreach (Mage::helper('core/string')->str_split($piece, 28, true, true) as $pl) {
                $page->drawText(trim($pl), $this->_colSchedule, $schedY, 'UTF-8');
                $schedY -= 11;
            }
        }

        /* Numeric columns (top-aligned with the row) */
        $qty = (float) $item->getQtyOrdered();
        $this->_textRight($page, rtrim(rtrim(number_format($qty, 2), '0'), '.'), $this->_colQty, $rowTop, 9);
        $this->_textRight($page, $order->formatPriceTxt($item->getPrice()), $this->_colPrice, $rowTop, 9);
        $this->_textRight($page, $order->formatPriceTxt($item->getRowTotal()), $this->_colAmount, $rowTop, 9);

        /* Advance below whichever column ran longest, then a faint separator */
        $this->y = min($courseBottom, $schedY) - 6;
        $page->setLineColor(new Zend_Pdf_Color_GrayScale(0.85));
        $page->setLineWidth(0.5);
        $page->drawLine(25, $this->y, 570, $this->y);
        $this->y -= 14;
    }

    protected function _drawTotals(&$page, Mage_Sales_Model_Order $order)
    {
        $labelX = 360;
        $valX   = $this->_colAmount;

        $this->y -= 6;
        $rows = array();
        $rows[] = array('Subtotal', $order->getSubtotal(), false);

        $discount = (float) $order->getDiscountAmount();
        if (abs($discount) > 0.001) {
            $rows[] = array('Discount', $discount, false);
        }
        $rows[] = array('GST', $order->getTaxAmount(), false);
        $rows[] = array('Total Payable (' . $order->getOrderCurrencyCode() . ')', $order->getGrandTotal(), true);

        foreach ($rows as $r) {
            list($label, $amount, $emphasis) = $r;
            if ($emphasis) {
                $this->y -= 4;
                $page->setLineColor(new Zend_Pdf_Color_GrayScale(0.4));
                $page->setLineWidth(0.8);
                $page->drawLine($labelX, $this->y + 12, 570, $this->y + 12);
                $this->_setFontBold($page, 11);
            } else {
                $this->_setFontRegular($page, 10);
            }
            $page->drawText($label, $labelX, $this->y, 'UTF-8');
            $this->_textRight($page, $order->formatPriceTxt($amount), $valX, $this->y, $emphasis ? 11 : 10, $emphasis);
            $this->y -= $emphasis ? 18 : 15;
        }
    }

    protected function _drawNotes(&$page, Mage_Sales_Model_Order $order)
    {
        $this->y -= 20;
        if ($this->y < 90) {
            $page = $this->newPage();
            $this->y = 790;
        }

        $this->_setFontBold($page, 9);
        $page->drawText('Notes', 25, $this->y, 'UTF-8');
        $this->y -= 14;

        $this->_setFontRegular($page, 9);
        $notes = array(
            'This is a pro forma invoice issued for course registration and funding-claim purposes '
                . '(e.g. SkillsFuture Credit). It is not a receipt of payment.',
            'For SkillsFuture Credit (SFC) claims, submit this pro forma invoice via the MySkillsFuture '
                . 'portal before the class start date.',
            'For an official tax invoice for payment processing, reply to your registration email or '
                . 'contact ' . $this->_storeEmail($order) . '.',
        );
        foreach ($notes as $note) {
            foreach (Mage::helper('core/string')->str_split($note, 110, true, true) as $line) {
                $page->drawText(trim($line), 25, $this->y, 'UTF-8');
                $this->y -= 12;
            }
            $this->y -= 3;
        }

        $this->y -= 6;
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0.5));
        $this->_setFontItalic($page, 8);
        $page->drawText('Computer-generated pro forma invoice — no signature required.', 25, $this->y, 'UTF-8');
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0));
    }

    /* ------------------------------------------------------------------ */

    /**
     * Pull a named custom-option value (e.g. "Course Date") off an order item.
     */
    protected function _itemOption($item, $label)
    {
        $opts = $item->getProductOptions();
        if (is_array($opts) && !empty($opts['options'])) {
            foreach ($opts['options'] as $o) {
                if (isset($o['label']) && strcasecmp(trim($o['label']), $label) === 0) {
                    return isset($o['value']) ? trim((string) $o['value']) : '';
                }
            }
        }
        return '';
    }

    protected function _storeEmail(Mage_Sales_Model_Order $order)
    {
        $email = Mage::getStoreConfig('trans_email/ident_sales/email', $order->getStoreId());
        return $email ?: 'sales@tertiarycourses.com.sg';
    }

    /**
     * Draw right-aligned text ending at $rightX on baseline $y.
     */
    protected function _textRight(&$page, $text, $rightX, $y, $size, $bold = false)
    {
        $font = $bold ? $this->_setFontBold($page, $size) : $this->_setFontRegular($page, $size);
        $width = $this->widthForStringUsingFontSize($text, $font, $size);
        $page->drawText($text, $rightX - $width, $y, 'UTF-8');
    }
}
