This page describes what is planned and what is deliberately deferred.

What already works is in [Features](Features.md). What the code should look like
is in [Architecture](Architecture.md); this page is the order it gets there.

---

## 3.0.0

One major version, one release. It is a rebuild of the inside of the app, and it
breaks stored data on purpose.

The order below is the order the work is done in. Each step leaves the app
building and running.

1. **Project structure.** `Sources/` and `Tests/` become synchronized folders,
   build settings move into `Config/*.xcconfig`, `SWIFT_VERSION` becomes `6` and
   approachable concurrency is enabled. No Swift file changes. This comes first
   because it makes every later move free. See
   [ADR-0016](<ADR/0016 - Synchronized folders and xcconfig over a hand-listed project.md>)
   and [ADR-0019](<ADR/0019 - Explicit MainActor over default isolation.md>).
2. **The core package.** `ProxmoxCore` is created and the models, the API client
   and the storage layer move into it, behind the `ProxmoxAPI` protocol. See
   [ADR-0017](<ADR/0017 - A local package for the core, an Xcode project for the app.md>).
3. **Storage, rewritten.** The new schema-versioned format, the keychain, and no
   migration from 2.x. The eleven aliases, the four-level recovery, the corrupt
   quarantine and the disk backup all go. See
   [ADR-0025](<ADR/0025 - A clean break on stored data for 3.0.0.md>) and
   [ADR-0020](<ADR/0020 - Token secrets in the data protection keychain.md>).
4. **Observation.** `@Observable` replaces `ObservableObject`, and the
   `objectWillChange` subscription disappears along with the redundant cluster
   refresh it caused. Responsibilities separate: the server store stops holding
   UI state, `AppDelegate` gives up the status item and the popover to a shell
   and a composition root. See
   [ADR-0018](<ADR/0018 - Observation instead of ObservableObject.md>).
5. **Certificate trust.** Normal validation, with per-server trust-on-first-use
   pinned by fingerprint, and the global exception removed. See
   [ADR-0021](<ADR/0021 - Per-server certificate trust instead of accepting everything.md>).
6. **Liquid Glass.** The hand-rolled background stack goes; the system provides
   the popover material, with the macOS 14 and 15 appearance behind availability
   checks confined to the design system. See
   [ADR-0024](<ADR/0024 - Adopting Liquid Glass while keeping the macOS 14 floor.md>).
7. **The reset message.** The one-time explanation shown when no server list has
   ever been written, plus the release notes. This is not optional and it does
   not ship later than the break. See
   [ADR-0025](<ADR/0025 - A clean break on stored data for 3.0.0.md>).
8. **Hygiene and tests.** `os.Logger` instead of `print`, no force unwraps, stop
   refetching the whole cluster to watch one guest, `swift-format` in CI, and the
   test suite written against the shape that actually shipped. See
   [ADR-0022](<ADR/0022 - Swift Testing with URLProtocol stubs at the network edge.md>)
   and [ADR-0023](<ADR/0023 - swift-format as the only style tool.md>).

Tests come last here, and that is a consequence of step 3, not an oversight. A
test net exists to prove a refactor did not change behaviour; this release
changes behaviour on purpose, so there is nothing to hold constant. Writing tests
against the 2.x storage contract would mean testing code scheduled for deletion.

The trade is real and worth naming: from step 1 to step 8, correctness rests on
review and on running the app, not on a suite. That is acceptable for one release
of a menu bar app with three endpoints. It would not be acceptable twice.

---

## Later

- Remember the selected server across launches.
- Refresh in the background while the popover is closed, so the menu bar icon can
  carry a state indicator. Requires deciding what that costs on battery, which is
  why [ADR-0007](<ADR/0007 - Polling on a fixed interval while the popover is open.md>)
  deferred it.
- Node-level detail, rather than only the aggregated datacenter row.
- Per-version release notes in the appcast, instead of one shared file.
- Localisation. The interface is English only.

---

## Deliberately deferred

- Creating, cloning or reconfiguring guests. ProxmoxBar operates what exists; the
  web interface builds it.
- Backups, snapshots and replication.
- A metrics history. Current usage is shown, a time series is a different
  product.
- Hypervisors other than Proxmox VE.
- Any hosted component, account or telemetry.
