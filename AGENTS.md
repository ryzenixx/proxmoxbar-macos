# AGENTS.md

## Scope

These instructions apply to the entire repository. A closer `AGENTS.md`, if one
exists, takes precedence over this one.

---

## Project

ProxmoxBar is a native macOS menu bar app for monitoring and controlling Proxmox
VE resources.

It is open source and MIT licensed. No accounts, no telemetry, no hosted
component.

It ships as a single signed and notarized application, distributed in a DMG
outside the Mac App Store, and updates itself through Sparkle.

It has real users on machines nobody can reach. That fact governs everything
below.

---

## Documentation is the specification

`docs/` is an Obsidian vault and it is the source of truth for how this project
is meant to work. Read it before proposing anything structural.

When the documentation and the code disagree, **the documentation is right and
the code is behind**. Several pages describe a target the code is still being
moved to, and each one says so at the end.

Start with [Architecture](docs/Architecture.md). Before touching anything that is
stored, read [Data & Persistence](<docs/Data & Persistence.md>). Before touching
credentials or the network, read [Security](docs/Security.md). Conventions are in
[Code Conventions](<docs/Code Conventions.md>) and [Interface](docs/Interface.md).

A decision that durably shapes the project needs an ADR. The rules, the format
and the index are in
[ADR](<docs/ADR (Architecture Decision Records).md>). An accepted ADR is
immutable: supersede it, never rewrite it.

Documentation a change invalidates is updated in the same change.

---

## The compatibility contract

This is the most important section in this file.

Every item below is depended on by copies of the app already installed on other
people's machines. Changing one does not break the build. It breaks those
machines, silently, and no rollback reaches them.

- `CFBundleIdentifier`, currently `com.proxmoxbar.app`.
- `SUFeedURL`, the Sparkle appcast URL.
- The Sparkle EdDSA key pair and the Developer ID certificate. **Never rotate
  both in the same release**, and note that changing the certificate also makes
  macOS prompt every user for keychain access.
- `PRODUCT_NAME`, currently `ProxmoxBar`.
- `MACOSX_DEPLOYMENT_TARGET`, currently `14.0`. Raising it silently stops
  offering updates to users below it.
- Every `UserDefaults` key, every JSON field name, every legacy field alias, and
  the four-step recovery order, all listed in
  [Data & Persistence](<docs/Data & Persistence.md>).

Renaming a Swift type is free. Renaming what it serialises to is data loss on
someone else's machine. A Proxmox token secret is displayed once at creation and
never again, so a user who loses theirs has to go create a new one.

Never change any of it without an ADR and an explicit go-ahead.

---

## Repository structure

```
Sources/       the application, grouped by responsibility
Config/        Info.plist
Tests/         unit tests, currently hosted by the application
scripts/       one shell script per release step
docs/          the Obsidian vault: pages and ADRs
.github/       CI and the release pipeline
```

This layout is being reworked into an application target plus a local
`ProxmoxCore` package. The target is described in
[Architecture](docs/Architecture.md), and the order of the work is in
[Roadmap](docs/Roadmap.md). Follow that order; it exists because each step makes
the next one safe.

---

## Commands

```bash
xcodebuild -project ProxmoxBar.xcodeproj -scheme ProxmoxBar \
  -destination 'platform=macOS' build        # build
xcodebuild -project ProxmoxBar.xcodeproj -scheme ProxmoxBar \
  -destination 'platform=macOS' test         # build and test
swift-format lint --strict --recursive Sources Tests
```

Xcode 26 or later is required. A beta is fine, and is the only option on a beta
macOS.

What must not change silently is the project format: `objectVersion` in
`project.pbxproj` is `77`, and the CI runner has to be able to read what is
committed. Decline "update to recommended settings", and never commit a format
bump without moving CI in the same change. See [Quality](docs/Quality.md).

Run the build, the tests and the format check for every area a change touches.

Report what was executed, what passed, and what could not run and why. Never
declare a task complete without that report. If the toolchain is unavailable, say
so plainly rather than presenting unverified code as finished.

---

## Verification beyond the compiler

A menu bar app has failure modes no test observes: a popover that will not
dismiss, a status item that does not draw, a sheet that loses focus, an update
that fails on the user's machine after downloading.

A change to behaviour is run in the actual app before it is called done.

A change to anything stored is verified by installing the previous public
release, configuring a real server, updating over it in place, and confirming
nothing was lost. No unit test replaces that.

---

## Working workflow

For every non-trivial task:

1. Explain the approach.
2. List the files that will be created or modified.
3. Explain the technical decisions and their trade-offs.
4. Wait for approval before writing code.

Never refactor or change the architecture without explicit approval.

Keep changes scoped to what was asked. Report anything else you spot instead of
fixing it.

---

## Verification

Do not answer from memory when something can be checked. Verification beats prior
knowledge, always.

Before a technical decision, read the code that is already there. If the answer is
in the repository, read the repository instead of assuming.

Verify anything that changes over time against its official source: Apple API
availability and deprecations, Swift language features and their build settings,
Sparkle behaviour, Proxmox API responses, security advisories. Apple's platform
APIs move, and an answer that was right two releases ago is a liability.

Generated code, templates and framework defaults are starting points, not
decisions. Xcode's new-project defaults in particular are not automatically right
for this project; see
[ADR-0019](<docs/ADR/0019 - Explicit MainActor over default isolation.md>).

When you verify something, say what you checked, where, and what you concluded.

Label facts, observations, assumptions and recommendations for what they are.
Never present an assumption as a fact.

---

## Dependencies

There is exactly one runtime dependency: Sparkle.

Wait for approval before adding a second. To propose one: name the latest stable
release, confirm it works with the current toolchain and deployment target, and
justify what it saves that Foundation does not already do. Pin it. No floating
constraints, no unmaintained packages.

A dependency inside the application bundle has to be signed and timestamped
correctly or updates fail on users' machines rather than in CI.

---

## Self review

Before presenting a result, look for your own mistakes: wrong assumptions,
inherited template defaults, technical debt, risks you did not mention.

If a previous assumption turns out to be wrong, say so, explain the impact, and
give the corrected version.

---

## Security

A Proxmox API token can power off virtual machines. Treat it as a credential of
the same value as the cluster.

Never weaken credential storage, certificate validation, update verification or
input validation without explicit approval. Prefer secure defaults, and make the
insecure path an explicit, informed, per-server choice.

Never log a token, a secret, an authorization header, or a whole server
configuration. `os.Logger` redacts non-numeric interpolations by default; never
mark one `.public` if it derives from a credential.

Never send a token anywhere other than the Proxmox host it belongs to, and never
add a network call to a host the user did not configure.

Never introduce telemetry, analytics or crash reporting.

---

## Git

Read freely: `git log`, `git diff`, `git show` and `git status` are how you find
out why something is the way it is.

Never write: no commits, no branches, no tags, no pushes, no history rewriting,
no staging.

When the work is ready, hand over one single-line Conventional Commit message and
stop.

---

## Communication

Ask instead of guessing when requirements are ambiguous.

When several approaches are possible, give the alternatives, their trade-offs,
and your recommendation.

Never silently change architecture, documented behaviour or project conventions.

Always explain why, not only what.
