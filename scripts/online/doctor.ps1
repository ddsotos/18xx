param(
  [int]$Port = 9293,
  [switch]$RequireCloudflared
)

$ErrorActionPreference = 'Continue'
$failed = $false

function Check($Name, [scriptblock]$Body) {
  Write-Host ""
  Write-Host "== $Name =="
  try {
    & $Body
    if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
      throw "Command exited with $LASTEXITCODE"
    }
    Write-Host "OK: $Name"
  } catch {
    Write-Host "FAILED: $Name"
    Write-Host $_
    $script:failed = $true
  }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

. "$PSScriptRoot\env.ps1"
Import-OnlineEnv
if (-not $PSBoundParameters.ContainsKey('Port')) {
  $Port = Get-OnlinePort
}

Check 'online env preflight' {
  & powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\preflight.ps1"
}

Check 'docker CLI' {
  docker --version
}

Check 'docker compose config' {
  docker compose -f docker-compose.online.yml config --quiet
}

Check 'docker daemon' {
  docker info --format '{{.ServerVersion}}'
}

Check 'online stack status' {
  docker compose -f docker-compose.online.yml ps
}

Check "local HTTP http://localhost:$Port/" {
  $response = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:$Port/" -TimeoutSec 20
  Write-Host "HTTP $($response.StatusCode)"
}

Write-Host ""
Write-Host "== Cloudflare Tunnel token =="
if ([string]::IsNullOrWhiteSpace($env:CLOUDFLARE_TUNNEL_TOKEN)) {
  Write-Host "WARN: CLOUDFLARE_TUNNEL_TOKEN is not set"
  Write-Host "Docker tunnel mode needs .env.online.local."
} else {
  Write-Host "OK: CLOUDFLARE_TUNNEL_TOKEN is set"
}

Write-Host ""
Write-Host "== cloudflared CLI =="
$cloudflared = Get-Command cloudflared -ErrorAction SilentlyContinue
if ($cloudflared) {
  cloudflared --version
  Write-Host "OK: cloudflared CLI"
} elseif ($RequireCloudflared) {
  Write-Host "FAILED: cloudflared CLI"
  Write-Host "cloudflared is not installed or not on PATH"
  $failed = $true
} else {
  Write-Host "WARN: cloudflared is not installed or not on PATH"
  Write-Host "This is only required for host-installed cloudflared mode. Docker tunnel mode does not need it."
}

if ($failed) {
  exit 1
}

exit 0
