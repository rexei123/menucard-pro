# Staging Verify: laed phase0-tag2-staging-verify.sh hoch und fuehrt es aus
$ServerIP   = "178.104.138.177"
$ServerUser = "root"

$local  = ".\phase0-tag2-staging-verify.sh"
$remote = "/root/phase0-tag2-staging-verify.sh"

if (-not (Test-Path $local)) { Write-Host "Verify-Script fehlt lokal." -ForegroundColor Red; exit 1 }

$content = Get-Content -Raw $local
$lf = $content -replace "`r`n", "`n"
$tempPath = Join-Path $env:TEMP "phase0-tag2-staging-verify.sh"
[IO.File]::WriteAllText($tempPath, $lf)

scp $tempPath "${ServerUser}@${ServerIP}:${remote}" | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "scp fehlgeschlagen." -ForegroundColor Red; exit 1 }

ssh "${ServerUser}@${ServerIP}" "chmod +x ${remote} && bash ${remote}"
