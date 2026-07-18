$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

$composeFiles = @('docker-compose.online.yml')

$composeArgs = @('compose')
foreach ($file in $composeFiles) {
  $composeArgs += @('-f', $file)
}

$composeArgs += @('ps')

Write-Host "18xx dev stack status"
Write-Host "docker $($composeArgs -join ' ')"

& docker @composeArgs
exit $LASTEXITCODE
