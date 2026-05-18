/**
 * Category edit — put the Reset / Save Category (and any other header)
 * buttons on the SAME horizontal row as the tab strip (General
 * Information / Display Settings / Custom Design / Menu / Category
 * Products), with the "<name> (ID: n)" heading left on its own row
 * above.
 *
 * Why JS: Magento renders the buttons inside `.content-header`
 * (a `<p class="content-buttons form-buttons">` next to the category
 * `<h3>`), while the tabs are a separate `<ul id="category_info_tabs">`
 * sibling. Two unrelated block siblings can't be reliably co-lined with
 * CSS alone, so wrap both into one flex row (#catActionsRow);
 * dark-theme.css styles it (tabs left, buttons right). Mirrors the
 * Order View #ovActionsRow approach.
 *
 * Idempotent and self-healing: re-asserts after the concurrent
 * sidebar-nav-v2.js / Branchscope re-renders via DOMContentLoaded, a
 * MutationObserver on the content column, and a short bounded interval.
 * Self-gating: no-ops unless this is the Category edit page.
 */
(function () {
    'use strict';

    function isCategoryEdit() {
        return /adminhtml-catalog-category/.test(document.body.className || '') ||
               (window.location.pathname || '').indexOf('/catalog_category') !== -1;
    }

    function arrange() {
        if (!isCategoryEdit()) return;

        var tabs = document.getElementById('category_info_tabs');
        if (!tabs) return;
        var btns = document.querySelector('.content-header .content-buttons') ||
                   document.querySelector('.content-header .form-buttons') ||
                   document.querySelector('#category-edit-container .content-buttons');
        if (!btns) return;

        var row = document.getElementById('catActionsRow');
        if (!row) {
            row = document.createElement('div');
            row.id = 'catActionsRow';
            // Insert where the tabs UL is so the category-name heading
            // (still in .content-header) stays on its own row above.
            tabs.parentNode.insertBefore(row, tabs);
        }
        if (tabs.parentNode !== row) row.appendChild(tabs);
        if (btns.parentNode !== row || btns.previousElementSibling !== tabs) {
            row.appendChild(btns); // buttons after the tabs
        }
    }

    function init() {
        if (!isCategoryEdit()) return;
        arrange();

        var host = document.getElementById('category-edit-container') ||
                   document.querySelector('.main-col-inner') ||
                   document.querySelector('.main-col') || document.body;
        if (window.MutationObserver && host) {
            var obs = new MutationObserver(function () { arrange(); });
            obs.observe(host, { childList: true, subtree: true });
        }
        var ticks = 0;
        var iv = window.setInterval(function () {
            arrange();
            if (++ticks >= 20) window.clearInterval(iv); // 20 × 500ms = 10s
        }, 500);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
