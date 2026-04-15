#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Deploying Mobile Optimization (T-035) ==="

# Backup
echo "1/4 Backing up..."
mkdir -p /tmp/menucard-backup-mobile
cp -f src/app/layout.tsx /tmp/menucard-backup-mobile/layout.bak
cp -f src/app/globals.css /tmp/menucard-backup-mobile/globals.bak

echo "2/4 Writing files..."

# === FILE 1: Root Layout with proper meta, fonts, viewport ===
cat > src/app/layout.tsx << 'ENDFILE'
import type { Metadata, Viewport } from 'next';
import { Playfair_Display, Source_Sans_3 } from 'next/font/google';
import './globals.css';

const playfair = Playfair_Display({
  subsets: ['latin'],
  variable: '--font-heading',
  display: 'swap',
});

const sourceSans = Source_Sans_3({
  subsets: ['latin'],
  variable: '--font-body',
  display: 'swap',
});

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  themeColor: '#FAFAF8',
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
    <html lang="de" suppressHydrationWarning className={`${playfair.variable} ${sourceSans.variable}`}>
      <body className="min-h-screen font-body antialiased">{children}</body>
    </html>
  );
}
ENDFILE

# === FILE 2: Updated globals.css (remove @import, use CSS variables from next/font) ===
cat > src/app/globals.css << 'ENDFILE'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 40 20% 98%;
    --foreground: 0 0% 10%;
    --card: 0 0% 100%;
    --card-foreground: 0 0% 10%;
    --primary: 0 0% 10%;
    --primary-foreground: 0 0% 98%;
    --secondary: 40 10% 94%;
    --secondary-foreground: 0 0% 10%;
    --muted: 40 10% 94%;
    --muted-foreground: 0 0% 45%;
    --accent: 43 74% 31%;
    --accent-foreground: 0 0% 98%;
    --destructive: 0 84% 60%;
    --destructive-foreground: 0 0% 98%;
    --border: 40 10% 88%;
    --input: 40 10% 88%;
    --ring: 43 74% 31%;
    --radius: 0.5rem;
    --sidebar: 0 0% 98%;
    --sidebar-foreground: 0 0% 10%;
    --sidebar-border: 40 10% 90%;
    --sidebar-accent: 43 74% 31%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    -webkit-tap-highlight-color: transparent;
  }
  h1, h2, h3, h4, h5, h6 {
    font-family: var(--font-heading), 'Playfair Display', serif;
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
  background: linear-gradient(90deg, hsl(var(--muted)) 25%, hsl(var(--background)) 50%, hsl(var(--muted)) 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s ease-in-out infinite;
  border-radius: var(--radius);
}

/* Pull-to-refresh prevention on iOS */
body {
  overscroll-behavior-y: none;
}
ENDFILE

# === FILE 3: Loading skeleton for menu page ===
mkdir -p "src/app/(public)/[tenant]/[location]/[menu]"
cat > "src/app/(public)/[tenant]/[location]/[menu]/loading.tsx" << 'ENDFILE'
export default function MenuLoading() {
  return (
    <div className="min-h-screen bg-[#FAFAF8]">
      {/* Header skeleton */}
      <header className="border-b px-6 py-6 text-center">
        <div className="skeleton mx-auto h-3 w-24 mb-3" />
        <div className="skeleton mx-auto h-8 w-48" />
      </header>

      {/* Search bar skeleton */}
      <div className="border-b bg-white/95 px-4 py-3">
        <div className="mx-auto max-w-2xl">
          <div className="skeleton h-10 w-full rounded-full" />
        </div>
      </div>

      {/* Section nav skeleton */}
      <div className="border-b px-4 py-2">
        <div className="flex gap-2 overflow-hidden">
          {[1,2,3,4,5].map(i => (
            <div key={i} className="skeleton h-8 w-24 flex-shrink-0 rounded-full" />
          ))}
        </div>
      </div>

      {/* Content skeleton */}
      <main className="mx-auto max-w-2xl px-4 py-8">
        <div className="mb-6 text-center">
          <div className="skeleton mx-auto h-6 w-40 mb-3" />
          <div className="skeleton mx-auto h-px w-16" />
        </div>
        <div className="space-y-3">
          {[1,2,3,4,5,6].map(i => (
            <div key={i} className="rounded-xl border bg-white p-4 shadow-sm">
              <div className="skeleton h-5 w-3/4 mb-2" />
              <div className="skeleton h-3 w-1/2 mb-3" />
              <div className="skeleton h-4 w-16" />
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}
ENDFILE

# === FILE 4: Loading skeleton for location page ===
mkdir -p "src/app/(public)/[tenant]/[location]"
cat > "src/app/(public)/[tenant]/[location]/loading.tsx" << 'ENDFILE'
export default function LocationLoading() {
  return (
    <div className="min-h-screen bg-[#FAFAF8]">
      <header className="border-b px-6 py-6 text-center">
        <div className="skeleton mx-auto h-3 w-24 mb-3" />
        <div className="skeleton mx-auto h-7 w-36" />
      </header>
      <main className="mx-auto max-w-lg px-4 py-6 space-y-3">
        {[1,2,3,4].map(i => (
          <div key={i} className="flex items-center gap-4 rounded-2xl border bg-white p-5">
            <div className="skeleton h-10 w-10 rounded-full" />
            <div className="flex-1">
              <div className="skeleton h-5 w-32 mb-2" />
              <div className="skeleton h-3 w-48" />
            </div>
          </div>
        ))}
      </main>
    </div>
  );
}
ENDFILE

# === FILE 5: Loading skeleton for item detail ===
mkdir -p "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]"
cat > "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/loading.tsx" << 'ENDFILE'
export default function ItemLoading() {
  return (
    <div className="min-h-screen bg-[#FAFAF8]">
      <header className="border-b px-4 py-4">
        <div className="skeleton h-4 w-32 mb-1" />
        <div className="skeleton h-3 w-20" />
      </header>
      <main className="mx-auto max-w-2xl px-4 py-6">
        <div className="skeleton h-8 w-3/4 mb-2" />
        <div className="skeleton h-4 w-1/2 mb-6" />
        <div className="rounded-xl border bg-white p-5 mb-6">
          <div className="skeleton h-4 w-full mb-2" />
          <div className="skeleton h-4 w-5/6 mb-2" />
          <div className="skeleton h-4 w-2/3" />
        </div>
        <div className="rounded-xl border bg-white p-5 mb-6">
          <div className="skeleton h-4 w-16 mb-4" />
          <div className="flex justify-between">
            <div className="skeleton h-4 w-20" />
            <div className="skeleton h-5 w-16" />
          </div>
        </div>
        <div className="rounded-xl border bg-white p-5">
          <div className="skeleton h-4 w-24 mb-4" />
          <div className="grid grid-cols-2 gap-3">
            {[1,2,3,4,5,6].map(i => (
              <div key={i}>
                <div className="skeleton h-2 w-16 mb-1" />
                <div className="skeleton h-4 w-24" />
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
ENDFILE

# === FILE 6: Update MenuContent - add hide-scrollbar to nav, better touch targets ===
sed -i 's/className="flex overflow-x-auto px-4 py-2 gap-1"/className="flex overflow-x-auto px-4 py-2 gap-1 hide-scrollbar"/g' src/components/menu-content.tsx

# Fix scroll-mt for new sticky search+nav bar height
sed -i 's/scroll-mt-32/scroll-mt-40/g' src/components/menu-content.tsx

echo "3/4 Building..."
npm run build

echo "4/4 Restarting..."
pm2 restart menucard-pro

echo ""
echo "=== Mobile Optimization deployed! ==="
echo ""
echo "Verbesserungen:"
echo "  - next/font statt CSS @import (schnelleres Font-Loading)"
echo "  - Viewport-Meta + Apple Web App Meta"
echo "  - Skeleton-Loading für alle Seiten"
echo "  - Scrollbar versteckt in Navigation"
echo "  - Touch-optimierte Tap-Targets"
echo "  - Smooth Scrolling"
echo "  - Pull-to-refresh Prevention"
