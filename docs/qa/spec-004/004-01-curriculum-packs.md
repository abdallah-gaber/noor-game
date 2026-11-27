# 004-01 curriculum ingestion verification

Verified 27 November 2026 on the SPEC-004 implementation branch. The branch starts at the regular [SPEC-003 merge](https://github.com/abdallah-gaber/noor-game/commit/f0897040c17a589925a06dfa8b0cadcf0e2a2636), whose second parent is the reviewed PR #3 head, `b0f09896bd9809c7c401e7c6e27db7a19b9484cc`. The published [spec-003-complete tag](https://github.com/abdallah-gaber/noor-game/tree/spec-003-complete) resolves to the merge. The stable Mission Control dashboard served that same main snapshot with 13 of 25 tasks verified.

## Automated verification

| Check | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | 50 files checked, no changes |
| `flutter analyze --no-pub` | No issues |
| `flutter test --no-pub` | 84 passed, including six curriculum pack tests |
| `python3 -m unittest discover -s scripts -p 'test_*.py'` | 5 Mission Control tests passed |
| `python3 scripts/content_inventory.py --check` | Export matches the four local canonical draft packs |
| `flutter build apk --release --no-pub` | Android release APK built and inspected |
| `flutter build ios --simulator --no-codesign --no-pub` | iOS simulator app built |

The tests cover all five mechanics, ambiguous answers, duplicate or unresolved IDs, cross-world prerequisites and cycles, prayer-readiness ordering, and the exact record and media gate. They cover independent pack updates and retaining resumed progress, historical attempts and completion across compatible changes. They also exercise the default application route when a bundled candidate is missing or invalid. The separately supplied test approvals exist only in-memory for synthetic fixture records. See the [schema contract and examples](../../curriculum/pack-schema.md).

## Release smoke test

The Android release APK was tested offline in landscape on the Medium Tablet emulator, Android API 35, 2560 × 1600 at 320 dpi. ADB confirmed that there was no active default network. A direct link to the synthetic lesson fell back to the worship world and displayed the Arabic lesson-preparation state. A developer challenge deep link returned to the public worlds screen. The accessibility tree contained the expected public labels. The APK archive contained no curriculum asset namespace, fixture pack or approval fixture. Its SHA-256 was `666d3f10b9465e881bd31fa8ae1d21e0fb0094004dc4dfebd7096b7a65ed6167`.

[Offline Android tablet capture](release-world.webp)

## Curriculum status

The provisionally accepted draft inventory remains 60 lessons, 180 knowledge units and 600 question variants. Zero records were finally approved or integrated by this task. Physical-tablet performance and religious source or rights review remain outside this infrastructure checkpoint. CONTENT-006 and CONTENT-007 remain in the separate authoring track.
