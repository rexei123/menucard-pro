import { test, expect } from './fixtures';

test.describe('Admin Smoke', () => {
  test('Dashboard laedt ohne Server-Error', async ({ adminPage }) => {
    await adminPage.goto('/admin');
    // Kein Next-Error-Overlay + kein "500" im Body
    await expect(adminPage).toHaveURL(/\/admin$/);
    const body = await adminPage.locator('body').innerText();
    expect(body).not.toMatch(/Server Error|500/i);
    // Sidebar oder Nav-Indikator sollte sichtbar sein
    await expect(adminPage.locator('nav, aside, header').first()).toBeVisible();
  });

  test('Items-Liste laedt und zeigt Produkte', async ({ adminPage }) => {
    await adminPage.goto('/admin/items');
    await adminPage.waitForLoadState('networkidle');
    await expect(adminPage).toHaveURL(/\/admin\/items/);
    // Mindestens ein Listen-Element / Zeile / Link auf ein Item sollte da sein
    const bodyText = await adminPage.locator('body').innerText();
    expect(bodyText.length).toBeGreaterThan(200);
    expect(bodyText).not.toMatch(/Server Error|500/i);
  });

  test('Menues-Liste laedt', async ({ adminPage }) => {
    await adminPage.goto('/admin/menus');
    await adminPage.waitForLoadState('networkidle');
    await expect(adminPage).toHaveURL(/\/admin\/menus/);
    const bodyText = await adminPage.locator('body').innerText();
    expect(bodyText).not.toMatch(/Server Error|500/i);
  });

  test('Design-Uebersicht laedt (4 SYSTEM-Templates erwartet)', async ({ adminPage }) => {
    await adminPage.goto('/admin/design');
    await adminPage.waitForLoadState('networkidle');
    await expect(adminPage).toHaveURL(/\/admin\/design/);
    const bodyText = await adminPage.locator('body').innerText();
    // Mindestens ein SYSTEM-Template-Name muss sichtbar sein
    expect(bodyText).toMatch(/Elegant|Modern|Klassisch|Minimal/);
  });

  test('Analytics-Seite laedt ohne 500', async ({ adminPage }) => {
    await adminPage.goto('/admin/analytics');
    await adminPage.waitForLoadState('networkidle');
    const bodyText = await adminPage.locator('body').innerText();
    expect(bodyText).not.toMatch(/Server Error|500/i);
  });
});
