| Field | Value |
| --- | --- |
| **Identifier** | ADR-0002 |
| **Date** | 2026-01-11 |
| **Status** | Accepted |

---

## Context

[ADR-0001](<0001 - A menu bar app with no dock presence.md>) commits to a menu
bar item and a popover.

SwiftUI offers `MenuBarExtra` for exactly this. It also decides, on the
application's behalf, how the panel is presented and when it is dismissed. The
behaviour needed here is not the default: the panel must survive a click inside a
modal sheet, and a right click must show a menu instead of the panel.

Writing the interface itself in AppKit was never on the table. The views are
lists, gauges and a form, which is what SwiftUI is good at.

---

## Decision

The application shell is AppKit and the interface is SwiftUI.

`ProxmoxBarApp` is a SwiftUI `App` with an empty `Settings` scene and an
`@NSApplicationDelegateAdaptor`. It contains no logic.

`AppDelegate` creates the status item, the popover and the object graph, and
hosts the SwiftUI hierarchy through an `NSHostingController`.

`MenuBarExtra` is rejected because it does not expose popover behaviour or the
mouse events needed to distinguish a left click from a right click.

---

## Consequences

Full control over presentation and dismissal, which
[ADR-0010](<0010 - A global event monitor to dismiss the popover.md>) then
depends on.

The cost is a hand-written lifecycle. `AppDelegate` owns the status item, the
popover, the event monitor and the composition root, and is the one file where a
mistake produces an application that launches into nothing visible.

The empty `Settings` scene is a piece of scaffolding with no purpose other than
satisfying the `App` protocol. It will confuse every newcomer, and it cannot be
removed.

Anything AppKit provides and SwiftUI does not now requires an
`NSViewRepresentable` bridge, of which there are four.
