This page states what ProxmoxBar must achieve. It is the reference against which
a feature is judged worth building.

---

## Product objectives

- Answer "what is running right now" in one click, for every configured cluster.
- Show nodes, VMs, containers and datastores with their current CPU, memory and
  disk usage.
- Allow the three actions that matter day to day: start, shut down, restart.
- Hand off to the Proxmox web interface for anything deeper, on the right object,
  without a second authentication.
- Stay useful with several clusters, not just one.

---

## Technical objectives

- Ship one signed, notarized application. No helper, no daemon, no installer.
- Read live state from the Proxmox API rather than maintaining a parallel model.
- Reflect the state of the cluster within the refresh interval while the popover
  is open, and cost nothing while it is closed.
- Keep the interface responsive when a host is unreachable: report the failure,
  never block.
- Keep the codebase small enough that a newcomer can read it in an afternoon.

---

## Operational objectives

- Never lose a configured server. An update, a crash or a corrupted preference
  file must not cost the user their setup. See [Data & Persistence](<Data & Persistence.md>).
- Update in place, silently and safely, through a signed feed.
- Support the macOS versions stated in [Packaging](Packaging.md), and never
  raise that floor without treating it as a breaking change.
- Require no configuration file, no terminal, and no privileged install step.

---

## Non-objectives

Stated so they are not proposed again.

- Creating, cloning, migrating or reconfiguring virtual machines.
- Backup, snapshot and replication management.
- Storing a metrics history. ProxmoxBar shows the current value; a time series is
  a different product.
- Supporting hypervisors other than Proxmox VE.
- Any hosted component, account system or telemetry.
