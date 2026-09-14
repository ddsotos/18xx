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
変換adapter、印刷線路の回転、地形・黒境界、首都効果の適用は未実装。
RSpec内の盤面は人工的な入力例であり、公式の固定マップではない。

## 未完了

W01の公式各部品台帳、W02のローカル起動、W03のゲーム登録・実際の固定盤面・
Game.load/clone接続、株式/運営/合併/能力/終局/UIを引き続き実装する。
今回のコードは独立した基盤で、RotLAはまだゲーム一覧から遊べない。

実行環境が利用できないため、ローカルRuby/Opal/ブラウザ検証は未実行。
既存GitHub Actionsを利用するため、設計ブランチをbaseとしたdraft PRを作成する。
CI結果はPRのChecksを参照し、成功が確認できるまではテスト通過と扱わない。

実行環境復旧後の対象テスト：

```sh
bundle exec rspec spec/lib/engine/game/g_rotla
```
