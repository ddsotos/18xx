param(
  [switch]$Detach
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

. "$PSScriptRoot\env.ps1"
Import-OnlineEnv -RequireTunnelToken

$composeArgs = @(
  'compose',
  '-f',
  'docker-compose.online.yml',
  '--profile',
  'tunnel',
  'up'
)

if ($Detach) {
  $composeArgs += '--detach'
}

$composeArgs += 'cloudflared'

Write-Host "Starting Cloudflare Tunnel"
Write-Host "docker $($composeArgs -join ' ')"

& docker @composeArgs
exit $LASTEXITCODE
