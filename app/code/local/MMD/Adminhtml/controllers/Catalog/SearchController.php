<?php
require_once Mage::getModuleDir('controllers', 'Mage_Adminhtml') . '/Catalog/SearchController.php';

/**
 * Preserves the listing's page / filter / search context across an
 * edit-save round trip on the Search Terms admin grid (catalog_search).
 *
 * The stock Mage_Adminhtml_Catalog_SearchController::saveAction always
 * redirects to the bare module/controller index — drops the user back
 * to /catalog_search/ with no params, losing any ?q=, ?page=,
 * ?filter=, ?store= they had set before clicking Edit.
 *
 * Snapshot strategy:
 *   1. `indexAction` writes the FULL request URI (path + query string)
 *      to the admin session under a per-controller key. Runs only on
 *      real full-page loads of the listing — AJAX filter / sort
 *      requests go through Mage_Adminhtml_Block_Widget_Grid's own
 *      `gridAction`, which we don't override, so they don't trash the
 *      snapshot.
 *   2. `saveAction` and `deleteAction` read that key and redirect to
 *      it instead of the bare index, then clear it.
 *
 * Why session (not a ?back= URL param threaded through the form):
 *   - Magento's edit/save form posts to a clean URL with no place to
 *     stash extra params without forking the edit-form block.
 *   - The edit page itself doesn't read query params reliably across
 *     the POST.
 *   - Session round-trip is one set + one get + one clear; no
 *     template changes needed.
 */
class MMD_Adminhtml_Catalog_SearchController
    extends Mage_Adminhtml_Catalog_SearchController
{
    /** Session key for the return URL — namespaced so other modules can't collide. */
    const RETURN_URL_KEY = 'mmd_catalog_search_return_url';

    public function indexAction()
    {
        // Stash the listing URL with all current params (q, store, page,
        // filter, sort, dir, etc.) so saveAction/deleteAction can come
        // back to the exact same view. RequestUri includes both the
        // path and the raw query string.
        try {
            $uri = (string) $this->getRequest()->getRequestUri();
            if ($uri !== '') {
                Mage::getSingleton('adminhtml/session')
                    ->setData(self::RETURN_URL_KEY, $uri);
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }
        parent::indexAction();
    }

    public function saveAction()
    {
        parent::saveAction();
        $this->_redirectToReturnUrl();
    }

    public function deleteAction()
    {
        parent::deleteAction();
        $this->_redirectToReturnUrl();
    }

    /**
     * Redirect resolution order:
     *   1. POST['back'] / GET['back']  — hidden field on the save form
     *      stamped by the JS injector on the edit page, originally
     *      coming from Grid::getRowUrl(). Per-request, immune to
     *      cross-tab races on the admin session.
     *   2. Session stash (RETURN_URL_KEY) — set by indexAction as a
     *      safety net for cases where a save somehow lands without
     *      `back` (older browser tabs, manual URL hits, etc.).
     *
     * Either way we only honor a target that points back at the
     * catalog_search controller — defense against an attacker
     * steering the save into an arbitrary URL.
     */
    protected function _redirectToReturnUrl()
    {
        $session = Mage::getSingleton('adminhtml/session');
        $return  = (string) $this->getRequest()->getParam('back', '');

        if ($return === '') {
            $return = (string) $session->getData(self::RETURN_URL_KEY);
        }

        if ($return === '') return;

        // Strip extra encoding layers. The frontend route to deleteAction
        // goes through Magento's setLocation() → encodeURI(), which
        // re-encodes `%` to `%25` — turning ?back=%2F... into
        // ?back=%252F.... PHP's URL parser only decodes one layer, so we
        // can land here with literal `%2F` still in the string. Decoding
        // those would produce a `Location: %2F...` header that the
        // browser treats as relative, dropping us at /catalog_search/
        // edit/<id>/%2F... — a 404. Loop until decoding is a no-op so
        // we always end with literal slashes.
        for ($i = 0; $i < 4; $i++) {
            $decoded = rawurldecode($return);
            if ($decoded === $return) break;
            $return = $decoded;
        }

        if (stripos($return, '/catalog_search') === false) {
            $session->unsetData(self::RETURN_URL_KEY);
            return;
        }

        $response = $this->getResponse();
        $response->clearHeader('Location');
        $response->setRedirect($return);

        $session->unsetData(self::RETURN_URL_KEY);
    }
}
