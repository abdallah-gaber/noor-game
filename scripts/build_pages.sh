#!/usr/bin/env bash
set -euo pipefail

site=${1:?Usage: build_pages.sh SITE MAIN_SHA [PREVIEW_SHA]}
main_sha=${2:?Missing main commit}
preview_sha=${3:-}
source_dir=$(mktemp -d)
trap 'rm -rf "$source_dir"' EXIT
mkdir -p "$source_dir/main" "$source_dir/preview"
mkdir -p "$site"
if [[ -n "$(ls -A "$site")" ]]; then
  echo "Pages output directory must be empty" >&2
  exit 1
fi

generate() {
  local snapshot=$1 branch=$2 sha=$3 destination=$4
  shift 4
  git archive "$sha" | tar -xf - -C "$snapshot"
  python3 scripts/generate_dashboard.py --root "$snapshot" --pages-dir "$destination" \
    --source-branch "$branch" --source-sha "$sha" \
    --updated-at "$(git show -s --format=%cI "$sha")" "$@"
}

if [[ -n "$preview_sha" ]]; then
  generate "$source_dir/preview" docs/season-one-mission-control "$preview_sha" "$site/previews/season-one"
  generate "$source_dir/main" main "$main_sha" "$site" --preview-link
else
  generate "$source_dir/main" main "$main_sha" "$site"
fi
touch "$site/.nojekyll"
