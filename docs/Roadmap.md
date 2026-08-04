This page describes what is planned and what is deliberately deferred.

What already works is in [Features](Features.md). What the code should look like
is in [Architecture](Architecture.md); this page is the order it gets there.

---

## Phase 1: structure

The application works and ships. The codebase is what holds it back, and the
order below is the order the work is done in, because each step makes the next
one cheaper and safer. None of it changes what the application does, and none of
it ships as a release on its own.

1. **A test net first.** Lock the storage contract and the API decoding under
   tests before moving anything. Without this, "clean the structure" means
   "hope nothing broke". See [Quality](Quality.md).
2. **Synchronized folders and xcconfig.** Stop listing every file by hand in the
   Xcode project, and move build settings into reviewable text. This is what
   makes every later step cheap, so it comes before any code moves. Fix
   `SWIFT_VERSION` to `6` at the same time. See
   [ADR-0016](<ADR/0016 - Synchronized folders and xcconfig over a hand-listed project.md>).
3. **Observation.** Replace `ObservableObject` with `@Observable` and delete the
   `objectWillChange` subscription. The redundant cluster refresh on opening the
   settings sheet disappears as a consequence rather than as a patch. See
   [ADR-0018](<ADR/0018 - Observation instead of ObservableObject.md>).
4. **Separate the mixed responsibilities.** The server model, the persistence and
   the presented sheet stop living in one type. `AppDelegate` gives up the status
   item, the popover and the object graph to a shell and a composition root.
5. **The core package.** Models, API client and storage move behind a module
   boundary, with a protocol at the network edge. Tests stop launching the app.
   See [ADR-0017](<ADR/0017 - A local package for the core, an Xcode project for the app.md>).
6. **Hygiene.** `os.Logger` instead of `print`, remove the force unwraps, stop
   refetching the whole cluster while waiting for one guest to change state, add
   `swift-format` to CI. See
   [ADR-0023](<ADR/0023 - swift-format as the only style tool.md>).

---

## Phase 2: security

Both items are real defects, documented in [Security](Security.md), and ship
together as one release once the structure is in place. Doing them after phase 1
is not procrastination: both touch storage and the network edge, which is exactly
the code phase 1 puts behind a tested boundary.

- **Token secrets in the keychain.** Stored in clear text today, in the
  preference file and in the disk backup. The migration must preserve the
  recovery order in [Data & Persistence](<Data & Persistence.md>), and a server
  whose secret is missing must remain a server, not disappear. See
  [ADR-0020](<ADR/0020 - Token secrets in the data protection keychain.md>).
- **Per-server certificate trust.** Validation is disabled globally today.
  Validate normally, and let a user accept one certificate for one host, pinned
  by fingerprint. See
  [ADR-0021](<ADR/0021 - Per-server certificate trust instead of accepting everything.md>).

That release is the one that needs the most careful update testing, because it
changes both stores at once.

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
