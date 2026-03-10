# Architecture

## Goals

- Keep UI responsive and native to macOS.
- Keep feature code isolated and readable.
- Keep update behavior predictable.

## Runtime Layers

### App Layer (`Sources/App`)

- App bootstrap (`ProxmoxBarApp`)
- AppKit lifecycle (`AppDelegate`)
- Global app constants (`AppConfig`)

### Core Layer (`Sources/Core`)

- `Models`: domain objects and API DTOs.
- `Services`: networking, settings persistence, launch-at-login, updater.

### Feature Layer (`Sources/Features`)

- `MenuBar`: dashboard views and `ProxmoxViewModel`.
- `Settings`: settings panel, server form, reorder delegate.

### Shared Layer (`Sources/Shared`)

- AppKit bridge wrappers (`NSViewRepresentable` helpers).
- Reusable visual components.
- Shared style helpers (adaptive colors).

## Data Flow

1. `AppDelegate` creates `ProxmoxAppState`.
2. `ProxmoxAppState` builds `SettingsService` + `ProxmoxViewModel`.
3. `ProxmoxViewModel` polls `ProxmoxService`.
4. Views render published state and trigger actions.
5. Update checks are delegated to `UpdaterController`.

## Update Compatibility Guarantees

- `CFBundleIdentifier` remains `com.proxmoxbar.app`.
- Sparkle feed URL remains stable.
