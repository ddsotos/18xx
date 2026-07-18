# Online Play Scripts

Windows 向けの身内オンラインプレイ補助スクリプト。

通常は `*.cmd` を実行する。`.ps1` は `.cmd` から呼ばれる実体。

## Daily Commands

| Command | Purpose |
| --- | --- |
| `play-start.cmd` | Start a play session: preflight, start stack, backup, start tunnel, check public URL. |
| `play-stop.cmd` | Stop a play session after taking a backup. |
| `overview.cmd` | Show local URL, public URL, token state, compose status, and local HTTP status. |
| `collect-diagnostics.cmd` | Write troubleshooting logs to `diagnostics/`. |

## Setup Commands

| Command | Purpose |
| --- | --- |
| `init-env.cmd` | Create or update `.env.online.local` from `.env.online.example`. |
| `preflight.cmd` | Validate local online settings before starting. |
| `doctor.cmd` | Check Docker, compose, local HTTP, and tunnel-related settings. |
| `check-public.cmd` | Check the Cloudflare public URL. |

## Lower-Level Commands

| Command | Purpose |
| --- | --- |
| `online-up.cmd` / `online-down.cmd` | Start or stop the stack and tunnel together. |
| `dev-up.cmd` / `dev-down.cmd` | Start or stop only the 18xx dev stack. |
| `tunnel-up.cmd` / `tunnel-down.cmd` | Start or stop only the Cloudflare Tunnel container. |
| `status.cmd` | Show compose service status. |
| `logs.cmd` | Show logs for `rack`, `queue`, `db`, or `redis`. |
| `tunnel-logs.cmd` | Show Cloudflare Tunnel logs. |
| `wait-local.cmd` | Wait until local HTTP responds. |

## Database Commands

| Command | Purpose |
| --- | --- |
| `db-backup.cmd` | Create a PostgreSQL backup in `backups/`. |
| `db-list-backups.cmd` | List recent backups. |
| `db-restore.cmd` | Restore a backup. Requires `-Force` to overwrite data. |
