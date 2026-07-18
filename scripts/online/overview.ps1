$ErrorActionPreference = 'Continue'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

. "$PSScriptRoot\env.ps1"
Import-OnlineEnv
$port = Get-OnlinePort

Write-Host "== 18xx online overview =="
Write-Host "Local URL:  http://localhost:$port"
if ([string]::IsNullOrWhiteSpace($env:CLOUDFLARE_PUBLIC_URL)) {
  Write-Host "Public URL: not set"
} else {
  Write-Host "Public URL: $env:CLOUDFLARE_PUBLIC_URL"
}

if ([string]::IsNullOrWhiteSpace($env:CLOUDFLARE_TUNNEL_TOKEN)) {
  Write-Host "Tunnel token: not set"
} else {
  Write-Host "Tunnel token: set"
}

Write-Host ""
Write-Host "== compose services =="
docker compose -f docker-compose.online.yml --profile tunnel ps

Write-Host ""
Write-Host "== local HTTP =="
try {
  $response = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:$port/" -TimeoutSec 10
  Write-Host "HTTP $($response.StatusCode)"
} catch {
  Write-Host "FAILED: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "Useful commands:"
Write-Host "  .\scripts\online\online-up.cmd"
Write-Host "  .\scripts\online\online-down.cmd"
Write-Host "  .\scripts\online\tunnel-logs.cmd"
Write-Host "  .\scripts\online\db-backup.cmd"
