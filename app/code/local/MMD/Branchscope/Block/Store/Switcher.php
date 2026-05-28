<?php
/**
 * Rewrites Magento's native admin store-switcher dropdown as a horizontal
 * pill strip. Every adminhtml page that already includes the switcher in
 * its layout XML (catalog, sales, customer, cms, etc.) now gets pills
 * instead — no per-page wiring needed.
 *
 * Public API (getStoreId / getStores / getWebsites / etc.) is inherited
 * unchanged so any external caller that probes the block keeps working.
 * Only _toHtml() is overridden.
 */
class MMD_Branchscope_Block_Store_Switcher extends Mage_Adminhtml_Block_Store_Switcher
{
    /**
     * Render the pill strip in place of the native <select> dropdown.
     *
     * @return string
     */
    protected function _toHtml()
    {
        if (Mage::app()->isSingleStoreMode()) {
            return '';
        }

        // Roles that don't get a branch switcher:
        //  - learner / trainer: scoped to their own registration country.
        // Everyone else (developer, marketing, admin, super-admin) sees
        // the bar on store-scoped pages. NOTE: 'training_provider' is
        // the internal role code for Super Admin (see RoleManager
        // Helper/Data.php).
        $_activeRole = '';
        try {
            $_activeRole = (string) Mage::helper('mmd_rolemanager')->getActiveRoleCode();
            if (in_array($_activeRole, array('learner', 'trainer'), true)) {
                return '';
            }
        } catch (Exception $e) { /* role helper unavailable — render normally */ }
          catch (Error $e)     { /* same */ }

        /** @var MMD_Branchscope_Helper_Data $helper */
        $helper = Mage::helper('branchscope');

        // Admin (role_code 'admin') and Super Admin ('training_provider')
        // see the pill strip on EVERY standard Magento admin page so they
        // can flip the active store anywhere — bypass both the
        // store-scoped-route allow-list and the dashboard/category
        // suppressions. All other roles fall through to the original
        // store-scoped gating below.
        $isFullAdmin = in_array($_activeRole, array('admin', 'training_provider'), true);

        // The block is injected into the <default> layout handle so it
        // would otherwise render on every adminhtml page. Suppress on
        // non-store-scoped routes (Permissions, System → Cache, etc.).
        // Blocks placed explicitly by core layout XML (Catalog product
        // grid's nested store_switcher) still render — those callers
        // already opted in by including the block in their layout.
        if (!$isFullAdmin
            && $this->getNameInLayout() === 'mmd.branch.pills.global'
            && !$helper->isStoreScopedRoute()) {
            return '';
        }

        // Manage Categories (catalog_category): catalog is shared across
        // all countries, the per-store category tree fetch already keys
        // off the native store switcher, and the extra pill row on top
        // of the tree was creating visual noise. Suppress for non-admin
        // roles (admins keep it as a global navigation aid).
        //
        // Manage Courses (?panel=courses) USED to be suppressed here
        // because the panel rendered its own inline country-pill strip.
        // That inline strip has been retired — the global Store View bar
        // is now the canonical selector for the course list too — so we
        // let it render here.
        if ($this->getNameInLayout() === 'mmd.branch.pills.global') {
            $_req = Mage::app()->getRequest();
            // Edit Course / Editing Course page renders its own inline
            // Store View bar (template/dashboard/index.phtml — preserves
            // course_id / mode / dev_back across switches). Suppress the
            // global bar here to avoid two stacked switchers.
            if ($_req->getRouteName() === 'adminhtml'
                && $_req->getControllerName() === 'dashboard'
                && $_req->getParam('course_id')
                && in_array((string) $_req->getParam('mode'), array('edit', 'editing'), true)) {
                return '';
            }
            if (!$isFullAdmin
                && $_req->getRouteName() === 'adminhtml'
                && $_req->getControllerName() === 'catalog_category') {
                return '';
            }
        }

        // Same markup as Edit Course's inline Store View bar
        // (template/dashboard/index.phtml, .dcf-store-switcher) — same
        // class names so the page CSS (now hoisted to admin-dashboard.css)
        // styles both identically. 6-country pill set only (no "All", no
        // Infotech) to match the Edit Course design exactly.
        $activeId = (int) $helper->getActiveStoreId();
        $options  = $helper->getCountryStorePillOptions();

        $pills = '';
        $activeName = '';
        $activeCode = '';
        foreach ($options as $opt) {
            $url   = $helper->buildPillUrl($opt['id']);
            $isAct = ((int) $opt['id'] === $activeId);
            if ($isAct) {
                $activeName = $opt['name'];
                $activeCode = $opt['code'];
            }
            $pills .= '<a class="dcf-store-tab' . ($isAct ? ' is-active' : '') . '"'
                   .  ' href="' . $this->escapeHtml($url) . '"'
                   .  ' role="tab" aria-selected="' . ($isAct ? 'true' : 'false') . '"'
                   .  ' data-store-id="' . (int) $opt['id'] . '"'
                   .  ' title="Switch to ' . $this->escapeHtml($opt['name']) . ' store view">'
                   .  '<span class="dcf-store-tab-flag">' . $this->escapeHtml($opt['code']) . '</span>'
                   .  '<span class="dcf-store-tab-name">' . $this->escapeHtml($opt['name']) . '</span>'
                   .  '</a>';
        }

        $bar = '<div class="dcf-store-switcher mmd-branchscope-pills"'
            . ' role="tablist" aria-label="Store view">'
            . '<span class="dcf-store-switcher-label">Store View:</span>'
            . $pills
            . '<span class="dcf-store-switcher-hint"'
            . ' title="Global-scope fields (SKU, price, dates) save the same value across all stores regardless of which tab is active.'
            . ' Store-view fields (titles, meta, descriptions, design overrides) save to the active store only.">'
            . '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">'
            . '<circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/>'
            . '<line x1="12" y1="16" x2="12.01" y2="16"/></svg><span>Scope</span></span>'
            . '</div>';

        // "Editing for: <Country> XX" notice band — renders right under the
        // Store View bar on every store-scoped admin page so operators
        // always see which country's data they are looking at, regardless
        // of role (developer / marketing / admin / super admin). Same
        // visual treatment as the Edit Course inline notice; styles live
        // in admin-dashboard.css (.dcf-edit-notice / .dcf-active-store-pill).
        // Label: "Editing for" on record-edit / record-new pages, "Viewing"
        // on listing / grid / dashboard pages. Keeps the band honest —
        // operators on a list page aren't editing anything store-scoped.
        $req       = Mage::app()->getRequest();
        $actionN   = strtolower((string) $req->getActionName());
        $editActs  = array('edit', 'new', 'save', 'editpost', 'newpost');
        $isEditing = in_array($actionN, $editActs, true)
            || $req->getParam('course_id')
            || in_array((string) $req->getParam('mode'), array('edit', 'editing'), true);
        $label     = $isEditing ? 'Editing for:' : 'Viewing:';
        $leftCopy  = $isEditing
            ? 'You are in edit mode. Make your changes and click Save Changes.'
            : 'Switch country via the Store View tabs above to filter this page.';

        $notice = '';
        if ($activeName !== '') {
            $notice = '<div class="dcf-edit-notice mmd-branchscope-notice"'
                . ' style="display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap;margin-top:10px;">'
                . '<span style="display:inline-flex;align-items:center;gap:8px;">'
                . '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">'
                . '<path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>'
                . '<path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>'
                . $this->escapeHtml($leftCopy)
                . '</span>'
                . '<span class="dcf-active-store-pill"'
                . ' title="Store-view-scoped fields on this page apply to this country. Switch via the Store View tabs above.">'
                . '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">'
                . '<circle cx="12" cy="12" r="10"/><path d="M2 12h20"/>'
                . '<path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>'
                . $this->escapeHtml($label) . ' <strong>' . $this->escapeHtml($activeName) . '</strong>'
                . '<span class="dcf-active-store-code">' . $this->escapeHtml($activeCode) . '</span>'
                . '</span>'
                . '</div>';
        }

        return $bar . $notice;
    }
}
