/** @type {import('tailwindcss').Config}
 *
 * Tailwind v4 setup for the OpenMage admin panel.
 *
 * Colours mirror the --d* / --b* / --t* tokens defined in
 * skin/adminhtml/default/default/dark-theme.css. Keep this map and that
 * file in sync — if you change one, change the other, or write Tailwind
 * tokens that reference the CSS variables via `<color>` mode.
 *
 * Preflight is disabled because Magento's legacy boxes.css + the admin
 * dark theme already define their own reset / base styles. Re-enabling
 * preflight would clobber legacy form layouts.
 */
module.exports = {
  content: [
    './app/design/adminhtml/**/*.phtml',
    './app/code/local/**/*.phtml',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // === Canvas / surfaces (matches --d* in dark-theme.css) ===
        canvas: '#0f172a',          // --d1, body / .middle / grid bg
        'surface-1': '#1e293b',     // --d2, raised surfaces (cards, inputs)
        'surface-2': '#334155',     // --d4, hover / active surfaces
        'surface-3': '#475569',     // --d5, strong surface
        'surface-mute': '#0b1120',  // --d0, inset / track background

        // === Borders ===
        'border-subtle': '#374151', // --b1, default hairlines
        'border-strong': '#4b5563', // --b2, focused / emphasised
        'border-loud': '#6b7280',   // --b3

        // === Text ===
        'text-strong': '#f1f5f9',   // --t1, headings
        'text-body': '#cbd5e1',     // --t2, body
        'text-muted': '#94a3b8',    // --t3, labels
        'text-faint': '#64748b',    // --t4, hints
        'text-disabled': '#475569', // --t5, disabled

        // === Brand / accents ===
        primary: {
          DEFAULT: '#258bb6',       // --blue, primary brand
          hover: '#3aa7d4',         // --blue2
          light: '#5ea6ff',         // hover / link
        },
        success: { DEFAULT: '#10b981', light: '#34d399' },
        warning: { DEFAULT: '#f59e0b', light: '#fbbf24' },
        danger:  { DEFAULT: '#ef4444', light: '#f87171' },
      },
      borderRadius: {
        sm: '6px',
        DEFAULT: '8px',
        md: '10px',
        lg: '14px',
      },
      fontFamily: {
        sans: ['-apple-system', 'BlinkMacSystemFont', 'Inter', 'Segoe UI', 'Roboto', 'sans-serif'],
        mono: ['ui-monospace', 'SFMono-Regular', 'Menlo', 'monospace'],
      },
      boxShadow: {
        sm: '0 1px 2px rgba(2,6,23,0.25)',
        md: '0 8px 24px rgba(2,6,23,0.28)',
        lg: '0 20px 40px rgba(2,6,23,0.32)',
      },
    },
  },
  corePlugins: {
    // Don't reset Magento's existing styles — boxes.css + dark-theme already
    // define a complete base. Preflight here would break legacy form layouts.
    preflight: false,
  },
}
