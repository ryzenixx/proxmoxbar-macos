This page describes how architectural decisions are recorded in ProxmoxBar.

Structural decisions are documented so that their context, their justification
and their consequences survive the people who made them. A note tells you how
ProxmoxBar works today. An ADR tells you why it became that way.

---

## When to write an ADR

Write one when a decision durably shapes the application:

- adopting, replacing or dropping a technology or a dependency;
- changing the architecture, a module boundary or the build system;
- changing anything a user's installed copy depends on: the bundle identifier,
  the update feed, the signing identity, a storage key or an encoded format;
- changing a security principle, including certificate handling and credential
  storage;
- accepting a trade-off that a future reader would otherwise undo by mistake.

Do not write one for a bug fix, a visual change, or a refactor with no external
effect.

---

## Format

ProxmoxBar uses the Nygard format: Context, Decision, Consequences, preceded by a
metadata table. See [0000 - Template](<ADR/0000 - Template.md>).

Keep an ADR short. One that nobody rereads has failed at its only job.

---

## Rules

An ADR is immutable once accepted. It is a record, not a living document.

To change a decision, write a new ADR that supersedes the old one, and set the
old one's status to Superseded with a link to its replacement. Never rewrite
history.

Numbers are sequential and never reused. The file name is
`NNNN - Short title.md`.

---

## Status values

| Status | Meaning |
| --- | --- |
| Proposed | Written, not yet agreed |
| Accepted | Agreed and binding |
| Superseded | Replaced by a later ADR, which must be linked |
| Deprecated | No longer applies, with no replacement |

**Accepted is about the decision, not the code.** An accepted ADR is the rule to
follow from now on; it does not claim the code already follows it. Several
accepted decisions are still being implemented, and where the code diverges is
recorded in [Architecture](Architecture.md) and [Security](Security.md), with the
order of the work in [Roadmap](Roadmap.md).

A superseded ADR can likewise still describe what the shipped app does, until its
replacement is implemented. That is the case for
[0006](<ADR/0006 - Accepting any TLS certificate.md>) today.

---

## Records

The first fifteen were written retroactively in August 2026, from the commit
history. Each is dated to the commit that introduced the decision, not to the day
it was written down.

| ADR | Title | Date | Status |
| --- | --- | --- | --- |
| 0001 | [A menu bar app with no dock presence](<ADR/0001 - A menu bar app with no dock presence.md>) | 2026-01-11 | Accepted |
| 0002 | [An AppKit lifecycle behind a SwiftUI app](<ADR/0002 - An AppKit lifecycle behind a SwiftUI app.md>) | 2026-01-11 | Accepted |
| 0003 | [API tokens instead of a user password](<ADR/0003 - API tokens instead of a user password.md>) | 2026-01-11 | Accepted |
| 0004 | [One cluster resources call instead of per-node endpoints](<ADR/0004 - One cluster resources call instead of per-node endpoints.md>) | 2026-01-11 | Accepted |
| 0005 | [Sparkle for in-app updates](<ADR/0005 - Sparkle for in-app updates.md>) | 2026-01-11 | Accepted |
| 0006 | [Accepting any TLS certificate](<ADR/0006 - Accepting any TLS certificate.md>) | 2026-01-11 | Superseded by 0021 |
| 0007 | [Polling on a fixed interval while the popover is open](<ADR/0007 - Polling on a fixed interval while the popover is open.md>) | 2026-01-12 | Accepted |
| 0008 | [Waiting on Proxmox task identifiers after an action](<ADR/0008 - Waiting on Proxmox task identifiers after an action.md>) | 2026-01-12 | Accepted |
| 0009 | [A universal binary for Apple silicon and Intel](<ADR/0009 - A universal binary for Apple silicon and Intel.md>) | 2026-01-13 | Accepted |
| 0010 | [A global event monitor to dismiss the popover](<ADR/0010 - A global event monitor to dismiss the popover.md>) | 2026-01-15 | Accepted |
| 0011 | [An Xcode project as the build system](<ADR/0011 - An Xcode project as the build system.md>) | 2026-03-11 | Accepted |
| 0012 | [macOS 14 as the minimum version](<ADR/0012 - macOS 14 as the minimum version.md>) | 2026-03-11 | Accepted |
| 0013 | [Layered recovery for the server list](<ADR/0013 - Layered recovery for the server list.md>) | 2026-03-11 | Accepted |
| 0014 | [Developer ID signing and notarization outside the App Store](<ADR/0014 - Developer ID signing and notarization outside the App Store.md>) | 2026-03-11 | Accepted |
| 0015 | [A tag-triggered release pipeline in isolated jobs](<ADR/0015 - A tag-triggered release pipeline in isolated jobs.md>) | 2026-03-11 | Accepted |
| 0016 | [Synchronized folders and xcconfig over a hand-listed project](<ADR/0016 - Synchronized folders and xcconfig over a hand-listed project.md>) | 2026-08-04 | Accepted |
| 0017 | [A local package for the core, an Xcode project for the app](<ADR/0017 - A local package for the core, an Xcode project for the app.md>) | 2026-08-04 | Accepted |
| 0018 | [Observation instead of ObservableObject](<ADR/0018 - Observation instead of ObservableObject.md>) | 2026-08-04 | Accepted |
| 0019 | [Explicit MainActor over default isolation](<ADR/0019 - Explicit MainActor over default isolation.md>) | 2026-08-04 | Accepted |
| 0020 | [Token secrets in the data protection keychain](<ADR/0020 - Token secrets in the data protection keychain.md>) | 2026-08-04 | Accepted |
| 0021 | [Per-server certificate trust instead of accepting everything](<ADR/0021 - Per-server certificate trust instead of accepting everything.md>) | 2026-08-04 | Accepted |
| 0022 | [Swift Testing with URLProtocol stubs at the network edge](<ADR/0022 - Swift Testing with URLProtocol stubs at the network edge.md>) | 2026-08-04 | Accepted |
| 0023 | [swift-format as the only style tool](<ADR/0023 - swift-format as the only style tool.md>) | 2026-08-04 | Accepted |
| 0024 | [Adopting Liquid Glass while keeping the macOS 14 floor](<ADR/0024 - Adopting Liquid Glass while keeping the macOS 14 floor.md>) | 2026-08-04 | Accepted |
