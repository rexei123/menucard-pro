'use client';
/**
 * Design-Editor v2 — Schema-driven 3-Spalten-Shell.
 *
 *  ┌────────────┬──────────────────────────┬────────────────┐
 *  │ Tab-Nav    │ Live-Preview (iframe)    │ SchemaForm     │
 *  │ (Schemas)  │                          │ Inspector      │
 *  └────────────┴──────────────────────────┴────────────────┘
 *
 * Parallel-Komponente zum Legacy-Editor. Aktivierung über Feature-Flag
 * (URL-Query `?v=legacy` oder `?v=new`), damit beide Versionen
 * während der Migration nebeneinander bestehen können.
 *
 * Siehe `docs/FEATURE-DESIGN-EDITOR-V2-PLAN.md` (Sprint 3).
 */
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  ALL_SCHEMAS,
  GLOBAL_SCHEMAS,
  COMPONENT_SCHEMAS,
  extractSchemaConfig,
  mergeSchemaConfig,
  applyDefaults,
  type ComponentSchema,
} from '@/lib/design-templates/schemas';
import { SchemaForm } from './schema-form';

// ─── Types (minimal, parallel zur Legacy-Definition) ─────────

type MenuModeProps = {
  mode?: 'menu';
  menuId: string;
  tenantSlug: string;
  locationSlug: string;
  menuSlug: string;
};
type TemplateModeProps = {
  mode: 'template';
  templateId: string;
  initialName: string;
  initialBaseType: string;
  previewUrl: string | null;
  previewPdfUrl?: string | null;
};
export type Props = MenuModeProps | TemplateModeProps;

// ─── API-Adapter — identisch zum Legacy-Editor ───────────────

function useApi(props: Props) {
  return useMemo(() => {
    if (props.mode === 'template') {
      return {
        mode: 'template' as const,
        load: async () => {
          const res = await fetch(`/api/v1/design-templates/${props.templateId}`);
          if (!res.ok) throw new Error('Laden fehlgeschlagen');
          const data = await res.json();
          const t = data.template;
          return {
            fullConfig: t.config || { digital: {}, analog: {} },
            meta: { name: t.name, baseType: t.baseType, type: t.type },
          };
        },
        save: async (fullConfig: any) => {
          const res = await fetch(`/api/v1/design-templates/${props.templateId}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ config: fullConfig }),
          });
          if (!res.ok) {
            const err = await res.json().catch(() => ({}));
            throw new Error(err.error || 'Speichern fehlgeschlagen');
          }
          return res.json();
        },
      };
    }
    const p = props as MenuModeProps;
    return {
      mode: 'menu' as const,
      load: async () => {
        const res = await fetch(`/api/v1/menus/${p.menuId}/design`);
        if (!res.ok) throw new Error('Laden fehlgeschlagen');
        const data = await res.json();
        return {
          fullConfig: data.designConfig || { digital: data.digital || data, analog: {} },
          meta: { name: '', baseType: '', type: 'MENU' },
        };
      },
      save: async (fullConfig: any) => {
        const res = await fetch(`/api/v1/menus/${p.menuId}/design`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ designConfig: fullConfig }),
        });
        if (!res.ok) throw new Error('Speichern fehlgeschlagen');
        return res.json();
      },
    };
  }, [props]);
}

// ─── Editor ─────────────────────────────────────────────────

export default function DesignEditorV2(props: Props) {
  const router = useRouter();
  const api = useApi(props);
  const isTemplateMode = api.mode === 'template';
  const previewUrl = isTemplateMode ? (props as TemplateModeProps).previewUrl : null;

  const [fullConfig, setFullConfig] = useState<any | null>(null);
  const [activeSchemaId, setActiveSchemaId] = useState<string>(ALL_SCHEMAS[0].id);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [savedAt, setSavedAt] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [templateName, setTemplateName] = useState(isTemplateMode ? (props as TemplateModeProps).initialName : '');

  const iframeRef = useRef<HTMLIFrameElement>(null);
  const saveTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const refreshTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Load
  useEffect(() => {
    let active = true;
    api
      .load()
      .then((data) => {
        if (!active) return;
        setFullConfig(data.fullConfig);
        if (isTemplateMode && data.meta?.name) setTemplateName(data.meta.name);
        setLoading(false);
      })
      .catch((e) => {
        setError(e.message);
        setLoading(false);
      });
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const scheduleSave = useCallback(
    (nextFull: any) => {
      if (saveTimerRef.current) clearTimeout(saveTimerRef.current);
      saveTimerRef.current = setTimeout(async () => {
        setSaving(true);
        setError(null);
        try {
          await api.save(nextFull);
          setSavedAt(Date.now());
          if (refreshTimerRef.current) clearTimeout(refreshTimerRef.current);
          refreshTimerRef.current = setTimeout(() => {
            if (iframeRef.current) iframeRef.current.src = iframeRef.current.src;
          }, 150);
        } catch (e: any) {
          setError(e.message || 'Speichern fehlgeschlagen');
        } finally {
          setSaving(false);
        }
      }, 800);
    },
    [api],
  );

  const activeSchema = useMemo<ComponentSchema | undefined>(
    () => ALL_SCHEMAS.find((s) => s.id === activeSchemaId),
    [activeSchemaId],
  );

  /** Flat-Config für das aktive Schema mit Defaults für fehlende Felder */
  const activeFlatConfig = useMemo(() => {
    if (!fullConfig || !activeSchema) return {};
    const extracted = extractSchemaConfig(fullConfig, activeSchema);
    return applyDefaults(extracted, activeSchema);
  }, [fullConfig, activeSchema]);

  const handleSchemaChange = useCallback(
    (nextFlat: Record<string, any>) => {
      if (!activeSchema || !fullConfig) return;
      const nextFull = mergeSchemaConfig(fullConfig, activeSchema, nextFlat);
      setFullConfig(nextFull);
      scheduleSave(nextFull);
    },
    [activeSchema, fullConfig, scheduleSave],
  );

  // ─── Render ─────────────────────────────────────────────

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <span className="text-sm text-gray-500">Lade Design-Editor…</span>
      </div>
    );
  }

  if (error && !fullConfig) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 max-w-md">
          <p className="text-sm font-semibold text-red-700 mb-1">Fehler beim Laden</p>
          <p className="text-xs text-red-600">{error}</p>
          <button
            type="button"
            onClick={() => router.refresh()}
            className="mt-3 rounded-lg px-3 py-1.5 text-xs font-medium bg-red-600 text-white"
          >
            Neu laden
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-screen bg-gray-50">
      {/* Topbar */}
      <header className="flex items-center justify-between gap-4 px-4 py-2 bg-white border-b border-gray-200">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => router.push(isTemplateMode ? '/admin/design' : '/admin/menus')}
            className="text-gray-500 hover:text-gray-700"
            aria-label="Zurück"
          >
            <span className="material-symbols-outlined" style={{ fontSize: 20 }}>
              arrow_back
            </span>
          </button>
          <h1 className="text-sm font-semibold text-gray-800">
            Design-Editor v2
            {templateName && <span className="text-gray-400 font-normal ml-2">· {templateName}</span>}
          </h1>
        </div>
        <div className="flex items-center gap-3 text-xs">
          {saving && (
            <span className="text-gray-500 flex items-center gap-1">
              <span className="material-symbols-outlined animate-spin" style={{ fontSize: 14 }}>
                sync
              </span>
              Speichere…
            </span>
          )}
          {!saving && savedAt && (
            <span className="text-green-600 flex items-center gap-1">
              <span className="material-symbols-outlined" style={{ fontSize: 14 }}>
                check_circle
              </span>
              Gespeichert
            </span>
          )}
          {error && (
            <span className="text-red-600 flex items-center gap-1">
              <span className="material-symbols-outlined" style={{ fontSize: 14 }}>
                error
              </span>
              {error}
            </span>
          )}
          <a
            href={`?v=legacy`}
            className="rounded-lg px-2 py-1 text-[11px] text-gray-600 hover:bg-gray-100 border border-gray-200"
            title="Zurück zum alten Akkordeon-Editor"
          >
            Legacy-Editor
          </a>
        </div>
      </header>

      {/* Main 3-column layout */}
      <div className="flex-1 flex overflow-hidden">
        {/* Links: Tab-Nav */}
        <nav className="w-56 shrink-0 border-r border-gray-200 bg-white overflow-y-auto">
          <div className="px-3 py-2 text-[10px] font-semibold text-gray-400 uppercase tracking-wider">
            Globale Einstellungen
          </div>
          {GLOBAL_SCHEMAS.map((s) => (
            <SchemaTab
              key={s.id}
              schema={s}
              active={s.id === activeSchemaId}
              onClick={() => setActiveSchemaId(s.id)}
            />
          ))}
          <div className="px-3 py-2 mt-2 text-[10px] font-semibold text-gray-400 uppercase tracking-wider">
            Komponenten
          </div>
          {COMPONENT_SCHEMAS.map((s) => (
            <SchemaTab
              key={s.id}
              schema={s}
              active={s.id === activeSchemaId}
              onClick={() => setActiveSchemaId(s.id)}
            />
          ))}
        </nav>

        {/* Mitte: Preview */}
        <section className="flex-1 min-w-0 bg-gray-100 flex flex-col overflow-hidden">
          {previewUrl ? (
            <iframe
              ref={iframeRef}
              src={previewUrl}
              className="flex-1 w-full bg-white"
              style={{ border: 'none' }}
              title="Live-Vorschau"
            />
          ) : (
            <div className="flex-1 flex items-center justify-center text-gray-400 text-sm">
              <div className="text-center">
                <span className="material-symbols-outlined block mb-2" style={{ fontSize: 48 }}>
                  preview
                </span>
                <p>Keine Vorschau verfügbar</p>
                <p className="text-xs mt-1">Weise dieses Template einer aktiven Karte zu, um eine Live-Vorschau zu sehen.</p>
              </div>
            </div>
          )}
        </section>

        {/* Rechts: SchemaForm-Inspector */}
        <aside className="w-[380px] shrink-0 border-l border-gray-200 bg-white overflow-y-auto">
          <div className="p-4">
            {activeSchema && (
              <>
                <div className="mb-3 pb-3 border-b border-gray-100">
                  <h2 className="text-sm font-semibold text-gray-800 flex items-center gap-2">
                    {activeSchema.icon && (
                      <span className="material-symbols-outlined text-gray-500" style={{ fontSize: 18 }}>
                        {activeSchema.icon}
                      </span>
                    )}
                    {activeSchema.label}
                  </h2>
                  {activeSchema.desc && (
                    <p className="mt-1 text-[11px] text-gray-500 leading-snug">{activeSchema.desc}</p>
                  )}
                </div>
                <SchemaForm
                  schema={activeSchema}
                  config={activeFlatConfig}
                  onChange={handleSchemaChange}
                />
              </>
            )}
          </div>
        </aside>
      </div>
    </div>
  );
}

// ─── Helper-Komponenten ─────────────────────────────────────

function SchemaTab({
  schema,
  active,
  onClick,
}: {
  schema: ComponentSchema;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="w-full flex items-center gap-2 px-3 py-2 text-left text-sm transition-colors"
      style={{
        backgroundColor: active ? 'rgba(221,60,113,0.08)' : 'transparent',
        color: active ? 'var(--color-primary)' : '#374151',
        borderLeft: active ? '3px solid var(--color-primary)' : '3px solid transparent',
      }}
    >
      {schema.icon && (
        <span className="material-symbols-outlined shrink-0" style={{ fontSize: 18 }}>
          {schema.icon}
        </span>
      )}
      <span className="truncate">{schema.label}</span>
    </button>
  );
}
