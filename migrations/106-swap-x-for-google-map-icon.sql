-- Swap the Twitter-X glyph that migration 105 introduced on the social-links
-- row that actually points at the country's Google Business Profile (Google
-- Maps URL) for a map-pin glyph -- same path used by the contact-location
-- icon in migration 098, so the navy square stays consistent.
--
-- Idempotent: REPLACE() on already-swapped content is a no-op.

UPDATE cms_block
SET content = REPLACE(content,
'<svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>',
'<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>')
WHERE identifier = 'block_footer_primary_bottom_left';
