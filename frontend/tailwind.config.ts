import type { Config } from "tailwindcss";

export default {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        finki: {
          navy:  "#00265c",
          blue:  "#00265c",
          mid:   "#0050b3",
          light: "#0050b3",
          bright:"#1a7fff",
        },
        canvas: "#f0f4f9",
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
      },
      boxShadow: {
        card: "0 1px 4px 0 rgb(0 0 0 / 0.07), 0 0 0 1px rgb(0 0 0 / 0.04)",
        "card-hover": "0 6px 20px 0 rgb(0 0 0 / 0.10), 0 0 0 1px rgb(0 0 0 / 0.04)",
        panel: "0 2px 8px 0 rgb(0 0 0 / 0.08), 0 0 0 1px rgb(0 0 0 / 0.05)",
      },
    },
  },
  plugins: [],
} satisfies Config;
