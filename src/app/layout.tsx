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
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200"
        />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700&family=Cormorant+Garamond:wght@400;500;600;700&family=Source+Sans+3:ital,wght@0,400;0,600;0,700;1,400&family=Lato:wght@400;700&family=Inter:wght@400;500;600;700;800&display=swap"
        />
      </head>
      <body className="min-h-screen font-body antialiased">{children}</body>
    </html>
  );
}
