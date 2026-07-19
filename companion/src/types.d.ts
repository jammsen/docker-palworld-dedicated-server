// esbuild bundles .css imports as plain text (see build.mjs loader config)
declare module "*.css" {
  const content: string;
  export default content;
}
