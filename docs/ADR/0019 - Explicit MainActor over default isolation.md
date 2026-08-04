| Field | Value |
| --- | --- |
| **Identifier** | ADR-0019 |
| **Date** | 2026-08-04 |
| **Status** | Proposed |

---

## Context

Swift 6.2 added two build settings that change how concurrency is written.

`SWIFT_APPROACHABLE_CONCURRENCY` enables a group of upcoming features, the most
consequential being `nonisolated(nonsending)` by default: an async function
inherits its caller's isolation instead of hopping to the global executor. That
removes a whole class of surprising context switches.

`SWIFT_DEFAULT_ACTOR_ISOLATION` set to `MainActor` makes every declaration
main-actor-isolated unless marked otherwise. Xcode 26 turns both on for new
projects; existing projects keep the previous behaviour.

The second one is genuinely contested. Antoine van der Lee and Donny Wals argue
it is the right default for an app target, because it matches how UI code
actually runs and removes annotation noise. Matt Massicotte argues the opposite:
it does not remove concurrency problems, it hides them until the first time you
hit one, and it makes that first encounter harder to reason about. He also notes
it implicitly enables `InferIsolatedConformances`.

The specific fact that decides it here: the core logic is moving into a package
that must not be main-actor isolated, because it performs network work and is
tested without a UI. See
[ADR-0017](<0017 - A local package for the core, an Xcode project for the app.md>).
Turning on `MainActor` by default in the app while the package stays nonisolated
produces exactly the two-inverted-models situation Massicotte describes, inside
one repository of three thousand lines.

The codebase also does not need it. Three types are main-actor isolated and one
is an actor. That is four annotations.

---

## Decision

`SWIFT_APPROACHABLE_CONCURRENCY` is enabled.

`SWIFT_DEFAULT_ACTOR_ISOLATION` is left at its default. Isolation is written
explicitly: `@MainActor` on anything that publishes state to SwiftUI, `actor` on
anything owning a shared mutable resource, and nothing implicit anywhere.

The language mode is Swift 6, written as `SWIFT_VERSION = 6`. There is no 6.2
language mode; the valid values are 4, 4.2, 5 and 6, and the project currently
declares `6.2`, which is not one of them.

The same posture applies to the package: no `defaultIsolation` setting, explicit
annotations.

---

## Consequences

Isolation is readable at the declaration. Someone opening a file knows which
actor a type runs on without knowing which build settings are set, which is the
property that matters most in a codebase two people will ever read.

There is one concurrency model across the app and the package.

`nonisolated(nonsending)` removes accidental executor hops from async functions,
which is the part of approachable concurrency with the clearest benefit and the
least ambiguity.

The cost is annotations that Xcode's default would have written. Every new
observable model needs `@MainActor`, and forgetting it produces a compile error
rather than a silent hop, which is the acceptable failure.

This diverges from Xcode's new-project default, so a contributor generating code
from a template will produce files that need an annotation added.

Fixing `SWIFT_VERSION` to `6` changes nothing about how the code compiles.
Measured against Xcode 27 on 2026-08-04, the project already reports
`EFFECTIVE_SWIFT_VERSION = 6`: Xcode resolves the invalid `6.2` down to the
language mode it corresponds to. The fix is for clarity, so the declared value
and the effective one agree and nobody has to run `-showBuildSettings` to learn
which mode the project is in.

Enabling approachable concurrency is the part that can surface new diagnostics,
and it has to be verified against a real build before merging, not assumed.
