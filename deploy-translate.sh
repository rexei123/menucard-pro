#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Adding Auto-Translation DE→EN ==="

# 1. Create translation API route
mkdir -p src/app/api/v1/translate
cat > src/app/api/v1/translate/route.ts << 'ENDFILE'
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
ENDFILE

# 2. Update product editor: replace copyDeToEn with translateDeToEn
echo "Updating editor..."
python3 << 'PYEOF'
content = open('src/components/admin/product-editor.tsx').read()

# Replace copyDeToEn with async translate function
content = content.replace(
    """const copyDeToEn = (field: string) => {
    const deVal = (data.translations.find(t => t.languageCode === 'de') as any)?.[field] || '';
    setTrans('en', field, deVal);
    setDeChanged(prev => { const n = new Set(prev); n.delete(field); return n; });
  };""",
    """const [translating, setTranslating] = useState<Set<string>>(new Set());

  const translateDeToEn = async (field: string) => {
    const deVal = (data.translations.find(t => t.languageCode === 'de') as any)?.[field] || '';
    if (!deVal.trim()) return;
    setTranslating(prev => new Set(prev).add(field));
    try {
      const res = await fetch('/api/v1/translate', {
        method: 'POST', credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: deVal, from: 'de', to: 'en' }),
      });
      if (res.ok) {
        const { translated } = await res.json();
        setTrans('en', field, translated);
        setDeChanged(prev => { const n = new Set(prev); n.delete(field); return n; });
      }
    } catch { /* fallback: copy as-is */
      setTrans('en', field, deVal);
    }
    setTranslating(prev => { const n = new Set(prev); n.delete(field); return n; });
  };"""
)

# Replace all copyDeToEn references with translateDeToEn
content = content.replace("copyDeToEn('", "translateDeToEn('")

# Update button text to show loading state
content = content.replace(
    """<button type="button" onClick={() => translateDeToEn('name')} className="text-[10px] text-gray-400 hover:text-amber-700">DE→EN</button>""",
    """<button type="button" onClick={() => translateDeToEn('name')} disabled={translating.has('name')} className="text-[10px] text-gray-400 hover:text-amber-700 disabled:opacity-50">{translating.has('name') ? '...' : 'DE→EN'}</button>"""
)
content = content.replace(
    """<button type="button" onClick={() => translateDeToEn('shortDescription')} className="text-[10px] text-gray-400 hover:text-amber-700">DE→EN</button>""",
    """<button type="button" onClick={() => translateDeToEn('shortDescription')} disabled={translating.has('shortDescription')} className="text-[10px] text-gray-400 hover:text-amber-700 disabled:opacity-50">{translating.has('shortDescription') ? '...' : 'DE→EN'}</button>"""
)
content = content.replace(
    """<button type="button" onClick={() => translateDeToEn('longDescription')} className="text-[10px] text-gray-400 hover:text-amber-700">DE→EN</button>""",
    """<button type="button" onClick={() => translateDeToEn('longDescription')} disabled={translating.has('longDescription')} className="text-[10px] text-gray-400 hover:text-amber-700 disabled:opacity-50">{translating.has('longDescription') ? '...' : 'DE→EN'}</button>"""
)
content = content.replace(
    """<button type="button" onClick={() => translateDeToEn('servingSuggestion')} className="text-[10px] text-gray-400 hover:text-amber-700">DE→EN</button>""",
    """<button type="button" onClick={() => translateDeToEn('servingSuggestion')} disabled={translating.has('servingSuggestion')} className="text-[10px] text-gray-400 hover:text-amber-700 disabled:opacity-50">{translating.has('servingSuggestion') ? '...' : 'DE→EN'}</button>"""
)

open('src/components/admin/product-editor.tsx', 'w').write(content)
print('Done!')
PYEOF

npm run build && pm2 restart menucard-pro
echo "=== Auto-Translation deployed ==="
