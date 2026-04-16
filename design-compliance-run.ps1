$ErrorActionPreference = 'Stop'

$sshHost   = 'menucard'
$remoteDir = '/var/www/menucard-pro'
$dateTag   = Get-Date -Format 'yyyyMMdd'
$localOut  = Join-Path $PSScriptRoot 'tests\design-compliance'
$xlsxName  = 'DESIGN-COMPLIANCE-REPORT-' + $dateTag + '.xlsx'

New-Item -ItemType Directory -Force -Path $localOut | Out-Null

Write-Host ''
Write-Host '== 1. Upload ==' -ForegroundColor Cyan
scp "$PSScriptRoot\design-compliance-preflight.sh" `
    "$PSScriptRoot\design-compliance.mjs" `
    "$PSScriptRoot\design-compliance-to-xlsx.py" `
    "$PSScriptRoot\design-compliance-remote.sh" `
    ($sshHost + ':' + $remoteDir + '/')

Write-Host ''
Write-Host '== 2. Preflight + Test + Excel auf Server ==' -ForegroundColor Cyan
ssh $sshHost "bash $remoteDir/design-compliance-remote.sh $dateTag"

Write-Host ''
Write-Host '== 3. Download Bundle ==' -ForegroundColor Cyan
scp ($sshHost + ':' + $remoteDir + '/tests/design-compliance/bundle.tgz') (Join-Path $localOut 'bundle.tgz')

Write-Host ''
Write-Host '== 4. Entpacken ==' -ForegroundColor Cyan
$bundle = Join-Path $localOut 'bundle.tgz'
if (-not (Test-Path $bundle)) {
    Write-Host 'ABBRUCH: bundle.tgz nicht vorhanden.' -ForegroundColor Red
    exit 1
}
Push-Location $localOut
tar -xzf bundle.tgz
Remove-Item bundle.tgz -ErrorAction SilentlyContinue
Pop-Location

$finalXlsx = Join-Path $localOut $xlsxName
if (Test-Path $finalXlsx) {
    Copy-Item $finalXlsx (Join-Path $PSScriptRoot $xlsxName) -Force
}

Write-Host ''
Write-Host 'FERTIG.' -ForegroundColor Green
Write-Host ('  Report : ' + (Join-Path $PSScriptRoot $xlsxName))
Write-Host ('  JSON   : ' + (Join-Path $localOut 'report.json'))
Write-Host ('  Routes : ' + (Join-Path $localOut 'routes.json'))
Write-Host ('  Shots  : ' + (Join-Path $localOut 'snapshots'))
