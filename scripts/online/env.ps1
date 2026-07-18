function Import-OnlineEnv {
  param(
    [string]$Path = '.env.online.local',
    [switch]$RequireTunnelToken
  )

  if (Test-Path $Path) {
    Get-Content $Path | ForEach-Object {
      $line = $_.Trim()
      if ($line -eq '' -or $line.StartsWith('#')) {
        return
      }

      $parts = $line.Split('=', 2)
      if ($parts.Count -ne 2) {
        return
      }

      $name = $parts[0].Trim()
      $value = $parts[1].Trim()
      if ($value.StartsWith('"') -and $value.EndsWith('"')) {
        $value = $value.Substring(1, $value.Length - 2)
      }

      Set-Item -Path "Env:$name" -Value $value
    }
  }

  if ($RequireTunnelToken -and [string]::IsNullOrWhiteSpace($env:CLOUDFLARE_TUNNEL_TOKEN)) {
    Write-Error "CLOUDFLARE_TUNNEL_TOKEN is not set. Copy .env.online.example to .env.online.local and paste the Cloudflare Tunnel token."
    exit 1
  }

  if ($RequireTunnelToken -and $env:CLOUDFLARE_TUNNEL_TOKEN -match '^<.*>$') {
    Write-Error "CLOUDFLARE_TUNNEL_TOKEN still looks like a placeholder. Paste the real Cloudflare Tunnel token."
    exit 1
  }
}

function Get-OnlinePort {
  param(
    [int]$Default = 9293
  )

  if ([string]::IsNullOrWhiteSpace($env:ONLINE_PORT)) {
    return $Default
  }

  $port = 0
  if ([int]::TryParse($env:ONLINE_PORT, [ref]$port) -and $port -gt 0 -and $port -lt 65536) {
    return $port
  }

  Write-Error "ONLINE_PORT must be a number between 1 and 65535."
  exit 1
}
