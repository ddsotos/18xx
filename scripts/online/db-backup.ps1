param(
  [string]$OutputDir = 'backups',
  [string]$FileName
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

if (-not $FileName) {
  $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $FileName = "18xx-online-$timestamp.dump"
}

$backupDir = Join-Path $repoRoot $OutputDir
New-Item -ItemType Directory -Force $backupDir | Out-Null

$backupPath = Join-Path $backupDir $FileName
$containerPath = "/tmp/$FileName"

Write-Host "Creating database backup: $backupPath"

& docker compose -f docker-compose.online.yml exec -T db pg_dump `
  --host localhost `
  --port 5432 `
  --username root `
  --no-password `
  --format custom `
  --file $containerPath `
  18xx_development
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

& docker compose -f docker-compose.online.yml cp "db:$containerPath" $backupPath
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

& docker compose -f docker-compose.online.yml exec -T db rm -f $containerPath
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Backup written to $backupPath"
