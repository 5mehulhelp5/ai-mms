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
        $q       = (string) $req->getParam('q', '');
        $rawBranch = $req->getParam('branch', null);

        // Default branch = Singapore (store_id 1) when no branch param is set.
        // Explicit "All" is signalled by ?branch=all.
        if ($rawBranch === null) {
            $branchId = '1';
        } elseif ((string) $rawBranch === 'all') {
            $branchId = '';
        } else {
            $branchId = (string) $rawBranch;
        }

        // Build the branch pills from real stores, stripping " Store View".
        // Order = store_id ASC, which by design maps to the canonical
        // country order (1 SG, 2 MY, 3 GH, 4 NG, 5 BT, 6 IN, 7 Infotech).
        $pills = '';
        $pillItems = array(array('id' => 'all', 'name' => Mage::helper('sales')->__('All')));
        $storeCol = Mage::getModel('core/store')->getCollection()->setOrder('store_id', 'ASC');
        foreach ($storeCol as $_s) {
            if ((int) $_s->getId() === 0) { continue; } // skip admin
            $name = preg_replace('/\s*Store View\s*$/i', '', $_s->getName());
            $pillItems[] = array('id' => (int) $_s->getId(), 'name' => $name);
        }
        foreach ($pillItems as $p) {
            $url = $baseUrl . '?branch=' . $p['id'];
            $isActive = ($p['id'] === 'all')
                ? ($branchId === '')
                : ((string) $p['id'] === $branchId);
            $cls = 'dev-country-btn' . ($isActive ? ' active' : '');
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

        $branchHidden = '<input type="hidden" name="branch" value="'
            . $this->escapeHtml($branchId !== '' ? $branchId : 'all') . '" />';

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
        $html .= '<span class="mmd-reg-filter-slot"></span>';
        $html .= '</div>';
        $html .= '</form>';

        // Relocate the auto-injected ".advanced-filter-toggle" (built by
        // sidebar-nav-v2.js → buildFilterPanels) from the top content-header
        // into our General Search row. Result: top shows only "New Registration";
        // the working Filters ▾ pill sits next to Reset on the search bar.
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
