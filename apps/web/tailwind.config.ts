import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/**/*.{ts,tsx}',
    '../../packages/shared/src/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        // Reference palette (screen 2 — desktop homepage)
        ink: '#050505',
        panel: '#111111',
        muted: '#A6A6A6', // spec neutral gray

        brand: {
          DEFAULT: '#1F6E3D', // primary green
          light: '#2E8B57', // secondary green
          bright: '#43C46A', // highlight / CTA green
          dark: '#0E2A1B', // header / features band
          hero: '#103826', // hero card
          heroEdge: '#0A2417',
          gold: '#CFA347',
          goldLight: '#FFD979',
          goldDark: '#8E6528',
          cream: '#FFF8E7',
          muted: '#F7F9F6',
        },
      },
      fontFamily: {
        sans: ['var(--font-cairo)', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        card: '0 8px 30px rgba(0,0,0,0.08)',
        soft: '0 4px 16px rgba(0,0,0,0.06)',
      },
      borderRadius: {
        xl2: '20px',
      },
    },
  },
  plugins: [],
};

export default config;
