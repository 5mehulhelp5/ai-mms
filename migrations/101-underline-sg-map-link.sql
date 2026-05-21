-- Underline the Google Maps link in the SG Contact Us block. The Ultimo
-- theme strips underline from links by default, so the `Map: ...` URL was
-- rendering as plain text indistinguishable from prose.
--
-- Idempotent: REPLACE() on already-styled link is a no-op.

UPDATE cms_block
SET content = REPLACE(content,
'<a href="https://g.page/tertiarycourses-sg?share">https://g.page/tertiarycourses-sg?share</a>',
'<a href="https://g.page/tertiarycourses-sg?share" style="text-decoration:underline;">https://g.page/tertiarycourses-sg?share</a>')
WHERE block_id = 23;
