-- Split the SG venue CMS block into two:
--   sg_venue_address              -> default Woodlands address (used by all courses)
--   sg_venue_address_hydroponics  -> MEOD Farm address (Neo Tiew Harvest Ln)
--
-- Storefront (rightData.phtml) picks the hydroponics block for the urban
-- farming with hydroponics course (SKU TGS-2025053916) and the default block
-- for everything else. The previous content carried both addresses with
-- "All courses except hydroponics courses:" / "Hydroponics courses:" labels
-- which read awkwardly on every product page — labels are dropped now that
-- the venue is picked per-product.
--
-- Idempotent: UPDATE sets absolute content; INSERT uses ON DUPLICATE KEY.

UPDATE cms_block
SET content = '<p>12 Woodlands Square #07-85/86/87 Woods Square Tower 1, Singapore 737715. 5 mins walk from Woodlands (NS9) MRT station.</p>\n<p>The venue is disabled-friendly.</p>'
WHERE identifier = 'sg_venue_address';

INSERT INTO cms_block (title, identifier, content, is_active, creation_time, update_time)
SELECT 'SG Venue Address - Hydroponics',
       'sg_venue_address_hydroponics',
       '<p>MEOD Farm 13 Neo Tiew Harvest Ln, Singapore 719838</p>',
       1, NOW(), NOW()
FROM dual
WHERE NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'sg_venue_address_hydroponics');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0
FROM cms_block b
WHERE b.identifier = 'sg_venue_address_hydroponics';
