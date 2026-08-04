This page describes everything ProxmoxBar writes to disk, and the rules that keep
an update from destroying it.

There is no database. Server identity lives in `UserDefaults` with a copy on disk
for recovery; token secrets live in the keychain.

---

## The compatibility contract

Every key and every field name on this page is part of a contract with every
installed copy of the application. A user who updates must find their servers
where they left them, without retyping a token they can no longer read — a
Proxmox secret is shown once, at creation, and never again.

Changing a key name, a JSON field name, or the encoded shape of a server is a
data loss bug, not a refactor. Renaming a Swift type is free; renaming what it
serialises to is not.

Nothing here may change without a migration that reads the old form, an ADR, and
a manual update test over a real previous build.

---

## What lives where

| Data | Store | Why |
| --- | --- | --- |
| Server id, name, URL, token id | `UserDefaults` | Not secret, and needed to render the settings screen before any keychain access |
| Pinned certificate fingerprint | `UserDefaults` | Not secret; a fingerprint is public by construction |
| Token secret | Keychain | Confers control over virtual machines |
| Sort order, notifications | `UserDefaults` | Preferences |
| Nothing at all | Disk backup, for secrets | The backup exists to survive a lost preference file, and must not become a second copy of a credential |

---

## Keys

| Key | Type | Holds |
| --- | --- | --- |
| `proxmox_servers` | `Data` | The server list, JSON encoded. The source of truth |
| `proxmox_servers_backup` | `Data` | The previous successfully decoded payload |
| `proxmox_servers_corrupt` | `Data` | A payload that failed to decode, kept for diagnosis |
| `enableNotifications` | `Bool` | Whether guest state changes post a notification |
| `SortOption` | `String` | `ID`, `Name` or `Status` |

Two legacy keys are still read and migrated to `proxmox_servers` on first launch:
`proxmoxServers` and `servers`. A legacy key is read only when the current one is
absent or undecodable.

`notificationsEnabled` is the former name of `enableNotifications`, read once when
the current key has never been written.

---

## Server encoding

A server encodes to five fields. `secret` is not one of them.

```json
{
  "id": "31D8D5D9-A695-4B98-8BC2-68A6F1C9F2CB",
  "name": "Homelab",
  "url": "https://pve.local:8006",
  "tokenId": "proxmoxbar@pve!monitor",
  "pinnedCertificate": "sha256/9f86d081884c7d65..."
}
```

`pinnedCertificate` is absent until the user accepts a certificate for that
server.

Decoding is deliberately more permissive than encoding. Payloads written by
earlier builds, or edited by hand, used other names for the same fields, so the
decoder accepts any of them and takes the first non-empty value:

| Field | Accepted names |
| --- | --- |
| `tokenId` | `tokenId`, `tokenID`, `token_id`, `apiTokenId`, `api_token_id`, `token`, `apiToken` |
| `secret` | `secret`, `tokenSecret`, `token_secret`, `apiTokenSecret`, `api_token_secret` |

A missing `id` is replaced by a fresh one rather than failing the decode. `name`
and `url` are trimmed of surrounding whitespace.

The `secret` aliases are decode-only and exist solely for migration. A decoded
secret is written to the keychain and dropped from the payload; it is never
encoded again.

Once a legacy payload has been decoded, it is rewritten in the canonical shape,
so each alias is paid for exactly once per installation.

---

## The keychain item

| Attribute | Value |
| --- | --- |
| Class | Generic password |
| Service | The bundle identifier |
| Account | The server's UUID |
| Accessible | After first unlock, this device only |
| Keychain | Data protection keychain (`kSecUseDataProtectionKeychain`) |

The account is the server's identifier, not its URL: editing a server's address
must not orphan its secret. Deleting a server deletes its item. See
[ADR-0020](<ADR/0020 - Token secrets in the data protection keychain.md>).

Access is bound to the application's designated requirement, which derives from
its code signature. A build signed by the same Developer ID identity reads its
own items silently; a build signed by a different one causes macOS to prompt the
user. That makes certificate rotation a user-visible event, on top of the Sparkle
constraint in [Updates](Updates.md).

---

## Recovery order

Loading the server list tries four sources, in order, and stops at the first that
decodes:

1. `proxmox_servers`.
2. The legacy keys, which are then migrated.
3. `proxmox_servers_backup`, the last payload that decoded successfully.
4. `~/Library/Application Support/com.proxmoxbar.app/Backups/proxmox_servers.json`.

A payload that fails to decode is copied to `proxmox_servers_corrupt` before the
next source is tried, so nothing is discarded silently.

The disk copy exists for the case the preference domain itself is lost or reset,
which `UserDefaults` alone cannot survive. It is rewritten atomically on every
save, and contains no secrets. See
[ADR-0013](<ADR/0013 - Layered recovery for the server list.md>).

---

## Writing

Every mutation of the server list writes the whole list. There is no partial
update and no merge.

Before overwriting `proxmox_servers`, the current payload is promoted to
`proxmox_servers_backup`, so the backup is always one generation behind rather
than a copy of what is being written.

An encoding failure is logged and leaves the stored payload untouched.

---

## A server without a secret

Two stores can disagree, and the interface has to survive it.

A server whose keychain item is missing is a valid server needing
re-authentication. It appears in the list, it is marked as needing a token, and
the settings screen offers to enter one. It is never a decode failure, and it
never removes the server.

That state is reachable in practice: a user restoring a home directory from a
backup that excluded the keychain, or a build signed by a new certificate whose
prompt the user dismissed.

---

## What is not persisted

- Cluster state. Nodes, guests and datastores are read live and thrown away.
- The selected server. It resets to the first entry on every launch.
- The search text, the resource filter and the current tab.
- Anything about Proxmox tasks.

---

## Verifying a change

A change to anything on this page is verified by installing the previous public
release, configuring a real server, updating to the new build in place, and
confirming the server, its token and the preferences survived. Tests cover the
encoding and the recovery order; only that manual test covers the keychain and
the code signature together.
