#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."

packages="$(mktemp -d)"
trap 'rm -rf "$packages"' EXIT
vp run build
(cd packages/oxlint-plugin && vp pm pack --out "$packages/oxlint-plugin.tgz")
(cd packages/vp-config && vp pm pack --out "$packages/vp-config.tgz")
bash .github/scripts/smoke-package.sh "$packages/oxlint-plugin.tgz" "$packages/vp-config.tgz"
