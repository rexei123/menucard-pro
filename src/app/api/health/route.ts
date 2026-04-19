// ============================================================================
// GET /api/health
// ----------------------------------------------------------------------------
// Minimaler Health-Endpoint fuer:
//   - Monitoring / Uptime-Checks
//   - Smoke-Test im Staging-Deploy (scripts/deploy-staging.sh)
//   - Test-Gate (ship.ps1) zur schnellen Verifikation "App laeuft"
//
// Absichtlich OHNE Datenbank-Zugriff, OHNE Auth. Nur Lebenszeichen.
// Fuer tiefergehende Checks (DB-Ping etc.) koennen spaeter /api/health/deep
// oder vergleichbare Endpoints folgen.
// ============================================================================

import { NextResponse } from 'next/server';

// Diese Route darf nicht statisch vor-gerendert werden.
export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function GET() {
  return NextResponse.json(
    {
      ok: true,
      service: 'menucard-pro',
      ts: new Date().toISOString(),
      uptimeSec: Math.round(process.uptime()),
      node: process.version,
      env: process.env.NODE_ENV ?? 'unknown',
      commit: process.env.GIT_COMMIT ?? 'unknown',
      version: process.env.npm_package_version ?? 'unknown',
    },
    {
      status: 200,
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate',
      },
    },
  );
}
