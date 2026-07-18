# Cloudflare Tunnel セットアップ手順

## 前提

この手順は、身内向けオンラインプレイ用にローカルの 18xx dev stack を Cloudflare Tunnel 経由で共有するためのもの。

最短の実行手順だけ確認したい場合は [身内オンラインプレイ Quickstart](online-play-quickstart.md) を参照する。

前提:

- ホスト PC に Docker Desktop が入っている。
- Cloudflare アカウントがある。
- Cloudflare 管理下のドメインがある。
- ホスト PC に `cloudflared` をインストールできる。

Cloudflare Tunnel で固定の公開 hostname を使うには、Cloudflare アカウントと Cloudflare 管理下のドメインが必要。

## 最短手順

初回だけ行う。

```powershell
.\scripts\online\init-env.cmd
notepad .env.online.local
.\scripts\online\preflight.cmd -RequireToken -RequirePublicUrl
```

`.env.online.local` には Cloudflare dashboard の token、公開 URL、ローカルポートを設定する。

```text
CLOUDFLARE_TUNNEL_TOKEN=<Cloudflare dashboard の token>
CLOUDFLARE_PUBLIC_URL=https://18xx.example.com
ONLINE_PORT=9293
```

Cloudflare dashboard の Public Hostname は次にする。

```text
Service type: HTTP
Service URL: http://rack:9292
```

プレイ開始時:

```powershell
.\scripts\online\play-start.cmd
```

プレイ終了時:

```powershell
.\scripts\online\play-stop.cmd
```

既に stack が止まっていてバックアップ不要な場合:

```powershell
.\scripts\online\play-stop.cmd -SkipBackup
```

トラブル時:

```powershell
.\scripts\online\overview.cmd
.\scripts\online\collect-diagnostics.cmd
```

## ローカル起動

Windows では Makefile の `ln -s` や `sudo` が使いにくいため、オンラインプレイ用の `docker-compose.online.yml` を直接指定する。

この compose は、Cloudflare Tunnel に必要な `rack` だけをホストへ公開する。既定のホスト側ポートは `9293` で、コンテナ内の `9292` へ転送する。PostgreSQL と Redis は Docker ネットワーク内だけで使い、ホストの `5433` や `6380` は使わない。

PowerShell でリポジトリ直下から実行する。

```powershell
.\scripts\online\dev-up.cmd
```

バックグラウンドで起動する場合:

```powershell
.\scripts\online\dev-up.cmd -Detach
```

起動後にローカル HTTP 応答まで待つ場合:

```powershell
.\scripts\online\dev-up.cmd -Detach -Wait
```

起動後、ホスト PC のブラウザで確認する。

```text
http://localhost:9293
```

初回アクセス時は JavaScript assets のコンパイルが走るため、応答まで 1 分前後かかることがある。2 回目以降は短くなる。

既に起動済みで、初回コンパイル完了だけを待つ場合:

```powershell
.\scripts\online\wait-local.cmd
```

停止する場合:

```powershell
.\scripts\online\dev-down.cmd
```

状態を確認する場合:

```powershell
.\scripts\online\status.cmd
```

全体の概要を確認する場合:

```powershell
.\scripts\online\overview.cmd
```

ローカル側の事前診断をまとめて実行する場合:

```powershell
.\scripts\online\doctor.cmd
```

Cloudflare Tunnel を使う直前に `cloudflared` も必須として確認する場合:

```powershell
.\scripts\online\doctor.cmd -RequireCloudflared
```

## Cloudflare Tunnel

Cloudflare Zero Trust dashboard で Named Tunnel を作成する。

Dashboard での設定方針:

- Tunnel type: Cloudflared
- Tunnel name: 任意。例: `18xx-online`
- Public hostname: 友人に共有するサブドメイン。例: `18xx.example.com`
- Service type: `HTTP`
- Service URL: `http://rack:9292`

Docker で `cloudflared` を動かす場合、Service URL は `http://rack:9292` にする。`localhost:9293` はホスト PC のブラウザ確認用であり、`cloudflared` コンテナ内からは使わない。

Dashboard に表示される `cloudflared` の install/run コマンドをホスト PC で実行する。

Tunnel が `Healthy` になったら、Cloudflare 側の URL から 18xx にアクセスできる。

### Docker で Tunnel を起動する

推奨は、ホスト PC に `cloudflared` を直接入れず、Docker Compose の `tunnel` profile で `cloudflared` コンテナを起動する方法。

Cloudflare dashboard で Named Tunnel を作成すると、run token が表示される。その token を `.env.online.local` に保存する。

```powershell
.\scripts\online\init-env.cmd
notepad .env.online.local
```

既に `.env.online.local` がある場合、`init-env.cmd` は不足しているキーだけを追記する。

`.env.online.local` の `CLOUDFLARE_TUNNEL_TOKEN=` の右側に token を貼る。

```text
CLOUDFLARE_TUNNEL_TOKEN=<Cloudflare dashboard の token>
CLOUDFLARE_PUBLIC_URL=https://18xx.example.com
ONLINE_PORT=9293
```

`.env.online.local` は git 管理しない。token はチャットや issue に貼らない。

設定値の事前確認:

```powershell
.\scripts\online\preflight.cmd -RequireToken -RequirePublicUrl
```

通常は、18xx stack と Tunnel をまとめて起動する。

```powershell
.\scripts\online\online-up.cmd
```

ビルドを省いて再起動する場合:

```powershell
.\scripts\online\online-up.cmd -NoBuild
```

Tunnel ログを見る。

```powershell
.\scripts\online\tunnel-logs.cmd
```

追跡表示する場合:

```powershell
.\scripts\online\tunnel-logs.cmd -Follow
```

Tunnel を止める場合:

```powershell
.\scripts\online\tunnel-down.cmd
```

18xx stack も含めて止める場合:

```powershell
.\scripts\online\online-down.cmd
```

個別に起動したい場合は、次の順に実行する。

```powershell
.\scripts\online\dev-up.cmd -Detach -Wait
.\scripts\online\tunnel-up.cmd -Detach
```

### ホストに cloudflared を入れる場合

Windows で `cloudflared` を手動インストールする場合は、Cloudflare 公式の Windows MSI または実行ファイルを使う。Windows 版 `cloudflared` は自動更新されないため、定期的に更新を確認する。

継続して使う場合は、Cloudflare dashboard に表示される Windows service 用コマンドで `cloudflared` をサービス化すると、PC 起動後に手動で Tunnel を立ち上げる手間が減る。

Named Tunnel 作成後の確認順:

1. `.\scripts\online\preflight.cmd -RequireToken -RequirePublicUrl` が通る。
2. `.\scripts\online\doctor.cmd` が local HTTP まで通る。
3. Cloudflare dashboard の Tunnel status が `Healthy` になっている。
4. Public hostname の route が `http://rack:9292` に向いている。
5. Cloudflare 側 URL を開くと Cloudflare Access 認証画面が出る。
6. 認証後に 18xx の画面が表示される。

## Cloudflare Access

URL を知っているだけでは入れないように、Cloudflare Access で self-hosted application を作成する。

設定方針:

- Application type: Self-hosted
- Application domain: Tunnel の public hostname と同じもの
- Policy action: Allow
- Include selector: Emails
- Values: 参加者のメールアドレス

`Everyone` や `All valid emails` を許可しない。

友人側は、共有 URL をブラウザで開き、Cloudflare Access のメール認証を通ってから 18xx に入る。

推奨ポリシー例:

```text
Application domain: 18xx.example.com
Policy name: 18xx friends
Action: Allow
Include: Emails
Values:
  alice@example.com
  bob@example.com
```

参加者を追加するときは、Cloudflare Access の Allow policy にメールアドレスを追加する。削除するときは、そのメールアドレスを policy から外す。

確認時は、主催者自身の通常ブラウザではなく、シークレットウィンドウで Cloudflare 側 URL を開く。Access 認証画面が出ることを確認してから、自分の許可済みメールでログインする。

コマンドで公開 URL の応答を見る場合:

```powershell
.\scripts\online\check-public.cmd https://18xx.example.com
```

Cloudflare Access が有効な場合、認証画面への redirect が返ることがある。これは期待される挙動。

## 運用チェックリスト

プレイ開始前:

1. Docker Desktop が起動している。
2. `.\scripts\online\play-start.cmd` で開始前バックアップ、18xx dev stack、Tunnel、公開URL確認が通っている。
3. `.\scripts\online\doctor.cmd` が local HTTP まで通る。
4. `.\scripts\online\tunnel-logs.cmd` に接続エラーが出ていない。
5. `.\scripts\online\check-public.cmd` が期待どおりの応答を返す。
6. Cloudflare Tunnel が `Healthy` になっている。
7. Cloudflare Access に参加者のメールアドレスが入っている。
8. Cloudflare 側の URL をシークレットウィンドウで開き、Access 認証が出ることを確認する。
9. 参加者には [友人向けアクセス手順](friend-access-guide.md) と URL を共有する。

プレイ終了後:

1. `.\scripts\online\play-stop.cmd` で終了後バックアップを取り、Tunnel と 18xx stack を停止する。
2. バックアップ一覧を `.\scripts\online\db-list-backups.cmd` で確認する。

## DB バックアップ

長期戦のゲームを遊ぶ場合は、プレイ終了後や大きな更新前にバックアップを取る。

```powershell
.\scripts\online\db-backup.cmd
```

バックアップは既定で `backups/` に保存される。ファイル名は `18xx-online-YYYYMMDD-HHMMSS.dump` 形式になる。

直近のバックアップを確認する場合:

```powershell
.\scripts\online\db-list-backups.cmd
```

保存先やファイル名を指定する場合:

```powershell
.\scripts\online\db-backup.cmd -OutputDir D:\18xx-backups
.\scripts\online\db-backup.cmd -FileName before-update.dump
```

`backups/` は git 管理しない。

## DB 復元

復元は現在のオンラインプレイ用 DB を上書きする。

まず、`-Force` なしで実行して対象ファイルを確認する。

```powershell
.\scripts\online\db-restore.cmd .\backups\18xx-online-YYYYMMDD-HHMMSS.dump
```

問題なければ `-Force` を付けて復元する。

```powershell
.\scripts\online\db-restore.cmd .\backups\18xx-online-YYYYMMDD-HHMMSS.dump -Force
```

復元スクリプトは既定で復元前バックアップを作成する。その後、`rack` と `queue` を止め、DB をリセットしてから backup を投入し、最後に `rack` と `queue` を起動し直す。

復元前バックアップが不要な場合だけ、明示的に `-SkipPreRestoreBackup` を付ける。

## トラブルシュート

### `http://localhost:9293` が開けない

18xx dev stack が起動していない可能性が高い。

```powershell
.\scripts\online\status.cmd
```

`rack`、`queue`、`db`、`redis` が起動しているか確認する。

`rack` のログを見る場合:

```powershell
.\scripts\online\logs.cmd -Service rack
```

追跡表示する場合:

```powershell
.\scripts\online\logs.cmd -Service rack -Follow
```

初回アクセス直後に `Compiling ...` が大量に出ている場合は、assets コンパイル中なので完了を待つ。

### `queue` が落ちている

`queue` のログを見る。

```powershell
.\scripts\online\logs.cmd -Service queue
```

DB migration より先に起動した場合は落ちることがある。通常は次で再作成できる。

```powershell
.\scripts\online\dev-up.cmd -Detach -NoBuild
```

### Cloudflare URL だけ開けない

まず Cloudflare Tunnel が `Healthy` か確認する。

次に、Tunnel の Service URL が `http://rack:9292` になっているか確認する。Docker Tunnel モードでは `localhost:9293` にしない。

Docker Tunnel のログを見る。

```powershell
.\scripts\online\tunnel-logs.cmd
```

`CLOUDFLARE_TUNNEL_TOKEN is not set` が出る場合は、`.env.online.local` に token が入っていない。

まとめて情報を集める場合:

```powershell
.\scripts\online\collect-diagnostics.cmd
```

出力先は `diagnostics/` で、git 管理しない。

### Access 認証後に 18xx が表示されない

Cloudflare Access の application domain と Tunnel の public hostname が一致しているか確認する。

### 友人だけ入れない

Cloudflare Access の Allow policy に友人のメールアドレスが入っているか確認する。

メール認証リンクの有効期限切れもあり得るため、再度ログインしてもらう。

## 後で検討すること

- `cloudflared` を Windows サービスとして常駐させる。
- バックアップを外部ストレージへ定期コピーする。

## 参照

- Cloudflare Tunnel overview: https://developers.cloudflare.com/tunnel/
- Cloudflare Tunnel setup: https://developers.cloudflare.com/tunnel/setup/
- Cloudflare Tunnel routing: https://developers.cloudflare.com/tunnel/routing/
- `cloudflared` downloads: https://developers.cloudflare.com/tunnel/downloads/
- Run `cloudflared` as a service: https://developers.cloudflare.com/tunnel/advanced/local-management/as-a-service/
