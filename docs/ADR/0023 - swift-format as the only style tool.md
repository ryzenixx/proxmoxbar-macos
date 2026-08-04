| Field | Value |
| --- | --- |
| **Identifier** | ADR-0023 |
| **Date** | 2026-08-04 |
| **Status** | Accepted |

---

## Context

There is no formatter and no linter. Formatting is whatever the author's editor
produced, which is visible in the existing files as inconsistent blank lines and
trailing whitespace.

Two tools are available.

SwiftLint is a rule engine covering style and a number of correctness-adjacent
checks. It is a third-party binary that has to be installed locally and in CI,
and kept current with each Swift release.

swift-format ships inside the Swift 6 toolchain. There is nothing to install: it
is present wherever the compiler is, including on a CI runner and in Xcode, which
can format a file with it directly. It formats, and it also lints against its own
rule set with `swift-format lint`.

For a one-person project the question is not which has more rules. It is which
one will still be working in a year without maintenance.

---

## Decision

swift-format is the only style tool. Configuration lives in `.swift-format` at
the repository root, checked in.

CI runs `swift-format lint --strict --recursive` and fails on a violation.
Formatting is not applied automatically in CI; a violation is the author's to
fix, so a diff never contains changes nobody wrote.

SwiftLint is not adopted. The correctness rules that would justify a second tool
are covered by the Swift 6 language mode and by the compiler warnings already
enabled.

Style rules that a formatter cannot express — naming, file organisation, what
belongs in which layer — are written in
[Code Conventions](<../Code Conventions.md>) and enforced by review, not by a
tool pretending to.

---

## Consequences

Nothing to install, for a contributor or for CI. The toolchain that compiles the
code also formats it, so the two can never be out of step.

Formatting stops being a review topic.

swift-format's rule set is narrower than SwiftLint's, and its opinions are not
configurable in the same way. Some things SwiftLint would have caught — force
unwrapping, for instance — are not caught here. That is accepted: the rule
against force unwrapping is in the conventions and in review, and the compiler
catches the cases that matter.

The first run reformats nearly every file. That commit is made on its own, with
no other change in it, so it can be skipped in `git blame` and never has to be
read.

Adopting a tool that is not the community default means a contributor who runs
SwiftLint out of habit will see complaints that this project does not care about.
The configuration file being checked in is what makes that unambiguous.
