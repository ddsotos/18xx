$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

$target = Join-Path $repoRoot '.env.online.local'
$source = Join-Path $repoRoot '.env.online.example'

if (Test-Path $target) {
  Write-Host ".env.online.local already exists: $target"
  $existing = Get-Content $target
  $keys = @{}
  foreach ($line in $existing) {
    $trimmed = $line.Trim()
    if ($trimmed -eq '' -or $trimmed.StartsWith('#') -or -not $trimmed.Contains('=')) {
      continue
    }

    $keys[$trimmed.Split('=', 2)[0].Trim()] = $true
  }

  $example = Get-Content $source
  $missing = @()
  foreach ($line in $example) {
    $trimmed = $line.Trim()
    if ($trimmed -eq '' -or $trimmed.StartsWith('#') -or -not $trimmed.Contains('=')) {
      continue
    }

    $key = $trimmed.Split('=', 2)[0].Trim()
    if (-not $keys.ContainsKey($key)) {
      $missing += $line
    }
  }

  if ($missing.Count -gt 0) {
    Add-Content -Path $target -Value ''
    Add-Content -Path $target -Value '# Added by scripts/online/init-env.cmd'
    Add-Content -Path $target -Value $missing
    Write-Host "Added missing keys: $($missing -join ', ')"
  }

  exit 0
}

Copy-Item $source $target
Write-Host "Created .env.online.local"
Write-Host "Open it and paste CLOUDFLARE_TUNNEL_TOKEN from Cloudflare Zero Trust."
