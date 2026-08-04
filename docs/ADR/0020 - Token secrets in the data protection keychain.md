| Field | Value |
| --- | --- |
| **Identifier** | ADR-0020 |
| **Date** | 2026-08-04 |
| **Status** | Accepted |

---

## Context

API token secrets are stored in clear text, in the preference file and again in
the disk backup written by
[ADR-0013](<0013 - Layered recovery for the server list.md>). Any process running
as the user can read them, and so can any backup of the home directory. A
Proxmox token can power off virtual machines.

macOS has two keychains. The file-based login keychain is the historical one. The
data protection keychain is the modern one, the same implementation as iOS, and
Apple's technote TN3137 recommends it for new code, and it is selected by passing
`kSecUseDataProtectionKeychain` in the query.

**Unverified, and it must be settled before this is implemented:** whether a
non-sandboxed Developer ID application needs an entitlement to use it. TN3137 is
the authority and has to be read directly, not summarised. If an entitlement is
required and cannot be obtained without sandboxing, the fallback is the
file-based keychain, which is still a decisive improvement over clear text and
leaves the rest of this decision — what is stored, keyed how, and how it migrates
— unchanged.

One property of the keychain matters more than the API choice. Access control is
bound to the creating application's designated requirement, which derives from
its code signature. A future version signed by the same Developer ID identity
reads its own items silently. A version signed by a different identity does not:
the user is prompted, for every item, with a dialog they have no context to
answer.

That connects storage to updates. Sparkle already forbids rotating the Developer
ID certificate and the EdDSA key in the same release, per
[ADR-0005](<0005 - Sparkle for in-app updates.md>). Adding the keychain makes a
certificate change user-visible as well as update-breaking.

---

## Decision

Token secrets move to the data protection keychain. Everything else about a
server — its identifier, name, URL and token id — stays in `UserDefaults`.

Items are generic passwords. The service is the bundle identifier and the account
is the server's UUID, not its URL: a user editing a server's address must not
orphan its secret. Accessibility is `kSecAttrAccessibleAfterFirstUnlock`, this
device only, so a secret is never synchronised to iCloud and never leaves the
Mac it was entered on.

Migration runs once, on load. A server payload carrying a `secret` field has that
value written to the keychain and stripped from the payload before it is
rewritten. The encoded shape gains no new field; it loses one.

The four-source recovery order of ADR-0013 is preserved for everything except the
secret, which the keychain owns and which is therefore not written to the disk
backup any more.

A secret that cannot be found is treated as a server needing re-authentication,
surfaced in the interface, and never as a decode failure. Losing a token must not
cost a user their server list.

---

## Consequences

A leaked preference file, a stolen Time Machine backup or a hostile process
running as the user no longer yields a working credential.

The disk backup stops containing secrets, which removes the second clear-text
copy that ADR-0013 introduced.

Keying on the UUID rather than the URL means editing a server address keeps its
secret, and deleting a server must explicitly delete its keychain item or leave
an orphan behind. Orphan cleanup is now a thing that has to be written and
tested.

Storage becomes two stores that can disagree. A server whose secret is missing is
a state that did not previously exist and that every code path reading a token
has to handle.

Rotating the Developer ID certificate now prompts users for keychain access on
first launch after the update, in addition to the Sparkle constraint. Certificate
rotation was already a careful operation; it is now one that needs a release note
telling users what the dialog is.

Tests can no longer drive the real store as freely. Keychain access in a test
process is a different security context, so the store is exercised through an
in-memory implementation, and the keychain implementation itself gets a small
number of tests that are allowed to touch the real keychain.

Migration is one-way. A user who downgrades to a build predating this change
finds their servers present and their tokens gone.
