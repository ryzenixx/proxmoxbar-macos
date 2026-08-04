| Field | Value |
| --- | --- |
| **Identifier** | ADR-0001 |
| **Date** | 2026-01-11 |
| **Status** | Accepted |

---

## Context

Checking whether a homelab is healthy happens many times a day and takes a
second. Acting on it happens rarely.

The Proxmox web interface answers both, and charges the same cost for each: find
the tab, authenticate, wait for the dashboard, read one number.

A regular application would not help much. It would still be a window to find, an
icon in the dock, and an entry in the app switcher, for something that is looked
at for two seconds at a time.

---

## Decision

ProxmoxBar is a menu bar application. It owns an `NSStatusItem` and shows its
entire interface in a popover attached to it.

`LSUIElement` is set, so the application has no dock icon, no application menu
and no entry in the app switcher. It has no window at all: the SwiftUI `App`
declares an empty `Settings` scene purely to satisfy `@main`.

Quitting is offered on right click, because an application with no menu bar menu
has nowhere else to put it.

---

## Consequences

The application is one click away at all times and disappears completely when not
in use.

There is no window to restore, no state restoration, and no multi-window code
path. The popover is the entire interface, which bounds how much the app can ever
show: 420 by 500 points, one screen, no detail view that needs room.

Nothing is discoverable through a menu bar menu, so anything that is not in the
popover does not exist to the user. Quit is behind a right click, which users
have to be told about.

An agent application is easy to forget while it is running. That is acceptable
here because nothing runs while the popover is closed, but it forecloses any
future work that would poll in the background without an indicator.
