param(
  [switch]$RequireToken,
  [switch]$RequirePublicUrl
)

$ErrorActionPreference = 'Continue'
$failed = $false

function Fail($Message) {
  Write-Host "FAILED: $Message"
  $script:failed = $true
}

function Ok($Message) {
  Write-Host "OK: $Message"
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

. "$PSScriptRoot\env.ps1"
Import-OnlineEnv
$port = Get-OnlinePort

Write-Host "== online preflight =="

if ($port -eq 9292) {
  Fail "ONLINE_PORT should not be 9292; use 9293 unless you know 9292 is free."
} else {
  Ok "ONLINE_PORT=$port"
}

if ([string]::IsNullOrWhiteSpace($env:CLOUDFLARE_TUNNEL_TOKEN)) {
  if ($RequireToken) {
    Fail "CLOUDFLARE_TUNNEL_TOKEN is not set"
  } else {
    Write-Host "WARN: CLOUDFLARE_TUNNEL_TOKEN is not set"
  }
} elseif ($env:CLOUDFLARE_TUNNEL_TOKEN -match '^<.*>$') {
  Fail "CLOUDFLARE_TUNNEL_TOKEN still looks like a placeholder"
} else {
  Ok "CLOUDFLARE_TUNNEL_TOKEN is set"
}

if ([string]::IsNullOrWhiteSpace($env:CLOUDFLARE_PUBLIC_URL)) {
  if ($RequirePublicUrl) {
    Fail "CLOUDFLARE_PUBLIC_URL is not set"
  } else {
    Write-Host "WARN: CLOUDFLARE_PUBLIC_URL is not set"
  }
} elseif ($env:CLOUDFLARE_PUBLIC_URL -notmatch '^https://') {
  Fail "CLOUDFLARE_PUBLIC_URL should start with https://"
} else {
  Ok "CLOUDFLARE_PUBLIC_URL is set"
}

Write-Host ""
Write-Host "Cloudflare dashboard Public Hostname service URL for Docker tunnel mode:"
Write-Host "  http://rack:9292"
Write-Host ""
Write-Host "Local browser check URL:"
Write-Host "  http://localhost:$port"

docker compose -f docker-compose.online.yml config --quiet
if ($LASTEXITCODE -eq 0) {
  Ok "docker-compose.online.yml is valid"
} else {
  Fail "docker-compose.online.yml is invalid"
}

if ($failed) {
  exit 1
}

exit 0
