'use client';

interface IconProps {
  name: string;
  size?: number;
  weight?: number;
  fill?: boolean;
  className?: string;
  onClick?: () => void;
}

export function Icon({
  name,
  size = 24,
  weight = 400,
  fill = false,
  className = '',
  onClick,
}: IconProps) {
  return (
    <span
      className={`material-symbols-outlined select-none ${className}`}
      style={{
        fontSize: size,
        fontVariationSettings: `'FILL' ${fill ? 1 : 0}, 'wght' ${weight}, 'GRAD' 0, 'opsz' ${size}`,
        lineHeight: 1,
      }}
      onClick={onClick}
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      {name}
    </span>
  );
}

/* Icon-Mapping: Emojis → Material Symbols
 *
 * Admin Icon-Bar:
 *   📊 Dashboard      → dashboard
 *   📦 Produkte       → inventory_2
 *   📋 Karten         → menu_book
 *   📱 QR-Codes       → qr_code_2
 *   🖼️ Bildarchiv     → photo_library
 *   📈 Analytics      → analytics
 *   ⚙️ Einstellungen  → settings
 *   🔄 Neu laden      → refresh
 *   🚪 Logout         → logout
 *
 * Produkttypen:
 *   🍷 Wein           → wine_bar
 *   🍸 Getränk        → local_bar
 *   🍽️ Speise         → restaurant
 *   ☕ Heißgetränk    → coffee
 *   🍺 Bier           → sports_bar
 *
 * Status & Aktionen:
 *   ✅ Aktiv          → check_circle (fill)
 *   🚫 Ausgetrunken   → block
 *   ⭐ Hauptbild      → star (fill)
 *   ✂️ Crop           → crop
 *   🗑️ Löschen        → delete
 *   💾 Speichern      → save
 *   ➕ Hinzufügen     → add
 *   ✕ Schließen      → close
 *   🔍 Suche          → search
 *   📤 Upload         → upload
 *   🌐 Web            → language
 *
 * Gästeansicht Kategorien:
 *   Vorspeisen        → tapas
 *   Hauptgerichte     → restaurant
 *   Pasta             → ramen_dining
 *   Desserts          → cake
 *   Weinkarte         → wine_bar
 *   Kaffee & Digestif → coffee
 *   Salate            → eco
 *   Burger            → lunch_dining
 *   Pizza             → local_pizza
 *
 * Allergene:
 *   Gluten            → grain
 *   Laktose           → water_drop
 *   Nüsse             → psychiatry
 *   Fisch             → set_meal
 *   Eier              → egg
 */
