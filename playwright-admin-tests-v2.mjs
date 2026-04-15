#!/usr/bin/env node
/**
 * MenuCard Pro — Admin Smoke-Tests v2 (14.04.2026)
 * Robuster Login-Flow: NextAuth credentials → wartet auf URL-Wechsel
 * und Cookie-Set, nicht auf navigation.
 */
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const BASE  = process.env.BASE_URL || 'https://menu.hotel-sonnblick.at';
const EMAIL = process.env.ADMIN_EMAIL || 'admin@hotel-sonnblick.at';
const PASS  = process.env.ADMIN_PASS  || 'Sonnblick2026!';
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

// === LOGIN v2 ===
console.log('## Login v2');
await page.goto(`${BASE}/auth/login`, { waitUntil: 'domcontentloaded' });
await shot('00-login-page');

// Felder füllen
await page.locator('input[type="email"]').first().fill(EMAIL);
await page.locator('input[type="password"]').first().fill(PASS);

// Submit + warten bis /admin (oder Dashboard) tatsächlich aktiv ist
try {
  await Promise.all([
    page.waitForURL(/\/admin/, { timeout: 20000 }),
    page.locator('button[type="submit"]').first().click(),
  ]);
  // Cookie-Check
  const cookies = await ctx.cookies();
  const sessionCookie = cookies.find(c =>
    c.name.includes('session-token') || c.name.includes('next-auth.session-token')
  );
  if (sessionCookie) {
    pass('Login', `Session-Cookie gesetzt, URL=${new URL(page.url()).pathname}`);
  } else {
    fail('Login', 'Kein Session-Cookie gefunden');
  }
  await shot('01-post-login');
} catch (e) {
  fail('Login', `Timeout / kein Admin-Redirect: ${e.message.slice(0, 120)}`);
  await shot('01-login-failed');
  console.log('\n⚠️  Login fehlgeschlagen — Admin-Screens werden übersprungen.');
  console.log('   URL nach Login-Versuch:', page.url());

  // Error-Text im Form suchen
  const errorText = await page.locator('[class*="error"], [class*="alert"], [role="alert"]').allTextContents().catch(() => []);
  if (errorText.length > 0) {
    console.log('   Fehlermeldungen:', errorText.join(' | '));
  }
  // Report schreiben und raus
  fs.writeFileSync('/tmp/playwright-admin-report.md',
    `# Admin-Test v2 Report\n\nLogin fehlgeschlagen: ${e.message}\n\nBitte Screenshot 01-login-failed.png prüfen.\n`);
  await browser.close();
  process.exit(1);
}

// === Auth-Verifikation: /admin muss jetzt HTTP 200 UND Admin-UI zeigen
async function visitAuthed(name, pathname, markerText = null) {
  consoleErrors.length = 0;
  const t0 = Date.now();
  try {
    const resp = await page.goto(`${BASE}${pathname}`, { waitUntil: 'networkidle', timeout: 20000 });
    const ms = Date.now() - t0;
    if (resp?.status() !== 200) {
      fail(name, `HTTP ${resp?.status()}`);
      return;
    }
    if (page.url().includes('/auth/login') || page.url().includes('/api/auth/signin')) {
      fail(name, 'Auth-Redirect — Session verloren');
      return;
    }
    if (markerText) {
      const body = await page.locator('body').innerText();
      if (!body.includes(markerText)) {
        fail(name, `Marker-Text "${markerText}" nicht gefunden`);
        await shot(name.replace(/[^a-z0-9]+/gi,'-').toLowerCase());
        return;
      }
    }
    pass(name, `${ms}ms`);
    if (consoleErrors.length) {
      report.consoleErrors.push({ name, errors: [...consoleErrors] });
    }
    await shot(name.replace(/[^a-z0-9]+/gi,'-').toLowerCase());
  } catch (e) {
    fail(name, `Exception: ${e.message.slice(0, 120)}`);
  }
}

console.log('\n## Admin-Screens (authentifiziert)');
await visitAuthed('Admin Dashboard',        '/admin');
await visitAuthed('Admin Menüs',            '/admin/menus');
await visitAuthed('Admin Produkte',         '/admin/products');
await visitAuthed('Admin Design-Übersicht', '/admin/design');
await visitAuthed('Admin QR-Codes',         '/admin/qr-codes');
await visitAuthed('Admin CSV-Import',       '/admin/import');
await visitAuthed('Admin Bildarchiv',       '/admin/media');
await visitAuthed('Admin PDF-Creator',      '/admin/pdf-creator');
await visitAuthed('Admin Einstellungen',    '/admin/settings');

// Produkt-Editor: echte Produkt-IDs aus der Liste holen
console.log('\n## Produkt-Editor');
try {
  await page.goto(`${BASE}/admin/products`, { waitUntil: 'networkidle' });
  const href = await page.evaluate(() => {
    const anchors = Array.from(document.querySelectorAll('a[href*="/admin/products/"]'));
    const edit = anchors.find(a => /\/admin\/products\/[a-f0-9\-]{8,}/i.test(a.getAttribute('href') || ''));
    return edit?.getAttribute('href') || null;
  });
  if (href) {
    await visitAuthed('Produkt-Editor', href);
  } else {
    // Fallback: Klick auf die erste Produktzeile
    const row = page.locator('tr, li, [role="button"], [data-testid*="product"]').first();
    const count = await row.count();
    fail('Produkt-Editor', `Kein Edit-Link gefunden (${count} Produkt-Reihen sichtbar)`);
  }
} catch (e) {
  fail('Produkt-Editor', e.message);
}

// Design-Editor: erste Karte in /admin/design
console.log('\n## Design-Editor');
try {
  await page.goto(`${BASE}/admin/design`, { waitUntil: 'networkidle' });
  const href = await page.evaluate(() => {
    const anchors = Array.from(document.querySelectorAll('a[href*="/admin/menus/"][href*="/design"]'));
    return anchors[0]?.getAttribute('href') || null;
  });
  if (href) {
    await visitAuthed('Design-Editor (Karte 1)', href);
  } else {
    fail('Design-Editor', 'Kein Karten-Design-Link gefunden');
  }
} catch (e) {
  fail('Design-Editor', e.message);
}

// === REPORT ===
const md = [];
md.push('# Playwright-Admin-Report v2');
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
    c.errors.slice(0, 5).forEach(e => md.push(`- \`${e}\``));
  });
  md.push('');
}
md.push('## Bestanden');
report.ok.forEach(o => md.push(`- ${o}`));

fs.writeFileSync('/tmp/playwright-admin-report.md', md.join('\n'));
console.log('\n=== Report: /tmp/playwright-admin-report.md ===');
console.log(`=== Screenshots: ${OUT}/screenshots/ ===`);
console.log(`Ergebnis: ${report.ok.length} OK, ${report.fail.length} Befunde, ${report.consoleErrors.length} mit Console-Errors`);

await browser.close();
