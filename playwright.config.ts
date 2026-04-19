import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright-Basis-Smoke-Suite
 *
 * Erwartete Env-Variablen:
 *   BASE_URL     - Ziel-URL, Standard http://127.0.0.1:3001 (Staging via SSH-Tunnel)
 *   ADMIN_EMAIL  - Staging-Admin-Email
 *   ADMIN_PASS   - Staging-Admin-Passwort
 *
 * Lauf:
 *   npm run test:e2e            # headless, alle Specs
 *   npm run test:e2e:ui         # Playwright UI-Mode
 *   npm run test:e2e:headed     # mit sichtbarem Browser
 */
export default defineConfig({
  testDir: './tests/e2e',
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: false,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://127.0.0.1:3001',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    ignoreHTTPSErrors: true,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
