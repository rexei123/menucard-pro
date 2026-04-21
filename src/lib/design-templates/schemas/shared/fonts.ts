/**
 * Zentrale Schrift-Whitelist für den Design-Editor.
 *
 * Jede Schrift wird via `next/font/google` in `src/app/layout.tsx` geladen
 * und ist via CSS-Variable `--font-{key}` global verfügbar.
 *
 * Drift-Warnung: aktuell ist die Liste zusätzlich in
 * `src/components/admin/design-editor.tsx` als `FONTS`-Konstante dupliziert.
 * Phase-1-Sprint-3 zieht diese Liste dort an und importiert aus hier.
 */

export type FontCategory = 'serif' | 'sans' | 'display';

export interface FontEntry {
  /** Exakter Name, wie er in `font-family` verwendet wird */
  value: string;
  /** Anzeige-Label im Editor */
  label: string;
  /** Kategorie für Gruppierung/Filter */
  type: FontCategory;
}

export const FONTS: FontEntry[] = [
  // Serif (Fine-Dining)
  { value: 'Playfair Display', label: 'Playfair Display', type: 'serif' },
  { value: 'Cormorant Garamond', label: 'Cormorant Garamond', type: 'serif' },
  { value: 'Libre Baskerville', label: 'Libre Baskerville', type: 'serif' },

  // Sans (Neutral, lesbar)
  { value: 'Inter', label: 'Inter', type: 'sans' },
  { value: 'Source Sans 3', label: 'Source Sans 3', type: 'sans' },
  { value: 'Lato', label: 'Lato', type: 'sans' },
  { value: 'Open Sans', label: 'Open Sans', type: 'sans' },

  // Display (Charakter, Moderne)
  { value: 'Montserrat', label: 'Montserrat', type: 'display' },
  { value: 'Raleway', label: 'Raleway', type: 'display' },
  { value: 'Josefin Sans', label: 'Josefin Sans', type: 'display' },
];

export const FONT_VALUES: string[] = FONTS.map((f) => f.value);

export function isKnownFont(value: string): boolean {
  return FONT_VALUES.includes(value);
}

/** Select-Options für den SchemaForm-Renderer */
export const FONT_OPTIONS = FONTS.map((f) => ({
  label: `${f.label} (${f.type})`,
  value: f.value,
}));
