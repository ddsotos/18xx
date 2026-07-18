param(
  [string]$Url,
  [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

. "$PSScriptRoot\env.ps1"
Import-OnlineEnv

if ([string]::IsNullOrWhiteSpace($Url)) {
  $Url = $env:CLOUDFLARE_PUBLIC_URL
}

if ([string]::IsNullOrWhiteSpace($Url)) {
  Write-Error "Url is required. Pass it as an argument or set CLOUDFLARE_PUBLIC_URL in .env.online.local."
  exit 1
}

Write-Host "Checking public URL: $Url"

try {
  $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec $TimeoutSeconds -MaximumRedirection 0
  Write-Host "HTTP $($response.StatusCode)"
  if (($response.Headers.Keys -contains 'cf-ray') -or ($response.Headers.Keys -contains 'cf-cache-status')) {
    Write-Host "Cloudflare headers detected"
  }
  exit 0
} catch {
  $exception = $_.Exception
  $response = $exception.Response

  if ($response) {
    $statusCode = [int]$response.StatusCode
    Write-Host "HTTP $statusCode"
    Write-Host $response.ResponseUri

    if ($statusCode -ge 300 -and $statusCode -lt 400) {
      Write-Host "Redirect received. This is expected if Cloudflare Access is asking for authentication."
      exit 0
    }
  }

  Write-Error $exception.Message
  exit 1
}
