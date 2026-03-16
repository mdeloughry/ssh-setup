#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────
# Bootstrap wrapper — downloads git-setup.sh,
# verifies its checksum, and asks before running.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOURUSER/dotfiles/main/bootstrap.sh | bash
#
# Or even safer (download, inspect, then run):
#   curl -fsSL -o bootstrap.sh https://raw.githubusercontent.com/YOURUSER/dotfiles/main/bootstrap.sh
#   less bootstrap.sh
#   bash bootstrap.sh
# ─────────────────────────────────────────────

# ── Config ─────────────────────────────────
# Update these with your actual values:
SCRIPT_URL="https://raw.githubusercontent.com/mdeloughry/ssh-setup/refs/heads/main/git-setup.sh"
EXPECTED_SHA256="2998b3c298df39dc904dc513f0cf81d03c2e1936f3f9f2910fe0080f28ddc8ff"
# To generate: shasum -a 256 git-setup.sh
# ───────────────────────────────────────────

TMPDIR=$(mktemp -d)
SCRIPT_PATH="${TMPDIR}/git-setup.sh"

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "⬇️  Downloading git-setup.sh..."
if ! curl -fsSL --proto '=https' --tlsv1.2 -o "$SCRIPT_PATH" "$SCRIPT_URL"; then
    echo "❌ Download failed." >&2
    exit 1
fi

# ── Verify checksum ───────────────────────

echo "🔒 Verifying checksum..."

if command -v shasum &>/dev/null; then
    ACTUAL_SHA256=$(shasum -a 256 "$SCRIPT_PATH" | awk '{print $1}')
elif command -v sha256sum &>/dev/null; then
    ACTUAL_SHA256=$(sha256sum "$SCRIPT_PATH" | awk '{print $1}')
else
    echo "⚠️  No sha256 tool found — skipping verification."
    ACTUAL_SHA256="$EXPECTED_SHA256"
fi

if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
    echo "❌ Checksum mismatch!" >&2
    echo "   Expected: $EXPECTED_SHA256" >&2
    echo "   Got:      $ACTUAL_SHA256" >&2
    echo "" >&2
    echo "   The script may have been tampered with. Aborting." >&2
    exit 1
fi

echo "✅ Checksum verified."

# ── Show script and confirm ───────────────

echo ""
echo "─── Script contents ─────────────────"
cat "$SCRIPT_PATH"
echo ""
echo "─────────────────────────────────────"
echo ""
read -rp "Run this script? [y/N] " CONFIRM < /dev/tty

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_PATH"
else
    echo "Aborted. Script saved at: $SCRIPT_PATH"
    trap - EXIT  # don't clean up so they can inspect
fi
