#!/usr/bin/env bash
set -euo pipefail

version="${1:?Pass the shared version}"
directory="${2:?Pass the tarball directory}"
scripts="$(cd "$(dirname "$0")" && pwd)"
tag="$(bash "$scripts/release-version.sh" "$version")"
error="$(mktemp)"
trap 'rm -f "$error"' EXIT
# Keep npm outside the checkout's pnpm-only devEngines policy.
cd "$directory"

npm_version() {
  if npm view "$1" version 2>"$error"; then
    return 0
  elif grep -q 'E404' "$error"; then
    return 0
  fi
  cat "$error" >&2
  return 1
}

pending=()
# Check both tags before publishing either package, including out-of-order approvals.
for package in oxlint-plugin vp-config; do
  published="$(npm_version "@jong-kyung/$package@$version")"
  if [ -n "$published" ]; then
    echo "@jong-kyung/$package@$version is already published."
    continue
  fi
  current="$(npm_version "@jong-kyung/$package@$tag")"
  bash "$scripts/release-version.sh" "$version" "$current" >/dev/null
  test -f "$package.tgz"
  pending+=("$package")
done

# Publish the dependency first. A rerun skips packages that already succeeded.
if [ "${#pending[@]}" -gt 0 ]; then
  for package in "${pending[@]}"; do
    npm publish "$package.tgz" --access public --tag "$tag" --provenance --ignore-scripts
  done
fi
