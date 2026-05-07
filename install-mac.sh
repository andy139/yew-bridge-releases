#!/bin/bash
#
# Yew Bridge — macOS one-line installer.
#
# Usage (paste into Terminal):
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/andy139/yew-bridge-releases/main/install-mac.sh)"
#
# Downloads the latest installer zip, unpacks it to a tmpdir, and runs
# the bundled INSTALL.sh. INSTALL.sh handles:
#   - stripping macOS quarantine + ad-hoc resigning the .app
#   - installing Node.js (via brew if needed)
#   - copying 'Yew Bridge.app' into /Applications
#   - npm install of the daemon's deps
#   - registering the daemon under launchd (auto-start at login)
#   - opening the menubar app
#
# After ~60 seconds: menubar dot is up, daemon is running, ready to
# pair from the Yew dashboard.

set -eu

REPO="andy139/yew-bridge-releases"
SUPPORT_PHONE="415-606-0656"
ASSET_URL="https://github.com/${REPO}/releases/latest/download/Yew-Bridge-installer.zip"

printf '\n  Yew Bridge installer\n'
printf '  --------------------\n\n'

# Architecture sanity. The Swift menubar binary in the zip is Apple
# Silicon only.
ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
    printf '  This installer ships an Apple Silicon build.\n'
    printf '  Your Mac reports: %s\n' "$ARCH"
    printf '  Call %s if you need an Intel build.\n\n' "$SUPPORT_PHONE"
    exit 1
fi

# Working dir + auto-cleanup on exit.
TMPDIR=$(mktemp -d -t yew-bridge)
trap 'rm -rf "$TMPDIR"' EXIT

ZIP_PATH="${TMPDIR}/installer.zip"

printf '  → downloading installer (%s)\n' "$ASSET_URL"
if ! curl -fsSL "$ASSET_URL" -o "$ZIP_PATH"; then
    printf '\n  Couldn'\''t download the installer. Check your internet, then\n'
    printf '  call %s if it persists.\n\n' "$SUPPORT_PHONE"
    exit 1
fi

printf '  → unpacking\n'
unzip -q "$ZIP_PATH" -d "$TMPDIR"

# The zip contains an `installer/` directory with INSTALL.sh inside it.
INSTALLER_DIR="${TMPDIR}/installer"
if [ ! -f "${INSTALLER_DIR}/INSTALL.sh" ]; then
    printf '\n  Installer zip is malformed (missing INSTALL.sh).\n'
    printf '  Call %s.\n\n' "$SUPPORT_PHONE"
    exit 1
fi

printf '  → running installer\n\n'
chmod +x "${INSTALLER_DIR}/INSTALL.sh"
cd "$INSTALLER_DIR"
exec ./INSTALL.sh
