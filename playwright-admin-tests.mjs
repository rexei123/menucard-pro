#!/usr/bin/env node
/**
 * MenuCard Pro — Admin Smoke-Tests (14.04.2026)
 * Testet Login + alle wichtigen Admin-Screens per Playwright.
 * Output: /tmp/playwright-admin-tests/screenshots + /tmp/playwright-admin-report.md
 *
 * Ausführung auf Server:
 *   cd /tmp && \
 *   BASE_URL=https://menu.hotel-sonnblick.at \
 *   ADMIN_EMAIL=admin@hotel-sonnblick.at \
 *   ADMIN_PASS='Sonnblick2026!' \
 *   node playwright-admin-tests.mjs
 */
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const BASE = process.env.BASE_URL || 'https://menu.hotel-sonnblick.at';
const EMAIL = process.env.ADMIN_EMAIL || 'admin@hotel-sonnblick.at';
const PASS  = process.env.ADMIN_PASS  || 'Sonnblick2026!';
const OUT   = '/tmp/playwright-admin-tests';
fs.mkdirSync(path.join(OUT, 'screenshots'), { recursive: true });

const report = { ok: [], fail: [], consoleErrors: [] };
const pass = (name, detail = '') => { report.ok.push(`${name}${detail ? ` — ${detail}` : ''}`); console.log(`  ✅ ${name} ${detail}`); };
const fail = (name, detail = '') => { report.fail.push(`${name} — ${detail}`); console.log(`  ❌ ${name} — ${detail}`); };

const browser = await chromium.launch({ headless: true });
const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
const page = await ctx.newPage();

// Console-Errors sammeln pro Screen
const consoleErrors = [];
page.on('pageerror', err => consoleErrors.push(`[pageerror] ${err.message}`));
page.on('console', msg => { if (msg.type() === 'error') consoleErrors.push(`[console.error] ${msg.text().slice(0, 200)}`); });

async function screenshot(name) {
  await page.screenshot({ path: path.join(OUT, 'screenshots', `${name}.png`), fullPage: true });
}

async function visit(name, pathname, check) {
  consoleErrors.length = 0;
  const url = `${BASE}${pathname}`;
  const t0 = Date.now();
  try {
    const resp = await page.goto(url, { waitUntil: 'networkidle', timeout: 15000 });
    const ms = Date.now() - t0;
    const status = resp?.status();
    if (status !== 200) {
      fail(name, `HTTP ${status} für ${pathname}`);
      await screenshot(name.replace(/[^a-z0-9]+/gi, '-').toLowerCase());
      return false;
    }
    if (check) {
      const ok = await check(page);
      if (!ok) {
        fail(name, `Check nicht bestanden (${ms}ms)`);
        await screenshot(name.replace(/[^a-z0-9]+/gi, '-').toLowerCase());
        return false;
      }
    }
    pass(name, `${ms}ms`);
    if (consoleErrors.length > 0) {
      report.consoleErrors.push({ name, errors: [...consoleErrors] });
    }
    await screenshot(name.replace(/[^a-z0-9]+/gi, '-').toLowerCase());
    return true;
  } catch (e) {
    fail(name, `Exception: ${e.message.slice(0, 120)}`);
    try { await screenshot(name.replace(/[^a-z0-9]+/gi, '-').toLowerCase()); } catch {}
    return false;
  }
}

// === LOGIN ===
console.log('## Login');
await page.goto(`${BASE}/auth/login`, { waitUntil: 'networkidle' });
await screenshot('00-login-page');

const emailInput = await page.locator('input[type="email"], input[name*="email" i], input[placeholder*="mail" i]').first();
const passInput  = await page.locator('input[type="password"], input[name*="pass" i]').first();
if (!(await emailInput.count()) || !(await passInput.count())) {
  fail('Login-Formular', 'Email- oder Passwort-Feld nicht gefunden');
} else {
  await emailInput.fill(EMAIL);
  await passInput.fill(PASS);
  const submitBtn = page.locator('button[type="submit"], button:has-text("Anmelden"), button:has-text("Login"), button:has-text("Sign in")').first();
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'networkidle', timeout: 15000 }).catch(() => null),
    submitBtn.click(),
  ]);
  const currentUrl = page.url();
  if (currentUrl.includes('/admin') || currentUrl.includes('/dashboard')) {
    pass('Login', `redirect → ${new URL(currentUrl).pathname}`);
    await screenshot('01-post-login');
  } else {
    fail('Login', `kein Redirect in Admin-Bereich, URL=${currentUrl}`);
  }
}

// === ADMIN-SCREENS ===
console.log('\n## Admin-Screens');

const SCREENS = [
  { name: 'Admin Dashboard',       path: '/admin' },
  { name: 'Admin Menüs',           path: '/admin/menus' },
  { name: 'Admin Produkte',        path: '/admin/products' },
  { name: 'Admin Design-Übersicht', path: '/admin/design' },
  { name: 'Admin QR-Codes',        path: '/admin/qr-codes' },
  { name: 'Admin CSV-Import',      path: '/admin/import' },
  { name: 'Admin Bildarchiv',      path: '/admin/media' },
  { name: 'Admin PDF-Creator',     path: '/admin/pdf-creator' },
  { name: 'Admin Einstellungen',   path: '/admin/settings' },
];

for (const s of SCREENS) {
  await visit(s.name, s.path);
}

// === PRODUKT-EDITOR (ersten Eintrag) ===
console.log('\n## Produkt-Editor');
try {
  await page.goto(`${BASE}/admin/products`, { waitUntil: 'networkidle' });
  const firstProductLink = page.locator('a[href^="/admin/products/"]').first();
  if (await firstProductLink.count()) {
    const href = await firstProductLink.getAttribute('href');
    await visit('Produkt-Editor (erstes Produkt)', href);
  } else {
    fail('Produkt-Editor', 'Kein Produkt-Link gefunden');
  }
} catch (e) {
  fail('Produkt-Editor', e.message);
}

// === DESIGN-EDITOR (ersten Eintrag) ===
console.log('\n## Design-Editor');
try {
  await page.goto(`${BASE}/admin/design`, { waitUntil: 'networkidle' });
  const firstDesignLink = page.locator('a[href*="/design"]').first();
  if (await firstDesignLink.count()) {
    const href = await firstDesignLink.getAttribute('href');
    if (href && href !== '/admin/design') {
      await visit('Design-Editor (erste Karte)', href);
    }
  }
} catch (e) {
  fail('Design-Editor', e.message);
}

// === GÄSTE-TEMPLATES (alle 4 via query-param falls möglich) ===
console.log('\n## Gäste-Templates');
// Jede Karte hat ein Template im designConfig — wir machen nur Screenshots der 9 Karten,
// um visuellen Vergleich zu ermöglichen.
const CARDS = [
  'restaurant/jaegerabend',
  'restaurant/italienischer-abend',
  'restaurant/heimatabend',
  'restaurant/amerikanischer-abend',
  'restaurant/gala-abend',
  'restaurant/schnitzel-abend',
  'restaurant/oesterreichischer-abend',
  'restaurant/weinkarte',
  'bar/barkarte',
];
await page.context().clearCookies();  // Als Gast
for (const slug of CARDS) {
  const name = slug.split('/').pop();
  await visit(`Gast-Karte ${name}`, `/hotel-sonnblick/${slug}`);
}

// === REPORT ===
const md = [];
md.push('# Playwright-Admin-Report');
md.push(`**Datum:** ${new Date().toISOString()}`);
md.push(`**Base-URL:** ${BASE}`);
md.push('');
md.push('## Zusammenfassung');
md.push(`- ✅ ${report.ok.length} Tests bestanden`);
md.push(`- ❌ ${report.fail.length} Befunde`);
md.push(`- ⚠️ ${report.consoleErrors.length} Screens mit Console-Errors`);
md.push('');
if (report.fail.length) {
  md.push('## Befunde');
  report.fail.forEach(f => md.push(`- **${f}**`));
  md.push('');
}
if (report.consoleErrors.length) {
  md.push('## Console-/JS-Fehler');
  report.consoleErrors.forEach(c => {
    md.push(`### ${c.name}`);
    c.errors.slice(0, 3).forEach(e => md.push(`- \`${e}\``));
  });
  md.push('');
}
md.push('## Bestanden');
report.ok.forEach(o => md.push(`- ${o}`));

fs.writeFileSync('/tmp/playwright-admin-report.md', md.join('\n'));
console.log('\n=== Report: /tmp/playwright-admin-report.md ===');
console.log(`=== Screenshots: ${OUT}/screenshots/ ===`);
console.log(`Ergebnis: ${report.ok.length} OK, ${report.fail.length} Befunde, ${report.consoleErrors.length} Screens mit Console-Errors`);

await browser.close();
