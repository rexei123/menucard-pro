# setup-ssh-key.ps1
# Einmal ausführen. Danach funktioniert scp/ssh zum Hetzner-Server ohne Passwort.
#
# Start:
#   cd "C:\Users\erich\Documents\Claude\Projects\Menucard Pro"
#   powershell -ExecutionPolicy Bypass -File ".\setup-ssh-key.ps1"

$ErrorActionPreference = 'Stop'

$server  = '178.104.138.177'
$user    = 'root'
$sshDir  = Join-Path $env:USERPROFILE '.ssh'
$keyPath = Join-Path $sshDir 'menucard_pro_id'
$pubPath = "$keyPath.pub"
$cfgPath = Join-Path $sshDir 'config'

New-Item -ItemType Directory -Force -Path $sshDir | Out-Null

# 1. Schlüsselpaar erzeugen (falls noch nicht da)
if (-not (Test-Path $keyPath)) {
  Write-Host "Erzeuge neues ed25519-Schlüsselpaar..." -ForegroundColor Cyan
  ssh-keygen -t ed25519 -f $keyPath -N '""' -C "menucard-pro-$(hostname)"
} else {
  Write-Host "Schlüsselpaar existiert bereits: $keyPath" -ForegroundColor Yellow
}

# 2. Öffentlichen Schlüssel auf den Server schreiben (EINMAL Passwort nötig)
$pub = (Get-Content $pubPath -Raw).Trim()
Write-Host "`nJetzt EINMAL das Server-Passwort eingeben:" -ForegroundColor Cyan
ssh "$user@$server" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && grep -qxF '$pub' ~/.ssh/authorized_keys 2>/dev/null || echo '$pub' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo OK"

# 3. SSH-Config-Alias 'menucard' eintragen
$cfgEntry = @"

Host menucard
  HostName $server
  User $user
  IdentityFile $keyPath
  IdentitiesOnly yes
  ServerAliveInterval 30
"@

if ((Test-Path $cfgPath) -and ((Get-Content $cfgPath -Raw) -match 'Host\s+menucard\b')) {
  Write-Host "SSH-Config-Alias 'menucard' existiert bereits." -ForegroundColor Yellow
} else {
  Add-Content -Path $cfgPath -Value $cfgEntry
  Write-Host "SSH-Config-Alias 'menucard' eingetragen." -ForegroundColor Green
}

# 4. Test
Write-Host "`nTeste passwortlose Verbindung..." -ForegroundColor Cyan
$test = ssh -o BatchMode=yes menucard 'echo "SSH-Key funktioniert: $(hostname) $(date -Is)"'
Write-Host $test -ForegroundColor Green

Write-Host "`nFERTIG. Der Compliance-Runner benutzt ab sofort den Alias 'menucard' ohne Passwort." -ForegroundColor Green
