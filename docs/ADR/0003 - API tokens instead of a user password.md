| Field | Value |
| --- | --- |
| **Identifier** | ADR-0003 |
| **Date** | 2026-01-11 |
| **Status** | Accepted |

---

## Context

Proxmox VE offers two ways to authenticate against its API.

A username and password produce a ticket and a CSRF token. The ticket expires
after two hours and has to be renewed, and the CSRF token has to accompany every
write. It also means the application holds a credential that can log into the web
interface and change the account itself.

An API token is a static credential of the form `USER@REALM!TOKENID` plus a
secret. It is sent on every request, needs no renewal, needs no CSRF token, and
can be bound to a role that grants far less than the user it belongs to. It can
also be revoked from the web interface without touching the account.

---

## Decision

ProxmoxBar authenticates with API tokens only, sent on every request:

```
Authorization: PVEAPIToken=USER@REALM!TOKENID=SECRET
```

There is no password field anywhere in the application, and no session handling.

The documentation walks users through creating a dedicated role holding the five
audit privileges plus `VM.PowerMgmt`, a dedicated user, and a token for it.

---

## Consequences

No session state, no expiry, no renewal path, and no CSRF handling. A request is
a request.

A leaked token is revocable in one click and cannot be used to log into the web
interface.

The blast radius is whatever role the user bound. The application cannot enforce
least privilege, only document it, and a user who reuses a `root@pam` token hands
the app full control of the cluster. That is why the documentation leads with the
scoped setup rather than the quick one.

Onboarding is heavier than a login form: four steps in the Proxmox interface
before the app is usable. That cost is paid once and is the reason the setup is
documented in the README rather than only in the app.

The token is stored on disk, which makes how it is stored the security question
that matters. See [Security](../Security.md).
