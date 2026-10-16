# @jong-kyung/vp-config

Shared Vite+ presets for Node applications and TypeScript libraries. Includes `@jong-kyung/oxlint-plugin` and its configured rules.

```bash
vp add -D --save-exact @jong-kyung/vp-config vite-plus@1.0.0
```

In `vite.config.ts`:

```ts
import { nodeConfig } from "@jong-kyung/vp-config";

export default nodeConfig;
```

Use `libConfig` for library packaging defaults. The `@jong-kyung/vp-config/plugin` export remains available for compatibility. Projects without Vite+ can install `@jong-kyung/oxlint-plugin` directly.

See the [usage and rule guide](https://github.com/jong-kyung/config#readme) for customization and all rules.
