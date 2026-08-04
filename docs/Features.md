This page lists what ProxmoxBar does today. Anything not listed here is not
built.

Planned work lives in [Roadmap](Roadmap.md).

---

## Servers

- Any number of Proxmox hosts, each with a name, a URL and an API token.
- Added, edited, reordered by drag and drop, and deleted from the settings
  screen.
- One server is selected at a time and drives the whole dashboard. The first in
  the list is selected by default, and the selection falls back to the first
  entry when the selected server disappears.
- A server is reached over HTTPS. Certificates are currently accepted without
  validation, which is a defect being fixed rather than a feature. See
  [Security](Security.md) and [Roadmap](Roadmap.md).

---

## Dashboard

- A datacenter summary aggregating every node of the selected server: CPU across
  all cores, memory across all nodes, disk across all datastores.
- The summary is online when at least one node is online.
- Two tabs: resources and storage.

---

## Resources

- Every VM and container of the selected server, with id, name, node, status and
  current CPU, memory and disk usage.
- Filter by kind: all, VM (QEMU) or LXC.
- Search by name, case and diacritic insensitive.
- Sort by id, name or status. The choice is remembered across launches.
- Start, shut down and restart, with a spinner on the row while the action runs.
- Click a row to open that guest in the Proxmox web interface, already selected.

---

## Storage

- Every datastore of the selected server, with its node, status, plugin type,
  content types and usage.
- Sorted by usage, fullest first.

---

## Notifications

- Optional. When enabled, a notification is posted when a guest changes between
  running and stopped.
- Requires the notification permission, requested when the setting is turned on.
  The setting stays off if permission is refused.

---

## Application

- Menu bar item with no dock icon and no window. Left click opens the popover,
  right click offers Quit.
- Launch at login, through the system login item registration.
- In-app updates, checked automatically and on demand. See [Updates](Updates.md).
- Adapts to light and dark appearance.
