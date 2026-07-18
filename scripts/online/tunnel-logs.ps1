param(
  [int]$Tail = 120,
  [switch]$Follow
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

. "$PSScriptRoot\env.ps1"
Import-OnlineEnv

$composeArgs = @(
  'compose',
  '-f',
  'docker-compose.online.yml',
  '--profile',
  'tunnel',
  'logs',
  "--tail=$Tail"
)

if ($Follow) {
  $composeArgs += '--follow'
}

$composeArgs += 'cloudflared'

Write-Host "docker $($composeArgs -join ' ')"
& docker @composeArgs
exit $LASTEXITCODE
