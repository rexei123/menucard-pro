#!/usr/bin/env python3
"""
Schritt 2a: Analog-Tab ("PDF-Layout") in den Design-Editor integrieren.
Verwendet nur exakte String-Ersetzungen, kein Regex.
Erzeugt .bak Dateien vor Änderungen.
"""
import sys
from pathlib import Path

ROOT = Path("/var/www/menucard-pro")
EDITOR = ROOT / "src/components/admin/design-editor.tsx"

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
    if not EDITOR.exists():
        print(f"FEHLER: {EDITOR} nicht gefunden"); sys.exit(1)

    # Backup
    bak = EDITOR.with_suffix(".tsx.bak")
    bak.write_text(EDITOR.read_text(encoding="utf-8"), encoding="utf-8")
    print(f"[BACKUP] {bak}")

    all_ok = True

    # 1) Import TabPdfLayout
    old1 = "import { useRouter } from 'next/navigation';"
    new1 = (
        "import { useRouter } from 'next/navigation';\n"
        "import { TabPdfLayout } from './pdf-layout-tab';"
    )
    all_ok &= patch_exact(EDITOR, old1, new1, "Import TabPdfLayout")

    # 2) TABS: Zusätzlicher Eintrag "PDF-Layout"
    old2 = "  { id: 'rahmen', label: 'Kopf & Fuß', icon: 'crop_landscape' },\n];"
    new2 = (
        "  { id: 'rahmen', label: 'Kopf & Fuß', icon: 'crop_landscape' },\n"
        "  { id: 'pdf', label: 'PDF-Layout', icon: 'picture_as_pdf' },\n"
        "];"
    )
    all_ok &= patch_exact(EDITOR, old2, new2, "TABS + PDF-Layout Entry")

    # 3) useApi template-mode load: analog zurückgeben
    old3 = (
        "          const digital = (t.config?.digital) || {};\n"
        "          return {\n"
        "            digital,\n"
        "            overrides: digital,\n"
        "            templateName: digital.template || t.baseType || 'elegant',\n"
        "            customTemplates: [],\n"
        "            meta: { name: t.name, baseType: t.baseType, type: t.type },\n"
        "          };"
    )
    new3 = (
        "          const digital = (t.config?.digital) || {};\n"
        "          const analog = (t.config?.analog) || {};\n"
        "          return {\n"
        "            digital,\n"
        "            analog,\n"
        "            overrides: digital,\n"
        "            analogOverrides: analog,\n"
        "            templateName: digital.template || t.baseType || 'elegant',\n"
        "            customTemplates: [],\n"
        "            meta: { name: t.name, baseType: t.baseType, type: t.type },\n"
        "          };"
    )
    all_ok &= patch_exact(EDITOR, old3, new3, "useApi template load (+analog)")

    # 4) useApi template-mode save: patch.analog unterstützen
    old4 = "          if (patch.digital !== undefined) body.config = { digital: patch.digital };"
    new4 = (
        "          if (patch.digital !== undefined || patch.analog !== undefined) {\n"
        "            body.config = {};\n"
        "            if (patch.digital !== undefined) body.config.digital = patch.digital;\n"
        "            if (patch.analog !== undefined) body.config.analog = patch.analog;\n"
        "          }"
    )
    all_ok &= patch_exact(EDITOR, old4, new4, "useApi template save (+analog)")

    # 5) useApi menu-mode load: analog durchreichen
    old5 = (
        "        return {\n"
        "          digital: data.designConfig?.digital || data.digital || data,\n"
        "          overrides: data.savedOverrides?.digital || {},\n"
        "          templateName: data.templateName || data.designConfig?.digital?.template || 'elegant',\n"
        "          customTemplates: data.customTemplates || [],\n"
        "          meta: { name: '', baseType: '', type: 'MENU' },\n"
        "        };"
    )
    new5 = (
        "        return {\n"
        "          digital: data.designConfig?.digital || data.digital || data,\n"
        "          analog: data.designConfig?.analog || {},\n"
        "          overrides: data.savedOverrides?.digital || {},\n"
        "          analogOverrides: data.savedOverrides?.analog || {},\n"
        "          templateName: data.templateName || data.designConfig?.digital?.template || 'elegant',\n"
        "          customTemplates: data.customTemplates || [],\n"
        "          meta: { name: '', baseType: '', type: 'MENU' },\n"
        "        };"
    )
    all_ok &= patch_exact(EDITOR, old5, new5, "useApi menu load (+analog)")

    # 6) State: analogConfig + analogOverrides
    old6 = (
        "  const [config, setConfig] = useState<DigitalConfig | null>(null);\n"
        "  const [overrides, setOverrides] = useState<any>({});"
    )
    new6 = (
        "  const [config, setConfig] = useState<DigitalConfig | null>(null);\n"
        "  const [analogConfig, setAnalogConfig] = useState<any>(null);\n"
        "  const [overrides, setOverrides] = useState<any>({});\n"
        "  const [analogOverrides, setAnalogOverrides] = useState<any>({});"
    )
    all_ok &= patch_exact(EDITOR, old6, new6, "State analogConfig")

    # 7) Load: setAnalogConfig / setAnalogOverrides
    old7 = (
        "      setConfig(data.digital as DigitalConfig);\n"
        "      setOverrides(data.overrides);\n"
        "      setTemplateName(data.templateName);"
    )
    new7 = (
        "      setConfig(data.digital as DigitalConfig);\n"
        "      setAnalogConfig((data as any).analog || {});\n"
        "      setOverrides(data.overrides);\n"
        "      setAnalogOverrides((data as any).analogOverrides || {});\n"
        "      setTemplateName(data.templateName);"
    )
    all_ok &= patch_exact(EDITOR, old7, new7, "Load setAnalogConfig")

    # 8) scheduleSave & updateAnalog neben updateConfig einfügen
    old8 = "  const updateConfig = useCallback((path: string, value: any) => {"
    new8 = (
        "  // ─── Analog (PDF) Save + Update ───\n"
        "  const scheduleSaveAnalog = useCallback((newAnalogOverrides: any) => {\n"
        "    if (saveTimerRef.current) clearTimeout(saveTimerRef.current);\n"
        "    saveTimerRef.current = setTimeout(async () => {\n"
        "      setSaving(true);\n"
        "      setError(null);\n"
        "      try {\n"
        "        await api.save({ analog: newAnalogOverrides });\n"
        "        setSavedAt(Date.now());\n"
        "      } catch (e: any) {\n"
        "        setError(e.message || 'Speichern fehlgeschlagen');\n"
        "      } finally {\n"
        "        setSaving(false);\n"
        "      }\n"
        "    }, 800);\n"
        "  }, [api]);\n"
        "\n"
        "  const updateAnalog = useCallback((path: string, value: any) => {\n"
        "    setAnalogConfig((prev: any) => {\n"
        "      const next = JSON.parse(JSON.stringify(prev || {}));\n"
        "      const parts = path.split('.');\n"
        "      let obj: any = next;\n"
        "      for (let i = 0; i < parts.length - 1; i++) {\n"
        "        if (!obj[parts[i]]) obj[parts[i]] = {};\n"
        "        obj = obj[parts[i]];\n"
        "      }\n"
        "      obj[parts[parts.length - 1]] = value;\n"
        "      return next;\n"
        "    });\n"
        "    setAnalogOverrides((prev: any) => {\n"
        "      const next = JSON.parse(JSON.stringify(prev || {}));\n"
        "      const parts = path.split('.');\n"
        "      let obj: any = next;\n"
        "      for (let i = 0; i < parts.length - 1; i++) {\n"
        "        if (!obj[parts[i]]) obj[parts[i]] = {};\n"
        "        obj = obj[parts[i]];\n"
        "      }\n"
        "      obj[parts[parts.length - 1]] = value;\n"
        "      scheduleSaveAnalog(next);\n"
        "      return next;\n"
        "    });\n"
        "  }, [scheduleSaveAnalog]);\n"
        "\n"
        "  const updateConfig = useCallback((path: string, value: any) => {"
    )
    all_ok &= patch_exact(EDITOR, old8, new8, "updateAnalog Funktion")

    # 9) Render: {activeTab === 'pdf' && ... }
    old9 = "          {activeTab === 'rahmen' && <TabRahmen config={config} update={updateConfig} />}"
    new9 = (
        "          {activeTab === 'rahmen' && <TabRahmen config={config} update={updateConfig} />}\n"
        "          {activeTab === 'pdf' && isTemplateMode && (\n"
        "            <TabPdfLayout analogConfig={analogConfig} update={updateAnalog} />\n"
        "          )}\n"
        "          {activeTab === 'pdf' && !isTemplateMode && (\n"
        "            <div className=\"rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900\">\n"
        "              <div className=\"font-medium mb-1\">PDF-Layout nur in Vorlagen verfügbar</div>\n"
        "              PDF-Einstellungen werden zentral in der zugeordneten Design-Vorlage gepflegt.\n"
        "              Bitte wechseln Sie in den Bereich <strong>Kartendesign</strong>, um diese Einstellungen zu bearbeiten.\n"
        "            </div>\n"
        "          )}"
    )
    all_ok &= patch_exact(EDITOR, old9, new9, "Render TabPdfLayout")

    if not all_ok:
        print("\n[ABBRUCH] Mindestens ein Patch schlug fehl. Backup liegt unter design-editor.tsx.bak")
        sys.exit(2)

    print("\n[FERTIG] Alle Patches angewendet.")

if __name__ == "__main__":
    main()
