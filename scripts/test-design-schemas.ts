/**
 * Self-Test für das Schema-System (Sprint 1 Abschluss-Check).
 *
 * Aufruf:   npx tsx scripts/test-design-schemas.ts
 * Exit-Code: 0 bei Erfolg, 1 bei Fehler.
 *
 * Prüft:
 *  1. Alle 11 Schemas (8 Komponenten + 3 globale) laden fehlerfrei.
 *  2. Validator akzeptiert gültige Defaults.
 *  3. Validator fängt typische Fehleingaben (Farbe, Enum, Wertebereich).
 *  4. applyDefaults füllt fehlende Felder korrekt.
 *  5. Minimal-Config aus src/lib/design-templates/minimal.ts wird gültig validiert.
 */
import {
  ALL_SCHEMAS,
  COMPONENT_SCHEMAS,
  GLOBAL_SCHEMAS,
  itemCardSchema,
  heroSchema,
  footerSchema,
  validateSchema,
  validateField,
  applyDefaults,
  getSchemaById,
  isKnownFont,
} from '../src/lib/design-templates/schemas';
import { minimalTemplate } from '../src/lib/design-templates/minimal';

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

// ─── 1. Schema-Struktur ────────────────────────────────────────
section('1. Schema-Struktur');
check('6 Komponenten-Schemas geladen (Wine+Beverage sind Sub-Gruppen von ItemCard)', COMPONENT_SCHEMAS.length === 6, `got ${COMPONENT_SCHEMAS.length}`);
check('5 globale Schemas geladen', GLOBAL_SCHEMAS.length === 5, `got ${GLOBAL_SCHEMAS.length}`);
check('ALL_SCHEMAS hat 11 Einträge', ALL_SCHEMAS.length === 11, `got ${ALL_SCHEMAS.length}`);

for (const s of ALL_SCHEMAS) {
  check(`Schema "${s.id}" hat Label`, typeof s.label === 'string' && s.label.length > 0);
  check(`Schema "${s.id}" hat configPath`, Array.isArray(s.configPath) && s.configPath.length > 0);
  check(`Schema "${s.id}" hat mindestens 1 Gruppe`, Array.isArray(s.groups) && s.groups.length >= 1);
  for (const g of s.groups) {
    check(`Gruppe "${s.id}/${g.id}" hat Felder`, Object.keys(g.fields).length >= 1);
  }
}

check('getSchemaById("item-card") findet Schema', getSchemaById('item-card')?.id === 'item-card');
check('getSchemaById("unbekannt") liefert undefined', getSchemaById('unbekannt') === undefined);

// ─── 2. Validator — gültige Defaults ──────────────────────────
section('2. Validator akzeptiert Defaults');
for (const s of ALL_SCHEMAS) {
  const cfg: Record<string, any> = {};
  for (const g of s.groups) {
    for (const [k, def] of Object.entries(g.fields)) {
      cfg[k] = def.default;
    }
  }
  const res = validateSchema(cfg, s);
  check(`Defaults für "${s.id}" sind valide`, res.valid, res.errors.map((e) => `${e.field}: ${e.message}`).join('; '));
}

// ─── 3. Validator — Fehlereingabe fangen ───────────────────────
section('3. Validator fängt Fehleingaben');

// Color: Kein HEX
check(
  'Color-Feld weist "rot" ab',
  validateField('rot', { type: 'color', label: 'X', default: '#000000' }, 'x', 'test').length === 1,
);

// Color: falsche Länge
check(
  'Color-Feld weist "#F00" ab (nur 3 Zeichen)',
  validateField('#F00', { type: 'color', label: 'X', default: '#000000' }, 'x', 'test').length === 1,
);

// Color: Alpha nur mit allowAlpha
check(
  'Color-Feld weist "#FF0000AA" ohne allowAlpha ab',
  validateField('#FF0000AA', { type: 'color', label: 'X', default: '#000000' }, 'x', 'test').length === 1,
);
check(
  'Color-Feld akzeptiert "#FF0000AA" mit allowAlpha',
  validateField('#FF0000AA', { type: 'color', label: 'X', default: '#000000', allowAlpha: true }, 'x', 'test').length === 0,
);

// Select: unbekannter Wert
check(
  'Select-Feld weist unbekannten Wert ab',
  validateField('xyz', {
    type: 'select',
    label: 'X',
    default: 'a',
    options: [{ label: 'A', value: 'a' }, { label: 'B', value: 'b' }],
  }, 'x', 'test').length === 1,
);

// Slider: außerhalb Wertebereich
check(
  'Slider weist Wert unter min ab',
  validateField(-5, { type: 'slider', label: 'X', min: 0, max: 100, default: 50 }, 'x', 'test').length === 1,
);
check(
  'Slider weist Wert über max ab',
  validateField(200, { type: 'slider', label: 'X', min: 0, max: 100, default: 50 }, 'x', 'test').length === 1,
);

// Font: unbekannte Schrift
check(
  'Font-Feld weist unbekannte Schrift ab',
  validateField('Comic Sans', { type: 'font', label: 'X', default: 'Inter' }, 'x', 'test').length === 1,
);
check(
  'Font-Feld akzeptiert "Inter"',
  validateField('Inter', { type: 'font', label: 'X', default: 'Inter' }, 'x', 'test').length === 0,
);

// MultiToggle: unbekannter Eintrag
check(
  'MultiToggle weist unbekannten Eintrag ab',
  validateField(['winery', 'xyz'], {
    type: 'multitoggle',
    label: 'X',
    default: [],
    options: [{ label: 'Winery', value: 'winery' }, { label: 'Vintage', value: 'vintage' }],
  }, 'x', 'test').length === 1,
);

// Boolean: string statt boolean
check(
  'Boolean-Feld weist "true" (string) ab',
  validateField('true', { type: 'boolean', label: 'X', default: false }, 'x', 'test').length === 1,
);

// ─── 4. applyDefaults ──────────────────────────────────────────
section('4. applyDefaults füllt fehlende Felder');
const partial = { show: false } as any;
const withDefaults = applyDefaults(partial, footerSchema);
check('show bleibt false', withDefaults.show === false);
check('text wird auf "" aufgefüllt', withDefaults.text === '');
check('showAllergenNote wird auf true aufgefüllt', withDefaults.showAllergenNote === true);

// ─── 5. Hero-Schema mit visibleIf ─────────────────────────────
section('5. Hero-Schema inkl. visibleIf-Felder');
const heroCfg = { height: 'small', logoPosition: 'center', logoSize: 80, title: '', subtitle: '', logo: '', backgroundImage: '', overlayOpacity: 60 };
const heroRes = validateSchema(heroCfg, heroSchema);
check('Hero small-Height ist valide', heroRes.valid, heroRes.errors.map((e) => e.message).join('; '));

const heroLarge = { ...heroCfg, height: 'large', backgroundImage: '/uploads/x.jpg' };
const heroLargeRes = validateSchema(heroLarge, heroSchema);
check('Hero large-Height ist valide', heroLargeRes.valid);

// ─── 6. Minimal-Template gegen Schemas validieren ─────────────
section('6. Minimal-Template ist schema-konform');

const digital = minimalTemplate.digital as any;

// Hero (header)
const heroMinimal = {
  height: digital.header.height,
  logoPosition: digital.header.logoPosition,
  logoSize: digital.header.logoSize,
  title: digital.header.title || '',
  subtitle: digital.header.subtitle || '',
  logo: digital.header.logo || '',
  backgroundImage: digital.header.backgroundImage || '',
  overlayOpacity: Math.round((digital.header.overlayOpacity || 0) * 100),
};
const heroMinRes = validateSchema(heroMinimal, heroSchema);
check('Minimal-Header ist schema-valide', heroMinRes.valid, heroMinRes.errors.map((e) => `${e.field}: ${e.message}`).join('; '));

// ItemCard (products)
const itemCardMinimal = {
  showImages: digital.products.showImages,
  imageStyle: digital.products.imageStyle,
  imageShape: digital.products.imageShape,
  imageSize: digital.products.imageSize,
  imagePosition: digital.products.imagePosition,
  showShortDesc: digital.products.showShortDesc,
  showLongDesc: digital.products.showLongDesc,
  descMaxLines: digital.products.descMaxLines,
  pricePosition: digital.products.pricePosition,
  showAllPrices: digital.products.showAllPrices,
  showFillQuantity: digital.products.showFillQuantity,
  wineDetails: digital.products.wineDetails,
  wineDetailPosition: digital.products.wineDetailPosition,
  drinkDetails: digital.products.drinkDetails,
};
const icMinRes = validateSchema(itemCardMinimal, itemCardSchema);
check('Minimal-ItemCard ist schema-valide', icMinRes.valid, icMinRes.errors.map((e) => `${e.field}: ${e.message}`).join('; '));

// Footer
const footerMinimal = {
  show: digital.footer.show,
  text: digital.footer.text,
  showAllergenNote: digital.footer.showAllergenNote,
  showPriceNote: digital.footer.showPriceNote,
  align: 'center',
  linkImprint: '',
  linkPrivacy: '',
};
const fMinRes = validateSchema(footerMinimal, footerSchema);
check('Minimal-Footer ist schema-valide', fMinRes.valid, fMinRes.errors.map((e) => `${e.field}: ${e.message}`).join('; '));

// ─── Summary ──────────────────────────────────────────────────
console.log(`\n━━ Zusammenfassung ━━`);
console.log(`  ${passed} passed, ${failed} failed`);
if (failed > 0) {
  console.log('\n  ✗ Schema-Self-Test fehlgeschlagen.');
  process.exit(1);
}
console.log('\n  ✓ Alle Schema-Tests grün.');
process.exit(0);
