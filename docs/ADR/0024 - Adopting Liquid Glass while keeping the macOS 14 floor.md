| Field | Value |
| --- | --- |
| **Identifier** | ADR-0024 |
| **Date** | 2026-08-04 |
| **Status** | Accepted |

---

## Context

macOS 26 Tahoe introduced Liquid Glass, a system-wide material and design
language. Recompiling against the macOS 26 SDK adopts it, with no code change and
no opt-in.

That has already happened. Version 2.0.6 was built on the `macos-26` runner on
2026-03-15, so every user on Tahoe has been running a Liquid Glass build since
March. Nobody decided that, and nobody designed for it.

Meanwhile the popover still builds its own background by hand: a
`windowBackgroundColor` at 40% opacity, under a `.popover` material blended
behind the window, under the system's own presentation. That stack was tuned
before Tahoe, against a different set of materials. On macOS 26 it sits on top of
a material that is already doing the job, which is the same class of mistake that
produced the doubled header removed in 2.0.5.

There is no escape hatch to rely on. A compatibility opt-out,
`UIDesignRequiresCompatibility`, is documented for iOS and is reported to be
ignored when building against the iOS 27 SDK. Whether an equivalent ever existed
for AppKit is **unverified**: every source found is iOS-facing, and the key
appears nowhere in Xcode 27.

*Corrected 2026-08-04, during a verification pass: an earlier revision of this
ADR asserted that key as a macOS opt-out. It was not verified and should not have
been stated as fact. The decision below never depended on it.*

The deployment target stays at macOS 14, per
[ADR-0012](<0012 - macOS 14 as the minimum version.md>) and confirmed on
2026-08-04: the Xcode 27 SDK still accepts deployment targets from 12.0 upward,
so nothing forces the floor up. Users on macOS 14 and 15 will therefore keep
seeing the pre-Tahoe look, and both must be correct.

---

## Decision

Liquid Glass is adopted deliberately rather than inherited by accident. The
compatibility opt-out is never set.

The hand-rolled background stack is removed. The popover lets the system provide
its material, and the app stops layering its own translucency on top of it. Where
a surface genuinely needs a material, it asks for the system one rather than
approximating it.

The macOS 14 floor stays. The difference between the two looks is expressed with
availability checks, and those checks live **only** in the design system layer.
No feature view, no model, and nothing in the package contains an
`if #available`. A view asks the design system for a surface; the design system
decides what that means on the running OS.

The exact API surface is verified against Apple's documentation at implementation
time, not assumed from memory. What is decided here is the posture, not the
symbol names.

Both appearances are checked before release: Tahoe on the development machine,
and macOS 14 or 15 in a virtual machine. A change to the design system layer that
was only looked at on one of the two is not done.

---

## Consequences

The interface stops fighting the system and starts matching every other app on
Tahoe, which is the entire point of a native menu bar app.

Removing the hand-rolled stack deletes code. The layering bug class — a material
over a material — becomes impossible to reintroduce, because the app no longer
draws its own.

Two visual paths have to be maintained until the floor rises, and only one of
them is visible on the development machine. That is the real cost, and it is why
the pre-release check names a virtual machine explicitly: without one, the macOS
14 look degrades silently over time and nobody notices until a user reports it.

Confining availability checks to the design system keeps the branching in one
place, at the cost of a slightly heavier abstraction between a view and a
background. That trade is deliberate: scattered `if #available` in feature views
is how a codebase becomes impossible to raise the floor on later.

Raising the floor to macOS 26 later becomes a cleanup of one layer rather than a
sweep across the app.

This does not touch the menu bar item itself. The status item image stays a
template image, which Tahoe tints the same way earlier versions did.
