$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\tunnel-down.ps1"
$tunnelExit = $LASTEXITCODE

& powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\dev-down.ps1"
$devExit = $LASTEXITCODE

if ($tunnelExit -ne 0) {
  exit $tunnelExit
}

exit $devExit
