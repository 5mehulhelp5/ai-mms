-- 201-proforma-link-self-sponsored-only.sql
--
-- Show the "Download Pro Forma Invoice" block in the SG New Order email
-- (core_email_template id 2) ONLY for self-sponsored registrations.
-- Employer/company-sponsored registrations are billed by company invoice and
-- never use SkillsFuture Credit, so the whole "Self Sponsored - SkillsFuture
-- Credits Claim (SFC)" section (header + blurb + pro forma link) is gated.
--
-- The gate is the email-filter conditional {{if order.getIsSelfSponsored()}}
-- ... {{/if}}. getIsSelfSponsored() is provided by MMD_Proforma_Model_Order
-- (a sales/order rewrite) and reads the order's "Sponsorship" custom option.
--
-- Two REPLACE()s, both via UNHEX() so the {{ }} braces, ampersand and quotes
-- pass through apply.php's splitter and MySQL escaping untouched:
--   1. prepend {{if order.getIsSelfSponsored()}} before the SFC <h1>
--   2. append  {{/if}} after the Download Pro Forma Invoice link's </p>
--
-- Idempotent: the WHERE guard skips the row once the conditional is present,
-- so a re-run is a no-op and can't double-wrap.

UPDATE core_email_template
SET template_text = REPLACE(
        REPLACE(
            template_text,
            -- <h1 ...>Self Sponsored - SkillsFuture Credits Claim (SFC)</h1>
            UNHEX('3C6831207374796C653D22666F6E742D73697A653A313670783B22203E53656C662053706F6E736F726564202D20536B696C6C73467574757265204372656469747320436C61696D2028534643293C2F68313E'),
            -- {{if order.getIsSelfSponsored()}}<h1 ...>Self Sponsored ...</h1>
            UNHEX('7B7B6966206F726465722E676574497353656C6653706F6E736F72656428297D7D3C6831207374796C653D22666F6E742D73697A653A313670783B22203E53656C662053706F6E736F726564202D20536B696C6C73467574757265204372656469747320436C61696D2028534643293C2F68313E')
        ),
        -- <b>Download Pro Forma Invoice </b></a></p>
        UNHEX('3C623E446F776E6C6F61642050726F20466F726D6120496E766F696365203C2F623E3C2F613E3C2F703E'),
        -- <b>Download Pro Forma Invoice </b></a></p>{{/if}}
        UNHEX('3C623E446F776E6C6F61642050726F20466F726D6120496E766F696365203C2F623E3C2F613E3C2F703E7B7B2F69667D7D')
    )
WHERE template_id = 2
  AND template_text LIKE '%Download Pro Forma Invoice%'
  AND template_text NOT LIKE '%getIsSelfSponsored%';
