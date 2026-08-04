| Field | Value |
| --- | --- |
| **Identifier** | ADR-0016 |
| **Date** | 2026-08-04 |
| **Status** | Accepted |

---

## Context

The Xcode project adopted in
[ADR-0011](<0011 - An Xcode project as the build system.md>) lists every source
file individually. Thirty files produce a 674-line `project.pbxproj` in which
each one appears twice, as a file reference and as a build phase entry, both
keyed by a generated identifier.

Two consequences follow. Moving or renaming a file means editing that file by
hand, and an omission produces a source file that is simply not compiled, with no
error. And the same file carries every build setting, duplicated across six
configuration blocks, where a change is neither readable nor reviewable in a
diff.

That cost is what has made reorganising the code feel risky, which is how a
codebase ends up being rewritten instead of reorganised.

Xcode 16 introduced synchronized groups, which reference a directory instead of a
list of files: adding a file to the directory adds it to the target, with an
exception mechanism for the cases that need it. Apple introduced them
specifically to shrink the project file and remove this class of conflict.

XcodeGen and Tuist solve the same problem by generating the project from a
manifest. Both add a tool that has to be installed locally and in CI, and kept
current with Xcode.

---

## Decision

The source directory and the test directory become synchronized folders. Neither
target lists files any more.

Build settings move out of the project into `.xcconfig` files: one shared, one
per configuration, one per target. Values that must stay overridable on the
command line, `SPARKLE_PUBLIC_ED_KEY` and the version, remain so.

No third-party project generator is adopted. Synchronized folders are an Apple
feature that requires nothing to be installed.

The conversion changes no source file and no build output. It is verified by
diffing `xcodebuild -showBuildSettings` against the same command before the
change.

---

## Consequences

Moving code becomes free, which is what makes the rest of the cleanup in
[Roadmap](../Roadmap.md) possible at all. Adding a file requires no project
edit, so a file can no longer be silently left out of the build.

Build settings become reviewable text. A change to the deployment target or the
hardened runtime shows up in a diff as one line.

The project file stops being a merge conflict surface, and stops being something
a contributor can break by opening Xcode.

The floor rises to Xcode 16, which is already required by the language mode in
use, so nothing is lost there.

Fine-grained per-file control is given up. A file that must be excluded from a
target now needs an explicit exception in the project rather than simply not
being listed, which is more obscure when it happens, and rarer.

Tooling that parses `.pbxproj` and predates Xcode 16 will not understand the new
group type. Nothing in this repository does.
