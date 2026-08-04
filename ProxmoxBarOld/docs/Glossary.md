This page defines the terms used across the ProxmoxBar documentation and
codebase.

---

## ADR

Architecture Decision Record. A dated, immutable note recording why a structural
decision was made. See [ADR (Architecture Decision Records)](<ADR (Architecture Decision Records).md>).

## Appcast

The RSS feed Sparkle reads to discover updates. It lives at the repository root
on `main` and is regenerated and signed by the release pipeline. See
[Updates](Updates.md).

## API token

A Proxmox credential of the form `USER@REALM!TOKENID` plus a secret, sent in an
`Authorization` header. It authenticates without a login round trip and is the
only credential ProxmoxBar accepts. See [Security](Security.md).

## Composition root

The single place where services are constructed and wired together. In
ProxmoxBar it is `AppEnvironment`, built by `AppDelegate` at launch. Nothing else
constructs a service, and nothing reaches for a singleton to find one.

## Data protection keychain

The modern of macOS's two keychains, the same implementation as iOS. Apple
recommends it for new code, and it needs no entitlement for a non-sandboxed
Developer ID app. Selected by passing `kSecUseDataProtectionKeychain`. See
[Security](Security.md).

## Designated requirement

The rule, derived from an application's code signature, that macOS uses to decide
whether a later version is "the same app". Keychain items are tagged with the
designated requirement of whatever created them, which is why changing the
signing certificate makes macOS prompt users for access to their own tokens.

## Datacenter

Proxmox's name for the top level of a cluster. ProxmoxBar shows a synthetic
`Datacenter` row that aggregates every node of the selected server. It is
computed, not returned by the API.

## EdDSA signature

The signature Sparkle verifies over an update archive, independent of Apple's
code signature. Its private half is a repository secret and its public half is
compiled into the app. See [Updates](Updates.md).

## Guest

A virtual machine or a container. The API calls them `qemu` and `lxc`;
ProxmoxBar shows them in one list and labels them VM and LXC.

## Hardened runtime

A macOS code signing option that restricts what a signed process may do. Required
for notarization. See [Packaging](Packaging.md).

## LSUIElement

The Info.plist key that makes an application an agent: no dock icon, no menu bar
menu, no entry in the app switcher. It is what makes ProxmoxBar a menu bar app.

## Node

A physical Proxmox host. A cluster has several; a standalone install has one.
Nodes carry the CPU and memory figures shown in the summary.

## Observation

The framework behind the `@Observable` macro. It tracks which properties a view
actually reads and invalidates only the views that read a changed one, replacing
`ObservableObject`'s single global change signal. See
[ADR-0018](<ADR/0018 - Observation instead of ObservableObject.md>).

## Notarization

Apple's automated scan of a signed application, after which a ticket is stapled
to the DMG so Gatekeeper admits it without a warning.

## Popover

The panel attached to the menu bar item. It is an `NSPopover` hosting the SwiftUI
hierarchy, and it is the entire user interface.

## Privilege separation

A Proxmox token option that limits a token to the intersection of its own
permissions and its user's. ProxmoxBar's documented setup leaves it off and
scopes the user instead. See [Security](Security.md).

## Storage

A Proxmox datastore: a named backing store attached to one or more nodes, with a
plugin type such as `dir`, `lvmthin` or `zfspool`, and a set of content types it
accepts.

## Synchronized folder

An Xcode project group that references a directory rather than a list of files,
so adding a file to the directory adds it to the target. Proposed in
[ADR-0016](<ADR/0016 - Synchronized folders and xcconfig over a hand-listed project.md>).

## Trust on first use

Accepting an untrusted certificate once, after being shown what it is, and
pinning it so that only that certificate is accepted afterwards. It is how a
self-signed Proxmox host is reached without disabling validation for every host.
See [ADR-0021](<ADR/0021 - Per-server certificate trust instead of accepting everything.md>).

## UPID

Unique Proxmox Identifier. The handle returned by a power action, used to poll
the task until it finishes. An action is asynchronous; the UPID is how its result
is retrieved. See [Proxmox Integration](<Proxmox Integration.md>).

## VMID

The cluster-wide numeric identifier of a guest. Unique across nodes, which is why
it is the default sort key.
