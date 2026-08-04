| Field | Value |
| --- | --- |
| **Identifier** | ADR-0005 |
| **Date** | 2026-01-11 |
| **Status** | Accepted |

---

## Context

ProxmoxBar is distributed outside the Mac App Store, so nothing updates it
automatically.

The alternative to an in-app updater is telling users to download a new DMG. In
practice that means most installations stay on the version they were first
installed with, including versions with known bugs.

Writing an updater by hand means downloading over TLS, verifying the download,
replacing a running application bundle, and relaunching it. The bundle
replacement in particular is where a naive implementation leaves users with a
broken install.

Sparkle is the established framework for this. It verifies both the Apple code
signature and an EdDSA signature over the archive, and it performs the swap and
relaunch through helper processes designed for it.

---

## Decision

The application embeds Sparkle and starts a `SPUStandardUpdaterController` at
launch. Checks run automatically every hour and on demand from the settings
screen.

The feed is an `appcast.xml` served raw from the `main` branch of the repository,
regenerated and signed by the release pipeline. The public EdDSA key is injected
into the bundle at build time.

The updater refuses to start when the bundle identifier, the feed URL or the
public key is missing, and reports that updates are unavailable instead.

---

## Consequences

Users get fixes without being asked to do anything, which is the entire point.

Update integrity now rests on two secrets and one URL, none of which can be
changed freely afterwards. The bundle identifier, the feed URL, the EdDSA key and
the Developer ID certificate become a compatibility contract with every installed
copy. Sparkle explicitly forbids rotating the certificate and the EdDSA key in
the same release. See [Updates](../Updates.md).

Losing the EdDSA private key means no installed copy can ever be updated again.

Hosting the feed in the repository costs nothing and adds no infrastructure, but
ties update delivery to GitHub being reachable.

Sparkle brings helper executables and XPC services inside the bundle, each of
which must be signed and timestamped correctly or the update fails on the user's
machine rather than in CI. The release pipeline checks them individually for that
reason. See [Packaging](../Packaging.md).

A build without the key cannot check for updates at all, which is deliberate: a
development build must never replace itself with a release.
