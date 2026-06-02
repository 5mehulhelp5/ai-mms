<?php
/**
 * Render the 3 auto-newsletter designs against a fixed test course
 * and dump them as static HTML files under media/marketing/preview-*.
 *
 * Lets you eyeball all 3 styles side by side without firing the
 * cron + pushing to MailerLite three times.
 */

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

// Pick an enabled SG product with a clean name + url_key.
$r = Mage::getSingleton('core/resource')->getConnection('core_read');
$nameAttr   = 71;
$shortAttr  = (int) $r->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=4");
$urlKeyAttr = (int) $r->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=4");

$row = $r->fetchRow(
    "SELECT p.entity_id AS pid, p.sku,
            COALESCE(NULLIF(n1.value,''), n0.value, '') AS name,
            COALESCE(NULLIF(sd1.value,''), sd0.value, '') AS short_desc,
            COALESCE(NULLIF(uk1.value,''), uk0.value, '') AS url_key
       FROM catalog_product_entity p
       JOIN catalog_product_website pw ON pw.product_id = p.entity_id AND pw.website_id = 1
       LEFT JOIN catalog_product_entity_varchar n0 ON n0.entity_id=p.entity_id AND n0.attribute_id={$nameAttr} AND n0.store_id=0
       LEFT JOIN catalog_product_entity_varchar n1 ON n1.entity_id=p.entity_id AND n1.attribute_id={$nameAttr} AND n1.store_id=1
       LEFT JOIN catalog_product_entity_text sd0 ON sd0.entity_id=p.entity_id AND sd0.attribute_id={$shortAttr} AND sd0.store_id=0
       LEFT JOIN catalog_product_entity_text sd1 ON sd1.entity_id=p.entity_id AND sd1.attribute_id={$shortAttr} AND sd1.store_id=1
       LEFT JOIN catalog_product_entity_varchar uk0 ON uk0.entity_id=p.entity_id AND uk0.attribute_id={$urlKeyAttr} AND uk0.store_id=0
       LEFT JOIN catalog_product_entity_varchar uk1 ON uk1.entity_id=p.entity_id AND uk1.attribute_id={$urlKeyAttr} AND uk1.store_id=1
      WHERE p.sku NOT LIKE 'K%'
      LIMIT 1"
);
$course = array(
    'pid'        => (int) $row['pid'],
    'sku'        => (string) $row['sku'],
    'name'       => (string) $row['name'],
    'short_desc' => trim(strip_tags((string) $row['short_desc'])),
    'url_key'    => (string) $row['url_key'],
);

// Fixed copy so the only difference between previews is the design.
$copy = array(
    'subject'      => 'Course Spotlight: ' . $course['name'],
    'preview_text' => 'Featured this week — ' . $course['name'],
    'tagline'      => 'Looking to upskill in ' . $course['name'] . '? This course gives you the hands-on practice and certifications that move careers forward.',
    'bullets'      => array(
        'Master the core concepts through guided practice',
        'Apply real-world techniques you can use on day one',
        'Build a portfolio-ready project to demonstrate your skills',
        'Learn from instructors active in the industry',
    ),
    'cta'          => 'Register Now',
    'stubbed'      => true,
);

$cron = Mage::getModel('mmd_marketing/cron_autoNewsletter');
$ref  = new ReflectionMethod($cron, '_renderHtml');
$ref->setAccessible(true);

$outDir = Mage::getBaseDir('media') . '/marketing';
if (!is_dir($outDir)) mkdir($outDir, 0775, true);

$templates = array('course_promo', 'visual_showcase', 'editorial');
foreach ($templates as $t) {
    $html = $ref->invoke($cron, $course, $copy, $t);
    $path = $outDir . '/preview-' . $t . '.html';
    file_put_contents($path, $html);
    echo "wrote " . $path . " (" . strlen($html) . " bytes)\n";
}

echo "\nOpen in browser:\n";
foreach ($templates as $t) {
    echo "  http://localhost:8080/media/marketing/preview-" . $t . ".html\n";
}
echo "\nCourse used: pid=" . $course['pid'] . " sku=" . $course['sku'] . " name=" . $course['name'] . "\n";
