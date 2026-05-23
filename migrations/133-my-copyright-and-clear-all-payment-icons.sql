-- migration 133: footer tweaks
--   1. Rewrite MY website copyright to the new short form requested by ops.
--      Keeps the {{year}} token (Ultimo footer template substitutes date('Y')
--      at render time — see migration 129) so the year stays current next Jan
--      without another DB edit.
--   2. Clear footer payment-method icon blocks across ALL stores. The PayPal
--      / Mastercard / Visa images no longer reflect how the various stores
--      actually collect payment, so we drop them entirely rather than swap
--      the assets. Targeting by identifier covers SG/MY/GH/NG/BT/IN footers.

UPDATE core_config_data SET value = 'Copyright © {{year}}. Tertiary Infotech Sdn. Bhd. Company Registration #: 1187680-U .All Rights Reserved.' WHERE path = 'design/footer/copyright' AND scope = 'websites' AND scope_id = 2;

UPDATE cms_block SET content = '' WHERE identifier = 'block_footer_payment';
