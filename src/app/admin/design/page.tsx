'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

/* ──────────────────────────────────────────
   Types
   ────────────────────────────────────────── */
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
  icon: string;
  features: string[];
  previewBg: string;
  previewAccent: string;
};

/* ──────────────────────────────────────────
   Template Definitionen
   ────────────────────────────────────────── */
const templates: TemplateInfo[] = [
  {
    key: 'elegant',
    name: 'Elegant',
    subtitle: 'Zeitloser Luxus',
    description: 'Großzügiger Weißraum, serifenlose Typografie, dezente Akzente. Ideal für gehobene Gastronomie.',
    icon: 'spa',
    features: ['Uppercase-Titel', 'Kursive Beschreibungen', 'Border-Separatoren', 'Allergen-Codes'],
    previewBg: '#FFFFFF',
    previewAccent: '#DD3C71',
  },
  {
    key: 'modern',
    name: 'Modern',
    subtitle: 'Bold & Visual',
    description: 'Großflächige Bilder, Card-Layout, kräftige Typografie. Perfekt für bildstarke Präsentationen.',
    icon: 'grid_view',
    features: ['Card-Layout', 'Große Bilder', 'Highlight-Badges', '2-Spalten Grid'],
    previewBg: '#FFFFFF',
    previewAccent: '#DD3C71',
  },
  {
    key: 'classic',
    name: 'Klassisch',
    subtitle: 'Fine Dining',
    description: 'Nummerierte Gerichte, Playfair Serif, französisch inspiriert. Für Gourmet-Erlebnisse.',
    icon: 'restaurant',
    features: ['Nummerierung (01, 02...)', 'Serif-Schrift', 'Cream-Hintergrund', 'Dekorative Header'],
    previewBg: '#FDFBF7',
    previewAccent: '#DD3C71',
  },
  {
    key: 'minimal',
    name: 'Minimal',
    subtitle: 'Klar & Reduziert',
    description: 'Nur Text, maximale Lesbarkeit, keine Bilder. Schnell, übersichtlich, auf das Wesentliche reduziert.',
    icon: 'text_fields',
    features: ['Nur Text', 'Montserrat Bold', 'Inline-Allergene', 'Uppercase-Tags'],
    previewBg: '#FFFFFF',
    previewAccent: '#DD3C71',
  },
];

/* ──────────────────────────────────────────
   Hilfsfunktion: Template aus designConfig lesen
   ────────────────────────────────────────── */
function getActiveTemplate(menu: Menu): string {
  try {
    const dc = menu.designConfig;
    return dc?.digital?.template || dc?.template || 'elegant';
  } catch {
    return 'elegant';
  }
}

/* ──────────────────────────────────────────
   Komponente: TemplateCard
   ────────────────────────────────────────── */
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
      {/* Preview-Header */}
      <div
        className="relative h-36 flex items-center justify-center"
        style={{ backgroundColor: tpl.previewBg }}
      >
        {/* Dezentes Muster */}
        <div className="absolute inset-0 opacity-[0.03]" style={{
          backgroundImage: 'radial-gradient(circle, #000 1px, transparent 1px)',
          backgroundSize: '20px 20px',
        }} />

        <div className="relative text-center">
          <span
            className="material-symbols-outlined mb-2 block"
            style={{ fontSize: 40, color: tpl.previewAccent, fontVariationSettings: "'FILL' 0, 'wght' 300" }}
          >
            {tpl.icon}
          </span>
          <div
            className="text-xs font-semibold uppercase tracking-widest"
            style={{ color: '#999', fontFamily: "'Inter', sans-serif" }}
          >
            Template
          </div>
        </div>

        {/* Aktiv-Badge */}
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
      <div className="p-5">
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

        {/* Features */}
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

        {/* Zugewiesene Karten */}
        {isExpanded && menuNames.length > 0 && (
          <div
            className="mt-3 pt-3"
            style={{ borderTop: '1px solid #F3F3F6' }}
          >
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

        {/* Toggle-Hinweis */}
        <div className="flex items-center justify-between mt-3">
          <span className="text-[11px]" style={{ color: '#BBB' }}>
            {menuNames.length > 0 ? (isExpanded ? 'Weniger anzeigen' : `${menuNames.length} Karte${menuNames.length > 1 ? 'n' : ''} zugewiesen`) : 'Noch keine Karte zugewiesen'}
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

/* ──────────────────────────────────────────
   Komponente: Vergleichstabelle
   ────────────────────────────────────────── */
function ComparisonTable() {
  const rows = [
    { label: 'Schriftart', elegant: 'Inter / Serif-Akzent', modern: 'Montserrat Bold', classic: 'Playfair Display', minimal: 'Montserrat' },
    { label: 'Bilder', elegant: 'Optional, dezent', modern: 'Großflächig', classic: 'Klein / Thumbnail', minimal: 'Keine' },
    { label: 'Layout', elegant: 'Listen-basiert', modern: 'Card-Grid', classic: 'Nummeriert', minimal: 'Nur Text' },
    { label: 'Weißraum', elegant: 'Viel', modern: 'Mittel', classic: 'Großzügig', minimal: 'Kompakt' },
    { label: 'Allergene', elegant: 'Code [A,G]', modern: 'Initialen', classic: 'Initialen', minimal: 'Inline-Code' },
    { label: 'Highlight-Badges', elegant: 'Dezent', modern: 'Prominent', classic: 'Outline-Rahmen', minimal: 'Uppercase-Text' },
    { label: 'Ideal für', elegant: 'Fine Dining', modern: 'Visual Menus', classic: 'Gourmet / Franz.', minimal: 'Schnelle Übersicht' },
  ];

  return (
    <div className="overflow-x-auto rounded-xl" style={{ border: '1px solid #E5E7EB' }}>
      <table className="w-full text-sm" style={{ fontFamily: "'Inter', sans-serif" }}>
        <thead>
          <tr style={{ backgroundColor: '#F9FAFB' }}>
            <th className="text-left p-3 font-semibold" style={{ color: '#565D6D', minWidth: 120 }}>Eigenschaft</th>
            {templates.map(t => (
              <th key={t.key} className="text-left p-3 font-semibold" style={{ color: '#171A1F', minWidth: 140 }}>
                <span className="material-symbols-outlined mr-1 align-middle" style={{ fontSize: 16, color: '#DD3C71' }}>{t.icon}</span>
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

/* ──────────────────────────────────────────
   HAUPTSEITE
   ────────────────────────────────────────── */
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

  // Karten pro Template gruppieren
  const menusByTemplate: Record<string, Menu[]> = {};
  templates.forEach(t => { menusByTemplate[t.key] = []; });
  menus.forEach(m => {
    const tpl = getActiveTemplate(m);
    if (menusByTemplate[tpl]) {
      menusByTemplate[tpl].push(m);
    } else {
      // Fallback: zum ersten Template
      menusByTemplate['elegant'].push(m);
    }
  });

  return (
    <div className="p-6 max-w-6xl mx-auto">
      {/* Header */}
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

      {/* Hinweis */}
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

      {/* Loading */}
      {loading && (
        <div className="flex items-center justify-center py-16">
          <div className="animate-spin rounded-full h-8 w-8 border-2" style={{ borderColor: '#F3F3F6', borderTopColor: '#DD3C71' }} />
        </div>
      )}

      {/* Template Grid */}
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

          {/* Vergleichstabelle */}
          <div className="mb-8">
            <h2
              className="text-lg font-bold mb-4"
              style={{ fontFamily: "'Playfair Display', serif", color: '#171A1F' }}
            >
              Template-Vergleich
            </h2>
            <ComparisonTable />
          </div>

          {/* Quick Actions */}
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
