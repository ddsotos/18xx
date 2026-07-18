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
  'stop',
  'cloudflared'
)

Write-Host "Stopping Cloudflare Tunnel"
Write-Host "docker $($composeArgs -join ' ')"

& docker @composeArgs
exit $LASTEXITCODE
