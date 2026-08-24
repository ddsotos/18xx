# 身内向けオンラインプレイ方針

## 目的

この文書は、身近な友人とそれぞれの PC から 18xx をオンラインプレイするための実行方針をまとめる。

不特定多数への公開、本格的な商用運用、独自の本番インフラ構築は当面の対象外とする。

実際に使うコマンドだけ確認したい場合は [身内オンラインプレイ Quickstart](online-play-quickstart.md) を参照する。

## 当面の採用方針

当面は Cloudflare Quick Tunnel を使う。

```text
友人のブラウザ
  -> https://ランダム文字列.trycloudflare.com
  -> Cloudflare Quick Tunnel
  -> ホスト PC 上の cloudflared
  -> http://localhost:9293
  -> 18xx dev stack
```

## 採用するもの

### Cloudflare Quick Tunnel

友人側に VPN クライアントを入れてもらわず、ブラウザで URL を開くだけで参加できるようにするため、Cloudflare Quick Tunnel を使う。

独自ドメインは不要。Cloudflare アカウントなしでも `*.trycloudflare.com` のランダム URL を発行できる。

ルーターのポート開放は行わない。ホスト PC から Cloudflare へ外向き接続を張り、Cloudflare 経由でローカルの 18xx サーバーへ転送する。

制約:

- URL は起動のたびに変わる。
- `cloudflared` を止めると URL は無効になる。
- Cloudflare Access のメール制限とは組み合わせにくい。
- テスト・開発向けの機能であり、長期固定 URL や安定運用の保証は前提にしない。

### dev stack

18xx 側は本番用 compose ではなく、開発用構成を使う。

起動は原則として次を使う。

```powershell
.\scripts\online\dev-up.cmd -Detach -Wait
```

理由:

- nginx や Let's Encrypt 証明書が不要。
- `NEW_RELIC_LICENSE_KEY`、`ELASTIC_KEY`、`SLACK_WEBHOOK_URL` などの本番用外部サービス設定が不要。
- ローカル開発中のコードをそのまま動かせる。

### Friend Login

オンライン用 compose では `FRIEND_LOGIN_ENABLED=true` を設定し、パスワードなしの `Friend Login` を有効にする。

友人は User Name と Email だけで入る。初回は User Name と Email でユーザーを作成し、次回以降は Email だけで同じユーザーとしてログインできる。

未登録の Email で既存の User Name を使った場合は拒否する。これにより、同じ名前で別メールの誤ログインを避ける。

### Docker またはホスト上の cloudflared

Quick Tunnel はどちらの方法でも起動できる。

ホスト PC に `cloudflared` を入れる場合:

```powershell
cloudflared tunnel --url http://localhost:9293
```

Docker で一時実行する場合:

```powershell
docker run --rm -it cloudflare/cloudflared:latest tunnel --no-autoupdate --url http://host.docker.internal:9293
```

まずは Docker の一時実行でよい。`cloudflared` をホスト PC に入れると、毎回のコマンドは少し短くなる。

## 当面使わないもの

### Cloudflare Access

Quick Tunnel のランダム URL は自分の管理ドメインではないため、Cloudflare Access で「友人のメールアドレスだけ許可する」運用とは相性が悪い。

当面は URL を知っている人がアクセスできる前提で運用し、URL は参加者以外へ転送しない。

メール制限まで必要になったら、独自ドメインを取得し、Named Tunnel と Cloudflare Access へ移行する。

### Named Tunnel

当面は使わない。

Named Tunnel は固定 URL と Cloudflare Access を使いたい場合の将来案とする。利用するには、Cloudflare 管理下の独自ドメインを用意するのが自然。

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

1. Docker Desktop を起動する。
2. 18xx stack を起動する。

```powershell
.\scripts\online\dev-up.cmd -Detach -Wait
```

3. ローカルで表示を確認する。

```text
http://localhost:9293
```

4. Quick Tunnel を起動する。

```powershell
docker run --rm -it cloudflare/cloudflared:latest tunnel --no-autoupdate --url http://host.docker.internal:9293
```

5. 表示された `https://...trycloudflare.com` URL を友人に共有する。

## 運用上の注意

ホスト PC の電源が落ちるとプレイできなくなる。

Quick Tunnel を停止すると、その URL は使えなくなる。再開時は新しい URL を発行して共有する。

ゲーム状態は Quick Tunnel 側ではなくローカル DB に保存される。URL が変わっても、ローカル DB を消していなければ続きから再開できる。

長期戦のゲームを遊ぶ場合は、プレイ終了後や大きな更新前に `.\scripts\online\db-backup.cmd` で PostgreSQL のバックアップを取る。

## 今後の作業

1. Quick Tunnel 起動用の補助スクリプトが必要か、実運用しながら判断する。
2. 必要に応じてバックアップを外部ストレージへ定期コピーする。
3. 固定 URL やメール制限が必要になったら、独自ドメイン、Named Tunnel、Cloudflare Access へ移行する。
