import { build } from "esbuild";
import { cp, mkdir, readFile } from "node:fs/promises";

const pkg = JSON.parse(await readFile("package.json", "utf8"));

await mkdir("dist", { recursive: true });

await build({
  entryPoints: ["src/index.ts"],
  outfile: "dist/companion.mjs",
  bundle: true,
  platform: "node",
  format: "esm",
  target: "node22",
  sourcemap: false,
  minify: false,
  define: {
    COMPANION_VERSION: JSON.stringify(pkg.version),
  },
  // Some transitive CJS dependencies expect require() to exist in ESM output
  banner: {
    js: "import { createRequire } from 'node:module'; const require = createRequire(import.meta.url);",
  },
});

await cp("public", "dist/public", { recursive: true });

console.log(`palworld-companion ${pkg.version} bundled to dist/companion.mjs`);
