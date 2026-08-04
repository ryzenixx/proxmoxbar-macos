| Field | Value |
| --- | --- |
| **Identifier** | ADR-0009 |
| **Date** | 2026-01-13 |
| **Status** | Accepted |

---

## Context

Early releases shipped whatever architecture the build machine happened to
produce, which was Apple silicon. Intel users got an application that ran under
Rosetta at best.

The audience is homelab operators, a group that keeps hardware. A 2019 Intel Mac
running the machine that manages a Proxmox cluster is an entirely ordinary setup,
and it is not going away for years.

---

## Decision

Release builds are universal: `arm64` and `x86_64` in one binary, in one DMG.

Debug builds compile for the active architecture only, so local iteration is not
slowed by building code nobody is running.

There is one download. Users are never asked which Mac they have.

---

## Consequences

Every supported Mac runs native code, and there is a single artifact to build,
sign, notarize and publish.

The DMG carries two copies of the executable, which roughly doubles its size.
At under two megabytes, that is irrelevant.

Release builds take longer than debug builds, and a compilation error that only
appears on one architecture surfaces in CI rather than locally.

Dropping Intel later is possible and would be invisible to Apple silicon users,
but it silently strands Intel users on their last compatible version, the same
way raising the minimum system version does. See
[ADR-0012](<0012 - macOS 14 as the minimum version.md>).
