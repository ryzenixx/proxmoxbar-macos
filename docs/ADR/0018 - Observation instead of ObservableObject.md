| Field | Value |
| --- | --- |
| **Identifier** | ADR-0018 |
| **Date** | 2026-08-04 |
| **Status** | Accepted |

---

## Context

State is published to SwiftUI with `ObservableObject` and `@Published`, observed
with `@ObservedObject`.

That mechanism has one signal: `objectWillChange`. It fires for any change to any
published property, and every view observing the object is invalidated,
regardless of what it actually reads.

Two concrete problems follow in this codebase.

The settings service publishes the currently presented sheet alongside the server
list. Opening the sheet fires `objectWillChange`, and the view model subscribes to
that signal to reload, so presenting a form triggers a full cluster refresh. The
coupling is not a mistake in the subscription; it is what a single global signal
makes possible.

And the dashboard invalidates on every field of the view model. Typing in the
search box republishes state that the storage list also observes.

The Observation framework replaces this. `@Observable` tracks reads per property,
so a view is invalidated only by the properties it actually used. It requires
macOS 14, which is already the minimum. See
[ADR-0012](<0012 - macOS 14 as the minimum version.md>).

---

## Decision

Observable state uses the `@Observable` macro. `ObservableObject`, `@Published`,
`@ObservedObject`, `@StateObject` and `@EnvironmentObject` are not used in new
code and are removed from existing code.

Views hold observable models with `@State` when they own them and with a plain
`let` when they are handed one. `@Bindable` is used where a binding into a model
is needed.

There is no `objectWillChange` subscription anywhere. A model that needs to react
to another model's change exposes a method the caller invokes, or observes a
specific value; it never subscribes to a change firehose.

Combine is dropped. It was imported only to observe `objectWillChange`.

---

## Consequences

The redundant refresh disappears as a structural consequence rather than as a
patched symptom, because there is no longer a signal to subscribe to.

Views re-render less. The search field no longer invalidates the storage list,
and the dashboard no longer invalidates on fields it does not read.

`@Observable` is not a drop-in replacement. `@StateObject` takes an autoclosure
and initialises once; `@State` takes a value and its initialiser runs on every
rebuild of the view hierarchy. Any model constructed inline in a view has to be
moved to the composition root or created in a way that tolerates that. This is
the migration's one real trap.

Observation tracks reads, so a property read inside a closure that runs later, or
outside a view body, is not tracked. Code that relied on "any change invalidates
everything" can stop updating silently.

`@ObservationIgnored` is needed for stored properties that must not participate,
which is a new annotation to remember.

The floor stays macOS 14. Observation does not raise it.
