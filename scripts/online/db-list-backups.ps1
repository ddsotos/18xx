param(
  [string]$OutputDir = 'backups',
  [int]$First = 10
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

$backupDir = Join-Path $repoRoot $OutputDir

if (-not (Test-Path $backupDir)) {
  Write-Host "No backup directory found: $backupDir"
  exit 0
}

Get-ChildItem $backupDir -Filter '*.dump' |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First $First Name, Length, LastWriteTime
