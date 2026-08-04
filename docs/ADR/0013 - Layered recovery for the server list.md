| Field | Value |
| --- | --- |
| **Identifier** | ADR-0013 |
| **Date** | 2026-03-11 |
| **Status** | Accepted |

---

## Context

The server list is the only thing a user configures, and reconstructing it means
going back into Proxmox to create a new API token because the secret is shown
once and never again.

Earlier builds had written the list under different keys, and had encoded the
token fields under several different names. Payloads written by those builds were
still on users' machines. A decode failure meant an empty settings screen and a
user who had to start over.

`UserDefaults` is also not a safe single home. A preference domain can be reset
by the system, lost with a corrupted plist, or wiped by a user clearing
preferences to fix something unrelated.

---

## Decision

The server list is loaded from four sources, in order, stopping at the first that
decodes: the current key, the legacy keys, a backup key holding the last payload
that decoded successfully, and a JSON file under Application Support.

A payload that fails to decode is copied to a third key before the next source is
tried, so nothing is discarded silently.

Decoding accepts every historical field name for the token and its secret and
takes the first non-empty value. Once decoded, the payload is rewritten in the
canonical shape, so each alias is paid for once per installation.

Every save promotes the current payload to the backup key before overwriting, and
rewrites the disk copy atomically.

The exact keys, field names and order are a compatibility contract, documented in
[Data & Persistence](<../Data & Persistence.md>).

---

## Consequences

A user keeps their servers across an update, a corrupted preference file, a reset
preference domain, and any payload written by any previous build.

The cost is a load path with four branches and a decoder that accepts eleven
field names for two fields. It is the most defensive code in the project and it
reads that way.

The disk backup means token secrets exist in a second clear-text location. That
is a real aggravation of the storage problem in [Security](../Security.md), and
whatever replaces it must keep the same recovery guarantees.

The legacy aliases can never be removed on a schedule. There is no way to know
that every installation has been migrated, so they stay until the format changes
for another reason.

This is also what makes the storage layer expensive to refactor, and why it is
covered by tests before anything else moves. See [Quality](../Quality.md).
