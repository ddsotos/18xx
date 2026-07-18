param(
  [string]$OutputDir = 'diagnostics'
)

$ErrorActionPreference = 'Continue'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

. "$PSScriptRoot\env.ps1"
Import-OnlineEnv

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dir = Join-Path (Join-Path $repoRoot $OutputDir) $timestamp
New-Item -ItemType Directory -Force $dir | Out-Null

function Save-Command($Name, [scriptblock]$Body) {
  $path = Join-Path $dir "$Name.txt"
  "### $Name" | Out-File -Encoding UTF8 $path
  try {
    & $Body *>&1 | Out-File -Append -Encoding UTF8 $path
  } catch {
    $_ | Out-File -Append -Encoding UTF8 $path
  }
}

Save-Command 'env-status' {
  Write-Host "ONLINE_PORT=$env:ONLINE_PORT"
  Write-Host "CLOUDFLARE_PUBLIC_URL=$env:CLOUDFLARE_PUBLIC_URL"
  if ([string]::IsNullOrWhiteSpace($env:CLOUDFLARE_TUNNEL_TOKEN)) {
    Write-Host "CLOUDFLARE_TUNNEL_TOKEN=not set"
  } else {
    Write-Host "CLOUDFLARE_TUNNEL_TOKEN=set"
  }
}

Save-Command 'git-status' {
  git status --short --branch
}

Save-Command 'preflight' {
  powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\preflight.ps1"
}

Save-Command 'compose-ps' {
  docker compose -f docker-compose.online.yml --profile tunnel ps
}

Save-Command 'rack-logs' {
  docker compose -f docker-compose.online.yml logs --tail=200 rack
}

Save-Command 'queue-logs' {
  docker compose -f docker-compose.online.yml logs --tail=200 queue
}

Save-Command 'tunnel-logs' {
  docker compose -f docker-compose.online.yml --profile tunnel logs --tail=200 cloudflared
}

Write-Host "Diagnostics written to $dir"
