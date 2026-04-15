#!/bin/bash
# Template-Vorschauen auf /admin/design: jede Karte mit eigenem Design
# (Hintergrund, Typografie, Farben, Trennlinien, Produktbeispiele)
set -e
cd /var/www/menucard-pro

echo "[1/3] Backup anlegen..."
cp src/app/admin/design/page.tsx src/app/admin/design/page.tsx.bak.$(date +%Y%m%d-%H%M%S)

echo "[2/3] page.tsx neu schreiben..."
cat > src/app/admin/design/page.tsx << 'ENDOFFILE'
'use client';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

/* Types */
type Menu = {
  id: string;
  name: string;
  slug: string;
  menuType: string;
  designConfig: any;
};

type TemplateInfo = {
  key: string;
  name: string;
  subtitle: string;
  description: string;
  features: string[];
};

/* Template Definitionen */
const templates: TemplateInfo[] = [
  {
    key: 'elegant',
    name: 'Elegant',
    subtitle: 'Zeitloser Luxus',
    description: 'Großzügiger Weißraum, Playfair-Display-Titel in Gold, dezente Akzente. Ideal für gehobene Gastronomie.',
    features: ['Playfair Display', 'Warmer Creme-BG', 'Gold-Akzent', 'Dotted-Separatoren'],
  },
  {
    key: 'modern',
    name: 'Modern',
    subtitle: 'Bold & Visual',
    description: 'Dunkler Hintergrund, Inter Bold, kräftiger Gold-Akzent. Perfekt für Barkarten und bildstarke Präsentationen.',
    features: ['Dark Mode', 'Inter Bold', 'Gold-Akzent #E8C547', 'Card-Layout'],
  },
  {
    key: 'classic',
    name: 'Klassisch',
    subtitle: 'Fine Dining',
    description: 'Nummerierte Gerichte, Cormorant Garamond, französisch inspiriert. Für Gourmet-Erlebnisse.',
    features: ['Cormorant Garamond', 'Nummerierung', 'Doppellinie', 'Cream-BG'],
  },
  {
    key: 'minimal',
    name: 'Minimal',
    subtitle: 'Klar & Reduziert',
    description: 'Nur Text, maximale Lesbarkeit, keine Bilder. Schnell, übersichtlich, auf das Wesentliche reduziert.',
    features: ['Inter', 'Monochrom', 'Hairline-Separatoren', 'Kein Bild'],
  },
];

function getActiveTemplate(menu: Menu): string {
  try {
    const dc = menu.designConfig;
    return dc?.digital?.template || dc?.template || 'elegant';
  } catch {
    return 'elegant';
  }
}

/* ──────────────────────────────────────────
   Authentische Mini-Vorschau pro Template
   ────────────────────────────────────────── */
function TemplatePreview({ templateKey }: { templateKey: string }) {
  // ELEGANT
  if (templateKey === 'elegant') {
    return (
      <div className="relative h-36 overflow-hidden px-5 py-3" style={{ backgroundColor: '#FFF8F0' }}>
        <div
          className="text-center"
          style={{
            fontFamily: "'Playfair Display', serif",
            fontSize: 12,
            fontWeight: 600,
            color: '#8B6914',
            letterSpacing: '0.22em',
            textTransform: 'uppercase',
            marginBottom: 6,
          }}
        >
          Aperitifs
        </div>
        <div style={{ borderBottom: '1px dotted #D4C4A8', marginBottom: 10 }} />
        <div className="flex items-baseline justify-between" style={{ fontFamily: "'Source Sans 3', sans-serif" }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: '#2C1810' }}>Aperol Spritz</div>
            <div style={{ fontSize: 9, fontStyle: 'italic', color: '#999' }}>fruchtig · erfrischend</div>
          </div>
          <div style={{ fontSize: 11, fontWeight: 700, color: '#6B4C1E' }}>€ 9,50</div>
        </div>
        <div className="flex items-baseline justify-between mt-2" style={{ fontFamily: "'Source Sans 3', sans-serif" }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: '#2C1810' }}>Champagner Cuvée</div>
            <div style={{ fontSize: 9, fontStyle: 'italic', color: '#999' }}>zart · mineralisch</div>
          </div>
          <div style={{ fontSize: 11, fontWeight: 700, color: '#6B4C1E' }}>€ 14,00</div>
        </div>
      </div>
    );
  }

  // MODERN
  if (templateKey === 'modern') {
    return (
      <div className="relative h-36 overflow-hidden px-5 py-3" style={{ backgroundColor: '#1A1A2E' }}>
        <div
          style={{
            fontFamily: "'Inter', sans-serif",
            fontSize: 10,
            fontWeight: 800,
            color: '#E8C547',
            letterSpacing: '0.18em',
            textTransform: 'uppercase',
            marginBottom: 6,
          }}
        >
          Cocktails
        </div>
        <div style={{ borderBottom: '2px solid #E8C547', marginBottom: 10 }} />
        <div className="flex items-center justify-between" style={{ fontFamily: "'Inter', sans-serif" }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 700, color: '#F0F0F0' }}>Negroni</div>
            <div style={{ fontSize: 9, color: '#AAAAAA' }}>Gin · Vermouth · Campari</div>
          </div>
          <div style={{ fontSize: 13, fontWeight: 800, color: '#E8C547' }}>14 €</div>
        </div>
        <div className="flex items-center justify-between mt-3" style={{ fontFamily: "'Inter', sans-serif" }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 700, color: '#F0F0F0' }}>Old Fashioned</div>
            <div style={{ fontSize: 9, color: '#AAAAAA' }}>Bourbon · Sugar · Bitters</div>
          </div>
          <div style={{ fontSize: 13, fontWeight: 800, color: '#E8C547' }}>16 €</div>
        </div>
      </div>
    );
  }

  // CLASSIC
  if (templateKey === 'classic') {
    return (
      <div className="relative h-36 overflow-hidden px-5 py-3" style={{ backgroundColor: '#FAFAF5' }}>
        <div
          className="text-center"
          style={{
            fontFamily: "'Cormorant Garamond', 'Playfair Display', serif",
            fontSize: 18,
            fontWeight: 600,
            color: '#6B4C1E',
            marginBottom: 2,
          }}
        >
          Entrées
        </div>
        <div
          style={{
            borderTop: '1px solid #D4C4A8',
            borderBottom: '1px solid #D4C4A8',
            height: 4,
            marginBottom: 8,
          }}
        />
        <div className="flex items-baseline justify-between" style={{ fontFamily: "'Lato', sans-serif" }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, color: '#000' }}>
              <span style={{ color: '#8B6914', marginRight: 6 }}>01</span>Foie Gras
            </div>
            <div style={{ fontSize: 9, color: '#666' }}>Brioche · Feigenchutney</div>
          </div>
          <div style={{ fontSize: 11, fontWeight: 700, color: '#333' }}>€ 28</div>
        </div>
        <div className="flex items-baseline justify-between mt-2" style={{ fontFamily: "'Lato', sans-serif" }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, color: '#000' }}>
              <span style={{ color: '#8B6914', marginRight: 6 }}>02</span>Beef Tartare
            </div>
            <div style={{ fontSize: 9, color: '#666' }}>Rind · Trüffel · Wachtelei</div>
          </div>
          <div style={{ fontSize: 11, fontWeight: 700, color: '#333' }}>€ 24</div>
        </div>
      </div>
    );
  }

  // MINIMAL
  return (
    <div className="relative h-36 overflow-hidden px-5 py-3" style={{ backgroundColor: '#FFFFFF' }}>
      <div
        style={{
          fontFamily: "'Inter', sans-serif",
          fontSize: 10,
          fontWeight: 700,
          color: '#111111',
          letterSpacing: '0.22em',
          textTransform: 'uppercase',
          marginBottom: 10,
        }}
      >
        Speisen
      </div>
      <div style={{ borderBottom: '1px solid #EEEEEE', marginBottom: 8 }} />
      <div className="flex items-center justify-between" style={{ fontFamily: "'Inter', sans-serif" }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: '#111' }}>Rindercarpaccio</div>
        <div style={{ fontSize: 11, fontWeight: 700, color: '#111' }}>18 €</div>
      </div>
      <div style={{ borderBottom: '1px solid #F3F3F3', margin: '6px 0' }} />
      <div className="flex items-center justify-between" style={{ fontFamily: "'Inter', sans-serif" }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: '#111' }}>Wiener Schnitzel</div>
        <div style={{ fontSize: 11, fontWeight: 700, color: '#111' }}>24 €</div>
      </div>
      <div style={{ borderBottom: '1px solid #F3F3F3', margin: '6px 0' }} />
      <div className="flex items-center justify-between" style={{ fontFamily: "'Inter', sans-serif" }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: '#111' }}>Tagliatelle Trüffel</div>
        <div style={{ fontSize: 11, fontWeight: 700, color: '#111' }}>22 €</div>
      </div>
    </div>
  );
}

/* TemplateCard */
function TemplateCard({
  tpl,
  menuCount,
  menuNames,
  isExpanded,
  onToggle,
}: {
  tpl: TemplateInfo;
  menuCount: number;
  menuNames: string[];
  isExpanded: boolean;
  onToggle: () => void;
}) {
  return (
    <div
      className="rounded-xl overflow-hidden transition-all duration-200 hover:shadow-lg cursor-pointer"
      style={{
        border: menuCount > 0 ? '2px solid #DD3C71' : '1px solid #E5E7EB',
        backgroundColor: '#FFFFFF',
        boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
      }}
      onClick={onToggle}
    >
      {/* Authentische Template-Vorschau */}
      <div className="relative">
        <TemplatePreview templateKey={tpl.key} />
        {menuCount > 0 && (
          <div
            className="absolute top-3 right-3 flex items-center gap-1 px-2.5 py-1 rounded-full"
            style={{ backgroundColor: '#DD3C71', color: '#FFF' }}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>check_circle</span>
            <span className="text-[10px] font-bold uppercase tracking-wider">
              {menuCount} {menuCount === 1 ? 'Karte' : 'Karten'}
            </span>
          </div>
        )}
      </div>

      {/* Content */}
      <div className="p-5" style={{ borderTop: '1px solid #F3F3F6' }}>
        <div className="flex items-start justify-between mb-1">
          <h3
            className="text-lg font-bold"
            style={{ fontFamily: "'Playfair Display', serif", color: '#171A1F' }}
          >
            {tpl.name}
          </h3>
        </div>
        <p
          className="text-xs font-semibold uppercase tracking-wider mb-2"
          style={{ color: '#DD3C71' }}
        >
          {tpl.subtitle}
        </p>
        <p className="text-sm leading-relaxed mb-3" style={{ color: '#565D6D' }}>
          {tpl.description}
        </p>
        <div className="flex flex-wrap gap-1.5 mb-3">
          {tpl.features.map((f, i) => (
            <span
              key={i}
              className="text-[10px] font-medium px-2 py-0.5 rounded-full"
              style={{ backgroundColor: '#F3F3F6', color: '#565D6D' }}
            >
              {f}
            </span>
          ))}
        </div>
        {isExpanded && menuNames.length > 0 && (
          <div className="mt-3 pt-3" style={{ borderTop: '1px solid #F3F3F6' }}>
            <div className="text-[11px] font-semibold uppercase tracking-wider mb-2" style={{ color: '#999' }}>
              Zugewiesene Karten
            </div>
            <div className="space-y-1">
              {menuNames.map((name, i) => (
                <div key={i} className="flex items-center gap-2 text-sm" style={{ color: '#171A1F' }}>
                  <span className="material-symbols-outlined" style={{ fontSize: 14, color: '#DD3C71' }}>menu_book</span>
                  {name}
                </div>
              ))}
            </div>
          </div>
        )}
        <div className="flex items-center justify-between mt-3">
          <span className="text-[11px]" style={{ color: '#BBB' }}>
            {menuNames.length > 0
              ? isExpanded
                ? 'Weniger anzeigen'
                : `${menuNames.length} Karte${menuNames.length > 1 ? 'n' : ''} zugewiesen`
              : 'Noch keine Karte zugewiesen'}
          </span>
          {menuNames.length > 0 && (
            <span className="material-symbols-outlined" style={{ fontSize: 16, color: '#CCC' }}>
              {isExpanded ? 'expand_less' : 'expand_more'}
            </span>
          )}
        </div>
      </div>
    </div>
  );
}

/* Vergleichstabelle (Werte an reale Templates angepasst) */
function ComparisonTable() {
  const rows = [
    { label: 'Schriftart', elegant: 'Playfair + Source Sans', modern: 'Inter Bold', classic: 'Cormorant + Lato', minimal: 'Inter' },
    { label: 'Hintergrund', elegant: 'Creme #FFF8F0', modern: 'Dark #1A1A2E', classic: 'Beige #FAFAF5', minimal: 'Weiß #FFFFFF' },
    { label: 'Akzentfarbe', elegant: 'Gold #8B6914', modern: 'Gold #E8C547', classic: 'Braun #6B4C1E', minimal: 'Schwarz #111' },
    { label: 'Separator', elegant: 'Dotted', modern: '2px solid', classic: 'Doppellinie', minimal: 'Hairline' },
    { label: 'Bilder', elegant: 'Optional', modern: 'Großflächig', classic: 'Klein', minimal: 'Keine' },
    { label: 'Allergene', elegant: 'Codes (A, G)', modern: 'Footer', classic: 'Footer', minimal: 'Abkürzungen' },
    { label: 'Ideal für', elegant: 'Weinkarten, Gala', classic: 'Fine Dining', modern: 'Barkarten', minimal: 'Frühstück, Schnellkarten' },
  ];
  return (
    <div className="overflow-x-auto rounded-xl" style={{ border: '1px solid #E5E7EB' }}>
      <table className="w-full text-sm" style={{ fontFamily: "'Inter', sans-serif" }}>
        <thead>
          <tr style={{ backgroundColor: '#F9FAFB' }}>
            <th className="text-left p-3 font-semibold" style={{ color: '#565D6D', minWidth: 120 }}>Eigenschaft</th>
            {templates.map(t => (
              <th key={t.key} className="text-left p-3 font-semibold" style={{ color: '#171A1F', minWidth: 160 }}>
                {t.name}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr key={i} style={{ borderTop: '1px solid #F3F3F6' }}>
              <td className="p-3 font-medium" style={{ color: '#565D6D' }}>{row.label}</td>
              <td className="p-3" style={{ color: '#171A1F' }}>{row.elegant}</td>
              <td className="p-3" style={{ color: '#171A1F' }}>{row.modern}</td>
              <td className="p-3" style={{ color: '#171A1F' }}>{row.classic}</td>
              <td className="p-3" style={{ color: '#171A1F' }}>{row.minimal}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

/* HAUPTSEITE */
export default function DesignOverviewPage() {
  const [menus, setMenus] = useState<Menu[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedCard, setExpandedCard] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    fetch('/api/v1/menus')
      .then(r => r.json())
      .then(data => {
        setMenus(Array.isArray(data) ? data : data.menus || []);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const menusByTemplate: Record<string, Menu[]> = {};
  templates.forEach(t => { menusByTemplate[t.key] = []; });
  menus.forEach(m => {
    const tpl = getActiveTemplate(m);
    if (menusByTemplate[tpl]) {
      menusByTemplate[tpl].push(m);
    } else {
      menusByTemplate['elegant'].push(m);
    }
  });

  return (
    <div className="p-6 max-w-6xl mx-auto">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1
            className="text-2xl font-bold mb-1"
            style={{ fontFamily: "'Playfair Display', serif", color: '#171A1F' }}
          >
            Templates
          </h1>
          <p className="text-sm" style={{ color: '#565D6D' }}>
            Wählen Sie den passenden Stil für Ihre digitalen Speisekarten
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span
            className="flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-full"
            style={{ backgroundColor: '#F3F3F6', color: '#565D6D' }}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>menu_book</span>
            {menus.length} {menus.length === 1 ? 'Karte' : 'Karten'}
          </span>
          <span
            className="flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-full"
            style={{ backgroundColor: '#FDF2F5', color: '#DD3C71' }}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>palette</span>
            4 Templates
          </span>
        </div>
      </div>

      <div
        className="flex items-start gap-3 p-4 rounded-lg mb-8"
        style={{ backgroundColor: '#FDF2F5', border: '1px solid rgba(221,60,113,0.12)' }}
      >
        <span className="material-symbols-outlined flex-shrink-0 mt-0.5" style={{ fontSize: 20, color: '#DD3C71' }}>
          info
        </span>
        <div className="text-sm" style={{ color: '#565D6D' }}>
          <strong style={{ color: '#171A1F' }}>Tipp:</strong> Templates können pro Karte individuell zugewiesen werden.
          Öffnen Sie die jeweilige Karte unter{' '}
          <button
            onClick={() => router.push('/admin/menus')}
            className="underline font-medium"
            style={{ color: '#DD3C71' }}
          >
            Karten
          </button>{' '}
          und wechseln Sie in den Design-Tab, um ein Template auszuwählen und anzupassen.
        </div>
      </div>

      {loading && (
        <div className="flex items-center justify-center py-16">
          <div className="animate-spin rounded-full h-8 w-8 border-2" style={{ borderColor: '#F3F3F6', borderTopColor: '#DD3C71' }} />
        </div>
      )}

      {!loading && (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5 mb-10">
            {templates.map(tpl => (
              <TemplateCard
                key={tpl.key}
                tpl={tpl}
                menuCount={menusByTemplate[tpl.key]?.length || 0}
                menuNames={menusByTemplate[tpl.key]?.map(m => m.name) || []}
                isExpanded={expandedCard === tpl.key}
                onToggle={() => setExpandedCard(expandedCard === tpl.key ? null : tpl.key)}
              />
            ))}
          </div>

          <div className="mb-8">
            <h2
              className="text-lg font-bold mb-4"
              style={{ fontFamily: "'Playfair Display', serif", color: '#171A1F' }}
            >
              Template-Vergleich
            </h2>
            <ComparisonTable />
          </div>

          <div
            className="rounded-xl p-5 flex items-center justify-between"
            style={{ backgroundColor: '#F9FAFB', border: '1px solid #E5E7EB' }}
          >
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined" style={{ fontSize: 24, color: '#DD3C71' }}>auto_fix_high</span>
              <div>
                <div className="text-sm font-semibold" style={{ color: '#171A1F' }}>Template zuweisen</div>
                <div className="text-xs" style={{ color: '#999' }}>Öffnen Sie eine Karte, um Design und Template anzupassen</div>
              </div>
            </div>
            <button
              onClick={() => router.push('/admin/menus')}
              className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-semibold transition-colors"
              style={{ backgroundColor: '#DD3C71', color: '#FFF' }}
              onMouseEnter={e => (e.currentTarget.style.backgroundColor = '#C42D60')}
              onMouseLeave={e => (e.currentTarget.style.backgroundColor = '#DD3C71')}
            >
              <span className="material-symbols-outlined" style={{ fontSize: 16 }}>menu_book</span>
              Zu den Karten
            </button>
          </div>
        </>
      )}
    </div>
  );
}
ENDOFFILE

echo "[3/3] Build & Restart..."
npm run build 2>&1 | tail -20
pm2 restart menucard-pro

echo ""
echo "Fertig. Bitte /admin/design im Browser aufrufen und Screenshot machen."
