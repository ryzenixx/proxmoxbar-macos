# Contributing

## Prerequisites

- macOS 14+
- Xcode 26+
- Swift 6.2+

## Local Setup

1. Clone this repository.
2. Open `ProxmoxBar.xcodeproj` in Xcode.
3. Select the `ProxmoxBar` scheme.
4. Run with `Cmd+R`.

## Before Opening a PR

1. Keep the change focused and scoped.
2. Build locally:
   - `xcodebuild -project ProxmoxBar.xcodeproj -scheme ProxmoxBar -configuration Debug -destination 'platform=macOS' build`
3. Run tests:
   - `xcodebuild -project ProxmoxBar.xcodeproj -scheme ProxmoxBar -configuration Debug -destination 'platform=macOS' test`
4. Include test notes in the PR description.

## Pull Request Guidelines

- Base branch: `develop`
- Provide a clear change summary
- Include screenshots for UI changes
- Avoid unrelated refactors in the same PR

## Project Conventions

- Keep behavior stable unless the PR explicitly changes it.
- Prefer small composable views over large files.
- Keep feature logic in `Sources/Features/*`.
- Keep shared services/models in `Sources/Core/*`.
- Keep workflows deterministic and non-interactive.

## Release Process

- Release workflow is triggered by pushing a semantic version tag (`vX.Y.Z`) that points to `main`.
- If needed, release can be rerun with the `Release` workflow `workflow_dispatch` input (`tag`).
