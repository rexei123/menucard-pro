#!/usr/bin/env python3
"""Patch: Template-API-PATCH auf deep-merge umstellen, damit Analog-Teil beim Digital-Save erhalten bleibt."""
import sys
from pathlib import Path

API = Path("src/app/api/v1/design-templates/[id]/route.ts")
text = API.read_text(encoding="utf-8")

BACKUP = API.with_suffix(API.suffix + ".bak-editor-v2")
BACKUP.write_text(text, encoding="utf-8")

# Bereits gepatcht?
if "function deepMergeTpl" in text:
    print("[skip] API bereits gepatcht.")
    sys.exit(0)

# deepMerge-Helfer am Anfang ergänzen
imports_end = text.find("export async function GET")
if imports_end == -1:
    print("[FEHLER] export async function GET nicht gefunden.")
    sys.exit(1)

helper = """function deepMergeTpl(target: any, source: any): any {
  if (!source) return target;
  if (!target) return source;
  const result = { ...target };
  for (const key of Object.keys(source)) {
    if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
      result[key] = deepMergeTpl(target[key] || {}, source[key]);
    } else {
      result[key] = source[key];
    }
  }
  return result;
}
"""
text = text[:imports_end] + helper + "\n" + text[imports_end:]

# config-Überschreiben durch deep-merge ersetzen
old = "  if (body.config !== undefined) data.config = body.config;"
new = "  if (body.config !== undefined) data.config = deepMergeTpl((template.config as any) || {}, body.config);"
if old not in text:
    print("[FEHLER] config-Zeile nicht gefunden.")
    sys.exit(1)
text = text.replace(old, new, 1)

API.write_text(text, encoding="utf-8")
print("[ok] Template-API mit deep-merge gepatcht.")
