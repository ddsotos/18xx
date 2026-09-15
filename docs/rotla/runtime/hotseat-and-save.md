# ローカル実行・保存

[詳細設計の入口](../README.md)

## 1. 実行形態

初期対象はlocalhostで動く既存アプリのHotseat。4人の席を同じPCで操作する。
初回のDockerイメージ・依存取得と、準備済み環境でネットを切った運用を別々に検証する。
単独HTML配布、Electron、AI、オンライン同期はこの完了条件に含めない。

参照コード：
[作成画面](../../../assets/app/view/create_game.rb)、
[ゲーム管理](../../../assets/app/game_manager.rb)、
[保存](../../../assets/app/lib/storage.rb)、
[Action処理](../../../assets/app/view/game/actionable.rb)、
[エンジン](../../../lib/engine/game/base.rb)。

## 2. 保存契約（提案）

既存Hotseat保存の外形を維持し、settings内のrotlaに初期設定を追加する。
以下は追加設定の設計例であり、そのまま読み込めるゲームJSONではない。

```json
{
  "settings": {
    "rotla": {
      "schema_version": 2,
      "ruleset": "en-second-printing",
      "mode": "long",
      "player_count": 4,
      "map_manifest_version": 1,
      "map_id": "long4-verified-01",
      "map_manifest": {},
      "minor_tableau": [["SPA", "ADA", "BRI", "OVN"], ["TUN", "RES", "EM", "AGR"], ["NP", "XPN", "XPR", "SUB"]],
      "setup_journal": []
    }
  }
}
```

map_manifestの構造は[マップ設計](../data/map-and-tiles.md)で定義する。
固定マップも保存時点の完全な配置とデータ版を持たせ、将来のプリセット修正で過去局が変わらないようにする。
seedだけに配置復元を任せない。会社列順・遠隔地収益など初期抽選の結果も再現可能にする。
既存のseedと独自の初期設定が矛盾する入力は受け付けない。

| データ | 保持先 | 復元方法 |
|---|---|---|
| ルール版・モード・初期盤面 | settings.rotla | エンジン初期化前に検証 |
| プレイヤー・seed | 既存保存フィールド | 既存Game.load経路 |
| ゲーム開始後の選択・操作 | 既存actions | 順番に再生 |
| 自由マップ作成操作 | setup_journal | 盤面確定前の専用形式 |
| 現金・株・列車・ラウンド状態 | 再生で導出 | 二重の正本を作らない |
| 選択中のタイル・表示タブ | UI一時状態 | ゲーム結果に影響させない |

## 3. loadとclone

確認済み：Game.loadはsettingsを初期化引数へ渡す。一方、Base#cloneはnames、id、pin、
seed、actions、optional_rules等からnewを呼び、追加settingsを渡していない。
通常ロードだけを直すと、undo・過去Action表示・複製時に盤面設定を失う可能性がある。

設計決定：
1. RotLA初期化でsettings.rotlaを読み、版と4人ロング条件を検証する。
2. init_hexesより前に盤面と会社ホームを決める。予約トークンの座標もここで必要。
3. RotLAのclone経路で初期設定を深くコピーして引き継ぐ。必要な既存フラグも保持する。
4. 入力JSONと設定を破壊的変更しない。新旧のゲームインスタンス間で可変配列を共有しない。
5. 共通Base修正が必要になった場合は他タイトルのclone回帰テストを追加する。

未認識schema/ruleset、欠落した盤面、重複IDはAction再生前に説明付きで拒否する。
既存局を黙って新ルールへ移行しない。将来の移行は明示的な変換と元ファイル保存を要する。

## 4. UIの保存経路

既存Actionableはprocess_action後にaction.to_hを保存データへ追加し、
HotseatではLib::Storageへ保存する。この経路にRotLA設定を載せ続ける。
UIから現金等を直接変更する処理は作らない。

自由マップのドラフトはゲーム保存と区別する。キャンセルした盤面を局の初期状態にしない。
盤面確定後は同じ局で編集不可。再配置する場合は新しい局を作る。
合併同意などは手番プレイヤーに対するエンジン検証を持たせる。
同じ端末のHotseatは本人認証の仕組みを提供するものではない。

## 5. 復元検証

次の各時点でJSON出力→新規ロード→次の合法Actionと状態を比較する。

- 競売の途中、落札後の会社選択待ち。
- 先行購入終了後、株式発行後、緊急購入の個人売却待ち。
- 合併の相手同意待ち、合併後の上限整理待ち。
- 固有能力使用後、廃車・輸出直後、最終得点確定後。

比較項目は現金、証券所有、株価と同値順序、列車所有、能力残数、盤面、手番、
サイクル、ラウンド、次の合法Action、終局結果。
同じ保存に対する同じAction列はRubyとブラウザで同じ結果になることを求める。
undo→別Actionの分岐では破棄した未来が混入しないことを確認する。

## 6. 起動の受入条件

既存DEVELOPMENT.mdとMakefileの手順を基準に、実装時点の依存で実測する。
Linux/macOS/Windows WSL2は検証した環境を明記し、未検証OSを対応済みとしない。
ブラウザ再起動、コンテナ再起動、JSONの別ブラウザへの移送を確認する。
外部ネットワーク遮断後もlocalhostで開始・再開・保存・完走できることを確認する。
localStorage消去に備え、既存JSON持出し導線が使用できることを操作手順に示す。
alpha版では新規Hotseat作成時に4人ロングの既定settingsを自動投入する。ゲーム名は
`Railways of the Lost Atlas`。開発用固定マップ`long4-playable-v0`を使い、固有能力、合併相手の明示同意、
公式盤面に基づく合併接続判定、合併直後の列車超過整理は未実装である。能力なしの合併選択と資産移管、
6サイクル終了は操作できる。
起動・ブラウザ操作・オフライン動作の実機確認はユーザー環境で行う。

## 7. 能力なしalphaの確認手順

1. リポジトリ直下で`make dev_up_b`を実行し、`http://localhost:9292`を開く。
2. New GameでHotseat、`Railways of the Lost Atlas`、4人を選ぶ。追加設定は不要。
3. SRで小会社を設立し、OR1・OR2を操作する。緑フェーズ以降はMRで合併またはskipを選ぶ。
4. 途中でHotseatのJSONを出力し、Import a hotseat gameから再開できることを確認する。
5. 第6サイクル終了時にGame overと最終資産が表示されることを確認する。

開発用盤面は全都市が印刷済み線路で接続されているため、Trackは自動skipする。
