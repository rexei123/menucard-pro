import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: { default: 'MenuCard Pro', template: '%s | MenuCard Pro' },
  description: 'Digitale Speise-, Getraenke- und Weinkarten',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="de" suppressHydrationWarning>
      <body className="min-h-screen">{children}</body>
    </html>
  );
}
