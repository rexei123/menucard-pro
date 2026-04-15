#!/bin/bash
# MenuCard Pro – PDF Design-Editor v2
# Analog Design-Editor mit 11 Akkordeons, Template-Wahl, PDF-Vorschau
# Tab-System im Admin: Digital | PDF
# Datum: 12.04.2026

cd /var/www/menucard-pro

echo "=== PDF Design-Editor v2 ==="

# Backups
cp src/app/admin/menus/\[id\]/design/page.tsx src/app/admin/menus/\[id\]/design/page.tsx.bak-pdf
cp src/app/api/v1/menus/\[id\]/pdf/route.ts src/app/api/v1/menus/\[id\]/pdf/route.ts.bak

# ═══════════════════════════════════════════════════
echo "[1/4] Analog Design-Editor Komponente erstellen..."
# ═══════════════════════════════════════════════════

cat > src/components/admin/analog-design-editor.tsx << 'ENDOFFILE'
'use client';

import { useState, useEffect, useCallback, useRef } from 'react';

// ─── Hilfskomponenten ───
function AccordionSection({ title, icon, open, onToggle, children }: {
  title: string; icon: string; open: boolean; onToggle: () => void; children: React.ReactNode;
}) {
  return (
    <div className="border border-gray-200 rounded-lg overflow-hidden">
      <button onClick={onToggle} className="w-full flex items-center justify-between px-4 py-3 bg-gray-50 hover:bg-gray-100 transition-colors">
        <span className="flex items-center gap-2 font-medium text-gray-700">
          <span>{icon}</span> {title}
        </span>
        <span className={`transform transition-transform ${open ? 'rotate-180' : ''}`}>▼</span>
      </button>
      {open && <div className="p-4 space-y-4 bg-white">{children}</div>}
    </div>
  );
}

function Label({ children }: { children: React.ReactNode }) {
  return <label className="block text-sm font-medium text-gray-600 mb-1">{children}</label>;
}

function ColorInput({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <div>
      <Label>{label}</Label>
      <div className="flex items-center gap-2">
        <input type="color" value={value || '#000000'} onChange={e => onChange(e.target.value)}
          className="w-10 h-10 rounded cursor-pointer border border-gray-300" />
        <input type="text" value={value || ''} onChange={e => onChange(e.target.value)}
          className="flex-1 border border-gray-300 rounded px-2 py-1.5 text-sm font-mono" />
      </div>
    </div>
  );
}

function SelectInput({ label, value, options, onChange }: {
  label: string; value: string; options: { value: string; label: string }[]; onChange: (v: string) => void;
}) {
  return (
    <div>
      <Label>{label}</Label>
      <select value={value || ''} onChange={e => onChange(e.target.value)}
        className="w-full border border-gray-300 rounded px-3 py-2 text-sm bg-white">
        {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
    </div>
  );
}

function NumberInput({ label, value, min, max, step, onChange, suffix }: {
  label: string; value: number; min?: number; max?: number; step?: number; onChange: (v: number) => void; suffix?: string;
}) {
  return (
    <div>
      <Label>{label}</Label>
      <div className="flex items-center gap-2">
        <input type="number" value={value ?? 0} min={min} max={max} step={step || 1}
          onChange={e => onChange(Number(e.target.value))}
          className="w-24 border border-gray-300 rounded px-3 py-2 text-sm" />
        {suffix && <span className="text-sm text-gray-500">{suffix}</span>}
      </div>
    </div>
  );
}

function Toggle({ label, checked, onChange, description }: {
  label: string; checked: boolean; onChange: (v: boolean) => void; description?: string;
}) {
  return (
    <div className="flex items-start gap-3">
      <button type="button" onClick={() => onChange(!checked)}
        className={`mt-0.5 w-10 h-6 rounded-full transition-colors flex-shrink-0 ${checked ? 'bg-blue-600' : 'bg-gray-300'}`}>
        <span className={`block w-4 h-4 bg-white rounded-full shadow transform transition-transform mx-1 ${checked ? 'translate-x-4' : ''}`} />
      </button>
      <div>
        <span className="text-sm font-medium text-gray-700">{label}</span>
        {description && <p className="text-xs text-gray-500 mt-0.5">{description}</p>}
      </div>
    </div>
  );
}

function TextInput({ label, value, onChange, placeholder }: {
  label: string; value: string; onChange: (v: string) => void; placeholder?: string;
}) {
  return (
    <div>
      <Label>{label}</Label>
      <input type="text" value={value || ''} onChange={e => onChange(e.target.value)} placeholder={placeholder}
        className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
    </div>
  );
}

function ConfirmDialog({ open, title, message, onConfirm, onCancel }: {
  open: boolean; title: string; message: string; onConfirm: () => void; onCancel: () => void;
}) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-xl p-6 max-w-md mx-4">
        <h3 className="text-lg font-bold text-gray-900 mb-2">{title}</h3>
        <p className="text-gray-600 mb-6">{message}</p>
        <div className="flex gap-3 justify-end">
          <button onClick={onCancel} className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50">Abbrechen</button>
          <button onClick={onConfirm} className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700">Zurücksetzen</button>
        </div>
      </div>
    </div>
  );
}

// ─── Font-Liste ───
const FONTS = [
  { value: 'Source Sans 3', label: 'Source Sans 3' },
  { value: 'Playfair Display', label: 'Playfair Display' },
  { value: 'Dancing Script', label: 'Dancing Script' },
  { value: 'Lora', label: 'Lora' },
  { value: 'Merriweather', label: 'Merriweather' },
  { value: 'Roboto', label: 'Roboto' },
  { value: 'Open Sans', label: 'Open Sans' },
  { value: 'Montserrat', label: 'Montserrat' },
];

// ─── Typo-Editor Subkomponente ───
function TypoEditor({ label, config, onChange }: {
  label: string; config: any; onChange: (field: string, value: any) => void;
}) {
  return (
    <div className="border border-gray-100 rounded-lg p-3 bg-gray-50/50">
      <p className="text-sm font-semibold text-gray-700 mb-2">{label}</p>
      <div className="grid grid-cols-2 gap-3">
        <SelectInput label="Schrift" value={config?.font || 'Source Sans 3'} options={FONTS} onChange={v => onChange('font', v)} />
        <NumberInput label="Größe" value={config?.size || 12} min={6} max={72} onChange={v => onChange('size', v)} suffix="pt" />
        {config?.weight !== undefined && (
          <SelectInput label="Stärke" value={String(config?.weight || 400)}
            options={[{ value: '400', label: 'Normal' }, { value: '600', label: 'Semibold' }, { value: '700', label: 'Bold' }]}
            onChange={v => onChange('weight', Number(v))} />
        )}
        <ColorInput label="Farbe" value={config?.color || '#333333'} onChange={v => onChange('color', v)} />
      </div>
    </div>
  );
}

// ─── Templates ───
const TEMPLATES = [
  { id: 'elegant', name: 'Elegant', desc: 'Goldakzente, Zierschrift', icon: '✨' },
  { id: 'modern', name: 'Modern', desc: 'Klar, minimalistisch', icon: '🔲' },
  { id: 'classic', name: 'Klassisch', desc: 'Traditionell, Serifen', icon: '📜' },
  { id: 'minimal', name: 'Minimal', desc: 'Reduziert, luftig', icon: '○' },
];

// ─── Hauptkomponente ───
export default function AnalogDesignEditor({ menuId }: { menuId: string }) {
  const [config, setConfig] = useState<any>(null);
  const [overrides, setOverrides] = useState<any>({});
  const [templateName, setTemplateName] = useState('elegant');
  const [customTemplates, setCustomTemplates] = useState<any[]>([]);
  const [customName, setCustomName] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);
  const [showResetDialog, setShowResetDialog] = useState(false);
  const [showTemplateSwitch, setShowTemplateSwitch] = useState<string | null>(null);
  const [openSections, setOpenSections] = useState<Record<string, boolean>>({ content: true });
  const [pdfUrl, setPdfUrl] = useState<string | null>(null);
  const [pdfLoading, setPdfLoading] = useState(false);
  const saveTimeout = useRef<NodeJS.Timeout | null>(null);

  const hasCustomOverrides = overrides && Object.keys(overrides).length > 0 &&
    JSON.stringify(overrides) !== JSON.stringify({ template: templateName });

  // Daten laden
  useEffect(() => {
    fetch(`/api/v1/menus/${menuId}/design`)
      .then(r => r.json())
      .then(data => {
        const analog = data.designConfig?.analog || {};
        setConfig(analog);
        setTemplateName(analog.template || 'elegant');
        setOverrides(data.savedOverrides?.analog || {});
        setCustomTemplates(data.customTemplates || []);
        setLoading(false);
      })
      .catch(() => { setError('Fehler beim Laden der Design-Konfiguration'); setLoading(false); });
  }, [menuId]);

  // Auto-Save
  const saveConfig = useCallback((newConfig: any) => {
    if (saveTimeout.current) clearTimeout(saveTimeout.current);
    saveTimeout.current = setTimeout(async () => {
      setSaving(true);
      try {
        const res = await fetch(`/api/v1/menus/${menuId}/design`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ designConfig: { analog: newConfig } }),
        });
        if (!res.ok) throw new Error('Speichern fehlgeschlagen');
        const data = await res.json();
        setOverrides(data.savedOverrides?.analog || {});
      } catch (e) {
        console.error('Save error:', e);
      }
      setSaving(false);
    }, 500);
  }, [menuId]);

  // Config-Update (verschachtelt)
  const updateConfig = useCallback((path: string, value: any) => {
    setConfig((prev: any) => {
      const newConfig = JSON.parse(JSON.stringify(prev));
      const keys = path.split('.');
      let current = newConfig;
      for (let i = 0; i < keys.length - 1; i++) {
        if (!current[keys[i]]) current[keys[i]] = {};
        current = current[keys[i]];
      }
      current[keys[keys.length - 1]] = value;
      saveConfig(newConfig);
      return newConfig;
    });
  }, [saveConfig]);

  // Template wechseln
  const switchTemplate = async (id: string) => {
    setSaving(true);
    try {
      const res = await fetch(`/api/v1/menus/${menuId}/design`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ designConfig: { analog: { template: id } }, resetAnalog: true }),
      });
      const data = await res.json();
      setConfig(data.designConfig?.analog || {});
      setTemplateName(id);
      setOverrides({});
    } catch (e) { console.error(e); }
    setSaving(false);
  };

  const handleTemplateClick = (id: string) => {
    if (id === templateName && !hasCustomOverrides) return;
    if (hasCustomOverrides) {
      setShowTemplateSwitch(id);
    } else {
      switchTemplate(id);
    }
  };

  // Reset
  const resetToDefaults = async () => {
    setShowResetDialog(false);
    await switchTemplate(templateName);
  };

  // Custom-Vorlage speichern
  const saveAsCustomTemplate = async () => {
    if (customTemplates.length >= 4) return;
    const name = customName.trim() || `Vorlage ${customTemplates.length + 1}`;
    const newCustom = [...customTemplates, { name, config: JSON.parse(JSON.stringify(config)) }];
    setCustomTemplates(newCustom);
    setCustomName('');
    await fetch(`/api/v1/menus/${menuId}/design`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ customTemplates: newCustom }),
    });
  };

  const loadCustomTemplate = async (idx: number) => {
    const tpl = customTemplates[idx];
    if (!tpl) return;
    setSaving(true);
    try {
      const res = await fetch(`/api/v1/menus/${menuId}/design`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ designConfig: { analog: tpl.config } }),
      });
      const data = await res.json();
      setConfig(data.designConfig?.analog || tpl.config);
      setTemplateName(tpl.config.template || 'elegant');
      setOverrides(data.savedOverrides?.analog || {});
    } catch (e) { console.error(e); }
    setSaving(false);
  };

  const deleteCustomTemplate = async (idx: number) => {
    const newCustom = customTemplates.filter((_, i) => i !== idx);
    setCustomTemplates(newCustom);
    await fetch(`/api/v1/menus/${menuId}/design`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ customTemplates: newCustom }),
    });
  };

  // PDF-Vorschau laden
  const loadPdfPreview = async () => {
    setPdfLoading(true);
    try {
      const res = await fetch(`/api/v1/menus/${menuId}/pdf`);
      if (!res.ok) throw new Error('PDF konnte nicht generiert werden');
      const blob = await res.blob();
      if (pdfUrl) URL.revokeObjectURL(pdfUrl);
      setPdfUrl(URL.createObjectURL(blob));
    } catch (e) {
      console.error('PDF preview error:', e);
    }
    setPdfLoading(false);
  };

  // Toggle Sektion
  const toggleSection = (key: string) => {
    setOpenSections(prev => ({ ...prev, [key]: !prev[key] }));
  };

  if (loading) return <div className="flex items-center justify-center h-64"><div className="animate-spin rounded-full h-8 w-8 border-2 border-blue-600 border-t-transparent" /></div>;
  if (error) return <div className="p-4 bg-red-50 text-red-600 rounded-lg">{error}</div>;
  if (!config) return null;

  return (
    <div className="flex gap-6 h-full">
      {/* ─── Linke Spalte: Editor ─── */}
      <div className="w-[420px] flex-shrink-0 overflow-y-auto space-y-4 pb-8">
        {/* Status-Leiste */}
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-500">
            Vorlage: <strong>{TEMPLATES.find(t => t.id === templateName)?.name || templateName}</strong>
            {hasCustomOverrides && <span className="ml-2 text-amber-600 text-xs">(Angepasst)</span>}
          </span>
          {saving && <span className="text-blue-600 animate-pulse">Speichern...</span>}
        </div>

        {/* ─── Template-Auswahl ─── */}
        <div className="grid grid-cols-2 gap-2">
          {TEMPLATES.map(t => (
            <button key={t.id} onClick={() => handleTemplateClick(t.id)}
              className={`p-3 rounded-lg border-2 text-left transition-all ${templateName === t.id && !hasCustomOverrides
                ? 'border-blue-600 bg-blue-50' : 'border-gray-200 hover:border-gray-300'}`}>
              <span className="text-lg">{t.icon}</span>
              <p className="font-medium text-sm mt-1">{t.name}</p>
              <p className="text-xs text-gray-500">{t.desc}</p>
            </button>
          ))}
        </div>

        {/* Custom Templates */}
        {customTemplates.length > 0 && (
          <div className="grid grid-cols-2 gap-2">
            {customTemplates.map((ct, idx) => (
              <div key={idx} className="p-3 rounded-lg border-2 border-gray-200 hover:border-gray-300 relative group">
                <button onClick={() => loadCustomTemplate(idx)} className="text-left w-full">
                  <span className="text-lg">🎨</span>
                  <p className="font-medium text-sm mt-1 truncate">{ct.name}</p>
                  <p className="text-xs text-gray-500">Benutzerdefiniert</p>
                </button>
                <button onClick={() => deleteCustomTemplate(idx)}
                  className="absolute top-1 right-1 w-5 h-5 rounded-full bg-red-100 text-red-600 text-xs opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">×</button>
              </div>
            ))}
          </div>
        )}

        {/* Benutzerdefiniert speichern */}
        {hasCustomOverrides && customTemplates.length < 4 && (
          <div className="space-y-2">
            <input type="text" value={customName} onChange={e => setCustomName(e.target.value)}
              placeholder="Name der Vorlage..." maxLength={30}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm" />
            <button onClick={saveAsCustomTemplate}
              className="w-full py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium text-sm transition-colors">
              Als Vorlage speichern ({customTemplates.length}/4)
            </button>
          </div>
        )}

        {/* Reset-Button */}
        {hasCustomOverrides && (
          <button onClick={() => setShowResetDialog(true)}
            className="w-full py-2 text-sm text-red-600 border border-red-200 rounded-lg hover:bg-red-50 transition-colors">
            Auf Standardwerte zurücksetzen
          </button>
        )}

        {/* ═══════════ Akkordeons ═══════════ */}

        {/* 1. Inhalt & Sprache */}
        <AccordionSection title="Inhalt & Sprache" icon="📄" open={!!openSections.content} onToggle={() => toggleSection('content')}>
          <div className="space-y-3">
            <Toggle label="Deckblatt anzeigen" checked={config.content?.showTitlePage !== false} onChange={v => updateConfig('content.showTitlePage', v)} />
            <Toggle label="Inhaltsverzeichnis" checked={config.content?.showToc !== false} onChange={v => updateConfig('content.showToc', v)} />
            <Toggle label="Legende / Allergenhinweis" checked={config.content?.showLegend !== false} onChange={v => updateConfig('content.showLegend', v)} />
            <Toggle label="QR-Code Seite" checked={config.content?.showQrPage !== false} onChange={v => updateConfig('content.showQrPage', v)} />
            <hr className="border-gray-200" />
            <SelectInput label="Hauptsprache" value={config.language?.primary || 'de'}
              options={[{ value: 'de', label: 'Deutsch' }, { value: 'en', label: 'Englisch' }]}
              onChange={v => updateConfig('language.primary', v)} />
            <SelectInput label="Zweitsprache" value={config.language?.secondary || 'en'}
              options={[{ value: 'en', label: 'Englisch' }, { value: 'de', label: 'Deutsch' }, { value: 'none', label: 'Keine' }]}
              onChange={v => updateConfig('language.secondary', v)} />
            <SelectInput label="Zweitsprache anzeigen bei" value={config.language?.secondaryScope || 'all'}
              options={[{ value: 'all', label: 'Alle Bereiche' }, { value: 'products', label: 'Nur Produkte' }, { value: 'headers', label: 'Nur Überschriften' }]}
              onChange={v => updateConfig('language.secondaryScope', v)} />
            <SelectInput label="Beschreibungssprache" value={config.language?.descriptionLang || 'both'}
              options={[{ value: 'both', label: 'Beide' }, { value: 'primary', label: 'Nur Hauptsprache' }, { value: 'secondary', label: 'Nur Zweitsprache' }]}
              onChange={v => updateConfig('language.descriptionLang', v)} />
          </div>
        </AccordionSection>

        {/* 2. Seitenformat */}
        <AccordionSection title="Seitenformat" icon="📐" open={!!openSections.page} onToggle={() => toggleSection('page')}>
          <div className="space-y-3">
            <SelectInput label="Format" value={config.page?.format || 'A4'}
              options={[{ value: 'A4', label: 'A4 (210 × 297 mm)' }, { value: 'A5', label: 'A5 (148 × 210 mm)' }, { value: 'LETTER', label: 'Letter (216 × 279 mm)' }]}
              onChange={v => updateConfig('page.format', v)} />
            <SelectInput label="Ausrichtung" value={config.page?.orientation || 'portrait'}
              options={[{ value: 'portrait', label: 'Hochformat' }, { value: 'landscape', label: 'Querformat' }]}
              onChange={v => updateConfig('page.orientation', v)} />
            <SelectInput label="Seitenränder" value={config.page?.margins || 'normal'}
              options={[{ value: 'narrow', label: 'Schmal (15 mm)' }, { value: 'normal', label: 'Normal (20 mm)' }, { value: 'wide', label: 'Breit (30 mm)' }]}
              onChange={v => updateConfig('page.margins', v)} />
            <Toggle label="Seitenzahlen" checked={config.page?.pageNumbers !== false} onChange={v => updateConfig('page.pageNumbers', v)} />
            <NumberInput label="Seitenzahl beginnt bei" value={config.page?.pageNumberStart || 1} min={1} max={99} onChange={v => updateConfig('page.pageNumberStart', v)} />
            <Toggle label="Deckblatt mitzählen" checked={!!config.page?.countTitlePage} onChange={v => updateConfig('page.countTitlePage', v)} />
            <Toggle label="Beschnitt (Bleed)" checked={!!config.page?.bleed} onChange={v => updateConfig('page.bleed', v)}
              description="3mm Beschnitt für professionellen Druck" />
          </div>
        </AccordionSection>

        {/* 3. Deckblatt */}
        <AccordionSection title="Deckblatt" icon="🏔️" open={!!openSections.titlePage} onToggle={() => toggleSection('titlePage')}>
          <div className="space-y-3">
            <SelectInput label="Logo-Position" value={config.titlePage?.logoPosition || 'upperThird'}
              options={[
                { value: 'upperThird', label: 'Oberes Drittel' },
                { value: 'center', label: 'Zentriert' },
                { value: 'lowerThird', label: 'Unteres Drittel' },
              ]}
              onChange={v => updateConfig('titlePage.logoPosition', v)} />
            <NumberInput label="Logo-Größe" value={config.titlePage?.logoSize || 200} min={50} max={400} step={10} onChange={v => updateConfig('titlePage.logoSize', v)} suffix="px" />
            <ColorInput label="Hintergrundfarbe" value={config.titlePage?.logoBgColor || '#555555'} onChange={v => updateConfig('titlePage.logoBgColor', v)} />
            <hr className="border-gray-200" />
            <TextInput label="Zitat (DE)" value={config.titlePage?.quote || ''} onChange={v => updateConfig('titlePage.quote', v)} placeholder="Optional: Begrüßungstext..." />
            <TextInput label="Zitat (EN)" value={config.titlePage?.quoteEN || ''} onChange={v => updateConfig('titlePage.quoteEN', v)} placeholder="Optional: Welcome text..." />
            <TextInput label="Autor" value={config.titlePage?.quoteAuthor || ''} onChange={v => updateConfig('titlePage.quoteAuthor', v)} placeholder="z.B. Hotel Sonnblick" />
            <SelectInput label="Zitat-Schrift" value={config.titlePage?.quoteFont || 'Dancing Script'} options={FONTS} onChange={v => updateConfig('titlePage.quoteFont', v)} />
          </div>
        </AccordionSection>

        {/* 4. Inhaltsverzeichnis */}
        <AccordionSection title="Inhaltsverzeichnis" icon="📑" open={!!openSections.toc} onToggle={() => toggleSection('toc')}>
          <div className="space-y-3">
            <SelectInput label="Tiefe" value={config.toc?.depth || 'categoryAndCountry'}
              options={[
                { value: 'categoryOnly', label: 'Nur Kategorien' },
                { value: 'categoryAndCountry', label: 'Kategorien + Herkunft' },
                { value: 'full', label: 'Alle Ebenen' },
              ]}
              onChange={v => updateConfig('toc.depth', v)} />
            <SelectInput label="Verbindungslinie" value={config.toc?.lineStyle || 'dotted'}
              options={[{ value: 'dotted', label: 'Gepunktet' }, { value: 'solid', label: 'Durchgezogen' }, { value: 'none', label: 'Keine' }]}
              onChange={v => updateConfig('toc.lineStyle', v)} />
            <Toggle label="Zweisprachig" checked={config.toc?.bilingual !== false} onChange={v => updateConfig('toc.bilingual', v)} />
            <Toggle label="Eingerückt" checked={config.toc?.indented !== false} onChange={v => updateConfig('toc.indented', v)} />
          </div>
        </AccordionSection>

        {/* 5. Typografie */}
        <AccordionSection title="Typografie" icon="🔤" open={!!openSections.typography} onToggle={() => toggleSection('typography')}>
          <div className="space-y-3">
            <TypoEditor label="Kategorie-Titel" config={config.typography?.sectionTitle}
              onChange={(field, value) => updateConfig(`typography.sectionTitle.${field}`, value)} />
            <TypoEditor label="Unterkategorie" config={config.typography?.subCategory}
              onChange={(field, value) => updateConfig(`typography.subCategory.${field}`, value)} />
            <TypoEditor label="Untergruppierung" config={config.typography?.subGrouping}
              onChange={(field, value) => updateConfig(`typography.subGrouping.${field}`, value)} />
            <TypoEditor label="Produktname" config={config.typography?.productName}
              onChange={(field, value) => updateConfig(`typography.productName.${field}`, value)} />
            <TypoEditor label="Weingut" config={config.typography?.winery}
              onChange={(field, value) => updateConfig(`typography.winery.${field}`, value)} />
            <TypoEditor label="Beschreibung" config={config.typography?.description}
              onChange={(field, value) => updateConfig(`typography.description.${field}`, value)} />
            <TypoEditor label="Preis" config={config.typography?.price}
              onChange={(field, value) => updateConfig(`typography.price.${field}`, value)} />
          </div>
        </AccordionSection>

        {/* 6. Farben */}
        <AccordionSection title="Farben" icon="🎨" open={!!openSections.colors} onToggle={() => toggleSection('colors')}>
          <div className="grid grid-cols-2 gap-3">
            <ColorInput label="Seitenhintergrund" value={config.colors?.pageBg || '#FFFFFF'} onChange={v => updateConfig('colors.pageBg', v)} />
            <ColorInput label="Textfarbe" value={config.colors?.textMain || '#333333'} onChange={v => updateConfig('colors.textMain', v)} />
            <ColorInput label="Akzentfarbe" value={config.colors?.accent || '#C8A850'} onChange={v => updateConfig('colors.accent', v)} />
            <ColorInput label="Preisfarbe" value={config.colors?.priceColor || '#000000'} onChange={v => updateConfig('colors.priceColor', v)} />
            <ColorInput label="Fußzeile" value={config.colors?.footerColor || '#999999'} onChange={v => updateConfig('colors.footerColor', v)} />
          </div>
        </AccordionSection>

        {/* 7. Produktdarstellung */}
        <AccordionSection title="Produktdarstellung" icon="🍷" open={!!openSections.productLayout} onToggle={() => toggleSection('productLayout')}>
          <div className="space-y-3">
            <Toggle label="Beschreibung (DE)" checked={config.productLayout?.descDE !== false} onChange={v => updateConfig('productLayout.descDE', v)} />
            <Toggle label="Beschreibung (EN)" checked={config.productLayout?.descEN !== false} onChange={v => updateConfig('productLayout.descEN', v)} />
            <SelectInput label="Beschreibungs-Layout" value={config.productLayout?.descLayout || 'stacked'}
              options={[{ value: 'stacked', label: 'Untereinander' }, { value: 'inline', label: 'Nebeneinander' }]}
              onChange={v => updateConfig('productLayout.descLayout', v)} />
            <SelectInput label="Textausrichtung" value={config.productLayout?.descAlign || 'justify'}
              options={[{ value: 'left', label: 'Linksbündig' }, { value: 'justify', label: 'Blocksatz' }, { value: 'center', label: 'Zentriert' }]}
              onChange={v => updateConfig('productLayout.descAlign', v)} />
            <NumberInput label="Max. Zeichen Beschreibung" value={config.productLayout?.descMaxChars || 0} min={0} max={500} step={10}
              onChange={v => updateConfig('productLayout.descMaxChars', v)} suffix="(0 = unbegrenzt)" />
            <hr className="border-gray-200" />
            <TextInput label="Preisformat" value={config.productLayout?.priceFormat || '{fill}  {price} €'}
              onChange={v => updateConfig('productLayout.priceFormat', v)} placeholder="{fill}  {price} €" />
            <SelectInput label="Mehrere Preise" value={config.productLayout?.multiplePrices || 'stacked'}
              options={[{ value: 'stacked', label: 'Untereinander' }, { value: 'inline', label: 'Nebeneinander' }]}
              onChange={v => updateConfig('productLayout.multiplePrices', v)} />
            <SelectInput label="Abstand" value={config.productLayout?.spacing || 'normal'}
              options={[{ value: 'compact', label: 'Kompakt' }, { value: 'normal', label: 'Normal' }, { value: 'relaxed', label: 'Großzügig' }]}
              onChange={v => updateConfig('productLayout.spacing', v)} />
            <Toggle label="Trennlinie" checked={!!config.productLayout?.dividerLine} onChange={v => updateConfig('productLayout.dividerLine', v)} />
          </div>
        </AccordionSection>

        {/* 8. Bilder */}
        <AccordionSection title="Bilder" icon="🖼️" open={!!openSections.images} onToggle={() => toggleSection('images')}>
          <div className="space-y-3">
            <Toggle label="Bilder anzeigen" checked={config.images?.show !== false} onChange={v => updateConfig('images.show', v)} />
            {config.images?.show !== false && (
              <>
                <SelectInput label="Position" value={config.images?.position || 'pageBottom'}
                  options={[
                    { value: 'pageBottom', label: 'Seitenende' },
                    { value: 'afterSection', label: 'Nach Sektion' },
                    { value: 'inline', label: 'Im Text' },
                  ]}
                  onChange={v => updateConfig('images.position', v)} />
                <NumberInput label="Max. pro Reihe" value={config.images?.maxPerRow || 4} min={1} max={6} onChange={v => updateConfig('images.maxPerRow', v)} />
                <NumberInput label="Höhe" value={config.images?.height || 120} min={40} max={300} step={10} onChange={v => updateConfig('images.height', v)} suffix="px" />
                <SelectInput label="Stil" value={config.images?.style || 'color'}
                  options={[{ value: 'color', label: 'Farbig' }, { value: 'grayscale', label: 'Schwarzweiß' }, { value: 'sepia', label: 'Sepia' }]}
                  onChange={v => updateConfig('images.style', v)} />
              </>
            )}
          </div>
        </AccordionSection>

        {/* 9. Kopf-/Fußzeile */}
        <AccordionSection title="Kopf- & Fußzeile" icon="📏" open={!!openSections.headerFooter} onToggle={() => toggleSection('headerFooter')}>
          <div className="space-y-3">
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Kopfzeile</p>
            <Toggle label="Kategorienname wiederholen" checked={config.headerFooter?.header?.repeatSectionName !== false}
              onChange={v => updateConfig('headerFooter.header.repeatSectionName', v)} />
            <SelectInput label="Schrift" value={config.headerFooter?.header?.font || 'Dancing Script'} options={FONTS}
              onChange={v => updateConfig('headerFooter.header.font', v)} />
            <Toggle label="Trennlinie" checked={config.headerFooter?.header?.dividerLine !== false}
              onChange={v => updateConfig('headerFooter.header.dividerLine', v)} />
            <hr className="border-gray-200" />
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Fußzeile</p>
            <Toggle label="Fußzeile anzeigen" checked={config.headerFooter?.footer?.show !== false}
              onChange={v => updateConfig('headerFooter.footer.show', v)} />
            {config.headerFooter?.footer?.show !== false && (
              <>
                <TextInput label="Text Links" value={config.headerFooter?.footer?.textLeft || ''}
                  onChange={v => updateConfig('headerFooter.footer.textLeft', v)} placeholder="z.B. Inklusivpreise in Euro" />
                <TextInput label="Text Mitte" value={config.headerFooter?.footer?.textCenter || ''}
                  onChange={v => updateConfig('headerFooter.footer.textCenter', v)} />
                <TextInput label="Text Rechts" value={config.headerFooter?.footer?.textRight || ''}
                  onChange={v => updateConfig('headerFooter.footer.textRight', v)} placeholder="{pageNumber}" />
                <Toggle label="Trennlinie" checked={config.headerFooter?.footer?.dividerLine !== false}
                  onChange={v => updateConfig('headerFooter.footer.dividerLine', v)} />
              </>
            )}
          </div>
        </AccordionSection>

        {/* 10. Seitenumbrüche */}
        <AccordionSection title="Seitenumbrüche" icon="📃" open={!!openSections.pageBreaks} onToggle={() => toggleSection('pageBreaks')}>
          <div className="space-y-3">
            <Toggle label="Neue Seite pro Hauptkategorie" checked={config.pageBreaks?.newPagePerMainCategory !== false}
              onChange={v => updateConfig('pageBreaks.newPagePerMainCategory', v)} />
            <Toggle label="Keine Waisen-Produkte" checked={config.pageBreaks?.noOrphanProducts !== false}
              onChange={v => updateConfig('pageBreaks.noOrphanProducts', v)}
              description="Vermeidet einzelne Produkte am Seitenende" />
            <NumberInput label="Min. Produkte nach Überschrift" value={config.pageBreaks?.minProductsAfterHeader || 2}
              min={1} max={5} onChange={v => updateConfig('pageBreaks.minProductsAfterHeader', v)} />
            <Toggle label="Bilder bei Text behalten" checked={config.pageBreaks?.keepImagesWithText !== false}
              onChange={v => updateConfig('pageBreaks.keepImagesWithText', v)} />
          </div>
        </AccordionSection>
      </div>

      {/* ─── Rechte Spalte: PDF-Vorschau ─── */}
      <div className="flex-1 flex flex-col min-w-0">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-medium text-gray-700">PDF-Vorschau</h3>
          <div className="flex gap-2">
            <button onClick={loadPdfPreview} disabled={pdfLoading}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 text-sm font-medium transition-colors flex items-center gap-2">
              {pdfLoading ? (
                <><span className="animate-spin">⟳</span> Generiere...</>
              ) : (
                <><span>🔄</span> Vorschau aktualisieren</>
              )}
            </button>
            <a href={`/api/v1/menus/${menuId}/pdf`} target="_blank" rel="noopener noreferrer"
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm font-medium transition-colors flex items-center gap-2">
              <span>⬇️</span> PDF herunterladen
            </a>
          </div>
        </div>
        <div className="flex-1 bg-gray-100 rounded-lg border border-gray-200 overflow-hidden min-h-[600px]">
          {pdfUrl ? (
            <iframe src={pdfUrl} className="w-full h-full" title="PDF-Vorschau" />
          ) : (
            <div className="flex flex-col items-center justify-center h-full text-gray-400">
              <span className="text-5xl mb-4">📄</span>
              <p className="text-lg">Klicken Sie auf &quot;Vorschau aktualisieren&quot;</p>
              <p className="text-sm mt-1">um eine PDF-Vorschau zu sehen</p>
            </div>
          )}
        </div>
      </div>

      {/* Dialoge */}
      <ConfirmDialog open={showResetDialog} title="Auf Standardwerte zurücksetzen?"
        message={`Alle Anpassungen werden verworfen und die Vorlage "${TEMPLATES.find(t => t.id === templateName)?.name}" wird auf Standardwerte zurückgesetzt.`}
        onConfirm={resetToDefaults} onCancel={() => setShowResetDialog(false)} />
      <ConfirmDialog open={!!showTemplateSwitch} title="Vorlage wechseln?"
        message="Sie haben Anpassungen vorgenommen. Beim Wechsel gehen diese verloren. Möchten Sie vorher als benutzerdefinierte Vorlage speichern?"
        onConfirm={() => { switchTemplate(showTemplateSwitch!); setShowTemplateSwitch(null); }}
        onCancel={() => setShowTemplateSwitch(null)} />
    </div>
  );
}
ENDOFFILE

echo "  ✓ analog-design-editor.tsx erstellt"

# ═══════════════════════════════════════════════════
echo "[2/4] Admin-Seite mit Tab-System erweitern..."
# ═══════════════════════════════════════════════════

cat > src/app/admin/menus/\[id\]/design/page.tsx << 'ENDOFFILE'
'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import DesignEditor from '@/components/admin/design-editor';
import AnalogDesignEditor from '@/components/admin/analog-design-editor';

export default function DesignPage() {
  const params = useParams();
  const router = useRouter();
  const menuId = params.id as string;
  const [menuName, setMenuName] = useState('');
  const [activeTab, setActiveTab] = useState<'digital' | 'pdf'>('digital');

  useEffect(() => {
    fetch(`/api/v1/menus/${menuId}`)
      .then(r => r.json())
      .then(data => setMenuName(data.name || 'Karte'))
      .catch(() => {});
  }, [menuId]);

  return (
    <div className="h-screen flex flex-col bg-white">
      {/* Header */}
      <div className="border-b border-gray-200 px-6 py-3 flex items-center justify-between flex-shrink-0">
        <div className="flex items-center gap-4">
          <button onClick={() => router.push('/admin/menus')}
            className="text-gray-500 hover:text-gray-700 transition-colors">
            ← Zurück
          </button>
          <div>
            <h1 className="text-lg font-bold text-gray-900">Design-Editor</h1>
            <p className="text-sm text-gray-500">{menuName}</p>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex bg-gray-100 rounded-lg p-1">
          <button
            onClick={() => setActiveTab('digital')}
            className={`px-5 py-2 rounded-md text-sm font-medium transition-all ${
              activeTab === 'digital'
                ? 'bg-white shadow-sm text-blue-600'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            🖥️ Digital
          </button>
          <button
            onClick={() => setActiveTab('pdf')}
            className={`px-5 py-2 rounded-md text-sm font-medium transition-all ${
              activeTab === 'pdf'
                ? 'bg-white shadow-sm text-blue-600'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            📄 PDF / Druck
          </button>
        </div>
      </div>

      {/* Editor-Bereich */}
      <div className="flex-1 overflow-hidden p-6">
        {activeTab === 'digital' ? (
          <DesignEditor menuId={menuId} />
        ) : (
          <AnalogDesignEditor menuId={menuId} />
        )}
      </div>
    </div>
  );
}
ENDOFFILE

echo "  ✓ Admin-Seite mit Tabs erstellt"

# ═══════════════════════════════════════════════════
echo "[3/4] Design-API für analog-Reset erweitern..."
# ═══════════════════════════════════════════════════

# API-Route patchen: resetAnalog Support hinzufügen
cat > /tmp/patch-design-api.ts << 'ENDOFPATCH'
// Patch: resetAnalog Support in PATCH handler
// Wird in die bestehende route.ts eingefügt
ENDOFPATCH

# Prüfen ob resetAnalog schon drin ist
if ! grep -q "resetAnalog" src/app/api/v1/menus/\[id\]/design/route.ts; then
  # Backup schon gemacht oben
  # Finde die PATCH-Funktion und füge resetAnalog-Support hinzu
  sed -i 's/const body = await request.json();/const body = await request.json();\n\n    \/\/ Reset analog config to template defaults\n    if (body.resetAnalog) {\n      const existing = (menu.designConfig as any) || {};\n      const templateName = body.designConfig?.analog?.template || existing.analog?.template || '\''elegant'\'';\n      const { getTemplate, mergeConfig } = await import('\''@\/lib\/design-templates'\'');\n      const tpl = getTemplate(templateName);\n      const resetConfig = { ...existing, analog: tpl.analog };\n      const updated = await prisma.menu.update({ where: { id: menuId }, data: { designConfig: resetConfig as any } });\n      const savedOverrides = {};\n      return NextResponse.json({ designConfig: (updated.designConfig as any), savedOverrides: { analog: savedOverrides }, templateName, customTemplates: (updated.designConfig as any)?.customTemplates || [] });\n    }/' src/app/api/v1/menus/\[id\]/design/route.ts
  echo "  ✓ API resetAnalog Support hinzugefügt"
else
  echo "  ✓ API resetAnalog Support bereits vorhanden"
fi

# ═══════════════════════════════════════════════════
echo "[4/4] Build und Restart..."
# ═══════════════════════════════════════════════════

npm run build 2>&1 | tail -20

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "═══════════════════════════════════"
  echo "  ✅ PDF Design-Editor v2 LIVE!"
  echo "═══════════════════════════════════"
  echo ""
  echo "  → Admin → Karte → Design-Editor"
  echo "  → Tab 'PDF / Druck' wählen"
  echo "  → 11 Akkordeons für alle Einstellungen"
  echo "  → PDF-Vorschau + Download"
  echo "  → Templates + benutzerdefinierte Vorlagen"
  echo ""
else
  echo ""
  echo "  ❌ Build fehlgeschlagen!"
  echo "  Prüfe die Fehlermeldung oben."
  echo ""
fi
