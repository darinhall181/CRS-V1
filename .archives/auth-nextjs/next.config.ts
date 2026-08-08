import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  turbopack: {
    // www/bun.lock above this dir causes Turbopack to detect the wrong
    // workspace root and resolve node_modules from www/ (Next.js 14).
    root: path.resolve(__dirname),
  },
};

export default nextConfig;
