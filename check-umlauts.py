import subprocess, os
os.environ['PGPASSWORD'] = 'ccTFFSJtuN7l1dC17PzT8Q'
sql = """SELECT name FROM "ProductTranslation" WHERE language='de' AND (name LIKE '%ue%' OR name LIKE '%ae%' OR name LIKE '%oe%') ORDER BY name;"""
r = subprocess.run(['psql','-h','127.0.0.1','-U','menucard','menucard_pro','-c',sql], capture_output=True, text=True)
print(r.stdout or r.stderr)
