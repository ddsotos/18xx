# 状態・Action・既存コードとの接続

[設計目次](../README.md)

## 1. 実装境界

`Engine::Game::GRotLA` は提案モジュール名。
`Game < Engine::Game::Base` を基点とし、専用Round/Stepと不変のデータ定義を置く。
1867の合併は参照するが、100%小会社、融資、国有化を継承しない。

| 変更候補 | 目的 |
|---|---|
| `lib/engine/game/g_rotla/{meta,game,entities,map}.rb` | タイトル登録、データ、初期化、全体進行 |
| `g_rotla/round/{stock,operating,merger}.rb` | 手番とサブラウンド |
| `g_rotla/step/` | 各行動の合法性と実行 |
| `g_rotla/{map_builder,setup_manifest}.rb` | 後続の自由マップ変換・データ検証（提案） |
| `assets/app/view/game/` 等 | 既存Choose画面で足りない表示だけ追加 |
| `lib/engine/action/` | 既存Actionで表せない場合のみ型を追加 |

まず既存のBuyShares/SellShares/BuyTrain/Dividend/Choose等を使う。
ゲーム専用Stepが同じActionを文脈で制限する方式とし、独自の株購入プロトコルは作らない。

## 2. 正本となる状態

| 状態 | 所有者・保持方法 |
|---|---|
| 個人現金 | Player.cash。会社現金から独立 |
| 会社現金・列車・トークン | Corporation。Engine::Minorの100%単独経営モデルを使わない |
| 株券 | 既存Shareオブジェクト。所有者は個人・発行会社・銀行プール |
| 小会社株券構成 | [40,20,20,20]。1株単位20%、社長証券2株分 |
| 大会社株券構成 | [20,10,10,10,10,10,10,10,10]。1株単位10% |
| 固定設定 | settings.rotla（後述の新設スキーマ） |
| サイクル | 既存turnを1〜6として用いる案。別の独立カウンタを併用しない |
| OR番号 | Round.round_numを1/2に限定 |
| 競売の一時状態 | Stock Roundのround_state。発起人、最高入札者、辞退者、選択待ち |
| 合併の一時状態 | Merger Roundのround_state。提案、回答待ち、拒否済みの会社ペア |
| 会社の初回運営完了 | IDで管理した事実、または既存運営履歴から取得。株売却可否と共用 |
| 固有能力 | 能力の定義＋使用回数・配置トークンなどの状態。合併先に引継ぐ |
| 検索グラフ・UI候補 | 派生キャッシュ。保存の正本にしない |

株価90は小会社の20%あたりの価格。40%社長証券を90として数えない。
実装スパイクでCorporation.share_percent、ShareBundle価格、資金移動、得点評価を確認する。

## 3. 既存コードで確認した接続点

調査基準は設計目次のコミット。

| 既存コード | 確認事実 | 対応 |
|---|---|---|
| [Game::Base](../../../lib/engine/game/base.rb) initialize | hexes→graph→cities→phase→setup_preround→init_round→cache_objects→connect_hexes→setup→Action再生 | マップはinit_hexesより前に確定させる |
| 同 game_hexes / optional_hexes | データ供給のフックがある | RotLAで展開済みHEXESを返す |
| 同 next_round! | 既定はSR/OR中心の遷移 | 合併・輸出・6サイクル終局を専用に記述 |
| 同 clone(actions) | settings/init_kwargsを引継がない | RotLAのcloneで設定を維持。全ゲーム共通変更は別途必要性を評価 |
| [Step::Train](../../../lib/engine/step/train.rb) | 既定can_entity_buy_train?はentity.minor?を除外 | 提案Corporation表現での挙動を確認し、必要な範囲だけoverride |
| [Action::Base](../../../lib/engine/action/base.rb) | JSONのtypeをEngine::Action名前空間で解決する | g_rotla/actionだけに型を置いても自動解決されない |
| [Actionable](../../../assets/app/view/game/actionable.rb) | process_action後にActionを保存。HotseatはlocalStorageに書く | 同経路に乗せる |
| 同 check_consent | 同意済みの確認とLogを記録するUI | ルール上の回答待ちは専用Choose状態で検証する |

## 4. Baseの既定値をそのまま使わない箇所

以下は設定案であり、共通定数への無検証な代入一覧ではない。

| 既定 | RotLAで必要な扱い |
|---|---|
| CAPITALIZATION=:full | 使用しない。会社定義を`:incremental`とし、落札額全額と追加株の購入代金を会社へ入れる |
| SELL_MOVEMENT=:down_share | 通常SRは売却手番ごと同社1回下落 |
| HOME_TOKEN_TIMING=:operate | 設立時ホーム配置。Adaptiveは選択を挟む |
| MUST_BUY_TRAIN=:route | 路線の有無にかかわらず列車なしなら購入義務 |
| EBUY_OWNER_MUST_HELP=false | 強制購入時の社長負担 |
| MUST_EMERGENCY_ISSUE_BEFORE_EBUY=false | 自動発行を追加しない。任意発行は早いStepで終わる |
| GAME_END_CHECKのbank等 | 通常フルは6サイクルまたは破産。Bank Breakとは分離 |

## 5. Action契約・エラー処理

各Stepに `actions(entity)`、検証、`process_*`、pass/完了条件を持たせる。
UIがボタンを隠していても、不正なActionを読み込んだらエンジン側で拒否する。
未知ID、負数、過剰保有、手番違い、古い提案への同意は状態変更前に検証する。

提案用Chooseキーは `launch:<id>`、`merge_accept:<proposal_id>` 等の
安定した文字列とし、表示ラベルや配列の並び番号に依存しない。
専用Actionを追加する場合はJSON往復とRuby/Opal両方の型登録をテストする。

複数移動を伴う設立・合併・購入は「全検証→移動計画→適用→ログ」の順。
例外後に一部の現金・株だけ動いたままになるのを避ける。
任意のRubyオブジェクトを丸ごとJSON化せず、初期設定と既存Actionを再生する。

## 6. 不変条件

- 各会社の株式割合合計100%。全株券の所有者は一意。
- 各列車・トークン・物理タイルの所有/配置先は一意。
- 個人/会社の現金は非負。銀行との入出金を含めて移動ログで説明できる。
- 各ORで各会社が高々1回運営する。
- 同じ設定・seed・Action列から同じ状態になる。壁時計や未seedのshuffleをルール処理に使わない。
- 合併で旧会社が消えても、履歴の旧IDを再生途中で解決できる。
