#!/usr/bin/env python3
"""
Schritt 2a – UI-Verbesserungen:
1) Tab-Leiste: flex-wrap statt horizontales Scrollen (alle 8 Tabs sichtbar)
2) PDF-Vorschau: neuer 3. Preview-Toggle neben Handy/Desktop
3) Template-Edit-Seite: previewPdfUrl berechnen und durchreichen
"""
import sys
from pathlib import Path

ROOT = Path("/var/www/menucard-pro")
EDITOR = ROOT / "src/components/admin/design-editor.tsx"
EDIT_PAGE = ROOT / "src/app/admin/design/[id]/edit/page.tsx"

def patch_exact(path: Path, old: str, new: str, label: str) -> bool:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count == 0:
        print(f"  [SKIP] {label}: Muster nicht gefunden")
        return False
    if count > 1:
        print(f"  [FAIL] {label}: Muster {count}x gefunden (muss eindeutig sein)")
        return False
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"  [OK]   {label}")
    return True

def main():
    for f in (EDITOR, EDIT_PAGE):
        if not f.exists():
            print(f"FEHLER: {f} nicht gefunden"); sys.exit(1)

    # Backups
    for f in (EDITOR, EDIT_PAGE):
        bak = f.with_suffix(f.suffix + ".bak2")
        bak.write_text(f.read_text(encoding="utf-8"), encoding="utf-8")
        print(f"[BACKUP] {bak}")

    all_ok = True

    # ─────────────────────────────────────────────────
    # design-editor.tsx
    # ─────────────────────────────────────────────────

    # 1) TemplateModeProps: previewPdfUrl ergänzen
    old1 = (
        "  initialBaseType: string;\n"
        "  previewUrl: string | null;\n"
        "};"
    )
    new1 = (
        "  initialBaseType: string;\n"
        "  previewUrl: string | null;\n"
        "  previewPdfUrl?: string | null;\n"
        "};"
    )
    all_ok &= patch_exact(EDITOR, old1, new1, "TemplateModeProps +previewPdfUrl")

    # 2) previewMode: 'pdf' hinzufügen
    old2 = "const [previewMode, setPreviewMode] = useState<'mobile' | 'desktop'>('mobile');"
    new2 = "const [previewMode, setPreviewMode] = useState<'mobile' | 'desktop' | 'pdf'>('mobile');"
    all_ok &= patch_exact(EDITOR, old2, new2, "previewMode Typ +pdf")

    # 3) previewPdfUrl ableiten (nach isTemplateMode)
    old3 = "  const isTemplateMode = api.mode === 'template';"
    new3 = (
        "  const isTemplateMode = api.mode === 'template';\n"
        "  const previewPdfUrl = isTemplateMode\n"
        "    ? ((props as TemplateModeProps).previewPdfUrl ?? null)\n"
        "    : null;"
    )
    all_ok &= patch_exact(EDITOR, old3, new3, "previewPdfUrl ableiten")

    # 4) Tab-Container: flex-wrap statt overflow-x-auto
    old4 = (
        "          <div className=\"px-2 overflow-x-auto\">\n"
        "            <div className=\"flex gap-1\">"
    )
    new4 = (
        "          <div className=\"px-2\">\n"
        "            <div className=\"flex flex-wrap gap-1\">"
    )
    all_ok &= patch_exact(EDITOR, old4, new4, "Tab-Leiste flex-wrap")

    # 5) Tab-Buttons kompakter (spart Platz damit 8 Tabs gut passen)
    old5 = "                    className=\"flex items-center gap-1.5 whitespace-nowrap rounded-t-lg px-3 py-2 text-xs font-medium transition-colors\""
    new5 = "                    className=\"flex items-center gap-1 whitespace-nowrap rounded-t-lg px-2.5 py-1.5 text-xs font-medium transition-colors\""
    all_ok &= patch_exact(EDITOR, old5, new5, "Tab-Button kompakter")

    # 6) PDF-Preview-Toggle neben Handy/Desktop einfügen
    old6 = "            <PreviewToggle active={previewMode === 'desktop'} onClick={() => setPreviewMode('desktop')} icon=\"desktop_windows\" label=\"Desktop\" />"
    new6 = (
        "            <PreviewToggle active={previewMode === 'desktop'} onClick={() => setPreviewMode('desktop')} icon=\"desktop_windows\" label=\"Desktop\" />\n"
        "            {previewPdfUrl && (\n"
        "              <PreviewToggle active={previewMode === 'pdf'} onClick={() => setPreviewMode('pdf')} icon=\"picture_as_pdf\" label=\"PDF\" />\n"
        "            )}"
    )
    all_ok &= patch_exact(EDITOR, old6, new6, "PreviewToggle PDF")

    # 7) "In neuem Tab" Link: URL je nach Mode
    old7 = "          {previewUrl && (\n            <a href={previewUrl} target=\"_blank\" rel=\"noopener noreferrer\" className=\"text-xs font-medium flex items-center gap-1 hover:underline\" style={{ color: PRIMARY }}>"
    new7 = "          {(previewMode === 'pdf' ? previewPdfUrl : previewUrl) && (\n            <a href={(previewMode === 'pdf' ? previewPdfUrl : previewUrl) || '#'} target=\"_blank\" rel=\"noopener noreferrer\" className=\"text-xs font-medium flex items-center gap-1 hover:underline\" style={{ color: PRIMARY }}>"
    all_ok &= patch_exact(EDITOR, old7, new7, "Tab-Link je nach Mode")

    # 8) Preview-Rendering: PDF-Iframe einfügen
    old8 = (
        "          {previewUrl ? (\n"
        "            <div className={`bg-white shadow-xl rounded-2xl overflow-hidden ${previewMode === 'mobile' ? 'w-[390px]' : 'w-full max-w-[1280px]'}`}\n"
        "              style={{ height: previewMode === 'mobile' ? '780px' : 'calc(100vh - 180px)' }}>\n"
        "              <iframe ref={iframeRef} src={previewUrl} className=\"w-full h-full border-0\" title=\"Vorschau\" />\n"
        "            </div>\n"
        "          ) : ("
    )
    new8 = (
        "          {previewMode === 'pdf' && previewPdfUrl ? (\n"
        "            <div className=\"bg-white shadow-xl rounded-2xl overflow-hidden w-full max-w-[900px]\"\n"
        "              style={{ height: 'calc(100vh - 180px)' }}>\n"
        "              <iframe ref={iframeRef} src={previewPdfUrl} className=\"w-full h-full border-0\" title=\"PDF-Vorschau\" />\n"
        "            </div>\n"
        "          ) : previewUrl ? (\n"
        "            <div className={`bg-white shadow-xl rounded-2xl overflow-hidden ${previewMode === 'mobile' ? 'w-[390px]' : 'w-full max-w-[1280px]'}`}\n"
        "              style={{ height: previewMode === 'mobile' ? '780px' : 'calc(100vh - 180px)' }}>\n"
        "              <iframe ref={iframeRef} src={previewUrl} className=\"w-full h-full border-0\" title=\"Vorschau\" />\n"
        "            </div>\n"
        "          ) : ("
    )
    all_ok &= patch_exact(EDITOR, old8, new8, "Preview-Rendering +PDF")

    # ─────────────────────────────────────────────────
    # admin/design/[id]/edit/page.tsx
    # ─────────────────────────────────────────────────

    # 9) previewPdfUrl berechnen
    old9 = (
        "  let previewUrl: string | null = null;\n"
        "  const firstMenu = template.menus[0];\n"
        "  if (firstMenu) {\n"
        "    previewUrl = `/${firstMenu.location.tenant.slug}/${firstMenu.location.slug}/${firstMenu.slug}`;\n"
        "  }"
    )
    new9 = (
        "  let previewUrl: string | null = null;\n"
        "  let previewPdfUrl: string | null = null;\n"
        "  const firstMenu = template.menus[0];\n"
        "  if (firstMenu) {\n"
        "    previewUrl = `/${firstMenu.location.tenant.slug}/${firstMenu.location.slug}/${firstMenu.slug}`;\n"
        "    previewPdfUrl = `/api/v1/menus/${firstMenu.id}/pdf`;\n"
        "  }"
    )
    all_ok &= patch_exact(EDIT_PAGE, old9, new9, "edit/page previewPdfUrl berechnen")

    # 10) previewPdfUrl an DesignEditor übergeben
    old10 = (
        "      initialBaseType={template.baseType}\n"
        "      previewUrl={previewUrl}\n"
        "    />"
    )
    new10 = (
        "      initialBaseType={template.baseType}\n"
        "      previewUrl={previewUrl}\n"
        "      previewPdfUrl={previewPdfUrl}\n"
        "    />"
    )
    all_ok &= patch_exact(EDIT_PAGE, old10, new10, "edit/page previewPdfUrl Prop")

    if not all_ok:
        print("\n[ABBRUCH] Mindestens ein Patch schlug fehl. Backups sind als *.bak2 gespeichert.")
        sys.exit(2)

    print("\n[FERTIG] Alle UI-Patches angewendet.")

if __name__ == "__main__":
    main()
