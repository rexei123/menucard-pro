'use client';

import { useState } from 'react';
import MediaPickerModal from './media-picker-modal';

interface ImagePickerButtonProps {
  label: string;
  currentUrl?: string | null;
  onSelect: (mediaId: string, url: string) => void;
  onRemove?: () => void;
  categoryFilter?: 'PHOTO' | 'LOGO';
}

export default function ImagePickerButton({
  label,
  currentUrl,
  onSelect,
  onRemove,
  categoryFilter,
}: ImagePickerButtonProps) {
  const [showPicker, setShowPicker] = useState(false);

  return (
    <div>
      <label className="text-xs font-medium text-gray-600 block mb-1">{label}</label>
      <div className="flex items-center gap-2">
        {currentUrl ? (
          <div className="relative w-16 h-16 rounded border overflow-hidden bg-gray-100">
            <img src={currentUrl} alt="" className="w-full h-full object-cover" />
            {onRemove && (
              <button onClick={onRemove}
                className="absolute top-0 right-0 w-4 h-4 bg-red-500 text-white text-[10px] rounded-bl flex items-center justify-center">
                &times;
              </button>
            )}
          </div>
        ) : null}
        <button type="button" onClick={() => setShowPicker(true)}
          className="px-3 py-1.5 border border-dashed border-amber-300 rounded text-xs text-amber-700 hover:bg-amber-50">
          {currentUrl ? 'Aendern' : label + ' waehlen'}
        </button>
      </div>
      {showPicker && (
        <MediaPickerModal
          isOpen={showPicker}
          onClose={() => setShowPicker(false)}
          onSelect={(media) => {
            const formats = media.formats as any;
            const url = formats?.['1:1']?.url || media.thumbnailUrl || media.url;
            onSelect(media.id, url);
            setShowPicker(false);
          }}
          categoryFilter={categoryFilter}
          title={label + ' aus Bildarchiv waehlen'}
        />
      )}
    </div>
  );
}
