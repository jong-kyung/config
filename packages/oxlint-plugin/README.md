# @jong-kyung/oxlint-plugin

Custom Oxlint rules for TypeScript projects. Vite+ is not required.

```bash
npm install --save-dev @jong-kyung/oxlint-plugin oxlint@1.85.0
```

Register the plugin in `.oxlintrc.json` and enable the rules you need:

```json
{
  "jsPlugins": [{ "name": "jong-kyung", "specifier": "@jong-kyung/oxlint-plugin" }],
  "rules": { "jong-kyung/no-reflect-get": "error" }
}
```

Run `npx oxlint .`. Registration does not enable rules. The package exports a default plugin object without presets.

Verified with Oxlint 1.85.0. Requires Node `^22.18.0 || ^24.11.0 || >=26.0.0` and ESM.

See the [usage and rule guide](https://github.com/jong-kyung/vp-config#readme) for all rules and options.
