| Field | Value |
| --- | --- |
| **Identifier** | ADR-0004 |
| **Date** | 2026-01-11 |
| **Status** | Accepted |

---

## Context

The dashboard needs nodes, guests and datastores for the selected server.

Assembling that from the per-object endpoints means listing the nodes, then for
each node listing its VMs, its containers and its datastores. On a four-node
cluster that is thirteen requests, fanned out, every refresh cycle.

Proxmox also exposes `/api2/json/cluster/resources`, which returns all of it in
one array where each entry carries a `type` discriminator. It exists on a
standalone install too, where it simply reports one node.

---

## Decision

The dashboard is built from a single `GET /api2/json/cluster/resources` call.

The response is decoded into one permissive payload type where nearly every field
is optional, then partitioned by `type` into nodes, datastores and guests. An
entry missing a field its kind requires is dropped rather than failing the
response.

Per-node endpoints are used for nothing. The only other calls are the power
action and the task status behind it.

---

## Consequences

One request per refresh, regardless of cluster size. No fan-out, no partial
failure to reconcile, and no code path that differs between a standalone host and
a cluster.

The payload type is a union of every resource kind, so it is a long list of
optionals and reads poorly. That is the price of one call, and the partitioning
happens once, in one place.

Dropping malformed entries means a Proxmox version that renames a field degrades
one row instead of emptying the dashboard. It also means such a change is silent:
nothing reports that entries were discarded.

Anything not in `/cluster/resources` is out of reach without adding a second call
path. That includes per-guest configuration, backup state and node hardware
detail, which is consistent with what
[Objectives](../Objectives.md) says the app will not do.
