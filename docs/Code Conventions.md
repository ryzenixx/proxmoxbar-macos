This page describes the conventions that apply to every Swift file in
ProxmoxBar.

Conventions specific to views are in [Interface](Interface.md). Where code
belongs is in [Architecture](Architecture.md).

---

## Layout

Code is grouped by responsibility, not by kind. There is no `Utils` folder, no
`Helpers` folder and no `Models` folder inside a feature, and there never will
be.

A type lives in a file named after it. An extension adding a distinct
responsibility lives in `Type+Responsibility.swift`.

The package holds everything that can be written against Foundation alone. If a
type needs SwiftUI or AppKit, it belongs in the application. If it does not, it
belongs in the package, whether or not that feels convenient today.

---

## Boundaries

A model never performs a request. A service never touches observable state. A
domain type never knows where it is stored.

Dependencies are injected through the initialiser, from the composition root. A
type never reaches for a singleton to find a collaborator.

Declare a protocol where it is consumed, keep it as small as the consumer needs,
and only when something other than the production type will implement it. There
are two in the whole project: the network boundary and the secret store. Both are
justified in [ADR-0022](<ADR/0022 - Swift Testing with URLProtocol stubs at the network edge.md>)
and [ADR-0020](<ADR/0020 - Token secrets in the data protection keychain.md>).

---

## Observation

Observable state uses the `@Observable` macro.

`ObservableObject`, `@Published`, `@ObservedObject`, `@StateObject` and
`@EnvironmentObject` are not used. Neither is Combine.

Never subscribe to a model's changes in order to react to them. A model that must
respond to something exposes a method the caller invokes. There is no
`objectWillChange` to observe, and reintroducing that pattern by hand defeats the
reason for the macro. See
[ADR-0018](<ADR/0018 - Observation instead of ObservableObject.md>).

Use `@ObservationIgnored` for stored properties that must not participate in
tracking, such as an injected service.

---

## Concurrency

The project builds in the Swift 6 language mode, with approachable concurrency
enabled and without default actor isolation. Isolation is always written, never
inferred from a build setting.

Anything that publishes state to SwiftUI is `@MainActor`. Anything that owns a
shared mutable resource is an `actor`. Everything else is nonisolated and says
so by saying nothing.

Never annotate a type `@unchecked Sendable` to silence an error. Fix the design
instead.

Never block a thread. `Task.sleep` for a delay, never `sleep` and never a
semaphore.

A long-running loop takes cancellation seriously: check `Task.isCancelled`, and
let the task be cancelled by the thing that started it rather than by a flag.

---

## Errors

Model failures as a typed error conforming to `LocalizedError`, with wording a
user can act on. `ProxmoxError` is that type for everything network and API
shaped; extend it rather than introducing a parallel one.

An error from another source is wrapped in a `ProxmoxError` case before it
reaches the interface. A raw `URLError` or `DecodingError` is never displayed.

Never swallow an error silently. `try?` is acceptable only where the failure is
genuinely irrelevant and the surrounding code makes that obvious.

---

## Optionals and force unwrapping

No force unwrapping, no implicitly unwrapped optionals, no `try!`, no `as!`.

`guard let` with an early return is the default. A value that genuinely cannot be
absent is expressed as a non-optional type rather than unwrapped at every use.

---

## Logging

Logging goes through `os.Logger`, never `print` or `NSLog`.

One logger per area, with the subsystem set to the bundle identifier and a
category naming the area, so `Console.app` and `log stream` can filter to one
subsystem without reading the whole system's output.

```swift
private let logger = Logger(subsystem: "com.proxmoxbar.app", category: "api")
```

Non-numeric interpolations are redacted by default, which is the behaviour that
protects tokens. Opt a value into the log with `privacy: .public` deliberately,
and never for anything derived from a credential.

Never log a token, a secret, an authorization header, a server configuration, or
a URL that could carry credentials.

---

## Persistence

Storage keys are declared once, as constants, in the type that owns them. A key
is never spelled out at a call site.

Read [Data & Persistence](<Data & Persistence.md>) before changing anything that
serialises. Renaming a Swift type is free; renaming what it encodes to is data
loss on a user's machine.

---

## Naming

Follow the Swift API Design Guidelines. Clarity at the point of use wins over
brevity.

A type is named after what it is, not after the pattern it implements. `Manager`,
`Helper` and `Service` are not responsibilities; `ServerStore`, `ProxmoxAPIClient`
and `DashboardModel` are.

Use the Proxmox vocabulary for Proxmox concepts: node, guest, storage, task,
UPID. See [Glossary](Glossary.md).

---

## Formatting

`swift-format` is the only style tool, configured by `.swift-format` at the
repository root and enforced in CI. Formatting is never a review topic. See
[ADR-0023](<ADR/0023 - swift-format as the only style tool.md>).

---

## Comments

Prefer clear names and small functions over comments.

A comment that explains what the code does is a naming failure. A comment that
explains why a decision was made belongs in an ADR. A comment that records a
non-obvious external constraint — a Proxmox behaviour, an AppKit quirk — is worth
keeping, and should say which one.
