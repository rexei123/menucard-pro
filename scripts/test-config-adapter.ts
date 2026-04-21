/**
 * Self-Test für den Config-Adapter (Sprint 3 Foundation).
 *
 * Aufruf:   npx tsx scripts/test-config-adapter.ts
 * Exit-Code: 0 bei Erfolg, 1 bei Fehler.
 *
 * Prüft:
 *   1. getByPath/setByPath auf verschachtelten Objekten
 *   2. splitFieldKey für Dot-Keys
 *   3. extractSchemaConfig aus Minimal-Template für jedes Schema
 *   4. Round-Trip: extract → merge → extract muss identisch sein
 *   5. Unbekannte Felder außerhalb des Schemas bleiben beim Merge unverändert
 */
import {
  getByPath,
  setByPath,
  splitFieldKey,
  extractSchemaConfig,
  mergeSchemaConfig,
  ALL_SCHEMAS,
  iconsBadgesSchema,
  farbenSchema,
  itemCardSchema,
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

function deepEqual(a: any, b: any): boolean {
  if (a === b) return true;
  if (typeof a !== typeof b) return false;
  if (a === null || b === null) return a === b;
  if (Array.isArray(a) !== Array.isArray(b)) return false;
  if (Array.isArray(a)) {
    if (a.length !== b.length) return false;
    return a.every((x, i) => deepEqual(x, b[i]));
  }
  if (typeof a === 'object') {
    const ka = Object.keys(a);
    const kb = Object.keys(b);
    if (ka.length !== kb.length) return false;
    return ka.every((k) => deepEqual(a[k], b[k]));
  }
  return false;
}

// ─── 1. Path-Helpers ─────────────────────────────────────────
section('1. Path-Helpers');

const sample = { digital: { products: { showImages: true, nested: { a: 1 } } } };
check('getByPath verschachtelt', getByPath(sample, ['digital', 'products', 'showImages']) === true);
check(
  'getByPath unbekannter Pfad → undefined',
  getByPath(sample, ['digital', 'unknown', 'x']) === undefined,
);
check('getByPath leerer Pfad → Objekt', getByPath(sample, []) === sample);

const updated = setByPath(sample, ['digital', 'products', 'showImages'], false);
check(
  'setByPath aktualisiert Wert immutabel',
  updated.digital.products.showImages === false && sample.digital.products.showImages === true,
);
check('setByPath behält Nachbar-Keys', updated.digital.products.nested.a === 1);

const created = setByPath({}, ['digital', 'new', 'flag'], true);
check('setByPath legt fehlende Zwischenobjekte an', created.digital.new.flag === true);

check('splitFieldKey zerlegt "icons.style"', JSON.stringify(splitFieldKey('icons.style')) === '["icons","style"]');
check('splitFieldKey ohne Punkt', JSON.stringify(splitFieldKey('showImages')) === '["showImages"]');

// ─── 2. extractSchemaConfig ──────────────────────────────────
section('2. extractSchemaConfig aus Minimal-Template');

const minimalCfg = minimalTemplate as any;
for (const schema of ALL_SCHEMAS) {
  let flat: Record<string, any>;
  try {
    flat = extractSchemaConfig(minimalCfg, schema);
  } catch (err: any) {
    check(`extractSchemaConfig "${schema.id}" läuft ohne Fehler`, false, err?.message || String(err));
    continue;
  }
  const keys = Object.keys(flat);
  const expectedKeys = schema.groups.flatMap((g) => Object.keys(g.fields));
  check(
    `extractSchemaConfig "${schema.id}" liefert alle ${expectedKeys.length} Feld-Keys`,
    expectedKeys.every((k) => keys.includes(k)),
    `fehlende Keys: ${expectedKeys.filter((k) => !keys.includes(k)).join(', ')}`,
  );
}

// Spezifischer Check: icons.style-Dot-Key wird korrekt aufgelöst
const iconsFlat = extractSchemaConfig(minimalCfg, iconsBadgesSchema);
check(
  'iconsBadges: icons.style wird aus digital.icons.style gelesen',
  iconsFlat['icons.style'] === minimalCfg.digital.icons.style,
);
check(
  'iconsBadges: badges.show wird aus digital.badges.show gelesen',
  Array.isArray(iconsFlat['badges.show']) && iconsFlat['badges.show'].length > 0,
);

// Spezifischer Check: farben/pageBackground
const farbenFlat = extractSchemaConfig(minimalCfg, farbenSchema);
check(
  'farben: pageBackground aus digital.colors.pageBackground',
  farbenFlat.pageBackground === '#FFFFFF',
);

// ─── 3. Round-Trip: extract → merge → extract ────────────────
section('3. Round-Trip extract → merge → extract');

for (const schema of ALL_SCHEMAS) {
  const flat1 = extractSchemaConfig(minimalCfg, schema);
  const merged = mergeSchemaConfig(minimalCfg, schema, flat1);
  const flat2 = extractSchemaConfig(merged, schema);
  check(
    `Round-Trip "${schema.id}" identisch`,
    deepEqual(flat1, flat2),
    `before: ${JSON.stringify(flat1).slice(0, 120)}\n    after:  ${JSON.stringify(flat2).slice(0, 120)}`,
  );
}

// ─── 4. Mergen ändert nur Schema-bekannte Felder ─────────────
section('4. Merge lässt unbekannte Felder unberührt');

const withExtraField = {
  ...minimalCfg,
  digital: {
    ...minimalCfg.digital,
    customField: 'X',
    products: {
      ...minimalCfg.digital.products,
      customProduct: 'Y',
    },
  },
};
const itemCardFlat = extractSchemaConfig(withExtraField, itemCardSchema);
itemCardFlat.showImages = true; // Feld ändern
const mergedWithExtra = mergeSchemaConfig(withExtraField, itemCardSchema, itemCardFlat);
check(
  'digital.customField bleibt nach Merge erhalten',
  mergedWithExtra.digital.customField === 'X',
);
check(
  'digital.products.customProduct bleibt erhalten',
  mergedWithExtra.digital.products.customProduct === 'Y',
);
check(
  'Schema-Feld wurde aktualisiert (showImages → true)',
  mergedWithExtra.digital.products.showImages === true,
);

// ─── 5. Merge mit leerem Basis-Config legt Struktur an ───────
section('5. Merge auf leerer Basis legt Pfad an');

const emptyConfig = {};
const seed: Record<string, any> = {
  'icons.style': 'filled',
  'badges.style': 'dot',
  'badges.show': ['recommendation'],
};
const seeded = mergeSchemaConfig(emptyConfig, iconsBadgesSchema, seed);
check(
  'Merge auf {} legt digital.icons.style an',
  seeded.digital.icons.style === 'filled',
);
check(
  'Merge auf {} legt digital.badges.show als Array an',
  Array.isArray(seeded.digital.badges.show) && seeded.digital.badges.show[0] === 'recommendation',
);

// ─── Summary ──────────────────────────────────────────────────
console.log(`\n━━ Zusammenfassung ━━`);
console.log(`  ${passed} passed, ${failed} failed`);
if (failed > 0) {
  console.log('\n  ✗ Config-Adapter-Self-Test fehlgeschlagen.');
  process.exit(1);
}
console.log('\n  ✓ Alle Config-Adapter-Tests grün.');
process.exit(0);
