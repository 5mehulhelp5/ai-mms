-- Strip Telegram, AI Chatbot, and Tertiary Courses GPT entries from the
-- footer "Contact Us Information" CMS blocks (SG block_id 7, MY block_id 34).
-- These are the same three rows removed from the per-page contacts block in
-- migration 096, but the footer copy lives in a separate `block_footer_column5`
-- block with a slightly different markup (attrs on one line, span-with-underline
-- instead of <u>). Match strings below are the exact stored HTML.
--
-- Idempotent: REPLACE() on already-stripped content is a no-op.

-- SG footer: Telegram
UPDATE cms_block
SET content = REPLACE(content,
'<div class="feature feature-icon-hover indent"><span class="icon" style="background-color: #fff; width: 40px; height: 40px;"><img alt="Tertiary Courses SG Telegram" src="https://www.tertiarycourses.com.sg/media/wysiwyg/telegram2.png" width="50" /></span>\r\n<p class="no-margin "><a href="https://t.me/TertiaryCoursesBot" target="_blank"><span style="text-decoration: underline;">Telegram</span></a></p>\r\n</div>\r\n',
'')
WHERE identifier = 'block_footer_column5' AND title = 'Singapore Footer Row 1';

-- SG footer: AI Chatbot
UPDATE cms_block
SET content = REPLACE(content,
'<div class="feature feature-icon-hover indent"><span class="icon" style="background-color: #fff; width: 40px; height: 40px;"><img alt="Tertiary Courses SG AI Chatbot" src="https://www.tertiarycourses.com.sg/media/wysiwyg/chatbot.png" width="50" /></span>\r\n<p class="no-margin "><a href="https://n8n.srv923061.hstgr.cloud/webhook/09398bc8-268a-4c14-83d9-0559f423e40b/chat" target="_blank"><span style="text-decoration: underline;">AI Chatbot</span></a></p>\r\n</div>\r\n',
'')
WHERE identifier = 'block_footer_column5' AND title = 'Singapore Footer Row 1';

-- SG footer: Tertiary Courses SG GPT
UPDATE cms_block
SET content = REPLACE(content,
'<div class="feature feature-icon-hover indent"><span class="icon" style="background-color: #fff; width: 40px; height: 40px;"><img alt="Tertiary Courses SG GPT" src="https://www.tertiarycourses.com.sg/media/wysiwyg/openai.png" width="50" /></span>\r\n<p class="no-margin "><a href="https://chat.openai.com/g/g-ewMTaVIbR-tertiary-courses-sg-gpt" target="_blank"><span style="text-decoration: underline;">Tertiary Courses SG GPT</span></a></p>\r\n</div>\r\n',
'')
WHERE identifier = 'block_footer_column5' AND title = 'Singapore Footer Row 1';

-- MY footer: AI Chatbot
UPDATE cms_block
SET content = REPLACE(content,
'<div class="feature feature-icon-hover indent">\r\n<span class="icon" style="background-color: #fff;width:40px;height:40px;"><img src="https://www.tertiarycourses.com.sg/media/wysiwyg/chatbot.png" alt="Tertiary Courses MY AI Chatbot" width="50"/></span>\r\n<p class="no-margin "> <a href="https://www.tertiarycourses.com.my/ai-chatbot-my.html" target="_blank"><u>AI Chatbot</u></a></p>\r\n</div>\r\n',
'')
WHERE identifier = 'block_footer_column5' AND title = 'Malaysia Footer Row 1';

-- MY footer: Tertiary Courses MY GPT
UPDATE cms_block
SET content = REPLACE(content,
'<div class="feature feature-icon-hover indent">\r\n<span class="icon" style="background-color: #fff;width:40px;height:40px;"><img src="https://www.tertiarycourses.com.sg/media/wysiwyg/openai.png" alt="Tertiary Courses MY GPT" width="50"/></span>\r\n<p class="no-margin "> <a href="https://chatgpt.com/g/g-683fba1ab4948191b6e0472e3a9d51cd-tertiary-courses-my-gpt" target="_blank"><u>Tertiary Courses MY GPT</u></a></p>\r\n</div>\r\n',
'')
WHERE identifier = 'block_footer_column5' AND title = 'Malaysia Footer Row 1';
