import { test, expect } from '@playwright/test';

test.describe('Auth', () => {
  test('unauth auf /admin leitet nach /auth/login um', async ({ page }) => {
    await page.goto('/admin');
    await expect(page).toHaveURL(/\/auth\/login/);
    await expect(page.getByRole('heading', { name: 'MenuCard Pro' })).toBeVisible();
    await expect(page.locator('input[type="email"]')).toBeVisible();
    await expect(page.locator('input[type="password"]')).toBeVisible();
  });

  test('Login mit gueltigen Credentials landet auf Dashboard', async ({ page }) => {
    const email = process.env.ADMIN_EMAIL!;
    const pass = process.env.ADMIN_PASS!;

    await page.goto('/auth/login');
    await page.locator('input[type="email"]').fill(email);
    await page.locator('input[type="password"]').fill(pass);
    await page.getByRole('button', { name: /Anmelden/i }).click();

    await page.waitForURL(/\/admin(\/|$)/, { timeout: 10_000 });
    await expect(page).toHaveURL(/\/admin/);
  });

  test('Login mit falschem Passwort zeigt Fehlermeldung', async ({ page }) => {
    await page.goto('/auth/login');
    await page.locator('input[type="email"]').fill('admin@hotel-sonnblick.at');
    await page.locator('input[type="password"]').fill('definitiv-falsches-passwort');
    await page.getByRole('button', { name: /Anmelden/i }).click();

    await expect(page.getByText(/Falsche E-Mail oder Passwort/i)).toBeVisible({ timeout: 5_000 });
    await expect(page).toHaveURL(/\/auth\/login/);
  });
});
