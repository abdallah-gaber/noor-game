# SPEC-004 starter release verification

Verified on 27 November 2026. The exact owner-approved request SHA-256 was
`8fee836f366522ee8393efe3530af1f157c2e738c6ea589085f925c5b9cfcf41`.
The trusted ledger matches all four pack identities and 112 exact projected record digests. Eligibility checks matched supplied claim evidence to scoped locators, excluded individual unresolved targets, and limited supporting source use to the selected claims. [Starter scope and approval basis](../../curriculum/starter-release.md)

| Check | Result |
|---|---|
| Dart formatting and static analysis | 68 files formatted and analysis clean |
| Full Flutter regressions | 106 passed, including actual starter fixtures, all five mechanics through production UI, adaptive and daily rounds, Rewards, Parent Mode, resume, and preview isolation |
| Python suite and canonical check | 20 passed. Checked exact authorized bytes, guarded input edits, pending evidence, starter asset projection, and the sanitized inventory |
| SQLite migration probe | Schema-2 completions stayed in preview. Schema-4 snapshots survived with nullable dates. Schema-5 intervals migrated to preview while approved intervals remained separate |
| Android release APK | 52.7 MB, min API 24, arm64, armv7, x86-64. Existing development signing configuration |
| iOS simulator | Unsigned app built, installed and launched on iPad A16, iOS 27.0 |

The APK archive contains exactly the four production packs, index and ledger. The archive matches the tracked curriculum assets byte for byte. It contains no private draft bundle, final approval request, deferred lessons, memorization or treasures. Android's manifest has no Internet permission. APK SHA-256 is
`ab80f4f9a56c183db1f8bbb5d55a2abadf8c52b915382067c23ef28910976627`.

## Android runtime

Both isolated Android emulators had no active default network. On the Android 9 phone, the release rejected a deferred lesson deep link and the developer route. On the Android 15 tablet, a submitted approved answer survived force-stop and cold restart.

The tablet completed W05 and W06 in the installed release, covering multiple choice, true/false, flashcards, matching and ordering. The results showed Rewards after completion. The offline tablet also opened and populated Daily Challenges, Adaptive Review and Parent Mode. The iPad simulator rendered the starter home and learning-tool entries in its debug simulator build.

[Phone home](phone-starter-home.webp) · [Tablet results](tablet-starter-results.webp) · [Tablet Parent Mode](tablet-starter-parent.webp)
