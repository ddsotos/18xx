# 身内オンラインプレイ Quickstart

Cloudflare Tunnel を使って、友人がブラウザだけで参加できるようにするための最短手順。

詳細は [Cloudflare Tunnel セットアップ手順](cloudflare-tunnel-runbook.md) を参照する。

## 初回セットアップ

1. Cloudflare Zero Trust で Named Tunnel を作る。
2. Public Hostname を設定する。

```text
Service type: HTTP
Service URL: http://rack:9292
```

3. Cloudflare Access で参加者のメールアドレスだけを許可する。
4. ローカル設定ファイルを作る。

```powershell
.\scripts\online\init-env.cmd
notepad .env.online.local
```

5. `.env.online.local` を設定する。

```text
CLOUDFLARE_TUNNEL_TOKEN=<Cloudflare dashboard の token>
CLOUDFLARE_PUBLIC_URL=https://18xx.example.com
ONLINE_PORT=9293
```

6. 設定を確認する。

```powershell
.\scripts\online\preflight.cmd -RequireToken -RequirePublicUrl
```

## プレイ開始

```powershell
.\scripts\online\play-start.cmd
```

このコマンドは、開始前バックアップ、18xx stack 起動、Tunnel 起動、公開 URL 確認まで行う。

## プレイ終了

```powershell
.\scripts\online\play-stop.cmd
```

このコマンドは、終了後バックアップを取ってから Tunnel と 18xx stack を停止する。

## 状態確認

```powershell
.\scripts\online\overview.cmd
```

## トラブル時

```powershell
.\scripts\online\collect-diagnostics.cmd
```

出力は `diagnostics/` に保存される。token 値は保存しない。

## 友人へ送るもの

- Cloudflare の公開 URL
- [友人向けアクセス手順](friend-access-guide.md)
