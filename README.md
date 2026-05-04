# yew-bridge-releases

Public download host for Yew Terminal Bridge installers.
Source lives in `andy139/yew-payments-app` (private).

## Install on macOS (Apple Silicon)

Paste this into Terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/andy139/yew-bridge-releases/main/install-mac.sh)"
```

The script downloads the latest `.dmg` from the [latest release](https://github.com/andy139/yew-bridge-releases/releases/latest), copies the app into `/Applications`, strips macOS Gatekeeper's quarantine flag, and launches it.

If you double-click the `.dmg` directly, macOS will say the app "is damaged" because Yew is not yet enrolled in the Apple Developer Program. The install script above is the supported path until that is fixed.

## Install on Windows

Download the `.exe` setup or the portable `.zip` from the [latest release](https://github.com/andy139/yew-bridge-releases/releases/latest) and run it.

## Support

415-606-0656
