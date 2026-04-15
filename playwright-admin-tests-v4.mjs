import { chromium } from 'playwright';
import fs from 'fs';

const BASE = 'https://menu.hotel-sonnblick.at';
const EMAIL = 'admin@hotel-sonnblick.at';
const PASS = 'Sonnblick2026!';

const PRODUCT_ID = 'c2d84dac-2ba2-4496-be38-a3139e66962c';
const MENU_ID = 'cmnooyalz002wu8rihn3tslhl';
const CUSTOM_TEMPLATE_ID = 'cmny9epa900008irm01i5ujpd'; // "Test 1"
const SYSTEM_TEMPLATE_ID = 'cmny7jrhs0000f2mzpigboldv'; // "Elegant"

const findings = [];
const ok = [];

async function check(name, url, page, opts = {}) {
  const t0 = Date.now();
  const resp = await page.goto(`${BASE}${url}`, { waitUntil: 'networkidle' });
  const ms = Date.now() - t0;
  const status = resp?.status() ?? 0;
  const finalUrl = page.url();
  const content = await page.content();

  // Check if redirected to signin
  if (finalUrl.includes('/api/auth/signin') || finalUrl.includes('/login')) {
    findings.push(`${name} — Redirect zu Signin (URL: ${finalUrl})`);
    return { status, ms, finalUrl };
  }

  // Expected redirect (e.g. SYSTEM → /admin/design)
  if (opts.expectRedirect) {
    if (finalUrl.endsWith(opts.expectRedirect) || finalUrl.includes(opts.expectRedirect)) {
      ok.push(`${name} — Redirect zu ${opts.expectRedirect} OK (${ms}ms)`);
      return { status, ms, finalUrl };
    } else {
      findings.push(`${name} — Erwartete Redirect zu ${opts.expectRedirect}, aber URL ist ${finalUrl}`);
      return { status, ms, finalUrl };
    }
  }

  if (status < 200 || status >= 400) {
    findings.push(`${name} — HTTP ${status}`);
  } else {
    ok.push(`${name} — ${ms}ms`);
  }

  // Optional content checks
  if (opts.expectText) {
    for (const txt of opts.expectText) {
      if (!content.includes(txt)) {
        findings.push(`${name} — Erwarteter Text fehlt: "${txt}"`);
      }
    }
  }

  return { status, ms, finalUrl };
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: 'de-AT' });
  const page = await ctx.newPage();

  // LOGIN
  console.log('Login...');
  const loginPaths = ['/login', '/admin/login', '/auth/signin', '/api/auth/signin'];
  let loginOK = false;
  for (const lp of loginPaths) {
    try {
      await page.goto(`${BASE}${lp}`, { waitUntil: 'domcontentloaded' });
      await page.waitForSelector('input[type="email"], input[name="email"]', { timeout: 10000 });
      const emailSel = await page.$('input[name="email"]') ? 'input[name="email"]' : 'input[type="email"]';
      const passSel = await page.$('input[name="password"]') ? 'input[name="password"]' : 'input[type="password"]';
      await page.fill(emailSel, EMAIL);
      await page.fill(passSel, PASS);
      await Promise.all([
        page.waitForURL(/\/admin/, { timeout: 15000 }),
        page.click('button[type="submit"]'),
      ]);
      console.log(`Login via ${lp} OK`);
      loginOK = true;
      break;
    } catch (e) {
      console.log(`Login via ${lp} FEHLGESCHLAGEN: ${e.message.split('\n')[0]}`);
    }
  }
  if (!loginOK) {
    console.error('ALLE LOGIN-PFADE FEHLGESCHLAGEN');
    process.exit(1);
  }
  const cookies = await ctx.cookies();
  const hasSession = cookies.some((c) => c.name.includes('session-token'));
  if (!hasSession) {
    console.error('LOGIN FEHLGESCHLAGEN (kein session-token)');
    process.exit(1);
  }
  console.log('Session-Cookie OK');

  // ADMIN SCREENS
  await check('Dashboard', '/admin', page);
  await check('Karten-Übersicht', '/admin/menus', page);
  await check('Produkte-Liste', '/admin/products', page);
  await check('Design-Übersicht', '/admin/design', page);
  await check('QR-Codes', '/admin/qr-codes', page);
  await check('Medien', '/admin/media', page);
  await check('Import', '/admin/import', page);
  await check('Benutzer', '/admin/users', page);
  await check('Einstellungen', '/admin/settings', page);

  // EDITOREN
  await check('Produkt-Editor', `/admin/products/${PRODUCT_ID}`, page);
  await check('Karten-Editor', `/admin/menus/${MENU_ID}`, page);
  await check('Design-Editor (CUSTOM)', `/admin/design/${CUSTOM_TEMPLATE_ID}/edit`, page);
  await check('Design-Editor (SYSTEM Redirect)', `/admin/design/${SYSTEM_TEMPLATE_ID}/edit`, page, {
    expectRedirect: '/admin/design',
  });

  // GÄSTE-KARTEN (9)
  const guestMenus = [
    { slug: 'amuse-bouche-menu', label: 'Gourmet Amuse-Bouche' },
    { slug: 'kulinarischer-dialog', label: 'Gourmet Dialog' },
    { slug: 'gourmet-alpin', label: 'Gourmet Alpin' },
    { slug: 'vegetarisches-menue', label: 'Gourmet Vegetarisch' },
    { slug: 'gourmet-klassik', label: 'Gourmet Klassik' },
    { slug: 'saisonale-spezialitaeten', label: 'Gourmet Saison' },
    { slug: 'signature-menu', label: 'Gourmet Signature' },
    { slug: 'weinkarte', label: 'Weinkarte' },
    { slug: 'barkarte', label: 'Barkarte' },
  ];
  for (const m of guestMenus) {
    await check(`Gast ${m.label}`, `/hotel-sonnblick/restaurant/${m.slug}`, page);
  }

  await browser.close();

  console.log('\n=== ERGEBNIS ===');
  console.log(`OK: ${ok.length}`);
  console.log(`Befunde: ${findings.length}`);
  if (ok.length) {
    console.log('\n--- OK ---');
    ok.forEach((o) => console.log('  ✓', o));
  }
  if (findings.length) {
    console.log('\n--- Befunde ---');
    findings.forEach((f) => console.log('  ✗', f));
  }
  fs.writeFileSync('/tmp/admin-test-v4-result.json', JSON.stringify({ ok, findings }, null, 2));
})();
