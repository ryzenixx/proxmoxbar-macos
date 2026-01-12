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
