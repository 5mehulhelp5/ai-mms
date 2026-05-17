<?php
/**
 * Quick Registration controller — backs the "New Registration" modal on the
 * sales order index page. Creates a real sales_order from a compact form
 * (learner + course + options + payment) so admins don't have to walk
 * through Magento's stock multi-step order-create wizard.
 *
 * Endpoints (all under /<frontName>/quickreg/):
 *   - searchcourses  : autocomplete catalog products by sku/title (GET ?q=)
 *   - courseinfo     : custom options + course_runs for a product (GET ?product_id=)
 *   - save           : create the order (POST)
 *
 * All endpoints emit JSON. Form-key check is enforced on save.
 */
class MMD_RoleManager_Adminhtml_QuickregController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return true;
    }

    protected function _json($data)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($data));
    }

    /**
     * GET /quickreg/searchcourses?q=<sku or title fragment>
     * Returns up to 20 hits sorted by SKU, scoped to the chosen store
     * (default = SG = store_id 1).
     */
    public function searchcoursesAction()
    {
        $q = trim((string) $this->getRequest()->getParam('q'));
        $storeId = max(1, (int) $this->getRequest()->getParam('store_id', 1));

        if (strlen($q) < 2) {
            $this->_json(['results' => []]);
            return;
        }

        $collection = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId($storeId)
            ->addAttributeToSelect(['sku', 'name', 'price'])
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)
            ->addAttributeToFilter(array(
                ['attribute' => 'sku',  'like' => '%' . $q . '%'],
                ['attribute' => 'name', 'like' => '%' . $q . '%'],
            ))
            ->setOrder('sku', 'ASC')
            ->setPageSize(20);

        $results = [];
        foreach ($collection as $p) {
            $results[] = [
                'product_id' => (int) $p->getId(),
                'sku'        => (string) $p->getSku(),
                'name'       => (string) $p->getName(),
                'price'      => (float) $p->getPrice(),
            ];
        }
        $this->_json(['results' => $results]);
    }

    /**
     * GET /quickreg/courseinfo?product_id=N&store_id=N
     * Returns the product's custom options (so the modal can render select
     * fields) + upcoming course_runs (so the start date dropdown is populated
     * with real scheduled dates).
     */
    public function courseinfoAction()
    {
        $productId = (int) $this->getRequest()->getParam('product_id');
        $storeId   = max(1, (int) $this->getRequest()->getParam('store_id', 1));

        if (!$productId) {
            $this->_json(['error' => 'product_id required']);
            return;
        }

        $product = Mage::getModel('catalog/product')->setStoreId($storeId)->load($productId);
        if (!$product->getId()) {
            $this->_json(['error' => 'product not found']);
            return;
        }

        // Custom options: fold each option's values into the payload so the
        // modal can render the right widget (select / drop_down / radio).
        $options = [];
        foreach ($product->getOptions() as $opt) {
            $row = [
                'option_id' => (int) $opt->getId(),
                'title'     => (string) $opt->getTitle(),
                'type'      => (string) $opt->getType(),
                'required'  => (bool) $opt->getIsRequire(),
                'values'    => [],
            ];
            foreach ($opt->getValues() as $v) {
                $row['values'][] = [
                    'option_type_id' => (int) $v->getOptionTypeId(),
                    'title'          => (string) $v->getTitle(),
                    'price'          => (float) $v->getPrice(),
                    'price_type'     => (string) $v->getPriceType(),
                ];
            }
            $options[] = $row;
        }

        // Course runs: only future / today's dates so we don't offer past
        // start dates in the dropdown.
        $read = Mage::getSingleton('core/resource')->getConnection('core_read');
        $today = date('Y-m-d');
        $runs = $read->fetchAll(
            "SELECT run_id, course_sku, course_start_date, course_end_date, mode_of_training, vacancy
               FROM course_runs
              WHERE product_id = ?
                AND course_start_date >= ?
              ORDER BY course_start_date ASC
              LIMIT 50",
            [$productId, $today]
        );

        $this->_json([
            'product_id' => $productId,
            'sku'        => (string) $product->getSku(),
            'name'       => (string) $product->getName(),
            'price'      => (float) $product->getPrice(),
            'options'    => $options,
            'runs'       => $runs,
        ]);
    }

    /**
     * POST /quickreg/save  (form_key required)
     *
     * Expected fields:
     *   store_id, email, firstname, lastname, telephone,
     *   product_id, qty,
     *   options[option_id] = value (string or option_type_id),
     *   payment_method,
     *   billing_street, billing_city, billing_country_id, billing_postcode,
     *   admin_note (optional)
     */
    public function saveAction()
    {
        if (!$this->getRequest()->isPost()) {
            $this->_json(['ok' => false, 'error' => 'POST required']);
            return;
        }
        $postedKey  = (string) $this->getRequest()->getPost('form_key');
        $sessionKey = (string) Mage::getSingleton('core/session')->getFormKey();
        if ($postedKey === '' || $postedKey !== $sessionKey) {
            $this->_json(['ok' => false, 'error' => 'invalid form key']);
            return;
        }

        try {
            $p = $this->getRequest()->getPost();

            // Sanitize required scalars.
            $storeId   = max(1, (int) ($p['store_id']   ?? 1));
            $productId = (int) ($p['product_id'] ?? 0);
            $qty       = max(1, (int) ($p['qty']        ?? 1));
            $email     = trim((string) ($p['email']     ?? ''));
            $firstname = trim((string) ($p['firstname'] ?? ''));
            $lastname  = trim((string) ($p['lastname']  ?? ''));
            $telephone = trim((string) ($p['telephone'] ?? ''));
            $paymentMethod = trim((string) ($p['payment_method'] ?? 'checkmo'));

            // Sane defaults so Magento doesn't reject the address as incomplete.
            $billingStreet    = trim((string) ($p['billing_street']    ?? 'Virtual delivery'));
            $billingCity      = trim((string) ($p['billing_city']      ?? '-'));
            $billingCountryId = trim((string) ($p['billing_country_id'] ?? ''));
            $billingPostcode  = trim((string) ($p['billing_postcode']  ?? '-'));
            $billingRegion    = trim((string) ($p['billing_region']    ?? '-'));
            $adminNote        = trim((string) ($p['admin_note']        ?? ''));

            // Validate.
            $missing = [];
            if (!$productId)         $missing[] = 'course';
            if ($email === '')       $missing[] = 'email';
            if ($firstname === '')   $missing[] = 'firstname';
            if ($lastname === '')    $missing[] = 'lastname';
            if ($telephone === '')   $missing[] = 'telephone';
            if (!empty($missing)) {
                $this->_json(['ok' => false, 'error' => 'missing fields: ' . implode(', ', $missing)]);
                return;
            }

            $store = Mage::app()->getStore($storeId);
            if (!$store->getId()) {
                $this->_json(['ok' => false, 'error' => 'invalid store_id']);
                return;
            }

            // Fall back to the store's default country if the form didn't pass one.
            if ($billingCountryId === '') {
                $billingCountryId = (string) Mage::getStoreConfig('general/country/default', $store);
                if ($billingCountryId === '') $billingCountryId = 'SG';
            }

            $product = Mage::getModel('catalog/product')->setStoreId($storeId)->load($productId);
            if (!$product->getId()) {
                $this->_json(['ok' => false, 'error' => 'course not found']);
                return;
            }

            // ---- 1. Find or create the customer (auto-link by email).
            $websiteId = $store->getWebsiteId();
            $customer = Mage::getModel('customer/customer')->setWebsiteId($websiteId)->loadByEmail($email);
            if (!$customer->getId()) {
                $customer = Mage::getModel('customer/customer');
                $customer->setWebsiteId($websiteId)
                    ->setStoreId($storeId)
                    ->setGroupId(Mage::getStoreConfig('customer/create_account/default_group', $store))
                    ->setEmail($email)
                    ->setFirstname($firstname)
                    ->setLastname($lastname)
                    ->setPassword($customer->generatePassword(10))
                    ->save();
            }

            // ---- 2. Build the quote.
            $quote = Mage::getModel('sales/quote')->setStore($store);
            $quote->assignCustomer($customer);
            $quote->setCustomerIsGuest(false);

            // Add the course with options.
            $buyRequest = new Varien_Object(['qty' => $qty]);
            // Options come in as options[<option_id>] = value
            if (!empty($p['options']) && is_array($p['options'])) {
                $optionsPayload = [];
                foreach ($p['options'] as $optId => $val) {
                    // Drop empty strings so the option engine doesn't reject the row.
                    if ($val === '' || $val === null) continue;
                    $optionsPayload[(int) $optId] = $val;
                }
                if (!empty($optionsPayload)) {
                    $buyRequest->setOptions($optionsPayload);
                }
            }
            $quote->addProduct($product, $buyRequest);

            // Common address payload.
            $addrData = [
                'firstname'  => $firstname,
                'lastname'   => $lastname,
                'street'     => $billingStreet,
                'city'       => $billingCity,
                'region'     => $billingRegion,
                'postcode'   => $billingPostcode,
                'country_id' => $billingCountryId,
                'telephone'  => $telephone,
                'email'      => $email,
                'save_in_address_book' => 0,
            ];
            $quote->getBillingAddress()->addData($addrData);
            // Even though courses are virtual, Magento's quote requires a
            // shipping address row — mirror billing and pick free shipping.
            $quote->getShippingAddress()
                ->addData($addrData)
                ->setCollectShippingRates(true)
                ->setShippingMethod('freeshipping_freeshipping');

            $quote->getPayment()->importData(['method' => $paymentMethod]);
            $quote->collectTotals()->save();

            // ---- 3. Submit the quote → order.
            $service = Mage::getModel('sales/service_quote', $quote);
            $service->submitAll();
            $order = $service->getOrder();

            if ($adminNote !== '') {
                $order->addStatusHistoryComment('Quick reg note: ' . $adminNote)->save();
            }

            $this->_json([
                'ok'           => true,
                'order_id'     => (int) $order->getId(),
                'increment_id' => (string) $order->getIncrementId(),
                'edit_url'     => Mage::helper('adminhtml')->getUrl(
                    'adminhtml/sales_order/view',
                    ['order_id' => $order->getId()]
                ),
            ]);
        } catch (Exception $e) {
            Mage::logException($e);
            $this->_json([
                'ok'    => false,
                'error' => $e->getMessage(),
                'trace' => Mage::getIsDeveloperMode() ? $e->getTraceAsString() : null,
            ]);
        }
    }
}
