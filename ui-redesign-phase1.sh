#!/bin/bash
set -e
echo "============================================"
echo "  UI-Redesign Phase 1: Foundation"
echo "  Tokens, Tailwind, Icons, Fonts, Komponenten"
echo "============================================"

cd /var/www/menucard-pro

# Backups
cp tailwind.config.ts tailwind.config.ts.bak-redesign
cp src/app/layout.tsx src/app/layout.tsx.bak-redesign
cp src/app/globals.css src/app/globals.css.bak-redesign

# ============================================
# 1. TOKENS.CSS
# ============================================
echo "[1/7] tokens.css erstellen..."
mkdir -p src/styles

cat > src/styles/tokens.css << 'TOKENSEOF'
/* ============================================================
   MenuCard Pro – Design Tokens
   EINZIGE Stelle für Farben, Schriften, Abstände, Radien.
   Alles andere referenziert nur diese Tokens.
   ============================================================ */

:root {
  /* ============================================ */
  /* FARBEN                                       */
  /* ============================================ */

  /* Primärfarbe (Akzent – Rosa/Pink) */
  --color-primary: #DD3C71;
  --color-primary-hover: #C42D60;
  --color-primary-light: #FDF2F5;
  --color-primary-subtle: rgba(221, 60, 113, 0.08);

  /* Neutrale Farben */
  --color-bg: #FFFFFF;
  --color-bg-subtle: #FAFAFB;
  --color-bg-muted: #F3F3F6;
  --color-surface: #FFFFFF;
  --color-surface-hover: #F9F9FB;

  /* Text */
  --color-text: #1A1A1A;
  --color-text-secondary: #565D6D;
  --color-text-muted: #8E8E8E;
  --color-text-inverse: #FFFFFF;

  /* Borders */
  --color-border: #E5E7EB;
  --color-border-subtle: rgba(0, 0, 0, 0.04);
  --color-border-focus: var(--color-primary);

  /* Status */
  --color-success: #16A34A;
  --color-success-light: #F0FDF4;
  --color-warning: #F59E0B;
  --color-warning-light: #FFFBEB;
  --color-error: #E05252;
  --color-error-light: #FEF2F2;
  --color-info: #3B82F6;
  --color-info-light: #EFF6FF;

  /* Admin Sidebar */
  --color-sidebar-bg: #FFFFFF;
  --color-sidebar-text: #565D6D;
  --color-sidebar-active-bg: var(--color-primary-light);
  --color-sidebar-active-text: var(--color-primary);
  --color-sidebar-hover-bg: #F3F3F6;
  --color-sidebar-border: #F3F3F6;

  /* Badges */
  --color-badge-new: #DD3C71;
  --color-badge-top: #F59E0B;
  --color-badge-bestseller: #16A34A;
  --color-badge-hot: #E05252;
  --color-badge-vegetarian: #16A34A;
  --color-badge-vegan: #059669;
  --color-badge-signature: #7C3AED;

  /* Marge-Farben (Admin Preiskalkulation) */
  --color-margin-good: #16A34A;
  --color-margin-ok: #F59E0B;
  --color-margin-bad: #E05252;

  /* Übersetzungs-Status */
  --color-translate-default: #9CA3AF;
  --color-translate-changed: #F59E0B;
  --color-translate-done: #16A34A;

  /* Selection (Text markieren) */
  --color-selection-bg: rgba(221, 60, 113, 0.2);
  --color-selection-text: #DD3C71;

  /* ============================================ */
  /* TYPOGRAFIE                                    */
  /* ============================================ */

  /* Schriftfamilien */
  --font-heading: 'Playfair Display', ui-serif, Georgia, serif;
  --font-body: 'Inter', ui-sans-serif, system-ui, sans-serif;
  --font-display: 'Montserrat', ui-sans-serif, system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, monospace;

  /* Schriftgrößen */
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;

  /* Schriftgewichte */
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;
  --font-extrabold: 800;

  /* Zeilenhöhen */
  --leading-tight: 1.25;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;

  /* ============================================ */
  /* ABSTÄNDE & LAYOUT                             */
  /* ============================================ */

  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
  --spacing-2xl: 48px;
  --spacing-3xl: 64px;

  /* Border Radius */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-full: 9999px;

  /* Schatten */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.05), 0 2px 4px rgba(0, 0, 0, 0.03);
  --shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.05), 0 8px 10px rgba(0, 0, 0, 0.03);
  --shadow-card: 0 1px 3px rgba(0, 0, 0, 0.08);
  --shadow-nav: 0 -2px 10px rgba(0, 0, 0, 0.05);

  /* ============================================ */
  /* ADMIN LAYOUT                                  */
  /* ============================================ */

  --sidebar-width: 200px;
  --sidebar-collapsed-width: 56px;
  --header-height: 56px;
  --list-panel-width: 400px;
  --list-panel-min-width: 280px;
  --list-panel-max-width: 600px;

  /* ============================================ */
  /* ÜBERGÄNGE                                     */
  /* ============================================ */

  --transition-fast: 150ms ease;
  --transition-normal: 250ms ease;
  --transition-slow: 350ms ease;
}

::selection {
  background-color: var(--color-selection-bg);
  color: var(--color-selection-text);
}
TOKENSEOF

# ============================================
# 2. GLOBALS.CSS (komplett neu)
# ============================================
echo "[2/7] globals.css neu schreiben..."

cat > src/app/globals.css << 'GLOBALSEOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Design Tokens importieren */
@import '../styles/tokens.css';

@layer base {
  /* Legacy HSL-Variablen für bestehende shadcn/ui Komponenten */
  :root {
    --background: 0 0% 100%;
    --foreground: 0 0% 10%;
    --card: 0 0% 100%;
    --card-foreground: 0 0% 10%;
    --primary: 340 70% 55%;
    --primary-foreground: 0 0% 100%;
    --secondary: 240 5% 96%;
    --secondary-foreground: 0 0% 10%;
    --muted: 240 5% 96%;
    --muted-foreground: 0 0% 45%;
    --accent: 340 70% 55%;
    --accent-foreground: 0 0% 100%;
    --destructive: 0 72% 51%;
    --destructive-foreground: 0 0% 98%;
    --border: 220 13% 91%;
    --input: 220 13% 91%;
    --ring: 340 70% 55%;
    --radius: 0.5rem;
    --sidebar: 0 0% 100%;
    --sidebar-foreground: 230 8% 40%;
    --sidebar-border: 240 5% 96%;
    --sidebar-accent: 340 70% 55%;
  }

  * {
    @apply border-border;
  }

  body {
    background-color: var(--color-bg);
    color: var(--color-text);
    font-family: var(--font-body);
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    -webkit-tap-highlight-color: transparent;
  }

  h1, h2, h3, h4, h5, h6 {
    font-family: var(--font-heading);
    color: var(--color-text);
  }
}

/* Smooth scrolling */
html {
  scroll-behavior: smooth;
}

/* Better touch targets */
@layer utilities {
  .touch-target {
    min-height: 44px;
    min-width: 44px;
  }
}

/* Hide scrollbar on nav but keep scroll */
.hide-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.hide-scrollbar::-webkit-scrollbar {
  display: none;
}

/* Skeleton animation */
@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}
.skeleton {
  background: linear-gradient(90deg, var(--color-bg-muted) 25%, var(--color-bg) 50%, var(--color-bg-muted) 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s ease-in-out infinite;
  border-radius: var(--radius-md);
}

/* Pull-to-refresh prevention on iOS */
body {
  overscroll-behavior-y: none;
}

/* Eyebrow / Overline Text (aus Visily-Designs) */
.eyebrow-text {
  font-family: var(--font-display);
  letter-spacing: 0.25em;
  font-size: var(--text-xs);
  font-weight: var(--font-medium);
  text-transform: uppercase;
  color: var(--color-text-muted);
}

/* Menu item italic description (Elegant Template) */
.menu-item-description {
  font-family: var(--font-heading);
  font-style: italic;
  line-height: var(--leading-relaxed);
  color: var(--color-text-secondary);
}

/* Price tag tabular numbers */
.price-tag {
  font-family: var(--font-heading);
  font-variant-numeric: tabular-nums;
}

/* Subtle border utility */
.border-subtle {
  border-color: var(--color-border-subtle);
}

/* Card shadow utility */
.shadow-card {
  box-shadow: var(--shadow-card);
}

/* Nav shadow (bottom bar) */
.shadow-nav {
  box-shadow: var(--shadow-nav);
}

/* Header blur effect */
.header-blur {
  backdrop-filter: blur(8px);
  background-color: rgba(255, 255, 255, 0.8);
}

/* Heading underline accent (Klassisch Template) */
.heading-underline::after {
  content: '';
  display: block;
  width: 40px;
  height: 2px;
  background-color: var(--color-primary);
  margin-top: 0.75rem;
}
.heading-underline-center::after {
  content: '';
  display: block;
  width: 40px;
  height: 2px;
  background-color: var(--color-primary);
  margin: 0.75rem auto 0;
}
GLOBALSEOF

# ============================================
# 3. TAILWIND.CONFIG.TS (komplett neu)
# ============================================
echo "[3/7] tailwind.config.ts neu schreiben..."

cat > tailwind.config.ts << 'TAILWINDEOF'
import type { Config } from 'tailwindcss';
const config: Config = {
  darkMode: ['class'],
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        /* Legacy HSL-Variablen (shadcn/ui Kompatibilität) */
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        popover: {
          DEFAULT: 'hsl(var(--popover, var(--card)))',
          foreground: 'hsl(var(--popover-foreground, var(--card-foreground)))',
        },

        /* Neues Token-System */
        primary: {
          DEFAULT: 'var(--color-primary)',
          hover: 'var(--color-primary-hover)',
          light: 'var(--color-primary-light)',
          subtle: 'var(--color-primary-subtle)',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
        surface: {
          DEFAULT: 'var(--color-surface)',
          hover: 'var(--color-surface-hover)',
        },
        sidebar: {
          DEFAULT: 'var(--color-sidebar-bg)',
          text: 'var(--color-sidebar-text)',
          active: 'var(--color-sidebar-active-bg)',
          'active-text': 'var(--color-sidebar-active-text)',
          hover: 'var(--color-sidebar-hover-bg)',
          border: 'var(--color-sidebar-border)',
          foreground: 'hsl(var(--sidebar-foreground))',
          accent: 'hsl(var(--sidebar-accent))',
        },

        /* Text-Farben */
        'text-primary': 'var(--color-text)',
        'text-secondary': 'var(--color-text-secondary)',
        'text-muted': 'var(--color-text-muted)',
        'text-inverse': 'var(--color-text-inverse)',

        /* Status-Farben */
        success: {
          DEFAULT: 'var(--color-success)',
          light: 'var(--color-success-light)',
        },
        warning: {
          DEFAULT: 'var(--color-warning)',
          light: 'var(--color-warning-light)',
        },
        error: {
          DEFAULT: 'var(--color-error)',
          light: 'var(--color-error-light)',
        },
        info: {
          DEFAULT: 'var(--color-info)',
          light: 'var(--color-info-light)',
        },

        /* Badge-Farben */
        badge: {
          new: 'var(--color-badge-new)',
          top: 'var(--color-badge-top)',
          bestseller: 'var(--color-badge-bestseller)',
          hot: 'var(--color-badge-hot)',
          vegetarian: 'var(--color-badge-vegetarian)',
          vegan: 'var(--color-badge-vegan)',
          signature: 'var(--color-badge-signature)',
        },

        /* Hintergrund */
        'bg-subtle': 'var(--color-bg-subtle)',
        'bg-muted': 'var(--color-bg-muted)',
      },
      fontFamily: {
        heading: ['var(--font-heading)', 'serif'],
        body: ['var(--font-body)', 'sans-serif'],
        display: ['var(--font-display)', 'sans-serif'],
        mono: ['var(--font-mono)', 'monospace'],
      },
      borderRadius: {
        sm: 'var(--radius-sm)',
        DEFAULT: 'var(--radius-md)',
        md: 'var(--radius-md)',
        lg: 'var(--radius-lg)',
        xl: 'var(--radius-xl)',
        full: 'var(--radius-full)',
      },
      boxShadow: {
        sm: 'var(--shadow-sm)',
        DEFAULT: 'var(--shadow-md)',
        md: 'var(--shadow-md)',
        lg: 'var(--shadow-lg)',
        card: 'var(--shadow-card)',
        nav: 'var(--shadow-nav)',
      },
      spacing: {
        sidebar: 'var(--sidebar-width)',
        'sidebar-collapsed': 'var(--sidebar-collapsed-width)',
        header: 'var(--header-height)',
      },
      transitionDuration: {
        fast: '150ms',
        normal: '250ms',
        slow: '350ms',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
};
export default config;
TAILWINDEOF

# ============================================
# 4. ICON-KOMPONENTE
# ============================================
echo "[4/7] Icon-Komponente erstellen..."
mkdir -p src/components/ui

cat > src/components/ui/icon.tsx << 'ICONEOF'
'use client';

interface IconProps {
  name: string;
  size?: number;
  weight?: number;
  fill?: boolean;
  className?: string;
  onClick?: () => void;
}

export function Icon({
  name,
  size = 24,
  weight = 400,
  fill = false,
  className = '',
  onClick,
}: IconProps) {
  return (
    <span
      className={`material-symbols-outlined select-none ${className}`}
      style={{
        fontSize: size,
        fontVariationSettings: `'FILL' ${fill ? 1 : 0}, 'wght' ${weight}, 'GRAD' 0, 'opsz' ${size}`,
        lineHeight: 1,
      }}
      onClick={onClick}
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      {name}
    </span>
  );
}

/* Icon-Mapping: Emojis → Material Symbols
 *
 * Admin Icon-Bar:
 *   📊 Dashboard      → dashboard
 *   📦 Produkte       → inventory_2
 *   📋 Karten         → menu_book
 *   📱 QR-Codes       → qr_code_2
 *   🖼️ Bildarchiv     → photo_library
 *   📈 Analytics      → analytics
 *   ⚙️ Einstellungen  → settings
 *   🔄 Neu laden      → refresh
 *   🚪 Logout         → logout
 *
 * Produkttypen:
 *   🍷 Wein           → wine_bar
 *   🍸 Getränk        → local_bar
 *   🍽️ Speise         → restaurant
 *   ☕ Heißgetränk    → coffee
 *   🍺 Bier           → sports_bar
 *
 * Status & Aktionen:
 *   ✅ Aktiv          → check_circle (fill)
 *   🚫 Ausgetrunken   → block
 *   ⭐ Hauptbild      → star (fill)
 *   ✂️ Crop           → crop
 *   🗑️ Löschen        → delete
 *   💾 Speichern      → save
 *   ➕ Hinzufügen     → add
 *   ✕ Schließen      → close
 *   🔍 Suche          → search
 *   📤 Upload         → upload
 *   🌐 Web            → language
 *
 * Gästeansicht Kategorien:
 *   Vorspeisen        → tapas
 *   Hauptgerichte     → restaurant
 *   Pasta             → ramen_dining
 *   Desserts          → cake
 *   Weinkarte         → wine_bar
 *   Kaffee & Digestif → coffee
 *   Salate            → eco
 *   Burger            → lunch_dining
 *   Pizza             → local_pizza
 *
 * Allergene:
 *   Gluten            → grain
 *   Laktose           → water_drop
 *   Nüsse             → psychiatry
 *   Fisch             → set_meal
 *   Eier              → egg
 */
ICONEOF

# ============================================
# 5. LAYOUT.TSX (komplett neu)
# ============================================
echo "[5/7] layout.tsx neu schreiben..."

cat > src/app/layout.tsx << 'LAYOUTEOF'
import type { Metadata, Viewport } from 'next';
import { Playfair_Display, Inter, Montserrat } from 'next/font/google';
import './globals.css';

const playfair = Playfair_Display({
  subsets: ['latin'],
  variable: '--font-heading',
  display: 'swap',
  weight: ['400', '500', '600', '700'],
});

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-body',
  display: 'swap',
});

const montserrat = Montserrat({
  subsets: ['latin'],
  variable: '--font-display',
  display: 'swap',
  weight: ['400', '500', '600', '700', '800'],
});

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  themeColor: '#FFFFFF',
};

export const metadata: Metadata = {
  title: { default: 'MenuCard Pro', template: '%s | MenuCard Pro' },
  description: 'Digitale Speise-, Getränke- und Weinkarten',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'default',
    title: 'MenuCard Pro',
  },
  formatDetection: {
    telephone: false,
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="de" suppressHydrationWarning className={`${playfair.variable} ${inter.variable} ${montserrat.variable}`}>
      <head>
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200"
        />
      </head>
      <body className="min-h-screen font-body antialiased">{children}</body>
    </html>
  );
}
LAYOUTEOF

# ============================================
# 6. BUTTON-KOMPONENTE
# ============================================
echo "[6/7] Basis-Komponenten erstellen..."

cat > src/components/ui/button.tsx << 'BUTTONEOF'
'use client';

import { forwardRef } from 'react';
import { Icon } from './icon';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger' | 'outline';
  size?: 'sm' | 'md' | 'lg';
  icon?: string;
  iconPosition?: 'left' | 'right';
  iconFill?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
}

const variantClasses: Record<string, string> = {
  primary: 'bg-[var(--color-primary)] text-white hover:bg-[var(--color-primary-hover)] active:bg-[var(--color-primary-hover)] shadow-sm',
  secondary: 'bg-transparent border border-[var(--color-border)] text-[var(--color-text)] hover:bg-[var(--color-bg-muted)] active:bg-[var(--color-bg-muted)]',
  ghost: 'bg-transparent text-[var(--color-primary)] hover:bg-[var(--color-primary-subtle)] active:bg-[var(--color-primary-subtle)]',
  danger: 'bg-[var(--color-error)] text-white hover:bg-[#C94444] active:bg-[#C94444] shadow-sm',
  outline: 'bg-transparent border border-[var(--color-primary)] text-[var(--color-primary)] hover:bg-[var(--color-primary-subtle)]',
};

const sizeClasses: Record<string, string> = {
  sm: 'px-3 py-1.5 text-sm gap-1.5',
  md: 'px-4 py-2 text-base gap-2',
  lg: 'px-6 py-3 text-lg gap-2.5',
};

const iconSizes: Record<string, number> = {
  sm: 18,
  md: 20,
  lg: 22,
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = 'primary',
      size = 'md',
      icon,
      iconPosition = 'left',
      iconFill = false,
      loading = false,
      fullWidth = false,
      className = '',
      children,
      disabled,
      ...props
    },
    ref
  ) => {
    const isDisabled = disabled || loading;

    return (
      <button
        ref={ref}
        className={`
          inline-flex items-center justify-center font-medium
          rounded-[var(--radius-md)] transition-all duration-fast
          focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)] focus-visible:ring-offset-2
          disabled:opacity-50 disabled:pointer-events-none
          ${variantClasses[variant]}
          ${sizeClasses[size]}
          ${fullWidth ? 'w-full' : ''}
          ${className}
        `.trim()}
        disabled={isDisabled}
        {...props}
      >
        {loading && (
          <span className="animate-spin">
            <Icon name="progress_activity" size={iconSizes[size]} />
          </span>
        )}
        {!loading && icon && iconPosition === 'left' && (
          <Icon name={icon} size={iconSizes[size]} fill={iconFill} />
        )}
        {children}
        {!loading && icon && iconPosition === 'right' && (
          <Icon name={icon} size={iconSizes[size]} fill={iconFill} />
        )}
      </button>
    );
  }
);

Button.displayName = 'Button';
BUTTONEOF

# INPUT-KOMPONENTE
cat > src/components/ui/input-field.tsx << 'INPUTEOF'
'use client';

import { forwardRef } from 'react';
import { Icon } from './icon';

interface InputFieldProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  helperText?: string;
  error?: string;
  icon?: string;
  fullWidth?: boolean;
}

export const InputField = forwardRef<HTMLInputElement, InputFieldProps>(
  ({ label, helperText, error, icon, fullWidth = true, className = '', id, ...props }, ref) => {
    const inputId = id || label?.toLowerCase().replace(/\s+/g, '-');

    return (
      <div className={`${fullWidth ? 'w-full' : ''}`}>
        {label && (
          <label
            htmlFor={inputId}
            className="block text-sm font-medium text-[var(--color-text)] mb-1.5 tracking-wide uppercase"
            style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-sm)' }}
          >
            {label}
          </label>
        )}
        <div className="relative">
          {icon && (
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)]">
              <Icon name={icon} size={20} />
            </div>
          )}
          <input
            ref={ref}
            id={inputId}
            className={`
              w-full border rounded-[var(--radius-md)] px-4 py-2.5 text-base
              bg-[var(--color-surface)] text-[var(--color-text)]
              placeholder:text-[var(--color-text-muted)]
              transition-all duration-fast
              focus:outline-none focus:border-[var(--color-primary)] focus:ring-1 focus:ring-[var(--color-primary-light)]
              ${error ? 'border-[var(--color-error)]' : 'border-[var(--color-border)]'}
              ${icon ? 'pl-10' : ''}
              ${className}
            `.trim()}
            {...props}
          />
        </div>
        {error && (
          <p className="mt-1 text-sm text-[var(--color-error)] flex items-center gap-1">
            <Icon name="error" size={16} />
            {error}
          </p>
        )}
        {helperText && !error && (
          <p className="mt-1 text-sm text-[var(--color-text-muted)]">{helperText}</p>
        )}
      </div>
    );
  }
);

InputField.displayName = 'InputField';
INPUTEOF

# CARD-KOMPONENTE
cat > src/components/ui/card-ui.tsx << 'CARDEOF'
'use client';

import { Icon } from './icon';

interface CardProps {
  children: React.ReactNode;
  className?: string;
  padding?: 'sm' | 'md' | 'lg';
  hover?: boolean;
  onClick?: () => void;
}

const paddingClasses: Record<string, string> = {
  sm: 'p-4',
  md: 'p-6',
  lg: 'p-8',
};

export function Card({ children, className = '', padding = 'md', hover = false, onClick }: CardProps) {
  return (
    <div
      className={`
        bg-[var(--color-surface)] rounded-[var(--radius-lg)] shadow-card
        border border-[var(--color-border-subtle)]
        ${paddingClasses[padding]}
        ${hover ? 'hover:shadow-md hover:border-[var(--color-border)] transition-all duration-normal cursor-pointer' : ''}
        ${className}
      `.trim()}
      onClick={onClick}
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      {children}
    </div>
  );
}

/* KPI-Card für Dashboard */
interface KpiCardProps {
  icon: string;
  iconColor?: string;
  label: string;
  value: string | number;
  trend?: { value: string; positive: boolean };
  className?: string;
}

export function KpiCard({ icon, iconColor = 'var(--color-primary)', label, value, trend, className = '' }: KpiCardProps) {
  return (
    <Card className={className}>
      <div className="flex items-start justify-between mb-3">
        <div
          className="w-10 h-10 rounded-[var(--radius-md)] flex items-center justify-center"
          style={{ backgroundColor: `${iconColor}15` }}
        >
          <Icon name={icon} size={22} className="text-[var(--color-primary)]" style={{ color: iconColor } as any} />
        </div>
        {trend && (
          <span
            className={`text-xs font-medium px-2 py-0.5 rounded-full flex items-center gap-0.5 ${
              trend.positive
                ? 'text-[var(--color-success)] bg-[var(--color-success-light)]'
                : 'text-[var(--color-error)] bg-[var(--color-error-light)]'
            }`}
          >
            <Icon name={trend.positive ? 'trending_up' : 'trending_down'} size={14} />
            {trend.value}
          </span>
        )}
      </div>
      <p className="text-sm text-[var(--color-text-muted)] mb-1">{label}</p>
      <p className="text-2xl font-bold text-[var(--color-text)]" style={{ fontFamily: 'var(--font-body)' }}>
        {value}
      </p>
    </Card>
  );
}
CARDEOF

# BADGE-KOMPONENTE
cat > src/components/ui/badge-ui.tsx << 'BADGEEOF'
'use client';

import { Icon } from './icon';

type BadgeVariant =
  | 'default'
  | 'primary'
  | 'success'
  | 'warning'
  | 'error'
  | 'info'
  | 'new'
  | 'top'
  | 'bestseller'
  | 'hot'
  | 'vegetarian'
  | 'vegan'
  | 'signature';

type BadgeSize = 'sm' | 'md';

interface BadgeProps {
  children: React.ReactNode;
  variant?: BadgeVariant;
  size?: BadgeSize;
  icon?: string;
  pill?: boolean;
  className?: string;
}

const variantClasses: Record<BadgeVariant, string> = {
  default: 'bg-[var(--color-bg-muted)] text-[var(--color-text-secondary)]',
  primary: 'bg-[var(--color-primary-light)] text-[var(--color-primary)]',
  success: 'bg-[var(--color-success-light)] text-[var(--color-success)]',
  warning: 'bg-[var(--color-warning-light)] text-[var(--color-warning)]',
  error: 'bg-[var(--color-error-light)] text-[var(--color-error)]',
  info: 'bg-[var(--color-info-light)] text-[var(--color-info)]',
  new: 'bg-[var(--color-badge-new)] text-white',
  top: 'bg-[var(--color-badge-top)] text-white',
  bestseller: 'bg-[var(--color-badge-bestseller)] text-white',
  hot: 'bg-[var(--color-badge-hot)] text-white',
  vegetarian: 'bg-[var(--color-success-light)] text-[var(--color-badge-vegetarian)]',
  vegan: 'bg-emerald-50 text-[var(--color-badge-vegan)]',
  signature: 'bg-purple-50 text-[var(--color-badge-signature)]',
};

const sizeClasses: Record<BadgeSize, string> = {
  sm: 'px-2 py-0.5 text-xs',
  md: 'px-3 py-1 text-xs',
};

export function Badge({
  children,
  variant = 'default',
  size = 'sm',
  icon,
  pill = false,
  className = '',
}: BadgeProps) {
  return (
    <span
      className={`
        inline-flex items-center gap-1 font-medium
        ${pill ? 'rounded-full' : 'rounded-[var(--radius-sm)]'}
        ${variantClasses[variant]}
        ${sizeClasses[size]}
        ${className}
      `.trim()}
    >
      {icon && <Icon name={icon} size={14} />}
      {children}
    </span>
  );
}
BADGEEOF

# ============================================
# 7. BUILD
# ============================================
echo "[7/7] Build starten..."
npm run build && pm2 restart menucard-pro

echo ""
echo "============================================"
echo "  UI-Redesign Phase 1: FERTIG!"
echo "============================================"
echo "  Erstellt:"
echo "  - src/styles/tokens.css (Design-Token-System)"
echo "  - src/app/globals.css (Token-basiert)"
echo "  - tailwind.config.ts (Token-Mapping)"
echo "  - src/components/ui/icon.tsx (Material Symbols)"
echo "  - src/app/layout.tsx (Playfair+Inter+Montserrat+Material Icons)"
echo "  - src/components/ui/button.tsx (4 Varianten, 3 Größen)"
echo "  - src/components/ui/input-field.tsx (Label, Error, Icon)"
echo "  - src/components/ui/card-ui.tsx (Card + KpiCard)"
echo "  - src/components/ui/badge-ui.tsx (13 Varianten)"
echo "============================================"
echo "  NÄCHSTER SCHRITT: Phase 2 – Admin-Sidebar"
echo "============================================"
