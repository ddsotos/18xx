# 身内オンラインプレイ Quickstart

Cloudflare Quick Tunnel を使って、友人がブラウザだけで参加できるようにするための最短手順。

この手順では独自ドメイン、Cloudflare Access、Named Tunnel は使わない。遊ぶたびに `*.trycloudflare.com` のランダム URL を発行して共有する。

## 前提

- Docker Desktop が起動している。
- ローカルの 18xx stack は `http://localhost:9293` で開く。
- Quick Tunnel の URL は `cloudflared` を止めると無効になる。
- 起動し直すたびに URL は変わる。

## プレイ開始

1. 18xx stack を起動する。

```powershell
.\scripts\online\dev-up.cmd -Detach -Wait
```

2. ホスト PC のブラウザでローカル表示を確認する。

```text
http://localhost:9293
```

3. Quick Tunnel を起動する。

ホスト PC に `cloudflared` を入れている場合:

```powershell
cloudflared tunnel --url http://localhost:9293
```

Docker で `cloudflared` を動かす場合:

```powershell
docker run --rm -it cloudflare/cloudflared:latest tunnel --no-autoupdate --url http://host.docker.internal:9293
```

4. ターミナルに表示された `https://...trycloudflare.com` の URL を友人に共有する。

## 友人のログイン

オンライン用 compose では、パスワードなしの `Friend Login` が有効になる。

初回ログインでは、友人に Login 画面で次を入力してもらう。

- User Name
- Email

一度作成済みのプレイヤーは、次回以降 Email だけで同じユーザーとしてログインできる。User Name は空でよい。

未登録の Email で User Name が空の場合は、初回ログインとして扱えないため拒否する。

未登録の Email で既存の User Name を使った場合は、別人のなりすましを避けるため拒否する。

オンライン用画面では、通常のパスワードログインと Signup は表示しない。

## プレイ終了

1. Quick Tunnel を動かしているターミナルで `Ctrl+C` を押す。
2. 必要なら DB バックアップを取る。

```powershell
.\scripts\online\db-backup.cmd
```

3. 18xx stack を停止する。

```powershell
.\scripts\online\dev-down.cmd
```

## 中断後の再開

Quick Tunnel の URL が変わっても、ゲーム状態はローカル DB に残る。

再開するときは、もう一度 18xx stack と Quick Tunnel を起動し、新しい `trycloudflare.com` URL を共有する。友人は新しい URL で開き直す。

ただし、`docker compose down -v`、Docker volume の削除、DB 初期化、リポジトリやデータディレクトリの削除をするとゲーム状態が失われる可能性がある。

## 状態確認

```powershell
.\scripts\online\overview.cmd
```

## トラブル時

```powershell
.\scripts\online\collect-diagnostics.cmd
```

出力は `diagnostics/` に保存される。

## 友人へ送るもの

- 今回発行された `https://...trycloudflare.com` の URL
- [友人向けアクセス手順](friend-access-guide.md)
