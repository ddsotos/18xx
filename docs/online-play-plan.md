# 身内向けオンラインプレイ方針

## 目的

この文書は、身近な友人とそれぞれの PC から 18xx をオンラインプレイするための実行方針をまとめる。

不特定多数への公開、本格的な商用運用、独自の本番インフラ構築は当面の対象外とする。

実際に使うコマンドだけ確認したい場合は [身内オンラインプレイ Quickstart](online-play-quickstart.md) を参照する。

## 採用方針

推奨構成は次のとおり。

```text
友人のブラウザ
  -> Cloudflare Access
  -> Cloudflare Tunnel
  -> Docker上の cloudflared
  -> http://rack:9292
  -> 18xx dev stack
```

## 採用するもの

### Cloudflare Tunnel

友人側に VPN クライアントを入れてもらわず、ブラウザで URL を開くだけで参加できるようにするため、Cloudflare Tunnel を使う。

ルーターのポート開放は行わない。ホスト PC から Cloudflare へ外向き接続を張り、Cloudflare 経由でローカルの 18xx サーバーへ転送する。

### Named Tunnel

一時的な Quick Tunnel ではなく、Cloudflare の Named Tunnel を使う。

理由:

- URL を固定できる。
- 継続中のゲームで接続先を変えずに済む。
- Cloudflare Access と組み合わせて管理しやすい。

### Cloudflare Access

URL を知っているだけでは入れないように、Cloudflare Access で友人のメールアドレスだけを許可する。

友人側の操作は、ブラウザで URL を開き、メール認証を通す形にする。

### dev stack

18xx 側は本番用 compose ではなく、開発用構成を使う。

起動は原則として次を使う。

```powershell
.\scripts\online\dev-up.cmd
```

理由:

- nginx や Let's Encrypt 証明書が不要。
- `NEW_RELIC_LICENSE_KEY`、`ELASTIC_KEY`、`SLACK_WEBHOOK_URL` などの本番用外部サービス設定が不要。
- ローカル開発中のコードをそのまま動かせる。

### Docker 上の cloudflared

Docker Compose の `tunnel` profile で `cloudflared` コンテナを起動する。

理由:

- ホスト PC に `cloudflared` を直接インストールしなくてよい。
- 18xx stack と Tunnel を同じ Docker Compose project で管理できる。
- token を `.env.online.local` に分離できる。

安定運用が必要になったら、後でホスト側の Windows service 化も検討する。

## 使わないもの

### production compose

当面は `docker-compose.prod.yml` を使わない。

理由:

- 本家 `18xx.games` 向けの nginx 設定が含まれている。
- TLS 証明書パスが `/etc/letsencrypt/live/18xx.games/` に固定されている。
- 本番用環境変数チェックが厳しく、身内プレイには不要な外部サービス設定まで要求される。
- `rack` と `rack_backup` の二重構成は、少人数プレイでは過剰。

### Tailscale / VPN

今回は採用しない。

理由:

- 友人側に VPN クライアントの導入が必要になる。
- 「ブラウザで URL を開くだけ」に比べると参加ハードルが上がる。

### ルーターのポート開放

採用しない。

理由:

- 自宅ネットワークに直接入口を作ることになる。
- ルーターやプロバイダ環境によって手順が変わる。
- Cloudflare Tunnel で代替できる。

## 初期セットアップの想定手順

実際の作業手順は [Cloudflare Tunnel セットアップ手順](cloudflare-tunnel-runbook.md) にまとめる。

1. Cloudflare にドメインを登録する。
2. Cloudflare で Named Tunnel を作成する。
3. Tunnel の公開 hostname を作る。
4. 公開 hostname の転送先を `http://rack:9292` にする。
5. Cloudflare Access で、参加する友人のメールアドレスだけを許可する。
6. `.env.online.local` を作成する。

```powershell
.\scripts\online\init-env.cmd
```

7. Cloudflare の Tunnel token を `.env.online.local` に保存する。
8. ローカル stack と Tunnel を起動する。

```powershell
.\scripts\online\play-start.cmd
```

9. ブラウザでローカル確認する。

```text
http://localhost:9293
```

10. 公開 URL をコマンドで確認する。

```powershell
.\scripts\online\check-public.cmd
```

11. 友人に Cloudflare 側の URL を共有する。

## 運用上の注意

ホスト PC の電源が落ちるとプレイできなくなる。

通常起動は `.\scripts\online\online-up.cmd` を使う。これは 18xx stack を起動し、ローカル HTTP 応答を待ち、`cloudflared` を起動する。

通常停止は `.\scripts\online\online-down.cmd` を使う。

プレイ日の運用では、開始前・終了後バックアップも含む `.\scripts\online\play-start.cmd` と `.\scripts\online\play-stop.cmd` を使う。

長期戦のゲームを遊ぶ場合は、プレイ終了後や大きな更新前に `.\scripts\online\db-backup.cmd` で PostgreSQL のバックアップを取る。バックアップ手順と復元手順は [Cloudflare Tunnel セットアップ手順](cloudflare-tunnel-runbook.md) にまとめる。

Cloudflare Access の許可対象メールアドレスは、参加者が増減するたびに見直す。

## 今後の作業

1. ローカルで `.\scripts\online\dev-up.cmd` が正常に起動することを確認する。
2. Cloudflare Tunnel の Named Tunnel 設定手順を実作業に合わせて追記する。
3. Cloudflare Access のメール制限設定を確認する。
4. 友人のブラウザからアクセスできることを確認する。
5. 必要に応じてバックアップを外部ストレージへ定期コピーする。
