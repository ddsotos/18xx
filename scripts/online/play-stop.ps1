param(
  [switch]$SkipBackup
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

Write-Host "Stopping online play session"

if (-not $SkipBackup) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\db-backup.ps1" -FileName "after-play-$(Get-Date -Format 'yyyyMMdd-HHmmss').dump"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\online-down.ps1"
exit $LASTEXITCODE
