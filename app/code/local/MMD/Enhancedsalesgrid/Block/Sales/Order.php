<?php
class MMD_Enhancedsalesgrid_Block_Sales_Order extends Mage_Adminhtml_Block_Sales_Order
{
    public function __construct()
    {
        parent::__construct();

        $this->_blockGroup = 'enhancedsalesgrid';
        // Keep "Registrations" as the header text — sidebar-nav-v2.js's
        // wrapAdminGridInCard() reads the h3 text and EARLY-RETURNS if
        // it's empty, which would also kill the gray .dcf-mag-bar card
        // around the grid. The visible "Registrations" word is hidden
        // via CSS instead (body[...sales_order] .dcf-mag-bar > span:first-child).
        $this->_headerText = Mage::helper('sales')->__('Registrations');
        $this->_addButtonLabel = Mage::helper('sales')->__('Create New Registration');
    }

    /**
     * Inject a compact toolbar — Total Registrations + Search input +
     * Reset + Filters toggle — and relocate it via JS into the grid's
     * existing header strip (the gray bar that already shows
     * "Registrations" + "New Registration"). One consolidated row,
     * no separate cards above the grid.
     *
     * Branch pills are no longer rendered here — the global MMD_Branchscope
     * store_switcher block (injected via branchscope.xml's <default> handle)
     * provides them, reading ?store=N. Filtering is wired in
     * MMD_Enhancedsalesgrid_Model_Observer::salesOrderGridCollectionLoadBefore.
     */
    public function getGridHtml()
    {
        $req     = $this->getRequest();
        $baseUrl = $this->getUrl('*/*/index');
        $q       = (string) $req->getParam('q', '');

        /** @var MMD_Branchscope_Helper_Data $branch */
        $branch    = Mage::helper('branchscope');
        $activeStoreId = (int) $branch->getActiveStoreId();

        // Total registrations for the current store (no other filters).
        $totalCol = Mage::getResourceModel('sales/order_grid_collection');
        if ($activeStoreId > 0) {
            $totalCol->addFieldToFilter('store_id', $activeStoreId);
        }
        $total = $totalCol->getSize();

        $searchIcon = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" '
                    . 'stroke="currentColor" stroke-width="2">'
                    . '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>';

        // Build the consolidated toolbar in a hidden staging container.
        // A small inline script then moves it into the grid's page-header
        // strip so "Registrations" + "New Registration" share the row
        // with Total + Search + Filters.
        $html  = '<div class="mmd-reg-staging" style="display:none;">';
        $html .= '<span class="mmd-reg-total">' . Mage::helper('sales')->__('Total Registrations')
              .  ' <span>' . number_format($total) . '</span></span>';
        $html .= '<form method="get" action="' . $baseUrl . '" class="mmd-reg-search-form">';
        $html .= '<input type="hidden" name="store" value="' . (int) $activeStoreId . '" />';
        $html .= '<div class="mmd-reg-search-input-wrap">' . $searchIcon
              .  '<input type="text" name="q" class="mmd-reg-search-input" '
              .  'placeholder="' . Mage::helper('sales')->__('Search Reg #, learner name, email, or course') . '" '
              .  'value="' . $this->escapeHtml($q) . '" autocomplete="off" />'
              .  '</div>';
        $html .= '<a class="mmd-reg-reset" href="' . $baseUrl . '?store=' . (int) $activeStoreId . '">'
              .  Mage::helper('sales')->__('Reset') . '</a>';
        $html .= '<span class="mmd-reg-filter-slot"></span>';
        $html .= '</form>';
        $html .= '</div>';

        // Relocate the staged toolbar + the auto-injected filter toggle
        // into the .dcf-mag-bar that wrapAdminGridInCard() in
        // sidebar-nav-v2.js builds around the grid. The bar appears
        // AFTER our inline script runs (the wrap happens at DOM-ready),
        // so we keep observing the body until both exist, then move
        // the toolbar in between the title span (hidden via CSS) and
        // the form buttons (Add New / New Registration). Always
        // continue observing — don't disconnect on the first success
        // because the filter toggle is injected by buildFilterPanels()
        // even later than wrapAdminGridInCard().
        $html .= '<script>'
              .  '(function(){'
              .  '  function relocate(){'
              .  '    var staging = document.querySelector(".mmd-reg-staging");'
              .  '    if (!staging) return;'
              .  '    var bar = document.querySelector(".dcf-mag-bar");'
              .  '    if (!bar) return;'
              .  '    var toolbar = bar.querySelector(".mmd-reg-toolbar");'
              .  '    if (!toolbar) {'
              .  '      toolbar = document.createElement("div");'
              .  '      toolbar.className = "mmd-reg-toolbar";'
              .  '      while (staging.firstChild) toolbar.appendChild(staging.firstChild);'
              .  '      var actions = bar.querySelector(".mmd-auto-card-actions");'
              .  '      if (actions) {'
              .  '        bar.insertBefore(toolbar, actions);'
              .  '      } else {'
              .  '        bar.appendChild(toolbar);'
              .  '      }'
              .  '    }'
              .  '    var slot = toolbar.querySelector(".mmd-reg-filter-slot");'
              .  '    var toggle = document.querySelector(".advanced-filter-toggle");'
              .  '    if (slot && toggle && toggle.parentNode !== slot) slot.appendChild(toggle);'
              .  '  }'
              .  '  relocate();'
              .  '  var obs = new MutationObserver(function(){ relocate(); });'
              .  '  obs.observe(document.body, {childList:true, subtree:true});'
              .  '  setTimeout(function(){ obs.disconnect(); }, 15000);'
              .  '})();'
              .  '</script>';

        return $html . parent::getGridHtml();
    }
}
