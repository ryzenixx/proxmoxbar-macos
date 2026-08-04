| Field | Value |
| --- | --- |
| **Identifier** | ADR-0021 |
| **Date** | 2026-08-04 |
| **Status** | Accepted |

---

## Context

[ADR-0006](<0006 - Accepting any TLS certificate.md>) accepts any server
certificate, for any host, without asking. It is what makes a stock Proxmox
install reachable, and it means the application has no defence against an
attacker able to intercept the connection.

Removing the exception is not an option: Proxmox issues node certificates from a
per-install certificate authority, and rejecting them would make the app unusable
for most of its users on first launch.

What has changed is that the exception no longer has to be all or nothing.
`SecTrustEvaluateWithError` reports why an evaluation failed, and
`SecTrustSetAnchorCertificates` lets a specific certificate be trusted as an
anchor for a specific host. A trust-on-first-use flow — show the fingerprint,
have the user accept it once, pin it, and reject anything that does not match
afterwards — gives the same first-launch experience with a real guarantee
afterwards.

The value at stake is higher than it was, because
[ADR-0020](<0020 - Token secrets in the data protection keychain.md>) is only
worth doing if the credential is not handed to whoever answers the connection.

---

## Decision

Certificate validation is performed normally. A server that validates against the
system trust store connects with no interaction.

When evaluation fails only because the chain is not trusted, the connection is
refused and the interface offers the user the certificate's SHA-256 fingerprint,
its subject and its expiry, and a single explicit choice to trust that
certificate for that server.

An accepted fingerprint is stored with the server and pinned. Subsequent
connections to that server succeed only against that certificate. A change of
fingerprint is a hard failure with an explicit message, not a new prompt, because
a silent re-prompt is how pinning becomes theatre.

A failure for any other reason — an expired certificate, a hostname mismatch — is
reported and not offered for acceptance.

`NSAllowsArbitraryLoads` is removed from the Info.plist. It is not what makes
self-signed certificates work, and leaving it behind weakens transport security
for no benefit.

This supersedes [ADR-0006](<0006 - Accepting any TLS certificate.md>).

---

## Consequences

An attacker between the Mac and the cluster can no longer collect a token by
presenting a certificate, which is the entire point.

A user with a properly configured certificate finally gets the benefit of having
configured it, which the global exception denied them.

First contact with a stock Proxmox host now costs one dialog. That dialog has to
be written well: it appears before the user has seen the app do anything useful,
and a fingerprint means nothing to most of the audience. Getting the wording
wrong turns a security feature into an obstacle users learn to click through.

Renewing a Proxmox certificate — which happens, and which Proxmox does
automatically for ACME setups — breaks the connection until the user accepts the
new fingerprint. That will generate support questions, and the error message has
to name the cause precisely.

Trust state becomes part of a server's stored configuration, which the migration
in ADR-0020 has to account for. A server configured before this change has no
pinned fingerprint and takes the trust-on-first-use path once.

The trust evaluation is custom code in a security-critical path. It gets tests
covering a valid chain, an untrusted chain with a matching pin, an untrusted
chain with a mismatched pin, and an expired certificate.
