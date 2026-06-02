#!/bin/bash
# One-shot cleanup of unused media folders on the Coolify volume.
#
# Reasons each folder is safe to remove:
#   media/dhl/             — shipping carrier never used (this is an LMS, no shipping)
#   media/downloadable/    — Magento downloadable-product module not active
#   media/providers/       — legacy training-provider image gallery, replaced
#   media/trainers/        — replaced by admin profile pictures
#   media/infortis/        — Ultimo theme demo assets (not referenced by live templates)
#   media/MagentoCaptcha/  — replaced by Cloudflare Turnstile
#   media/xmlconnect/      — Magento Mobile (XML API) — discontinued by Magento
#
# bankpayment/ removed too — payment/banktransferplus/active = false (verified
# disabled in core_config_data), so no new uploads; the existing files are
# customer payment proofs sitting in a publicly-served path, which is a data-
# protection issue the owner wants closed. Set KEEP_BANKPAYMENT=1 to retain.
#
# Gated by a sentinel so it runs once per Coolify volume; delete the sentinel
# to force re-run.
set -u

MEDIA=/var/www/html/media
MARKER=/var/www/html/var/.cleaned-unused-media-2026-06-02

if [ -f "$MARKER" ]; then
    echo "cleanup-unused-media: marker present, skipping"
    exit 0
fi

if [ ! -d "$MEDIA" ]; then
    echo "cleanup-unused-media: $MEDIA missing, skipping"
    exit 0
fi

# Folders to remove. Each line is checked individually so a missing folder
# doesn't break the whole sweep.
FOLDERS=(
    dhl
    downloadable
    providers
    trainers
    infortis
    MagentoCaptcha
    xmlconnect
)
if [ "${KEEP_BANKPAYMENT:-0}" != "1" ]; then
    FOLDERS+=(bankpayment)
fi

TOTAL_FREED=0
for f in "${FOLDERS[@]}"; do
    TARGET="$MEDIA/$f"
    if [ -d "$TARGET" ]; then
        SIZE=$(du -sk "$TARGET" 2>/dev/null | awk '{print $1}')
        echo "cleanup-unused-media: removing $TARGET (${SIZE}K)"
        rm -rf "$TARGET" && TOTAL_FREED=$((TOTAL_FREED + ${SIZE:-0}))
    fi
done

echo "cleanup-unused-media: total freed ~${TOTAL_FREED}K"

touch "$MARKER" && chown www-data:www-data "$MARKER" 2>/dev/null || true
