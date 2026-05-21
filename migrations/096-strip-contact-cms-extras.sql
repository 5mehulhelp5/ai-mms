-- Strip Telegram, AI Chatbot, and Tertiary Courses GPT entries from the
-- per-store `contacts` CMS blocks (SG block_id 23, MY block_id 36).
-- The Contact Us page right-column information is rendered by this block;
-- these three rows are being retired in favour of the WhatsApp + email +
-- training-centre address rows that remain.
--
-- The stored content uses CRLF line endings, so the REPLACE target strings
-- below embed '\r\n' explicitly. Idempotent: REPLACE() on already-stripped
-- content is a no-op.

-- SG: Telegram
UPDATE cms_block
SET content = REPLACE(content,
'<div class="feature feature-icon-hover indent">\r\n<span class="icon" style="background-color: #fff;width:40px;height:40px;"><img src="https://www.tertiarycourses.com.sg/media/wysiwyg/telegram2.png"" alt="Tertiary Courses SG Telegram" width="50"/></span>\r\n<p class="no-margin "> <a href="https://t.me/TertiaryCoursesBot" target="_blank"><u>Telegram</u></a></p>\r\n</div>\r\n',
'')
WHERE identifier = 'contacts';

-- SG: AI Chatbot
UPDATE cms_block
SET content = REPLACE(content,
'<div class="feature feature-icon-hover indent">\r\n<span class="icon" style="background-color: #fff;width:40px;height:40px;"><img src="https://www.tertiarycourses.com.sg/media/wysiwyg/chatbot.png" alt="Tertiary Courses SG AI Chatbot" width="50"/></span>\r\n<p class="no-margin "> <a href="https://n8n.srv923061.hstgr.cloud/webhook/09398bc8-268a-4c14-83d9-0559f423e40b/chat" target="_blank"><u>AI Chatbot</u></a></p>\r\n</div>\r\n',
'')
WHERE identifier = 'contacts';

-- SG: Tertiary Courses GPT
UPDATE cms_block
SET content = REPLACE(content,
'<div class="feature feature-icon-hover indent">\r\n<span class="icon" style="background-color: #fff;width:40px;height:40px;"><img src="https://www.tertiarycourses.com.sg/media/wysiwyg/openai.png" alt="Tertiary Courses SG GPT" width="50"/></span>\r\n<p class="no-margin "> <a href="https://chat.openai.com/g/g-ewMTaVIbR-tertiary-courses-gpt" target="_blank"><u>Tertiary Courses GPT</u></a></p>\r\n</div>\r\n',
'')
WHERE identifier = 'contacts';

-- MY: AI Chatbot
UPDATE cms_block
SET content = REPLACE(content,
'<div class="feature feature-icon-hover indent">\r\n<span class="icon" style="background-color: #fff;width:40px;height:40px;"><img src="https://www.tertiarycourses.com.sg/media/wysiwyg/chatbot.png" alt="Tertiary Courses MY AI Chatbot" width="50"/></span>\r\n<p class="no-margin "> <a href="https://www.tertiarycourses.com.my/ai-chatbot-my.html" target="_blank"><u>AI Chatbot</u></a></p>\r\n</div>\r\n',
'')
WHERE identifier = 'contacts';

-- MY: Tertiary Courses MY GPT
UPDATE cms_block
SET content = REPLACE(content,
'<div class="feature feature-icon-hover indent">\r\n<span class="icon" style="background-color: #fff;width:40px;height:40px;"><img src="https://www.tertiarycourses.com.sg/media/wysiwyg/openai.png" alt="Tertiary Courses MY GPT" width="50"/></span>\r\n<p class="no-margin "> <a href="https://chatgpt.com/g/g-683fba1ab4948191b6e0472e3a9d51cd-tertiary-courses-my-gpt" target="_blank"><u>Tertiary Courses MY GPT</u></a></p>\r\n</div>\r\n',
'')
WHERE identifier = 'contacts';
