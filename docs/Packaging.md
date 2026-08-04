This page describes how ProxmoxBar is built, signed and shipped.

---

## Target

One application bundle, signed with a Developer ID certificate, notarized by
Apple, delivered in a DMG, and updated in place afterwards.

There is no installer, no helper tool, no login item bundle and no privileged
step. Dragging the app to Applications is the entire installation.

---

## Build

```bash
xcodebuild \
  -project ProxmoxBar.xcodeproj \
  -scheme ProxmoxBar \
  -configuration Debug \
  -destination 'platform=macOS' \
  build test
```

That is exactly what CI runs. A release build additionally injects the version
and the Sparkle public key:

```bash
xcodebuild … -configuration Release \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$VERSION" \
  SPARKLE_PUBLIC_ED_KEY="$SPARKLE_PUBLIC_KEY" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$CODESIGN_IDENTITY" \
  archive
```

The version exists only in the git tag. Nothing in the repository carries it, so
a version can never disagree with the tag it was built from.

---

## Architectures

Release builds are universal: Apple silicon and Intel in one binary. Debug builds
compile for the active architecture only, which is what keeps local iteration
fast. See [ADR-0009](<ADR/0009 - A universal binary for Apple silicon and Intel.md>).

---

## Signing and notarization

The archive is exported with the `developer-id` method and manual signing, then
verified before anything else happens:

- the signature is checked with `codesign --verify --deep --strict`;
- the main executable is confirmed to be signed by a *Developer ID Application*
  authority and to carry a trusted timestamp;
- every Sparkle helper is checked the same way, individually: `Autoupdate`, the
  `Updater.app` executable, and the `Downloader` and `Installer` XPC services.

That last check exists because an unsigned or untimestamped Sparkle helper passes
a naive verification and then fails at install time, on the user's machine,
after the update has already been downloaded.

The DMG is then signed in turn, submitted to `notarytool`, stapled, and assessed
with `spctl` both as a DMG and as the app mounted inside it. A rejected
submission prints the full notary log before failing. See
[ADR-0014](<ADR/0014 - Developer ID signing and notarization outside the App Store.md>).

---

## The DMG

`hdiutil` builds a compressed read-only image containing the app and a symlink to
`/Applications`, so the drag target is present without a custom background or a
layout script.

A SHA-256 checksum is published next to it on the GitHub release.

---

## Releasing

Pushing a tag matching `vX.Y.Z` runs the pipeline. It can also be started
manually against an existing tag.

The first job refuses anything that is not a three-part version tag, or a tag
that is not an ancestor of `origin/main`. A release can therefore never be cut
from a branch that has not been merged.

The jobs then run in order, each consuming the previous one's artifact:

| Job | Produces |
| --- | --- |
| Preflight | The validated tag and version |
| Build and test | Nothing, but blocks the rest on a failure |
| Archive signed app | The signed `.app`, verified helper by helper |
| Package DMG | The DMG |
| Notarize and staple | The notarized, stapled DMG |
| Generate appcast | `appcast.xml`, signed with the EdDSA private key |
| Publish GitHub release | The release, with the DMG and its checksum |
| Publish appcast | `appcast.xml` committed to `main`, then merged into `develop` |

Splitting them means a notarization failure does not force a rebuild, and the
signed artifact of a failed run can be downloaded and inspected. See
[ADR-0015](<ADR/0015 - A tag-triggered release pipeline in isolated jobs.md>).

---

## Where things land

| Artifact | Location |
| --- | --- |
| `ProxmoxBar.dmg` | GitHub release assets, for the tag |
| `ProxmoxBar.dmg.sha256` | Next to it |
| `appcast.xml` | Repository root on `main`, served raw to Sparkle |
| `RELEASE_NOTES.md` | Repository root on `main`, linked from every feed item |

The appcast lives in the repository rather than on a server, so there is no
hosting to pay for and no domain to keep alive. The trade-off is that update
delivery depends on GitHub remaining reachable.

---

## Release notes

`RELEASE_NOTES.md` is written by hand before the tag, and every appcast item
points at the same file rather than at a per-version anchor. Users therefore see
the current file, including entries newer than the version they are being offered.

That is a known rough edge, kept because a single file is one thing to maintain
correctly rather than two.
