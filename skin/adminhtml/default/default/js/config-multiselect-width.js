/**
 * Force a uniform width on System > Configuration multi-select list
 * boxes (Allow Countries, Postal Code Optional, EU Countries, Weekend
 * Days, …).
 *
 * Why JS instead of CSS: this admin theme has a deep, conflicting
 * cascade (an ID-specificity `#config_edit_form select { max-width:100%
 * !important }` rule kept clamping every fixed-width CSS attempt back
 * down to each row's variable grid value-cell, so the boxes stayed
 * ragged). An inline style set with `setProperty(..., 'important')`
 * sits at the very top of the cascade and beats every author
 * stylesheet rule regardless of specificity — so this actually holds.
 *
 * Bulletproofed 2026-05-17: the concurrent Branchscope / side-col
 * refactor keeps re-rendering or restyling these selects after first
 * paint, which un-did the previous one-shot pin (it had a
 * `__cfgWidthPinned` guard that stopped re-application). Now the pin
 * is idempotent (no one-shot guard — re-setting the same inline
 * !important style is harmless), and re-applies via DOMContentLoaded,
 * MutationObserver on the form, a delegated click, AND a short
 * bounded interval to catch late async re-renders.
 *
 * Self-gating: no-ops unless a #config_edit_form is present.
 */
(function () {
    'use strict';

    var WIDTH = '620px';

    function pin(el) {
        if (!el) return;
        // Idempotent — always (re)assert. Only skip the (cheap) writes
        // if the inline width is already exactly ours, to avoid layout
        // thrash under the interval/observer.
        if (el.style.getPropertyValue('width') === WIDTH &&
            el.style.getPropertyPriority('width') === 'important') {
            return;
        }
        el.style.setProperty('width', WIDTH, 'important');
        el.style.setProperty('min-width', WIDTH, 'important');
        el.style.setProperty('max-width', WIDTH, 'important');
        el.style.setProperty('box-sizing', 'border-box', 'important');
        el.style.setProperty('display', 'block', 'important');
    }

    function applyAll() {
        var form = document.getElementById('config_edit_form');
        if (!form) return;
        var boxes = form.querySelectorAll('select[multiple], select.multiselect');
        for (var i = 0; i < boxes.length; i++) pin(boxes[i]);
    }

    function init() {
        var form = document.getElementById('config_edit_form');
        if (!form) return; // not the System Configuration page

        applyAll();

        // 1) Re-pin whenever the form subtree changes (section
        //    expand/collapse, async re-render by Magento/Branchscope JS).
        if (window.MutationObserver) {
            var obs = new MutationObserver(function () { applyAll(); });
            obs.observe(form, {
                childList: true, subtree: true, attributes: true,
                attributeFilter: ['style', 'class']
            });
        }
        // 2) Re-pin on any click inside the form (accordion toggles).
        form.addEventListener('click', function () {
            window.setTimeout(applyAll, 0);
            window.setTimeout(applyAll, 200);
        }, true);
        // 3) Bounded interval — catches late async re-renders that fire
        //    without a mutation we observe (e.g. another script swapping
        //    the node wholesale). Stops after 10s so it's not a
        //    permanent timer.
        var ticks = 0;
        var iv = window.setInterval(function () {
            applyAll();
            if (++ticks >= 20) window.clearInterval(iv); // 20 × 500ms = 10s
        }, 500);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
