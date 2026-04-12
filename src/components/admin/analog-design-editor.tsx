'use client';

import { useState, useEffect, useCallback, useRef } from 'react';

/* ─── Hilfskomponenten ─── */
function AccordionSection({ title, icon, open, onToggle, children }: {
  title: string; icon: string; open: boolean; onToggle: () => void; children: React.ReactNode;
}) {
  return (
    <div className="border border-gray-200 rounded-lg overflow-hidden">
      <button onClick={onToggle} className="w-full flex items-center justify-between px-4 py-3 bg-gray-50 hover:bg-gray-100 transition-colors">
        <span className="flex items-center gap-2 font-medium text-gray-700"><span>{icon}</span> {title}</span>
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
  return (<div><Label>{label}</Label><div className="flex items-center gap-2">
    <input type="color" value={value || '#000000'} onChange={e => onChange(e.target.value)} className="w-10 h-10 rounded cursor-pointer border border-gray-300" />
    <input type="text" value={value || ''} onChange={e => onChange(e.target.value)} className="flex-1 border border-gray-300 rounded px-2 py-1.5 text-sm font-mono" />
  </div></div>);
}
function SelectInput({ label, value, options, onChange }: {
  label: string; value: string; options: { value: string; label: string }[]; onChange: (v: string) => void;
}) {
  return (<div><Label>{label}</Label>
    <select value={value || ''} onChange={e => onChange(e.target.value)} className="w-full border border-gray-300 rounded px-3 py-2 text-sm bg-white">
      {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
    </select></div>);
}
function NumberInput({ label, value, min, max, step, onChange, suffix }: {
  label: string; value: number; min?: number; max?: number; step?: number; onChange: (v: number) => void; suffix?: string;
}) {
  return (<div><Label>{label}</Label><div className="flex items-center gap-2">
    <input type="number" value={value ?? 0} min={min} max={max} step={step || 1} onChange={e => onChange(Number(e.target.value))} className="w-24 border border-gray-300 rounded px-3 py-2 text-sm" />
    {suffix && <span className="text-sm text-gray-500">{suffix}</span>}
  </div></div>);
}
function Toggle({ label, checked, onChange, description }: {
  label: string; checked: boolean; onChange: (v: boolean) => void; description?: string;
}) {
  return (<div className="flex items-start gap-3">
    <button type="button" onClick={() => onChange(!checked)} className={`mt-0.5 w-10 h-6 rounded-full transition-colors flex-shrink-0 ${checked ? 'bg-blue-600' : 'bg-gray-300'}`}>
      <span className={`block w-4 h-4 bg-white rounded-full shadow transform transition-transform mx-1 ${checked ? 'translate-x-4' : ''}`} />
    </button>
    <div><span className="text-sm font-medium text-gray-700">{label}</span>
      {description && <p className="text-xs text-gray-500 mt-0.5">{description}</p>}</div>
  </div>);
}
function TextInput({ label, value, onChange, placeholder }: {
  label: string; value: string; onChange: (v: string) => void; placeholder?: string;
}) {
  return (<div><Label>{label}</Label>
    <input type="text" value={value || ''} onChange={e => onChange(e.target.value)} placeholder={placeholder} className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
  </div>);
}
function ConfirmDialog({ open, title, message, onConfirm, onCancel }: {
  open: boolean; title: string; message: string; onConfirm: () => void; onCancel: () => void;
}) {
  if (!open) return null;
  return (<div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
    <div className="bg-white rounded-xl shadow-xl p-6 max-w-md mx-4">
      <h3 className="text-lg font-bold text-gray-900 mb-2">{title}</h3>
      <p className="text-gray-600 mb-6">{message}</p>
      <div className="flex gap-3 justify-end">
        <button onClick={onCancel} className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50">Abbrechen</button>
        <button onClick={onConfirm} className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700">Bestätigen</button>
      </div>
    </div>
  </div>);
}

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

function TypoEditor({ label, config, onChange }: { label: string; config: any; onChange: (f: string, v: any) => void }) {
  return (<div className="border border-gray-100 rounded-lg p-3 bg-gray-50/50">
    <p className="text-sm font-semibold text-gray-700 mb-2">{label}</p>
    <div className="grid grid-cols-2 gap-3">
      <SelectInput label="Schrift" value={config?.font || 'Source Sans 3'} options={FONTS} onChange={v => onChange('font', v)} />
      <NumberInput label="Größe" value={config?.size || 12} min={6} max={72} onChange={v => onChange('size', v)} suffix="pt" />
      {config?.weight !== undefined && <SelectInput label="Stärke" value={String(config?.weight || 400)}
        options={[{ value: '400', label: 'Normal' }, { value: '600', label: 'Semibold' }, { value: '700', label: 'Bold' }]}
        onChange={v => onChange('weight', Number(v))} />}
      <ColorInput label="Farbe" value={config?.color || '#333333'} onChange={v => onChange('color', v)} />
    </div>
  </div>);
}

const TEMPLATES = [
  { id: 'elegant', name: 'Elegant', desc: 'Goldakzente, Zierschrift', icon: '✨' },
  { id: 'modern', name: 'Modern', desc: 'Klar, minimalistisch', icon: '🔲' },
  { id: 'classic', name: 'Klassisch', desc: 'Traditionell, Serifen', icon: '📜' },
  { id: 'minimal', name: 'Minimal', desc: 'Reduziert, luftig', icon: '○' },
];

/* ─── Hauptkomponente ─── */
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
  const [previewKey, setPreviewKey] = useState(0);
  const saveTimeout = useRef<NodeJS.Timeout | null>(null);

  const hasCustomOverrides = overrides && Object.keys(overrides).length > 0 &&
    JSON.stringify(overrides) !== JSON.stringify({ template: templateName });

  useEffect(() => {
    fetch(`/api/v1/menus/${menuId}/design`)
      .then(r => r.json())
      .then(data => {
        const analog = data.designConfig?.analog || {};
        setConfig(analog);
        setTemplateName(analog.template || 'elegant');
        setOverrides(data.designConfig?.analog || data.savedOverrides?.analog || {});
        setCustomTemplates(data.customTemplates || []);
        setLoading(false);
      })
      .catch(() => { setError('Fehler beim Laden'); setLoading(false); });
  }, [menuId]);

  const saveConfig = useCallback((newConfig: any) => {
    if (saveTimeout.current) clearTimeout(saveTimeout.current);
    saveTimeout.current = setTimeout(async () => {
      setSaving(true);
      try {
        const res = await fetch(`/api/v1/menus/${menuId}/design`, {
          method: 'PATCH', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ designConfig: { analog: newConfig } }),
        });
        if (!res.ok) throw new Error('Fehler');
        const data = await res.json();
        setOverrides(data.designConfig?.analog || data.savedOverrides?.analog || {});
      } catch (e) { console.error(e); }
      setSaving(false);
    }, 500);
  }, [menuId]);

  const updateConfig = useCallback((path: string, value: any) => {
    setConfig((prev: any) => {
      const nc = JSON.parse(JSON.stringify(prev));
      const keys = path.split('.');
      let cur = nc;
      for (let i = 0; i < keys.length - 1; i++) { if (!cur[keys[i]]) cur[keys[i]] = {}; cur = cur[keys[i]]; }
      cur[keys[keys.length - 1]] = value;
      saveConfig(nc);
      return nc;
    });
  }, [saveConfig]);

  const switchTemplate = async (id: string) => {
    setSaving(true);
    try {
      const res = await fetch(`/api/v1/menus/${menuId}/design`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json' },
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
    if (hasCustomOverrides) { setShowTemplateSwitch(id); } else { switchTemplate(id); }
  };

  const resetToDefaults = async () => { setShowResetDialog(false); await switchTemplate(templateName); };

  const saveAsCustomTemplate = async () => {
    if (customTemplates.length >= 4) return;
    const name = customName.trim() || `Vorlage ${customTemplates.length + 1}`;
    const nc = [...customTemplates, { name, overrides: JSON.parse(JSON.stringify(config)), baseTemplate: templateName }];
    setCustomTemplates(nc); setCustomName('');
    await fetch(`/api/v1/menus/${menuId}/design`, {
      method: 'PATCH', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ customTemplates: nc }),
    });
  };

  const loadCustomTemplate = async (idx: number) => {
    const tpl = customTemplates[idx]; if (!tpl) return;
    setSaving(true);
    try {
      const res = await fetch(`/api/v1/menus/${menuId}/design`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ designConfig: { analog: tpl.overrides || tpl.config } }),
      });
      const data = await res.json();
      setConfig(data.designConfig?.analog || tpl.overrides || tpl.config);
      setTemplateName(tpl.baseTemplate || tpl.config?.template || 'elegant');
      setOverrides(data.designConfig?.analog || data.savedOverrides?.analog || {});
    } catch (e) { console.error(e); }
    setSaving(false);
  };

  const deleteCustomTemplate = async (idx: number) => {
    const nc = customTemplates.filter((_, i) => i !== idx);
    setCustomTemplates(nc);
    await fetch(`/api/v1/menus/${menuId}/design`, {
      method: 'PATCH', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ customTemplates: nc }),
    });
  };

  const saveCustomName = (name: string) => {
    setCustomName(name);
    saveConfig({ ...config, customName: name });
  };

  const toggleSection = (key: string) => setOpenSections(prev => ({ ...prev, [key]: !prev[key] }));

  if (loading) return <div className="flex items-center justify-center h-64"><div className="animate-spin rounded-full h-8 w-8 border-2 border-blue-600 border-t-transparent" /></div>;
  if (error) return <div className="p-4 bg-red-50 text-red-600 rounded-lg">{error}</div>;
  if (!config) return null;

  const pdfViewerUrl = `/pdf-viewer.html?url=${encodeURIComponent(`/api/v1/menus/${menuId}/pdf`)}&k=${previewKey}`;

  return (
    <div className="flex gap-6 h-full">
      {/* ─── Links: Editor ─── */}
      <div className="w-[420px] flex-shrink-0 overflow-y-auto space-y-4 pb-8">
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-500">
            Vorlage: <strong>{TEMPLATES.find(t => t.id === templateName)?.name || templateName}</strong>
            {hasCustomOverrides && <span className="ml-2 text-amber-600 text-xs">(Angepasst)</span>}
          </span>
          {saving && <span className="text-blue-600 animate-pulse">Speichern...</span>}
        </div>

        {/* Templates */}
        <div className="grid grid-cols-2 gap-2">
          {TEMPLATES.map(t => (
            <button key={t.id} onClick={() => handleTemplateClick(t.id)}
              className={`rounded-lg border-2 p-3 text-left transition-all ${!hasCustomOverrides && templateName === t.id ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'}`}>
              <div className="text-lg mb-1">{t.icon}</div>
              <div className="text-sm font-medium">{t.name}</div>
              <div className="text-xs text-gray-500">{t.desc}</div>
            </button>
          ))}
        </div>

        {/* Gespeicherte benutzerdefinierte Vorlagen */}
        {customTemplates.length > 0 && (
          <div className="grid grid-cols-2 gap-2">
            {customTemplates.map((ct, idx) => (
              <div key={idx}
                className="rounded-lg border-2 border-gray-200 hover:border-blue-300 p-3 text-left transition-all cursor-pointer relative group"
                onClick={() => loadCustomTemplate(idx)}>
                <div className="text-lg mb-1">✏️</div>
                <div className="text-sm font-medium truncate">{ct.name}</div>
                <div className="text-xs text-gray-500 truncate">Basis: {ct.baseTemplate === 'elegant' ? 'Elegant' : ct.baseTemplate === 'modern' ? 'Modern' : ct.baseTemplate === 'classic' ? 'Klassisch' : 'Minimal'}</div>
                <button onClick={(e: React.MouseEvent) => { e.stopPropagation(); deleteCustomTemplate(idx); }}
                  className="absolute top-1 right-1 hidden group-hover:flex items-center justify-center w-5 h-5 rounded-full bg-red-100 text-red-500 text-xs hover:bg-red-200"
                  title="Vorlage löschen">✕</button>
              </div>
            ))}
          </div>
        )}

        {/* Aktive benutzerdefinierte Anpassungen */}
        {hasCustomOverrides && (
          <div className="rounded-lg border-2 border-blue-500 bg-blue-50 p-3">
            <div className="text-lg mb-1">✏️</div>
            <input
              type="text"
              value={customName}
              onChange={e => saveCustomName(e.target.value)}
              placeholder="Benutzerdefiniert"
              className="w-full text-sm font-medium text-blue-700 bg-transparent border-b border-transparent hover:border-blue-300 focus:border-blue-500 focus:outline-none py-0.5 placeholder-blue-400"
            />
            <div className="text-xs text-blue-500 mt-0.5">Basierend auf {templateName === 'elegant' ? 'Elegant' : templateName === 'modern' ? 'Modern' : templateName === 'classic' ? 'Klassisch' : 'Minimal'}</div>
            {customTemplates.length < 4 && (
              <button onClick={() => saveAsCustomTemplate()}
                className="mt-2 w-full rounded-lg py-1.5 text-xs font-medium text-white bg-blue-500 hover:bg-blue-600 transition-colors">
                Als Vorlage speichern
              </button>
            )}
          </div>
        )}

        {hasCustomOverrides && (
          <button onClick={() => setShowResetDialog(true)}
            className="w-full py-2 text-sm text-red-600 border border-red-200 rounded-lg hover:bg-red-50 transition-colors">
            Auf Standardwerte zurücksetzen
          </button>
        )}

        {/* Akkordeon 1: Inhalt & Sprache */}
        <AccordionSection title="Inhalt & Sprache" icon="📄" open={!!openSections.content} onToggle={() => toggleSection('content')}>
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
          <SelectInput label="Beschreibungssprache" value={config.language?.descriptionLang || 'both'}
            options={[{ value: 'both', label: 'Beide' }, { value: 'primary', label: 'Nur Hauptsprache' }, { value: 'secondary', label: 'Nur Zweitsprache' }]}
            onChange={v => updateConfig('language.descriptionLang', v)} />
        </AccordionSection>

        {/* Akkordeon 2: Seitenformat */}
        <AccordionSection title="Seitenformat" icon="📐" open={!!openSections.page} onToggle={() => toggleSection('page')}>
          <SelectInput label="Format" value={config.page?.format || 'A4'}
            options={[{ value: 'A4', label: 'A4 (210 × 297 mm)' }, { value: 'A5', label: 'A5 (148 × 210 mm)' }, { value: 'LETTER', label: 'Letter' }]}
            onChange={v => updateConfig('page.format', v)} />
          <SelectInput label="Ausrichtung" value={config.page?.orientation || 'portrait'}
            options={[{ value: 'portrait', label: 'Hochformat' }, { value: 'landscape', label: 'Querformat' }]}
            onChange={v => updateConfig('page.orientation', v)} />
          <SelectInput label="Seitenränder" value={config.page?.margins || 'normal'}
            options={[{ value: 'narrow', label: 'Schmal' }, { value: 'normal', label: 'Normal' }, { value: 'wide', label: 'Breit' }]}
            onChange={v => updateConfig('page.margins', v)} />
          <Toggle label="Seitenzahlen" checked={config.page?.pageNumbers !== false} onChange={v => updateConfig('page.pageNumbers', v)} />
          <Toggle label="Beschnitt (3mm)" checked={!!config.page?.bleed} onChange={v => updateConfig('page.bleed', v)} />
        </AccordionSection>

        {/* Akkordeon 3: Deckblatt */}
        <AccordionSection title="Deckblatt" icon="🏔️" open={!!openSections.titlePage} onToggle={() => toggleSection('titlePage')}>
          <SelectInput label="Logo-Position" value={config.titlePage?.logoPosition || 'upperThird'}
            options={[{ value: 'upperThird', label: 'Oberes Drittel' }, { value: 'center', label: 'Zentriert' }, { value: 'lowerThird', label: 'Unteres Drittel' }]}
            onChange={v => updateConfig('titlePage.logoPosition', v)} />
          <NumberInput label="Logo-Größe" value={config.titlePage?.logoSize || 200} min={50} max={400} step={10} onChange={v => updateConfig('titlePage.logoSize', v)} suffix="px" />
          <ColorInput label="Hintergrundfarbe" value={config.titlePage?.logoBgColor || '#555555'} onChange={v => updateConfig('titlePage.logoBgColor', v)} />
          <TextInput label="Zitat (DE)" value={config.titlePage?.quote || ''} onChange={v => updateConfig('titlePage.quote', v)} placeholder="Begrüßungstext..." />
          <TextInput label="Zitat (EN)" value={config.titlePage?.quoteEN || ''} onChange={v => updateConfig('titlePage.quoteEN', v)} placeholder="Welcome text..." />
          <SelectInput label="Zitat-Schrift" value={config.titlePage?.quoteFont || 'Dancing Script'} options={FONTS} onChange={v => updateConfig('titlePage.quoteFont', v)} />
        </AccordionSection>

        {/* Akkordeon 4: Inhaltsverzeichnis */}
        <AccordionSection title="Inhaltsverzeichnis" icon="📑" open={!!openSections.toc} onToggle={() => toggleSection('toc')}>
          <SelectInput label="Tiefe" value={config.toc?.depth || 'categoryAndCountry'}
            options={[{ value: 'categoryOnly', label: 'Nur Kategorien' }, { value: 'categoryAndCountry', label: 'Kategorien + Herkunft' }, { value: 'full', label: 'Alle Ebenen' }]}
            onChange={v => updateConfig('toc.depth', v)} />
          <SelectInput label="Verbindungslinie" value={config.toc?.lineStyle || 'dotted'}
            options={[{ value: 'dotted', label: 'Gepunktet' }, { value: 'solid', label: 'Durchgezogen' }, { value: 'none', label: 'Keine' }]}
            onChange={v => updateConfig('toc.lineStyle', v)} />
          <Toggle label="Zweisprachig" checked={config.toc?.bilingual !== false} onChange={v => updateConfig('toc.bilingual', v)} />
          <Toggle label="Eingerückt" checked={config.toc?.indented !== false} onChange={v => updateConfig('toc.indented', v)} />
        </AccordionSection>

        {/* Akkordeon 5: Typografie */}
        <AccordionSection title="Typografie" icon="🔤" open={!!openSections.typography} onToggle={() => toggleSection('typography')}>
          <TypoEditor label="Kategorie-Titel" config={config.typography?.sectionTitle} onChange={(f, v) => updateConfig(`typography.sectionTitle.${f}`, v)} />
          <TypoEditor label="Unterkategorie" config={config.typography?.subCategory} onChange={(f, v) => updateConfig(`typography.subCategory.${f}`, v)} />
          <TypoEditor label="Untergruppierung" config={config.typography?.subGrouping} onChange={(f, v) => updateConfig(`typography.subGrouping.${f}`, v)} />
          <TypoEditor label="Produktname" config={config.typography?.productName} onChange={(f, v) => updateConfig(`typography.productName.${f}`, v)} />
          <TypoEditor label="Weingut" config={config.typography?.winery} onChange={(f, v) => updateConfig(`typography.winery.${f}`, v)} />
          <TypoEditor label="Beschreibung" config={config.typography?.description} onChange={(f, v) => updateConfig(`typography.description.${f}`, v)} />
          <TypoEditor label="Preis" config={config.typography?.price} onChange={(f, v) => updateConfig(`typography.price.${f}`, v)} />
        </AccordionSection>

        {/* Akkordeon 6: Farben */}
        <AccordionSection title="Farben" icon="🎨" open={!!openSections.colors} onToggle={() => toggleSection('colors')}>
          <div className="grid grid-cols-2 gap-3">
            <ColorInput label="Seitenhintergrund" value={config.colors?.pageBg || '#FFFFFF'} onChange={v => updateConfig('colors.pageBg', v)} />
            <ColorInput label="Textfarbe" value={config.colors?.textMain || '#333333'} onChange={v => updateConfig('colors.textMain', v)} />
            <ColorInput label="Akzentfarbe" value={config.colors?.accent || '#C8A850'} onChange={v => updateConfig('colors.accent', v)} />
            <ColorInput label="Preisfarbe" value={config.colors?.priceColor || '#000000'} onChange={v => updateConfig('colors.priceColor', v)} />
            <ColorInput label="Fußzeile" value={config.colors?.footerColor || '#999999'} onChange={v => updateConfig('colors.footerColor', v)} />
          </div>
        </AccordionSection>

        {/* Akkordeon 7: Produktdarstellung */}
        <AccordionSection title="Produktdarstellung" icon="🍷" open={!!openSections.productLayout} onToggle={() => toggleSection('productLayout')}>
          <Toggle label="Beschreibung (DE)" checked={config.productLayout?.descDE !== false} onChange={v => updateConfig('productLayout.descDE', v)} />
          <Toggle label="Beschreibung (EN)" checked={config.productLayout?.descEN !== false} onChange={v => updateConfig('productLayout.descEN', v)} />
          <SelectInput label="Beschreibungs-Layout" value={config.productLayout?.descLayout || 'stacked'}
            options={[{ value: 'stacked', label: 'Untereinander' }, { value: 'inline', label: 'Nebeneinander' }]}
            onChange={v => updateConfig('productLayout.descLayout', v)} />
          <SelectInput label="Abstand" value={config.productLayout?.spacing || 'normal'}
            options={[{ value: 'compact', label: 'Kompakt' }, { value: 'normal', label: 'Normal' }, { value: 'relaxed', label: 'Großzügig' }]}
            onChange={v => updateConfig('productLayout.spacing', v)} />
          <Toggle label="Trennlinie" checked={!!config.productLayout?.dividerLine} onChange={v => updateConfig('productLayout.dividerLine', v)} />
        </AccordionSection>

        {/* Akkordeon 8: Bilder */}
        <AccordionSection title="Bilder" icon="🖼️" open={!!openSections.images} onToggle={() => toggleSection('images')}>
          <Toggle label="Bilder anzeigen" checked={config.images?.show !== false} onChange={v => updateConfig('images.show', v)} />
          {config.images?.show !== false && (<>
            <SelectInput label="Position" value={config.images?.position || 'pageBottom'}
              options={[{ value: 'pageBottom', label: 'Seitenende' }, { value: 'afterSection', label: 'Nach Sektion' }, { value: 'inline', label: 'Im Text' }]}
              onChange={v => updateConfig('images.position', v)} />
            <NumberInput label="Max. pro Reihe" value={config.images?.maxPerRow || 4} min={1} max={6} onChange={v => updateConfig('images.maxPerRow', v)} />
            <NumberInput label="Höhe" value={config.images?.height || 120} min={40} max={300} step={10} onChange={v => updateConfig('images.height', v)} suffix="px" />
          </>)}
        </AccordionSection>

        {/* Akkordeon 9: Kopf-/Fußzeile */}
        <AccordionSection title="Kopf- & Fußzeile" icon="📏" open={!!openSections.headerFooter} onToggle={() => toggleSection('headerFooter')}>
          <Toggle label="Kategorienname in Kopfzeile" checked={config.headerFooter?.header?.repeatSectionName !== false}
            onChange={v => updateConfig('headerFooter.header.repeatSectionName', v)} />
          <SelectInput label="Kopfzeile Schrift" value={config.headerFooter?.header?.font || 'Dancing Script'} options={FONTS}
            onChange={v => updateConfig('headerFooter.header.font', v)} />
          <Toggle label="Kopfzeile Trennlinie" checked={config.headerFooter?.header?.dividerLine !== false}
            onChange={v => updateConfig('headerFooter.header.dividerLine', v)} />
          <hr className="border-gray-200" />
          <Toggle label="Fußzeile anzeigen" checked={config.headerFooter?.footer?.show !== false}
            onChange={v => updateConfig('headerFooter.footer.show', v)} />
          {config.headerFooter?.footer?.show !== false && (<>
            <TextInput label="Text Links" value={config.headerFooter?.footer?.textLeft || ''} onChange={v => updateConfig('headerFooter.footer.textLeft', v)} />
            <TextInput label="Text Rechts" value={config.headerFooter?.footer?.textRight || ''} onChange={v => updateConfig('headerFooter.footer.textRight', v)} placeholder="{pageNumber}" />
            <Toggle label="Fußzeile Trennlinie" checked={config.headerFooter?.footer?.dividerLine !== false}
              onChange={v => updateConfig('headerFooter.footer.dividerLine', v)} />
          </>)}
        </AccordionSection>

        {/* Akkordeon 10: Seitenumbrüche */}
        <AccordionSection title="Seitenumbrüche" icon="📃" open={!!openSections.pageBreaks} onToggle={() => toggleSection('pageBreaks')}>
          <Toggle label="Neue Seite pro Hauptkategorie" checked={config.pageBreaks?.newPagePerMainCategory !== false}
            onChange={v => updateConfig('pageBreaks.newPagePerMainCategory', v)} />
          <Toggle label="Keine Waisen-Produkte" checked={config.pageBreaks?.noOrphanProducts !== false}
            onChange={v => updateConfig('pageBreaks.noOrphanProducts', v)} description="Vermeidet einzelne Produkte am Seitenende" />
          <NumberInput label="Min. Produkte nach Überschrift" value={config.pageBreaks?.minProductsAfterHeader || 2}
            min={1} max={5} onChange={v => updateConfig('pageBreaks.minProductsAfterHeader', v)} />
        </AccordionSection>
      </div>

      {/* ─── Rechts: PDF-Vorschau ─── */}
      <div className="flex-1 flex flex-col min-w-0">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-medium text-gray-700">PDF-Vorschau</h3>
          <div className="flex gap-2">
            <button onClick={() => setPreviewKey(k => k + 1)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm font-medium transition-colors">
              🔄 Vorschau aktualisieren
            </button>
            <button onClick={() => window.open(`/api/v1/menus/${menuId}/pdf`, '_blank')}
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm font-medium transition-colors">
              ⬇️ PDF herunterladen
            </button>
          </div>
        </div>
        <div className="flex-1 bg-gray-100 rounded-lg border border-gray-200 overflow-hidden" style={{ minHeight: '700px' }}>
          {previewKey > 0 ? (
            <iframe src={pdfViewerUrl} className="w-full h-full border-0" title="PDF-Vorschau" />
          ) : (
            <div className="flex flex-col items-center justify-center h-full text-gray-400">
              <span className="text-5xl mb-4">📄</span>
              <p className="text-lg font-medium">PDF-Vorschau</p>
              <p className="text-sm mt-1">Klicken Sie auf &quot;Vorschau aktualisieren&quot;</p>
            </div>
          )}
        </div>
      </div>

      {/* Dialoge */}
      <ConfirmDialog open={showResetDialog} title="Auf Standardwerte zurücksetzen?"
        message={`Alle Anpassungen werden verworfen und die Vorlage "${TEMPLATES.find(t => t.id === templateName)?.name}" wird auf Standardwerte zurückgesetzt.`}
        onConfirm={resetToDefaults} onCancel={() => setShowResetDialog(false)} />
      <ConfirmDialog open={!!showTemplateSwitch} title="Vorlage wechseln?"
        message="Sie haben Anpassungen vorgenommen. Beim Wechsel gehen diese verloren."
        onConfirm={() => { switchTemplate(showTemplateSwitch!); setShowTemplateSwitch(null); }}
        onCancel={() => setShowTemplateSwitch(null)} />
    </div>
  );
}
