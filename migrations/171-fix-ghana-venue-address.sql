-- Fix Ghana venue address.
--
-- The cms_block `my_venue_address` is the per-store venue card that
-- the storefront product page renders inside the Course Information
-- panel, AND that the brochure controller reads to fill the Venue
-- section. Each store's row in cms_block_store carries that store's
-- own address — for MY (KL), NG (Lagos), BT (Thimphu), IN (Chennai)
-- this was set up correctly.
--
-- Ghana (store_id=3) was a copy-paste mistake: the block content was
-- seeded with the Malaysian "Kuala Lumpur + Penang" address instead
-- of Ghana's. Result: every Ghana course's storefront product page
-- AND every Ghana brochure (TGS-/M-prefix SKUs published on the Ghana
-- store) was advertising a Malaysian venue.
--
-- Replace with the address that pairs with the Ghana store's
-- general/store_information/address config:
--   "Tertiary Courses Ghana Company Ltd, North Legon, Greater Accra, Ghana"
--
-- Idempotent: re-running this is a no-op (the UPDATE just rewrites
-- the same value).

UPDATE cms_block cb
JOIN cms_block_store cbs ON cb.block_id = cbs.block_id
SET cb.content = '<b>Address:</b> Tertiary Courses Ghana Company Ltd, North Legon, Greater Accra, Ghana.'
WHERE cb.identifier = 'my_venue_address'
  AND cbs.store_id = 3;
