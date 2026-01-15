# Release 1.0.12

### Fixed
- **Settings Alerts**: Resolved an issue where the "Delete Server" confirmation and other alerts were not appearing correctly.
- **Popover Behavior**: Fixed the menu bar window not closing when clicking outside the application.
- **Documentation**: Clarified security model in README (Hardened Runtime support).

---

# Release 1.0.10

### Features
- **Intel Mac Support**: ProxmoxBar is now a **Universal Binary**!
  - It runs natively on both **Apple Silicon** and **Intel** based Macs.
  - The same application file works for everyone, no separate downloads needed.

---

# Release 1.0.8

### Features
- **Notifications (Beta)**: Stay informed about your resources with native macOS notifications.
  - **State Monitoring**: Get alerted immediately when a VM or LXC container starts or stops.
  - **Safety First**: This feature is currently in Beta and disabled by default. It includes a dedicated warning when enabling to ensure you are aware of the background monitoring involved.
  - **Visual Feedback**: A new settings toggle with a clear Beta badge helps distinguish this experimental feature.

---

# Release 1.0.7

### Features
- **Resource Sorting**: Added a new sort menu to organize your VMs and LXCs.
  - **Sort Options**: Choose between **ID** (default), **Name**, or **Status**.
  - **Smart Status Sort**: The "Status" option prioritizes running resources, keeping them at the top of the list for quick access.
  - **Persistence**: Your sort preference is saved automatically.

---

# Release 1.0.6

### Features
- **Server Management**:
  - **Edit Servers**: Added ability to edit existing server configurations (Host, Token, Secret) without deleting/recreating them.
  - **Reordering**: Implemented Drag & Drop to reorder your list of servers.
  - **Refined UI**: Preserved the custom "Card" design while adding native management features.

### Improvements
- **Settings UI**: Polished the Settings view by hiding scroll indicators and optimizing layout.
- **Form Behavior**: Fixed a flickering issue when opening the server editor; the form now loads instantly.

### Fixed
- **Stale Data**: Fixed a bug where data from the previous server would remain visible if the connection to the new server failed. The list is now properly cleared on error.

---

# Release 1.0.5

### Fixed
- **Dark Mode Detection**: Improved logic to robustly detect Dark Mode on all system configurations.
  - Previously, the app could incorrectly fallback to "Light Mode" colors (darker/forest tones) even when Dark Mode was active.
  - Now uses `NSAppearance.bestMatch` for 100% reliable detection, restoring the vibrant "neon" colors for Dark Mode users.

---

# Release 1.0.4

### Fixed
- **UI Contrast**: Fixed readability issue in Light Mode where usage statistics (CPU/RAM/Disk) appeared as white text on a light background. Changed to adaptive system colors for perfect contrast in both Light and Dark modes.
- **Light Mode Colors**: Adjusted Green/Red/Orange status colors to be less "neon" and more legible when using Light Mode, while retaining the vibrant look in Dark Mode.
- **Transparency**: Added a subtle background tint to improve legibility on colorful wallpapers while maintaining the frosted glass effect.
