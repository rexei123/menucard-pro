'use client';
import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

type Menu = {
  id: string;
  name: string;
  slug: string;
  menuType: string;
  templateId?: string | null;
  template?: { id: string; name: string; baseType: string } | null;
};

type DesignTemplate = {
  id: string;
  name: string;
  type: 'SYSTEM' | 'CUSTOM';
  baseType: string;
  config: any;
  isArchived: boolean;
  createdBy?: string | null;
  _count?: { menus: number };
};

const BASE_META: Record<string, { subtitle: string; description: string; features: string[] }> = {
  elegant: {
    subtitle: 'Zeitloser Luxus',
    description: 'Großzügiger Weißraum, Playfair-Display-Titel in Gold, kursive Beschreibungen in Source Sans 3. Ideal für gehobene Gastronomie und Weinkarten.',
    features: ['Playfair Display', 'Source Sans 3', 'Gold #8B6914', 'Creme #FFF8F0'],
  },
  modern: {
    subtitle: 'Bold & Visual',
    description: 'Dunkler Hintergrund, Inter Bold, kräftiger Gold-Akzent mit 2px-Separator. Perfekt für Barkarten und bildstarke Präsentationen.',
    features: ['Inter Bold', 'Dark #1A1A2E', 'Gold #E8C547', '2px Separator'],
  },
  classic: {
    subtitle: 'Fine Dining',
    description: 'Cormorant Garamond Überschriften in Braun, Lato-Body, zartgelbe Doppellinie. Französisch inspirierte Eleganz für Gourmet-Menüs.',
    features: ['Cormorant Garamond', 'Lato', 'Braun #6B4C1E', 'Doppellinie'],
  },
  minimal: {
    subtitle: 'Klar & Reduziert',
    description: 'Inter in Graustufen, Hairline-Separatoren #EEEEEE, keine Bilder. Maximale Lesbarkeit für Frühstück und Schnellkarten.',
    features: ['Inter', 'Monochrom', 'Hairline #EEE', 'Kein Bild'],
  },
};

function TemplatePreview({ baseType }: { baseType: string }) {
  if (baseType === 'elegant') {
    return (
      <div className="relative h-44 px-5 py-4" style={{ backgroundColor: '#FFF8F0' }}>
        <div className="text-center" style={{ fontFamily: "'Playfair Display', Georgia, serif", fontSize: 13, fontWeight: 600, color: '#8B6914', letterSpacing: '0.05em', textTransform: 'uppercase', marginBottom: 10 }}>Aperitifs</div>
        <div style={{ borderBottom: '1px solid #D4A853', marginBottom: 12 }} />
        <div className="flex items-baseline justify-between" style={{ fontFamily: "'Source Sans 3', 'Source Sans Pro', sans-serif" }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#333333' }}>Aperol Spritz</div>
            <div style={{ fontSize: 10, fontStyle: 'italic', color: '#777777', fontWeight: 400 }}>fruchtig · erfrischend</div>
          </div>
          <div style={{ fontSize: 12, fontWeight: 700, color: '#6B4C1E' }}>€ 9,50</div>
        </div>
        <div className="flex items-baseline justify-between mt-3" style={{ fontFamily: "'Source Sans 3', 'Source Sans Pro', sans-serif" }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#333333' }}>Champagner Cuvée</div>
            <div style={{ fontSize: 10, fontStyle: 'italic', color: '#777777', fontWeight: 400 }}>zart · mineralisch</div>
          </div>
          <div style={{ fontSize: 12, fontWeight: 700, color: '#6B4C1E' }}>€ 14,00</div>
        </div>
      </div>
    );
  }
  if (baseType === 'modern') {
    return (
      <div className="relative h-44 px-5 py-4" style={{ backgroundColor: '#1A1A2E' }}>
        <div style={{ fontFamily: "'Inter', sans-serif", fontSize: 12, fontWeight: 700, color: '#E8C547', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10 }}>Cocktails</div>
        <div style={{ borderBottom: '2px solid #E8C547', marginBottom: 12 }} />
        <div className="flex items-center justify-between" style={{ fontFamily: "'Inter', sans-serif" }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#F0F0F0' }}>Negroni</div>
            <div style={{ fontSize: 10, color: '#AAAAAA', fontWeight: 400 }}>Gin · Vermouth · Campari</div>
          </div>
          <div style={{ fontSize: 13, fontWeight: 800, color: '#E8C547' }}>14 €</div>
        </div>
        <div className="flex items-center justify-between mt-3" style={{ fontFamily: "'Inter', sans-serif" }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#F0F0F0' }}>Old Fashioned</div>
            <div style={{ fontSize: 10, color: '#AAAAAA', fontWeight: 400 }}>Bourbon · Sugar · Bitters</div>
          </div>
          <div style={{ fontSize: 13, fontWeight: 800, color: '#E8C547' }}>16 €</div>
        </div>
      </div>
    );
  }
  if (baseType === 'classic') {
    return (
      <div className="relative h-44 px-5 py-4" style={{ backgroundColor: '#FAFAF5' }}>
        <div className="text-center" style={{ fontFamily: "'Cormorant Garamond', 'Playfair Display', Georgia, serif", fontSize: 20, fontWeight: 600, color: '#6B4C1E', letterSpacing: '0.02em', marginBottom: 4 }}>Entrées</div>
        <div style={{ borderTop: '1px solid #D4C4A8', borderBottom: '1px solid #D4C4A8', height: 4, marginBottom: 12 }} />
        <div className="flex items-baseline justify-between" style={{ fontFamily: "'Lato', 'Helvetica Neue', sans-serif" }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#333333' }}>Foie Gras</div>
            <div style={{ fontSize: 10, color: '#666666', fontWeight: 400 }}>Brioche · Feigenchutney</div>
          </div>
          <div style={{ fontSize: 12, fontWeight: 700, color: '#333333' }}>€ 28</div>
        </div>
        <div className="flex items-baseline justify-between mt-3" style={{ fontFamily: "'Lato', 'Helvetica Neue', sans-serif" }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#333333' }}>Beef Tartare</div>
            <div style={{ fontSize: 10, color: '#666666', fontWeight: 400 }}>Rind · Trüffel · Wachtelei</div>
          </div>
          <div style={{ fontSize: 12, fontWeight: 700, color: '#333333' }}>€ 24</div>
        </div>
      </div>
    );
  }
  return (
    <div className="relative h-44 px-5 py-4" style={{ backgroundColor: '#FFFFFF' }}>
      <div style={{ fontFamily: "'Inter', sans-serif", fontSize: 11, fontWeight: 600, color: '#333333', letterSpacing: '0.06em', textTransform: 'uppercase', marginBottom: 12 }}>Speisen</div>
      <div style={{ borderBottom: '1px solid #EEEEEE', marginBottom: 10 }} />
      <div className="flex items-center justify-between" style={{ fontFamily: "'Inter', sans-serif" }}>
        <div style={{ fontSize: 12, fontWeight: 600, color: '#222222' }}>Rindercarpaccio</div>
        <div style={{ fontSize: 12, fontWeight: 700, color: '#111111' }}>18 €</div>
      </div>
      <div style={{ borderBottom: '1px solid #F0F0F0', margin: '8px 0' }} />
      <div className="flex items-center justify-between" style={{ fontFamily: "'Inter', sans-serif" }}>
        <div style={{ fontSize: 12, fontWeight: 600, color: '#222222' }}>Wiener Schnitzel</div>
        <div style={{ fontSize: 12, fontWeight: 700, color: '#111111' }}>24 €</div>
      </div>
      <div style={{ borderBottom: '1px solid #F0F0F0', margin: '8px 0' }} />
      <div className="flex items-center justify-between" style={{ fontFamily: "'Inter', sans-serif" }}>
        <div style={{ fontSize: 12, fontWeight: 600, color: '#222222' }}>Tagliatelle Trüffel</div>
        <div style={{ fontSize: 12, fontWeight: 700, color: '#111111' }}>22 €</div>
      </div>
    </div>
  );
}

function ActionBtn({ icon, label, color, onClick, disabled, title }: { icon: string; label: string; color?: string; onClick: () => void; disabled?: boolean; title?: string }) {
  return (
    <button
      onClick={(e) => { e.stopPropagation(); if (!disabled) onClick(); }}
      disabled={disabled}
      title={title || label}
      className="flex items-center gap-1 px-2.5 py-1.5 rounded-md text-xs font-medium transition-colors"
      style={{
        backgroundColor: disabled ? '#F3F3F6' : '#FFFFFF',
        color: disabled ? '#BBB' : (color || '#565D6D'),
        border: `1px solid ${disabled ? '#ECECEC' : '#E5E7EB'}`,
        cursor: disabled ? 'not-allowed' : 'pointer',
      }}
    >
      <span className="material-symbols-outlined" style={{ fontSize: 15 }}>{icon}</span>
      {label}
    </button>
  );
}

function TemplateCard({
  tpl, menuNames, isExpanded, onToggle,
  onDuplicate, onEdit, onArchive, onRestore,
}: {
  tpl: DesignTemplate;
  menuNames: string[];
  isExpanded: boolean;
  onToggle: () => void;
  onDuplicate: () => void;
  onEdit: () => void;
  onArchive: () => void;
  onRestore: () => void;
}) {
  const meta = BASE_META[tpl.baseType] || BASE_META.elegant;
  const menuCount = menuNames.length;
  const isSystem = tpl.type === 'SYSTEM';
  const isArchived = tpl.isArchived;
  const hasMenus = menuCount > 0;

  return (
    <div
      className="rounded-xl overflow-hidden transition-all duration-200 hover:shadow-lg"
      style={{
        border: hasMenus ? '2px solid #DD3C71' : '1px solid #E5E7EB',
        backgroundColor: '#FFFFFF',
        boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
        opacity: isArchived ? 0.85 : 1,
      }}
    >
      {/* Metadaten-Leiste OBERHALB der Vorschau - überdeckt nichts */}
      <div className="flex items-center justify-between px-3 py-2"
           style={{ backgroundColor: '#F9FAFB', borderBottom: '1px solid #F3F3F6' }}>
        <div className="flex items-center gap-1.5">
          {isSystem ? (
            <span className="flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider"
                  style={{ backgroundColor: '#E5E7EB', color: '#4B5563' }}>
              <span className="material-symbols-outlined" style={{ fontSize: 12 }}>lock</span>
              System
            </span>
          ) : (
            <span className="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider"
                  style={{ backgroundColor: '#FDF2F5', color: '#DD3C71' }}>
              Eigene Vorlage
            </span>
          )}
          {isArchived && (
            <span className="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider"
                  style={{ backgroundColor: '#6B7280', color: '#FFF' }}>
              Archiviert
            </span>
          )}
        </div>
        {hasMenus && (
          <div className="flex items-center gap-1 px-2 py-0.5 rounded-full"
               style={{ backgroundColor: '#DD3C71', color: '#FFF' }}>
            <span className="material-symbols-outlined" style={{ fontSize: 12 }}>check_circle</span>
            <span className="text-[10px] font-bold uppercase tracking-wider">
              {menuCount} {menuCount === 1 ? 'Karte' : 'Karten'}
            </span>
          </div>
        )}
      </div>

      {/* Vorschau (ohne Overlay) */}
      <div className="cursor-pointer" onClick={onToggle}>
        <TemplatePreview baseType={tpl.baseType} />
      </div>

      <div className="p-5" style={{ borderTop: '1px solid #F3F3F6' }}>
        <h3 className="text-lg font-bold mb-1" style={{ fontFamily: "'Playfair Display', serif", color: '#171A1F' }}>
          {tpl.name}
        </h3>
        <p className="text-xs font-semibold uppercase tracking-wider mb-2" style={{ color: '#DD3C71' }}>
          {meta.subtitle}
        </p>
        <p className="text-sm leading-relaxed mb-3" style={{ color: '#565D6D' }}>
          {meta.description}
        </p>
        <div className="flex flex-wrap gap-1.5 mb-3">
          {meta.features.map((f, i) => (
            <span key={i} className="text-[10px] font-medium px-2 py-0.5 rounded-full"
                  style={{ backgroundColor: '#F3F3F6', color: '#565D6D' }}>
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
        <div className="flex items-center flex-wrap gap-2 mt-4 pt-3" style={{ borderTop: '1px solid #F3F3F6' }}>
          {!isArchived && (
            <>
              <ActionBtn icon="content_copy" label="Duplizieren" onClick={onDuplicate}
                         color="#DD3C71" title="Eine eigene, editierbare Kopie erstellen" />
              <ActionBtn icon="edit" label="Bearbeiten" onClick={onEdit}
                         disabled={isSystem}
                         title={isSystem ? 'System-Vorlagen sind schreibgeschützt. Bitte zuerst duplizieren.' : 'Template bearbeiten'} />
              <ActionBtn icon="archive" label="Archivieren" onClick={onArchive}
                         disabled={isSystem || hasMenus}
                         title={isSystem
                           ? 'System-Vorlagen können nicht archiviert werden.'
                           : hasMenus
                             ? 'Nur möglich, wenn keine Karte zugewiesen ist.'
                             : 'In Archiv verschieben'} />
            </>
          )}
          {isArchived && (
            <ActionBtn icon="unarchive" label="Wiederherstellen" onClick={onRestore}
                       color="#DD3C71" title="Zurück in aktive Vorlagen" />
          )}
          <div className="ml-auto flex items-center gap-1 cursor-pointer text-[11px]" style={{ color: '#BBB' }} onClick={onToggle}>
            {menuCount > 0 && (isExpanded ? 'Weniger' : `${menuCount} Karte${menuCount > 1 ? 'n' : ''}`)}
            {menuCount > 0 && (
              <span className="material-symbols-outlined" style={{ fontSize: 15, color: '#CCC' }}>
                {isExpanded ? 'expand_less' : 'expand_more'}
              </span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function DuplicateDialog({ source, onClose, onConfirm }: { source: DesignTemplate; onClose: () => void; onConfirm: (name: string) => Promise<void> }) {
  const [name, setName] = useState(`${source.name} (Kopie)`);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ backgroundColor: 'rgba(0,0,0,0.4)' }} onClick={onClose}>
      <div className="bg-white rounded-xl w-full max-w-md p-6 shadow-xl" onClick={(e) => e.stopPropagation()}>
        <h3 className="text-lg font-bold mb-1" style={{ fontFamily: "'Playfair Display', serif", color: '#171A1F' }}>
          Vorlage duplizieren
        </h3>
        <p className="text-sm mb-4" style={{ color: '#565D6D' }}>
          Es wird eine eigene, bearbeitbare Kopie von <strong>{source.name}</strong> angelegt.
        </p>
        <label className="block text-xs font-semibold uppercase tracking-wider mb-1" style={{ color: '#565D6D' }}>
          Name der neuen Vorlage
        </label>
        <input type="text" value={name} onChange={(e) => setName(e.target.value)} autoFocus
               className="w-full px-3 py-2 rounded-md text-sm"
               style={{ border: '1px solid #E5E7EB', color: '#171A1F' }} />
        {error && <div className="mt-3 text-xs p-2 rounded" style={{ backgroundColor: '#FEF2F2', color: '#B91C1C' }}>{error}</div>}
        <div className="flex justify-end gap-2 mt-5">
          <button onClick={onClose} disabled={busy} className="px-4 py-2 rounded-md text-sm font-medium"
                  style={{ backgroundColor: '#F3F3F6', color: '#565D6D' }}>
            Abbrechen
          </button>
          <button
            onClick={async () => {
              if (!name.trim()) { setError('Bitte Namen eingeben.'); return; }
              setBusy(true); setError(null);
              try { await onConfirm(name.trim()); }
              catch (e: any) { setError(e.message || 'Fehler beim Duplizieren'); }
              finally { setBusy(false); }
            }}
            disabled={busy}
            className="px-4 py-2 rounded-md text-sm font-semibold"
            style={{ backgroundColor: '#DD3C71', color: '#FFF', opacity: busy ? 0.6 : 1 }}>
            {busy ? 'Wird erstellt …' : 'Duplizieren'}
          </button>
        </div>
      </div>
    </div>
  );
}

function ConfirmDialog({ title, message, confirmLabel, onCancel, onConfirm }: { title: string; message: string; confirmLabel: string; onCancel: () => void; onConfirm: () => Promise<void> }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ backgroundColor: 'rgba(0,0,0,0.4)' }} onClick={onCancel}>
      <div className="bg-white rounded-xl w-full max-w-md p-6 shadow-xl" onClick={(e) => e.stopPropagation()}>
        <h3 className="text-lg font-bold mb-1" style={{ fontFamily: "'Playfair Display', serif", color: '#171A1F' }}>{title}</h3>
        <p className="text-sm mb-4" style={{ color: '#565D6D' }}>{message}</p>
        {error && <div className="mb-3 text-xs p-2 rounded" style={{ backgroundColor: '#FEF2F2', color: '#B91C1C' }}>{error}</div>}
        <div className="flex justify-end gap-2">
          <button onClick={onCancel} disabled={busy} className="px-4 py-2 rounded-md text-sm font-medium"
                  style={{ backgroundColor: '#F3F3F6', color: '#565D6D' }}>
            Abbrechen
          </button>
          <button
            onClick={async () => {
              setBusy(true); setError(null);
              try { await onConfirm(); }
              catch (e: any) { setError(e.message || 'Fehler'); }
              finally { setBusy(false); }
            }}
            disabled={busy}
            className="px-4 py-2 rounded-md text-sm font-semibold"
            style={{ backgroundColor: '#DD3C71', color: '#FFF', opacity: busy ? 0.6 : 1 }}>
            {busy ? 'Bitte warten …' : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

function ComparisonTable() {
  const rows = [
    { label: 'Überschrift-Font', elegant: 'Playfair Display 22px', modern: 'Inter 20px Bold', classic: 'Cormorant Garamond 24px', minimal: 'Inter 18px' },
    { label: 'Body-Font', elegant: 'Source Sans 3 italic', modern: 'Inter', classic: 'Lato', minimal: 'Inter' },
    { label: 'Hintergrund', elegant: '#FFF8F0 Creme', modern: '#1A1A2E Dark', classic: '#FAFAF5 Beige', minimal: '#FFFFFF Weiß' },
    { label: 'Akzentfarbe', elegant: 'Gold #8B6914', modern: 'Gold #E8C547', classic: 'Braun #6B4C1E', minimal: 'Schwarz #333' },
    { label: 'Sektionslinie', elegant: '1px solid Gold', modern: '2px solid Gold', classic: '1px double Beige', minimal: '1px solid #EEE' },
    { label: 'Bilder', elegant: 'Rund 64px', modern: 'Rund 80px', classic: 'Aus', minimal: 'Aus' },
    { label: 'Ideal für', elegant: 'Weinkarten, Gala', modern: 'Barkarte, Cocktails', classic: 'Fine Dining', minimal: 'Frühstück, Schnellkarten' },
  ];
  const cols = [
    { key: 'elegant', name: 'Elegant' },
    { key: 'modern', name: 'Modern' },
    { key: 'classic', name: 'Klassisch' },
    { key: 'minimal', name: 'Minimal' },
  ];
  return (
    <div className="overflow-x-auto rounded-xl" style={{ border: '1px solid #E5E7EB' }}>
      <table className="w-full text-sm" style={{ fontFamily: "'Inter', sans-serif" }}>
        <thead>
          <tr style={{ backgroundColor: '#F9FAFB' }}>
            <th className="text-left p-3 font-semibold" style={{ color: '#565D6D', minWidth: 140 }}>Eigenschaft</th>
            {cols.map(t => (
              <th key={t.key} className="text-left p-3 font-semibold" style={{ color: '#171A1F', minWidth: 170 }}>{t.name}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row: any, i) => (
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

export default function DesignOverviewPage() {
  const [menus, setMenus] = useState<Menu[]>([]);
  const [dbTemplates, setDbTemplates] = useState<DesignTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'active' | 'archived'>('active');
  const [expandedCard, setExpandedCard] = useState<string | null>(null);
  const [duplicateSource, setDuplicateSource] = useState<DesignTemplate | null>(null);
  const [archiveTarget, setArchiveTarget] = useState<DesignTemplate | null>(null);
  const [restoreTarget, setRestoreTarget] = useState<DesignTemplate | null>(null);
  const router = useRouter();

  const loadAll = useCallback(async () => {
    setLoading(true);
    try {
      const [mRes, tRes] = await Promise.all([
        fetch('/api/v1/menus'),
        fetch('/api/v1/design-templates?includeArchived=true'),
      ]);
      const mData = await mRes.json();
      const tData = await tRes.json();
      setMenus(Array.isArray(mData) ? mData : mData.menus || []);
      setDbTemplates(tData.templates || []);
    } catch (e) { console.error(e); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { loadAll(); }, [loadAll]);

  const menusByTemplateId: Record<string, Menu[]> = {};
  menus.forEach(m => {
    const id = m.templateId || 'none';
    if (!menusByTemplateId[id]) menusByTemplateId[id] = [];
    menusByTemplateId[id].push(m);
  });

  const visibleTemplates = dbTemplates.filter(t => activeTab === 'active' ? !t.isArchived : t.isArchived);
  const activeCount = dbTemplates.filter(t => !t.isArchived).length;
  const archivedCount = dbTemplates.filter(t => t.isArchived).length;

  const handleDuplicate = async (name: string) => {
    if (!duplicateSource) return;
    const res = await fetch(`/api/v1/design-templates/${duplicateSource.id}/duplicate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || `Fehler ${res.status}`);
    }
    setDuplicateSource(null);
    await loadAll();
  };

  const handleArchive = async () => {
    if (!archiveTarget) return;
    const res = await fetch(`/api/v1/design-templates/${archiveTarget.id}`, { method: 'DELETE' });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || `Fehler ${res.status}`);
    }
    setArchiveTarget(null);
    await loadAll();
  };

  const handleRestore = async () => {
    if (!restoreTarget) return;
    const res = await fetch(`/api/v1/design-templates/${restoreTarget.id}/restore`, { method: 'POST' });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || `Fehler ${res.status}`);
    }
    setRestoreTarget(null);
    await loadAll();
  };

  const customActive = dbTemplates.filter(t => t.type === 'CUSTOM' && !t.isArchived).length;
  const capReached = customActive >= 6;

  return (
    <div className="p-6 max-w-6xl mx-auto pb-16">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold mb-1" style={{ fontFamily: "'Playfair Display', serif", color: '#171A1F' }}>
            Kartendesign – Werkstatt
          </h1>
          <p className="text-sm" style={{ color: '#565D6D' }}>
            Verwalten Sie System-Vorlagen, eigene Designs und Zuweisungen zu Karten.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-full"
                style={{ backgroundColor: '#F3F3F6', color: '#565D6D' }}>
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>menu_book</span>
            {menus.length} {menus.length === 1 ? 'Karte' : 'Karten'}
          </span>
          <span className="flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-full"
                style={{ backgroundColor: '#FDF2F5', color: '#DD3C71' }}>
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>palette</span>
            {activeCount} aktive Vorlagen
          </span>
        </div>
      </div>

      <div className="flex items-center gap-2 mb-5" style={{ borderBottom: '1px solid #E5E7EB' }}>
        <button
          onClick={() => setActiveTab('active')}
          className="px-4 py-2 text-sm font-semibold transition-colors"
          style={{
            color: activeTab === 'active' ? '#DD3C71' : '#565D6D',
            borderBottom: activeTab === 'active' ? '2px solid #DD3C71' : '2px solid transparent',
            marginBottom: -1,
          }}>
          Aktive Vorlagen ({activeCount})
        </button>
        <button
          onClick={() => setActiveTab('archived')}
          className="px-4 py-2 text-sm font-semibold transition-colors"
          style={{
            color: activeTab === 'archived' ? '#DD3C71' : '#565D6D',
            borderBottom: activeTab === 'archived' ? '2px solid #DD3C71' : '2px solid transparent',
            marginBottom: -1,
          }}>
          Archiv ({archivedCount})
        </button>
        <div className="ml-auto text-xs" style={{ color: capReached ? '#B91C1C' : '#999' }}>
          Eigene Vorlagen: {customActive} / 6
        </div>
      </div>

      {capReached && activeTab === 'active' && (
        <div className="flex items-start gap-3 p-3 rounded-lg mb-5"
             style={{ backgroundColor: '#FEF2F2', border: '1px solid #FCA5A5' }}>
          <span className="material-symbols-outlined flex-shrink-0 mt-0.5" style={{ fontSize: 18, color: '#B91C1C' }}>warning</span>
          <div className="text-sm" style={{ color: '#7F1D1D' }}>
            Die maximale Anzahl eigener Vorlagen (6) ist erreicht. Bitte archivieren Sie zuerst eine bestehende Vorlage, bevor Sie eine neue duplizieren.
          </div>
        </div>
      )}

      {loading && (
        <div className="flex items-center justify-center py-16">
          <div className="animate-spin rounded-full h-8 w-8 border-2"
               style={{ borderColor: '#F3F3F6', borderTopColor: '#DD3C71' }} />
        </div>
      )}

      {!loading && visibleTemplates.length === 0 && (
        <div className="text-center py-16" style={{ color: '#999' }}>
          <span className="material-symbols-outlined" style={{ fontSize: 40 }}>inventory_2</span>
          <div className="mt-2 text-sm">
            {activeTab === 'archived' ? 'Keine archivierten Vorlagen.' : 'Keine aktiven Vorlagen.'}
          </div>
        </div>
      )}

      {!loading && visibleTemplates.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5 mb-10">
          {visibleTemplates.map(tpl => {
            const menusList = menusByTemplateId[tpl.id] || [];
            return (
              <TemplateCard
                key={tpl.id}
                tpl={tpl}
                menuNames={menusList.map(m => m.name)}
                isExpanded={expandedCard === tpl.id}
                onToggle={() => setExpandedCard(expandedCard === tpl.id ? null : tpl.id)}
                onDuplicate={() => setDuplicateSource(tpl)}
                onEdit={() => router.push(`/admin/design/${tpl.id}/edit`)}
                onArchive={() => setArchiveTarget(tpl)}
                onRestore={() => setRestoreTarget(tpl)}
              />
            );
          })}
        </div>
      )}

      {!loading && activeTab === 'active' && (
        <>
          <div className="mb-8">
            <h2 className="text-lg font-bold mb-4" style={{ fontFamily: "'Playfair Display', serif", color: '#171A1F' }}>
              Template-Vergleich
            </h2>
            <ComparisonTable />
          </div>
          <div className="rounded-xl p-5 flex items-center justify-between"
               style={{ backgroundColor: '#F9FAFB', border: '1px solid #E5E7EB' }}>
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined" style={{ fontSize: 24, color: '#DD3C71' }}>auto_fix_high</span>
              <div>
                <div className="text-sm font-semibold" style={{ color: '#171A1F' }}>Vorlage einer Karte zuweisen</div>
                <div className="text-xs" style={{ color: '#999' }}>
                  Öffnen Sie eine Karte, um dort eine Vorlage auszuwählen.
                </div>
              </div>
            </div>
            <button
              onClick={() => router.push('/admin/menus')}
              className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-semibold transition-colors"
              style={{ backgroundColor: '#DD3C71', color: '#FFF' }}
              onMouseEnter={e => (e.currentTarget.style.backgroundColor = '#C42D60')}
              onMouseLeave={e => (e.currentTarget.style.backgroundColor = '#DD3C71')}>
              <span className="material-symbols-outlined" style={{ fontSize: 16 }}>menu_book</span>
              Zu den Karten
            </button>
          </div>
        </>
      )}

      {duplicateSource && (
        <DuplicateDialog
          source={duplicateSource}
          onClose={() => setDuplicateSource(null)}
          onConfirm={handleDuplicate}
        />
      )}
      {archiveTarget && (
        <ConfirmDialog
          title="Vorlage archivieren"
          message={`Möchten Sie „${archiveTarget.name}" wirklich archivieren? Sie können die Vorlage später jederzeit wiederherstellen.`}
          confirmLabel="Archivieren"
          onCancel={() => setArchiveTarget(null)}
          onConfirm={handleArchive}
        />
      )}
      {restoreTarget && (
        <ConfirmDialog
          title="Vorlage wiederherstellen"
          message={`Möchten Sie „${restoreTarget.name}" zurück in die aktiven Vorlagen verschieben?`}
          confirmLabel="Wiederherstellen"
          onCancel={() => setRestoreTarget(null)}
          onConfirm={handleRestore}
        />
      )}
    </div>
  );
}
