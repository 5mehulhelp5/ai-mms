<?php
/**
 * Public (no-auth) frontend controller for trainer invitation responses.
 *
 * URL pattern: /trainer_invite/respond?token=<hex>&action=accept|decline
 *   frontName = trainer_invite (config.xml frontend router)
 *   controller = respond  -> this class
 *   action     = index    -> indexAction (the ?action= query param chooses
 *                            accept vs decline; it is NOT a path segment)
 *
 * No session or login required — the token is the authentication. Renders a
 * standalone HTML response page (no Magento layout) whose design + wording
 * mirror the AI-LMS-TMS trainer-invitation response pages.
 */
class MMD_RoleManager_RespondController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        $token  = (string) $this->getRequest()->getParam('token', '');
        $action = (string) $this->getRequest()->getParam('action', '');

        if (strlen($token) < 16 || !in_array($action, array('accept', 'decline'), true)) {
            $this->_render('Invalid Invitation', 'red', 'This invitation link is invalid or incomplete.');
            return;
        }

        // Trainer name + run label for the message copy (mirrors LMS).
        list($name, $runLabel) = $this->_context($token);
        $name = $name !== '' ? $name : 'there';

        /** @var MMD_RoleManager_Model_TrainerInvitationService $svc */
        $svc = Mage::getModel('mmd_rolemanager/trainerInvitationService');
        $result = ($action === 'accept') ? $svc->handleAccept($token) : $svc->handleDecline($token);

        switch ($result['html']) {
            case 'accepted':
                $this->_render('Invitation Accepted', 'green',
                    'Thank you, ' . $name . '! You have been assigned to course run ' . $runLabel . '. A confirmation email has been sent.');
                break;
            case 'declined':
                $this->_render('Invitation Declined', 'red',
                    'Thank you, ' . $name . ', for your response. The invitation for course run ' . $runLabel . ' has been declined. We will reach out to the next available trainer.');
                break;
            case 'already_accepted':
                $this->_render('Already Responded', 'slate',
                    'This invitation has already been accepted. ' . $name . ' is assigned to this class.');
                break;
            case 'already_declined':
                $this->_render('Already Responded', 'slate',
                    'This invitation was declined. The class may have been assigned to another trainer.');
                break;
            case 'blocked':
                $this->_render('Already Assigned', 'slate',
                    'Thank you for your response, ' . $name . '. Unfortunately, this class has already been assigned. We appreciate your willingness and will reach out for future opportunities.');
                break;
            case 'inactive':
                $this->_render('Invitation Not Found', 'red',
                    'This trainer invitation could not be found or may have expired.');
                break;
            default:
                $this->_render('Invitation Not Found', 'red',
                    'This trainer invitation could not be found or may have expired.');
                break;
        }
    }

    /** Returns [trainerName, runLabel] for the token (runLabel = class_id). */
    protected function _context($token)
    {
        try {
            $res  = Mage::getSingleton('core/resource');
            $read = $res->getConnection('core_read');
            $inv  = $read->fetchRow(
                "SELECT trainer_name, run_id FROM " . $res->getTableName('course_run_trainer_invitations') . " WHERE token = ? LIMIT 1",
                array($token)
            );
            if (!$inv) return array('', 'this class');
            $classId = (string) $read->fetchOne(
                "SELECT class_id FROM " . $res->getTableName('course_runs') . " WHERE run_id = ?",
                array((int)$inv['run_id'])
            );
            return array(trim((string)$inv['trainer_name']), $classId !== '' ? $classId : 'this class');
        } catch (Exception $e) {
            return array('', 'this class');
        }
    }

    /**
     * Render the LMS-style response page: dark body, slate card, pill badge.
     * $tone: green | red | slate.
     */
    protected function _render($title, $tone, $message)
    {
        $badge = array(
            'green' => array('bg' => '#dcfce7', 'text' => '#166534'),
            'red'   => array('bg' => '#fee2e2', 'text' => '#991b1b'),
            'slate' => array('bg' => '#e2e8f0', 'text' => '#334155'),
        );
        $b = isset($badge[$tone]) ? $badge[$tone] : $badge['slate'];
        $e = function($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); };

        $this->getResponse()->clearHeaders()->setHeader('Content-Type', 'text/html; charset=UTF-8');
        $this->getResponse()->setBody(
            '<!doctype html><html><head><meta charset="utf-8" />'
          . '<meta name="viewport" content="width=device-width, initial-scale=1" />'
          . '<title>' . $e($title) . '</title></head>'
          . '<body style="margin:0;font-family:Arial,sans-serif;background:#0f172a;color:#e2e8f0;display:flex;align-items:center;justify-content:center;min-height:100vh;padding:24px;">'
          . '<div style="max-width:560px;width:100%;background:#1e293b;border-radius:16px;padding:32px;box-shadow:0 20px 50px rgba(15,23,42,0.45);">'
          . '<div style="display:inline-block;padding:8px 12px;border-radius:999px;background:' . $b['bg'] . ';color:' . $b['text'] . ';font-weight:700;margin-bottom:16px;">' . $e($title) . '</div>'
          . '<p style="margin:0;font-size:16px;line-height:1.6;color:#cbd5e1;">' . $e($message) . '</p>'
          . '</div></body></html>'
        );
    }
}
