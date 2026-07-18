param(
  [switch]$NoBuild,
  [switch]$SkipTunnel
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

. "$PSScriptRoot\env.ps1"
Import-OnlineEnv -RequireTunnelToken
$port = Get-OnlinePort

$devArgs = @('-Detach', '-Wait', '-Port', $port)
if ($NoBuild) {
  $devArgs += '-NoBuild'
}

& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\dev-up.ps1" @devArgs
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

if (-not $SkipTunnel) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\tunnel-up.ps1" -Detach
  exit $LASTEXITCODE
}

exit 0
