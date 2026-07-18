param(
  [switch]$NoBuild,
  [switch]$SkipBackup,
  [switch]$SkipPublicCheck
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

Write-Host "Starting online play session"

& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\preflight.ps1" -RequireToken -RequirePublicUrl
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$onlineArgs = @('-SkipTunnel')
if ($NoBuild) {
  $onlineArgs += '-NoBuild'
}

& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\online-up.ps1" @onlineArgs
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

if (-not $SkipBackup) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\db-backup.ps1" -FileName "before-play-$(Get-Date -Format 'yyyyMMdd-HHmmss').dump"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\tunnel-up.ps1" -Detach
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

if (-not $SkipPublicCheck) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\check-public.ps1"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\overview.ps1"
exit $LASTEXITCODE
