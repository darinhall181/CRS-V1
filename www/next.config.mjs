/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    remotePatterns: [
      // Cloudflare R2 — primary image CDN after running upload_images_to_r2.py
      { protocol: "https", hostname: "*.r2.dev" },
      // Canon USA CDN — fallback while images are still on manufacturer servers
      { protocol: "https", hostname: "**.canon.com" },
      { protocol: "https", hostname: "**.usa.canon.com" },
      // Generic fallback for any other scraped image host (http + https)
      { protocol: "https", hostname: "**" },
      { protocol: "http", hostname: "**" },
    ],
  },
}

export default nextConfig
