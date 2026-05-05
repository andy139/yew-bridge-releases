#!/bin/bash
#
# yew. terminal bridge: macOS installer
#
# Usage (paste this into Terminal):
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/andy139/yew-bridge-releases/main/install-mac.sh)"
#
# Downloads the latest signed-but-unnotarized .dmg, copies the app into
# /Applications, strips Gatekeeper's quarantine flag, ad-hoc re-signs the
# bundle (so the embedded sidecar doesn't fail strict validation on launch),
# and opens it. No Apple Developer ID required on the user's machine.

set -eu

REPO="andy139/yew-bridge-releases"
APP_NAME="Yew Terminal Bridge"
APP_DST="/Applications/${APP_NAME}.app"
SUPPORT_PHONE="415-606-0656"

printf '\n  yew. terminal bridge installer\n'
printf '  ------------------------------\n\n'

# Architecture sanity. The released .dmg is Apple Silicon only.
ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
  printf '  This installer ships an Apple Silicon build.\n'
  printf '  Your Mac reports: %s\n' "$ARCH"
  printf '  Call %s and we will get you set up.\n\n' "$SUPPORT_PHONE"
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

printf '  [1/8] stopping any running bridge processes...\n'
pkill -f "yew-agent" >/dev/null 2>&1 || true
pkill -f "yew-terminal-bridge" >/dev/null 2>&1 || true
# Give them a moment to release file handles on the bundle.
sleep 1

printf '  [2/8] cleaning up stale Yew Terminal Bridge volumes...\n'
for v in /Volumes/Yew\ Terminal\ Bridge*; do
  [ -d "$v" ] || continue
  hdiutil detach "$v" -force >/dev/null 2>&1 || true
done

printf '  [3/8] finding latest release...\n'
DMG_URL=$(
  curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
  | grep '"browser_download_url"' \
  | grep -iE 'macos.*\.dmg"' \
  | head -1 \
  | cut -d '"' -f 4
)

if [ -z "$DMG_URL" ]; then
  printf '  could not find a macOS .dmg in the latest release.\n'
  printf '  visit https://github.com/%s/releases or call %s.\n\n' "$REPO" "$SUPPORT_PHONE"
  exit 1
fi

DMG_PATH="${TMPDIR}/yew-bridge.dmg"
printf '  [4/8] downloading %s...\n' "$(basename "$DMG_URL")"
curl -fL --progress-bar "$DMG_URL" -o "$DMG_PATH"

printf '  [5/8] mounting installer...\n'
MOUNT_POINT=$(
  hdiutil attach "$DMG_PATH" -nobrowse -quiet \
  | grep -oE '/Volumes/.*' \
  | tail -1
)
if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT" ]; then
  printf '  failed to mount the installer.\n'
  printf '  call %s and we will help.\n\n' "$SUPPORT_PHONE"
  exit 1
fi

APP_SRC="${MOUNT_POINT}/${APP_NAME}.app"
if [ ! -d "$APP_SRC" ]; then
  printf '  app bundle missing inside the .dmg.\n'
  printf '  call %s and we will help.\n\n' "$SUPPORT_PHONE"
  exit 1
fi

printf '  [6/8] copying to /Applications...\n'
if [ -d "$APP_DST" ]; then
  if ! rm -rf "$APP_DST" 2>/dev/null; then
    printf '  could not remove the existing /Applications/%s.app.\n' "$APP_NAME"
    printf '  macOS App Management protection may be in the way.\n'
    printf '  open System Settings, Privacy and Security, App Management,\n'
    printf '  and enable Terminal. Then re-run this installer.\n'
    printf '  questions? %s\n\n' "$SUPPORT_PHONE"
    exit 1
  fi
fi
if ! cp -R "$APP_SRC" "$APP_DST"; then
  printf '  copy to /Applications failed.\n'
  printf '  call %s and we will help.\n\n' "$SUPPORT_PHONE"
  exit 1
fi

printf '  [7/8] clearing quarantine and re-signing locally...\n'
xattr -cr "$APP_DST" >/dev/null 2>&1 || true
codesign --force --deep --sign - "$APP_DST" >/dev/null 2>&1 || true

# Verify quarantine is gone. If anything is left, the sidecar will fail
# silently and the dashboard will show "Bridge isn't connected".
if xattr -lr "$APP_DST" 2>/dev/null | grep -q 'com.apple.quarantine'; then
  printf '  quarantine flag is still present after cleaning.\n'
  printf '  this is unusual. call %s.\n\n' "$SUPPORT_PHONE"
  exit 1
fi

printf '  [8/8] launching...\n'
open "$APP_DST"

printf '\n  done. yew. terminal bridge is in /Applications and starting now.\n'
printf '  questions? %s\n\n' "$SUPPORT_PHONE"
