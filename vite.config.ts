import { mergeConfig } from "vite-plus";
import { nodeConfig } from "./packages/vp-config/src/index.ts";

export default mergeConfig(
  {
    ...nodeConfig,
    // Replace inherited lint to load source without requiring an earlier package build.
    lint: {
      ...nodeConfig.lint.extends[0],
      jsPlugins: [{ name: "jong-kyung", specifier: "./packages/oxlint-plugin/src/index.ts" }],
    },
  },
  {
    staged: { "*": "vp check --fix" },
    test: {
      include: ["tests/**/*.test.ts"],
    },
  },
);
