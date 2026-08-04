| Field | Value |
| --- | --- |
| **Identifier** | ADR-0012 |
| **Date** | 2026-03-11 |
| **Status** | Accepted |

---

## Context

Moving to an Xcode project in
[ADR-0011](<0011 - An Xcode project as the build system.md>) made the deployment
target an explicit decision for the first time.

Two APIs the application relies on set a floor. `SMAppService`, which registers
the app itself as a login item without a helper bundle, requires macOS 13.
Several SwiftUI behaviours the interface depends on are only consistent from
macOS 14.

The audience keeps hardware, so the floor is not free. Every macOS version left
behind is a set of users frozen on their last compatible release, silently.

---

## Decision

`MACOSX_DEPLOYMENT_TARGET` is `14.0`, and the appcast declares the same minimum
system version so Sparkle does not offer an update a machine cannot run.

Raising it is treated as a breaking change: it requires an ADR, and the release
notes must say so.

---

## Consequences

No availability checks and no conditional code paths in the application. What
compiles runs.

Users below macOS 14 keep the last version that supported them and are never
prompted again. They are not told why, because Sparkle simply stops offering
updates to a machine under the declared minimum. That silence is the reason this
is a decision and not a build setting.

The two values, the build setting and the appcast minimum, have to move together.
They are set from the same build setting, but the appcast entry is generated per
release, so a mismatch would only appear after publication.

macOS 13 support is not coming back. Reverting the floor would require the
declared minimum to go down in the feed, which Sparkle handles, but the code has
since been written without availability checks.
