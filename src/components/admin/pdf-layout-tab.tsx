'use client';
import React, { useState } from 'react';

// ─── Types ───
export type AnalogConfig = any;

type UpdateFn = (path: string, value: any) => void;

type Props = {
  analogConfig: AnalogConfig;
  update: UpdateFn;
  previewPdfUrl?: string | null;
};

// ─── Options ───
const FORMAT_OPTIONS = [
  { label: 'A4 (210 × 297 mm)', value: 'A4' },
  { label: 'A5 (148 × 210 mm)', value: 'A5' },
];

const ORIENTATION_OPTIONS = [
  { label: 'Hochformat', value: 'portrait' },
  { label: 'Querformat', value: 'landscape' },
];

const MARGIN_OPTIONS = [
  { label: 'Schmal', value: 'narrow' },
  { label: 'Normal', value: 'normal' },
  { label: 'Breit', value: 'wide' },
  { label: 'Benutzerdefiniert', value: 'custom' },
];

const DEPTH_OPTIONS = [
  { label: 'Nur Hauptkategorien', value: 'categoryOnly' },
  { label: 'Kategorien + Land/Region', value: 'categoryAndCountry' },
  { label: 'Vollständig (alle Ebenen)', value: 'full' },
];

const LINE_STYLE_OPTIONS = [
  { label: 'Gepunktet', value: 'dotted' },
  { label: 'Gestrichelt', value: 'dashed' },
  { label: 'Durchgezogen', value: 'solid' },
  { label: 'Keine Linie', value: 'none' },
];

const POSITION_OPTIONS = [
  { label: 'Nach Titelseite', value: 'afterTitle' },
  { label: 'Am Ende', value: 'atEnd' },
];

const IMAGE_POSITION_OPTIONS = [
  { label: 'Am Seitenende', value: 'pageBottom' },
  { label: 'Neben Produkten', value: 'inline' },
  { label: 'Auf eigener Seite', value: 'ownPage' },
];

const IMAGE_STYLE_OPTIONS = [
  { label: 'Farbig', value: 'color' },
  { label: 'Graustufen', value: 'grayscale' },
  { label: 'Schwarz-Weiß', value: 'bw' },
];

const IMAGE_TYPE_OPTIONS = [
  { value: 'BOTTLE', label: 'Flasche' },
  { value: 'LABEL', label: 'Etikett' },
  { value: 'DISH', label: 'Gericht' },
  { value: 'PRODUCT', label: 'Produkt' },
];

const DESC_LANG_OPTIONS = [
  { label: 'Deutsch', value: 'de' },
  { label: 'Englisch', value: 'en' },
  { label: 'Beide Sprachen', value: 'both' },
];

const DESC_ALIGN_OPTIONS = [
  { label: 'Links', value: 'left' },
  { label: 'Zentriert', value: 'center' },
  { label: 'Blocksatz', value: 'justify' },
];

const PRICE_FORMAT_OPTIONS = [
  { label: 'Glas / Flasche kombiniert', value: 'combined' },
  { label: 'Nur Flaschenpreis', value: 'bottleOnly' },
  { label: 'Alle Varianten', value: 'all' },
];

const FONTS = [
  'Playfair Display', 'Cormorant Garamond', 'Libre Baskerville',
  'Source Sans 3', 'Inter', 'Lato', 'Open Sans',
  'Dancing Script', 'Great Vibes', 'Pinyon Script',
  'Josefin Sans', 'Raleway', 'Montserrat',
];

// ─── Small helpers ───
function Label({ children }: { children: React.ReactNode }) {
  return <label className="block text-xs font-medium text-gray-500 mb-1">{children}</label>;
}

function NumInput({ value, onChange, min, max, step, suffix }: {
  value: number; onChange: (v: number) => void; min?: number; max?: number; step?: number; suffix?: string;
}) {
  return (
    <div className="flex items-center gap-1.5">
      <input
        type="number"
        value={value ?? 0}
        min={min}
        max={max}
        step={step || 1}
        onChange={e => onChange(Number(e.target.value))}
        className="w-20 rounded-lg border border-gray-200 px-2 py-1 text-sm outline-none focus:border-gray-400"
      />
      {suffix && <span className="text-xs text-gray-500">{suffix}</span>}
    </div>
  );
}

function TextInput({ value, onChange, placeholder }: { value: string; onChange: (v: string) => void; placeholder?: string }) {
  return (
    <input
      type="text"
      value={value ?? ''}
      placeholder={placeholder}
      onChange={e => onChange(e.target.value)}
      className="w-full rounded-lg border border-gray-200 px-2 py-1.5 text-sm outline-none focus:border-gray-400"
    />
  );
}

function ColorInput({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <div className="flex items-center gap-2">
      <input
        type="color"
        value={value || '#000000'}
        onChange={e => onChange(e.target.value)}
        className="h-8 w-8 cursor-pointer rounded border border-gray-300 p-0.5"
      />
      <div className="flex-1">
        <div className="text-xs text-gray-500">{label}</div>
        <input
          type="text"
          value={value || ''}
          onChange={e => onChange(e.target.value)}
          className="w-full text-xs font-mono border-b border-gray-200 py-0.5 outline-none focus:border-gray-400"
        />
      </div>
    </div>
  );
}

function SelectInput({ label, value, options, onChange }: {
  label: string; value: string; options: { label: string; value: string }[]; onChange: (v: string) => void;
}) {
  return (
    <div>
      <Label>{label}</Label>
      <select
        value={value ?? ''}
        onChange={e => onChange(e.target.value)}
        className="w-full rounded-lg border border-gray-200 px-2 py-1.5 text-sm outline-none focus:border-gray-400"
      >
        {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
    </div>
  );
}

function FontSelect({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <SelectInput label={label} value={value || 'Source Sans 3'} onChange={onChange}
      options={FONTS.map(f => ({ label: f, value: f }))} />
  );
}

function Toggle({ label, checked, onChange }: { label: string; checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <label className="flex items-center justify-between gap-3 cursor-pointer select-none">
      <span className="text-sm text-gray-700">{label}</span>
      <span
        className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors ${checked ? 'bg-gray-900' : 'bg-gray-300'}`}
        onClick={() => onChange(!checked)}
        role="switch"
        aria-checked={checked}
      >
        <span
          className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${checked ? 'translate-x-4' : 'translate-x-0.5'}`}
        />
      </span>
    </label>
  );
}

function SectionTitle({ children }: { children: React.ReactNode }) {
  return <h4 className="text-xs font-semibold uppercase tracking-wider text-gray-500 mb-2">{children}</h4>;
}

function Accordion({ id, label, icon, open, onToggle, children }: {
  id: string; label: string; icon: string; open: boolean; onToggle: (id: string) => void; children: React.ReactNode;
}) {
  return (
    <div className="rounded-xl border border-gray-200 bg-white overflow-hidden">
      <button
        onClick={() => onToggle(id)}
        className="w-full flex items-center justify-between px-3 py-2.5 hover:bg-gray-50 transition-colors"
      >
        <span className="flex items-center gap-2">
          <span className="material-symbols-outlined" style={{ fontSize: 18, color: '#6B7280' }}>{icon}</span>
          <span className="text-sm font-medium text-gray-800">{label}</span>
        </span>
        <span className="material-symbols-outlined text-gray-400" style={{ fontSize: 18 }}>
          {open ? 'expand_less' : 'expand_more'}
        </span>
      </button>
      {open && (
        <div className="px-3 pb-3 pt-1 border-t border-gray-100 space-y-4">
          {children}
        </div>
      )}
    </div>
  );
}

function TypoEditor({ label, desc, val, path, update }: {
  label: string; desc?: string; val: any; path: string; update: UpdateFn;
}) {
  const v = val || {};
  return (
    <div className="rounded-lg border border-gray-100 p-2.5 space-y-2">
      <div>
        <div className="text-xs font-semibold text-gray-700">{label}</div>
        {desc && <div className="text-[10px] text-gray-400 mt-0.5">{desc}</div>}
      </div>
      <div className="grid grid-cols-2 gap-2">
        <FontSelect label="Schriftart" value={v.font} onChange={x => update(`${path}.font`, x)} />
        <div>
          <Label>Größe (pt)</Label>
          <NumInput value={v.size} onChange={x => update(`${path}.size`, x)} min={6} max={72} />
        </div>
        <div>
          <Label>Stärke</Label>
          <select
            value={v.weight || 400}
            onChange={e => update(`${path}.weight`, Number(e.target.value))}
            className="w-full rounded-lg border border-gray-200 px-2 py-1.5 text-sm outline-none focus:border-gray-400"
          >
            <option value={300}>Light (300)</option>
            <option value={400}>Normal (400)</option>
            <option value={500}>Medium (500)</option>
            <option value={600}>Semibold (600)</option>
            <option value={700}>Bold (700)</option>
          </select>
        </div>
        <div>
          <Label>Farbe</Label>
          <ColorInput label="" value={v.color || '#000000'} onChange={x => update(`${path}.color`, x)} />
        </div>
      </div>
    </div>
  );
}

// ─── Main ───
export function TabPdfLayout({ analogConfig, update, previewPdfUrl }: Props) {
  const [open, setOpen] = useState<string>('seite');
  const toggle = (id: string) => setOpen(prev => prev === id ? '' : id);
  const cfg = analogConfig || {};

  const page = cfg.page || {};
  const titlePage = cfg.titlePage || {};
  const toc = cfg.toc || {};
  const typo = cfg.typography || {};
  const colors = cfg.colors || {};
  const productLayout = cfg.productLayout || {};
  const images = cfg.images || {};
  const language = cfg.language || {};
  const headerFooter = cfg.headerFooter || {};
  const header = headerFooter.header || {};
  const footer = headerFooter.footer || {};
  const pageBreaks = cfg.pageBreaks || {};

  const imgTypes: string[] = Array.isArray(images.typeFilter) ? images.typeFilter : [];
  const toggleImageType = (t: string) => {
    const next = imgTypes.includes(t) ? imgTypes.filter(x => x !== t) : [...imgTypes, t];
    update('images.typeFilter', next);
  };

  return (
    <div className="space-y-3">
      {/* Info Banner */}
      <div className="rounded-xl bg-blue-50 border border-blue-100 p-3 flex gap-2">
        <span className="material-symbols-outlined text-blue-600" style={{ fontSize: 20 }}>picture_as_pdf</span>
        <div className="text-xs text-blue-900 leading-relaxed">
          Diese Einstellungen gelten für die <strong>druckbare PDF-Version</strong> der Karte.
          Die digitale Gästeansicht wird nicht verändert. Änderungen werden automatisch gespeichert.
          {previewPdfUrl && (
            <>
              {' '}
              <a
                href={previewPdfUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="font-medium underline hover:no-underline"
              >
                PDF-Vorschau öffnen ↗
              </a>
            </>
          )}
        </div>
      </div>

      {/* Seite */}
      <Accordion id="seite" label="Seite & Papier" icon="description" open={open === 'seite'} onToggle={toggle}>
        <SelectInput label="Format" value={page.format || 'A4'}
          options={FORMAT_OPTIONS} onChange={v => update('page.format', v)} />
        <SelectInput label="Ausrichtung" value={page.orientation || 'portrait'}
          options={ORIENTATION_OPTIONS} onChange={v => update('page.orientation', v)} />
        <SelectInput label="Seitenränder" value={page.margins || 'normal'}
          options={MARGIN_OPTIONS} onChange={v => update('page.margins', v)} />
        {page.margins === 'custom' && (
          <div className="grid grid-cols-2 gap-2 rounded-lg bg-gray-50 p-2">
            <div>
              <Label>Oben (mm)</Label>
              <NumInput value={page.customMargins?.top ?? 20} onChange={v => update('page.customMargins.top', v)} min={0} max={80} />
            </div>
            <div>
              <Label>Unten (mm)</Label>
              <NumInput value={page.customMargins?.bottom ?? 20} onChange={v => update('page.customMargins.bottom', v)} min={0} max={80} />
            </div>
            <div>
              <Label>Links (mm)</Label>
              <NumInput value={page.customMargins?.left ?? 20} onChange={v => update('page.customMargins.left', v)} min={0} max={80} />
            </div>
            <div>
              <Label>Rechts (mm)</Label>
              <NumInput value={page.customMargins?.right ?? 20} onChange={v => update('page.customMargins.right', v)} min={0} max={80} />
            </div>
          </div>
        )}
        <Toggle label="Seitenzahlen anzeigen" checked={page.pageNumbers ?? true}
          onChange={v => update('page.pageNumbers', v)} />
        {(page.pageNumbers ?? true) && (
          <div>
            <Label>Startseite für Nummerierung</Label>
            <NumInput value={page.pageNumberStart ?? 1} onChange={v => update('page.pageNumberStart', v)} min={1} max={20} />
          </div>
        )}
        <Toggle label="Titelseite in Seitenzählung einbeziehen" checked={page.countTitlePage ?? false}
          onChange={v => update('page.countTitlePage', v)} />

        <div className="pt-2 border-t border-gray-100">
          <SectionTitle>Sprachen</SectionTitle>
          <div className="space-y-2">
            <SelectInput label="Primärsprache" value={language.primary || 'de'}
              options={[{ label: 'Deutsch', value: 'de' }, { label: 'Englisch', value: 'en' }]}
              onChange={v => update('language.primary', v)} />
            <SelectInput label="Zweitsprache" value={language.secondary || 'en'}
              options={[
                { label: 'Keine', value: '' },
                { label: 'Deutsch', value: 'de' },
                { label: 'Englisch', value: 'en' },
              ]}
              onChange={v => update('language.secondary', v)} />
            <SelectInput label="Beschreibungs-Sprache" value={language.descriptionLang || 'both'}
              options={DESC_LANG_OPTIONS} onChange={v => update('language.descriptionLang', v)} />
          </div>
        </div>
      </Accordion>

      {/* Titelseite */}
      <Accordion id="titel" label="Titelseite" icon="auto_stories" open={open === 'titel'} onToggle={toggle}>
        <Toggle label="Titelseite anzeigen" checked={cfg.content?.showTitlePage ?? true}
          onChange={v => update('content.showTitlePage', v)} />
        {(cfg.content?.showTitlePage ?? true) && (
          <>
            <div>
              <Label>Hintergrundfarbe der Titelseite</Label>
              <ColorInput label="" value={titlePage.logoBgColor || '#555555'}
                onChange={v => update('titlePage.logoBgColor', v)} />
            </div>
            <div>
              <Label>Logo-Position</Label>
              <SelectInput label="" value={titlePage.logoPosition || 'center'}
                options={[
                  { label: 'Zentriert', value: 'center' },
                  { label: 'Oben', value: 'top' },
                  { label: 'Unten', value: 'bottom' },
                ]} onChange={v => update('titlePage.logoPosition', v)} />
            </div>
            <div>
              <Label>Logo-Größe</Label>
              <SelectInput label="" value={titlePage.logoSize || 'medium'}
                options={[
                  { label: 'Klein', value: 'small' },
                  { label: 'Mittel', value: 'medium' },
                  { label: 'Groß', value: 'large' },
                ]} onChange={v => update('titlePage.logoSize', v)} />
            </div>
            <div className="pt-2 border-t border-gray-100 space-y-2">
              <SectionTitle>Zitat</SectionTitle>
              <div>
                <Label>Zitat (Deutsch)</Label>
                <TextInput value={titlePage.quote || ''} onChange={v => update('titlePage.quote', v)}
                  placeholder='z.B. "Im Wein liegt Wahrheit."' />
              </div>
              <div>
                <Label>Zitat (Englisch)</Label>
                <TextInput value={titlePage.quoteEN || ''} onChange={v => update('titlePage.quoteEN', v)}
                  placeholder='e.g. "In wine there is truth."' />
              </div>
              <div>
                <Label>Autor / Quelle</Label>
                <TextInput value={titlePage.quoteAuthor || ''} onChange={v => update('titlePage.quoteAuthor', v)}
                  placeholder="z.B. Plinius" />
              </div>
              <FontSelect label="Schriftart des Zitats" value={titlePage.quoteFont || 'Dancing Script'}
                onChange={v => update('titlePage.quoteFont', v)} />
            </div>
          </>
        )}
      </Accordion>

      {/* Inhaltsverzeichnis */}
      <Accordion id="toc" label="Inhaltsverzeichnis" icon="list_alt" open={open === 'toc'} onToggle={toggle}>
        <Toggle label="Inhaltsverzeichnis anzeigen" checked={cfg.content?.showToc ?? true}
          onChange={v => update('content.showToc', v)} />
        {(cfg.content?.showToc ?? true) && (
          <>
            <SelectInput label="Detailtiefe" value={toc.depth || 'categoryAndCountry'}
              options={DEPTH_OPTIONS} onChange={v => update('toc.depth', v)} />
            <SelectInput label="Linienstil" value={toc.lineStyle || 'dotted'}
              options={LINE_STYLE_OPTIONS} onChange={v => update('toc.lineStyle', v)} />
            <SelectInput label="Position" value={toc.position || 'afterTitle'}
              options={POSITION_OPTIONS} onChange={v => update('toc.position', v)} />
            <Toggle label="Zweisprachig anzeigen" checked={toc.bilingual ?? true}
              onChange={v => update('toc.bilingual', v)} />
            <Toggle label="Eingerückt darstellen" checked={toc.indented ?? true}
              onChange={v => update('toc.indented', v)} />
          </>
        )}
        <div className="pt-2 border-t border-gray-100 space-y-2">
          <Toggle label="Legende am Ende anzeigen" checked={cfg.content?.showLegend ?? true}
            onChange={v => update('content.showLegend', v)} />
          <Toggle label="QR-Code-Seite am Ende" checked={cfg.content?.showQrPage ?? true}
            onChange={v => update('content.showQrPage', v)} />
        </div>
      </Accordion>

      {/* Typografie & Farben */}
      <Accordion id="typo" label="Typografie & Farben" icon="text_fields" open={open === 'typo'} onToggle={toggle}>
        <SectionTitle>Farben</SectionTitle>
        <div className="space-y-2">
          <ColorInput label="Seitenhintergrund" value={colors.pageBg || '#FFFFFF'}
            onChange={v => update('colors.pageBg', v)} />
          <ColorInput label="Haupttext" value={colors.textMain || '#333333'}
            onChange={v => update('colors.textMain', v)} />
          <ColorInput label="Akzentfarbe (Überschriften, Linien)" value={colors.accent || '#C8A850'}
            onChange={v => update('colors.accent', v)} />
          <ColorInput label="Preisfarbe" value={colors.priceColor || '#000000'}
            onChange={v => update('colors.priceColor', v)} />
          <ColorInput label="Fußzeilen-Farbe" value={colors.footerColor || '#999999'}
            onChange={v => update('colors.footerColor', v)} />
        </div>

        <div className="pt-2 border-t border-gray-100 space-y-2">
          <SectionTitle>Schriften pro Ebene</SectionTitle>
          <TypoEditor label="Sektions-Titel" desc='z.B. "Weißwein", "Rotwein"'
            val={typo.sectionTitle} path="typography.sectionTitle" update={update} />
          <TypoEditor label="Unterkategorie" desc='z.B. "Österreich"'
            val={typo.subCategory} path="typography.subCategory" update={update} />
          <TypoEditor label="Unter-Gruppierung" desc='z.B. "Wachau"'
            val={typo.subGrouping} path="typography.subGrouping" update={update} />
          <TypoEditor label="Produktname"
            val={typo.productName} path="typography.productName" update={update} />
          <TypoEditor label="Weingut / Hersteller"
            val={typo.winery} path="typography.winery" update={update} />
          <TypoEditor label="Beschreibung"
            val={typo.description} path="typography.description" update={update} />
          <TypoEditor label="Preis"
            val={typo.price} path="typography.price" update={update} />
        </div>
      </Accordion>

      {/* Produkt-Layout & Bilder */}
      <Accordion id="produkt" label="Produkt-Layout & Bilder" icon="inventory_2" open={open === 'produkt'} onToggle={toggle}>
        <SectionTitle>Produkt-Darstellung</SectionTitle>
        <Toggle label="Weingut/Hersteller anzeigen" checked={productLayout.wineryShow ?? true}
          onChange={v => update('productLayout.wineryShow', v)} />
        <Toggle label="Beschreibung Deutsch" checked={productLayout.descDE ?? true}
          onChange={v => update('productLayout.descDE', v)} />
        <Toggle label="Beschreibung Englisch" checked={productLayout.descEN ?? false}
          onChange={v => update('productLayout.descEN', v)} />
        <SelectInput label="Beschreibungs-Ausrichtung" value={productLayout.descAlign || 'left'}
          options={DESC_ALIGN_OPTIONS} onChange={v => update('productLayout.descAlign', v)} />
        <SelectInput label="Preisformat" value={productLayout.priceFormat || 'combined'}
          options={PRICE_FORMAT_OPTIONS} onChange={v => update('productLayout.priceFormat', v)} />
        <Toggle label="Mehrere Preise anzeigen (Glas + Flasche)" checked={productLayout.multiplePrices ?? true}
          onChange={v => update('productLayout.multiplePrices', v)} />
        <Toggle label="Trennlinie zwischen Produkten" checked={productLayout.dividerLine ?? false}
          onChange={v => update('productLayout.dividerLine', v)} />
        <div>
          <Label>Abstand zwischen Produkten (pt)</Label>
          <NumInput value={productLayout.spacing ?? 8} onChange={v => update('productLayout.spacing', v)} min={0} max={40} />
        </div>

        <div className="pt-2 border-t border-gray-100 space-y-2">
          <SectionTitle>Bilder</SectionTitle>
          <Toggle label="Bilder in PDF anzeigen" checked={images.show ?? true}
            onChange={v => update('images.show', v)} />
          {(images.show ?? true) && (
            <>
              <SelectInput label="Position" value={images.position || 'pageBottom'}
                options={IMAGE_POSITION_OPTIONS} onChange={v => update('images.position', v)} />
              <SelectInput label="Darstellung" value={images.style || 'color'}
                options={IMAGE_STYLE_OPTIONS} onChange={v => update('images.style', v)} />
              <div>
                <Label>Max. Bilder pro Reihe</Label>
                <NumInput value={images.maxPerRow ?? 4} onChange={v => update('images.maxPerRow', v)} min={1} max={8} />
              </div>
              <div>
                <Label>Bildhöhe (pt)</Label>
                <NumInput value={images.height ?? 120} onChange={v => update('images.height', v)} min={40} max={400} />
              </div>
              <div>
                <Label>Welche Bildtypen?</Label>
                <div className="grid grid-cols-2 gap-1.5 mt-1">
                  {IMAGE_TYPE_OPTIONS.map(t => {
                    const active = imgTypes.includes(t.value);
                    return (
                      <button
                        key={t.value}
                        onClick={() => toggleImageType(t.value)}
                        className={`text-xs py-1.5 px-2 rounded-lg border transition-colors ${active ? 'bg-gray-900 text-white border-gray-900' : 'bg-white text-gray-700 border-gray-200 hover:border-gray-400'}`}
                      >
                        {t.label}
                      </button>
                    );
                  })}
                </div>
              </div>
            </>
          )}
        </div>
      </Accordion>

      {/* Kopf/Fuß & Seitenumbrüche */}
      <Accordion id="ramen" label="Kopf/Fuß & Umbrüche" icon="crop_landscape" open={open === 'ramen'} onToggle={toggle}>
        <SectionTitle>Kopfzeile</SectionTitle>
        <Toggle label="Sektionsnamen in Kopfzeile wiederholen" checked={header.repeatSectionName ?? true}
          onChange={v => update('headerFooter.header.repeatSectionName', v)} />
        <Toggle label="Trennlinie unter Kopfzeile" checked={header.dividerLine ?? true}
          onChange={v => update('headerFooter.header.dividerLine', v)} />
        {(header.repeatSectionName ?? true) && (
          <FontSelect label="Schriftart Kopfzeile" value={header.font || 'Dancing Script'}
            onChange={v => update('headerFooter.header.font', v)} />
        )}

        <div className="pt-2 border-t border-gray-100 space-y-2">
          <SectionTitle>Fußzeile</SectionTitle>
          <Toggle label="Fußzeile anzeigen" checked={footer.show ?? true}
            onChange={v => update('headerFooter.footer.show', v)} />
          {(footer.show ?? true) && (
            <>
              <div>
                <Label>Fußzeilen-Text (Deutsch)</Label>
                <TextInput value={footer.text || ''} onChange={v => update('headerFooter.footer.text', v)}
                  placeholder="z.B. Hotel Sonnblick · Kaprun" />
              </div>
              <div>
                <Label>Fußzeilen-Text (Englisch)</Label>
                <TextInput value={footer.textEN || ''} onChange={v => update('headerFooter.footer.textEN', v)}
                  placeholder="e.g. Hotel Sonnblick · Kaprun" />
              </div>
              <Toggle label="Allergen-Hinweis" checked={footer.showAllergenNote ?? true}
                onChange={v => update('headerFooter.footer.showAllergenNote', v)} />
              <Toggle label="Preishinweis" checked={footer.showPriceNote ?? true}
                onChange={v => update('headerFooter.footer.showPriceNote', v)} />
            </>
          )}
        </div>

        <div className="pt-2 border-t border-gray-100 space-y-2">
          <SectionTitle>Seitenumbrüche</SectionTitle>
          <Toggle label="Neue Seite pro Hauptkategorie" checked={pageBreaks.newPagePerMainCategory ?? true}
            onChange={v => update('pageBreaks.newPagePerMainCategory', v)} />
          <Toggle label="Keine Waisenkind-Produkte (am Seitenende)" checked={pageBreaks.noOrphanProducts ?? true}
            onChange={v => update('pageBreaks.noOrphanProducts', v)} />
          <Toggle label="Bilder bei zugehörigem Text halten" checked={pageBreaks.keepImagesWithText ?? true}
            onChange={v => update('pageBreaks.keepImagesWithText', v)} />
          <div>
            <Label>Minimum Produkte nach Kopfzeile</Label>
            <NumInput value={pageBreaks.minProductsAfterHeader ?? 2}
              onChange={v => update('pageBreaks.minProductsAfterHeader', v)} min={0} max={10} />
          </div>
        </div>
      </Accordion>
    </div>
  );
}
