| Field | Value |
| --- | --- |
| **Identifier** | ADR-0010 |
| **Date** | 2026-01-15 |
| **Status** | Accepted |

---

## Context

An `NSPopover` with `.transient` behaviour closes itself when the user clicks
anywhere outside it. That is the right behaviour for a menu bar panel, and it was
what the app used.

It also closes when the user clicks inside a sheet the popover presented. Adding
a server meant opening a form, clicking a text field, and watching the entire
popover disappear along with everything typed into it. Alerts had the same
problem.

`.semitransient` and `.applicationDefined` both keep the popover open, but
`.applicationDefined` means macOS never closes it at all: the application becomes
responsible for every dismissal, including the ordinary click-outside case.

---

## Decision

The popover uses `.applicationDefined` behaviour, and the application decides
when it closes.

An `EventMonitor` wraps `NSEvent.addGlobalMonitorForEvents` for left and right
mouse down, and is started when the popover opens and stopped when it closes.
When it fires, the popover closes — unless a sheet is currently presented, in
which case the click is ignored.

The sheet exception reads the active sheet state, which is why that state has to
be reachable from the delegate.

---

## Consequences

Forms and alerts keep focus, and a click outside still dismisses the popover, so
the behaviour matches what a menu bar panel should do.

Dismissal is now application code, and every path that should close the popover
has to remember to. A missed case leaves a panel that cannot be dismissed except
by clicking the status item again.

A global event monitor observes clicks across the whole system. It receives only
the fact that a click happened outside the app, not its content, but it is still
a system-wide observer running whenever the popover is open, and it is stopped as
soon as it closes.

The sheet exception forced the active sheet to be exposed on a service the
delegate can reach. That is why `SettingsService` holds a piece of UI state
today, which turned out to be the seed of a layering problem documented in
[Architecture](../Architecture.md).
