# Noor / نور

The Flutter foundation for an Arabic, tablet-first learning game.

Use Flutter **3.47.8 stable** with Dart **3.13.7**. The project pins both in `pubspec.yaml`, and FVM users can use the pin in `.fvmrc`.

```sh
flutter pub get
flutter run
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Open [Mission Control](docs/mission-control/index.html) for phase status and evidence. Regenerate it with `python3 scripts/generate_dashboard.py` after editing the canonical [progress data](docs/mission-control/progress.json). See [SPEC-001](specs/001-foundation/spec.md) for the acceptance criteria and [CODEX_START.md](CODEX_START.md) for the SDD workflow.

## Learning worlds

The Android and iOS app open to a four-world Arabic adventure map. Debug runs include a labeled, non-religious catalog for trying the player, lesson states and local resume. Profile and release builds show the public world shells while the approved catalog is empty. See [SPEC-002](specs/002-learning-worlds/spec.md) and the [emulator evidence](docs/qa/spec-002/002-04-verification.md).
