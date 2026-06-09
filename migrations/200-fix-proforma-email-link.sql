-- 200-fix-proforma-email-link.sql
--
-- Fix the broken "Download Pro Forma Invoice" link in the SG New Order email
-- (core_email_template id 2). The href carried a stray literal suffix
--   ...?orderID={{var order.increment_id}}92345393939298334
-- instead of the security token, so /pdf/ rejected every request (404).
--
-- Correct form expected by MMD_Proforma_IndexController:
--   ...?orderID={{var order.increment_id}}&token={{var order.protect_code}}
--
-- REPLACE() arguments are passed via UNHEX() so the {{ }} braces and the
-- backslash-free ampersand survive apply.php's semicolon splitter and MySQL's
-- string-escape handling untouched (repo convention, see migration history).
--
-- Idempotent: a second run finds the bad literal already gone and REPLACE() is
-- a no-op.

UPDATE core_email_template
SET template_text = REPLACE(
        template_text,
        -- {{var order.increment_id}}92345393939298334
        UNHEX('7B7B766172206F726465722E696E6372656D656E745F69647D7D3932333435333933393339323938333334'),
        -- {{var order.increment_id}}&token={{var order.protect_code}}
        UNHEX('7B7B766172206F726465722E696E6372656D656E745F69647D7D26746F6B656E3D7B7B766172206F726465722E70726F746563745F636F64657D7D')
    )
WHERE template_id = 2;
