'use client';

/**
 * SchemaForm — generischer Renderer für ComponentSchema.
 *
 * Nimmt ein Schema + den aktuellen Config-Teilbaum, generiert daraus:
 *  - pro Gruppe eine klappbare Sektion
 *  - pro Feld die passende Field-Komponente (fields.tsx)
 *  - Validierungs-Feedback via validateSchema
 *  - visibleIf-Auswertung pro Feld
 *
 * Änderungen werden über `onChange(nextConfig)` nach oben gereicht.
 */
import React, { useMemo, useState } from 'react';
import type { ComponentSchema } from '../../../lib/design-templates/schemas/types';
import { validateSchema } from '../../../lib/design-templates/schemas/validator';
import { FieldRenderer } from './fields';

export interface SchemaFormProps {
  schema: ComponentSchema;
  /** Aktueller Config-Stand für dieses Schema (flaches Objekt: fieldKey → value) */
  config: Record<string, any>;
  /** Callback: wird mit dem neuen Config-Objekt aufgerufen, wenn sich ein Feld ändert */
  onChange: (nextConfig: Record<string, any>) => void;
  /** Wenn gesetzt, zeigt zusätzlich die Validierungs-Errors pro Feld an */
  showValidation?: boolean;
  /** Optional: Start-Zustand (welche Gruppen sind offen). Default: alle offen */
  initialOpenGroups?: string[];
}

export function SchemaForm({
  schema,
  config,
  onChange,
  showValidation = true,
  initialOpenGroups,
}: SchemaFormProps) {
  const [openGroups, setOpenGroups] = useState<Set<string>>(
    () => new Set(initialOpenGroups ?? schema.groups.map((g) => g.id)),
  );

  const validation = useMemo(
    () => (showValidation ? validateSchema(config, schema, { mode: 'lenient' }) : { valid: true, errors: [] }),
    [config, schema, showValidation],
  );

  // Map: fieldKey → message (erste gefundene Fehlermeldung)
  const errorMap = useMemo(() => {
    const m = new Map<string, string>();
    for (const e of validation.errors) {
      if (!m.has(e.field)) m.set(e.field, e.message);
    }
    return m;
  }, [validation]);

  const toggleGroup = (id: string) => {
    setOpenGroups((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const handleFieldChange = (fieldKey: string, value: any) => {
    onChange({ ...config, [fieldKey]: value });
  };

  return (
    <div className="space-y-3" data-schema-id={schema.id}>
      {schema.groups.map((group) => {
        const isOpen = openGroups.has(group.id);
        // Zähle sichtbare Felder in dieser Gruppe
        const visibleFields = Object.entries(group.fields).filter(([, def]) =>
          def.visibleIf ? def.visibleIf(config) : true,
        );
        if (visibleFields.length === 0) return null;

        return (
          <section
            key={group.id}
            className="rounded-lg border border-gray-200 bg-white overflow-hidden"
            data-group-id={group.id}
          >
            <button
              type="button"
              onClick={() => toggleGroup(group.id)}
              className="w-full flex items-center justify-between gap-2 px-3 py-2 bg-gray-50 hover:bg-gray-100 transition-colors text-left"
              aria-expanded={isOpen}
            >
              <div className="flex flex-col">
                <span className="text-sm font-semibold text-gray-800">{group.label}</span>
                {group.desc && <span className="text-[11px] text-gray-500">{group.desc}</span>}
              </div>
              <span
                className="material-symbols-outlined text-gray-400"
                style={{ fontSize: 20, transform: isOpen ? 'rotate(180deg)' : 'none', transition: 'transform 150ms' }}
              >
                expand_more
              </span>
            </button>
            {isOpen && (
              <div className="px-3 py-3 space-y-3">
                {visibleFields.map(([fieldKey, def]) => (
                  <FieldRenderer
                    key={fieldKey}
                    def={def}
                    value={config[fieldKey]}
                    onChange={(v) => handleFieldChange(fieldKey, v)}
                    error={errorMap.get(fieldKey)}
                  />
                ))}
              </div>
            )}
          </section>
        );
      })}
      {showValidation && !validation.valid && validation.errors.length > 0 && (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2">
          <p className="text-xs font-semibold text-red-700 mb-1 flex items-center gap-1">
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>error</span>
            {validation.errors.length} Validierungsfehler
          </p>
          <ul className="text-[11px] text-red-700 space-y-0.5 list-disc list-inside">
            {validation.errors.slice(0, 5).map((e, i) => (
              <li key={i}>
                <span className="font-mono">{e.field}</span>: {e.message}
              </li>
            ))}
            {validation.errors.length > 5 && (
              <li className="italic">… und {validation.errors.length - 5} weitere</li>
            )}
          </ul>
        </div>
      )}
    </div>
  );
}
