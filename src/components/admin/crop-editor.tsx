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
  const [saving, setSaving] = useState(false);

  const ratio = FORMAT_RATIOS[format] || 1;

  const [crop, setCrop] = useState(() => {
    if (initialCrop) return initialCrop;
    const srcRatio = imageWidth / imageHeight;
    let cropW: number, cropH: number, cropX: number, cropY: number;
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

    ctx.clearRect(0, 0, canvasW, canvasH);
    ctx.drawImage(img, 0, 0, canvasW, canvasH);

    ctx.fillStyle = 'rgba(0,0,0,0.5)';
    ctx.fillRect(0, 0, canvasW, canvasH);

    const cx = crop.cropX * scale;
    const cy = crop.cropY * scale;
    const cw = crop.cropW * scale;
    const ch = crop.cropH * scale;

    ctx.drawImage(img, crop.cropX, crop.cropY, crop.cropW, crop.cropH, cx, cy, cw, ch);

    ctx.strokeStyle = '#f59e0b';
    ctx.lineWidth = 2;
    ctx.strokeRect(cx, cy, cw, ch);

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

  useEffect(() => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => { imgRef.current = img; setLoaded(true); };
    img.src = imageUrl;
  }, [imageUrl]);

  const handleMouseDown = (e: React.MouseEvent) => {
    const rect = canvasRef.current?.getBoundingClientRect();
    if (!rect) return;
    setDragging(true);
    setDragStart({ x: e.clientX, y: e.clientY });
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!dragging) return;
    const dx = (e.clientX - dragStart.x) / scale;
    const dy = (e.clientY - dragStart.y) / scale;
    setDragStart({ x: e.clientX, y: e.clientY });

    setCrop(prev => {
      let newX = Math.round(prev.cropX + dx);
      let newY = Math.round(prev.cropY + dy);
      newX = Math.max(0, Math.min(imageWidth - prev.cropW, newX));
      newY = Math.max(0, Math.min(imageHeight - prev.cropH, newY));
      return { ...prev, cropX: newX, cropY: newY };
    });
  };

  const handleMouseUp = () => { setDragging(false); };

  const resetCrop = () => {
    const srcRatio = imageWidth / imageHeight;
    let cropW: number, cropH: number, cropX: number, cropY: number;
    if (srcRatio > ratio) {
      cropH = imageHeight; cropW = Math.round(imageHeight * ratio);
      cropX = Math.round((imageWidth - cropW) / 2); cropY = 0;
    } else {
      cropW = imageWidth; cropH = Math.round(imageWidth / ratio);
      cropX = 0; cropY = Math.round((imageHeight - cropH) / 2);
    }
    setCrop({ cropX, cropY, cropW, cropH });
  };

  const handleSave = async () => {
    setSaving(true);
    await onSave(crop);
    setSaving(false);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60" onClick={onCancel}>
      <div className="bg-white rounded-xl shadow-2xl p-6 max-w-[700px]" onClick={(e) => e.stopPropagation()}>
        <h3 className="text-lg font-semibold mb-4">Ausschnitt bearbeiten &ndash; {format}</h3>

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

        <p className="text-xs text-[#565D6D] text-center mb-4">
          Ausschnitt: {crop.cropW}&times;{crop.cropH} px ab ({crop.cropX}, {crop.cropY})
          <br />
          <span className="text-[#999]">Ziehen Sie den Ausschnitt mit der Maus</span>
        </p>

        <div className="flex justify-between">
          <button onClick={resetCrop}
            className="px-4 py-2 text-sm border rounded hover:bg-[#F9FAFB]">
            Zuruecksetzen
          </button>
          <div className="flex gap-2">
            <button onClick={onCancel}
              className="px-4 py-2 text-sm border rounded hover:bg-[#F9FAFB]">
              Abbrechen
            </button>
            <button onClick={handleSave} disabled={saving}
              className="px-4 py-2 text-sm bg-amber-600 text-white rounded hover:bg-amber-700 disabled:opacity-50">
              {saving ? 'Speichere...' : 'Speichern'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
