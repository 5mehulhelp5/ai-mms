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
     * Inject a Manage-Courses-style filter UI above the grid:
     *   - Country/Branch pills (All / Singapore / Malaysia / …)
     *   - "Total Registrations N" heading
     *   - General Search card with text input, Reset, and Show Filters toggle
     *
     * The pills submit as ?branch=<store_id>, search as ?q=<text>; both are
     * read by MMD_Enhancedsalesgrid_Block_Sales_Order_Grid::_prepareCollection.
     * "Show Filters" toggles the grid's built-in <tr class="filter"> row.
     */
    public function getGridHtml()
    {
        $req      = $this->getRequest();
        $baseUrl  = $this->getUrl('*/*/index');
        $q        = (string) $req->getParam('q', '');
        $branchId = (string) $req->getParam('branch', '');

        // Build the branch pills from real stores, stripping " Store View".
        // Order = store_id ASC, which by design maps to the canonical
        // country order (1 SG, 2 MY, 3 GH, 4 NG, 5 BT, 6 IN, 7 Infotech).
        $pills = '';
        $pillItems = array(array('id' => '', 'name' => Mage::helper('sales')->__('All')));
        $storeCol = Mage::getModel('core/store')->getCollection()->setOrder('store_id', 'ASC');
        foreach ($storeCol as $_s) {
            if ((int) $_s->getId() === 0) { continue; } // skip admin
            $name = preg_replace('/\s*Store View\s*$/i', '', $_s->getName());
            $pillItems[] = array('id' => (int) $_s->getId(), 'name' => $name);
        }
        foreach ($pillItems as $p) {
            $url   = $baseUrl . ($p['id'] === '' ? '' : '?branch=' . $p['id']);
            $cls   = 'dev-country-btn' . ((string) $p['id'] === $branchId ? ' active' : '');
            $pills .= '<a href="' . $url . '" class="' . $cls . '">' . $this->escapeHtml($p['name']) . '</a>';
        }

        // Total registrations (current branch, no further filters)
        $totalCol = Mage::getResourceModel('sales/order_grid_collection');
        if ($branchId !== '') {
            $totalCol->addFieldToFilter('store_id', (int) $branchId);
        }
        $total = $totalCol->getSize();

        $searchIcon = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" '
                    . 'stroke="currentColor" stroke-width="2">'
                    . '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>';

        $branchHidden = $branchId !== ''
            ? '<input type="hidden" name="branch" value="' . $this->escapeHtml($branchId) . '" />'
            : '';

        $html  = '<div class="mmd-reg-wrap">';
        $html .= '<div class="dev-country-tabs">' . $pills . '</div>';
        $html .= '<h2 class="mmd-reg-total">' . Mage::helper('sales')->__('Total Registrations')
              .  ' <span>' . number_format($total) . '</span></h2>';

        $html .= '<form method="get" action="' . $baseUrl . '" class="dev-search-wrap mmd-reg-search-form">';
        $html .= $branchHidden;
        $html .= '<div class="dev-search-label">' . Mage::helper('sales')->__('General Search') . '</div>';
        $html .= '<div class="dev-search-row">';
        $html .= '<div class="dev-search-input-wrap">' . $searchIcon
              .  '<input type="text" name="q" class="dev-search-input" '
              .  'placeholder="' . Mage::helper('sales')->__('Search Reg #, learner name, email, or course') . '" '
              .  'value="' . $this->escapeHtml($q) . '" autocomplete="off" />'
              .  '</div>';
        $html .= '<a class="mmd-reg-reset" href="' . $baseUrl . '">' . Mage::helper('sales')->__('Reset') . '</a>';
        $html .= '<button type="button" class="mmd-reg-filter-toggle" onclick="mmdRegToggleFilters(this)">'
              .  Mage::helper('sales')->__('Show Filters') . '</button>';
        $html .= '</div>';
        $html .= '</form>';

        $html .= '<script>'
              .  '(function(){'
              .  '  window.mmdRegFiltersHidden = true;'
              .  '  function apply(){'
              .  '    var t = document.getElementById("sales_order_grid_table");'
              .  '    if(!t) return false;'
              .  '    t.classList.toggle("mmd-filters-hidden", window.mmdRegFiltersHidden);'
              .  '    var rows = t.querySelectorAll("tr.filter");'
              .  '    for (var i=0;i<rows.length;i++){ rows[i].style.removeProperty("display"); }'
              .  '    return true;'
              .  '  }'
              .  '  window.mmdRegToggleFilters = function(btn){'
              .  '    window.mmdRegFiltersHidden = !window.mmdRegFiltersHidden;'
              .  '    apply();'
              .  '    btn.textContent = window.mmdRegFiltersHidden ? "Show Filters" : "Hide Filters";'
              .  '    btn.classList.toggle("active", !window.mmdRegFiltersHidden);'
              .  '  };'
              .  '  if (apply()) return;'
              .  '  var obs = new MutationObserver(function(){ if (apply()) obs.disconnect(); });'
              .  '  obs.observe(document.body, {childList:true, subtree:true});'
              .  '  setTimeout(function(){ obs.disconnect(); }, 15000);'
              .  '})();'
              .  '</script>';

        $html .= '</div>';

        return $html . parent::getGridHtml();
    }
}
