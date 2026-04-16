import Link from 'next/link';

export default function HomePage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-[#FAFAF8] px-6 text-center">
      <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-[#1a1a1a] text-2xl font-bold text-white">M</div>
      <h1 className="mt-6 text-4xl font-bold tracking-tight text-[#1a1a1a]" style={{fontFamily: "'Playfair Display', serif"}}>MenuCard Pro</h1>
      <p className="mt-3 max-w-md text-lg text-gray-500">Digitale Speise-, Getränke- und Weinkarten für die gehobene Hotellerie</p>
      <div className="mt-8 flex gap-3">
        <Link href="/hotel-sonnblick" className="rounded-xl bg-[#1a1a1a] px-6 py-3 text-sm font-semibold text-white hover:bg-[#333]">Demo ansehen</Link>
        <Link href="/auth/login" className="rounded-xl border border-gray-300 px-6 py-3 text-sm font-semibold text-[#1a1a1a] hover:bg-gray-100">Admin Login</Link>
      </div>
    </div>
  );
}
