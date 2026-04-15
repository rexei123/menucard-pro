'use client';
import { useEffect, useState } from 'react';

type Template = {
  id: string;
  name: string;
  description?: string | null;
  type: 'SYSTEM' | 'CUSTOM';
  baseType: string;
  isArchived: boolean;
};

export default function TemplatePickerDrawer({
  menuId,
  currentTemplateId,
  onClose,
}: {
  menuId: string;
  currentTemplateId: string | null;
  onClose: () => void;
}) {
  const [templates, setTemplates] = useState<Template[]>([]);
  const [selected, setSelected] = useState<string | null>(currentTemplateId);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetch('/api/v1/design-templates')
      .then(r => r.json())
      .then(data => {
        const list: Template[] = Array.isArray(data) ? data : (data.templates || []);
        setTemplates(list.filter(t => !t.isArchived));
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const save = async () => {
    if (!selected || selected === currentTemplateId) { onClose(); return; }
    setSaving(true);
    const res = await fetch(`/api/v1/menus/${menuId}/template`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ templateId: selected }),
    });
    setSaving(false);
    if (res.ok) {
      window.location.reload();
    } else {
      alert('Speichern fehlgeschlagen');
    }
  };

  const systemTemplates = templates.filter(t => t.type === 'SYSTEM');
  const customTemplates = templates.filter(t => t.type === 'CUSTOM');

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative w-full max-w-md bg-white h-full overflow-y-auto shadow-2xl flex flex-col">
        <div className="sticky top-0 bg-white border-b border-gray-100 px-6 py-4 flex items-center justify-between z-10">
          <div>
            <h2 className="text-xl font-bold" style={{ fontFamily: "'Playfair Display', serif" }}>Design-Vorlage</h2>
            <p className="text-xs text-gray-500 mt-0.5">Vorlage für diese Karte wählen</p>
          </div>
          <button onClick={onClose} className="rounded-lg p-1.5 hover:bg-gray-100" aria-label="Schließen">
            <span className="material-symbols-outlined" style={{ fontSize: 20 }}>close</span>
          </button>
        </div>

        <div className="flex-1 p-6 space-y-6">
          {loading && <p className="text-sm text-gray-500">Lade Vorlagen …</p>}
          {!loading && templates.length === 0 && (
            <p className="text-sm text-gray-500">Keine aktiven Vorlagen vorhanden.</p>
          )}

          {systemTemplates.length > 0 && (
            <section>
              <h3 className="text-xs font-semibold uppercase tracking-wider text-gray-500 mb-2">System-Vorlagen</h3>
              <div className="space-y-2">
                {systemTemplates.map(t => renderCard(t, selected, setSelected, currentTemplateId))}
              </div>
            </section>
          )}

          {customTemplates.length > 0 && (
            <section>
              <h3 className="text-xs font-semibold uppercase tracking-wider text-gray-500 mb-2">Eigene Vorlagen</h3>
              <div className="space-y-2">
                {customTemplates.map(t => renderCard(t, selected, setSelected, currentTemplateId))}
              </div>
            </section>
          )}
        </div>

        <div className="sticky bottom-0 bg-white border-t border-gray-100 px-6 py-4 flex gap-2">
          <button onClick={onClose} className="flex-1 rounded-lg border border-gray-200 px-4 py-2 text-sm font-medium hover:bg-gray-50">
            Abbrechen
          </button>
          <button
            onClick={save}
            disabled={saving || !selected || selected === currentTemplateId}
            className="flex-1 rounded-lg px-4 py-2 text-sm font-medium text-white transition-opacity disabled:opacity-50"
            style={{ backgroundColor: 'var(--color-primary)' }}
          >
            {saving ? 'Speichern …' : 'Übernehmen'}
          </button>
        </div>
      </div>
    </div>
  );
}

function renderCard(
  t: Template,
  selected: string | null,
  setSelected: (id: string) => void,
  currentTemplateId: string | null,
) {
  const active = selected === t.id;
  const isCurrent = t.id === currentTemplateId;
  return (
    <button
      key={t.id}
      type="button"
      onClick={() => setSelected(t.id)}
      className="w-full text-left rounded-xl border p-4 transition-all"
      style={{
        borderColor: active ? 'var(--color-primary)' : '#E5E7EB',
        backgroundColor: active ? 'rgba(221,60,113,0.04)' : 'white',
        boxShadow: active ? '0 0 0 2px rgba(221,60,113,0.15)' : 'none',
      }}
    >
      <div className="flex items-center justify-between mb-1">
        <span className="font-semibold text-gray-900">{t.name}</span>
        {isCurrent && (
          <span className="text-xs px-2 py-0.5 rounded-full" style={{ backgroundColor: 'rgba(221,60,113,0.1)', color: 'var(--color-primary)' }}>
            Aktuell
          </span>
        )}
      </div>
      {t.description && <p className="text-sm text-gray-500">{t.description}</p>}
      <p className="text-xs text-gray-400 mt-2">Basis: {t.baseType}</p>
    </button>
  );
}
