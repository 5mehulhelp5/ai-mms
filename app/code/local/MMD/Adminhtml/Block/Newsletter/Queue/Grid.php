<?php
/**
 * Newsletter Queue grid — wire ?store=N. Queue → queue_store map; the
 * collection's addStoreFilter takes a single id or array.
 */
class MMD_Adminhtml_Block_Newsletter_Queue_Grid extends Mage_Adminhtml_Block_Newsletter_Queue_Grid
{
    protected function _beforeLoadCollection()
    {
        parent::_beforeLoadCollection();
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        if ($storeId > 0 && $this->getCollection()
            && method_exists($this->getCollection(), 'addStoreFilter')) {
            $this->getCollection()->addStoreFilter(array($storeId));
        }
        return $this;
    }
}
