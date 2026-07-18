$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

$composeFiles = @('docker-compose.online.yml')

$composeArgs = @('compose')
foreach ($file in $composeFiles) {
  $composeArgs += @('-f', $file)
}

$composeArgs += @('down')

Write-Host "Stopping 18xx dev stack"
Write-Host "docker $($composeArgs -join ' ')"

& docker @composeArgs
exit $LASTEXITCODE
