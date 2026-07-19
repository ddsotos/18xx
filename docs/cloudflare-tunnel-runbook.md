# Cloudflare Tunnel セットアップ手順

## 前提

この手順は、身内向けオンラインプレイ用にローカルの 18xx dev stack を Cloudflare Tunnel 経由で共有するためのもの。

当面は独自ドメインなしで使える Cloudflare Quick Tunnel を採用する。固定 URL やメール制限が必要になった場合だけ、後で Named Tunnel と Cloudflare Access へ移行する。

## Quick Tunnel で始める

### 1. Docker Desktop を起動する

Docker Desktop が起動していることを確認する。

```powershell
docker info
```

### 2. 18xx stack を起動する

```powershell
.\scripts\online\dev-up.cmd -Detach -Wait
```

初回は Docker image のビルドや JavaScript assets のコンパイルで時間がかかる。

### 3. ローカル表示を確認する

ホスト PC のブラウザで開く。

```text
http://localhost:9293
```

またはコマンドで確認する。

```powershell
.\scripts\online\doctor.cmd
```

### 4. Quick Tunnel を起動する

Docker で `cloudflared` を一時実行する場合:

```powershell
docker run --rm -it cloudflare/cloudflared:latest tunnel --no-autoupdate --url http://host.docker.internal:9293
```

ホスト PC に `cloudflared` をインストールしている場合:

```powershell
cloudflared tunnel --url http://localhost:9293
```

起動後、ターミナルに `https://...trycloudflare.com` の URL が表示される。その URL を友人に共有する。

このターミナルを閉じる、または `Ctrl+C` で止めると URL は無効になる。

### 5. プレイ終了後にバックアップする

```powershell
.\scripts\online\db-backup.cmd
```

バックアップは既定で `backups/` に保存される。

### 6. 停止する

Quick Tunnel を動かしているターミナルで `Ctrl+C` を押す。

その後、18xx stack を停止する。

```powershell
.\scripts\online\dev-down.cmd
```

## 中断と再開

Quick Tunnel の URL が変わっても、ゲーム状態はローカル DB に残る。

再開するときは、もう一度 18xx stack と Quick Tunnel を起動し、新しい `trycloudflare.com` URL を友人に共有する。

消してはいけないもの:

- Docker volume
- `docker compose down -v` 相当で削除される DB データ
- `backups/` に保存したバックアップ

## ローカル操作

状態を確認する:

```powershell
.\scripts\online\status.cmd
```

全体の概要を確認する:

```powershell
.\scripts\online\overview.cmd
```

ログを見る:

```powershell
.\scripts\online\logs.cmd -Service rack
```

追跡表示する:

```powershell
.\scripts\online\logs.cmd -Service rack -Follow
```

トラブル情報をまとめる:

```powershell
.\scripts\online\collect-diagnostics.cmd
```

出力先は `diagnostics/`。git 管理しない。

## DB バックアップ

長期戦のゲームを遊ぶ場合は、プレイ終了後や大きな更新前にバックアップを取る。

```powershell
.\scripts\online\db-backup.cmd
```

ファイル名を指定する場合:

```powershell
.\scripts\online\db-backup.cmd -FileName before-play.dump
```

最近のバックアップを確認する:

```powershell
.\scripts\online\db-list-backups.cmd
```

## DB 復元

復元は現在のオンラインプレイ用 DB を上書きする。

まず `-Force` なしで対象ファイルを確認する。

```powershell
.\scripts\online\db-restore.cmd .\backups\18xx-online-YYYYMMDD-HHMMSS.dump
```

問題なければ `-Force` を付けて復元する。

```powershell
.\scripts\online\db-restore.cmd .\backups\18xx-online-YYYYMMDD-HHMMSS.dump -Force
```

復元スクリプトは既定で復元前バックアップを作成する。

## トラブルシュート

### `http://localhost:9293` が開けない

18xx dev stack が起動しているか確認する。

```powershell
.\scripts\online\status.cmd
```

`rack`、`queue`、`db`、`redis` が起動しているか確認する。

`rack` のログを見る。

```powershell
.\scripts\online\logs.cmd -Service rack
```

### `trycloudflare.com` URL が開けない

まずローカルの `http://localhost:9293` が開けるか確認する。

次に、Quick Tunnel を起動しているターミナルがまだ動いているか確認する。止まっている場合は、もう一度 Quick Tunnel を起動して新しい URL を共有する。

Docker で Quick Tunnel を起動している場合、転送先は `http://host.docker.internal:9293` にする。`localhost:9293` は cloudflared コンテナ自身を指すため使わない。

### F5 しないと他人の操作が反映されない

18xx のリアルタイム反映は `/message-bus/<client-id>/poll` への long polling で動く。

ブラウザの開発者ツールで Network を開き、`message-bus` を検索する。`poll` が 500 になる場合は rack ログを確認する。

オンライン用 compose では `RACK_ENV=online` にしている。これは Rack の開発用 Lint が `message_bus` のレスポンスヘッダを 500 にしないようにするため。DB migration は引き続き `rake dev_up` が development DB に対して実行する。

### 友人だけ入れない

友人に次を確認してもらう。

- 最新の URL を開いているか。
- URL を途中でコピーし損ねていないか。
- ブラウザ更新で改善するか。

Quick Tunnel では Cloudflare Access のメール認証は使わない。URL を知っている人はアクセスできる前提で扱う。

## 将来: Named Tunnel に移行する場合

固定 URL や Cloudflare Access のメール制限が必要になったら、独自ドメインを用意して Named Tunnel に移行する。

その場合の構成:

```text
友人のブラウザ
  -> Cloudflare Access
  -> Cloudflare Tunnel
  -> Docker上の cloudflared
  -> http://rack:9292
  -> 18xx dev stack
```

Cloudflare dashboard の Public Hostname は次にする。

```text
Service type: HTTP
Service URL: http://rack:9292
```

Docker Compose の `tunnel` profile を使う場合、Service URL は `http://rack:9292` にする。`localhost:9293` はホスト PC のブラウザ確認用であり、Docker 上の `cloudflared` からは使わない。

Named Tunnel では `.env.online.local` に token と公開 URL を設定する。

```text
CLOUDFLARE_TUNNEL_TOKEN=<Cloudflare dashboard の token>
CLOUDFLARE_PUBLIC_URL=https://18xx.example.com
ONLINE_PORT=9293
```

起動前確認:

```powershell
.\scripts\online\preflight.cmd -RequireToken -RequirePublicUrl
```

起動:

```powershell
.\scripts\online\play-start.cmd
```

## 参考

- Cloudflare Quick Tunnels: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/
- Cloudflare Tunnel overview: https://developers.cloudflare.com/tunnel/
- Cloudflare Tunnel routing: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/routing-to-tunnel/
- `cloudflared` downloads: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/
