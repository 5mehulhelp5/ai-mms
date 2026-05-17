<?php
/**
 * Kael Review API — POST a product review programmatically.
 *
 * Endpoint: POST <site_base_url>/kael_review_api.php
 *
 * Headers:
 *   Content-Type: application/json
 *   X-Api-Key:    <KAEL_REVIEW_API_KEY env var>
 *
 * Request body (JSON):
 * {
 *   "product_id":  1362,                       // required, int — Magento product entity_id
 *   "nickname":    "John Tan",                 // required, string
 *   "title":       "Average Rating: 4.7/5",    // required, string
 *   "detail":      "Great course!",            // required, string
 *   "ratings":     { "1": 5, "2": 5, "5": 4 }, // required, map of rating_id => stars (1-5)
 *   "created_at":  "2026-04-10 04:00:17",      // optional, ISO/MySQL datetime — defaults to NOW()
 *   "store_id":    1,                          // optional, int — defaults to current store
 *   "customer_id": null                        // optional, int — defaults to null (guest review)
 * }
 *
 * Rating IDs (multi-criteria review form on this site):
 *   "1" = "Do you find the course meet your expectation?"  (1-5 stars)
 *   "2" = "Do you find the trainer knowledgeable?"         (1-5 stars)
 *   "5" = "How do you find the training environment?"      (1-5 stars)
 *
 * Reviews are always saved with status = APPROVED so they appear on the
 * storefront immediately.
 *
 * Success response (HTTP 200):
 *   { "success": true, "review_id": 22863, "message": "Review created and approved" }
 *
 * Error responses:
 *   400  Invalid JSON / missing required field / invalid created_at
 *   401  Invalid or missing X-Api-Key
 *   404  Product not found
 *   405  Non-POST method
 *   500  Server error (message in body)
 */

// Rating option ID mapping: rating_id => [1-star option_id, 2-star, 3-star, 4-star, 5-star]
// These map to the radio button values in the review form.
$RATING_MAP = array(
    '1' => array(1, 2, 3, 4, 5),       // Q1: Course meets expectation? values 1-5
    '2' => array(6, 7, 8, 9, 10),      // Q2: Trainer knowledgeable?    values 6-10
    '5' => array(21, 22, 23, 24, 25),  // Q3: Training environment?     values 21-25
);

// ── Request Handling ───────────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(array('error' => 'Method not allowed. Use POST.'));
    exit;
}

// ── Bootstrap Magento (needed to read the key from core_config_data) ──
require_once 'app/Mage.php';
// No store code arg — site has no "default" store; the website codes
// are base/admin/malaysia/ghana/... and Mage::app() defaults to the
// admin-side store, which is fine for API context.
Mage::app();

// Resolve the configured API key. Priority: DB (mmd_company/api/
// kael_review_key, set via admin Company Setting → API Summary) →
// env var KAEL_REVIEW_API_KEY → sentinel that nothing can match.
$apiSecretKey = (string) Mage::getStoreConfig('mmd_company/api/kael_review_key', 0);
if ($apiSecretKey === '') {
    $apiSecretKey = (string) (getenv('KAEL_REVIEW_API_KEY') ?: '');
}
if ($apiSecretKey === '') {
    $apiSecretKey = 'CHANGE_ME';
}

$apiKey = isset($_SERVER['HTTP_X_API_KEY']) ? $_SERVER['HTTP_X_API_KEY'] : '';
if (!hash_equals($apiSecretKey, $apiKey)) {
    http_response_code(401);
    echo json_encode(array('error' => 'Invalid API key'));
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
if (!$input) {
    http_response_code(400);
    echo json_encode(array('error' => 'Invalid JSON body'));
    exit;
}

$required = array('product_id', 'nickname', 'title', 'detail', 'ratings');
foreach ($required as $field) {
    if (!isset($input[$field]) || $input[$field] === '' || $input[$field] === array()) {
        http_response_code(400);
        echo json_encode(array('error' => "Missing required field: $field"));
        exit;
    }
}

$createdAtRaw = isset($input['created_at']) ? trim((string) $input['created_at']) : '';
$createdAtSql = '';
if ($createdAtRaw !== '') {
    $ts = strtotime($createdAtRaw);
    if ($ts === false) {
        http_response_code(400);
        echo json_encode(array('error' => "Invalid created_at: '$createdAtRaw'"));
        exit;
    }
    $createdAtSql = date('Y-m-d H:i:s', $ts);
}

try {
    $productId  = (int) $input['product_id'];
    $nickname   = trim($input['nickname']);
    $title      = trim($input['title']);
    $detail     = trim($input['detail']);
    $ratings    = $input['ratings'];
    $storeId    = isset($input['store_id']) ? (int) $input['store_id'] : (int) Mage::app()->getStore()->getId();
    $customerId = isset($input['customer_id']) && $input['customer_id'] !== '' ? (int) $input['customer_id'] : null;

    $product = Mage::getModel('catalog/product')->load($productId);
    if (!$product->getId()) {
        http_response_code(404);
        echo json_encode(array('error' => "Product ID $productId not found"));
        exit;
    }

    $review = Mage::getModel('review/review');
    $review->setEntityPkValue($productId);
    $review->setStatusId(Mage_Review_Model_Review::STATUS_APPROVED);
    $review->setTitle($title);
    $review->setDetail($detail);
    $review->setEntityId($review->getEntityIdByCode(Mage_Review_Model_Review::ENTITY_PRODUCT_CODE));
    $review->setStoreId($storeId);
    $review->setStores(array($storeId));
    $review->setCustomerId($customerId);
    $review->setNickname($nickname);
    $review->save();

    // Override created_at if supplied. Mage_Review_Model_Review::save() always
    // writes NOW() via the schema default, so we patch the row after the fact.
    // This is the canonical pattern for backfilling reviews with their original
    // timestamps (used by historical imports and batch backfills).
    if ($createdAtSql !== '') {
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $write->update(
            Mage::getSingleton('core/resource')->getTableName('review/review'),
            array('created_at' => $createdAtSql),
            array('review_id = ?' => (int) $review->getId())
        );
    }

    // Add rating votes
    foreach ($ratings as $ratingId => $starValue) {
        $ratingId  = (string) $ratingId;
        $starValue = (int) $starValue;

        if (!isset($RATING_MAP[$ratingId]) || $starValue < 1 || $starValue > 5) {
            continue;
        }

        $optionId = $RATING_MAP[$ratingId][$starValue - 1];
        Mage::getModel('rating/rating')
            ->setRatingId($ratingId)
            ->setReviewId($review->getId())
            ->addOptionVote($optionId, $productId);
    }

    $review->aggregate();

    header('Content-Type: application/json');
    echo json_encode(array(
        'success'    => true,
        'review_id'  => (int) $review->getId(),
        'created_at' => $createdAtSql !== '' ? $createdAtSql : date('Y-m-d H:i:s'),
        'store_id'   => $storeId,
        'message'    => 'Review created and approved',
    ));

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(array(
        'error'   => 'Failed to create review',
        'message' => $e->getMessage(),
    ));
}
