| Field | Value |
| --- | --- |
| **Identifier** | ADR-0008 |
| **Date** | 2026-01-12 |
| **Status** | Accepted |

---

## Context

Proxmox power actions are asynchronous. `POST .../status/start` returns HTTP 200
and a UPID: the request was queued, nothing more.

The first implementation treated that 200 as success. The button stopped
spinning, the row still said stopped, and the next refresh cycle eventually
corrected it. A failure — a guest that would not boot, a lock held by a backup —
looked identical to a success.

Proxmox exposes the outcome at `/api2/json/nodes/{node}/tasks/{upid}/status`,
which reports whether the task is running or stopped and, once stopped, its exit
status.

---

## Decision

An action is followed to completion.

The app posts the action, takes the returned UPID, and polls the task status
until it reports stopped, up to thirty times at one second intervals. A task that
stops with an exit status other than `OK` is surfaced as a failure with that
status in the message. Exhausting the attempts is reported as a timeout.

Start and shutdown then wait for the guest status itself to flip, because a
finished task means the hypervisor accepted the request, not that the guest is
up or down. Reboot skips that wait, since its start and end states are the same.

---

## Consequences

The spinner reflects the real operation, and a failure is reported as a failure
instead of being silently reverted by the next refresh.

Every action now costs at least two requests and usually several, over up to
thirty seconds. A guest that takes longer than that to shut down reports a
timeout even though it is shutting down correctly, and the user sees an error for
an operation that will succeed.

The status confirmation loop is implemented by re-running the full dashboard
refresh, which fetches every node, guest and datastore up to thirty more times to
observe one guest changing state. It works, and it is wasteful; replacing it with
a single-guest query is tracked in [Roadmap](../Roadmap.md).
