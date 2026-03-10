# Version 2.0.0

## Internal Refactor (No UI/Behavior Changes)

- Full source tree reorganization into `App`, `Core`, `Features`, and `Shared`.
- Large view files split into focused components:
  - Menu bar dashboard
  - Resource list / VM row
  - Storage list
  - Settings sections
- `ProxmoxViewModel` split into state/computed vs operation extensions.
- `ProxmoxService` refactored into clearer request/validation/decoding flow.

## Tooling and Packaging

- Build/package scripts were simplified and hardened.
- DMG packaging now uses native `hdiutil`.
- Signature checks now validate timestamp + hardened runtime on the main executable.

## Compatibility

- Bundle identifier unchanged (`com.proxmoxbar.app`).
- Sparkle feed URL unchanged.
- Update path preserved for existing installations.
