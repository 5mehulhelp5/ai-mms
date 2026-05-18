/**
 * Course-editing page (catalog_product/edit) tools:
 *   • Collapse toggle for the left .side-col ("Course Information"
 *     tab list) — mirrors the main admin sidebar's collapse affordance.
 *   • Each form section (.entry-edit, header = .entry-edit-head)
 *     becomes collapsible by clicking its header.
 *
 * Styling lives in sidebar-nav.css (scoped to
 * body.adminhtml-catalog-product-edit). This script only wires
 * behaviour. Magento loads tab panels via AJAX, so new .entry-edit
 * blocks appear after tab switches — a MutationObserver re-applies.
 *
 * Self-gating (only on catalog_product/edit), idempotent, re-inits
 * after instant-nav PJAX swaps.
 */
(function () {
    'use strict';

    function isProductEdit() {
        return /adminhtml-catalog-product-edit/.test(document.body.className || '') ||
               (window.location.pathname || '').indexOf('/catalog_product/edit') !== -1;
    }

    function caret(cls) {
        var ns = 'http://www.w3.org/2000/svg';
        var s = document.createElementNS(ns, 'svg');
        s.setAttribute('viewBox', '0 0 24 24');
        s.setAttribute('width', '16'); s.setAttribute('height', '16');
        s.setAttribute('fill', 'none'); s.setAttribute('stroke', 'currentColor');
        s.setAttribute('stroke-width', '2'); s.setAttribute('class', cls);
        var p = document.createElementNS(ns, 'polyline');
        p.setAttribute('points', '6 9 12 15 18 9');
        s.appendChild(p);
        return s;
    }

    function wireSideCol() {
        var side = document.querySelector('.side-col');
        if (!side || side.querySelector('.cpe-sidecol-toggle')) return;
        var btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'cpe-sidecol-toggle';
        btn.appendChild(document.createTextNode('Collapse'));
        btn.appendChild(caret('cpe-sidecol-caret'));
        btn.addEventListener('click', function () {
            var collapsed = document.body.classList.toggle('cpe-sidecol-collapsed');
            btn.firstChild.nodeValue = collapsed ? 'Expand' : 'Collapse';
            var c = btn.querySelector('.cpe-sidecol-caret');
            if (c) c.style.transform = collapsed ? 'rotate(90deg)' : '';
            btn.style.justifyContent = collapsed ? 'center' : 'flex-end';
        });
        side.insertBefore(btn, side.firstChild);
    }

    function wireSections() {
        var secs = document.querySelectorAll('.entry-edit');
        for (var i = 0; i < secs.length; i++) {
            var sec = secs[i];
            if (sec.getAttribute('data-cpe')) continue;
            var head = sec.querySelector(':scope > .entry-edit-head');
            if (!head) continue;
            sec.setAttribute('data-cpe', '1');
            if (!head.querySelector('.cpe-caret')) head.appendChild(caret('cpe-caret'));
            head.addEventListener('click', function (e) {
                if (e.target.closest &&
                    e.target.closest('a,button,input,select,textarea,label')) return;
                this.parentNode.classList.toggle('cpe-collapsed');
            });
        }
    }

    // Course products have no inventory / recurring / gift concepts
    // (CLAUDE.md: virtual courses, no stock/shipping). Remove these
    // tabs + their content panels from the editor. Matched by label,
    // not tab id — Recurring Profile / Gift Options render as
    // attribute-group tabs (group_N) whose ids vary per product /
    // attribute set, so an id-based removeTab is unreliable.
    var DROP_TABS = { 'recurring profile': 1, 'gift options': 1, 'inventory': 1 };

    function removeUnwantedTabs() {
        var links = document.querySelectorAll(
            '.side-col ul.tabs li a, .side-col ul#product_info_tabs li a, ul.tabs.tabs-relocated li a');
        for (var i = 0; i < links.length; i++) {
            var a = links[i];
            var label = (a.getAttribute('title') || a.textContent || '')
                            .replace(/\s+/g, ' ').trim().toLowerCase();
            if (!DROP_TABS[label]) continue;
            var li = a.closest ? a.closest('li') : a.parentNode;
            if (li && !li.classList.contains('cpe-tab-hidden')) {
                li.classList.add('cpe-tab-hidden');
            }
            // Hide the matching content panel (id = <anchor id>_content).
            if (a.id) {
                var panel = document.getElementById(a.id + '_content');
                if (panel) panel.classList.add('cpe-tab-content-hidden');
            }
        }
    }

    function run() {
        if (!isProductEdit()) return;
        removeUnwantedTabs();
        wireSideCol();
        wireSections();
    }

    function init() {
        run();
        var host = document.querySelector('.main-col') ||
                   document.getElementById('anchor-content') || document.body;
        if (window.MutationObserver && host) {
            new MutationObserver(function () { run(); })
                .observe(host, { childList: true, subtree: true });
        }
        document.addEventListener('instant-nav:after-swap', run);
        var t = 0, iv = window.setInterval(function () {
            run(); if (++t >= 12) window.clearInterval(iv);
        }, 500);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
