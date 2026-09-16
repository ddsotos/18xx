# 実装進捗

[詳細設計の入口](../README.md)

## 2026-09-14：初期設定・座標計算

実装ブランチ：feat/rotla-setup-foundation。設計ブランチの9c4593cから分岐。

| 実装 | 範囲 |
|---|---|
| SetupConfig | settings.rotlaの構造・版・4人ロング条件、配置/プロジェクトのIDと入力型を検証 |
| 設定スナップショット | 入力から深くコピーして内部をfreeze、to_hも独立したJSON互換データを返す |
| MapGeometry | axial座標の0〜5回転、移動、配置集合の変換、重複と共有辺の判定 |
| RSpec | JSON往復、入力/出力の独立性、不正入力、既知の回転結果、共有辺数、幾何変換の不変性 |

SetupConfig.newはsettings.rotlaの値を受け取り、from_settingsは既存settings全体を受け取る。
設定スキーマは保存設計の例に従う。現段階では固定マップのみなのでsetup_journalは空配列に限定する。
to_hが成功しても、公式の全タイル・列車・都市の照合や盤面の合法性が確認されたことにはならない。
外部の公式部品台帳と照合する処理は次工程で追加する。

MapGeometryの方向番号は内部axial座標用であり、Engine::Hexの辺番号ではない。
EngineMapでflat layoutの倍精度座標・辺番号へ変換する。MapBuilderは物理タイル台帳と配置から
game_hexes形式を生成し、経路・border・stubを初期化中に回転する。回転partitionは明示的に拒否する。
地形・黒境界の合法性と首都効果の適用は未実装。
RSpec内の盤面は人工的な入力例であり、公式の固定マップではない。

## 2026-09-15：エンジン接続・保存複製

Setupモジュールを追加し、Base初期化より先に設定と実プレイヤー数を検証する。
Game.loadのsettings転送、生成されたseed、engine v2設定、Action再生、clone、Undoで
同じRotLA設定が維持されることを実際のGame::Base派生クラスで確認した。

人工3ヘックスを既存Engine::Hexへ変換し、回転後のpath・border・stub、隣接、Graph生成を確認した。
追加分を含むRotLA対象RSpecは52 examples、0 failures。変更6ファイルのRuboCopは違反0件。
Solの設計レビューとLunaのEngineMap実装を統合した。ブラウザ操作と全体compile_allは未確認。

FixedMapモジュールは、将来のGameクラスのMAP_CATALOGと保存manifestをMapBuilderへ渡し、
game_hexesとinit_hexesへ接続する。Setup→FixedMapのinclude順とクラス固有台帳を強制し、
cloneとAction再生でも同じ盤面を再構築する仕様テストを追加した。この追加4テストはPR上のCI確認待ち。

## 2026-09-15：4人フル列車・フェーズデータ

英語第2版の紙面p.3、p.7、p.16を再照合し、30枚の列車を
2×7、3×6、4×4、5×3、6×3、7/∞×7としてGameDataへ定義した。
4人用と印刷された追加3列車・6列車を含む。価格、4/6/7による廃車、
3/5/7の色フェーズ、各列車段階の小会社/大会社上限、4人開始資金275も定義した。
7/∞の800＋列車交換は専用購入Stepで処理するため、現時点の∞variantは通常価格1000だけを持つ。

## 2026-09-15：会社データ

4人ロングで使う小会社12社と、合併で選ぶ大会社6社の識別子・色・証券構成・hub費用を
Entitiesへ分離した。小会社は40%＋20%×3、ホームhub 1個。大会社は20%＋10%×8、
hubは無料2個・60・80とした。各小会社には会社名分岐を避けるため安定したability_idを割り当てた。
ホーム座標は生成マップmanifestから接続するため、Entitiesでは未確定値を持たない。

## 2026-09-15：小会社表・設立競売状態

保存設定へ3列×4社の初期minor_tableauを追加し、各列の先頭だけを候補として公開する
MinorTableauを実装した。初期生成には境界付き乱数を受け取るFisher–Yatesを用い、確定順そのものを
settingsへ保存する。競売は会社を先に指定しないFoundingAuctionStateへ分離し、最低120、5刻み、
辞退者の離脱、落札後の候補会社選択、発起人の次へ戻る手番を保持する。現金・株・ホームの移動は
全検証後に行う将来のStock Stepへ残し、この状態オブジェクトでは変更しない。
minor_tableauを必須化したためsettings schemaは2へ更新し、map manifestの版1とは独立させた。

## 2026-09-15：設立競売Step・財務確定

FoundingAuction Stepを追加し、通常手番のtargetless Bidで競売を開始、競売中だけ後続Stepを遮断する。
Bid/Pass/ChooseをFoundingAuctionStateへ接続し、会社選択時に全条件を事前検証してから、初期株価設定、
落札額全額の会社金庫への移動、40%社長証券の移管、会社表の更新を行う。株価は入札額半分以下へ
切り下げ、黄色90・緑110・紫/灰135のフェーズ上限を適用する。同値株価の会社は既存tokenの下へ
追加される。Adaptiveは財務確定後にpendingとして残し、ホーム選択を後続Stepへ分離した。

AdaptiveHome Stepを追加し、初期社長だけがEngine標準の都市IDをChooseできるようにした。候補の
基本都市分類は生成マップを知るGame側フックへ分離し、Stepは現在盤上の都市であること、都市・タイル予約、
通常・追加トークン、空きスロットを操作直前に再検証する。既設線路は候補から除外しない。確定時は無料の
先頭hubをCity APIで置き、ホーム座標とグラフを更新する。Adaptive選択前にも候補の存在を検証するため、
落札金・株・株価・会社表を変更した後にホーム不能で停止することはない。

物理マップcatalogの各ローカルhexに`city_type`（`basic` / `capital` / `company` / 都市なしの`nil`）を
必須化した。MapBuilderは配置・回転後の座標と分類を保持し、FixedMapの
`rotla_adaptive_home_cities`は`basic` hex上にある現在タイルのCityを返す。これにより既設線路や
タイルアップグレードを都市分類と混同しない。首都プロジェクト効果と実GameのStock Round配線は未完了。

Stock Round配線前の状態寿命も修正した。MinorTableauはFoundingAuction Stepごとの一時状態ではなく
Setupが生成するGame所有状態とし、後続SRの新しいStepも同じ除去済み表を参照する。新規Game・clone・
Action再生では初期settingsから表を作り、設立Action列によって同じ状態へ戻す。

通常株取引用のStockTrade Stepを追加した。会社金庫/市場からの普通株1株購入、売却後の任意購入、
購入後の手番終了、初回運営前売却・50%市場上限・60%個人上限・同SR買戻しの拒否をStep内で
再検証する。同一手番で同じ会社を複数回売却しても、全株を売却前価格で精算して終了時に1段階だけ
株価を下げる。株取引後の競売開始もUIとAction処理の両方で拒否する。会社定義は追加株代金を
会社へ入れる`incremental`資本方式にした。

Stock RoundのStep順は`StockRoundSteps`に集約し、`StockRound`モジュールの`Game#stock_round`から
RotLA専用`Round::Stock`へ渡す。専用Roundは浮動済みの小会社・大会社をSR終了時の処理対象にし、
全株が個人所有なら1段階上昇させる。証券上限はGame APIでも非表示・無制限とした。競売の各Bidは
通常passを解除し、最後の非pass行為として記録する。

初回SRで会社が1社も設立されず全員がpassした場合は、Gameのseed付き乱数で12社を再シャッフルし、
pass状態・pass順・最後の行為者を消して同じRoundを元の開始プレイヤーから再開する。2回目以降のSRや、
1社でも設立済みの場合には適用しない。

具体的なGameクラスへのmodule includeと、次SR優先権のfixture確認は未完了である。

W05の最初の独立Stepとして`LeadoffTrain`を追加した。新設小会社の初回運営冒頭だけ、列車山または
銀行プールにある現在購入可能な列車を、会社現金の範囲で定価購入できる。購入は任意で最大1台、
他社列車・社長補填・交換や追加指定をAction処理時にも拒否する。通常の`BuyTrain`とはpass状態を共有しない。
具体的なOperating RoundのStep列への組込みは、後続の運営Round実装で行う。

## 2026-09-16：能力なし完走vertical slice

`Meta`と具体的な`Game`を追加し、4人Hotseatのゲーム一覧から選択できるalpha実装へ接続した。
settingsを持たない新規作成には、4人ロング用の自己完結した既定settingsを渡す。保存・cloneでは従来どおり
完全manifestを維持する。現時点の`long4-playable-v0`はラウンド実装を進めるための開発用固定マップであり、
公式33部品を照合した盤面ではない。12個の3ヘックス物理コピー、11社の固定ホーム、Adaptive用基本都市を持つ。

Operating Roundは`LeadoffTrain → IssueOrRedeem → Track → Token → Route → Dividend → DiscardTrain → BuyTrain`
へ接続した。開発用固定マップは印刷済み全接続線路のためTrackを自動skipする。発行/買戻しは普通株1株だけ、
配当株価は総収益と現在株価の0/1/2段階ルールを使う。通常列車購入では列車なしを強制購入とし、他社購入を許す。

SR→OR1→OR2→MR境界→列車輸出→次SRを6サイクル繰り返し、最終MR境界で得点確定する。
緑フェーズ以降のMRでは、小会社と未使用大会社を組にしたChooseから能力なし合併を実行する。旧2社の
個人・市場・自己保有株を20%→10%へ換算し、合計保有が最多の個人を新社長とする。株価は旧2社の平均以下へ
切り下げ、現金・列車・配置済みhubを移管する。同じ都市のhub重複は1個へ整理する。

相手社長の明示同意、接続判定、合併直後の列車上限整理は未接続である。固有能力はUIにpending表示だけを出し、
ルール効果を適用しない。これによりローカル完走経路を先に接続し、厳密な合併同意と能力を独立して追加できる。

## 未完了

W01の公式各部品台帳、公式固定盤面への差替え、合併の同意・接続・列車超過処理、固有能力、
厳密な輸出・破産処理、UI受入を
引き続き実装する。能力なしalphaはゲーム一覧から開始・完走できる構造になったが、公式ルール完成版ではない。

## 2026-09-16：タイル配置フェイズ試作（別ブランチ）

`feat/rotla-map-tile-placement`を能力なし完走alphaから分岐した。HotseatのNew Game画面で、4人が順番に
仮3ヘックスタイル33枚をslotへ配置・回転し、続いて首都プロジェクト3枚の対象となる基本都市を選択する。
配置完了までCreateを無効にし、完成後は`settings.rotla`へmanifestと36手のsetup journalを渡す。

`MapSetup`は同じjournalを再生して配置・首都対象を復元し、`SetupConfig`はjournalと完成manifestの一致を検査する。
`MapBuilder`は首都対象の都市分類をbasicからcapitalへ変更するため、Adaptiveのホーム候補からも除外される。
回転や配置によって座標が変わる会社都市は、Game初期化中に完成盤面から11社のホームへ再割当てする。

この段階の33枚はUI・保存・再生・首都選択を検証するための仮データであり、公式図柄、公開順、黒境界、
3辺接触、配置不能時の山送り・マップ再作成は未実装である。

既存GitHub Actionsを利用するため、masterをbaseとした[draft PR #1](https://github.com/ddsotos/18xx/pull/1)を作成した。
既存CIのPR対象パターンに合わせたもので、マージは行っていない。
既存基盤テストはユーザー側で通過済み。今回の追加は上記の対象テスト結果も記録した。

実行環境復旧後の対象テスト：

```sh
bundle exec rspec spec/lib/engine/game/g_rotla
```
