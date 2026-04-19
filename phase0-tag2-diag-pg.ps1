$ServerIP   = "178.104.138.177"
$ServerUser = "root"

Write-Host "Diag-Upload..." -ForegroundColor Yellow
scp phase0-tag2-diag-pg.sh "${ServerUser}@${ServerIP}:/tmp/phase0-tag2-diag-pg.sh"
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host ""
ssh -t "${ServerUser}@${ServerIP}" "bash /tmp/phase0-tag2-diag-pg.sh"
