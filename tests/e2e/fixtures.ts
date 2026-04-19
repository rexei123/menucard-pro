import { test as base, Page, expect } from '@playwright/test';

/**
 * Admin-Login-Fixture. Meldet sich via /auth/login an und liefert eine Page,
 * die NextAuth-cookie-authentifiziert im /admin-Bereich ist.
 *
 * Nutzt ADMIN_EMAIL + ADMIN_PASS aus der Umgebung.
 */
export const test = base.extend<{ adminPage: Page }>({
  adminPage: async ({ page }, use) => {
    const email = process.env.ADMIN_EMAIL;
    const pass = process.env.ADMIN_PASS;
    if (!email || !pass) {
      throw new Error('ADMIN_EMAIL und ADMIN_PASS muessen gesetzt sein.');
    }

    await page.goto('/auth/login');
    // Login-Form hat keine htmlFor-Label-Bindung -> Inputs ueber type-Attribut
    await page.locator('input[type="email"]').fill(email);
    await page.locator('input[type="password"]').fill(pass);
    await page.getByRole('button', { name: /Anmelden/i }).click();

    // Login redirectet nach /admin via router.push -> auf URL-Wechsel warten
    await page.waitForURL(/\/admin(\/|$)/, { timeout: 10_000 });
    await expect(page).toHaveURL(/\/admin/);

    await use(page);
  },
});

export { expect };
