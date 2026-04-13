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
