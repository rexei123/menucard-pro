// design-compliance.mjs
// Prüft MenuCard Pro gegen Design-Strategie 2.0 — 6 Schichten.
// Wird auf dem Server ausgeführt (benötigt Playwright), schreibt report.json.

import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const BASE   = process.env.BASE   || 'https://menu.hotel-sonnblick.at';
const EMAIL  = process.env.EMAIL  || 'admin@hotel-sonnblick.at';
const PASS   = process.env.PASS   || 'Sonnblick2026!';
const ROOT   = path.resolve('tests/design-compliance');
const ROUTES = JSON.parse(fs.readFileSync(path.join(ROOT, 'routes.json'), 'utf8'));
const SNAP   = path.join(ROOT, 'snapshots');
fs.mkdirSync(SNAP, { recursive: true });

/* ============================================================
 * SCHICHT 1 — Token-Soll-Werte aus Design-Strategie 2.0
 * ============================================================ */
const EXPECTED_TOKENS = {
  // Primär
  '--color-primary'         : '#DD3C71',
  '--color-primary-hover'   : '#C42D60',
  '--color-primary-light'   : '#FDF2F5',
  '--color-primary-subtle'  : 'rgba(221, 60, 113, 0.08)',
  // Hintergrund
  '--color-bg'              : '#FFFFFF',
  '--color-bg-subtle'       : '#FAFAFB',
  '--color-bg-muted'        : '#F3F3F6',
  '--color-surface'         : '#FFFFFF',
  '--color-surface-hover'   : '#F9F9FB',
  // Text
  '--color-text'            : '#1A1A1A',
  '--color-text-secondary'  : '#565D6D',
  '--color-text-muted'      : '#8E8E8E',
  '--color-text-inverse'    : '#FFFFFF',
  // Rand
  '--color-border'          : '#E5E7EB',
  // Semantisch
  '--color-success'         : '#16A34A',
  '--color-warning'         : '#F59E0B',
  '--color-error'           : '#E05252',
  '--color-info'            : '#3B82F6',
  // Sidebar
  '--color-sidebar-bg'      : '#FFFFFF',
  '--color-sidebar-text'    : '#565D6D',
  // Badges
  '--color-badge-new'       : '#DD3C71',
  '--color-badge-top'       : '#F59E0B',
  '--color-badge-bestseller': '#16A34A',
  '--color-badge-hot'       : '#E05252',
  // Layout
  '--sidebar-width'         : '200px',
  '--sidebar-collapsed-width': '56px',
  '--header-height'         : '56px',
  '--list-panel-width'      : '400px',
  // Typografie (Fonts werden gesondert geprüft; hier nur Strings-Abgleich)
  '--font-body'             : "'Inter', ui-sans-serif, system-ui, sans-serif",
  '--font-heading'          : "'Playfair Display', ui-serif, Georgia, serif",
  // Radius
  '--radius-md'             : '8px',
  '--radius-lg'             : '12px',
  '--radius-full'           : '9999px',
  // Spacing
  '--spacing-md'            : '16px',
  '--spacing-lg'            : '24px',
  '--spacing-xl'            : '32px',
};

/* ============================================================
 * SCHICHT 2 — Erwartete Schriften
 * ============================================================ */
const ADMIN_FONT_EXPECT = { // Benutzer-Regel: Admin = Roboto für ALLES
  body     : /Roboto/i,
  heading  : /Roboto/i,
};
const TEMPLATE_FONT_EXPECT = {
  elegant  : { heading: /Playfair Display/i,  body: /Inter/i         },
  modern   : { heading: /Montserrat/i,        body: /Montserrat/i    },
  classic  : { heading: /Playfair Display/i,  body: /(Playfair|Inter)/i },
  minimal  : { heading: /(Grotesk|Inter|Roboto)/i, body: /(Grotesk|Inter|Roboto)/i },
};

/* ============================================================
 * SCHICHT 4 — Icon-Inventar (Material Symbols → müssen vorhanden sein,
 *   Emojis dürfen NICHT in Admin-Navigation / Template-Kategorie-Kacheln)
 * ============================================================ */
const MATERIAL_ICONS_CORE = [
  'dashboard','inventory_2','menu_book','qr_code_2','photo_library',
  'analytics','settings','refresh','logout',
  'wine_bar','local_bar','restaurant','coffee','sports_bar',
  'check_circle','block','star','crop','delete','save','add','close','search','upload','language'
];
const EMOJI_RE = /\p{Extended_Pictographic}/u;

/* ============================================================
 * Helper
 * ============================================================ */
const findings = [];
const report   = { generatedAt: new Date().toISOString(), base: BASE, pages: [] };

function log(...a){ console.log('[compliance]', ...a); }

async function login(page) {
  await page.goto(`${BASE}/auth/login`, { waitUntil: 'networkidle', timeout: 30000 });
  // Mehrere mögliche Selektoren probieren
  const emailSel = [
    'input[name="email"]',
    'input[type="email"]',
    '#email',
    'input[name="username"]',
    'input[autocomplete="email"]',
    'input[placeholder*="mail" i]',
  ];
  const passSel = [
    'input[name="password"]',
    'input[type="password"]',
    '#password',
    'input[autocomplete="current-password"]',
  ];
  let emailFound = null, passFound = null;
  for (const s of emailSel) {
    if (await page.$(s)) { emailFound = s; break; }
  }
  for (const s of passSel) {
    if (await page.$(s)) { passFound = s; break; }
  }
  if (!emailFound || !passFound) {
    // Screenshot vom Login-Screen, damit wir sehen was gerendert wurde
    try { await page.screenshot({ path: path.join(SNAP, '_login_debug.png'), fullPage: true }); } catch {}
    const html = await page.content();
    fs.writeFileSync(path.join(ROOT, '_login_debug.html'), html);
    throw new Error(`Login-Felder nicht gefunden (email=${emailFound}, pass=${passFound}). HTML unter _login_debug.html gesichert.`);
  }
  await page.fill(emailFound, EMAIL);
  await page.fill(passFound, PASS);
  const submitBtn = await page.$('button[type="submit"]')
                 || await page.$('button:has-text("Anmelden")')
                 || await page.$('button:has-text("Login")')
                 || await page.$('button');
  await Promise.all([
    page.waitForURL(/\/admin/, { timeout: 20000 }).catch(() => null),
    submitBtn.click(),
  ]);
  const finalUrl = page.url();
  if (!/\/admin/.test(finalUrl)) throw new Error(`Login scheiterte. URL nach Submit: ${finalUrl}`);
  log('Login OK');
}

/* --- SCHICHT 1: Tokens via getComputedStyle auf :root --- */
async function checkTokens(page) {
  return page.evaluate((expected) => {
    const cs = getComputedStyle(document.documentElement);

    // CSS-Wert-Normalisierer: Browser normalisiert Werte unterschiedlich.
    // Wir reduzieren Soll und Ist auf eine kanonische Form vor dem Vergleich.
    const canon = (s) => {
      if (!s) return '';
      let v = String(s).trim();
      // Klammer-Inhalte normalisieren: Leerzeichen weg, führende 0 weg
      v = v.replace(/\s+/g, ' ').trim();
      // Hex-Farben: #FFFFFF == #FFF == #ffffff == #fff
      v = v.replace(/#([0-9a-fA-F]{6,8})/g, (m, hex) => {
        const lo = hex.toLowerCase();
        if (lo.length === 6 && lo[0]===lo[1] && lo[2]===lo[3] && lo[4]===lo[5])
          return '#' + lo[0] + lo[2] + lo[4];
        return '#' + lo;
      });
      v = v.replace(/#([0-9a-fA-F]{3,4})/g, (m, hex) => '#' + hex.toLowerCase());
      // rgb/rgba(): Whitespace weg, immer mit führender 0 (.08 → 0.08)
      v = v.replace(/rgba?\(([^)]+)\)/gi, (m, inner) => {
        const parts = inner.split(',').map(p => p.trim()).map(p => {
          // .08 → 0.08 (eine kanonische Form)
          if (/^\.\d/.test(p)) return '0' + p;
          return p;
        });
        return 'rgb' + (parts.length === 4 ? 'a' : '') + '(' + parts.join(',') + ')';
      });
      // Anführungszeichen in Font-Family egalisieren
      v = v.replace(/["']/g, "'");
      // Mehrfach-Leerzeichen zu Einzel-Leerzeichen
      v = v.replace(/\s*,\s*/g, ',').replace(/\s+/g, ' ').toLowerCase().trim();
      return v;
    };

    const results = {};
    for (const [k, v] of Object.entries(expected)) {
      const actual = cs.getPropertyValue(k).trim();
      results[k] = {
        expected: v,
        actual,
        pass: canon(actual) === canon(v),
        canonExpected: canon(v),
        canonActual:   canon(actual),
      };
    }
    return results;
  }, EXPECTED_TOKENS);
}

/* --- SCHICHT 2: Fonts für Body + Heading --- */
async function checkFonts(page) {
  return page.evaluate(() => {
    const body = document.body;
    const h    = document.querySelector('h1, h2, h3') || body;
    const bodyFont = getComputedStyle(body).fontFamily;
    const headFont = getComputedStyle(h).fontFamily;
    // Material-Symbols-Element geladen?
    const msTest = document.createElement('span');
    msTest.className = 'material-symbols-outlined';
    msTest.textContent = 'settings';
    msTest.style.position = 'absolute'; msTest.style.opacity = '0';
    document.body.appendChild(msTest);
    const msFont = getComputedStyle(msTest).fontFamily;
    msTest.remove();
    return { bodyFont, headFont, msFont, hasMaterial: /material symbols/i.test(msFont) };
  });
}

/* --- SCHICHT 3: Farb-Spotcheck --- */
async function checkColors(page) {
  return page.evaluate(() => {
    const pickFirst = (selectors, attr='color') => {
      for (const sel of selectors) {
        const el = document.querySelector(sel);
        if (el) return { sel, attr, value: getComputedStyle(el)[attr] };
      }
      return null;
    };
    return [
      pickFirst(['body'], 'backgroundColor'),
      pickFirst(['a'], 'color'),
      pickFirst(['button[type="submit"]', 'button'], 'backgroundColor'),
      pickFirst(['h1','h2','h3'], 'color'),
      pickFirst(['aside','[data-sidebar]','nav[aria-label*="Haupt" i]','div[class*="sidebar"]'], 'backgroundColor'),
      pickFirst(['header','[role="banner"]','div[class*="header"]'], 'backgroundColor'),
      pickFirst(['[data-badge-new]','.badge-new','[class*="bg-primary"]'], 'backgroundColor'),
    ].filter(Boolean);
  });
}

/* --- SCHICHT 4: Icon-Audit --- */
async function checkIcons(page) {
  return page.evaluate((opts) => {
    const bodyText = document.body.innerText || '';
    const emojis   = [...bodyText.matchAll(/\p{Extended_Pictographic}/gu)].map(m => m[0]);
    const uniqueEmojis = [...new Set(emojis)];
    const msNodes = document.querySelectorAll('.material-symbols-outlined, [class*="material-symbols"]');
    const presentIcons = [...msNodes].map(n => (n.textContent || '').trim()).filter(Boolean);
    const missingCore  = opts.core.filter(i => !presentIcons.includes(i));
    return {
      emojiCount   : emojis.length,
      uniqueEmojis ,
      materialCount: msNodes.length,
      presentIcons : [...new Set(presentIcons)].slice(0, 50),
      missingCore  ,
    };
  }, { core: MATERIAL_ICONS_CORE });
}

/* --- SCHICHT 5: Layout --- */
async function checkLayout(page) {
  return page.evaluate(() => {
    // Robust gegen Tailwind-Admin-Layouts: probiere viele Kandidaten.
    const findFirst = (selectors) => {
      for (const s of selectors) {
        const el = document.querySelector(s);
        if (el) return { sel: s, el };
      }
      return null;
    };
    // Sidebar: erst semantisch, dann übliche Tailwind-Klassen/Attribute
    const sidebarCand = findFirst([
      'aside', '[data-sidebar]', '[role="navigation"][aria-label*="main" i]',
      'nav[aria-label*="Haupt" i]', 'nav[aria-label*="Admin" i]',
      'div[class*="sidebar"]', '[data-testid*="sidebar"]',
      'div.w-\\[200px\\]', 'div.w-\\[240px\\]', 'div.w-56', 'div.w-60', 'div.w-64',
    ]);
    const headerCand = findFirst([
      'header', '[role="banner"]', '[data-header]',
      'div[class*="header"]', 'div[class*="topbar"]',
      'div.h-14', 'div.h-16',
    ]);
    const listCand = findFirst([
      '[data-list-panel]', '.list-panel',
      'div[class*="list-panel"]', 'div[class*="ListPanel"]',
      'div.w-\\[400px\\]', 'div.w-96',
    ]);
    // Größte sichtbare Navigation als Fallback
    let sidebarEl = sidebarCand?.el || null;
    if (!sidebarEl) {
      const navs = [...document.querySelectorAll('nav')]
        .map(n => ({ n, r: n.getBoundingClientRect() }))
        .filter(x => x.r.height > 300 && x.r.width > 100 && x.r.width < 320)
        .sort((a, b) => b.r.height - a.r.height);
      sidebarEl = navs[0]?.n || null;
    }
    const measure = (el) => el ? {
      w: Math.round(el.getBoundingClientRect().width),
      h: Math.round(el.getBoundingClientRect().height),
    } : null;
    const s = measure(sidebarEl);
    const h = measure(headerCand?.el);
    const l = measure(listCand?.el);
    return {
      sidebarWidth: s?.w ?? null,
      sidebarSel  : sidebarCand?.sel || (sidebarEl ? 'nav(fallback)' : null),
      headerHeight: h?.h ?? null,
      headerSel   : headerCand?.sel || null,
      listWidth   : l?.w ?? null,
      listSel     : listCand?.sel || null,
      viewport    : { w: window.innerWidth, h: window.innerHeight },
    };
  });
}

/* --- Ein Routen-Durchlauf --- */
async function runPage(ctx, label, url, kind, viewport, extra={}) {
  const page = await ctx.newPage();
  await page.setViewportSize(viewport);
  const t0 = Date.now();
  const resp = await page.goto(`${BASE}${url}`, { waitUntil: 'domcontentloaded', timeout: 20000 }).catch(e => null);
  await page.waitForTimeout(1500);   // clientseitiges Rendering abwarten
  const status = resp?.status?.() ?? 0;
  const finalUrl = page.url();

  let tokens=null, fonts=null, colors=null, icons=null, layout=null, errMsg=null;
  try { tokens = await checkTokens(page); } catch(e){ errMsg = (errMsg||'') + 'tokens:' + e.message + ';'; }
  try { fonts  = await checkFonts(page); }  catch(e){ errMsg = (errMsg||'') + 'fonts:'  + e.message + ';'; }
  try { colors = await checkColors(page); } catch(e){ errMsg = (errMsg||'') + 'colors:' + e.message + ';'; }
  try { icons  = await checkIcons(page); }  catch(e){ errMsg = (errMsg||'') + 'icons:'  + e.message + ';'; }
  try { layout = await checkLayout(page); } catch(e){ errMsg = (errMsg||'') + 'layout:' + e.message + ';'; }

  // Screenshot
  const shotName = `${kind}_${label.replace(/[^\w-]+/g,'_')}_${viewport.width}x${viewport.height}.png`;
  const shotPath = path.join(SNAP, shotName);
  try { await page.screenshot({ path: shotPath, fullPage: true, timeout: 15000 }); }
  catch(e){ errMsg = (errMsg||'') + 'snap:' + e.message + ';'; }

  const ms = Date.now() - t0;
  report.pages.push({
    label, url, kind, viewport, status, finalUrl, ms,
    screenshot: path.relative(ROOT, shotPath),
    tokens, fonts, colors, icons, layout,
    extra, errMsg,
  });
  log(` ${status} ${kind}/${viewport.width}w ${label} (${ms}ms)`);
  await page.close();
}

/* ============================================================
 * MAIN
 * ============================================================ */
(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctx     = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: 'de-AT' });
  const page    = await ctx.newPage();

  let loginWorked = false;
  try {
    await login(page);
    loginWorked = true;
  } catch (e) {
    log('LOGIN FEHLGESCHLAGEN:', e.message);
    report.loginError = e.message;
  }
  await page.close();

  const VIEWPORTS = [
    { width: 1440, height: 900 },   // Desktop
    { width: 375,  height: 812 },   // Mobile
  ];

  // 1. Admin-Routen (nur wenn Login klappte)
  if (loginWorked) {
    for (const r of ROUTES.adminRoutes) {
      for (const vp of VIEWPORTS) {
        await runPage(ctx, r.label, r.path, 'admin', vp, { needsAuth: r.needsAuth });
      }
    }
  } else {
    // Immerhin den Login-Screen selbst prüfen
    for (const vp of VIEWPORTS) {
      await runPage(ctx, 'Login', '/auth/login', 'admin-login', vp, {});
    }
  }

  // 2. Gast-Karten (aktive Menus)
  for (const m of ROUTES.menus) {
    for (const vp of VIEWPORTS) {
      await runPage(ctx, `Menu-${m.menu}`, m.publicPath, 'guest-menu', vp,
        { templateKey: m.templateKey, templateSource: m.templateSource });
      if (m.itemProductId) {
        await runPage(ctx, `Item-${m.menu}`, `${m.publicPath}/item/${m.itemProductId}`, 'guest-item', vp,
          { templateKey: m.templateKey });
      }
    }
  }

  // 3. Jedes SYSTEM-Template direkt via erstem passenden Menu
  //    (bereits in 2 abgedeckt; kein Extra-Durchlauf nötig)

  await browser.close();

  fs.writeFileSync(path.join(ROOT, 'report.json'), JSON.stringify(report, null, 2));
  log(`Fertig. ${report.pages.length} Seiten geprüft. Report: tests/design-compliance/report.json`);
})().catch(e => {
  console.error('FATAL', e);
  process.exit(2);
});
