/**
 * Order View — put the action buttons (Back / Edit / Cancel / Send
 * Email / Hold / Invoice / Reorder) on the SAME horizontal row as the
 * detail tabs (Information / Invoices / Credit Memos / Comments
 * History / Transactions), with the "Order # … | <date>" heading left
 * on its own row above.
 *
 * Why JS: Magento renders the buttons inside `.content-header` (a
 * `<p class="form-buttons">` next to the order-# `<h3>`), while the
 * tabs are a separate `<ul id="sales_order_view_tabs">` that
 * sidebar-nav-v2.js (relocateOrderTabs) physically moves into
 * `.main-col-inner` after `.content-header`. They are two unrelated
 * block siblings, so CSS alone can't reliably co-line them. This wraps
 * both into one flex row (#ovActionsRow); dark-theme.css styles it
 * (tabs left, buttons right) and shrinks the tabs.
 *
 * Idempotent and self-healing: re-asserts after the concurrent
 * relocateOrderTabs / Branchscope re-renders via DOMContentLoaded, a
 * MutationObserver on the main column, and a short bounded interval.
 * Self-gating: no-ops unless this is the Order View page.
 */
(function () {
    'use strict';

    function isOrderView() {
        return document.documentElement.classList.contains('is-order-view') ||
               (window.location.pathname || '').indexOf('/sales_order/view/') !== -1;
    }

    function arrange() {
        if (!isOrderView()) return;

        var tabs = document.getElementById('sales_order_view_tabs');
        if (!tabs) return; // relocateOrderTabs hasn't run yet
        var btns = document.querySelector('.content-header .form-buttons') ||
                   document.querySelector('.content-header .content-buttons') ||
                   document.querySelector('.content-buttons');
        if (!btns) return;

        var row = document.getElementById('ovActionsRow');
        if (!row) {
            row = document.createElement('div');
            row.id = 'ovActionsRow';
            // Place the row exactly where the tabs UL currently sits so
            // the order-# heading (still in .content-header) stays above.
            tabs.parentNode.insertBefore(row, tabs);
        }
        // Idempotent moves — only touch the DOM if not already arranged
        // (tabs first, buttons second), to avoid layout thrash under the
        // observer/interval.
        if (tabs.parentNode !== row) row.appendChild(tabs);
        if (btns.parentNode !== row || btns.previousElementSibling !== tabs) {
            row.appendChild(btns); // ensure buttons come after the tabs
        }
    }

    function init() {
        if (!isOrderView()) return;
        arrange();

        var host = document.querySelector('.main-col-inner') ||
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
