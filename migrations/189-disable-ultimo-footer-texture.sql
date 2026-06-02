-- 189-disable-ultimo-footer-texture.sql
--
-- The Ultimo theme footer was configured to tile a background texture from the
-- demo asset set: ultimo_design/footer/tex = 1  ->  rendered as
--   media/wysiwyg/infortis/ultimo/_patterns/default/1.png
--
-- That _patterns/ directory is Ultimo *demo* content (not a live brand asset) and
-- is being removed from the VPS media volume to reclaim space. With the texture
-- still enabled, the footer would issue a 404 for the missing pattern on every
-- page load. Disable the footer texture so the footer cleanly falls back to its
-- configured background colour. All other tex slots (page/header/main/footer.tex2)
-- are already 0.
--
-- Idempotent: no-op if the value is already 0 or the row is absent.

UPDATE core_config_data
   SET value = '0'
 WHERE path = 'ultimo_design/footer/tex'
   AND value = '1';
