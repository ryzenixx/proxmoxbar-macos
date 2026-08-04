This page describes how ProxmoxBar is tested and what "done" means.

---

## Prerequisites

- macOS 14 or later
- Xcode 26 or later, from the App Store rather than a beta

Nothing else. `swift-format` is in the toolchain, Sparkle is resolved by Xcode,
and the core package is local.

A beta Xcode is specifically discouraged: it can upgrade the project file to a
format the CI runner cannot read, which breaks the build for everyone but the
person who opened it.

---

## Definition of done

A change is done when the build, the tests and the format check pass, and when
that has been reported rather than assumed.

A change that alters behaviour has been run in the actual app, not only compiled.
A menu bar app has failure modes a test cannot see: a popover that does not
dismiss, a status item that does not draw, a sheet that loses focus.

Documentation the change invalidates is updated in the same change. An
implementation and a note are never allowed to diverge; when they do, the note is
the specification and the code is the bug.

A change touching [Data & Persistence](<Data & Persistence.md>) has been verified
by updating over a previous public build with real data present. No test replaces
that one.

---

## Commands

```bash
swift test --package-path ProxmoxCore        # logic tests, no app, seconds

xcodebuild -project ProxmoxBar.xcodeproj -scheme ProxmoxBar \
  -destination 'platform=macOS' build test   # everything

swift-format lint --strict --recursive ProxmoxBar ProxmoxCore
```

In Xcode, `Cmd+B` and `Cmd+U` do the same as the second command.

---

## Testing strategy

Tests exercise the real type wherever the real type is cheap, and substitute only
at a boundary the app does not own.

| Under test | Real | Substituted |
| --- | --- | --- |
| `ProxmoxAPIClient` | Session, request building, decoding, retries, error mapping | The bytes on the wire, via a stubbed `URLProtocol` |
| `ServerStore` | Encoding, decoding, migration, recovery order, a real `UserDefaults` suite and a real temporary file | The keychain, via an in-memory secret store |
| Models | Selection, filtering, sorting, error presentation | The API, via the `ProxmoxAPI` protocol |
| `KeychainSecretStore` | Everything, against the real keychain | Nothing |
| Trust evaluation | Certificate chains from fixtures | Nothing |

That is deliberate over mocking every collaborator. A mock asserts that code was
called; this asserts that it works. See
[ADR-0022](<ADR/0022 - Swift Testing with URLProtocol stubs at the network edge.md>).

---

## What must be tested

Coverage is a signal, not a target. The rule is simpler: anything that could
silently lose a user's data, silently leak a credential, or silently stop working
is tested.

Concretely:

- Every storage key, every legacy field alias, every step of the recovery order.
  Those tests are the reason a refactor can move code without fear.
- The migration of a secret from a legacy payload into the keychain, including a
  payload that has already been migrated.
- Decoding a real `/cluster/resources` payload, and one with a missing field, and
  one with an unknown resource type.
- Every branch of certificate trust: valid chain, untrusted chain with a matching
  pin, untrusted chain with a mismatched pin, expired certificate.
- Every `ProxmoxError` case a user can reach.

---

## Conventions

Write tests with Swift Testing: `@Test`, `#expect`, `#require`. Port an XCTest
case when you touch it, not on a schedule.

Swift Testing runs cases in parallel by default. Give each case an isolated
`UserDefaults` suite and an isolated temporary directory, and clean both up. A
test that touches the real preference domain has failed before it ran.

Name a test after the behaviour it protects, not after the function it calls.

Never sleep in a test. Anything time-dependent is restructured until it is
deterministic.

Use real payloads as fixtures, captured from an actual Proxmox host and stripped
of identifying detail. A hand-written fixture tests the fixture writer's
assumptions.

---

## Continuous integration

GitHub Actions runs on every push and every pull request targeting `develop`, on
a macOS runner: the format check, the package tests, then the full build and
test.

Changes limited to documentation and repository metadata are excluded, so writing
a note does not consume a macOS runner.

The release workflow runs the same build and test as its second job, so a release
can never be cut from a commit that failed.

---

## Dependencies

Adding a dependency requires a reason that survives the question "what does this
save that Foundation does not do".

There is exactly one runtime dependency, Sparkle, pinned to a major version and
recorded in `Package.resolved`. See [Tech Stack](<Tech Stack.md>).

GitHub Actions are pinned by commit hash, not by tag, and updated by Dependabot,
which also watches the Swift package ecosystem.
