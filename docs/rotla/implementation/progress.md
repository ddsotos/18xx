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
