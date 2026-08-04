| Field          | Value                                                                                                              |
| -------------- | ------------------------------------------------------------------------------------------------------------------ |
| **Identifier** | ADR-0006                                                                                                           |
| **Date**       | 2026-01-11                                                                                                         |
| **Status**     | Accepted, to be superseded by [ADR-0021](<0021 - Per-server certificate trust instead of accepting everything.md>) |

---

## Context

Proxmox VE generates its own certificate authority at install time and issues
each node a certificate from it. That is the default, and it is what the
overwhelming majority of homelab installs run.

macOS rejects such a certificate. With default validation, ProxmoxBar cannot
reach a stock Proxmox host at all, and the first thing every user would see is a
TLS failure they cannot fix from inside the app.

The alternatives considered:

- Ask the user to install the Proxmox CA into the system keychain. Correct, and
  far beyond what a menu bar app can ask for before showing anything.
- Accept one certificate per server, pinned after the user confirms it. Correct,
  and requires a trust-on-first-use flow that did not exist.
- Accept everything.

---

## Decision

The URL session uses a delegate that accepts any server trust, for any host,
without asking. `NSAllowsArbitraryLoads` is set in the Info.plist alongside it.

---

## Consequences

Every stock Proxmox install works with no setup, which is the reason this was
chosen and the reason it has not been reverted.

The application has no defence against an attacker who can intercept the
connection. Any certificate is accepted, so a machine positioned between the Mac
and the cluster can terminate the connection, present its own certificate, and
read the API token in the request header.

Combined with the token being stored in clear text, the realistic worst case is
an attacker on an untrusted network obtaining a credential that can power off
production guests. On a trusted LAN, which is the assumed deployment, the
exposure is small. Over a public network it is not, and nothing in the app warns
about the difference.

The exception is global rather than per server, so it also applies to a host that
does have a valid publicly trusted certificate. A correctly configured user gets
no benefit from having configured it.

This is the weakest part of the security model and is documented as such in
[Security](../Security.md). The replacement is per-server trust-on-first-use with
a pinned fingerprint, which keeps stock installs working while restoring
validation everywhere else. See
[ADR-0021](<0021 - Per-server certificate trust instead of accepting everything.md>),
which supersedes this one once accepted.
