param(
  [int]$Port = 9293,
  [string]$Path = '/',
  [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

. "$PSScriptRoot\env.ps1"
Import-OnlineEnv
if (-not $PSBoundParameters.ContainsKey('Port')) {
  $Port = Get-OnlinePort
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$uri = "http://localhost:$Port$Path"

Write-Host "Waiting for $uri"

while ((Get-Date) -lt $deadline) {
  try {
    $response = Invoke-WebRequest -UseBasicParsing -Uri $uri -TimeoutSec 15
    if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
      Write-Host "Local server responded with HTTP $($response.StatusCode)"
      exit 0
    }
  } catch {
    Write-Host "Waiting: $($_.Exception.Message)"
  }

  Start-Sleep -Seconds 5
}

Write-Error "Timed out waiting for $uri"
exit 1
