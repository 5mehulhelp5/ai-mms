/**
 * MMD_SingaporePrice — storefront pricing for SG product pages.
 *
 * Formula (the only thing this file does):
 *
 *     fee     = x * (1 - y/100)
 *     gst     = gstRate * x
 *     total   = fee + gst
 *
 * x = catalog price, y = funding-discount percent (matched by label),
 * gstRate = mmd_company/gst/rate (default 0.09). Reads its config
 * from window.MMD_SG_PRICING which the head template publishes only
 * on storeId 1 or 7.
 *
 * Design goals:
 *   - No coupling to MMD_CustomOptions's JS or opConfig — this file
 *     stands on its own, listens to native DOM events, and writes
 *     into the existing Ultimo .price-box markup.
 *   - All template hacks for SG can be deleted once this is verified;
 *     the file's behaviour does not depend on them.
 */
(function () {
    'use strict';

    // CRITICAL: do NOT read window.MMD_SG_PRICING here. The merged JS
    // bundle that contains this file is loaded in <head> BEFORE the
    // inline script that sets window.MMD_SG_PRICING. If we read cfg
    // at IIFE-evaluation time, it's undefined and we bail.
    //
    // Defer the cfg read into start(), which runs at DOMContentLoaded
    // by which point both the bundle and every inline <head> script
    // have executed.
    var cfg, sym, x, rate, map;

    function fmt(n) {
        return sym + (Math.round(n * 100) / 100).toFixed(2);
    }
    function normalise(s) {
        return (s || '').toString().toLowerCase().replace(/\s+/g, ' ').trim();
    }
    function discountForLabel(label) {
        var key = normalise(label);
        return parseFloat(map[key]) || 0;
    }
    function discountForRadio(radio) {
        if (!radio || !radio.checked) return 0;
        var lbl = document.querySelector('label[for="' + radio.id + '"]');
        return discountForLabel(lbl ? lbl.textContent : '');
    }

    /** Pick the largest funding discount among all checked radios. */
    function activeDiscountPercent() {
        var radios = document.querySelectorAll('input[type="radio"].product-custom-option');
        var best = 0;
        for (var i = 0; i < radios.length; i++) {
            var y = discountForRadio(radios[i]);
            if (y > best) best = y;
        }
        return best;
    }

    // render() exists for back-compat; everything routes through
    // safeRender() so the MutationObserver/re-entrancy guard applies
    // uniformly.

    function annotateBadges() {
        var radios = document.querySelectorAll('input[type="radio"].product-custom-option');
        for (var i = 0; i < radios.length; i++) {
            var r = radios[i];
            if (r.getAttribute('data-mmd-sg-annotated')) continue;
            var lbl = document.querySelector('label[for="' + r.id + '"]');
            if (!lbl) continue;
            var y = discountForLabel(lbl.textContent);
            if (y <= 0) continue;
            var badge = document.createElement('span');
            badge.className = 'mmd-sg-badge';
            badge.textContent = y + '% off';
            lbl.appendChild(badge);
            r.setAttribute('data-mmd-sg-annotated', '1');
        }
    }

    // Re-entrancy guard: setting innerHTML inside the MutationObserver
    // would fire the observer again. This lets us write once per real
    // change without looping.
    var _writing = false;
    var _lastWritten = null;

    function safeRender() {
        if (_writing) return;
        var y     = activeDiscountPercent();
        var fee   = x * (1 - y / 100);
        var gst   = x * rate;
        var total = fee + gst;
        var key   = fee.toFixed(2) + '|' + total.toFixed(2);
        if (key === _lastWritten) return;

        var feeWrap = document.querySelector('.price-box .regular-price');
        var feeInner = feeWrap ? (feeWrap.querySelector('.price') || feeWrap) : null;
        var gtP      = document.getElementById('gtP');
        var simple   = document.getElementById('simpleProdPrice');
        var gstProd  = document.getElementById('gstProdPrice');
        if (!feeInner) return;

        _writing = true;
        try {
            feeInner.innerHTML = fmt(fee);
            if (gtP)     gtP.innerHTML    = fmt(total);
            if (simple)  simple.value     = fee.toFixed(4);
            if (gstProd) gstProd.value    = total.toFixed(2);
            _lastWritten = key;
        } finally {
            // Defer release past synchronous observer callbacks.
            setTimeout(function(){ _writing = false; }, 0);
        }
    }

    function attach() {
        // 1. Native change events on the form cover radios + selects + checkboxes.
        var form = document.getElementById('product_addtocart_form') || document;
        form.addEventListener('change', function () {
            // Reset cache so we re-write even if computed value matches.
            _lastWritten = null;
            // Defer past Magento's synchronous reloadPrice chain.
            setTimeout(safeRender, 0);
            setTimeout(safeRender, 50);
            setTimeout(safeRender, 150);
        }, true);

        // 2. MutationObserver — Magento's OptionsPrice sometimes rewrites
        //    #product-price-<id> on its own schedule (window.load, dom:loaded,
        //    AJAX option reload, etc.). Watch the price text node and snap
        //    it back to our computed value whenever anything else mutates it.
        var feeWrap = document.querySelector('.price-box .regular-price');
        if (feeWrap && typeof MutationObserver !== 'undefined') {
            new MutationObserver(function(){
                _lastWritten = null;
                safeRender();
            }).observe(feeWrap, { childList: true, subtree: true, characterData: true });
        }

        annotateBadges();
        // Initial render passes — cover dom:loaded, window.load, and post-init.
        setTimeout(safeRender, 0);
        setTimeout(safeRender, 100);
        setTimeout(safeRender, 500);
    }

    function start() {
        cfg = window.MMD_SG_PRICING;
        if (!cfg || !cfg.active) return;
        sym  = cfg.currencySymbol || '$';
        x    = parseFloat(cfg.catalogPrice) || 0;
        rate = parseFloat(cfg.gstRate)      || 0.09;
        map  = cfg.fundingMap                || {};
        if (x <= 0) return;
        attach();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', start);
    } else {
        start();
    }
})();
