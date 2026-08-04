This page describes how the interface is built and the conventions that apply to
every view.

---

## Shell

The application has no window. It owns an `NSStatusItem` of variable length whose
button image is a template image, so macOS tints it for the current menu bar
appearance.

Left click toggles an `NSPopover` of 420 by 500 points hosting the SwiftUI
hierarchy. Right click builds a one-item menu offering Quit, attaches it to the
status item for the duration of the click, and detaches it immediately after, so
the popover keeps working.

Opening the popover triggers a refresh before it is shown, so it never appears
with stale numbers. Closing it cancels the refresh.

`MenuBarExtra` is not used. Its window style constrains the panel's size and does
not expose the dismissal control this app needs. That was true when
[ADR-0002](<ADR/0002 - An AppKit lifecycle behind a SwiftUI app.md>) was written
and is still true in 2026.

The shell lives in `ProxmoxBar/Shell/`, split by responsibility: the status item
and its click routing, the popover and its presentation, and the global click
monitor. `AppDelegate` owns none of it.

---

## Dismissal

The popover uses `.applicationDefined` behaviour, which means macOS never closes
it. The app decides.

A global event monitor watches for mouse clicks outside the application and
closes the popover, unless a sheet is presented. Without that exception, clicking
inside the server form dismissed the whole popover and lost what was being typed.
See [ADR-0010](<ADR/0010 - A global event monitor to dismiss the popover.md>).

The sheet state is read from the settings model, which owns it. The shell asks
the model whether it may close; it does not reach into a storage service to find
out.

---

## Structure

Screens are composed of small views in their own files. A view that grows past a
screenful is split, not scrolled past.

| View | Renders |
| --- | --- |
| `DashboardView` | Header, datacenter summary, tab bar |
| `ResourceListView` | Guests, with the search field and filters |
| `ResourceRowView` | One guest and its actions |
| `StorageListView` | Datastores |
| `ClusterSummaryRow` | The three usage gauges, reused by the summary |
| `SettingsView` | Settings screen, sheets and alerts |
| `ServerListSection`, `ServerFormView` | Server management |
| `CertificateTrustPromptView` | The first-contact certificate decision |

---

## State

A view that owns a model holds it in `@State`. A view that is handed one takes it
as a plain `let`. `@Bindable` is used where a binding into the model is needed,
such as a text field bound to a form field.

`@State` is also for state that dies with the view: the current screen, the
selected tab, a spinner.

Because `@Observable` tracks reads per property, a view is invalidated only by
what it actually used. That is a correctness property, not just a performance
one: it is what stops an unrelated change from re-running a view's body and
re-triggering whatever that body started.

Two consequences to keep in mind. A model created inline in a view body is
recreated whenever SwiftUI rebuilds the hierarchy, unlike `@StateObject` — so
models are built in the composition root, not in a view. And a property read
outside a view body, or inside a closure that runs later, is not tracked.

Derived values are computed properties on the model, never stored and never
duplicated in a view. Filtering and sorting the guest list happens in one place,
so two views cannot disagree about what is displayed.

An action is a method on the model. A view never awaits a network call itself.

---

## AppKit bridges

Four `NSViewRepresentable` wrappers exist for behaviour SwiftUI does not expose,
and they are the only place AppKit appears inside the view layer.

| Bridge | Reason |
| --- | --- |
| `VisualEffectView` | Real vibrancy behind the popover |
| `WindowAccessor` | Reaches the hosting window to hide its title bar and make it non-resizable |
| `CursorFixView` | Restores the arrow cursor, which a hosted SwiftUI view can leave in the wrong state |
| `GlobalClickMonitor` | Global mouse monitor used for dismissal |

Add a bridge only when SwiftUI genuinely cannot express the behaviour, and keep
it to one responsibility.

---

## Appearance

Colours come from the design system, which resolves against the effective
appearance rather than a stored light or dark flag. Never hardcode a colour that
has to differ between appearances.

The popover background comes from the system. The app does not draw its own
translucency underneath it, and individual rows do not add a material on top;
layering two materials is what made the header look wrong before it was removed
in 2.0.5, and it is what the hand-rolled background stack still does today.

Releases are built against the macOS 26 SDK, so they adopt Liquid Glass. Users
below macOS 26 keep the earlier appearance, and both have to be right. The
difference is expressed with availability checks that live **only** in the design
system layer — never in a feature view, never in a model. A view asks for a
surface; the design system decides what that means on the running OS. See
[ADR-0024](<ADR/0024 - Adopting Liquid Glass while keeping the macOS 14 floor.md>).

Status colours are semantic: running is green, stopped is secondary, an error is
red. Usage gauges shift with the ratio rather than with the resource.

---

## Text

Interface text is English, sentence case, and short enough not to wrap in a 420
point popover.

An error names what failed and what to check. `ProxmoxError` conforms to
`LocalizedError` and carries that wording, which is what makes
`localizedDescription` safe to display. An error from another source is wrapped
before it reaches a view, never rendered raw.

The certificate trust prompt is the hardest text in the app to get right. It
appears before the user has seen anything work, and a fingerprint means nothing
to most of the audience. It must say what the app is about to trust, what the
risk is in one sentence, and what the user should compare it against — not just
show a hash and two buttons. See
[ADR-0021](<ADR/0021 - Per-server certificate trust instead of accepting everything.md>).
