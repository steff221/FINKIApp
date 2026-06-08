/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  async rewrites() {
    // BACKEND_URL is the server-to-server target (e.g. http://backend:8080 in Docker).
    // Falls back to localhost for local dev without Docker.
    const backendUrl = process.env.BACKEND_URL ?? "http://localhost:8080";
    return [
      {
        source: "/api/:path*",
        destination: `${backendUrl}/api/:path*`,
      },
    ];
  },
};

export default nextConfig;
