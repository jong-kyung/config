import { expect, test } from "vite-plus/test";
import workspace from "../package.json" with { type: "json" };
import plugin from "../packages/oxlint-plugin/package.json" with { type: "json" };
import preset from "../packages/vp-config/package.json" with { type: "json" };

test("releases both packages at the shared workspace version", () => {
  expect(workspace.private).toBe(true);
  expect(plugin.version).toBe(workspace.version);
  expect(preset.version).toBe(workspace.version);
  expect(preset.dependencies["@jong-kyung/oxlint-plugin"]).toBe("workspace:*");
});
