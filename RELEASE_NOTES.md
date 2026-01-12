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
