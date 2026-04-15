#!/usr/bin/env python3
"""Schritt 5: Template-Picker-Drawer in menu-editor.tsx + page.tsx einbauen."""
import sys
from pathlib import Path

EDITOR = Path("src/components/admin/menu-editor.tsx")
PAGE = Path("src/app/admin/menus/[id]/page.tsx")


def patch(path: Path, old: str, new: str, label: str) -> None:
    text = path.read_text(encoding="utf-8")
    if new.strip() and new in text:
        print(f"[skip] {label}: bereits angewendet")
        return
    if old not in text:
        print(f"[FEHLER] {label}: Block nicht gefunden in {path}")
        sys.exit(1)
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"[ok]   {label}")


# --- Backup ---
for p in (EDITOR, PAGE):
    bak = p.with_suffix(p.suffix + ".bak-s5")
    bak.write_text(p.read_text(encoding="utf-8"), encoding="utf-8")

# --- menu-editor.tsx: Import ---
patch(
    EDITOR,
    "import Link from 'next/link';\n",
    "import Link from 'next/link';\nimport TemplatePickerDrawer from './template-picker-drawer';\n",
    "Import TemplatePickerDrawer",
)

# --- menu-editor.tsx: MenuInfo-Type um templateId erweitern ---
patch(
    EDITOR,
    "publicUrl: string; qrCodes:",
    "publicUrl: string; templateId: string | null; qrCodes:",
    "MenuInfo.templateId",
)

# --- menu-editor.tsx: drawerOpen-State ---
patch(
    EDITOR,
    "  const [groupFilter, setGroupFilter] = useState('');\n",
    "  const [groupFilter, setGroupFilter] = useState('');\n  const [drawerOpen, setDrawerOpen] = useState(false);\n",
    "State drawerOpen",
)

# --- menu-editor.tsx: Link → Button + Drawer ---
OLD_LINK = """              <Link
                href={`/admin/menus/${menu.id}/design`}
                className="rounded-lg px-3 py-1.5 text-sm font-medium inline-flex items-center gap-1 transition-colors"
                style={{
                  border: '1px solid var(--color-primary)',
                  color: 'var(--color-primary)',
                  backgroundColor: 'transparent',
                }}
                onMouseEnter={e => { e.currentTarget.style.backgroundColor = 'rgba(221,60,113,0.08)'; }}
                onMouseLeave={e => { e.currentTarget.style.backgroundColor = 'transparent'; }}
              >
                <span className="material-symbols-outlined" style={{ fontSize: 16, fontVariationSettings: "'FILL' 0, 'wght' 500" }}>palette</span>
                Design
              </Link>"""

NEW_LINK = """              <button
                type="button"
                onClick={() => setDrawerOpen(true)}
                className="rounded-lg px-3 py-1.5 text-sm font-medium inline-flex items-center gap-1 transition-colors"
                style={{
                  border: '1px solid var(--color-primary)',
                  color: 'var(--color-primary)',
                  backgroundColor: 'transparent',
                }}
                onMouseEnter={e => { e.currentTarget.style.backgroundColor = 'rgba(221,60,113,0.08)'; }}
                onMouseLeave={e => { e.currentTarget.style.backgroundColor = 'transparent'; }}
              >
                <span className="material-symbols-outlined" style={{ fontSize: 16, fontVariationSettings: "'FILL' 0, 'wght' 500" }}>palette</span>
                Vorlage
              </button>
              {drawerOpen && (
                <TemplatePickerDrawer
                  menuId={menu.id}
                  currentTemplateId={menu.templateId}
                  onClose={() => setDrawerOpen(false)}
                />
              )}"""

patch(EDITOR, OLD_LINK, NEW_LINK, "Link → Button + Drawer")

# --- page.tsx: templateId in menuData ---
patch(
    PAGE,
    "publicUrl: `/${tenant.slug}/${menu.location.slug}/${menu.slug}`,\n    qrCodes:",
    "publicUrl: `/${tenant.slug}/${menu.location.slug}/${menu.slug}`,\n    templateId: menu.templateId || null,\n    qrCodes:",
    "page.tsx templateId",
)

print("\nAlle Patches erfolgreich.")
