| Field | Value |
| --- | --- |
| **Identifier** | ADR-0025 |
| **Date** | 2026-08-04 |
| **Status** | Accepted |

---

## Context

The stored server list carries eleven accepted field names for two values and a
four-level recovery path, all of it to serve payloads written by builds from
2026-01. That is documented in
[ADR-0013](<0013 - Layered recovery for the server list.md>) and it is the most
defensive code in the project.

Three accepted decisions change the stored shape anyway. Secrets move to the
keychain ([ADR-0020](<0020 - Token secrets in the data protection keychain.md>)).
A pinned certificate fingerprint is added
([ADR-0021](<0021 - Per-server certificate trust instead of accepting everything.md>)).
And the format will keep moving, because features are still being added.

Preserving all of it means writing migration code across a format that is being
replaced — new code, written to be thrown away, in the layer that is hardest to
test. It is exactly the thing the cleanup exists to remove.

The other side of the ledger is real and is not a formality. A Proxmox token
secret is displayed once, at creation, and cannot be read back. Users cannot
retype what they never saw. Losing the stored list therefore does not mean
re-entering a URL: it means going into the Proxmox web interface, creating a new
API token, assigning the role to it, and coming back — the four-step procedure in
the README, per server.

---

## Decision

Version 3.0.0 does not migrate. It starts from an empty server list.

Storage moves to a new key with an explicit schema version as its first field.
The version exists so the next format change is a migration of one known shape
into another, rather than a negotiation with archaeology.

The keys written by 2.x are **not read, and not deleted**. Leaving them costs
nothing and means a user who downgrades to 2.0.6 finds their servers intact.

An empty list on first launch after the update is not silent. The app explains,
once, that 3.0.0 resets stored servers and links to the setup instructions. That
message ships **in the same release as the break**, never after: Sparkle updates
without asking, so without it the app simply looks broken.

The release notes say it first, in plain terms, before anyone installs.

This supersedes [ADR-0013](<0013 - Layered recovery for the server list.md>), and
replaces the migration paragraph of
[ADR-0020](<0020 - Token secrets in the data protection keychain.md>): there is no
secret to migrate, so secrets are written to the keychain from the moment a
server is created.

---

## Consequences

Every existing user has to create a new API token in Proxmox. That is the cost,
it is paid by people who did nothing wrong, and it is the reason the in-app
message and the release notes are part of this decision rather than an
afterthought.

The storage layer loses the eleven aliases, the four-level recovery, the corrupt
payload quarantine and the disk backup. What remains is one key, one shape, one
version number.

Future format changes get a version to branch on, so this decision does not have
to be made twice.

A downgrade path exists for free, because 2.x data is left untouched. That is
worth stating in the release notes: a user who is not ready can go back.

The absence of migration code removes the main reason the storage layer needed a
test net before being refactored. Tests still get written, at the end, against
the shape that ends up shipping rather than against one being replaced.

Nothing protects a user who updates, does not read the message, and expects their
servers to be there. That case is accepted deliberately, with the message as the
only mitigation.
