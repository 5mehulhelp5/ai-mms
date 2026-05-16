-- Update Nigeria store footer address (CMS static block)
-- Replaces the "Visit Our Training Centers" address with the new office address.
-- Uses REPLACE + LIKE so the migration only touches the block containing the
-- old address. Safe to re-run (no-op on second pass).
UPDATE cms_block
SET content = REPLACE(
    content,
    'Visit Our Training Centers at : <br/>3/5 Esan Close, College Estate, Off Oko Oloyun Street, Off Isheri-Igando Expressway, Igando Lagos, Nigeria 100216.',
    'Office Address: <br/>No. 8 Ola-ifa Street, Bucknor Estate, Ejigbo, Lagos, Nigeria'
)
WHERE content LIKE '%3/5 Esan Close, College Estate%';
