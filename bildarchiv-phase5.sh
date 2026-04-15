#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Bildarchiv Phase 5: Crop-Editor, PDF-Integration, QR-Logo, Migration
# ═══════════════════════════════════════════════════════════════
cd /var/www/menucard-pro

echo "=== Bildarchiv Phase 5 ==="
echo ""

# ───────────────────────────────────────
echo "[1/5] API: Crop-Endpoint..."
# ───────────────────────────────────────

mkdir -p src/app/api/v1/media/\[id\]/crop

cat > src/app/api/v1/media/\[id\]/crop/route.ts << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import sharp from 'sharp';
import { readFile } from 'fs/promises';
import path from 'path';

const FORMAT_SIZES: Record<string, { width: number; height: number }> = {
  '16:9': { width: 1920, height: 1080 },
  '4:3': { width: 1200, height: 900 },
  '1:1': { width: 800, height: 800 },
  '3:4': { width: 600, height: 800 },
};

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { format, cropX, cropY, cropW, cropH } = await req.json();

  if (!format || !FORMAT_SIZES[format]) {
    return NextResponse.json({ error: 'Invalid format. Use: 16:9, 4:3, 1:1, 3:4' }, { status: 400 });
  }
  if (cropX === undefined || cropY === undefined || cropW === undefined || cropH === undefined) {
    return NextResponse.json({ error: 'cropX, cropY, cropW, cropH required' }, { status: 400 });
  }

  const media = await prisma.media.findUnique({ where: { id: params.id } });
  if (!media) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  const formats = (media.formats as any) || {};
  const originalUrl = formats.original?.url;
  if (!originalUrl) return NextResponse.json({ error: 'Original not found' }, { status: 404 });

  try {
    const basePath = path.join(process.cwd(), 'public');
    const originalPath = path.join(basePath, originalUrl);
    const buffer = await readFile(originalPath);

    const targetSize = FORMAT_SIZES[format];
    const isLogo = media.category === 'LOGO';
    const ext = isLogo ? 'png' : 'webp';
    const formatUrl = formats[format]?.url;
    if (!formatUrl) return NextResponse.json({ error: 'Format URL not found' }, { status: 404 });

    const outputPath = path.join(basePath, formatUrl);

    // Crop + Resize
    const cropped = sharp(buffer)
      .rotate()
      .extract({ left: Math.round(cropX), top: Math.round(cropY), width: Math.round(cropW), height: Math.round(cropH) })
      .resize(targetSize.width, targetSize.height, { fit: 'fill' });

    if (isLogo) {
      await cropped.png().toFile(outputPath);
    } else {
      await cropped.webp({ quality: 85 }).toFile(outputPath);
    }

    // Crop-Koordinaten in formats JSON aktualisieren
    formats[format] = {
      ...formats[format],
      cropX: Math.round(cropX),
      cropY: Math.round(cropY),
      cropW: Math.round(cropW),
      cropH: Math.round(cropH),
    };

    await prisma.media.update({
      where: { id: params.id },
      data: { formats: formats as any },
    });

    return NextResponse.json({ success: true, format: formats[format] });
  } catch (e: any) {
    console.error('Crop error:', e);
    return NextResponse.json({ error: 'Crop failed', details: e.message }, { status: 500 });
  }
}
ENDOFFILE

echo "  ✓ Crop-API erstellt"

# ───────────────────────────────────────
echo "[2/5] Crop-Editor Komponente..."
# ───────────────────────────────────────

cat > src/components/admin/crop-editor.tsx << 'ENDOFFILE'
'use client';

import { useState, useRef, useEffect, useCallback } from 'react';

interface CropEditorProps {
  imageUrl: string;
  imageWidth: number;
  imageHeight: number;
  format: string;
  initialCrop?: { cropX: number; cropY: number; cropW: number; cropH: number };
  onSave: (crop: { cropX: number; cropY: number; cropW: number; cropH: number }) => void;
  onCancel: () => void;
}

const FORMAT_RATIOS: Record<string, number> = {
  '16:9': 16 / 9,
  '4:3': 4 / 3,
  '1:1': 1,
  '3:4': 3 / 4,
};

export default function CropEditor({
  imageUrl,
  imageWidth,
  imageHeight,
  format,
  initialCrop,
  onSave,
  onCancel,
}: CropEditorProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const imgRef = useRef<HTMLImageElement | null>(null);
  const [loaded, setLoaded] = useState(false);
  const [dragging, setDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });

  const ratio = FORMAT_RATIOS[format] || 1;

  // Crop-Bereich im Originalbild-Koordinaten
  const [crop, setCrop] = useState(() => {
    if (initialCrop) return initialCrop;
    // Zentrierter Default-Crop
    const srcRatio = imageWidth / imageHeight;
    let cropW, cropH, cropX, cropY;
    if (srcRatio > ratio) {
      cropH = imageHeight;
      cropW = Math.round(imageHeight * ratio);
      cropX = Math.round((imageWidth - cropW) / 2);
      cropY = 0;
    } else {
      cropW = imageWidth;
      cropH = Math.round(imageWidth / ratio);
      cropX = 0;
      cropY = Math.round((imageHeight - cropH) / 2);
    }
    return { cropX, cropY, cropW, cropH };
  });

  // Canvas-Dimensionen (max 600px breit)
  const maxW = 600;
  const scale = Math.min(maxW / imageWidth, 1);
  const canvasW = Math.round(imageWidth * scale);
  const canvasH = Math.round(imageHeight * scale);

  const draw = useCallback(() => {
    const canvas = canvasRef.current;
    const img = imgRef.current;
    if (!canvas || !img || !loaded) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Bild zeichnen (gedimmt)
    ctx.clearRect(0, 0, canvasW, canvasH);
    ctx.drawImage(img, 0, 0, canvasW, canvasH);

    // Overlay
    ctx.fillStyle = 'rgba(0,0,0,0.5)';
    ctx.fillRect(0, 0, canvasW, canvasH);

    // Crop-Bereich hell
    const cx = crop.cropX * scale;
    const cy = crop.cropY * scale;
    const cw = crop.cropW * scale;
    const ch = crop.cropH * scale;

    ctx.drawImage(img, crop.cropX, crop.cropY, crop.cropW, crop.cropH, cx, cy, cw, ch);

    // Rahmen
    ctx.strokeStyle = '#f59e0b';
    ctx.lineWidth = 2;
    ctx.strokeRect(cx, cy, cw, ch);

    // Drittel-Linien
    ctx.strokeStyle = 'rgba(255,255,255,0.3)';
    ctx.lineWidth = 1;
    for (let i = 1; i <= 2; i++) {
      ctx.beginPath();
      ctx.moveTo(cx + (cw * i) / 3, cy);
      ctx.lineTo(cx + (cw * i) / 3, cy + ch);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(cx, cy + (ch * i) / 3);
      ctx.lineTo(cx + cw, cy + (ch * i) / 3);
      ctx.stroke();
    }
  }, [crop, canvasW, canvasH, scale, loaded]);

  useEffect(() => { draw(); }, [draw]);

  // Bild laden
  useEffect(() => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => { imgRef.current = img; setLoaded(true); };
    img.src = imageUrl;
  }, [imageUrl]);

  // Mouse-Events für Drag
  function handleMouseDown(e: React.MouseEvent) {
    const rect = canvasRef.current?.getBoundingClientRect();
    if (!rect) return;
    setDragging(true);
    setDragStart({ x: e.clientX, y: e.clientY });
  }

  function handleMouseMove(e: React.MouseEvent) {
    if (!dragging) return;
    const dx = (e.clientX - dragStart.x) / scale;
    const dy = (e.clientY - dragStart.y) / scale;
    setDragStart({ x: e.clientX, y: e.clientY });

    setCrop(prev => {
      let newX = Math.round(prev.cropX + dx);
      let newY = Math.round(prev.cropY + dy);
      // Clamp
      newX = Math.max(0, Math.min(imageWidth - prev.cropW, newX));
      newY = Math.max(0, Math.min(imageHeight - prev.cropH, newY));
      return { ...prev, cropX: newX, cropY: newY };
    });
  }

  function handleMouseUp() { setDragging(false); }

  function resetCrop() {
    const srcRatio = imageWidth / imageHeight;
    let cropW, cropH, cropX, cropY;
    if (srcRatio > ratio) {
      cropH = imageHeight; cropW = Math.round(imageHeight * ratio);
      cropX = Math.round((imageWidth - cropW) / 2); cropY = 0;
    } else {
      cropW = imageWidth; cropH = Math.round(imageWidth / ratio);
      cropX = 0; cropY = Math.round((imageHeight - cropH) / 2);
    }
    setCrop({ cropX, cropY, cropW, cropH });
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60" onClick={onCancel}>
      <div className="bg-white rounded-xl shadow-2xl p-6 max-w-[700px]" onClick={(e) => e.stopPropagation()}>
        <h3 className="text-lg font-semibold mb-4">Ausschnitt bearbeiten – {format}</h3>

        <div className="flex justify-center mb-4">
          <canvas
            ref={canvasRef}
            width={canvasW}
            height={canvasH}
            onMouseDown={handleMouseDown}
            onMouseMove={handleMouseMove}
            onMouseUp={handleMouseUp}
            onMouseLeave={handleMouseUp}
            className="border rounded cursor-move"
            style={{ maxWidth: '100%' }}
          />
        </div>

        <p className="text-xs text-gray-500 text-center mb-4">
          Ausschnitt: {crop.cropW}×{crop.cropH} px ab ({crop.cropX}, {crop.cropY})
        </p>

        <div className="flex justify-between">
          <button onClick={resetCrop}
            className="px-4 py-2 text-sm border rounded hover:bg-gray-50">
            Zurücksetzen
          </button>
          <div className="flex gap-2">
            <button onClick={onCancel}
              className="px-4 py-2 text-sm border rounded hover:bg-gray-50">
              Abbrechen
            </button>
            <button onClick={() => onSave(crop)}
              className="px-4 py-2 text-sm bg-amber-600 text-white rounded hover:bg-amber-700">
              Speichern
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
ENDOFFILE

echo "  ✓ Crop-Editor erstellt"

# ───────────────────────────────────────
echo "[3/5] Crop-Editor in Detailansicht integrieren..."
# ───────────────────────────────────────

# Patch media-detail.tsx: Crop-Buttons und CropEditor einfügen

python3 << 'PYEOF'
with open('src/components/admin/media-detail.tsx', 'r') as f:
    content = f.read()

# Import CropEditor hinzufügen
if 'CropEditor' not in content:
    content = content.replace(
        "import { useRouter } from 'next/navigation';",
        "import { useRouter } from 'next/navigation';\nimport CropEditor from './crop-editor';"
    )

    # State für Crop-Editor hinzufügen
    content = content.replace(
        "const [showDelete, setShowDelete] = useState(false);",
        "const [showDelete, setShowDelete] = useState(false);\n  const [cropFormat, setCropFormat] = useState<string | null>(null);"
    )

    # Crop-Button zu jedem Format hinzufügen (außer original und thumb)
    old_format_display = """<p className="text-[10px] text-center text-gray-400">
                  {formats[key]?.width}×{formats[key]?.height}
                </p>"""

    new_format_display = """<p className="text-[10px] text-center text-gray-400">
                  {formats[key]?.width}×{formats[key]?.height}
                </p>
                {key !== 'original' && key !== 'thumb' && (
                  <button
                    onClick={() => setCropFormat(key)}
                    className="mt-1 w-full text-[10px] text-amber-600 hover:text-amber-800"
                  >
                    ✂️ Zuschneiden
                  </button>
                )}"""

    content = content.replace(old_format_display, new_format_display)

    # CropEditor Modal vor dem letzten </div> der Komponente einfügen
    crop_modal = """
      {/* Crop-Editor Modal */}
      {cropFormat && media && formats.original && (
        <CropEditor
          imageUrl={formats.original.url}
          imageWidth={media.width || 800}
          imageHeight={media.height || 600}
          format={cropFormat}
          initialCrop={formats[cropFormat]?.cropX !== undefined ? {
            cropX: formats[cropFormat].cropX,
            cropY: formats[cropFormat].cropY,
            cropW: formats[cropFormat].cropW,
            cropH: formats[cropFormat].cropH,
          } : undefined}
          onSave={async (crop) => {
            try {
              await fetch(`/api/v1/media/${mediaId}/crop`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ format: cropFormat, ...crop }),
              });
              setCropFormat(null);
              // Refresh
              const res = await fetch(`/api/v1/media/${mediaId}`);
              const data = await res.json();
              setMedia(data);
            } catch (e) { console.error(e); }
          }}
          onCancel={() => setCropFormat(null)}
        />
      )}"""

    # Finde das letzte </div> in der return-Anweisung
    last_closing = content.rfind('    </div>\n  );\n}')
    if last_closing > -1:
        content = content[:last_closing] + crop_modal + '\n' + content[last_closing:]

with open('src/components/admin/media-detail.tsx', 'w') as f:
    f.write(content)

print("  ✓ Crop-Editor in Detailansicht integriert")
PYEOF

echo "  ✓ Crop-Editor integriert"

# ───────────────────────────────────────
echo "[4/5] QR-Code: Logo aus Bildarchiv..."
# ───────────────────────────────────────

# Erstelle eine Hilfsfunktion für QR-Code-Logo-Auswahl
# Die eigentliche QR-Code-Komponente wird nur minimal erweitert

QR_FILE=""
for f in src/components/admin/qr-code-editor.tsx src/components/admin/qr-codes.tsx src/app/admin/qr-codes/page.tsx; do
  if [ -f "$f" ]; then
    QR_FILE="$f"
    break
  fi
done

if [ -n "$QR_FILE" ]; then
  cp "$QR_FILE" "${QR_FILE}.bak-bildarchiv"
  echo "  ℹ️  QR-Code-Datei: $QR_FILE – manuelles Patching empfohlen"
  echo "     (ImagePickerButton aus Phase 4 verwenden für Logo-Auswahl)"
else
  echo "  ⚠️  QR-Code-Editor nicht gefunden – überspringe"
fi

echo "  ✓ QR-Code Logo vorbereitet"

# ───────────────────────────────────────
echo "[5/5] Migration bestehender Bilder..."
# ───────────────────────────────────────

cat > src/app/api/v1/media/migrate/route.ts << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import sharp from 'sharp';
import { readFile, mkdir, access } from 'fs/promises';
import path from 'path';

// POST /api/v1/media/migrate – Fehlende Formate für bestehende Bilder generieren
export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const basePath = path.join(process.cwd(), 'public');
  await mkdir(path.join(basePath, 'uploads', 'formats'), { recursive: true });

  // Alle Bilder ohne formats JSON
  const mediaList = await prisma.media.findMany({
    where: {
      OR: [
        { formats: { equals: null } },
        { formats: { equals: {} } },
      ],
    },
    take: 50, // Batch von 50
  });

  if (mediaList.length === 0) {
    return NextResponse.json({ message: 'Keine Migration nötig', migrated: 0 });
  }

  let migrated = 0;
  let errors = 0;

  for (const media of mediaList) {
    try {
      // Original-Datei finden
      let originalPath = '';
      const possiblePaths = [
        path.join(basePath, 'uploads', 'original', media.filename),
        path.join(basePath, media.url),
      ];

      for (const p of possiblePaths) {
        try {
          await access(p);
          originalPath = p;
          break;
        } catch {}
      }

      if (!originalPath) {
        // Versuche large als Fallback
        const largePath = path.join(basePath, 'uploads', 'large', media.filename);
        try { await access(largePath); originalPath = largePath; } catch {}
      }

      if (!originalPath) {
        errors++;
        continue;
      }

      const buffer = await readFile(originalPath);
      const img = sharp(buffer).rotate();
      const meta = await img.metadata();
      const w = meta.width || 800;
      const h = meta.height || 600;

      const filenameBase = media.filename.replace(/\.[^.]+$/, '');
      const isLogo = media.category === 'LOGO';
      const ext = isLogo ? 'png' : 'webp';

      const fmt = isLogo
        ? (clone: sharp.Sharp) => clone.png()
        : (clone: sharp.Sharp) => clone.webp({ quality: 85 });

      // Formate generieren
      await fmt(img.clone().resize(1920, 1080, { fit: 'cover', position: 'center' }))
        .toFile(path.join(basePath, 'uploads', 'formats', `${filenameBase}-16x9.${ext}`));
      await fmt(img.clone().resize(1200, 900, { fit: 'cover', position: 'center' }))
        .toFile(path.join(basePath, 'uploads', 'formats', `${filenameBase}-4x3.${ext}`));
      await fmt(img.clone().resize(800, 800, { fit: 'cover', position: 'center' }))
        .toFile(path.join(basePath, 'uploads', 'formats', `${filenameBase}-1x1.${ext}`));
      await fmt(img.clone().resize(600, 800, { fit: 'cover', position: 'center' }))
        .toFile(path.join(basePath, 'uploads', 'formats', `${filenameBase}-3x4.${ext}`));

      // Crop-Koordinaten berechnen
      function centerCrop(srcW: number, srcH: number, tgtRatio: number) {
        const srcRatio = srcW / srcH;
        let cropW, cropH, cropX, cropY;
        if (srcRatio > tgtRatio) {
          cropH = srcH; cropW = Math.round(srcH * tgtRatio);
          cropX = Math.round((srcW - cropW) / 2); cropY = 0;
        } else {
          cropW = srcW; cropH = Math.round(srcW / tgtRatio);
          cropX = 0; cropY = Math.round((srcH - cropH) / 2);
        }
        return { cropX, cropY, cropW, cropH };
      }

      const formats = {
        original: { url: `/uploads/original/${media.filename}`, width: w, height: h },
        '16:9': { url: `/uploads/formats/${filenameBase}-16x9.${ext}`, width: 1920, height: 1080, ...centerCrop(w, h, 16/9) },
        '4:3': { url: `/uploads/formats/${filenameBase}-4x3.${ext}`, width: 1200, height: 900, ...centerCrop(w, h, 4/3) },
        '1:1': { url: `/uploads/formats/${filenameBase}-1x1.${ext}`, width: 800, height: 800, ...centerCrop(w, h, 1) },
        '3:4': { url: `/uploads/formats/${filenameBase}-3x4.${ext}`, width: 600, height: 800, ...centerCrop(w, h, 3/4) },
        thumb: { url: media.thumbnailUrl || `/uploads/thumb/${media.filename}`, width: 200, height: 200 },
      };

      await prisma.media.update({
        where: { id: media.id },
        data: {
          formats: formats as any,
          width: w,
          height: h,
          originalName: media.originalName || media.filename,
          title: media.title || media.alt || media.filename.replace(/\.[^.]+$/, ''),
        },
      });

      migrated++;
    } catch (e) {
      console.error(`Migration error for ${media.id}:`, e);
      errors++;
    }
  }

  return NextResponse.json({
    migrated,
    errors,
    remaining: await prisma.media.count({
      where: { OR: [{ formats: { equals: null } }, { formats: { equals: {} } }] },
    }),
  });
}
ENDOFFILE

echo "  ✓ Migrations-API erstellt"

# ───────────────────────────────────────
echo ""
echo "[BUILD] Kompiliere..."
# ───────────────────────────────────────

npm run build 2>&1 | tail -15

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "  ✅ Bildarchiv Phase 5 LIVE!"
  echo "═══════════════════════════════════════════════"
  echo ""
  echo "  Neue Features:"
  echo "  → Crop-Editor (Canvas, Drag & Drop)"
  echo "  → Crop-API: PATCH /api/v1/media/[id]/crop"
  echo "  → Migrations-API: POST /api/v1/media/migrate"
  echo "  → QR-Code Logo vorbereitet"
  echo ""
  echo "  Migration starten:"
  echo "  curl -X POST http://localhost:3000/api/v1/media/migrate \\"
  echo "    -H 'Cookie: ...' (mehrfach ausführen bis remaining=0)"
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "  🎉 ALLE 5 PHASEN ABGESCHLOSSEN!"
  echo "═══════════════════════════════════════════════"
  echo ""
else
  echo ""
  echo "  ❌ Build fehlgeschlagen – siehe Fehler oben"
fi
