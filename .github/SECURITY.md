# Security Policy

ProxmoxBar holds an API token that can power your machines on and off, and it talks to a server on your own network. Security reports are welcome and taken seriously.

## Supported versions

| Version | Supported |
| ------- | --------- |
| 3.x     | Yes       |
| 2.x     | No        |
| < 2.0   | No        |

Only the latest 3.x release receives fixes. Version 3.0 requires macOS 15 or later; earlier versions of macOS are no longer served by the update feed.

## Reporting a vulnerability

Please **do not open a public issue**.

Use [private vulnerability reporting](https://github.com/ryzenixx/proxmoxbar-macos/security/advisories/new) instead: the Security tab of this repository, then *Report a vulnerability*. It keeps the report private until a fix ships, and it credits you on the advisory when it is published.

If you would rather not use GitHub, write to **hello@maelduret.com**.

Please include what you found, how to reproduce it, and the version shown at the bottom of the Settings page.

ProxmoxBar is maintained by one person in his spare time. Expect a first reply within a few days rather than a few hours, and a fix as soon as one can be written and released.

## What is worth reporting

These are the parts where a flaw would hurt most:

- **The API token.** It is stored in the macOS keychain and is never written elsewhere, never logged, and never sent anywhere but the Proxmox host it belongs to.
- **The TLS connection.** Certificates are validated; a self-signed one must be approved by the user, and its fingerprint is then pinned. A later change is refused rather than trusted silently.
- **The update channel.** Releases are signed with an EdDSA key, notarized by Apple, and delivered over HTTPS. Anything that could substitute an update is a serious finding.

Reports about Proxmox VE itself belong to the Proxmox project, not here.

## Out of scope

Findings that require an attacker to already have administrator access to your Mac, and anything about servers you choose to add yourself.
