import { defineConfig } from "vite-plus";

export default defineConfig({
  pack: {
    entry: ["src/index.ts", "src/plugin.ts"],
    target: "node22.18",
    dts: { generator: "tsgo" },
    exports: false,
  },
});
