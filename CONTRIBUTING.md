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

Conventions live in the `docs/` vault so there is one copy of each rule:

- [Code Conventions](<docs/Code Conventions.md>) for Swift, concurrency, errors
  and logging.
- [Interface](docs/Interface.md) for views and AppKit bridges.
- [Quality](docs/Quality.md) for what "done" means and how to test.
- [Architecture](docs/Architecture.md) for where code belongs.

Two rules matter more than the rest:

- Keep behavior stable unless the PR explicitly changes it.
- Read [Data & Persistence](<docs/Data & Persistence.md>) before touching
  anything that is stored. Its keys and encoded shapes are a contract with
  every installed copy of the app.

A change that shapes the project durably needs an ADR. See
[ADR](<docs/ADR (Architecture Decision Records).md>).
