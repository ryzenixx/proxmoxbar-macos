This page describes how ProxmoxBar talks to a Proxmox VE host, and what it
deliberately never does.

---

## Client

`ProxmoxAPIClient` is the only type that performs a request. No view and no model
ever constructs a `URLRequest`.

It is an `actor` holding one `URLSession`, and it conforms to `ProxmoxAPI`, the
protocol models depend on. That protocol exists so a model can be tested without
a request; the client itself is tested against a stubbed `URLProtocol`, with its
real session and real decoding. See
[ADR-0022](<ADR/0022 - Swift Testing with URLProtocol stubs at the network edge.md>).

The session's delegate evaluates the server certificate. A chain that validates
against the system trust store passes; one that does not is accepted only if its
fingerprint matches the one pinned for that server. See
[ADR-0021](<ADR/0021 - Per-server certificate trust instead of accepting everything.md>)
and [Security](Security.md).

Every call takes the server it is for. The client holds no server state, so
switching servers requires no invalidation.

---

## Authentication

Every request carries an API token, never a password or a ticket:

```
Authorization: PVEAPIToken=USER@REALM!TOKENID=SECRET
```

Proxmox accepts this on any endpoint without a prior login round trip and without
a CSRF token, which is why no session handling exists in the app. See
[ADR-0003](<ADR/0003 - API tokens instead of a user password.md>).

---

## Endpoints

Three, and no more.

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/api2/json/cluster/resources` | The entire dashboard, in one call |
| `POST` | `/api2/json/nodes/{node}/{type}/{vmid}/status/{action}` | `start`, `shutdown`, `reboot` |
| `GET` | `/api2/json/nodes/{node}/tasks/{upid}/status` | Whether the action finished, and how |

`/cluster/resources` returns nodes, guests and datastores in a single
heterogeneous array. One call renders the whole popover, on a cluster of any
size, and works identically on a single host. See
[ADR-0004](<ADR/0004 - One cluster resources call instead of per-node endpoints.md>).

---

## Decoding

The response array is decoded into one permissive payload type where nearly every
field is optional, then partitioned by the `type` discriminator into nodes,
datastores and guests.

An entry that does not carry the fields its kind requires is dropped rather than
failing the whole response, so a Proxmox version that adds a resource type or
renames a field on one object degrades that row instead of emptying the
dashboard.

Dropped entries are counted and logged. That log line is the only way anyone
finds out a payload changed shape, so it is not optional.

Guests are `qemu` and `lxc` only. Anything else is ignored.

Ordering is applied at decode time: guests by id, datastores by usage descending
then by name.

---

## Refresh

The popover runs a loop that fetches, waits five seconds, and fetches again,
until it disappears. Nothing runs while the popover is closed. See
[ADR-0007](<ADR/0007 - Polling on a fixed interval while the popover is open.md>).

A fetch retries up to three times with a short delay, because a homelab host
behind a VPN or a sleeping switch fails the first attempt often enough to matter.
An HTTP error is not retried: a 401 will still be a 401 on the third try.

Requests bypass the URL cache, and carry a ten second timeout.

---

## Actions

Proxmox answers a power action with a UPID, not with a result. The action is
queued, and the caller has to follow it.

The app therefore posts the action, then polls the task status until it reports
stopped, up to thirty times at one second intervals. A task that stops with a
non-`OK` exit status is surfaced as a failure. See
[ADR-0008](<ADR/0008 - Waiting on Proxmox task identifiers after an action.md>).

Start and shutdown then wait for the guest status to actually flip, because a
finished task means the hypervisor accepted the request, not that the guest is up
or down. Reboot does not wait, since its start and end states are identical.

---

## Deep links

Clicking a guest opens the Proxmox web interface on that object, by rebuilding
the base URL of the server and appending the fragment the interface uses to
select a resource:

```
https://host:8006/#v1:0:=qemu%2F100
```

The browser reuses whatever Proxmox session is already open. ProxmoxBar never
passes its token to the browser.

---

## What ProxmoxBar never does

- It never writes to the cluster outside an explicit user action. Refreshing is
  read-only.
- It never creates, deletes or reconfigures anything. Three power actions is the
  entire write surface.
- It never stores what it read. Cluster state lives in memory for as long as the
  popover is open.
- It never authenticates with a password, and never asks for one.
