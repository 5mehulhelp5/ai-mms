<?php
/**
 * Public (no-auth) frontend controller for trainer invitation responses.
 *
 * URL pattern: /trainer_invite/respond?token=<hex>&action=accept|decline
 *
 * No session or login required — the token is the authentication.
 * Renders a standalone HTML response page (no Magento layout, intentional)
 * so the email link works cleanly on any device without a login redirect.
 */
class MMD_RoleManager_TrainerInvitationController extends Mage_Core_Controller_Front_Action
{
    public function respondAction()
    {
        $token  = (string) $this->getRequest()->getParam('token', '');
        $action = (string) $this->getRequest()->getParam('action', '');

        if (strlen($token) < 16 || !in_array($action, array('accept', 'decline'), true)) {
            $this->_renderPage('invalid', 'Invalid Link', 'This invitation link is invalid or has expired.');
            return;
        }

        /** @var MMD_RoleManager_Model_TrainerInvitationService $svc */
        $svc = Mage::getModel('mmd_rolemanager/trainerInvitationService');

        if ($action === 'accept') {
            $result = $svc->handleAccept($token);
        } else {
            $result = $svc->handleDecline($token);
        }

        switch ($result['html']) {
            case 'accepted':
                $this->_renderPage('accepted', 'Invitation Accepted',
                    'Thank you! You have been confirmed as the trainer for this class. A confirmation email has been sent to you.');
                break;
            case 'already_accepted':
                $this->_renderPage('already', 'Already Accepted',
                    'You have already accepted this invitation.');
                break;
            case 'declined':
                $this->_renderPage('declined', 'Invitation Declined',
                    'Thank you for letting us know. We have noted your unavailability and a confirmation email has been sent to you.');
                break;
            case 'already_declined':
                $this->_renderPage('already', 'Already Declined',
                    'You have already declined this invitation.');
                break;
            case 'blocked':
                $this->_renderPage('blocked', 'Already Assigned',
                    'Another trainer has already been assigned to this class. No action is needed on your part.');
                break;
            case 'inactive':
                $this->_renderPage('invalid', 'Link No Longer Active',
                    'This invitation link is no longer active.');
                break;
            default:
                $this->_renderPage('invalid', 'Invalid Link',
                    htmlspecialchars($result['message']));
                break;
        }
    }

    protected function _renderPage($type, $heading, $message)
    {
        $colors = array(
            'accepted' => array('header' => '#14532d', 'accent' => '#4ade80'),
            'declined' => array('header' => '#450a0a', 'accent' => '#f87171'),
            'blocked'  => array('header' => '#1e293b', 'accent' => '#94a3b8'),
            'already'  => array('header' => '#1e293b', 'accent' => '#94a3b8'),
            'invalid'  => array('header' => '#450a0a', 'accent' => '#f87171'),
        );
        $c = isset($colors[$type]) ? $colors[$type] : $colors['invalid'];

        $this->getResponse()->clearHeaders()->setHeader('Content-Type', 'text/html; charset=UTF-8');
        $this->getResponse()->setBody('<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>' . htmlspecialchars($heading) . ' — Tertiary Courses</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{background:#0f172a;font-family:Arial,sans-serif;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px}
    .card{background:#1e2132;border-radius:12px;overflow:hidden;max-width:480px;width:100%}
    .card-header{background:' . $c['header'] . ';padding:20px 28px}
    .card-header p{color:' . $c['accent'] . ';font-size:12px;font-weight:700;letter-spacing:1px;text-transform:uppercase;margin:0}
    .card-body{padding:28px}
    h1{color:#e2e8f0;font-size:20px;margin-bottom:12px}
    p{color:#94a3b8;font-size:14px;line-height:1.6;margin-bottom:16px}
    .footer{padding:14px 28px;border-top:1px solid #1e293b}
    .footer p{color:#334155;font-size:11px;margin:0}
    .footer a{color:#60a5fa;text-decoration:none}
  </style>
</head>
<body>
  <div class="card">
    <div class="card-header"><p>Tertiary Courses — Trainer Invitation</p></div>
    <div class="card-body">
      <h1>' . htmlspecialchars($heading) . '</h1>
      <p>' . htmlspecialchars($message) . '</p>
      <p>You may close this window.</p>
    </div>
    <div class="footer">
      <p><a href="https://tertiarycourses.com.sg">tertiarycourses.com.sg</a></p>
    </div>
  </div>
</body>
</html>');
    }
}
