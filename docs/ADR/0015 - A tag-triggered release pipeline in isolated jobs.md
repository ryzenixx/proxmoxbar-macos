| Field | Value |
| --- | --- |
| **Identifier** | ADR-0015 |
| **Date** | 2026-03-11 |
| **Status** | Accepted |

---

## Context

Releasing meant building, signing, packaging, notarizing, generating the appcast
and publishing, as one long sequence. Notarization is the slowest step and the
one that fails most often, for reasons that have nothing to do with the code:
a rejected submission, an expired credential, a slow notary service.

When it failed, everything before it was rebuilt from scratch, and the signed
artifact that had been produced successfully was gone.

The version was also duplicated: in the project, in a script, and in the tag.
They disagreed more than once.

---

## Decision

Pushing a tag matching `vX.Y.Z` runs the pipeline, which can also be started
manually against an existing tag.

A preflight job validates first: the tag must match the version pattern, must
exist, and must be an ancestor of `origin/main`. A release cannot be cut from an
unmerged branch.

The remaining work is one job per step — build and test, archive, package,
notarize, appcast, publish release, publish appcast — each consuming the previous
one's artifact.

Every step is a script in `scripts/release/`, called by the workflow rather than
written inline, and each validates the environment it needs and fails
immediately when something is missing.

The version exists only in the git tag, and is injected into the build.

---

## Consequences

A notarization failure costs a rerun of one job, and the signed artifact of a
failed run can be downloaded and inspected.

Any step can be run by hand, with the same environment variables, when it fails
in a way the logs do not explain. That is the main reason the logic is in scripts
rather than in the workflow.

The version can no longer disagree with the tag, because there is only one.

The pipeline is eight jobs, which is more machinery than a one-person project
would otherwise carry, and each handoff is an artifact upload and download. A
release takes longer end to end than a single sequential job would.

Requiring the tag to be on `main` means a hotfix has to be merged before it can
ship, which is the intended constraint and occasionally the annoying one.
