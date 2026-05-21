<?php

/**
 * MMD_CourseImage general helper.
 *
 * Reads R2 credentials from the environment (loaded into Apache by Docker /
 * Coolify). The .env in this repo defines R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY,
 * R2_ENDPOINT, R2_BUCKET, R2_PUBLIC_URL — those are the only ones the cover
 * renderer + uploader use.
 */
class MMD_CourseImage_Helper_Data extends Mage_Core_Helper_Abstract
{
    public const ASSET_DIR = 'app/code/local/MMD/CourseImage/assets';

    public function getModuleBase(): string
    {
        return Mage::getBaseDir() . DIRECTORY_SEPARATOR . self::ASSET_DIR;
    }

    public function getFontPath(): string
    {
        // Inter Bold — modern, neutral, professional. Used for the title and
        // the brand wordmark. Replaced DejaVu Sans Bold which read too generic.
        return $this->getModuleBase() . DIRECTORY_SEPARATOR . 'Inter-Bold.ttf';
    }

    public function getSemiBoldFontPath(): string
    {
        // Inter SemiBold — used for kickers and chip labels where Bold would
        // shout too loud against the dark gradient.
        return $this->getModuleBase() . DIRECTORY_SEPARATOR . 'Inter-SemiBold.ttf';
    }

    public function getTertiaryLogoPath(): string
    {
        // The "T mark" — circular blue badge only, no wordmark. The wordmark
        // is drawn in code (white "Tertiary Infotech Academy") so it can be
        // tuned for the dark-gradient background.
        return $this->getModuleBase() . DIRECTORY_SEPARATOR . 'tertiary-mark.png';
    }

    public function getWsqLogoPath(): string
    {
        return $this->getModuleBase() . DIRECTORY_SEPARATOR . 'wsq-logo.png';
    }

    /**
     * WSQ-funded course detection. Production SKU pattern is "TGS-..." for
     * SSG/WSQ-funded products — see commit f1439f014 (TGS-2024043854).
     */
    public function isWsqCourse(string $sku): bool
    {
        return stripos($sku, 'TGS-') === 0;
    }

    public function env(string $key, ?string $default = null): ?string
    {
        $val = getenv($key);
        if ($val !== false && $val !== '') {
            return $val;
        }
        return $default;
    }
}
