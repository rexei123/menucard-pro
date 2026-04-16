'use client';

import { usePathname, useSearchParams, useRouter } from 'next/navigation';

export default function LanguageSwitcher() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const router = useRouter();
  const current = searchParams.get('lang') === 'en' ? 'en' : 'de';

  const toggle = () => {
    const next = current === 'de' ? 'en' : 'de';
    const params = new URLSearchParams(searchParams.toString());
    if (next === 'de') {
      params.delete('lang');
    } else {
      params.set('lang', next);
    }
    const qs = params.toString();
    router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
  };

  return (
    <button
      onClick={toggle}
      className="fixed bottom-4 right-4 z-50 flex items-center gap-1.5 rounded-full border bg-white/95 px-3 py-2 text-xs font-medium shadow-lg backdrop-blur-sm transition-all hover:shadow-xl active:scale-95"
      aria-label={current === 'de' ? 'Switch to English' : 'Auf Deutsch wechseln'}
    >
      <span className="text-sm">{current === 'de' ? '🇬🇧' : '🇦🇹'}</span>
      <span className="uppercase tracking-wide">{current === 'de' ? 'EN' : 'DE'}</span>
    </button>
  );
}
