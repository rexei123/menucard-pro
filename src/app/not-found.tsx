import Link from 'next/link';
export default function NotFound() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-[#FAFAF8] px-6 text-center">
      <p className="text-6xl font-bold text-[#8B6914]" style={{fontFamily: "'Playfair Display', serif"}}>404</p>
      <h1 className="mt-4 text-2xl font-bold text-[#1a1a1a]">Seite nicht gefunden</h1>
      <Link href="/" className="mt-6 rounded-xl bg-[#1a1a1a] px-6 py-3 text-sm font-semibold text-white hover:bg-[#333]">Zur Startseite</Link>
    </div>
  );
}
