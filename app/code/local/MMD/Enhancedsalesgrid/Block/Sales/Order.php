<?php
class MMD_Enhancedsalesgrid_Block_Sales_Order extends Mage_Adminhtml_Block_Sales_Order
{
    public function __construct()
    {
        parent::__construct();

        $this->_blockGroup = 'enhancedsalesgrid';
        $this->_headerText = Mage::helper('sales')->__('Registrations');
        $this->_addButtonLabel = Mage::helper('sales')->__('Create New Registration');
    }

    /**
     * Inject the Registrations search card above the grid:
     *   - "Total Registrations N" heading (filtered by active store)
     *   - General Search input + Reset + Filters toggle
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

        $html  = '<div class="mmd-reg-wrap">';
        $html .= '<h2 class="mmd-reg-total">' . Mage::helper('sales')->__('Total Registrations')
              .  ' <span>' . number_format($total) . '</span></h2>';

        $html .= '<form method="get" action="' . $baseUrl . '" class="dev-search-wrap mmd-reg-search-form">';
        // Preserve active store in the search form so submitting search keeps the branch.
        $html .= '<input type="hidden" name="store" value="' . (int) $activeStoreId . '" />';
        $html .= '<div class="dev-search-label">' . Mage::helper('sales')->__('General Search') . '</div>';
        $html .= '<div class="dev-search-row">';
        $html .= '<div class="dev-search-input-wrap">' . $searchIcon
              .  '<input type="text" name="q" class="dev-search-input" '
              .  'placeholder="' . Mage::helper('sales')->__('Search Reg #, learner name, email, or course') . '" '
              .  'value="' . $this->escapeHtml($q) . '" autocomplete="off" />'
              .  '</div>';
        $html .= '<a class="mmd-reg-reset" href="' . $baseUrl . '?store=' . (int) $activeStoreId . '">'
              .  Mage::helper('sales')->__('Reset') . '</a>';
        $html .= '<span class="mmd-reg-filter-slot"></span>';
        $html .= '</div>';
        $html .= '</form>';

        // Relocate the auto-injected ".advanced-filter-toggle" (built by
        // sidebar-nav-v2.js → buildFilterPanels) from the top content-header
        // into our General Search row.
        $html .= '<script>'
              .  '(function(){'
              .  '  function move(){'
              .  '    var slot = document.querySelector(".mmd-reg-filter-slot");'
              .  '    var toggle = document.querySelector(".advanced-filter-toggle");'
              .  '    if (!slot || !toggle) return false;'
              .  '    if (toggle.parentNode === slot) return true;'
              .  '    slot.appendChild(toggle);'
              .  '    return true;'
              .  '  }'
              .  '  if (move()) return;'
              .  '  var obs = new MutationObserver(function(){ move(); });'
              .  '  obs.observe(document.body, {childList:true, subtree:true});'
              .  '  setTimeout(function(){ obs.disconnect(); }, 15000);'
              .  '})();'
              .  '</script>';

        $html .= '</div>';

        return $html . parent::getGridHtml();
    }
}
