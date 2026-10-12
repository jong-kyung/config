#!/usr/bin/env bash
set -euo pipefail
scripts="$(cd "$(dirname "$0")" && pwd)"
fixtures="$(mktemp -d)"
trap 'rm -rf "$fixtures"' EXIT
mkdir "$fixtures/bin" "$fixtures/packages"
touch "$fixtures/packages/oxlint-plugin.tgz" "$fixtures/packages/vp-config.tgz"
export PUBLISH_LOG="$fixtures/published"
export MOCK_PUBLISHED='' MOCK_CURRENT='' MOCK_ERROR='' MOCK_FAIL_PRESET=''

# The real publish script runs against a fake registry and never publishes packages.
cat > "$fixtures/bin/npm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  view)
    if [ -n "$MOCK_ERROR" ]; then echo 'Network failure' >&2; exit 2; fi
    if [[ "$2" == *@0.2.0 ]]; then
      if [ "$MOCK_PUBLISHED" = both ] || { [ "$MOCK_PUBLISHED" = plugin ] && [[ "$2" == */oxlint-plugin@* ]]; }; then
        echo 0.2.0
        exit 0
      fi
    elif [ -n "$MOCK_CURRENT" ] && [[ "$2" == */vp-config@* ]]; then
      echo "$MOCK_CURRENT"
      exit 0
    fi
    echo 'npm error E404' >&2
    exit 1
    ;;
  publish)
    if [ -n "$MOCK_FAIL_PRESET" ] && [ "$2" = vp-config.tgz ]; then exit 2; fi
    printf '%s\n' "$2" >> "$PUBLISH_LOG"
    ;;
  *) exit 2 ;;
esac
SH
chmod +x "$fixtures/bin/npm"
export PATH="$fixtures/bin:$PATH"

bash "$scripts/publish-packages.sh" 0.2.0 "$fixtures/packages"
[ "$(<"$PUBLISH_LOG")" = $'oxlint-plugin.tgz\nvp-config.tgz' ]

export MOCK_PUBLISHED=plugin
: > "$PUBLISH_LOG"
bash "$scripts/publish-packages.sh" 0.2.0 "$fixtures/packages"
[ "$(<"$PUBLISH_LOG")" = vp-config.tgz ]

export MOCK_PUBLISHED=both
: > "$PUBLISH_LOG"
bash "$scripts/publish-packages.sh" 0.2.0 "$fixtures/packages"
[ ! -s "$PUBLISH_LOG" ]

export MOCK_PUBLISHED='' MOCK_CURRENT=0.3.0
if bash "$scripts/publish-packages.sh" 0.2.0 "$fixtures/packages"; then
  echo 'Accepted an outdated release.' >&2
  exit 1
fi
[ ! -s "$PUBLISH_LOG" ]

export MOCK_CURRENT='' MOCK_ERROR=1
if bash "$scripts/publish-packages.sh" 0.2.0 "$fixtures/packages"; then
  echo 'Treated a registry failure as an unpublished version.' >&2
  exit 1
fi
[ ! -s "$PUBLISH_LOG" ]

export MOCK_ERROR='' MOCK_FAIL_PRESET=1
if bash "$scripts/publish-packages.sh" 0.2.0 "$fixtures/packages"; then
  echo 'Ignored a failed publish.' >&2
  exit 1
fi
[ "$(<"$PUBLISH_LOG")" = oxlint-plugin.tgz ]

echo 'Workspace publication checks passed.'
