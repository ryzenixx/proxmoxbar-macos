This page describes how ProxmoxBar updates itself, and what must never change for
that to keep working.

---

## How it works

The app embeds Sparkle. On launch it starts a standard updater, which checks the
feed once an hour and on demand from the settings screen.

The feed is `appcast.xml`, served raw from the `main` branch of the repository.
Each entry points at the DMG attached to the corresponding GitHub release and
carries an EdDSA signature over that file.

An update is installed only when both verifications pass: Apple's code signature
on the downloaded app, and the EdDSA signature on the archive. See
[ADR-0005](<ADR/0005 - Sparkle for in-app updates.md>).

---

## The updater is optional at runtime

`UpdaterController` refuses to start when the bundle has no identifier, no feed
URL, or an empty public key. It then reports that updates are unavailable instead
of failing later.

That is what makes a local build safe: `SPARKLE_PUBLIC_ED_KEY` is empty outside
the release pipeline, so a development build never checks the feed and can never
replace itself with a release. See [Configuration](Configuration.md).

---

## What must never change

Every item below is load-bearing for installed copies of the app. Changing one
does not break the build, it breaks updates on machines you cannot reach.

| Item | Value | If it changes |
| --- | --- | --- |
| `CFBundleIdentifier` | `com.proxmoxbar.app` | The new build is a different app; the old one keeps updating itself |
| `SUFeedURL` | Raw `appcast.xml` on `main` | Installed copies keep polling the old URL forever |
| EdDSA public key | The one embedded at build time | Signature verification fails and the update is refused |
| Developer ID certificate | The current one | Sparkle refuses an update signed by a different team, **and** macOS prompts every user for keychain access |
| `PRODUCT_NAME` | `ProxmoxBar` | Sparkle's helper paths inside the bundle no longer resolve |
| Minimum system version | `14.0` in the appcast and the build | Raising it silently stops offering updates to users below it |

**The Apple certificate and the EdDSA key can never be rotated in the same
release.** Sparkle trusts a change of EdDSA key because the Apple code signature
still matches, and trusts a change of certificate because the EdDSA signature
still verifies. Changing both at once leaves nothing to anchor the trust, and
every installed copy stops updating.

If both must change, ship two releases and let users pass through the
intermediate one.

The certificate carries a second consequence that has nothing to do with Sparkle.
Keychain items are bound to the creating application's designated requirement,
which derives from its signature, so a build signed by a different identity makes
macOS ask each user to authorise access to their own stored tokens. A certificate
change therefore needs a release note explaining that dialog, or users will
refuse it and lose their credentials. See
[Data & Persistence](<Data & Persistence.md>) and
[ADR-0020](<ADR/0020 - Token secrets in the data protection keychain.md>).

---

## The Sparkle version lives in two places

The framework is a package dependency of the app. `generate_appcast`, which signs
the feed, is downloaded by the release workflow from `SPARKLE_TOOLS_VERSION`.

Both must be bumped together. A feed signed by one version of the tools and read
by another version of the framework is a failure mode that only appears after a
release is published.

---

## The private key

The EdDSA private key is stored as a repository secret and exists nowhere else.

Losing it means no future release can ever be signed for the existing feed, and
every installed copy has to be replaced by hand. Rotating it, as above, requires
an intermediate release while the current Developer ID certificate is still in
use.

Back it up outside GitHub.

---

## Version numbers

Versions come from the git tag, in `vX.Y.Z` form, and are injected into
`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` at build time. Sparkle compares
`CFBundleVersion`, so both must move together, which they do because both are set
from the same value.

Versions only ever go up. A tag that is not an ancestor of `main` is rejected
before anything is built. See [Packaging](Packaging.md).

---

## Verifying a release reached users

After a release, the checks worth doing:

1. `curl` the feed URL and confirm the new item is present and signed.
2. Confirm the DMG URL in the enclosure resolves to the release asset.
3. Install the previous version, run it, and let it update itself. This is the
   only check that exercises signature verification, the helper signatures and
   the relaunch, which are exactly the parts that fail silently.
