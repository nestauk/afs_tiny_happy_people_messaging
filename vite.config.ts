import vue from "@vitejs/plugin-vue";
import { defineConfig } from "vite";
import Rails from "vite-plugin-rails";

export default defineConfig(({ mode }) => {
  if (mode === "test") {
    return {
      plugins: [Rails({ compress: false }), vue()],
      server: {
        allowedHosts: ["vite-test"],
        host: "0.0.0.0",
        port: 3037,
        hmr: {
          host: "vite-test",
        },
      },
    };
  }

  return {
    plugins: [Rails(), vue()],
    server: {
      allowedHosts: ["vite"],
      host: "0.0.0.0",
    },
  };
});
