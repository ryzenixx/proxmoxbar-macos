This page lists everything that configures ProxmoxBar: what ends up in the
bundle, what the build reads, and what the release pipeline needs.

The application itself has no configuration file, no flags and no environment
variables. Everything a user can change is in the settings screen and stored as
described in [Data & Persistence](<Data & Persistence.md>).

---

## Build settings

Build settings live in `Config/*.xcconfig`, not in the Xcode project. They are
plain text, so a change to the deployment target or the hardened runtime shows up
in a diff as one line. See
[ADR-0016](<ADR/0016 - Synchronized folders and xcconfig over a hand-listed project.md>).

| File | Applies to |
| --- | --- |
| `Shared.xcconfig` | Everything: identity, deployment target, language mode, warnings |
| `Debug.xcconfig` | Debug only |
| `Release.xcconfig` | Release only |
| `App.xcconfig` | The application target |
| `Tests.xcconfig` | The test target |

The ones that carry meaning:

| Setting | Value | Note |
| --- | --- | --- |
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.proxmoxbar.app` | Never change. See [Updates](Updates.md) |
| `PRODUCT_NAME` | `ProxmoxBar` | Also the executable name |
| `MARKETING_VERSION` | `0.0.0` | Placeholder, overridden from the tag at release |
| `CURRENT_PROJECT_VERSION` | `0` | Same |
| `MACOSX_DEPLOYMENT_TARGET` | `14.0` | Also the appcast minimum system version |
| `SWIFT_VERSION` | `6` | The language mode. There is no `6.2` mode |
| `SWIFT_APPROACHABLE_CONCURRENCY` | `YES` | See [ADR-0019](<ADR/0019 - Explicit MainActor over default isolation.md>) |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | unset | Isolation is written explicitly |
| `ENABLE_HARDENED_RUNTIME` | `YES` | Required for notarization |
| `INFOPLIST_FILE` | `Config/Info.plist` | With `GENERATE_INFOPLIST_FILE = NO` |
| `SPARKLE_PUBLIC_ED_KEY` | empty | Overridden on the command line at release |

Rules for the xcconfig files: they belong to no target and appear in no copy
phase, every value that supports it inherits with `$(inherited)`, and a custom
variable is prefixed with a double underscore so it cannot collide with a real
build setting.

Values overridden on the command line at release — the version and the Sparkle
key — must stay overridable. A value hardcoded in an xcconfig cannot be injected
by the pipeline.

---

## Info.plist

`Config/Info.plist` is checked in and used verbatim; `GENERATE_INFOPLIST_FILE` is
off, so this file is the only source of bundle keys.

| Key | Value | Effect |
| --- | --- | --- |
| `CFBundleIdentifier` | `$(PRODUCT_BUNDLE_IDENTIFIER)` | Identity for preferences, keychain, login item and updates |
| `CFBundleShortVersionString` | `$(MARKETING_VERSION)` | The version users and Sparkle compare |
| `CFBundleVersion` | `$(CURRENT_PROJECT_VERSION)` | Build number, set to the same value at release |
| `CFBundleIconFile` | `AppIcon` | Resolves to `AppIcon.icns` in the bundle |
| `LSUIElement` | `true` | No dock icon, no menu bar menu, no app switcher entry |
| `LSMinimumSystemVersion` | `$(MACOSX_DEPLOYMENT_TARGET)` | Kept in sync with the build setting |
| `NSHighResolutionCapable` | `true` | Retina rendering |
| `SUFeedURL` | Raw URL of `appcast.xml` on `main` | Where updates are looked up |
| `SUPublicEDKey` | `$(SPARKLE_PUBLIC_ED_KEY)` | Injected at build time, empty in a normal local build |
| `SUEnableAutomaticChecks` | `true` | Check without asking first |
| `SUScheduledCheckInterval` | `3600` | One hour between background checks |

There is no `NSAppTransportSecurity` exception. Self-signed Proxmox certificates
are handled by evaluating and pinning them per server, not by disabling transport
security globally. See
[ADR-0021](<ADR/0021 - Per-server certificate trust instead of accepting everything.md>).

A local build has an empty `SPARKLE_PUBLIC_ED_KEY`, so the updater refuses to
start and reports that updates are unavailable rather than checking against a
feed it cannot verify. That is intentional: a debug build must never install a
release over itself.

---

## Release environment

The workflow reads these from repository secrets and passes them to the scripts
in `scripts/release/`. Every script validates what it needs and fails
immediately when something is missing.

| Variable | Secret | Used by |
| --- | --- | --- |
| `SPARKLE_PUBLIC_KEY` | `MACOS_SPARKLE_PUBLIC_KEY` | Build, test and archive, injected as `SPARKLE_PUBLIC_ED_KEY` |
| `SPARKLE_PRIVATE_KEY` | `MACOS_SPARKLE_PRIVATE_KEY` | Signing the appcast entry |
| `CODESIGN_IDENTITY` | `MACOS_CODESIGN_IDENTITY` | Signing the app and the DMG |
| — | `MACOS_CERTIFICATE`, `MACOS_CERTIFICATE_PWD` | Importing the Developer ID certificate |
| `NOTARY_APPLE_ID` | `MACOS_NOTARY_APPLE_ID` | Notarization |
| `NOTARY_APP_PASSWORD` | `MACOS_NOTARY_APP_PASSWORD` | Notarization, an app-specific password |
| `NOTARY_TEAM_ID` | `MACOS_NOTARY_TEAM_ID` | Notarization, also the export team id |

`APP_NAME`, `VERSION`, `TAG_NAME` and `SPARKLE_TOOLS_VERSION` come from the
workflow rather than from secrets. `VERSION` is the tag without its `v`.

Two secrets are irreplaceable in different ways. Losing the Sparkle private key
means no installed copy can ever be updated again. Changing the Developer ID
certificate breaks Sparkle's trust chain *and* makes macOS prompt every user for
keychain access. Neither is a routine operation. See [Updates](Updates.md).

---

## Local development

No configuration is required. Open the project, pick the `ProxmoxBar` scheme, and
run.

Signing is not configured in the project. A local build is signed to run locally,
and only the release pipeline sets a Developer ID identity explicitly.

A locally signed build cannot read keychain items created by the released app,
because the designated requirement differs. That is expected, and it means
development uses its own servers and its own tokens.
