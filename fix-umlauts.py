import subprocess, os
os.environ['PGPASSWORD'] = 'ccTFFSJtuN7l1dC17PzT8Q'

# Gezielte Korrekturen: ASCII-Umlaute -> echte Umlaute
fixes = [
    ("Apfelsaft naturtrueb", "Apfelsaft naturtrüb"),
    ("Blaufraenkisch Ried Hochberg Moric 2021", "Blaufränkisch Ried Hochberg Moric 2021"),
    ("Gruener Veltliner Federspiel Domaene Wachau 2023", "Grüner Veltliner Federspiel Domäne Wachau 2023"),
    ("Kuerbiscremesuppe", "Kürbiscremesuppe"),
    ("Pinot Noir Tatschler Bruendlmayer 2021", "Pinot Noir Tatschler Bründlmayer 2021"),
    ("Rose vom Zweigelt Pittnauer 2023", "Rosé vom Zweigelt Pittnauer 2023"),
    ("Sauvignon Blanc Suedsteiermark Tement 2023", "Sauvignon Blanc Südsteiermark Tement 2023"),
    ("Spinatknoedel", "Spinatknödel"),
    ("Stiegl Goldbraeu", "Stiegl Goldbräu"),
]

sql_parts = []
for old, new in fixes:
    sql_parts.append(f"""UPDATE "ProductTranslation" SET name='{new}' WHERE name='{old}';""")

sql = "\n".join(sql_parts)
sql += """\nSELECT name FROM "ProductTranslation" WHERE language='de' AND (name LIKE '%ue%' OR name LIKE '%ae%' OR name LIKE '%oe%') ORDER BY name;"""

r = subprocess.run(
    ['psql', '-h', '127.0.0.1', '-U', 'menucard', 'menucard_pro', '-c', sql],
    capture_output=True, text=True
)
print(r.stdout)
if r.stderr:
    print("ERRORS:", r.stderr)
print("Done!")
