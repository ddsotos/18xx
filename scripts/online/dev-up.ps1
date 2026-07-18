param(
  [switch]$Detach,
  [switch]$NoBuild,
  [switch]$Wait,
  [int]$Port = 9293
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

. "$PSScriptRoot\env.ps1"
Import-OnlineEnv
if (-not $PSBoundParameters.ContainsKey('Port')) {
  $Port = Get-OnlinePort
}
$env:ONLINE_PORT = $Port.ToString()

$composeFiles = @('docker-compose.online.yml')

$composeArgs = @('compose')
foreach ($file in $composeFiles) {
  $composeArgs += @('-f', $file)
}

$composeArgs += 'up'

if (-not $NoBuild) {
  $composeArgs += '--build'
}

if ($Detach) {
  $composeArgs += '--detach'
}

Write-Host "Starting 18xx dev stack on http://localhost:$Port"
Write-Host "docker $($composeArgs -join ' ')"

& docker @composeArgs
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
  exit $exitCode
}

if ($Wait) {
  & "$PSScriptRoot\wait-local.ps1" -Port $Port
  exit $LASTEXITCODE
}

exit 0
