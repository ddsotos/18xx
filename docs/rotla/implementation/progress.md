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

## 未完了

W01の公式各部品台帳、W02のローカル起動、W03のゲーム登録・実際の固定盤面・
株式/運営/合併/能力/終局/UIを引き続き実装する。
今回のコードは独立した基盤で、RotLAはまだゲーム一覧から遊べない。

既存GitHub Actionsを利用するため、masterをbaseとした[draft PR #1](https://github.com/ddsotos/18xx/pull/1)を作成した。
既存CIのPR対象パターンに合わせたもので、マージは行っていない。
既存基盤テストはユーザー側で通過済み。今回の追加は上記の対象テスト結果も記録した。

実行環境復旧後の対象テスト：

```sh
bundle exec rspec spec/lib/engine/game/g_rotla
```
