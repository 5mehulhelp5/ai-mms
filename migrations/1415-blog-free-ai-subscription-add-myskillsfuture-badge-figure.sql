-- 1415: Blog post 'free-ai-subscription-now-live-swda-eligible-courses' — add the
--       MySkillsFuture listing screenshot showing the "Free AI Subscription" label.
--
-- Applied LIVE on SG prod 2026-09-17 (blog content is data, not code, so the
-- shipped migration alone does NOT change an already-populated row). This file
-- exists so a rebuilt DB reproduces the same state.
--
-- Image: supplied by the admin, compressed to 1100px / q72 (72,329 bytes) before
-- upload — the "Free AI Subscription" pill and the TGS- course code stay legible.
-- Hosted on our R2 bucket at
--   blog/myskillsfuture-free-ai-subscription-badge-n8n.jpg
-- Placed directly after the "Our eligible courses" intro paragraph, where it is
-- visual proof of the claim the surrounding copy makes.
--
-- Idempotent: the UPDATE no-ops once the figure is present (LOCATE guard), so
-- re-running is safe and never inserts a second copy.
-- SG-only: partner sites have no such post; the url_key match makes it a no-op there.

UPDATE `mmd_blog_post`
   SET `content` = REPLACE(`content`, '<p>These nine WSQ courses qualify. All are SkillsFuture-funded, so the subscription sits on top of the subsidy you already receive &mdash; you are not trading one for the other.</p>', '<p>These nine WSQ courses qualify. All are SkillsFuture-funded, so the subscription sits on top of the subsidy you already receive &mdash; you are not trading one for the other.</p><figure class="mmd-blog-figure"><img src="https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/myskillsfuture-free-ai-subscription-badge-n8n.jpg" alt="MySkillsFuture course listing for WSQ Agentic AI Automation with n8n showing the Free AI Subscription label" width="1100" height="508" loading="lazy" /><figcaption>On MySkillsFuture, an eligible course carries the <em>Free AI Subscription</em> label &mdash; shown here on WSQ Agentic AI Automation with n8n (TGS-2023035977). Screenshot: MySkillsFuture.</figcaption></figure>'),
       `updated_at` = NOW()
 WHERE `url_key` = 'free-ai-subscription-now-live-swda-eligible-courses'
   AND LOCATE('mmd-blog-figure', `content`) = 0
   AND LOCATE('<p>These nine WSQ courses qualify. All are SkillsFuture-funded, so the subscription sits on top of the subsidy you already receive &mdash; you are not trading one for the other.</p>', `content`) > 0;
