# 線路タイル台帳（英語第2版）

[マップ作成・タイルデータ](map-and-tiles.md)

## 1. 対象と確定範囲

参照元は `Railways-EN-2nd-Rulebook.pdf` の紙面p.2（PDF p.3）にある
「135 Track Tiles」の部品図である。印刷タイルには通常の18xxタイル番号がないため、
実装用ID `RLA-Y01` などを割り当てた。

この台帳で確定したものは次のとおり。

- 物理タイル135枚
- 図柄54種類
- 色別枚数
- 各図柄の枚数、hub spot数を含む大分類、部品図上の位置
- 橋タイル5枚の内訳
- 全54種類の辺0〜5の接続、収益、hub spot数
- star、Eastern Mining、Northern Portのアップグレード系列

固有の地名・道路背景と特殊記号の原画は再現していない。ゲーム判定には安定したラベル
`S`、`EM`、`NP`を使う。線路、収益、hub spot数、アップグレード判定に必要な情報は
`TrackTiles::TILES`を介して`Map::TILES`へ接続済みである。

## 2. 読み取り方法

PDF p.3の内部画像を抽出すると、線路タイル領域には画像配置が136個ある。
ただし部品図上の同一座標 `(66.388, 357.107)` に2画像を重ねた合成タイルが1枚あり、
座標単位で数えると135枚になる。

積み重ねは、隣り合う画像座標の差
`(-1.738, +2.317)` を同じ山としてまとめた。これにより54山・135枚となり、
目視で隠れた枚数を推定せずに数えられる。Ruby台帳の `source_group`、
`source_image`、`source_top` はこの再照合用情報である。

辺は印刷タイルの右上を0として時計回りに0〜5とした。yellowの単線3形状を回転した
テンプレートとしてgreen/purple図柄へ重ね、黒線の一致度で各pathを分解した。
green 16図柄とpurple 11図柄はいずれも最良のpath集合が次候補より明確に一致した。

部品図の複数の白丸は別都市ではなく、同じ都市のhub spotである。紙面p.13の
「Cities cannot be created or removed」「They will often gain additional city spots」に従い、
全city tileをcity 1個とし、白丸の数を`slots`へ設定した。

## 3. 集計

| 色 | 種類 | 枚数 |
|---|---:|---:|
| Yellow | 9 | 55 |
| Green | 24 | 43 |
| Purple | 15 | 27 |
| Gray | 3 | 5 |
| Blue（橋） | 3 | 5 |
| **合計** | **54** | **135** |

## 4. 種類別台帳

### Yellow

| ID | 枚数 | 大分類 | source group / image |
|---|---:|---|---|
| RLA-Y01 | 14 | broad curve | 1 / 262 |
| RLA-Y02 | 7 | city straight | 2 / 340 |
| RLA-Y03 | 7 | city straight | 3 / 319 |
| RLA-Y04 | 1 | city straight | 4 / 68 |
| RLA-Y05 | 1 | city straight | 5 / 66 |
| RLA-Y06 | 1 | city sharp curve（star） | 6 / 64 |
| RLA-Y07 | 13 | straight | 7 / 223 |
| RLA-Y08 | 6 | sharp curve | 8 / 361 |
| RLA-Y09 | 5 | city sharp curve | 9 / 379 |

### Green

| ID | 枚数 | 大分類 | source group / image |
|---|---:|---|---|
| RLA-G01 | 4 | two paths | 10 / 211 |
| RLA-G02 | 4 | two paths | 11 / 199 |
| RLA-G03 | 2 | two paths | 12 / 193 |
| RLA-G04 | 1 | two paths | 13 / 48 |
| RLA-G05 | 1 | two paths | 14 / 38 |
| RLA-G06 | 1 | two paths | 15 / 36 |
| RLA-G07 | 1 | two paths | 16 / 42 |
| RLA-G08 | 1 | two paths | 17 / 40 |
| RLA-G09 | 1 | two paths | 18 / 32 |
| RLA-G10 | 1 | two paths | 19 / 30 |
| RLA-G11 | 1 | two paths | 20 / 28 |
| RLA-G12 | 1 | two paths | 21 / 24 |
| RLA-G13 | 5 | city / 2 spots | 22 / 142 |
| RLA-G14 | 4 | city / 2 spots | 23 / 304 |
| RLA-G15 | 4 | city / 2 spots | 24 / 130 |
| RLA-G16 | 1 | crossing paths | 25 / 34 |
| RLA-G17 | 1 | parallel curves | 26 / 26 |
| RLA-G18 | 1 | crossing paths | 27 / 46 |
| RLA-G19 | 1 | crossing paths | 28 / 44 |
| RLA-G20 | 2 | city / 2 spots（star） | 32 / 124 |
| RLA-G21 | 2 | city / 2 spots（star） | 33 / 118 |
| RLA-G22 | 1 | city / 2 spots（star） | 34 / 54 |
| RLA-G23 | 1 | city / 2 spots（Eastern Mining） | 35 / 58 |
| RLA-G24 | 1 | city / 2 spots（Northern Port） | 36 / 56 |

### Purple

| ID | 枚数 | 大分類 | source group / image |
|---|---:|---|---|
| RLA-P01 | 2 | multi-path | 29 / 163 |
| RLA-P02 | 2 | multi-path | 30 / 187 |
| RLA-P03 | 2 | multi-path | 31 / 169 |
| RLA-P04 | 2 | multi-path | 37 / 157 |
| RLA-P05 | 2 | multi-path | 38 / 175 |
| RLA-P06 | 2 | multi-path | 39 / 181 |
| RLA-P07 | 1 | multi-path | 40 / 18 |
| RLA-P08 | 1 | multi-path | 41 / 20 |
| RLA-P09 | 1 | multi-path | 42 / 14 |
| RLA-P10 | 1 | multi-path | 43 / 16 |
| RLA-P11 | 6 | city / 2 spots | 44 / 100 |
| RLA-P12 | 2 | city / 3 spots（star） | 46 / 85 |
| RLA-P13 | 1 | city / 3 spots（Eastern Mining） | 47 / 50 |
| RLA-P14 | 1 | city / 4 spots（Northern Port） | 48 / 52 |
| RLA-P15 | 1 | crossing paths | 49 / 22 |

### Gray

| ID | 枚数 | 大分類 | source group / image |
|---|---:|---|---|
| RLA-X01 | 3 | city / 2 spots | 45 / 91 |
| RLA-X02 | 1 | city / 3 spots（star） | 50 / 60 |
| RLA-X03 | 1 | city / 3 spots（Eastern Mining） | 51 / 62 |

### Blue（Bridging Company専用）

| ID | 枚数 | 大分類 | source group / image |
|---|---:|---|---|
| RLA-B01 | 2 | broad curve bridge | 52 / 73 |
| RLA-B02 | 2 | straight bridge | 53 / 79 |
| RLA-B03 | 1 | sharp curve bridge | 54 / 70 |

橋の内訳は紙面p.3、p.13の「broad curve 2、straight 2、sharp curve 1」と一致する。
橋は通常のyellow layの代わりに水上へ置き、アップグレード不可である。

## 5. 実装状態と次の単位

- `TrackTileManifest`：物理枚数とPDF再照合情報
- `TrackTiles::PATH_SPECS`：非city tileの独立したpath組
- `TrackTiles::CITY_SPECS`：収益、slots、exit、特殊系列
- `TrackTiles::TILES`：Engine DSLへ変換した54種類
- `Map::TILES`：上記在庫を使用
- 色進行：yellow→green→purple→gray

次はBridging Companyだけがblue tileを水hexへyellow layの代わりに置ける制限と、
橋をアップグレードできない制限をTrack Stepへ接続する。特殊記号は同じラベル同士のみを
通常アップグレード候補にし、Eastern Miningの時計回り/反時計回りの2配置は回転候補で検証する。
