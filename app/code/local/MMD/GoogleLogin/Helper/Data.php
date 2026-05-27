<?php
/**
 * Read Google OAuth2 credentials from environment variables (.env injected
 * into Apache via docker-compose). Never hard-code secrets. Returns empty
 * string when unset so the login template can hide the button gracefully.
 */
class MMD_GoogleLogin_Helper_Data extends Mage_Core_Helper_Abstract
{
    const ENV_CLIENT_ID     = 'GOOGLE_OAUTH_CLIENT_ID';
    const ENV_CLIENT_SECRET = 'GOOGLE_OAUTH_CLIENT_SECRET';

    public function getClientId()
    {
        return (string) getenv(self::ENV_CLIENT_ID);
    }

    public function getClientSecret()
    {
        return (string) getenv(self::ENV_CLIENT_SECRET);
    }

    public function isConfigured()
    {
        return $this->getClientId() !== '' && $this->getClientSecret() !== '';
    }

    /**
     * Redirect URI registered in Google Cloud Console must match this exactly.
     * Uses adminhtml URL builder so it picks up the right secure key and the
     * current admin frontName (tigerdragon).
     */
    public function getRedirectUri()
    {
        return Mage::helper('adminhtml')->getUrl(
            'adminhtml/googlelogin/callback',
            array('_nosecret' => true)
        );
    }

    public function getStartUrl()
    {
        return Mage::helper('adminhtml')->getUrl(
            'adminhtml/googlelogin/start',
            array('_nosecret' => true)
        );
    }

    /**
     * Find an active admin_user by email. Returns the loaded user or null.
     * Strict — never auto-creates an account.
     */
    public function findActiveAdminByEmail($email)
    {
        $email = trim((string) $email);
        if ($email === '') {
            return null;
        }
        /** @var Mage_Admin_Model_User $user */
        $user = Mage::getModel('admin/user')->loadByEmail($email);
        if (!$user || !$user->getId()) {
            return null;
        }
        if (!$user->getIsActive()) {
            return null;
        }
        return $user;
    }
}
