/**
 * Self-Test für den SchemaForm-Renderer (Sprint 2 Abschluss-Check).
 *
 * Aufruf:   npx tsx scripts/test-schema-form.tsx
 * Exit-Code: 0 bei Erfolg, 1 bei Fehler.
 *
 * Strategie:
 *   - Server-Side-Render via `react-dom/server` → wir prüfen das HTML-Output.
 *   - Kein jsdom, keine Interaktionstests (Sprint 2 deckt nur Rendering ab).
 *   - Interaktive Tests kommen in Phase 1's Playwright-Smoke-Test.
 *
 * Prüft:
 *   1. FieldRenderer liefert Markup für jeden der 8 Feldtypen.
 *   2. SchemaForm rendert alle 11 Schemas aus der Registry fehlerfrei.
 *   3. visibleIf blendet Felder korrekt aus/ein.
 *   4. Validator-Errors werden im Output sichtbar.
 */
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { FieldRenderer } from '../src/components/admin/schema-form/fields';
import { SchemaForm } from '../src/components/admin/schema-form/SchemaForm';
import {
  ALL_SCHEMAS,
  heroSchema,
  itemCardSchema,
  applyDefaults,
} from '../src/lib/design-templates/schemas';
import type { FieldDef } from '../src/lib/design-templates/schemas/types';

let failed = 0;
let passed = 0;

function check(label: string, ok: boolean, detail?: string): void {
  if (ok) {
    console.log(`  ✓ ${label}`);
    passed++;
  } else {
    console.log(`  ✗ ${label}${detail ? `\n    → ${detail}` : ''}`);
    failed++;
  }
}

function section(label: string): void {
  console.log(`\n━━ ${label} ━━`);
}

function render(node: React.ReactElement): string {
  try {
    return renderToStaticMarkup(node);
  } catch (err: any) {
    return `__ERROR__${err?.message || String(err)}`;
  }
}

// ─── 1. FieldRenderer: ein Feld pro Typ ────────────────────────
section('1. FieldRenderer rendert alle 8 Feldtypen');

const fieldSamples: Array<{ label: string; def: FieldDef; value: any; mustContain: string[] }> = [
  {
    label: 'boolean',
    def: { type: 'boolean', label: 'Zeige Icon', default: true },
    value: true,
    mustContain: ['Zeige Icon', 'aria-pressed="true"'],
  },
  {
    label: 'select',
    def: {
      type: 'select',
      label: 'Stil',
      default: 'a',
      options: [
        { label: 'Variante A', value: 'a' },
        { label: 'Variante B', value: 'b' },
      ],
    },
    value: 'b',
    mustContain: ['Stil', '<select', 'Variante A', 'Variante B'],
  },
  {
    label: 'color (6-Hex)',
    def: { type: 'color', label: 'Akzent', default: '#FF8800' },
    value: '#112233',
    mustContain: ['Akzent', 'type="color"', 'value="#112233"'],
  },
  {
    label: 'color (Alpha)',
    def: { type: 'color', label: 'Hintergrund', default: '#FFFFFFFF', allowAlpha: true },
    value: '#112233AA',
    mustContain: ['Hintergrund', '#112233AA'],
  },
  {
    label: 'number',
    def: { type: 'number', label: 'Logo-Höhe', default: 120, min: 10, max: 500, unit: 'px' },
    value: 200,
    mustContain: ['Logo-Höhe', 'type="number"', 'value="200"'],
  },
  {
    label: 'slider',
    def: { type: 'slider', label: 'Overlay', default: 50, min: 0, max: 100, unit: '%' },
    value: 80,
    mustContain: ['Overlay', 'type="range"', 'value="80"', '80%'],
  },
  {
    label: 'text (single-line)',
    def: { type: 'text', label: 'Titel', default: '' },
    value: 'Weinkarte',
    mustContain: ['Titel', 'value="Weinkarte"'],
  },
  {
    label: 'text (multiline)',
    def: { type: 'text', label: 'Fuß-Notiz', default: '', multiline: true, maxLength: 200 },
    value: 'Preise inkl. USt.',
    mustContain: ['Fuß-Notiz', '<textarea', '17/200'],
  },
  {
    label: 'font',
    def: { type: 'font', label: 'H1-Schrift', default: 'Inter' },
    value: 'Playfair Display',
    mustContain: ['H1-Schrift', '<select', 'Inter', 'Playfair Display'],
  },
  {
    label: 'multitoggle',
    def: {
      type: 'multitoggle',
      label: 'Wein-Details',
      default: [],
      options: [
        { label: 'Winery', value: 'winery' },
        { label: 'Vintage', value: 'vintage' },
        { label: 'Grape', value: 'grape' },
      ],
    },
    value: ['winery', 'vintage'],
    mustContain: ['Wein-Details', 'Winery', 'Vintage', 'Grape', 'aria-pressed="true"'],
  },
];

for (const s of fieldSamples) {
  const html = render(<FieldRenderer def={s.def} value={s.value} onChange={() => {}} />);
  const missing = s.mustContain.filter((needle) => !html.includes(needle));
  check(
    `FieldRenderer "${s.label}" rendert erwartetes Markup`,
    missing.length === 0 && !html.startsWith('__ERROR__'),
    missing.length > 0
      ? `fehlt: ${missing.join(', ')}\n    HTML: ${html.slice(0, 240)}…`
      : html.startsWith('__ERROR__')
        ? html
        : undefined,
  );
}

// Text-Counter explizit testen (17/200)
const textHtml = render(
  <FieldRenderer
    def={{ type: 'text', label: 'x', default: '', maxLength: 200, multiline: true } as FieldDef}
    value="Preise inkl. USt."
    onChange={() => {}}
  />,
);
check('TextField-Multiline zeigt Längen-Counter', textHtml.includes('17/200'));

// ─── 2. SchemaForm: alle 11 Schemas mit Defaults ───────────────
section('2. SchemaForm rendert alle 11 Schemas mit Defaults');

for (const schema of ALL_SCHEMAS) {
  const cfg = applyDefaults({}, schema);
  const html = render(<SchemaForm schema={schema} config={cfg} onChange={() => {}} />);
  const hasSchemaId = html.includes(`data-schema-id="${schema.id}"`);
  const noError = !html.startsWith('__ERROR__');
  // Eine Gruppe darf fehlen, wenn ALLE ihre Felder durch visibleIf versteckt sind
  // (korrektes SchemaForm-Verhalten: leere Gruppe wird nicht gerendert).
  const missingGroups = schema.groups.filter((g) => {
    const visibleFields = Object.entries(g.fields).filter(([, def]) =>
      def.visibleIf ? def.visibleIf(cfg) : true,
    );
    if (visibleFields.length === 0) return false;
    return !html.includes(`data-group-id="${g.id}"`);
  });
  check(
    `SchemaForm "${schema.id}" rendert ohne Fehler + alle sichtbaren Gruppen`,
    noError && hasSchemaId && missingGroups.length === 0,
    noError
      ? hasSchemaId
        ? `Gruppen fehlen: ${missingGroups.map((g) => g.id).join(', ')}`
        : 'data-schema-id fehlt'
      : html,
  );
}

// ─── 3. visibleIf-Auswertung ───────────────────────────────────
section('3. visibleIf blendet Felder korrekt');

// Hero: backgroundImage + overlayOpacity sind nur sichtbar, wenn height === 'large'
const heroSmall = render(
  <SchemaForm
    schema={heroSchema}
    config={applyDefaults({ height: 'small' }, heroSchema)}
    onChange={() => {}}
  />,
);
check(
  'Hero mit height=small → Overlay-Deckkraft versteckt',
  !heroSmall.includes('Overlay-Deckkraft') && !heroSmall.includes('Hintergrundbild-URL'),
);

const heroLarge = render(
  <SchemaForm
    schema={heroSchema}
    config={applyDefaults({ height: 'large' }, heroSchema)}
    onChange={() => {}}
  />,
);
check(
  'Hero mit height=large → Overlay-Deckkraft sichtbar',
  heroLarge.includes('Overlay-Deckkraft') && heroLarge.includes('Hintergrundbild-URL'),
);

// ItemCard: Bild-Unterfelder nur sichtbar wenn showImages = true
const itemCardOff = render(
  <SchemaForm
    schema={itemCardSchema}
    config={applyDefaults({ showImages: false }, itemCardSchema)}
    onChange={() => {}}
  />,
);
const itemCardOn = render(
  <SchemaForm
    schema={itemCardSchema}
    config={applyDefaults({ showImages: true }, itemCardSchema)}
    onChange={() => {}}
  />,
);
// Annahme: imageShape/imageStyle haben visibleIf. Wir prüfen auf Längen-Delta.
check(
  'ItemCard mit showImages=false rendert weniger Felder als showImages=true',
  itemCardOff.length < itemCardOn.length,
  `off=${itemCardOff.length} on=${itemCardOn.length}`,
);

// ─── 4. Validation-Error im Output ─────────────────────────────
section('4. Ungültiger Config-Wert wird im Markup angezeigt');

// Bad color value in Farben-Schema
const badColorCfg = { pageBackground: 'rot' }; // ungültige Farbe
const farbenSchema = ALL_SCHEMAS.find((s) => s.id === 'farben')!;
const badHtml = render(
  <SchemaForm schema={farbenSchema} config={applyDefaults(badColorCfg, farbenSchema)} onChange={() => {}} />,
);
check(
  'Ungültige Farbe "rot" taucht im Validierungs-Panel auf',
  badHtml.includes('Validierungsfehler') && badHtml.includes('pageBackground'),
);

// Gute Config → kein Fehler-Panel
const goodHtml = render(
  <SchemaForm schema={farbenSchema} config={applyDefaults({}, farbenSchema)} onChange={() => {}} />,
);
check('Default-Config zeigt kein Fehler-Panel', !goodHtml.includes('Validierungsfehler'));

// ─── Summary ──────────────────────────────────────────────────
console.log(`\n━━ Zusammenfassung ━━`);
console.log(`  ${passed} passed, ${failed} failed`);
if (failed > 0) {
  console.log('\n  ✗ SchemaForm-Self-Test fehlgeschlagen.');
  process.exit(1);
}
console.log('\n  ✓ Alle SchemaForm-Tests grün.');
process.exit(0);
