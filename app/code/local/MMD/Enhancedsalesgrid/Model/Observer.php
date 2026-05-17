<?php
class MMD_Enhancedsalesgrid_Model_Observer
{

	public function salesOrderGridCollectionLoadBefore(Varien_Event_Observer $observer)
    {

        $collection = $observer->getEvent()->getOrderGridCollection();

        $select = $collection->getSelect();

        // Branch (store) filter for the Registrations grid.
        // Default = Singapore (store_id 1); ?branch=all disables the filter.
        // Applied here (load-before) so it covers the grid render AND any
        // other code path that loads this collection on the registrations page.
        $req = Mage::app()->getRequest();
        $route = $req->getRouteName() . '/' . $req->getControllerName() . '/' . $req->getActionName();
        if (strpos($route, 'adminhtml/sales_order/') === 0) {
            $rawBranch = $req->getParam('branch', null);
            if ($rawBranch === null) {
                $branch = '1';
            } elseif ((string) $rawBranch === 'all') {
                $branch = '';
            } else {
                $branch = (string) $rawBranch;
            }
            if ($branch !== '' && ctype_digit($branch)) {
                $select->where('main_table.store_id = ?', (int) $branch);
            }
        }

        // Add the selected columns if they are enabled
        $enabled_options = Mage::getStoreConfig('enhancedsalesgrid/options/columns_to_show');
        $enabled_options = explode(',', $enabled_options);

        if(in_array('products_ordered', $enabled_options) || in_array('products_options', $enabled_options)) {
            $table_sales_flat_order_item = Mage::getSingleton('core/resource')->getTableName('sales/order_item');
            $select->joinLeft(
                $table_sales_flat_order_item,
                'main_table.entity_id = '.$table_sales_flat_order_item.'.order_id',
                array(
                    'product_options',
                    'products_ordered' => 'GROUP_CONCAT(DISTINCT ROUND(qty_ordered), " x ", name, " (", sku, ")" SEPARATOR "'.PHP_EOL.'")',
                    'order_tax_percent' => 'MAX('.$table_sales_flat_order_item.'.tax_percent)',
                )
            );
            //$select->group('main_table.entity_id');
        }

		$feilds = array();
		 if(in_array('subtotal', $enabled_options)) {
           $feilds[]="subtotal";
        }

        if(in_array('customer_email', $enabled_options)) {
		$feilds[]="customer_email";
		}
		 if(in_array('shipping_amount', $enabled_options)) {
		$feilds[]="shipping_amount";
		}
		// Always pull tax + discount so the Tax Rate column renders correctly.
		$feilds[] = 'tax_amount';
		$feilds[] = 'discount_amount';
			
        /* if($feilds) {*/
		 $table_sales_flat_order = Mage::getSingleton('core/resource')->getTableName('sales/order');
            $select->joinLeft(
                $table_sales_flat_order,
                'main_table.entity_id = '.$table_sales_flat_order.'.entity_id',$feilds
                
            );
       /* }*/
		
				
		if(in_array('shipping_address', $enabled_options) || in_array('telephone', $enabled_options)) {
            $shipping_address = Mage::getSingleton('core/resource')->getTableName('sales_flat_order_address');
            $select->joinLeft(
                $shipping_address,
                'main_table.entity_id = '.$shipping_address.'.parent_id AND address_type="shipping"',
                array('telephone','postcode','shipping_address' => 'CONCAT(IF(street IS NULL, "--", street),", ", IF(city IS NULL, "--", city),", ",IF(region IS NULL, "--", region),", ",IF(country_id IS NULL, "--", country_id),", ",IF(postcode IS NULL, "--", postcode))')
            );
            //$select->group('main_table.entity_id');
        }
		
		
				
		if(in_array('payment_method', $enabled_options)) {
            $payment_method = Mage::getSingleton('core/resource')->getTableName('sales_flat_order_payment');
            $select->joinLeft(
                $payment_method,
                'main_table.entity_id = '.$payment_method.'.parent_id',
                array('payment_method' => 'method')
            );
           
        }
		 $select->group('main_table.entity_id');  
		
		$select->distinct(true);
           		 
    }
}
