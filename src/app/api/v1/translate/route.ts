import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { text, from, to } = await req.json();
  if (!text || !text.trim()) return NextResponse.json({ translated: '' });

  try {
    const res = await fetch(
      `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${from || 'de'}|${to || 'en'}&de=admin@hotel-sonnblick.at`
    );
    const data = await res.json();
    const translated = data?.responseData?.translatedText || text;
    return NextResponse.json({ translated });
  } catch {
    return NextResponse.json({ translated: text });
  }
}
