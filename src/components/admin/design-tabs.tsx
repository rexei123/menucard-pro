'use client';

import { useState } from 'react';
import DesignEditor from '@/components/admin/design-editor';
import AnalogDesignEditor from '@/components/admin/analog-design-editor';

type Props = {
  menuId: string;
  tenantSlug: string;
  locationSlug: string;
  menuSlug: string;
};

export default function DesignTabs({ menuId, tenantSlug, locationSlug, menuSlug }: Props) {
  const [activeTab, setActiveTab] = useState<'digital' | 'pdf'>('digital');

  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <div className="flex justify-center py-3 border-b bg-gray-50">
        <div className="flex bg-gray-200 rounded-lg p-1">
          <button onClick={() => setActiveTab('digital')}
            className={`px-5 py-2 rounded-md text-sm font-medium transition-all ${
              activeTab === 'digital' ? 'bg-white shadow-sm text-blue-600' : 'text-gray-600 hover:text-gray-900'
            }`}>
            Digital
          </button>
          <button onClick={() => setActiveTab('pdf')}
            className={`px-5 py-2 rounded-md text-sm font-medium transition-all ${
              activeTab === 'pdf' ? 'bg-white shadow-sm text-blue-600' : 'text-gray-600 hover:text-gray-900'
            }`}>
            PDF / Druck
          </button>
        </div>
      </div>
      <div className="flex-1 overflow-hidden">
        {activeTab === 'digital' ? (
          <DesignEditor menuId={menuId} tenantSlug={tenantSlug} locationSlug={locationSlug} menuSlug={menuSlug} />
        ) : (
          <AnalogDesignEditor menuId={menuId} />
        )}
      </div>
    </div>
  );
}
