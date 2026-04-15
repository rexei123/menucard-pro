// Playwright-Tests für die öffentliche Gästeansicht
// Lauft auf dem Server: node playwright-guest-tests.mjs
// Voraussetzung: npm install -g playwright && npx playwright install chromium

import { chromium } from 'playwright';
import fs from 'node:fs/promises';
import path from 'node:path';

const BASE = process.env.BASE_URL || 'https://menu.hotel-sonnblick.at';
const OUT = '/tmp/playwright-guest-tests';
const REPORT = '/tmp/playwright-report.md';

const VIEWPORTS = [
  { name: 'desktop', width: 1440, height: 900 },
  { name: 'tablet',  width: 768,  height: 1024 },
  { name: 'mobile',  width: 375,  height: 667 },
];

const KARTEN = [
  { slug: 'restaurant/jaegerabend',           name: 'Jägerabend' },
  { slug: 'restaurant/italienischer-abend',   name: 'Italienischer Abend' },
  { slug: 'restaurant/heimatabend',           name: 'Heimatabend' },
  { slug: 'restaurant/amerikanischer-abend',  name: 'Amerikanischer Abend' },
  { slug: 'restaurant/gala-abend',            name: 'Gala Abend' },
  { slug: 'restaurant/schnitzel-abend',       name: 'Schnitzel Abend' },
  { slug: 'restaurant/oesterreichischer-abend', name: 'Österreichischer Abend' },
  { slug: 'restaurant/weinkarte',             name: 'Weinkarte' },
  { slug: 'bar/barkarte',                     name: 'Barkarte' },
];

const findings = [];
const ok = [];

function fail(area, msg) {
  findings.push({ area, msg });
  console.log(`  ❌ ${area}: ${msg}`);
}
function pass(area, msg) {
  ok.push({ area, msg });
  console.log(`  ✅ ${area}: ${msg}`);
}

await fs.mkdir(OUT, { recursive: true });
await fs.mkdir(path.join(OUT, 'screenshots'), { recursive: true });

const browser = await chromium.launch({ headless: true });

console.log(`\n=== Test gegen ${BASE} ===\n`);

// 1. Startseite
{
  console.log('## Startseite');
  const ctx = await browser.newContext({ viewport: VIEWPORTS[0] });
  const page = await ctx.newPage();
  const resp = await page.goto(BASE, { waitUntil: 'networkidle' });
  resp?.status() === 200 ? pass('Startseite', 'HTTP 200') : fail('Startseite', `HTTP ${resp?.status()}`);
  const body = await page.textContent('body');
  if (/Getraenke|fuer/i.test(body)) {
    fail('Startseite', 'Umlaute fehlen ("Getraenke" / "fuer")');
  } else {
    pass('Startseite', 'Umlaute korrekt');
  }
  await page.screenshot({ path: path.join(OUT, 'screenshots', '00-startseite.png'), fullPage: true });
  await ctx.close();
}

// 2. Standortwahl
{
  console.log('\n## Standortauswahl');
  const ctx = await browser.newContext({ viewport: VIEWPORTS[0] });
  const page = await ctx.newPage();
  const resp = await page.goto(`${BASE}/hotel-sonnblick`, { waitUntil: 'networkidle' });
  resp?.status() === 200 ? pass('Standorte', 'HTTP 200') : fail('Standorte', `HTTP ${resp?.status()}`);
  const text = await page.textContent('body');
  if (/1 Karten\b/.test(text)) fail('Standorte', 'Plural-Fehler "1 Karten" statt "1 Karte"');
  await page.screenshot({ path: path.join(OUT, 'screenshots', '01-standorte.png'), fullPage: true });
  await ctx.close();
}

// 3. Restaurant-Übersicht
{
  console.log('\n## Restaurant-Übersicht');
  const ctx = await browser.newContext({ viewport: VIEWPORTS[0] });
  const page = await ctx.newPage();
  await page.goto(`${BASE}/hotel-sonnblick/restaurant`, { waitUntil: 'networkidle' });
  const text = await page.textContent('body');
  // Mix Punkt/Komma im Preisformat
  const punkt = (text.match(/€\s?\d+\.\d{2}/g) || []).length;
  const komma = (text.match(/€\s?\d+,\d{2}/g) || []).length;
  if (punkt > 0 && komma > 0) {
    fail('Restaurant-Index', `Preisformat gemischt: ${punkt}× Punkt, ${komma}× Komma`);
  } else if (punkt > 0) {
    fail('Restaurant-Index', `${punkt} Preise mit Punkt (DE sollte Komma sein)`);
  } else {
    pass('Restaurant-Index', `Alle ${komma} Preise mit Komma`);
  }
  await page.screenshot({ path: path.join(OUT, 'screenshots', '02-restaurant.png'), fullPage: true });
  await ctx.close();
}

// 4. Alle 9 Karten – Screenshots in 3 Viewports + Inhaltsprüfung
console.log('\n## Karten (alle 9, alle Viewports)');
for (const k of KARTEN) {
  console.log(`\n### ${k.name}`);
  for (const vp of VIEWPORTS) {
    const ctx = await browser.newContext({ viewport: { width: vp.width, height: vp.height } });
    const page = await ctx.newPage();
    const url = `${BASE}/hotel-sonnblick/${k.slug}`;
    const start = Date.now();
    const resp = await page.goto(url, { waitUntil: 'networkidle' });
    const ms = Date.now() - start;
    const fileBase = `${k.slug.replace(/\//g, '_')}__${vp.name}.png`;
    if (resp?.status() !== 200) {
      fail(`${k.name}/${vp.name}`, `HTTP ${resp?.status()} (${url})`);
      await ctx.close();
      continue;
    }
    pass(`${k.name}/${vp.name}`, `HTTP 200 in ${ms}ms`);
    if (ms > 2000) fail(`${k.name}/${vp.name}`, `Lade über 2s (${ms}ms)`);
    await page.screenshot({ path: path.join(OUT, 'screenshots', fileBase), fullPage: true });
    // Horizontale Scrollbar?
    const hasHScroll = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth);
    if (hasHScroll) fail(`${k.name}/${vp.name}`, 'horizontale Scrollbar vorhanden');
    await ctx.close();
  }
}

// 5. Sprachwechsel DE → EN
{
  console.log('\n## Sprachwechsel');
  const ctx = await browser.newContext({ viewport: VIEWPORTS[0] });
  const page = await ctx.newPage();
  await page.goto(`${BASE}/hotel-sonnblick/restaurant/jaegerabend?lang=en`, { waitUntil: 'networkidle' });
  const title = await page.textContent('h1');
  if (title?.includes('Hunter')) {
    pass('Sprache', `EN-Titel "${title.trim()}"`);
  } else {
    fail('Sprache', `EN-Titel unerwartet: "${title?.trim()}"`);
  }
  await page.screenshot({ path: path.join(OUT, 'screenshots', '03-en.png'), fullPage: true });
  await ctx.close();
}

// 6. Suche – cocktail darf 0 sein, veuve muss 1+ liefern
{
  console.log('\n## Suchfunktion');
  const ctx = await browser.newContext({ viewport: VIEWPORTS[0] });
  const page = await ctx.newPage();
  await page.goto(`${BASE}/hotel-sonnblick/bar/barkarte`, { waitUntil: 'networkidle' });
  const search = page.locator('input[placeholder*="uche"]').first();

  await search.fill('veuve');
  await page.waitForTimeout(500);
  const txt1 = await page.textContent('body');
  const m1 = txt1.match(/(\d+)\s*\/\s*\d+\s*Ergebnisse/);
  if (m1 && parseInt(m1[1]) >= 1) {
    pass('Suche', `"veuve" → ${m1[0]}`);
  } else {
    fail('Suche', `"veuve" → keine Treffer/Counter sichtbar`);
  }

  await search.fill('cocktail');
  await page.waitForTimeout(500);
  const txt2 = await page.textContent('body');
  const m2 = txt2.match(/(\d+)\s*\/\s*\d+\s*Ergebnisse/);
  if (m2 && parseInt(m2[1]) === 0) {
    fail('Suche', `"cocktail" → 0 Treffer (Kategorienamen werden nicht durchsucht)`);
  } else if (m2) {
    pass('Suche', `"cocktail" → ${m2[0]}`);
  }
  await ctx.close();
}

// 7. PDF-Endpunkt direkt testen (umgeht Browser)
{
  console.log('\n## PDF-Generierung (alle 9 Karten)');
  const ctx = await browser.newContext({ viewport: VIEWPORTS[0] });
  const page = await ctx.newPage();
  await page.goto(`${BASE}/hotel-sonnblick`, { waitUntil: 'domcontentloaded' });

  // Menu-IDs aus interner API holen ist nicht öffentlich — wir testen über Slugs
  // Hier nehmen wir die Menu-IDs aus einem vorherigen DB-Lookup oder akzeptieren manuelle Eingabe via ENV
  const ids = (process.env.MENU_IDS || '').split(',').filter(Boolean);
  if (ids.length === 0) {
    console.log('  ⏭ MENU_IDS env nicht gesetzt → PDF-Test übersprungen (extern bereits geprüft)');
  } else {
    for (const id of ids) {
      const r = await page.request.get(`${BASE}/api/v1/menus/${id}/pdf`);
      const ct = r.headers()['content-type'] || '';
      if (r.status() === 200 && ct.includes('pdf')) {
        pass(`PDF/${id}`, `200 ${ct}`);
      } else {
        fail(`PDF/${id}`, `${r.status()} ${ct}`);
      }
    }
  }
  await ctx.close();
}

await browser.close();

// Report schreiben
const lines = [];
lines.push('# Playwright-Auto-Test-Report');
lines.push(`\n**Datum:** ${new Date().toISOString()}`);
lines.push(`**Base-URL:** ${BASE}`);
lines.push(`\n## Zusammenfassung\n`);
lines.push(`- ✅ ${ok.length} Tests bestanden`);
lines.push(`- ❌ ${findings.length} Befunde`);
lines.push(`\n## Befunde\n`);
if (findings.length === 0) {
  lines.push('Keine Befunde — alles grün.');
} else {
  for (const f of findings) lines.push(`- **${f.area}** — ${f.msg}`);
}
lines.push('\n## Bestandene Tests\n');
for (const o of ok) lines.push(`- ${o.area} — ${o.msg}`);
lines.push(`\n## Screenshots\n`);
lines.push(`Alle Screenshots unter \`${OUT}/screenshots/\` (9 Karten × 3 Viewports + Sonderseiten).`);

await fs.writeFile(REPORT, lines.join('\n'));
console.log(`\n=== Report: ${REPORT} ===`);
console.log(`=== Screenshots: ${OUT}/screenshots/ ===`);
console.log(`\nErgebnis: ${ok.length} OK, ${findings.length} Befunde\n`);
process.exit(findings.length > 0 ? 1 : 0);
