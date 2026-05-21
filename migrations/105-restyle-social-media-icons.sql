-- Restyle the social-media icon badges in every country's social-links
-- CMS block (`block_footer_primary_bottom_left`) to the same 40x40 navy
-- rounded-square + inline-SVG glyph style used by migrations 098-104
-- for contact and footer icons.
--
-- All six storefronts use the same Ultimo `ib ib-hover ic ic-lg ic-*`
-- span markup, so a single REPLACE per platform covers them all:
--   2 SG, 43 MY, 63 GH, 68 NG, 80 BT, 96 IN.
-- The `ic-twitter` glyph is kept on the row that already links to a
-- Google Business profile -- the rebranding from Twitter to a maps icon
-- is a separate content decision, outside the scope of this restyle.
--
-- Idempotent: REPLACE() on already-restyled content is a no-op.

-- Facebook
UPDATE cms_block
SET content = REPLACE(content,
'<span class="ib ib-hover ic ic-lg ic-facebook"></span>',
'<span class="ib ib-hover ic ic-lg" style="display:inline-flex;align-items:center;justify-content:center;width:40px;height:40px;background:#1e3a8a;border-radius:8px;color:#fff;flex-shrink:0;"><svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z"/></svg></span>')
WHERE identifier = 'block_footer_primary_bottom_left';

-- LinkedIn
UPDATE cms_block
SET content = REPLACE(content,
'<span class="ib ib-hover ic ic-lg ic-linkedin"></span>',
'<span class="ib ib-hover ic ic-lg" style="display:inline-flex;align-items:center;justify-content:center;width:40px;height:40px;background:#1e3a8a;border-radius:8px;color:#fff;flex-shrink:0;"><svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.268 2.37 4.268 5.455v6.286zM5.337 7.433a2.062 2.062 0 0 1-2.063-2.065 2.063 2.063 0 1 1 2.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/></svg></span>')
WHERE identifier = 'block_footer_primary_bottom_left';

-- Twitter / X (kept on the Google-Business-link row to preserve existing UI)
UPDATE cms_block
SET content = REPLACE(content,
'<span class="ib ib-hover ic ic-lg ic-twitter"></span>',
'<span class="ib ib-hover ic ic-lg" style="display:inline-flex;align-items:center;justify-content:center;width:40px;height:40px;background:#1e3a8a;border-radius:8px;color:#fff;flex-shrink:0;"><svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg></span>')
WHERE identifier = 'block_footer_primary_bottom_left';

-- YouTube
UPDATE cms_block
SET content = REPLACE(content,
'<span class="ib ib-hover ic ic-lg ic-youtube"></span>',
'<span class="ib ib-hover ic ic-lg" style="display:inline-flex;align-items:center;justify-content:center;width:40px;height:40px;background:#1e3a8a;border-radius:8px;color:#fff;flex-shrink:0;"><svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/></svg></span>')
WHERE identifier = 'block_footer_primary_bottom_left';
