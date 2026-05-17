<?php
class MMD_Enhancedsalesgrid_Block_Sales_Order_Grid extends Mage_Adminhtml_Block_Sales_Order_Grid
{
    	 
	 protected function _getStore()
    {
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        return Mage::app()->getStore($storeId);
    }

    /**
     * Filter by parsed Course Date inside the serialised product_options blob.
     * Matches order items whose Course Date option text references a calendar
     * date inside the supplied [from, to] range. Pattern recognises tokens like
     * "13/14 May 2026", "5 Jun 2026", "5 - 7 June 2026".
     */
    protected function _filterCourseDateRange($collection, $column)
    {
        $cond = $column->getFilter()->getValue();
        if (!$cond) {
            return $this;
        }
        $from = isset($cond['from']) ? strtotime($cond['from']) : null;
        $to   = isset($cond['to'])   ? strtotime($cond['to'])   : null;
        if (!$from && !$to) {
            return $this;
        }

        $months = '(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*';
        // Match a leading day (or day-range "13/14" / "13-14") + month + year.
        $regex  = '\\\\b([0-9]{1,2})(?:[\\\\/\\\\-][0-9]{1,2})?\\\\s+(' . $months . ')\\\\s+([0-9]{4})\\\\b';

        $select = $collection->getSelect();
        $expr = "REGEXP_SUBSTR(sales_flat_order_item.product_options, '" . $regex . "')";
        // Cast first parsed date in the option text to DATE for range compare.
        $dateExpr = "STR_TO_DATE($expr, '%d %b %Y')";

        if ($from) {
            $select->where($dateExpr . ' >= ?', date('Y-m-d', $from));
        }
        if ($to) {
            $select->where($dateExpr . ' <= ?', date('Y-m-d', $to));
        }
        return $this;
    }
	 protected function _addCouponCodeMetodToFilter($collection, $column){
                $names = $column->getFilter()->getValue();
                $namesArray = explode(' ', $names);
                $cond = array();
                foreach ($namesArray as $item)
                {
                    $cond[] = 'sales_flat_order_address.street LIKe "%'.$item.'%" OR sales_flat_order_address.city LIKe "%'.$item.'%" OR sales_flat_order_address.region LIKe "%'.$item.'%" OR sales_flat_order_address.postcode LIKe "%'.$item.'%"' ;
                }
                $collection->getSelect()->where("(".implode(' OR ', $cond).")");
                return $this;
                //$collection->printlogquery(true);
                //die;
                
        } 
	protected function _prepareColumns()
    {
        $store = $this->_getStore();

        // 1. Reg #  — no filter (per spec, only the 6 listed columns filter)
        $this->addColumn('real_order_id', array(
            'header'       => Mage::helper('sales')->__('Reg #'),
            'width'        => '80px',
            'type'         => 'text',
            'index'        => 'increment_id',
            'filter'       => false,
            'filter_index' => 'main_table.increment_id',
        ));

        // 2. Reg Date — no filter
        $this->addColumn('created_at', array(
            'header'       => Mage::helper('sales')->__('Reg Date'),
            'index'        => 'created_at',
            'type'         => 'datetime',
            'width'        => '120px',
            'filter'       => false,
            'filter_index' => 'sales_flat_order.created_at',
        ));

        // 3. Learner Name — no filter
        $this->addColumn('billing_name', array(
            'header' => Mage::helper('sales')->__('Learner Name'),
            'index'  => 'billing_name',
            'width'  => '140px',
            'filter' => false,
        ));

        // 4. Learner Email — no filter
        $this->addColumn('customer_email', array(
            'header'       => Mage::helper('sales')->__('Learner Email'),
            'index'        => 'customer_email',
            'type'         => 'text',
            'width'        => '180px',
            'filter'       => false,
            'filter_index' => 'sales_flat_order.customer_email',
        ));

        // 5. Course
        $this->addColumn('products_ordered', array(
            'header'           => Mage::helper('sales')->__('Course'),
            'index'            => 'products_ordered',
            'renderer'         => 'enhancedsalesgrid/sales_order_grid_renderer_product',
            'type'             => 'textarea',
            'width'            => '260px',
            'column_css_class' => 'col-products-ordered',
            'filter_index'     => 'sales_flat_order_item.name',
        ));

        // 6. Course Date (renderer filters product_options to just Course Date).
        // Filter is a from/to date range parsed out of the option text.
        $this->addColumn('product_options', array(
            'header'                    => Mage::helper('sales')->__('Course Date'),
            'index'                     => 'product_options',
            'renderer'                  => 'MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Options',
            'type'                      => 'date',
            'width'                     => '160px',
            'filter_index'              => 'sales_flat_order_item.product_options',
            'filter_condition_callback' => array($this, '_filterCourseDateRange'),
        ));

        // 7. Branch (store) — strip the trailing " Store View" suffix so the
        // column reads "Singapore", "Malaysia", etc.
        $branchOptions = array();
        foreach (Mage::getModel('core/store')->getCollection() as $_store) {
            $name = preg_replace('/\s*Store View\s*$/i', '', $_store->getName());
            $branchOptions[$_store->getId()] = $name;
        }
        $this->addColumn('store_id', array(
            'header'       => Mage::helper('sales')->__('Branch'),
            'index'        => 'store_id',
            'type'         => 'options',
            'width'        => '120px',
            'filter_index' => 'sales_flat_order.store_id',
            'options'      => $branchOptions,
        ));

        // 8. Fee (subtotal)
        $this->addColumn('subtotal', array(
            'header'        => Mage::helper('sales')->__('Fee'),
            'index'         => 'subtotal',
            'type'          => 'price',
            'currency'      => 'price',
            'currency_code' => $store->getBaseCurrency()->getCode(),
            'filter_index'  => 'sales_flat_order.subtotal',
            'width'         => '90px',
            'align'         => 'left',
        ));

        // 9. Tax Rate — derived from (tax_amount / subtotal) * 100
        $this->addColumn('tax_rate', array(
            'header'   => Mage::helper('sales')->__('Tax Rate'),
            'index'    => 'tax_amount',
            'renderer' => 'MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Taxrate',
            'filter'   => false,
            'sortable' => false,
            'width'    => '70px',
            'align'    => 'left',
        ));

        // 10. Fee + Tax (base grand total)
        $this->addColumn('base_grand_total', array(
            'header'       => Mage::helper('sales')->__('Fee + Tax'),
            'index'        => 'base_grand_total',
            'type'         => 'currency',
            'currency'     => 'base_currency_code',
            'filter_index' => 'sales_flat_order.base_grand_total',
            'width'        => '90px',
            'align'        => 'left',
        ));

        // 10. Payment Method
        $connection = Mage::getSingleton('core/resource')->getConnection('core_read');
        $sql = "select method from " . Mage::getConfig()->getTablePrefix()
            . "sales_flat_order_payment group by method order by method";
        $rowsArray = $connection->fetchAll($sql);
        $payment_options = array();
        if ($rowsArray) {
            foreach ($rowsArray as $row) {
                $payment_options[$row['method']] = $row['method'];
            }
        }
        $this->addColumn('payment_method', array(
            'header'       => Mage::helper('sales')->__('Payment Method'),
            'index'        => 'payment_method',
            'type'         => 'options',
            'width'        => '110px',
            'options'      => $payment_options,
            'filter_index' => Mage::getConfig()->getTablePrefix() . 'sales_flat_order_payment.method',
        ));

        // 11. Status
        $this->addColumn('status', array(
            'header'       => Mage::helper('sales')->__('Status'),
            'index'        => 'status',
            'filter_index' => 'main_table.status',
            'type'         => 'options',
            'width'        => '90px',
            'options'      => Mage::getSingleton('sales/order_config')->getStatuses(),
        ));

        // 12. Action (View / Cancel)
        if (Mage::getSingleton('admin/session')->isAllowed('sales/order/actions/view')) {
            $this->addColumn('action', array(
                'header'   => Mage::helper('sales')->__('Action'),
                'width'    => '110px',
                'type'     => 'action',
                'renderer' => 'MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Actionlinks',
                'getter'   => 'getId',
                'actions'  => array(
                    array(
                        'caption' => Mage::helper('sales')->__('View'),
                        'url'     => array('base' => '*/sales_order/view'),
                        'field'   => 'order_id',
                    ),
                    array(
                        'caption' => Mage::helper('sales')->__('Cancel'),
                        'url'     => array('base' => '*/sales_order/cancel'),
                        'field'   => 'order_id',
                        'confirm' => Mage::helper('sales')->__('Cancel this registration?'),
                    ),
                ),
                'filter'    => false,
                'sortable'  => false,
                'index'     => 'stores',
                'is_system' => true,
            ));
        }

        $this->addExportType('*/*/exportCsv', Mage::helper('sales')->__('CSV'));
        $this->addExportType('*/*/exportExcel', Mage::helper('sales')->__('Excel XML'));

        return $this;
    }

    /**
     * Suppress the mass-action ("Actions … Submit") dropdown — the Registrations
     * grid uses per-row View/Cancel links instead.
     */
    protected function _prepareMassaction()
    {
        return $this;
    }
}
