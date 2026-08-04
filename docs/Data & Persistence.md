This page describes everything ProxmoxBar writes to disk.

There is no database. Server identity lives in `UserDefaults`; token secrets live
in the keychain. Nothing else is persisted.

Version 3.0.0 does not read anything written by 2.x. That is a deliberate clean
break, decided in
[ADR-0025](<ADR/0025 - A clean break on stored data for 3.0.0.md>), and it is the
one thing on this page a reader must know before assuming compatibility.

---

## What lives where

| Data | Store | Why |
| --- | --- | --- |
| Server id, name, URL, token id | `UserDefaults` | Not secret, and needed to render the settings screen before any keychain access |
| Pinned certificate fingerprint | `UserDefaults` | Not secret; a fingerprint is public by construction |
| Token secret | Keychain | Confers control over virtual machines |
| Sort order, notifications | `UserDefaults` | Preferences, cheap to lose |

---

## Keys

| Key | Type | Holds |
| --- | --- | --- |
| `ProxmoxBar.servers` | `Data` | The server list, JSON encoded, with its schema version |
| `ProxmoxBar.sortOrder` | `String` | `id`, `name` or `status` |
| `ProxmoxBar.notificationsEnabled` | `Bool` | Whether guest state changes post a notification |

The 2.x keys — `proxmox_servers`, `proxmox_servers_backup`,
`proxmox_servers_corrupt`, `enableNotifications`, `SortOption`, and the older
`proxmoxServers` and `servers` — are neither read nor written nor deleted. They
are left in place so a user who downgrades to 2.0.6 finds their configuration
intact.

---

## The stored shape

The payload is an object, not a bare array, so the schema version has somewhere
to live:

```json
{
  "schemaVersion": 1,
  "servers": [
    {
      "id": "31D8D5D9-A695-4B98-8BC2-68A6F1C9F2CB",
      "name": "Homelab",
      "url": "https://pve.local:8006",
      "tokenId": "proxmoxbar@pve!monitor",
      "pinnedCertificate": "sha256/9f86d081884c7d65..."
    }
  ]
}
```

`pinnedCertificate` is absent until the user accepts a certificate for that
server. Every other field is required.

Decoding is strict. There are no field aliases, no fallbacks, and no permissive
defaults: a payload that does not match is a payload this version did not write.

**The schema version is the whole point of this format.** A future change reads
`schemaVersion`, and migrates one known shape into the next. That is a migration
with a fixed input, which is a different thing from what 2.x had to do.

A payload whose `schemaVersion` is unknown — higher than this build understands,
which means the user downgraded — is left untouched and reported, never
overwritten.

---

## The keychain item

| Attribute | Value |
| --- | --- |
| Class | Generic password |
| Service | The bundle identifier |
| Account | The server's UUID |
| Accessible | After first unlock, this device only |
| Keychain | Data protection keychain |

The account is the server's identifier, not its URL: editing a server's address
must not orphan its secret. Deleting a server deletes its item. See
[ADR-0020](<ADR/0020 - Token secrets in the data protection keychain.md>).

Access is bound to the application's designated requirement, which derives from
its code signature. A build signed by the same Developer ID identity reads its
own items silently; a build signed by a different one causes macOS to prompt the
user. That makes certificate rotation a user-visible event, on top of the Sparkle
constraint in [Updates](Updates.md).

---

## Writing

Every mutation writes the whole list. There is no partial update and no merge.

There is no backup key and no backup file. A preference domain that is lost takes
the server list with it, and the keychain items it referenced become orphans.
That is an accepted consequence of keeping this layer small; the mitigation is
that re-adding a server is a documented procedure, not a mystery.

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

## The 3.0.0 reset

An existing user updates and finds an empty list. That is expected, and it is not
allowed to look like a bug.

The app detects that it has never written `ProxmoxBar.servers` and shows a
one-time explanation: 3.0.0 resets stored servers, here is how to add one, and
2.x data is still on disk if you downgrade. That message ships in the same
release as the break.

The release notes say it first, before anyone installs.

Re-adding a server is not just retyping a URL. A Proxmox token secret is shown
once at creation and cannot be read back, so the user has to create a new token
in the Proxmox web interface. The message links to that procedure rather than
assuming it is obvious.

---

## What is not persisted

- Cluster state. Nodes, guests and datastores are read live and thrown away.
- The selected server. It resets to the first entry on every launch.
- The search text, the resource filter and the current tab.
- Anything about Proxmox tasks.

---

## Changing this page

From 3.0.0 onward, the shape above is a contract again, and the schema version is
how it is changed: bump it, write the migration from the previous version, and
say so in an ADR.

The clean break was a one-time decision that spent the users' goodwill once. It
does not get to happen twice.
