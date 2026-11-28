#!/usr/bin/env bash
set -euo pipefail

repo="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/noor-adventure.XXXXXX")"
trap 'rm -rf -- "$scratch"' EXIT

# Build separately from existing signed APKs and ignore local authoring files.
(
  cd "$repo"
  git ls-files -z --cached --others --exclude-standard -- \
    .metadata android assets lib pubspec.yaml pubspec.lock |
    tar --null -cf - -T -
) | tar -xf - -C "$scratch"

(
  cd "$scratch"
  flutter pub get --offline --enforce-lockfile
  ORG_GRADLE_PROJECT_noorAdventurePlaytest=true flutter build apk \
    --release --no-pub --target lib/adventure_main.dart \
    --dart-define=NOOR_ADVENTURE_PLAYTEST=true --build-name=0.2.0 --build-number=1
)

output="$repo/build/playtest/noor-adventure-0.2.0.apk"
mkdir -p "$(dirname "$output")"
install -m 644 "$scratch/build/app/outputs/flutter-apk/app-release.apk" "$output"
printf '%s\n' "$output"
