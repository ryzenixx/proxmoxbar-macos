This page describes how ProxmoxBar is put together and why it is shaped that way.

It describes the target the code is being moved to. What still diverges is listed
at the end and tracked in [Roadmap](Roadmap.md). When the two disagree, this page
is right and the code is behind.

ProxmoxBar is a single macOS application with no dock presence, no window and no
background helper. It owns a menu bar item, shows a popover, and talks directly
to the Proxmox API over HTTPS. There is no server, no database and no cache.

---

## Principles

- One process, one bundle, no companion. Every added moving part must earn its
  place against that baseline.
- Proxmox is the source of truth for runtime state. The app stores only what
  Proxmox cannot remember: the server list, their credentials, and a handful of
  preferences.
- Nothing is fetched while the popover is closed. A menu bar app that polls in
  the background costs battery for information nobody is reading.
- The boundary between logic and interface is a module boundary, not a folder
  name. Code that cannot import SwiftUI cannot drift into the interface.
- Views render observable state and call a model. They never build a request.

---

## Two modules

The logic lives in a local Swift package. The application depends on it and keeps
everything that touches AppKit, SwiftUI, Sparkle or the bundle.

`ProxmoxCore` imports Foundation and Security, and nothing else. That is enforced
by the compiler, not by discipline: a view cannot be added to it, and a request
cannot be made from outside it. See
[ADR-0017](<ADR/0017 - A local package for the core, an Xcode project for the app.md>).

Two modules, not more. Splitting further is not justified at three thousand
lines.

```
ProxmoxBar/          the application target, an Xcode synchronized folder
ProxmoxBarTests/     its tests, also a synchronized folder
ProxmoxCore/         a local Swift package: models, API, storage, trust
Configurations/      xcconfig files, and nothing else
```

The folder carrying a target is named after that target, and its `Info.plist`
lives inside it. That is Xcode's own template convention and what Ice, Maccy,
Rectangle and Stats all do; a folder called `Sources` or `Config` at the root of
a macOS app is not a thing anyone else does, and reads as a Swift package that
went wrong.

`Configurations/` holds build configuration files only. There is no convention
for that name because few apps use xcconfig at all, so it is a judgement call:
"configurations" is Xcode's own word for what those files configure.

---

## Layout

| Path | Responsibility |
| --- | --- |
| `ProxmoxBar/App/` | `@main`, the AppKit lifecycle, and the composition root |
| `ProxmoxBar/Shell/` | Status item, popover presentation, dismissal |
| `ProxmoxBar/Features/Dashboard/` | Dashboard, resource and storage views, and their model |
| `ProxmoxBar/Features/Settings/` | Settings screen, server form, and its model |
| `ProxmoxBar/Platform/` | Login item, notifications, updater: everything bound to the bundle |
| `ProxmoxBar/DesignSystem/` | Reusable views, adaptive colours, and the four AppKit bridges |
| `ProxmoxBar/Resources/` | Menu bar icon and application icon |
| `ProxmoxBar/Info.plist` | Bundle keys, excluded from the target's resources by a membership exception |
| `ProxmoxBarTests/` | The application-hosted test target |
| `Configurations/` | `Shared`, `Debug`, `Release`, `App`, `Tests` xcconfig |
| `ProxmoxCore/…/Models/` | `ProxmoxGuest`, `ProxmoxNode`, `ProxmoxStorage`, `ClusterSnapshot` |
| `ProxmoxCore/…/API/` | `ProxmoxAPI`, its client, `ProxmoxError`, `GuestAction`, the trust delegate |
| `ProxmoxCore/…/API/Payloads/` | The wire format, internal to the package |
| `ProxmoxCore/…/Storage/` | Server store, secret store, preferences |
| `ProxmoxCore/…/Trust/` | Certificate evaluation and pinning |
| `ProxmoxCore/Tests/` | Everything testable without an application |

One type per file, named after the type, per the
[Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
and the [Google Swift Style Guide](https://google.github.io/swift/). An extension
adding a distinct responsibility is `Type+Responsibility.swift`.

Both directories are synchronized folders: the target references the directory,
not a list of files. Adding a file adds it to the build. See
[ADR-0016](<ADR/0016 - Synchronized folders and xcconfig over a hand-listed project.md>).

The conventions that apply inside them are in
[Code Conventions](<Code Conventions.md>) and [Interface](Interface.md). Terms
used throughout are defined in [Glossary](Glossary.md).

---

## Startup

`ProxmoxBarApp` is a SwiftUI `App` whose only scene is an empty `Settings` scene.
It exists to satisfy `@main` and to host an `@NSApplicationDelegateAdaptor`.
Every real decision happens below it.

`AppDelegate` builds the composition root and hands it to the shell. It contains
no interface logic and no business logic; when something grows there, it belongs
in `Shell/` or in a model.

The application never shows a window. `LSUIElement` keeps it out of the dock and
the app switcher. See
[ADR-0001](<ADR/0001 - A menu bar app with no dock presence.md>) and
[ADR-0002](<ADR/0002 - An AppKit lifecycle behind a SwiftUI app.md>).

---

## Object graph

`AppEnvironment` is the composition root. It is the only place a service is
constructed, and it is built once, at launch.

```
AppDelegate
  └── AppEnvironment
        ├── ServerStore          servers, backed by UserDefaults + the keychain
        ├── Preferences          sort order, notifications
        ├── ProxmoxAPIClient     the only type that performs a request
        ├── DashboardModel       observable cluster state and actions
        ├── SettingsModel        observable server editing and sheet state
        ├── LaunchAtLogin
        ├── Notifications
        └── Updater
  └── ShellController            status item, popover, dismissal
```

Dependencies are passed into initialisers. Nothing reaches for a singleton to
find a collaborator, and there is no dependency container: the graph is small
enough to read in one screen.

---

## Data flow

1. The popover opens. The shell tells the dashboard model to start refreshing.
2. The model asks `ProxmoxAPIClient` for a snapshot, resolving the selected
   server's credential from the store.
3. The model publishes nodes, storages and guests. Views observing those
   properties re-render; views that read none of them do not.
4. An action calls the client, waits for the Proxmox task to finish, then
   refreshes.
5. The popover closes. The refresh task is cancelled.

Nothing is cached between the API and the view. See
[Proxmox Integration](<Proxmox Integration.md>).

---

## State and observation

Observable models use the `@Observable` macro, so SwiftUI tracks which properties
each view actually reads and invalidates only those views. `ObservableObject`,
`@Published` and `objectWillChange` are not used. See
[ADR-0018](<ADR/0018 - Observation instead of ObservableObject.md>).

That is what keeps the layers honest. There is no single change signal for a
model to subscribe to, so one model cannot react to another one's every mutation
by accident — which is exactly how presenting a settings sheet came to trigger a
cluster refresh.

Interface state belongs to the model that owns the interface. `SettingsModel`
owns which sheet is presented; the server store does not know sheets exist.

---

## Concurrency

Isolation is written explicitly.

`ProxmoxAPIClient` is an `actor`, so its `URLSession` is never touched from two
contexts at once. Observable models are `@MainActor`, so everything SwiftUI reads
is mutated on the main actor by construction.

The project builds in the Swift 6 language mode with approachable concurrency
enabled, and without default main-actor isolation, so a type's isolation is
readable at its declaration rather than inferred from a build setting. See
[ADR-0019](<ADR/0019 - Explicit MainActor over default isolation.md>).

---

## Persistence

Server identity — id, name, URL, token id — lives in `UserDefaults` with a copy
on disk as a last-resort backup. Token secrets live in the data protection
keychain, keyed by the server's identifier.

The exact keys, the encoding and the recovery order are a compatibility contract
with every installed copy of the app, and are documented in
[Data & Persistence](<Data & Persistence.md>). Read that page before changing
anything that serialises.

---

## What still diverges

The code has not caught up with this page yet. Today:

- `ProxmoxCore` exists and holds the models and the API client, but not the
  storage layer: `SettingsService` is still in the app, because step 3 replaces
  it outright rather than moving it. The app's own files still sit under `App/`,
  `Core/`, `Features/` and `Shared/`.
- State uses `ObservableObject`, and the view model subscribes to the settings
  service's `objectWillChange`, which is why opening the settings sheet triggers
  a redundant cluster refresh.
- `SettingsService` holds a domain model, the persistence and the presented sheet
  at once, and still reads the 2.x storage format.
- Token secrets are stored in clear text, and certificate validation is disabled
  globally.
- `AppDelegate` owns the status item, the popover, the event monitor and the
  object graph.
- **There are no tests.** The 2.x migration suite was deleted rather than
  maintained against a format being replaced; the suite is written back in the
  last step, against what ships. Until then, nothing but review and running the
  app catches a regression.

The project structure itself is done: synchronized folders, xcconfig, and the
conventional layout are in place.

The order the rest is being closed in, and why that order, is in
[Roadmap](Roadmap.md).
