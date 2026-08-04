This page describes the security model of ProxmoxBar and the rules that protect
it.

It describes the target. What the shipped app still does differently is at the
end, and tracked in [Roadmap](Roadmap.md).

---

## Threat model

ProxmoxBar holds an API token for a Proxmox VE cluster. What that token can do
depends entirely on the role it is bound to, and the app cannot restrict it.

A token with `VM.PowerMgmt` can stop production guests. A token created with the
default administrator role can do everything the web interface can, including
deleting virtual machines and reaching their consoles.

The app therefore treats the token as a credential of the same value as the
cluster itself. Two things follow, and they are the whole security model: the
token is never stored where another process can read it, and it is never sent to
anything that has not proved it is the server the user configured.

The assumed deployment is a personal Mac, used by its owner, talking to a homelab
or an internal cluster. ProxmoxBar is not designed for a shared machine.

---

## Permissions

The README documents a least-privilege setup: a dedicated `ProxmoxBar` role
carrying only the audit privileges plus `VM.PowerMgmt`, bound to a dedicated user
and an API token.

`Datastore.Audit`, `Pool.Audit`, `SDN.Audit`, `Sys.Audit` and `VM.Audit` are what
`/cluster/resources` needs to return a complete picture. `VM.PowerMgmt` is what
start, shutdown and reboot need. Nothing else is required, and nothing else
should be granted.

Privilege separation is left unchecked on the token, because a separated token is
limited to the intersection of its own permissions and the user's, and the setup
above already scopes the user.

---

## Credential storage

Token secrets live in the data protection keychain, as generic passwords keyed by
the server's identifier, accessible after first unlock on that device only and
never synchronised.

Everything else about a server — name, URL, token id, pinned fingerprint — is not
secret and lives in `UserDefaults`. The disk backup contains no secrets.

Keychain access is bound to the application's designated requirement, so a build
signed by a different identity cannot read the items silently. See
[ADR-0020](<ADR/0020 - Token secrets in the data protection keychain.md>) and
[Data & Persistence](<Data & Persistence.md>).

A token is never written to a log, never included in an error message, and never
handed to the browser when opening a deep link.

---

## Transport

Certificates are validated normally. A server with a publicly trusted certificate
connects with no interaction.

Proxmox issues node certificates from a per-install certificate authority, so
most servers will not validate. For those, the connection is refused and the user
is shown the certificate's fingerprint, subject and expiry, and asked once
whether to trust it for that server. An accepted fingerprint is pinned, and
afterwards only that certificate is accepted for that server.

A fingerprint that changes is a hard failure with an explicit message, not a new
prompt. A failure for any other reason — expired, hostname mismatch — is reported
and not offered for acceptance.

There is no global exception and no `NSAllowsArbitraryLoads`. See
[ADR-0021](<ADR/0021 - Per-server certificate trust instead of accepting everything.md>).

---

## Application hardening

The hardened runtime is enabled, which notarization requires. The app is signed
with a Developer ID certificate, notarized by Apple and stapled, so Gatekeeper
admits it without a warning. See [Packaging](Packaging.md).

The app is not sandboxed. It reaches arbitrary hosts on the local network and
writes its own backup under Application Support; a sandbox would add entitlements
without adding a boundary that matters here. A README claim that it was sandboxed
was removed in January 2026 because it was false.

Updates are verified twice, by Apple's code signature and by an EdDSA signature
over the archive. See [Updates](Updates.md).

---

## Rules

- Never log a token, a secret, an authorization header, or a whole server
  configuration. `os.Logger` redacts non-numeric interpolations by default; never
  mark one `.public` if it derives from a credential.
- Never weaken certificate handling, credential storage or update verification
  without an ADR.
- Never send a token anywhere other than the Proxmox host it belongs to.
- Never add a network call to a host the user did not configure, beyond the
  update feed.
- Never introduce telemetry, analytics or crash reporting.
- Never present a security decision the user cannot evaluate. A dialog that says
  only "this certificate is invalid, continue?" trains people to click through.
- Prefer the secure default even when it is less convenient, and make the
  insecure path an explicit, per-server, informed choice.

---

## What the shipped app still does differently

Both of these are real defects, not accepted trade-offs, and they are the reason
the security work is the first thing to follow the structural cleanup.

- **Token secrets are stored in clear text**, in the preference file and again in
  the disk backup. Any process running as the user, and any backup of the home
  directory, can read them.
- **Certificate validation is disabled**, globally, for every host. Combined with
  the above, an attacker positioned between the Mac and the cluster can present
  any certificate and capture a token that controls virtual machines.

On a trusted LAN, which is the assumed deployment, the exposure is limited. Over
a public network it is not, and nothing in the current app warns about the
difference.

---

## Reporting

Vulnerability reporting is described in [SECURITY.md](../.github/SECURITY.md).
