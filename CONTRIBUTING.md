# Contributing

Thanks for taking the time. Bug reports, ideas and pull requests are all welcome.

## Prerequisites

- macOS 15 or later
- Xcode 27 or later
- Swift 6

## Local setup

1. Clone this repository.
2. Open `ProxmoxBar.xcodeproj`. Swift Package Manager resolves Sparkle on first open.
3. Select the `ProxmoxBar` scheme and run with `Cmd+R`.

You need a reachable Proxmox VE server and an API token to exercise anything
beyond the welcome screen. The README explains how to create a restricted one.

## Before opening a pull request

Keep the change focused, then run what the CI runs:

```
xcrun swift-format lint --strict --recursive ProxmoxBar ProxmoxBarTests
xcodebuild -project ProxmoxBar.xcodeproj -scheme ProxmoxBar -destination 'platform=macOS' build test
```

Both must pass. `Cmd+U` in Xcode runs the same tests.

## Pull requests

- Base branch: `main`
- Say what changes and why, and how you checked it
- Screenshots or a short clip for anything visual
- No unrelated refactors in the same pull request

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org):
`feat:`, `fix:`, `refactor:`, `docs:`, `ci:`, `chore:`.

## Where things live

```
ProxmoxBar/
  MenuBar/     the panel: dashboard, pages, settings, server form
  Proxmox/     API client, models, certificate trust
  Storage/     servers, preferences, keychain
  Platform/    launch at login, updates, anything AppKit
  Welcome/     first run
ProxmoxBarTests/
```

## Conventions

- The codebase carries no comments. Names and small functions do the explaining;
  if a line needs a comment, it usually needs a better name instead.
- Views stay small and composable, and hold no networking.
- Anything that talks to Proxmox or to disk goes behind a protocol, so tests can
  supply a double instead of a live server.
- Persistence is a contract. Storage keys and the shape of what is written are
  read by versions already installed on people's machines; changing them strands
  their configuration.
- Keep workflows deterministic and non-interactive.
