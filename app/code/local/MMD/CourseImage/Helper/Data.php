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

    /**
     * Master list of badge labels the AI cover renderer + chip checkboxes
     * support. Order here drives the order admins see them in the UI.
     */
    public function getAllBadges(): array
    {
        return [
            'WSQ',
            'SkillsFuture Credit',
            'PSEA',
            'UTAP',
            'IBF',
            'HRDF',
            'SFEC',
            'Absentee Payroll',
            'MCES',
        ];
    }

    /**
     * Per-website default-checked badges. The cover renderer is country-
     * neutral, but admins want country-appropriate funding badges pre-ticked
     * so the common case is one-click. Map keyed by website code (see
     * Mage::app()->getWebsites()): base = Singapore, malaysia = MY, others
     * default to none so we don't show SG-only funding hooks in NG/GH/IN.
     */
    public function getDefaultBadgesForWebsite(string $websiteCode): array
    {
        $map = [
            'base'     => ['WSQ', 'MCES', 'UTAP'],
            'malaysia' => ['HRDF'],
        ];
        return $map[$websiteCode] ?? [];
    }

    /**
     * Resolve default badges for a product based on the website it lives in.
     * Falls back to the SG defaults for the legacy WSQ shortcut so existing
     * callers that key off the SKU still behave sensibly.
     */
    public function getDefaultBadgesForProduct(Mage_Catalog_Model_Product $product): array
    {
        $websiteIds = $product->getWebsiteIds() ?: [];
        // Prefer the first website Magento returns; admins editing a course
        // are typically scoped to one country at a time.
        $code = '';
        if ($websiteIds) {
            try {
                $code = (string) Mage::app()->getWebsite((int) reset($websiteIds))->getCode();
            } catch (Throwable $e) {
                $code = '';
            }
        }
        return $this->getDefaultBadgesForWebsite($code);
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
