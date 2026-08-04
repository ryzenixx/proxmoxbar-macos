| Field          | Value      |
| -------------- | ---------- |
| **Identifier** | ADR-0014   |
| **Date**       | 2026-03-11 |
| **Status**     | Accepted   |

---

## Context

Until version 2.0.4 the DMG was published unsigned. Gatekeeper refused to open
it, and the install instructions amounted to teaching users to bypass a security
warning. That is a bad thing to teach anyone, and worse for an audience that will
hand the app a credential to their infrastructure.

The Mac App Store would remove the problem and is not viable. A sandboxed app
cannot reach an arbitrary host on the local network the way this one must, the
app updates itself through Sparkle, which the store does not allow, and the
review cycle is incompatible with the release cadence.

Distributing outside the store therefore means Developer ID signing plus
notarization: Apple scans the binary and issues a ticket, which is stapled to the
DMG so Gatekeeper admits it without ever contacting Apple at open time.

Notarization requires the hardened runtime, and rejects anything in the bundle
that is unsigned or missing a trusted timestamp.

---

## Decision

Release builds enable the hardened runtime and are signed with a Developer ID
Application certificate, with manual signing and an explicit identity.

The exported app is verified before anything else happens: the signature is
checked, and the main executable plus each Sparkle helper — `Autoupdate`, the
updater application, and the downloader and installer XPC services — are
confirmed individually to carry a Developer ID authority and a trusted timestamp.

The DMG is signed in turn, submitted to `notarytool`, stapled, and assessed with
`spctl` both as a DMG and as the application mounted inside it. A rejected
submission prints the notary log before failing.

The application is not sandboxed.

---

## Consequences

Users double-click and the app opens. No warning, no right-click-open, no
instructions to disable a protection.

The helper checks exist because an unsigned or untimestamped Sparkle helper
passes a shallow verification and then fails at install time, on a machine nobody
can debug, after the update has already downloaded. Verifying each one in CI
turns that into a failed build.

Releasing now depends on an Apple Developer Program membership, a certificate
that expires, an app-specific password, and Apple's notary service being
available. Any of the four can block a release for reasons unrelated to the code.

The certificate becomes part of the update contract. Sparkle uses the code
signature to trust a change of EdDSA key, so the certificate and the key can
never be rotated in the same release. See [Updates](../Updates.md).

Not sandboxing is deliberate and keeps the Mac App Store closed as an option. It
also means the security boundary is the user account, which is stated plainly in
[Security](../Security.md).
