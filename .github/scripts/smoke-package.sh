#!/usr/bin/env bash
set -euo pipefail

plugin="${1:?Pass the plugin tarball path or npm package spec}"
preset="${2:?Pass the preset tarball path or npm package spec}"
consumer="$(mktemp -d)"
trap 'rm -rf "$consumer"' EXIT
cd "$consumer"
npm init --yes >/dev/null
npm pkg set type=module
npm install --ignore-scripts --no-audit --no-fund "$plugin" oxlint@1.85.0 typescript@7.0.2
node --input-type=module <<'NODE'
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import plugin from '@jong-kyung/oxlint-plugin';

assert.throws(() => import.meta.resolve('vite-plus'), { code: 'ERR_MODULE_NOT_FOUND' });
assert.equal(plugin.meta.name, 'jong-kyung');
assert.equal(Object.keys(plugin.rules).length, 21);
const manifest = JSON.parse(readFileSync(new URL(import.meta.resolve('@jong-kyung/oxlint-plugin/package.json')), 'utf8'));
assert.deepEqual(manifest.dependencies, { '@oxlint/plugins': '1.79.0' });
assert.equal(manifest.peerDependencies, undefined);

writeFileSync('types.ts', `import plugin from '@jong-kyung/oxlint-plugin';\nexport const rules = plugin.rules;\n`);
writeFileSync('tsconfig.json', JSON.stringify({
  compilerOptions: { module: 'nodenext', target: 'es2023', strict: true, noEmit: true, skipLibCheck: false },
  files: ['types.ts'],
}));
const types = spawnSync('./node_modules/.bin/tsc', ['-p', 'tsconfig.json'], { encoding: 'utf8' });
assert.equal(types.status, 0, types.stdout + types.stderr);

const config = {
  categories: { correctness: 'off' },
  plugins: [],
  jsPlugins: [{ name: 'jong-kyung', specifier: '@jong-kyung/oxlint-plugin' }],
  rules: {},
};
writeFileSync('valid.ts', 'export const value = { value: 1 }.value;\n');
writeFileSync('invalid.ts', 'Reflect.get({ value: 1 }, "value");\n');
writeFileSync('fix.ts', '// Returns a value.\nexport function value() { return 1; }\n');

function lint(filename, ...flags) {
  writeFileSync('.oxlintrc.json', JSON.stringify(config));
  const result = spawnSync('./node_modules/.bin/oxlint', ['--config', '.oxlintrc.json', '--threads=1', filename, ...flags], {
    encoding: 'utf8', env: { ...process.env, CI: undefined, NO_COLOR: '1', FORCE_COLOR: '0' },
  });
  assert.ifError(result.error);
  return result;
}

assert.equal(lint('invalid.ts').status, 0, 'Registering the plugin must not enable rules');
config.rules = { 'jong-kyung/no-reflect-get': 'error', 'jong-kyung/prefer-jsdoc': 'error' };
assert.equal(lint('valid.ts').status, 0);
const invalid = lint('invalid.ts');
assert.equal(invalid.status, 1, invalid.stdout + invalid.stderr);
assert.match(invalid.stdout, /jong-kyung\(no-reflect-get\)/);
const fixed = lint('fix.ts', '--fix');
assert.equal(fixed.status, 0, fixed.stdout + fixed.stderr);
assert.equal(readFileSync('fix.ts', 'utf8'), '/** Returns a value. */\nexport function value() { return 1; }\n');
console.log(`Verified ${manifest.name}@${manifest.version} with Oxlint 1.85.0 and no Vite+.`);
NODE

# Match the release npm version; npm 10 crashes resolving Vite+'s peer graph.
npx --yes npm@11.13.0 install --ignore-scripts --no-audit --no-fund "$preset" @types/node@26.6.4
node --input-type=module <<'NODE'
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { nodeConfig, libConfig } from '@jong-kyung/vp-config';
import compatibilityPlugin from '@jong-kyung/vp-config/plugin';
import plugin from '@jong-kyung/oxlint-plugin';

const manifestPath = fileURLToPath(import.meta.resolve('@jong-kyung/vp-config/package.json'));
const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
const pluginManifest = JSON.parse(readFileSync(new URL(import.meta.resolve('@jong-kyung/oxlint-plugin/package.json')), 'utf8'));
assert.equal(manifest.name, '@jong-kyung/vp-config');
assert.equal(manifest.version, pluginManifest.version);
assert.equal(manifest.dependencies['@jong-kyung/oxlint-plugin'], manifest.version);
assert.equal(manifest.peerDependencies['vite-plus'], '1.0.0');
for (const entry of ['.', './plugin']) {
  assert(existsSync(resolve(dirname(manifestPath), manifest.exports[entry].types)));
}
const lint = nodeConfig.lint.extends[0];
assert.equal(libConfig.lint, nodeConfig.lint);
assert.equal(compatibilityPlugin, plugin);
assert.equal((await import(lint.jsPlugins[0].specifier)).default, plugin);
for (const name of Object.keys(lint.rules).filter((name) => name.startsWith('jong-kyung/'))) {
  assert.equal(typeof plugin.rules[name.slice('jong-kyung/'.length)].create, 'function');
}
writeFileSync('types.ts', `import { nodeConfig, libConfig } from '@jong-kyung/vp-config';
import plugin from '@jong-kyung/vp-config/plugin';
import type { UserConfig } from 'vite-plus';
export const configs: UserConfig[] = [nodeConfig, libConfig];
export const rules = plugin.rules;
`);
writeFileSync('tsconfig.json', JSON.stringify({
  compilerOptions: { module: 'nodenext', target: 'es2023', strict: true, noEmit: true, skipLibCheck: true },
  files: ['types.ts', 'valid.ts', 'invalid.ts'],
}));
const types = spawnSync('./node_modules/.bin/tsc', ['-p', 'tsconfig.json'], { encoding: 'utf8' });
assert.equal(types.status, 0, types.stdout + types.stderr);
writeFileSync('vite.config.ts', `import { nodeConfig } from '@jong-kyung/vp-config';\nexport default nodeConfig;\n`);
const result = spawnSync('./node_modules/.bin/vp', ['lint', '--threads=1', 'invalid.ts'], {
  encoding: 'utf8', env: { ...process.env, CI: undefined, NO_COLOR: '1', FORCE_COLOR: '0' },
});
assert.equal(result.status, 1, result.stdout + result.stderr);
assert.match(result.stdout, /jong-kyung\(no-reflect-get\)/);
console.log(`Verified ${manifest.name}@${manifest.version}, compatibility export, types and Vite+ lint.`);
NODE
