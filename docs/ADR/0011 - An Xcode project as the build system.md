| Field | Value |
| --- | --- |
| **Identifier** | ADR-0011 |
| **Date** | 2026-03-11 |
| **Status** | Accepted |

---

## Context

Until version 2.0.0 the application was assembled by shell scripts: compile,
build a bundle layout by hand, copy resources into it, write an Info.plist, sign
the result. There was no Xcode project in the repository.

That worked until it had to be signed, notarized and shipped with Sparkle inside
it. A bundle assembled by hand has to get the framework layout, the helper
signatures, the runtime search paths and the archive export exactly right, and
each of those failed at least once.

Swift Package Manager was considered and does not solve it. SPM builds
executables and libraries; it does not produce an application bundle, does not
handle an Info.plist, and has no notion of code signing or archiving. Producing a
signed `.app` from a package means recreating by hand exactly what the scripts
were already doing badly.

---

## Decision

The repository contains an Xcode project with two targets, the application and
its tests. Every build, local and CI, goes through `xcodebuild`.

Sparkle is declared as a Swift package dependency of the application target,
resolved by Xcode.

The legacy bundling scripts are deleted. The release scripts that remain call
`xcodebuild`, `codesign` and `notarytool`; none of them assembles a bundle.

---

## Consequences

Archiving, exporting, embedding frameworks and signing helpers are handled by the
tool that is designed for them, and the release pipeline stopped producing
bundles that failed on users' machines.

The `.pbxproj` becomes a file that has to be maintained and reviewed, and it is a
poor file for both. In its current form it lists every source file individually,
which makes moving code more expensive than it should be. That is addressed in
[ADR-0016](<0016 - Synchronized folders and xcconfig over a hand-listed project.md>),
not by abandoning Xcode.

Building requires Xcode, so CI needs a macOS runner and a contributor needs a
ten gigabyte install. There is no way around that for a signed macOS app.

Build settings live inside the project file rather than in something reviewable,
which is the second half of what ADR-0016 fixes.
