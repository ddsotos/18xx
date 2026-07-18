param(
  [ValidateSet('rack', 'queue', 'db', 'redis')]
  [string]$Service = 'rack',
  [int]$Tail = 120,
  [switch]$Follow
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

$composeArgs = @(
  'compose',
  '-f',
  'docker-compose.online.yml',
  'logs',
  "--tail=$Tail"
)

if ($Follow) {
  $composeArgs += '--follow'
}

$composeArgs += $Service

Write-Host "docker $($composeArgs -join ' ')"
& docker @composeArgs
exit $LASTEXITCODE
