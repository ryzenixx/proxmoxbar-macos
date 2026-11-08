# Contributing

Open an [issue](https://github.com/ryzenixx/proxmoxbar-macos/issues) for a bug or feature request. Report vulnerabilities through the [private security channel](.github/SECURITY.md).

## Build locally

Use Xcode 27 or later. Open `ProxmoxBar.xcodeproj`, select **ProxmoxBar** and run. The dashboard demo is available before a server is configured. For networking changes, use a development Proxmox VE server with a dedicated API token.

Run the formatter check and compile both variants before opening a pull request:

```sh
xcrun swift-format lint --strict --recursive ProxmoxBar ProxmoxBarWidget Shared

for scheme in ProxmoxBar 'ProxmoxBar MAS'; do
  xcodebuild -project ProxmoxBar.xcodeproj -scheme "$scheme" \
    -configuration Release -destination 'generic/platform=macOS' \
    CODE_SIGNING_ALLOWED=NO build
done
```

## Project layout

| Directory | Responsibility |
| --- | --- |
| `ProxmoxBar/App` | App entry point, lifecycle and dependency setup |
| `ProxmoxBar/MenuBar` | Panel, menu bar label and navigation |
| `ProxmoxBar/Features` | Dashboard, server setup, settings and welcome |
| `ProxmoxBar/Components` | Views reused across features |
| `ProxmoxBar/Proxmox` | API operations, HTTP transport, models and certificate trust |
| `ProxmoxBar/Monitoring` | Background polling, status changes and widget publishing |
| `ProxmoxBar/Persistence` | Server configuration, preferences and Keychain |
| `ProxmoxBar/System` | macOS integrations and Sparkle adapter |
| `ProxmoxBar/Resources` | App icons and asset catalog |
| `ProxmoxBarWidget` | Widget extension, configuration intent and timeline |
| `Shared/Components` | Usage meter and percentage formatting |
| `Shared/WidgetData` | Snapshot format and App Group storage |
| `Configuration` | Shared and target-specific build settings and Info.plist inputs |

Keep pull requests focused. Describe how you verified the change and include a screenshot for visible changes. Treat stored keys and payload formats as compatibility contracts for existing installations.
