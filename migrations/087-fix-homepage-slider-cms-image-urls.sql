-- Homepage slider images on the Infotech store were hardcoded to
-- https://www.tertiarycourses.com.sg/media/wysiwyg/... — files never
-- existed on that legacy host (HTTP 500) AND the cross-domain link is
-- the wrong shape for a multi-country deploy. Rewrite the two slider
-- CMS blocks to use Magento's {{media url='...'}} directive so the
-- URL resolves to whichever store the visitor is on.
--
-- Files still need to be present at media/wysiwyg/cybersec2.png and
-- media/wysiwyg/subsidies.png on the prod media volume (uploaded
-- separately via Coolify — media/ is gitignored and not baked into
-- the image).
--
-- Idempotent: the WHERE pins to the exact legacy URL so re-running
-- after the fix is a no-op.

UPDATE cms_block
SET content = '<a href="https://www.tertiaryinfotech.edu.sg/advanced-certificate-in-cyber-security.html"><img src="{{media url=''wysiwyg/cybersec2.png''}}" alt="Advanced Certificate in Cyber Security" /></a>'
WHERE identifier = 'block_slide1'
  AND content LIKE '%tertiarycourses.com.sg/media/wysiwyg/cybersec2.png%';

UPDATE cms_block
SET content = '<a href="https://www.tertiaryinfotech.edu.sg/wsq-ibf-skillsfuture-utap-funded-courses.html"><img src="{{media url=''wysiwyg/subsidies.png''}}" alt="WSQ IBF SkillsFuture Credit Courses in Singapore" /></a>'
WHERE identifier = 'block_slide3'
  AND content LIKE '%tertiarycourses.com.sg/media/wysiwyg/subsidies.png%';
