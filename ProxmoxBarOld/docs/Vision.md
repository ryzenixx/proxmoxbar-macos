## Why ProxmoxBar

Proxmox VE has a good web interface. It is also a browser tab you have to find,
authenticate against, and navigate, which is a lot of ceremony to answer "is that
container still running".

Homelab operators check their cluster constantly and act on it rarely. The web
interface is built for the rare case.

**ProxmoxBar puts the answer in the menu bar.** One click shows every node, VM,
container and datastore across every cluster you configured, and lets you start,
stop or restart any of them without leaving what you were doing.

---

## Principles

- **Read-mostly, act-occasionally.** The common case is a glance. The interface
  optimises for that, and keeps actions one click away rather than in front.
- **Native, not a wrapper.** SwiftUI and AppKit, a real menu bar item, a real
  popover. No embedded web view of the Proxmox interface.
- **Proxmox is the source of truth.** ProxmoxBar keeps no model of your cluster.
  It asks, renders, and forgets. Only your server list is persisted.
- **Your credentials stay yours.** No account, no telemetry, no server between
  you and your cluster. The app talks to your Proxmox host and to GitHub for
  updates, and to nothing else.
- **Honest about privilege.** An API token that can power a VM can also power it
  off. The app says so, and the documentation shows how to scope it down.
- **Open source, entirely.** MIT, no paid tier, no feature withheld.

---

## What ProxmoxBar refuses to be

- A replacement for the Proxmox web interface. It does not create VMs, edit
  hardware, manage backups or configure networking, and it will not.
- A monitoring product. It shows current usage, it does not store history.
- A cloud service that reaches your cluster on your behalf.
- A cross-platform app. It is a macOS menu bar app, and being one is the point.
