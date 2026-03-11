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
2. In Xcode:
   - Build with `Cmd+B`
   - Run tests with `Cmd+U`
3. Optional CLI equivalent:
   - `xcodebuild -project ProxmoxBar.xcodeproj -scheme ProxmoxBar -destination 'platform=macOS' build test`
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
