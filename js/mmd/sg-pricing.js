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

    var cfg = window.MMD_SG_PRICING;
    if (!cfg || !cfg.active) return;

    var sym  = cfg.currencySymbol || '$';
    var x    = parseFloat(cfg.catalogPrice) || 0;
    var rate = parseFloat(cfg.gstRate)      || 0.09;
    var map  = cfg.fundingMap                || {};

    if (x <= 0) return; // nothing to render

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

    function render() {
        var y     = activeDiscountPercent();
        var fee   = x * (1 - y / 100);
        var gst   = x * rate;
        var total = fee + gst;

        // GST-exclusive Fee — main number inside .price-box .regular-price
        var feeWrap = document.querySelector('.price-box .regular-price');
        if (feeWrap) {
            var feeInner = feeWrap.querySelector('.price') || feeWrap;
            feeInner.innerHTML = fmt(fee);
        }
        // GST-inclusive total
        var gtP = document.getElementById('gtP');
        if (gtP) gtP.innerHTML = fmt(total);

        // Hidden inputs kept in sync for any downstream JS still reading them
        var simple = document.getElementById('simpleProdPrice');
        if (simple) simple.value = fee.toFixed(4);
        var gstProd = document.getElementById('gstProdPrice');
        if (gstProd) gstProd.value = total.toFixed(2);
    }

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

    function attach() {
        // Use change events on the form so we cover radios, checkboxes,
        // and selects without per-input listeners.
        var form = document.getElementById('product_addtocart_form') || document;
        form.addEventListener('change', function () {
            // Defer past any other listener (e.g. Magento OptionsPrice)
            // that might also write into .price-box on the same event.
            setTimeout(render, 0);
        }, true);

        annotateBadges();
        // Defer initial render the same way, so it lands after Magento's
        // own DOMContentLoaded/window.load price update.
        setTimeout(render, 0);
        setTimeout(render, 100);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', attach);
    } else {
        attach();
    }
})();
