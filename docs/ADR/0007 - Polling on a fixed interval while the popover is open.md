| Field | Value |
| --- | --- |
| **Identifier** | ADR-0007 |
| **Date** | 2026-01-12 |
| **Status** | Accepted |

---

## Context

The first versions fetched once when the popover opened. A user watching a guest
boot saw a frozen list and had to close and reopen the popover to see it change.

Proxmox offers no push mechanism for cluster state. There is no event stream to
subscribe to, so the only way to observe a change is to ask again.

A background refresh on a timer would keep the data warm at all times, at the
cost of waking the machine, holding the network up and querying the cluster
continuously for a panel nobody is looking at.

---

## Decision

The popover drives the refresh. When it appears, a task fetches, sleeps five
seconds, and fetches again, until the view disappears and the task is cancelled.

Nothing runs while the popover is closed. Opening it also triggers an immediate
fetch before it is shown, so it never appears with stale numbers.

---

## Consequences

The list stays live while it is being read, and the application costs nothing
while it is not. On a laptop, that is the difference between an app that affects
battery life and one that does not.

The menu bar icon cannot show state. It is a static template image, because the
app has no idea what is happening in the cluster until the user opens it. Any
future indicator requires a background refresh and a new decision.

Five seconds is a compromise, not a measurement. It is fast enough to watch a
guest start and slow enough not to hammer a small host, and it is fixed: users
cannot change it.

A refresh is one request regardless of cluster size, which is what makes a five
second interval reasonable at all. See
[ADR-0004](<0004 - One cluster resources call instead of per-node endpoints.md>).
