<?php
class MMD_FeedbackForm_Adminhtml_ResponsesController extends Mage_Adminhtml_Controller_Action
{
    const PAGE_SIZE = 30;

    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/mmd/feedbackform/responses');
    }

    public function indexAction()
    {
        $this->loadLayout()
             ->_title($this->__('Feedback Form'))->_title($this->__('Responses'));
        $this->renderLayout();
    }

    /** GET JSON — paginated response list with optional search + date filters. */
    public function listAction()
    {
        try {
            $req      = $this->getRequest();
            $page     = max(1, (int)$req->getParam('page', 1));
            $q        = (string)$req->getParam('q', '');
            $from     = (string)$req->getParam('from', '');
            $to       = (string)$req->getParam('to', '');

            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');
            $tbl      = $resource->getTableName('mmd_feedback_form_response');

            $where = array('1=1');
            $bind  = array();
            if ($q !== '') {
                $like = '%' . $q . '%';
                $where[] = "(learner_name LIKE ? OR learner_email LIKE ? OR course_title LIKE ? OR course_sku LIKE ? OR class_id LIKE ? OR trainer_name LIKE ?)";
                $bind = array_merge($bind, array($like,$like,$like,$like,$like,$like));
            }
            if ($from) { $where[] = 'submitted_at >= ?'; $bind[] = $from . ' 00:00:00'; }
            if ($to)   { $where[] = 'submitted_at <= ?'; $bind[] = $to   . ' 23:59:59'; }

            $whereStr = implode(' AND ', $where);
            $total    = (int)$read->fetchOne("SELECT COUNT(*) FROM `$tbl` WHERE $whereStr", $bind);
            $offset   = ($page - 1) * self::PAGE_SIZE;
            $rows     = $read->fetchAll(
                "SELECT * FROM `$tbl` WHERE $whereStr ORDER BY submitted_at DESC LIMIT " . self::PAGE_SIZE . " OFFSET $offset",
                $bind
            );
            foreach ($rows as &$r) {
                $r['answers'] = json_decode($r['answers'], true) ?: array();
            }
            unset($r);

            $this->_jsonResponse(array(
                'success' => true,
                'total'   => $total,
                'pages'   => max(1, (int)ceil($total / self::PAGE_SIZE)),
                'page'    => $page,
                'rows'    => $rows,
            ));
        } catch (Exception $e) {
            $this->_jsonResponse(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /** POST — update a single response (learner_name, learner_email, answers). */
    public function updateAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            $body = json_decode($this->getRequest()->getRawBody(), true);
            $id   = (int)($body['response_id'] ?? 0);
            if (!$id) throw new Exception('response_id required');

            $allowed = array('learner_name', 'learner_email', 'answers');
            $update  = array();
            foreach ($allowed as $k) {
                if (isset($body[$k])) {
                    $update[$k] = ($k === 'answers') ? json_encode($body[$k]) : $body[$k];
                }
            }
            if (empty($update)) throw new Exception('Nothing to update');

            $resource = Mage::getSingleton('core/resource');
            $resource->getConnection('core_write')->update(
                $resource->getTableName('mmd_feedback_form_response'),
                $update,
                array('response_id = ?' => $id)
            );
            $this->_jsonResponse(array('success' => true));
        } catch (Exception $e) {
            $this->_jsonResponse(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /** POST — delete one or many responses. */
    public function deleteAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            $body = json_decode($this->getRequest()->getRawBody(), true);
            $ids  = array_filter(array_map('intval', (array)($body['ids'] ?? array())));
            if (empty($ids)) throw new Exception('No IDs provided');

            $resource = Mage::getSingleton('core/resource');
            $resource->getConnection('core_write')->delete(
                $resource->getTableName('mmd_feedback_form_response'),
                array('response_id IN (?)' => $ids)
            );
            $this->_jsonResponse(array('success' => true, 'deleted' => count($ids)));
        } catch (Exception $e) {
            $this->_jsonResponse(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    protected function _jsonResponse(array $data)
    {
        $this->getResponse()
             ->setHeader('Content-Type', 'application/json', true)
             ->setBody(json_encode($data));
    }
}
