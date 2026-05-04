#!/bin/bash
#
# yew. terminal bridge — macOS installer
#
# Usage (paste this into Terminal):
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/andy139/yew-bridge-releases/main/install-mac.sh)"
#
# Downloads the latest signed-but-unnotarized .dmg, copies the app into
# /Applications, strips Gatekeeper's quarantine flag, ad-hoc re-signs the
# bundle (so the embedded sidecar doesn't fail strict validation on launch),
# and opens it. No Apple Developer ID required on the user's machine.

set -e

REPO="andy139/yew-bridge-releases"
APP_NAME="Yew Terminal Bridge"
APP_DST="/Applications/${APP_NAME}.app"

printf '\n  yew. terminal bridge — installer\n'
printf '  --------------------------------\n\n'

# Architecture sanity. The released .dmg is Apple Silicon only.
ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
  printf '  This installer ships an Apple Silicon build.\n'
  printf '  Your Mac reports: %s\n' "$ARCH"
  printf '  Call 415-606-0656 and we will get you set up.\n\n'
  exit 1
fi

TMPDIR=$(mktemp -d -t yew-bridge)
MOUNT_POINT=""
cleanup() {
  if [ -n "$MOUNT_POINT" ] && [ -d "$MOUNT_POINT" ]; then
    hdiutil detach "$MOUNT_POINT" -quiet >/dev/null 2>&1 || true
  fi
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

printf '  [1/6] finding latest release...\n'
DMG_URL=$(
  curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
  | grep '"browser_download_url"' \
  | grep -iE 'macos.*\.dmg"' \
  | head -1 \
  | cut -d '"' -f 4
)

if [ -z "$DMG_URL" ]; then
  printf '  could not find a macOS .dmg in the latest release.\n'
  printf '  visit https://github.com/%s/releases or call 415-606-0656.\n\n' "$REPO"
  exit 1
fi

DMG_PATH="${TMPDIR}/yew-bridge.dmg"
printf '  [2/6] downloading %s...\n' "$(basename "$DMG_URL")"
curl -fL --progress-bar "$DMG_URL" -o "$DMG_PATH"

printf '  [3/6] mounting installer...\n'
MOUNT_POINT=$(
  hdiutil attach "$DMG_PATH" -nobrowse -quiet \
  | grep -oE '/Volumes/.*' \
  | tail -1
)
if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT" ]; then
  printf '  failed to mount the installer.\n\n'
  exit 1
fi

APP_SRC="${MOUNT_POINT}/${APP_NAME}.app"
if [ ! -d "$APP_SRC" ]; then
  printf '  app bundle missing inside the .dmg.\n\n'
  exit 1
fi

printf '  [4/6] copying to /Applications...\n'
if [ -d "$APP_DST" ]; then
  rm -rf "$APP_DST"
fi
cp -R "$APP_SRC" "$APP_DST"

printf '  [5/6] clearing quarantine and re-signing locally...\n'
xattr -cr "$APP_DST" >/dev/null 2>&1 || true
codesign --force --deep --sign - "$APP_DST" >/dev/null 2>&1 || true

printf '  [6/6] launching...\n'
open "$APP_DST"

printf '\n  done. yew. terminal bridge is in /Applications and starting now.\n'
printf '  questions? 415-606-0656\n\n'
