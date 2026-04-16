import { NextRequest, NextResponse } from 'next/server';
import QRCode from 'qrcode';

export async function GET(req: NextRequest) {
  const url = req.nextUrl.searchParams.get('url');
  const format = req.nextUrl.searchParams.get('format') || 'png';
  const fg = req.nextUrl.searchParams.get('fg') || '#000000';
  const bg = req.nextUrl.searchParams.get('bg') || '#FFFFFF';
  const size = parseInt(req.nextUrl.searchParams.get('size') || '512');

  if (!url) return NextResponse.json({ error: 'url required' }, { status: 400 });

  try {
    if (format === 'svg') {
      const svg = await QRCode.toString(url, { type: 'svg', color: { dark: fg, light: bg }, width: size, margin: 2 });
      return new NextResponse(svg, { headers: { 'Content-Type': 'image/svg+xml', 'Cache-Control': 'public, max-age=3600' } });
    } else {
      const buffer = await QRCode.toBuffer(url, { type: 'png', color: { dark: fg, light: bg }, width: size, margin: 2 });
      return new NextResponse(new Uint8Array(buffer), { headers: { 'Content-Type': 'image/png', 'Cache-Control': 'public, max-age=3600' } });
    }
  } catch (e) {
    return NextResponse.json({ error: 'QR generation failed' }, { status: 500 });
  }
}
