This page lists the technologies ProxmoxBar uses and the reason each one was
retained.

The version of record is always the project itself: the xcconfig files for build
settings, `Package.resolved` for dependencies. This page explains choices, not
versions.

---

## Language and platform

### Stack

- Swift, language mode 6, with approachable concurrency
- macOS 14 as the minimum version
- Xcode as the build system, with a local Swift package for the core

### Why

Swift 6 turns data race safety into a compile-time property. For an application
that mixes an actor, main-actor models and AppKit callbacks, that is worth more
than the migration cost.

Approachable concurrency is enabled; default main-actor isolation is not.
Isolation is written explicitly so a type's context is readable at its
declaration rather than inferred from a build setting, and so the app and the
package share one model. See
[ADR-0019](<ADR/0019 - Explicit MainActor over default isolation.md>).

The language mode is `6`. There is no 6.2 language mode: the valid values are 4,
4.2, 5 and 6, and the compiler version is a separate thing from the mode it
compiles in.

macOS 14 is what `SMAppService` and the Observation framework require without
conditional code. Raising the floor is a breaking change for users and is treated
as one. See [ADR-0012](<ADR/0012 - macOS 14 as the minimum version.md>).

Xcode is not a preference, it is a requirement: Swift Package Manager alone
cannot produce a signed, notarized `.app`. The core is a package anyway, because
a package is what makes the boundary real and the tests fast. See
[ADR-0011](<ADR/0011 - An Xcode project as the build system.md>) and
[ADR-0017](<ADR/0017 - A local package for the core, an Xcode project for the app.md>).

---

## Interface

### Stack

- SwiftUI for every view
- Observation for state
- AppKit for the application shell

### Why

SwiftUI describes the popover contents concisely and adapts to appearance changes
for free.

Observation replaces `ObservableObject` entirely. It tracks reads per property,
so a view is invalidated only by what it used — which is a correctness property
here, not only a performance one. It requires macOS 14, already the floor. See
[ADR-0018](<ADR/0018 - Observation instead of ObservableObject.md>).

SwiftUI does not give control over a menu bar item and a popover that must
survive a click inside a sheet; `MenuBarExtra` decides too much and constrains
the panel's size. So the shell is AppKit and the contents are SwiftUI, bridged by
`NSHostingController`. See
[ADR-0002](<ADR/0002 - An AppKit lifecycle behind a SwiftUI app.md>) and
[Interface](Interface.md).

Combine is not used. It was only ever imported to observe `objectWillChange`.

---

## Networking

### Stack

- `URLSession` from Foundation
- `Codable` for payloads

### Why

Three endpoints, JSON in and JSON out, no streaming, no websocket. A networking
library would add a dependency to save nothing.

Certificate evaluation is custom, through `SecTrust`, because per-server pinning
is not something `URLSession` does on its own. See
[ADR-0021](<ADR/0021 - Per-server certificate trust instead of accepting everything.md>)
and [Proxmox Integration](<Proxmox Integration.md>).

---

## Credential storage

### Stack

- The Security framework, data protection keychain

### Why

It is the only place on macOS a credential belongs, and Apple recommends the data
protection keychain over the file-based login keychain for new code. Whether a
non-sandboxed Developer ID app needs an entitlement for it is unverified and is
settled at implementation time, per
[ADR-0020](<ADR/0020 - Token secrets in the data protection keychain.md>).

No third-party keychain wrapper. The wrappers exist to hide a dictionary-building
API that this app touches in exactly one file. See
[ADR-0020](<ADR/0020 - Token secrets in the data protection keychain.md>).

---

## Updates

### Stack

- Sparkle

### Why

It is the standard for applications distributed outside the Mac App Store, it
verifies both the Apple code signature and an EdDSA signature over the archive,
and it handles the install-and-relaunch dance correctly.

The alternative, telling users to download a new DMG, does not get applied. See
[ADR-0005](<ADR/0005 - Sparkle for in-app updates.md>) and [Updates](Updates.md).

---

## System integration

### Stack

- `ServiceManagement` for launch at login
- `UserNotifications` for state change notifications
- `os.Logger` for logging

### Why

`SMAppService.mainApp` registers the application itself as a login item, with no
helper bundle to embed, sign and keep in sync.

`UserNotifications` requires a bundled application with an identifier, which is
why the notification code checks for one before touching the notification centre.

`os.Logger` redacts non-numeric interpolations by default, which is the behaviour
that keeps a token out of the system log. `print` writes to a console nobody is
attached to in a release build.

---

## Testing and style

### Stack

- Swift Testing
- `URLProtocol` stubs at the network edge
- `swift-format`

### Why

Swift Testing ships with the toolchain and is the default for new projects.
XCTest remains only where it has no replacement.

Stubbing at `URLProtocol` keeps the real session, the real request construction
and the real decoding under test, and substitutes only the bytes coming back. See
[ADR-0022](<ADR/0022 - Swift Testing with URLProtocol stubs at the network edge.md>).

`swift-format` is in the Swift 6 toolchain, so there is nothing to install
locally or in CI. SwiftLint is not adopted. See
[ADR-0023](<ADR/0023 - swift-format as the only style tool.md>).

---

## Build and release

### Stack

- GitHub Actions
- `xcodebuild`, `codesign`, `notarytool`, `hdiutil`
- Sparkle's `generate_appcast`

### Why

Every step is an Apple tool called from a small shell script, so the same command
can be run locally when a release fails. Nothing is hidden in a marketplace
action except certificate import.

See [Packaging](Packaging.md) and
[ADR-0015](<ADR/0015 - A tag-triggered release pipeline in isolated jobs.md>).

---

## What is deliberately absent

- No dependency injection framework. The composition root is one screen.
- No networking library, no JSON library, no keychain wrapper.
- No project generator. Synchronized folders and xcconfig cover it. See
  [ADR-0016](<ADR/0016 - Synchronized folders and xcconfig over a hand-listed project.md>).
- No analytics, no crash reporter, no telemetry of any kind.
- One runtime dependency: Sparkle.
