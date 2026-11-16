// Production build config used only by the Dockerfile.
// It mirrors the project's own vite.config.ts, but without the development-only plugins
// (ESLint, Istanbul code coverage) so the Docker build stays fast and reliable.
import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "VITE");
  return {
    // expose all "VITE_*" variables as process.env.VITE_* in the browser (same as the original config)
    define: {
      "process.env": env,
    },
    build: {
      outDir: "build",
      sourcemap: false,
    },
    plugins: [react()],
    resolve: {
      alias: [
        {
          find: "./runtimeConfig",
          replacement: "./runtimeConfig.browser",
        },
      ],
    },
  };
});