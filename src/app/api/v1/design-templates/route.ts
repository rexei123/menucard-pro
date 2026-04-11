import { NextResponse } from 'next/server';

const templates = [
  { id: 'elegant', name: 'Elegant', description: 'Weinkarten, Gala-Menüs – Playfair Display, warme Töne, viel Weißraum', mood: 'warm' },
  { id: 'modern', name: 'Modern', description: 'Barkarte, Cocktails – Inter, dunkler Hintergrund, große Bilder', mood: 'dark' },
  { id: 'classic', name: 'Klassisch', description: 'Restaurant-Menüs, Themenabende – Garamond, Bordüren, zentriert', mood: 'light' },
  { id: 'minimal', name: 'Minimal', description: 'Frühstück, Room Service – Max. Lesbarkeit, wenig Dekoration', mood: 'light' },
];

export async function GET() {
  return NextResponse.json({ templates });
}
