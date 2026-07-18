param(
  [Parameter(Mandatory = $true)]
  [string]$BackupPath,
  [switch]$Force,
  [switch]$SkipPreRestoreBackup
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

$resolvedBackup = Resolve-Path $BackupPath
$fileName = Split-Path $resolvedBackup -Leaf
$containerPath = "/tmp/$fileName"

if (-not $Force) {
  Write-Host "This will overwrite the online-play database with: $resolvedBackup"
  Write-Host "Re-run with -Force to proceed."
  exit 2
}

if (-not $SkipPreRestoreBackup) {
  Write-Host "Creating pre-restore backup"
  & powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\db-backup.ps1" -FileName "pre-restore-$(Get-Date -Format 'yyyyMMdd-HHmmss').dump"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

Write-Host "Stopping rack and queue before restore"
& docker compose -f docker-compose.online.yml stop rack queue
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Copying backup into db container"
& docker compose -f docker-compose.online.yml cp $resolvedBackup "db:$containerPath"
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Resetting database schema"
& docker compose -f docker-compose.online.yml exec -T rack bundle exec rake 'dev_down[0]'
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

& docker compose -f docker-compose.online.yml exec -T rack bundle exec rake dev_up
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Restoring backup"
& docker compose -f docker-compose.online.yml exec -T db pg_restore `
  --clean `
  --if-exists `
  --username root `
  --dbname 18xx_development `
  --format custom `
  $containerPath
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

& docker compose -f docker-compose.online.yml exec -T db rm -f $containerPath
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Starting rack and queue"
& docker compose -f docker-compose.online.yml up --detach rack queue
exit $LASTEXITCODE
