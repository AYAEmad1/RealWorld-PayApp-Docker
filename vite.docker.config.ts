
import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "VITE");
  return {
  
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