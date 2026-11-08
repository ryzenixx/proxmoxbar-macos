# Privacy Policy

ProxmoxBar connects your Mac directly to the Proxmox VE servers you configure. The developer does not operate an intermediary service. The app has no account system, analytics or advertising.

## What the app stores

| Data | Where it is stored |
| --- | --- |
| Server addresses, names, token IDs, approved certificate fingerprints and app preferences | Local macOS preferences |
| API token secrets | macOS Keychain |
| The latest server names, status and usage summaries for widgets | A local App Group shared by ProxmoxBar and its widget extension |

## Network requests

ProxmoxBar sends the API token to the configured Proxmox VE server in the authorization header when it reads cluster data or sends a power command.

The direct-download edition uses Sparkle to check the public update feed and download releases from GitHub. App Store installations receive updates through the Mac App Store.

## Contact

For privacy questions, use the [project issue tracker](https://github.com/ryzenixx/proxmoxbar-macos/issues). For reports involving credentials or another security issue, use the [private reporting instructions](.github/SECURITY.md).

Last updated November 8, 2026.
