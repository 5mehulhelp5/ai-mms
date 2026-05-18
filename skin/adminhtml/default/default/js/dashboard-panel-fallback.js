/**
 * Dashboard panel fallback — guarantees the "Ongoing / Upcoming /
 * Completed Classes" views actually render.
 *
 * Those sidebar links open the dashboard with `?dash_filter=ongoing`
 * (resp. upcoming / completed) and no `?panel=`. The server renders the
 * full admin panel (#dash-panel-admin, "N Ongoing Classes Found",
 * table, …) but with `display:none`; the big inline panel-switcher
 * script is supposed to flip it visible via
 * showAdminSubPanel('admin', filter). The plain dashboard (no filter →
 * showPanel) works, but the `?dash_filter` code path leaves the panel
 * hidden, so the page looks completely blank.
 *
 * Rather than chase the regression through the ~12k-line concurrently
 * churned dashboard template, this acts as a deterministic net: when
 * the URL carries a known dash_filter and #dash-panel-admin exists but
 * is still hidden, force it visible (and hide the other top-level
 * dash panels, exactly like showAdminSubPanel would). It only ever
 * un-hides — never hides a panel the inline script correctly showed —
 * so it can't regress the working cases.
 *
 * Idempotent; re-runs on DOMContentLoaded, instant-nav PJAX swaps, and
 * a short bounded interval. Self-gating: no-ops off the dashboard or
 * without a dash_filter.
 */
(function () {
    'use strict';

    var FILTERS = { ongoing: 1, upcoming: 1, completed: 1 };

    function param(name) {
        try {
            return new URLSearchParams(window.location.search).get(name) || '';
        } catch (e) { return ''; }
    }

    function apply() {
        if ((window.location.pathname || '').indexOf('/dashboard') === -1) return;
        var filter = param('dash_filter');
        if (!FILTERS[filter]) return;            // only the class-time views
        if (param('panel')) return;              // a real ?panel= owns routing

        var target = document.getElementById('dash-panel-admin');
        if (!target) return;                     // nothing we can safely do

        var visible = target.style.display !== 'none' &&
                      getComputedStyle(target).display !== 'none';
        if (visible) return;                     // inline script already did it

        // Hide the other top-level role/sub panels, then reveal admin —
        // same hide/show contract as the inline showAdminSubPanel().
        var all = document.querySelectorAll('[id^="dash-panel-"]');
        for (var i = 0; i < all.length; i++) {
            if (all[i].id !== 'dash-panel-admin') all[i].style.display = 'none';
        }
        target.style.display = '';

        // Re-apply the time filter if the inline helper is ready.
        if (typeof window.applyDashTimeFilter === 'function') {
            try { window.applyDashTimeFilter(filter); } catch (e) {}
        }
    }

    function init() {
        apply();
        document.addEventListener('instant-nav:after-swap', apply);
        window.addEventListener('popstate', apply);
        var ticks = 0;
        var iv = window.setInterval(function () {
            apply();
            if (++ticks >= 12) window.clearInterval(iv); // 12 × 250ms = 3s
        }, 250);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
