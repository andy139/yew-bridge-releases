# yew-bridge-releases

Public download host for Yew Terminal Bridge installers.
Source lives in `andy139/yew-payments-app` (private).

## Install on macOS (Apple Silicon)

Paste this into Terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/andy139/yew-bridge-releases/main/install-mac.sh)"
```

The script downloads the latest `.dmg` from the [latest release](https://github.com/andy139/yew-bridge-releases/releases/latest), stops any running bridge, copies the app into `/Applications`, strips macOS Gatekeeper's quarantine flag, ad-hoc re-signs the bundle so the embedded `yew-agent` sidecar can launch, verifies the cleanup actually took, and opens the app.

Do **not** double-click the `.dmg` and drag the app to `/Applications` by hand. The drag is silent: the app appears installed, opens cleanly when you double-click it, and shows up in the dock. But Finder re-applies the quarantine flag during the drag, and Gatekeeper then refuses to let the Tauri shell exec the embedded `yew-agent` sidecar. The dashboard sits at "Bridge isn't connected" with no error dialog. The install script above is the supported path until the build is notarized.

## Install on Windows

Download the `.exe` setup or the portable `.zip` from the [latest release](https://github.com/andy139/yew-bridge-releases/releases/latest) and run it.

## Support

415-606-0656
