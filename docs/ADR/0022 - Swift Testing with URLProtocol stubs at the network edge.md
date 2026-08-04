| Field | Value |
| --- | --- |
| **Identifier** | ADR-0022 |
| **Date** | 2026-08-04 |
| **Status** | Proposed |

---

## Context

There are four tests. They cover storage migration, they are XCTest, and they run
inside the application because the test target is hosted by it.

Nothing covers the Proxmox client: not URL construction, not the authorization
header, not the retry policy, not decoding, not the mapping of an HTTP status to
an error. That is the code most likely to break silently when Proxmox changes a
field name.

Two things have moved since those tests were written. Swift Testing ships with
the toolchain and is the default for new projects in Xcode 27; XCTest remains for
UI and performance tests, and the two coexist in one target.

And the received wisdom on testing networking has settled. Wrapping `URLSession`
in a protocol purely to substitute it produces a layer that exists only for
tests. Stubbing at `URLProtocol` instead keeps the real session, the real request
construction and the real decoding in the test, and substitutes only the bytes
coming back.

Those two arguments point at different layers, and both are right at their own
layer.

---

## Decision

New tests are written with Swift Testing, using `@Test`, `#expect` and
`#require`. The existing XCTest cases are ported as they are touched, not in a
migration sprint.

The Proxmox client is tested against a stubbed `URLProtocol` installed on a
dedicated session configuration. Those tests exercise the real client: the URL it
builds, the header it sets, how it retries, what it decodes, and which error it
produces for each failure. Fixtures are real `/cluster/resources` payloads.

The view model is tested against a small protocol at the network boundary, with a
hand-written double. It is the only protocol introduced for testability, and it
exists because the view model's logic — selection, filtering, sorting, error
presentation — is worth testing without a request at all.

Storage is tested against the real store with an isolated `UserDefaults` suite and
a temporary directory, as it already is. Only the keychain is substituted, per
[ADR-0020](<0020 - Token secrets in the data protection keychain.md>).

Tests live in the package and run without an application host, per
[ADR-0017](<0017 - A local package for the core, an Xcode project for the app.md>).

---

## Consequences

The decoding path finally has coverage, which is what makes it safe to move that
code at all.

Tests run in seconds without launching a menu bar item, and can run from the
command line without a full Xcode build.

Stubbing at `URLProtocol` means a test failure points at real behaviour rather
than at a mock's expectations. It also means the tests are coupled to
`URLSession`'s loading system, and a stub installed on the wrong configuration
silently does nothing, which is a confusing failure the first time it happens.

Two test styles coexist during the port, and the two frameworks have different
assertion vocabularies. That is untidy and is preferred to rewriting working
tests for their own sake.

Swift Testing runs cases in parallel by default. Anything touching a shared
`UserDefaults` domain or a shared temporary path has to be isolated per case or
serialised explicitly, which is a real source of flakiness if forgotten.

A protocol at the network edge is a layer that exists partly for tests. It is
accepted here because it is one protocol with four methods, and rejected as a
general pattern.
