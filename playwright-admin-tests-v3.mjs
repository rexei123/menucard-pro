#!/usr/bin/env node
/**
 * MenuCard Pro — Admin Smoke-Tests v3 (14.04.2026)
 * v3: Produkt- und Design-Editor via direkte URL (IDs aus ENV)
 */
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const BASE  = process.env.BASE_URL || 'https://menu.hotel-sonnblick.at';
const EMAIL = process.env.ADMIN_EMAIL || 'admin@hotel-sonnblick.at';
const PASS  = process.env.ADMIN_PASS  || 'Sonnblick2026!';
const PRODUCT_ID = process.env.PRODUCT_ID || '';
const MENU_ID    = process.env.MENU_ID    || '';
const OUT   = '/tmp/playwright-admin-tests';
fs.mkdirSync(path.join(OUT, 'screenshots'), { recursive: true });

const report = { ok: [], fail: [], consoleErrors: [] };
const pass = (n, d='') => { report.ok.push(`${n}${d?` — ${d}`:''}`); console.log(`  ✅ ${n} ${d}`); };
const fail = (n, d='') => { report.fail.push(`${n} — ${d}`); console.log(`  ❌ ${n} — ${d}`); };

const browser = await chromium.launch({ headless: true });
const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
const page = await ctx.newPage();

const consoleErrors = [];
page.on('pageerror', err => consoleErrors.push(`[pageerror] ${err.message}`));
page.on('console', msg => { if (msg.type() === 'error') consoleErrors.push(`[console.error] ${msg.text().slice(0, 200)}`); });

async function shot(name) {
  await page.screenshot({ path: path.join(OUT, 'screenshots', `${name}.png`), fullPage: true });
}

// === Login ===
console.log('## Login v3');
await page.goto(`${BASE}/auth/login`, { waitUntil: 'domcontentloaded' });
await shot('00-login-page');
await page.locator('input[type="email"]').first().fill(EMAIL);
await page.locator('input[type="password"]').first().fill(PASS);
try {
  await Promise.all([
    page.waitForURL(/\/admin/, { timeout: 20000 }),
    page.locator('button[type="submit"]').first().click(),
  ]);
  pass('Login', `→ ${new URL(page.url()).pathname}`);
  await shot('01-post-login');
} catch (e) {
  fail('Login', e.message.slice(0, 120));
  await shot('01-login-failed');
  await browser.close();
  process.exit(1);
}

async function visit(name, pathname) {
  consoleErrors.length = 0;
  const t0 = Date.now();
  try {
    const resp = await page.goto(`${BASE}${pathname}`, { waitUntil: 'networkidle', timeout: 20000 });
    const ms = Date.now() - t0;
    if (resp?.status() !== 200) { fail(name, `HTTP ${resp?.status()}`); return; }
    if (page.url().includes('/auth/login')) { fail(name, 'Auth-Redirect'); return; }
    pass(name, `${ms}ms`);
    if (consoleErrors.length) report.consoleErrors.push({ name, errors: [...consoleErrors] });
    await shot(name.replace(/[^a-z0-9]+/gi,'-').toLowerCase());
  } catch (e) { fail(name, e.message.slice(0, 120)); }
}

console.log('\n## Admin-Screens');
for (const s of [
  ['Admin Dashboard',        '/admin'],
  ['Admin Menüs',            '/admin/menus'],
  ['Admin Produkte',         '/admin/products'],
  ['Admin Design-Übersicht', '/admin/design'],
  ['Admin QR-Codes',         '/admin/qr-codes'],
  ['Admin CSV-Import',       '/admin/import'],
  ['Admin Bildarchiv',       '/admin/media'],
  ['Admin PDF-Creator',      '/admin/pdf-creator'],
  ['Admin Einstellungen',    '/admin/settings'],
]) await visit(s[0], s[1]);

// === Editor-Seiten ===
console.log('\n## Editor-Seiten (via ID aus DB)');

if (PRODUCT_ID) {
  await visit('Produkt-Editor',    `/admin/products/${PRODUCT_ID}`);
} else {
  console.log('  ⏭  PRODUCT_ID env nicht gesetzt');
}

if (MENU_ID) {
  await visit('Karten-Editor',     `/admin/menus/${MENU_ID}`);
  await visit('Design-Editor',     `/admin/menus/${MENU_ID}/design`);
} else {
  console.log('  ⏭  MENU_ID env nicht gesetzt');
}

// === Gäste-Screenshots (Vergleich nach Fix-Runde) ===
console.log('\n## Gäste-Karten (Vergleichs-Screenshots)');
await ctx.clearCookies();
for (const slug of [
  'restaurant/jaegerabend', 'restaurant/italienischer-abend', 'restaurant/heimatabend',
  'restaurant/amerikanischer-abend', 'restaurant/gala-abend', 'restaurant/schnitzel-abend',
  'restaurant/oesterreichischer-abend', 'restaurant/weinkarte', 'bar/barkarte',
]) await visit(`Gast ${slug.split('/')[1]}`, `/hotel-sonnblick/${slug}`);

// === Report ===
const md = ['# Playwright-Admin-Report v3',
  `**Datum:** ${new Date().toISOString()}`,
  `**Base-URL:** ${BASE}`, '',
  '## Zusammenfassung',
  `- ✅ ${report.ok.length} Tests bestanden`,
  `- ❌ ${report.fail.length} Befunde`,
  `- ⚠️ ${report.consoleErrors.length} Screens mit Console-Errors`, ''];

if (report.fail.length) {
  md.push('## Befunde');
  report.fail.forEach(f => md.push(`- **${f}**`));
  md.push('');
}
if (report.consoleErrors.length) {
  md.push('## Console-/JS-Fehler');
  report.consoleErrors.forEach(c => {
    md.push(`### ${c.name}`);
    c.errors.slice(0, 5).forEach(e => md.push(`- \`${e}\``));
  });
  md.push('');
}
md.push('## Bestanden');
report.ok.forEach(o => md.push(`- ${o}`));

fs.writeFileSync('/tmp/playwright-admin-report.md', md.join('\n'));
console.log('\n=== Report: /tmp/playwright-admin-report.md ===');
console.log(`Ergebnis: ${report.ok.length} OK, ${report.fail.length} Befunde, ${report.consoleErrors.length} mit Errors`);
await browser.close();
