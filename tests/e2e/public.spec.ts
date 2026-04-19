import { test, expect } from '@playwright/test';

/**
 * Public-Smoke: Oeffentliche Gaeste-Seiten ohne Auth.
 *
 * Strategie:
 *  - ueber /api/v1/menus (unauth -> nur ACTIVE) eine gueltige Karte ermitteln
 *  - Tenant-Slug aus env PUBLIC_TENANT_SLUG (Default: hotel-sonnblick)
 *  - Kartenansicht + Item-Detail aufrufen und auf Grundstruktur pruefen
 */
test.describe('Public Smoke', () => {
  const tenantSlug = process.env.PUBLIC_TENANT_SLUG || 'hotel-sonnblick';

  test('Kartenansicht rendert ohne Server-Error', async ({ page, request }) => {
    // Erste ACTIVE-Karte aus der API ziehen
    const res = await request.get('/api/v1/menus');
    expect(res.ok(), 'GET /api/v1/menus').toBeTruthy();
    const menus = (await res.json()) as Array<any>;
    expect(Array.isArray(menus)).toBeTruthy();
    expect(menus.length, 'Mindestens eine ACTIVE-Karte').toBeGreaterThan(0);

    const m = menus.find((x) => x.isActive) || menus[0];
    expect(m.slug, 'Karte hat slug').toBeTruthy();
    expect(m.location?.slug, 'Karte hat location.slug').toBeTruthy();

    const url = `/${tenantSlug}/${m.location.slug}/${m.slug}`;
    const resp = await page.goto(url, { waitUntil: 'domcontentloaded' });
    expect(resp?.status(), `HTTP-Status fuer ${url}`).toBeLessThan(400);

    const body = await page.locator('body').innerText();
    expect(body).not.toMatch(/Server Error|500|Application error/i);
    // Karte hat einen <h1> mit Titel (robust gegen unterschiedliche Template-Wrapper)
    await expect(page.locator('h1').first()).toBeVisible();
    expect(body.length, 'Seite hat Inhalt').toBeGreaterThan(100);
  });

  test('Item-Detail-Seite rendert (falls Produkte vorhanden)', async ({ page, request }) => {
    const res = await request.get('/api/v1/menus');
    const menus = (await res.json()) as Array<any>;
    const m = menus.find((x) => x.isActive) || menus[0];
    if (!m) test.skip();

    // Kartenansicht oeffnen und einen Item-Link suchen
    await page.goto(`/${tenantSlug}/${m.location.slug}/${m.slug}`, { waitUntil: 'networkidle' });

    const itemLink = page.locator('a[href*="/item/"]').first();
    const count = await itemLink.count();
    if (count === 0) {
      // Karte ohne sichtbare Produkte: Test als skipped markieren, nicht als failed
      test.skip(true, 'Karte enthaelt keine Item-Links fuer Detail-Test');
    }

    const href = await itemLink.getAttribute('href');
    expect(href, 'Item-Link href vorhanden').toBeTruthy();
    await itemLink.click();
    await page.waitForLoadState('domcontentloaded');

    const body = await page.locator('body').innerText();
    expect(body).not.toMatch(/Server Error|500|Application error/i);
    expect(body.length).toBeGreaterThan(100);
    // Item-Detail hat entweder h1 oder h2 mit Produktname
    await expect(page.locator('h1, h2').first()).toBeVisible();
  });

  test('Sprach-Switch auf /?lang=en liefert englische Texte', async ({ page, request }) => {
    const res = await request.get('/api/v1/menus');
    const menus = (await res.json()) as Array<any>;
    const m = menus.find((x) => x.isActive) || menus[0];
    if (!m) test.skip();

    const resp = await page.goto(`/${tenantSlug}/${m.location.slug}/${m.slug}?lang=en`, {
      waitUntil: 'domcontentloaded',
    });
    expect(resp?.status()).toBeLessThan(400);

    const body = await page.locator('body').innerText();
    expect(body).not.toMatch(/Server Error|500/i);
    // Englischer Footer-Hinweis: "All prices in EUR incl. taxes."
    expect(body).toMatch(/All prices|EUR|taxes/i);
  });
});
