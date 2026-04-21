'use client';

/**
 * Field-Komponenten für den schema-driven Design-Editor (v2).
 *
 * Jede Komponente bekommt `{ def, value, onChange, error }` und rendert
 * im Admin-Roboto-Stil (konform zu Design-Strategie 2.0). Der Stil lehnt
 * sich an die bestehenden Helper aus `design-editor.tsx` an, damit der
 * neue Inspector optisch identisch zum Legacy-Akkordeon wirkt.
 */
import React from 'react';
import type {
  FieldDef,
  BooleanField,
  SelectField,
  ColorField,
  NumberField,
  SliderField,
  TextField,
  FontField,
  MultiToggleField,
} from '../../../lib/design-templates/schemas/types';
import { FONT_OPTIONS } from '../../../lib/design-templates/schemas/shared/fonts';

const PRIMARY = 'var(--color-primary)';

// ─── Shared-Presentation ──────────────────────────────────────

function FieldLabel({ children }: { children: React.ReactNode }) {
  return <label className="block text-xs font-medium text-gray-500 mb-1">{children}</label>;
}

function FieldError({ error }: { error?: string }) {
  if (!error) return null;
  return (
    <p className="mt-1 text-xs text-red-600 flex items-center gap-1">
      <span className="material-symbols-outlined" style={{ fontSize: 14 }}>error</span>
      {error}
    </p>
  );
}

function FieldDesc({ desc }: { desc?: string }) {
  if (!desc) return null;
  return <p className="mt-0.5 text-[11px] text-gray-400 leading-snug">{desc}</p>;
}

// ─── Boolean ──────────────────────────────────────────────────

export function BooleanFieldUI({
  def,
  value,
  onChange,
}: {
  def: BooleanField;
  value: boolean;
  onChange: (v: boolean) => void;
  error?: string;
}) {
  const checked = value ?? def.default;
  return (
    <div>
      <label className="flex items-center justify-between cursor-pointer py-1">
        <span className="text-sm text-gray-700">{def.label}</span>
        <button
          type="button"
          onClick={() => onChange(!checked)}
          className="relative inline-flex h-5 w-9 items-center rounded-full transition-colors"
          style={{ backgroundColor: checked ? PRIMARY : '#D1D5DB' }}
          aria-pressed={checked}
          aria-label={def.label}
        >
          <span
            className="inline-block h-3.5 w-3.5 transform rounded-full bg-white transition-transform"
            style={{ transform: checked ? 'translateX(18px)' : 'translateX(2px)' }}
          />
        </button>
      </label>
      <FieldDesc desc={def.desc} />
    </div>
  );
}

// ─── Select ───────────────────────────────────────────────────

export function SelectFieldUI({
  def,
  value,
  onChange,
  error,
}: {
  def: SelectField;
  value: string;
  onChange: (v: string) => void;
  error?: string;
}) {
  return (
    <div>
      <FieldLabel>{def.label}</FieldLabel>
      <select
        value={value ?? def.default}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-lg border border-gray-200 px-2 py-1.5 text-sm outline-none focus:border-gray-400 bg-white"
        aria-label={def.label}
      >
        {def.options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
      <FieldDesc desc={def.desc} />
      <FieldError error={error} />
    </div>
  );
}

// ─── Color ────────────────────────────────────────────────────

export function ColorFieldUI({
  def,
  value,
  onChange,
  error,
}: {
  def: ColorField;
  value: string;
  onChange: (v: string) => void;
  error?: string;
}) {
  const current = value || def.default || '#000000';
  // <input type="color"> kann nur 6-stellige Hex; bei allowAlpha wird das
  // Alpha-Segment über das Text-Feld gepflegt.
  const colorPickerValue = current.length >= 7 ? current.slice(0, 7) : current;
  return (
    <div>
      <div className="flex items-center gap-2">
        <input
          type="color"
          value={colorPickerValue}
          onChange={(e) => {
            // Wenn allowAlpha + aktueller Wert 8-stellig: Alpha-Teil erhalten.
            if (def.allowAlpha && current.length === 9) {
              onChange(e.target.value + current.slice(7));
            } else {
              onChange(e.target.value);
            }
          }}
          className="h-8 w-8 cursor-pointer rounded border border-gray-300 p-0.5 bg-white"
          aria-label={def.label}
        />
        <div className="flex-1">
          <div className="text-xs text-gray-500">{def.label}</div>
          <input
            type="text"
            value={current}
            onChange={(e) => onChange(e.target.value)}
            className="w-full text-xs font-mono border-b border-gray-200 py-0.5 outline-none focus:border-gray-400 bg-transparent"
            placeholder={def.allowAlpha ? '#RRGGBB[AA]' : '#RRGGBB'}
          />
        </div>
      </div>
      <FieldDesc desc={def.desc} />
      <FieldError error={error} />
    </div>
  );
}

// ─── Number ───────────────────────────────────────────────────

export function NumberFieldUI({
  def,
  value,
  onChange,
  error,
}: {
  def: NumberField;
  value: number;
  onChange: (v: number) => void;
  error?: string;
}) {
  const current = typeof value === 'number' ? value : def.default;
  return (
    <div>
      <FieldLabel>
        {def.label}
        {def.unit ? <span className="text-gray-400 font-normal ml-1">({def.unit})</span> : null}
      </FieldLabel>
      <input
        type="number"
        min={def.min}
        max={def.max}
        step={def.step ?? 1}
        value={current}
        onChange={(e) => {
          const next = Number(e.target.value);
          if (!Number.isFinite(next)) return;
          onChange(next);
        }}
        className="w-full rounded-lg border border-gray-200 px-2 py-1.5 text-sm outline-none focus:border-gray-400 bg-white"
        aria-label={def.label}
      />
      <FieldDesc desc={def.desc} />
      <FieldError error={error} />
    </div>
  );
}

// ─── Slider ───────────────────────────────────────────────────

export function SliderFieldUI({
  def,
  value,
  onChange,
  error,
}: {
  def: SliderField;
  value: number;
  onChange: (v: number) => void;
  error?: string;
}) {
  const current = typeof value === 'number' ? value : def.default;
  return (
    <div>
      <div className="flex justify-between items-baseline">
        <FieldLabel>{def.label}</FieldLabel>
        <span className="text-xs text-gray-400 font-mono">
          {current}
          {def.unit || ''}
        </span>
      </div>
      <input
        type="range"
        min={def.min}
        max={def.max}
        step={def.step ?? 1}
        value={current}
        onChange={(e) => onChange(Number(e.target.value))}
        className="w-full"
        style={{ accentColor: PRIMARY }}
        aria-label={def.label}
      />
      <FieldDesc desc={def.desc} />
      <FieldError error={error} />
    </div>
  );
}

// ─── Text ─────────────────────────────────────────────────────

export function TextFieldUI({
  def,
  value,
  onChange,
  error,
}: {
  def: TextField;
  value: string;
  onChange: (v: string) => void;
  error?: string;
}) {
  const current = value ?? def.default ?? '';
  return (
    <div>
      <FieldLabel>{def.label}</FieldLabel>
      {def.multiline ? (
        <textarea
          value={current}
          maxLength={def.maxLength}
          onChange={(e) => onChange(e.target.value)}
          placeholder={def.placeholder}
          rows={3}
          className="w-full rounded-lg border border-gray-200 px-2 py-1.5 text-sm outline-none focus:border-gray-400 bg-white resize-y"
          aria-label={def.label}
        />
      ) : (
        <input
          type="text"
          value={current}
          maxLength={def.maxLength}
          onChange={(e) => onChange(e.target.value)}
          placeholder={def.placeholder}
          className="w-full rounded-lg border border-gray-200 px-2 py-1.5 text-sm outline-none focus:border-gray-400 bg-white"
          aria-label={def.label}
        />
      )}
      {def.maxLength && (
        <p className="mt-0.5 text-[11px] text-gray-400 text-right">
          {current.length}/{def.maxLength}
        </p>
      )}
      <FieldDesc desc={def.desc} />
      <FieldError error={error} />
    </div>
  );
}

// ─── Font ─────────────────────────────────────────────────────

export function FontFieldUI({
  def,
  value,
  onChange,
  error,
}: {
  def: FontField;
  value: string;
  onChange: (v: string) => void;
  error?: string;
}) {
  const current = value || def.default;
  return (
    <div>
      <FieldLabel>{def.label}</FieldLabel>
      <select
        value={current}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-lg border border-gray-200 px-2 py-1.5 text-sm outline-none focus:border-gray-400 bg-white"
        style={{ fontFamily: current }}
        aria-label={def.label}
      >
        {FONT_OPTIONS.map((o) => (
          <option key={o.value} value={o.value} style={{ fontFamily: o.value }}>
            {o.label}
          </option>
        ))}
      </select>
      <FieldDesc desc={def.desc} />
      <FieldError error={error} />
    </div>
  );
}

// ─── MultiToggle ──────────────────────────────────────────────

export function MultiToggleFieldUI({
  def,
  value,
  onChange,
  error,
}: {
  def: MultiToggleField;
  value: string[];
  onChange: (v: string[]) => void;
  error?: string;
}) {
  const current = Array.isArray(value) ? value : def.default;
  const toggle = (val: string) => {
    if (current.includes(val)) {
      onChange(current.filter((v) => v !== val));
    } else {
      onChange([...current, val]);
    }
  };
  return (
    <div>
      <FieldLabel>{def.label}</FieldLabel>
      <div className="flex flex-wrap gap-1.5">
        {def.options.map((o) => {
          const active = current.includes(o.value);
          return (
            <button
              key={o.value}
              type="button"
              onClick={() => toggle(o.value)}
              className="rounded-full border px-3 py-1 text-xs font-medium transition-colors"
              style={{
                borderColor: active ? PRIMARY : '#E5E7EB',
                backgroundColor: active ? 'rgba(221,60,113,0.08)' : '#FFFFFF',
                color: active ? PRIMARY : '#4B5563',
              }}
              aria-pressed={active}
              aria-label={o.label}
            >
              {o.label}
            </button>
          );
        })}
      </div>
      <FieldDesc desc={def.desc} />
      <FieldError error={error} />
    </div>
  );
}

// ─── Dispatcher ───────────────────────────────────────────────

export function FieldRenderer({
  def,
  value,
  onChange,
  error,
}: {
  def: FieldDef;
  value: any;
  onChange: (v: any) => void;
  error?: string;
}) {
  switch (def.type) {
    case 'boolean':
      return <BooleanFieldUI def={def} value={value} onChange={onChange} error={error} />;
    case 'select':
      return <SelectFieldUI def={def} value={value} onChange={onChange} error={error} />;
    case 'color':
      return <ColorFieldUI def={def} value={value} onChange={onChange} error={error} />;
    case 'number':
      return <NumberFieldUI def={def} value={value} onChange={onChange} error={error} />;
    case 'slider':
      return <SliderFieldUI def={def} value={value} onChange={onChange} error={error} />;
    case 'text':
      return <TextFieldUI def={def} value={value} onChange={onChange} error={error} />;
    case 'font':
      return <FontFieldUI def={def} value={value} onChange={onChange} error={error} />;
    case 'multitoggle':
      return <MultiToggleFieldUI def={def} value={value} onChange={onChange} error={error} />;
    default: {
      // Exhaustiveness-Check — sollte bei valider FieldDef nie erreicht werden.
      const _exhaustive: never = def;
      return null;
    }
  }
}
