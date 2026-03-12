# ProxmoxBar

Native macOS menu bar app for monitoring and controlling Proxmox VE resources.

[![macOS](https://img.shields.io/badge/platform-macOS%2014%2B-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.2-orange?style=for-the-badge&logo=swift&logoColor=white)](https://www.swift.org/)
[![Sparkle](https://img.shields.io/badge/Sparkle-2.9.0-blue?style=for-the-badge)](https://sparkle-project.org/)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

## Features

- Multi-server Proxmox configuration
- VM/LXC status, search, filtering, and quick actions
- Datacenter resource overview (CPU, memory, storage)
- Sparkle-based in-app updates

## Requirements

- macOS 14+
- Proxmox VE API token

## Install

1. Open the [latest release](https://github.com/ryzenixx/proxmoxbar-macos/releases/latest).
2. Download `ProxmoxBar.dmg`.
3. Drag `ProxmoxBar.app` to `/Applications`.
4. Launch ProxmoxBar.

## Permissions & Security

For better security, use the Principle of Least Privilege and create a restricted token for ProxmoxBar.

### 1. Create a Custom Role

Go to **Datacenter** -> **Permissions** -> **Roles** and click **Create**.

- Name: `ProxmoxBar`
- Privileges:
  - `Datastore.Audit` (View Storage)
  - `Pool.Audit` (View Pools and members)
  - `SDN.Audit` (View Network)
  - `Sys.Audit` (View Node stats)
  - `VM.Audit` (View VMs)
  - `VM.PowerMgmt` (Start/Stop/Reboot)

### 2. Create a User

Go to **Datacenter** -> **Permissions** -> **Users** -> **Add**.

- User name: `proxmoxbar`
- Realm: `Proxmox VE authentication server`
- Password: set a strong password (not used directly by the app)

### 3. Create an API Token

Go to **Datacenter** -> **Permissions** -> **API Tokens** -> **Add**.

- User: `proxmoxbar@pve`
- Token ID: `monitor` (or any name you prefer)
- Privilege Separation: unchecked
- Copy the token secret now (it is shown only once)

### 4. Assign Permissions

Go to **Datacenter** -> **Permissions** -> **Add** -> **User Permission**.

- Path: `/`
- User: `proxmoxbar`
- Role: `ProxmoxBar`
- Propagate: checked (applies to all VMs and nodes)

## Run from Source (Xcode)

1. Clone the repository.
2. Open `ProxmoxBar.xcodeproj` in Xcode.
3. Select the `ProxmoxBar` scheme.
4. Press `Cmd+R`.

## Development

Use Xcode for development and debugging.

Prerequisites:
- Xcode 26+

Commands:
- Build: `Cmd+B`
- Run: `Cmd+R`
- Tests: `Cmd+U`

## Project Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Contributing](CONTRIBUTING.md)

## License

MIT. See [LICENSE](LICENSE).
