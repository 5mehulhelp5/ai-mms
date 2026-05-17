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
 * Self-gating: no-ops unless a #config_edit_form is present. Re-applies
 * after section expand/collapse (Magento's Fieldset.toggleCollapse can
 * reveal selects that were display:none on load) via a MutationObserver
 * plus a delegated click handler.
 */
(function () {
    'use strict';

    var WIDTH = '620px';

    function pin(el) {
        if (!el || el.__cfgWidthPinned) return;
        el.style.setProperty('width', WIDTH, 'important');
        el.style.setProperty('min-width', WIDTH, 'important');
        el.style.setProperty('max-width', WIDTH, 'important');
        el.style.setProperty('box-sizing', 'border-box', 'important');
        el.style.setProperty('display', 'block', 'important');
        el.__cfgWidthPinned = true;
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

        // Sections collapsed on load reveal their selects later — re-pin
        // when the form subtree changes, and on any click inside it
        // (covers the accordion toggle without hooking Magento's JS).
        if (window.MutationObserver) {
            var obs = new MutationObserver(function () { applyAll(); });
            obs.observe(form, { childList: true, subtree: true, attributes: true,
                                 attributeFilter: ['style', 'class'] });
        }
        form.addEventListener('click', function () {
            // let the toggle finish, then re-pin
            window.setTimeout(applyAll, 0);
            window.setTimeout(applyAll, 200);
        }, true);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
