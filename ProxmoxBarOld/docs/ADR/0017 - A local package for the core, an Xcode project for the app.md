| Field | Value |
| --- | --- |
| **Identifier** | ADR-0017 |
| **Date** | 2026-08-04 |
| **Status** | Accepted |

---

## Context

The layering is a convention, and conventions erode. `SettingsService` holds a
domain model, the persistence code and a piece of UI state at once. Because that
UI state is published, opening the settings sheet triggers a full cluster
refresh. Nothing prevented that, because nothing enforces the boundary.

Testing is the sharper problem. The test target is hosted by the application, so
the app launches to run four unit tests. That is a property of `@testable import`
against an application target: without a `TEST_HOST`, the module cannot be
imported at all.

And the view model depends on `ProxmoxService` itself rather than on a protocol,
so it cannot be exercised without performing real requests. There are no view
model tests as a result.

Moving the logic into a separate module solves both. A package builds and tests
without an application, and the module boundary is checked by the compiler rather
than by discipline: code inside it cannot import AppKit or SwiftUI, so a view
cannot leak into it.

This is also the correct form of a suggestion that has been made informally: the
core becomes a package, the app does not. Swift Package Manager cannot produce a
signed, notarized bundle, which is settled in
[ADR-0011](<0011 - An Xcode project as the build system.md>).

---

## Decision

The models, the Proxmox client and the storage layer move into a local Swift
package. The application target depends on it and keeps everything that touches
AppKit, SwiftUI, Sparkle or the bundle itself.

A protocol is introduced at the network boundary, and the view model depends on
it rather than on the concrete client.

Logic tests move into the package and run without an application host. The
application target keeps only tests that genuinely need a bundle.

Two modules, not more. Splitting further is not justified at this size.

---

## Consequences

Tests for the storage contract, the API decoding and the view model run in
seconds, without launching a menu bar item, and can run without a full Xcode
build.

The layering is enforced rather than encouraged. A future change that puts a view
concern back into the storage layer stops compiling.

Everything the application uses from the package has to be `public`, which is
noise on every type and every member that crosses the boundary. That is the main
cost, and it is paid once.

Types crossing the boundary must satisfy `Sendable` where the concurrency model
requires it, which may surface isolation problems that the single-module build
currently tolerates. Finding them is a benefit; the work of fixing them is not
free.

There is one more manifest to maintain, and dependency resolution now involves a
local package as well as Sparkle.

The application remains an Xcode project, and can never become a package.
