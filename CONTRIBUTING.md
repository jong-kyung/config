# Contributing

## Setup

Use the Node version in `.node-version`, which also selects the CI runtime. Install the global Vite+ CLI and Git, then install dependencies:

```bash
vp install
```

Both packages use the existing Vite+ Node support range. Package manager settings are in the private root `package.json`. Workspace packages and shared dependency versions are in `pnpm-workspace.yaml`.

## Make changes

Add regression cases in `tests/` when changing a rule. Custom rules and analysis helpers live in `packages/oxlint-plugin/src/`. Vite+ presets and rule settings live in `packages/vp-config/src/`. The Vite+ package depends on the plugin and preserves its original `./plugin` export. The private root manifest records the shared release version. Both package manifests must match it, which is checked by `tests/packages.test.ts`.

Run these checks before submitting changes:

```bash
vp run build
vp check
vp run knip
vp run duplication --baseline-from-ref origin/main
vp test
vp run test:packages
bash .github/scripts/test-release-version.sh
bash .github/scripts/test-publish-packages.sh
```

Knip checks unused files, exports, and dependencies. The duplication command scans package source against the supplied Git ref. Existing clones are allowed. New clones or an unavailable baseline fail the check. Tests are outside the duplication scope.

## Tests and snapshots

Vitest discovers `tests/**/*.test.ts` through `vite.config.ts`. Each custom rule has a file in `tests/rules/`. Define its valid and invalid inputs once and run them with the shared RuleTester in `tests/helpers/rule-tester.ts`. Keep options, declaration filenames, local-analysis boundaries, directives, and exact line endings in regression cases. Remove a case only when its input, options, and verification purpose duplicate another case.

Public preset settings, including native severities and options, are captured together in `tests/__snapshots__/index.test.ts.snap`. Only the checkout-specific plugin path is normalized. Keep explicit assertions for relationships such as plugin registration completeness, shared method identity, and unchanged output.

The `no-runtime-typeof` and `prefer-jsdoc` suites also run the same inputs through the installed `vp lint` CLI. This is a limited snapshot pilot, not a replacement for RuleTester. Each suite writes its inputs to a temporary directory under `node_modules`, activates only the tested rule through native Vite+ overrides, and cleans up afterward. It does not build or install a consumer package and needs no network after dependency installation.

Diagnostic snapshots contain Vite+'s default error output, including source lines, underlines, messages, and error counts. Each invalid case is rendered separately so no custom diagnostic parser or renderer is needed. Valid cases run together and share the expected zero-error summary. Color is disabled, line endings and the code-frame filename are normalized, and the variable timing footer is removed. The lint subprocess unsets `CI` to prevent Oxlint from forcing a different colored Unicode theme. The test runner keeps its CI behavior, including failing on missing or outdated snapshots. Expected fixes have separate source snapshots. All snapshots are external `.snap` files managed by the built-in `vp test` runner.

Original diagnostics are collected before `--fix`, because that command reports only remaining issues. Fix passes are batched across the suite. Explicit comparisons against the shared RuleTester expectations preserve error counts, unchanged code, exact CRLF bytes, and fixed output. A second fix run must leave the output unchanged. CLI fixing may apply multiple passes, so it is compared with RuleTester's default single-pass expectation rather than assumed equivalent.

Review snapshot diffs as behavior changes. Update only the affected suite after checking its inputs and intended results, then rerun without update mode:

```bash
vp test tests/rules/prefer-jsdoc.test.ts --update
vp test tests/rules/prefer-jsdoc.test.ts
```

Keep the pilot limited to these two rules until diagnostic accuracy, repeatability, runtime, and maintenance cost have been evaluated. The CLI helper currently supports code, names, options, numeric error counts, and optional fixed output. Extend its contract explicitly before using cases with custom filenames, parser settings, or hooks.

`vp run test:packages` builds and packs both workspace packages, then installs the tarballs in a temporary project outside this workspace. It checks plugin imports and declarations without Vite+, explicit rule activation, diagnostics and autofixes with Oxlint 1.85.0. It then installs the Vite+ package and verifies the compatibility export, shared version, declarations and actual preset linting. This check needs registry access. Consumer library builds and Git staging behavior remain outside the test suite.

To inspect the package without publishing:

```bash
vp run build
(cd packages/oxlint-plugin && vp pm pack --out /tmp/oxlint-plugin.tgz)
(cd packages/vp-config && vp pm pack --out /tmp/vp-config.tgz)
```

## CI

CI builds both packages and runs `vp check`, Knip, Vitest, packed-consumer checks, and release-script checks on PRs, main pushes, manual runs, and Sundays at 02:00 UTC. Duplication checks run on PRs and main pushes.

[autofix.ci](https://autofix.ci/setup) receives changed file contents and commits fixes to PRs when its GitHub App is enabled. The workflow excludes `.github` paths from automatic fixes.

## Releases

The Prepare Release workflow updates the private root and both package manifests to the same version. Merging its release PR triggers checks, builds both tarballs, and verifies them before the release environment approval gate. The release workflow publishes `@jong-kyung/oxlint-plugin` first, then `@jong-kyung/vp-config`. Packing converts `workspace:*` into the exact shared plugin version. One `vVERSION` tag and GitHub release describe both packages.

Configure npm trusted publishing for both package names to use `.github/workflows/release.yml` and the `release` environment. The new plugin package may require an authorized first publication before trusted publishing can be configured. Local validation does not create packages or configure npm permissions.

npm does not publish multiple packages atomically. If publication stops after one package succeeds, rerun the failed release jobs for the same commit. The publication script skips existing versions and checks both dist-tags before publishing missing packages. It does not move tags backward. Its local test substitutes a fake npm registry and verifies ordering, partial-release recovery, already-published versions, stale versions and failure handling without publishing anything.
