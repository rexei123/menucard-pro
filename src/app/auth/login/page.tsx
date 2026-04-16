'use client';
import { useState } from 'react';
import { signIn } from 'next-auth/react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      const result = await signIn('credentials', { email, password, redirect: false });
      if (result?.error) setError('Falsche E-Mail oder Passwort');
      else { router.push('/admin'); router.refresh(); }
    } catch { setError('Ein Fehler ist aufgetreten'); }
    finally { setLoading(false); }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-[#FAFAF8]">
      <div className="w-full max-w-md space-y-8 px-6">
        <div className="text-center">
          <h1 className="text-3xl font-bold tracking-tight text-gray-900" style={{fontFamily: "'Playfair Display', serif"}}>MenuCard Pro</h1>
          <p className="mt-2 text-sm text-gray-500">Melden Sie sich an</p>
        </div>
        <form onSubmit={handleSubmit} className="mt-8 space-y-6">
          {error && <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>}
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">E-Mail</label>
              <input type="email" required value={email} onChange={e => setEmail(e.target.value)} className="mt-1 block w-full rounded-lg border border-gray-300 px-4 py-3 focus:border-[#8B6914] focus:outline-none focus:ring-1 focus:ring-[#8B6914]" placeholder="admin@hotel-sonnblick.at" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Passwort</label>
              <input type="password" required value={password} onChange={e => setPassword(e.target.value)} className="mt-1 block w-full rounded-lg border border-gray-300 px-4 py-3 focus:border-[#8B6914] focus:outline-none focus:ring-1 focus:ring-[#8B6914]" />
            </div>
          </div>
          <button type="submit" disabled={loading} className="flex w-full justify-center rounded-lg bg-[#1a1a1a] px-4 py-3 text-sm font-semibold text-white hover:bg-[#333] disabled:opacity-50">
            {loading ? 'Anmelden...' : 'Anmelden'}
          </button>
        </form>
      </div>
    </div>
  );
}
