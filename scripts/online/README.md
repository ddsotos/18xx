# Online Play Scripts

Windows 向けの身内オンラインプレイ補助スクリプト。

通常は `*.cmd` を実行する。`.ps1` は `.cmd` から呼ばれる実体。

## Daily Commands

| Command | Purpose |
| --- | --- |
| `dev-up.cmd -Detach -Wait` | Start the 18xx dev stack for Quick Tunnel play. |
| `dev-down.cmd` | Stop the 18xx dev stack after Quick Tunnel is stopped. |
| `db-backup.cmd` | Create a backup before or after play. |
| `overview.cmd` | Show the local URL, Quick Tunnel command, compose status, and local HTTP status. |
| `collect-diagnostics.cmd` | Write troubleshooting logs to `diagnostics/`. |

Quick Tunnel itself is currently started directly:

```powershell
docker run --rm -it cloudflare/cloudflared:latest tunnel --no-autoupdate --url http://host.docker.internal:9293
```

If `cloudflared` is installed on the host PC:

```powershell
cloudflared tunnel --url http://localhost:9293
```

## Setup Commands

| Command | Purpose |
| --- | --- |
| `init-env.cmd` | Create or update `.env.online.local` from `.env.online.example`. |
| `preflight.cmd` | Validate local online settings before starting. |
| `doctor.cmd` | Check Docker, compose, local HTTP, and optional tunnel-related settings. |
| `check-public.cmd` | Check a fixed Cloudflare public URL. Mainly for future Named Tunnel use. |

## Lower-Level Commands

| Command | Purpose |
| --- | --- |
| `online-up.cmd` / `online-down.cmd` | Start or stop the stack and Named Tunnel together. Mainly for future fixed-URL use. |
| `dev-up.cmd` / `dev-down.cmd` | Start or stop only the 18xx dev stack. |
| `tunnel-up.cmd` / `tunnel-down.cmd` | Start or stop only the Named Tunnel container. Mainly for future fixed-URL use. |
| `status.cmd` | Show compose service status. |
| `logs.cmd` | Show logs for `rack`, `queue`, `db`, or `redis`. |
| `tunnel-logs.cmd` | Show Named Tunnel logs. |
| `wait-local.cmd` | Wait until local HTTP responds. |

## Database Commands

| Command | Purpose |
| --- | --- |
| `db-backup.cmd` | Create a PostgreSQL backup in `backups/`. |
| `db-list-backups.cmd` | List recent backups. |
| `db-restore.cmd` | Restore a backup. Requires `-Force` to overwrite data. |
