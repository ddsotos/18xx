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
- 各図柄の枚数、都市数を含む大分類、部品図上の位置
- 橋タイル5枚の内訳

まだ確定していないものは、各辺と都市・分岐点の接続を表すEngine DSL、特殊記号の
アップグレード系列、固有背景名である。これらは小さい部品図から推測せず、別の
ベクトル化確認を終えてから `Map::TILES` へ接続する。

## 2. 読み取り方法

PDF p.3の内部画像を抽出すると、線路タイル領域には画像配置が136個ある。
ただし部品図上の同一座標 `(66.388, 357.107)` に2画像を重ねた合成タイルが1枚あり、
座標単位で数えると135枚になる。

積み重ねは、隣り合う画像座標の差
`(-1.738, +2.317)` を同じ山としてまとめた。これにより54山・135枚となり、
目視で隠れた枚数を推定せずに数えられる。Ruby台帳の `source_group`、
`source_image`、`source_top` はこの再照合用情報である。

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
| RLA-Y06 | 1 | city three-way | 6 / 64 |
| RLA-Y07 | 13 | straight | 7 / 223 |
| RLA-Y08 | 6 | sharp curve | 8 / 361 |
| RLA-Y09 | 5 | city sharp curve | 9 / 379 |

### Green

| ID | 枚数 | 大分類 | source group / image |
|---|---:|---|---|
| RLA-G01 | 4 | three-way junction | 10 / 211 |
| RLA-G02 | 4 | three-way junction | 11 / 199 |
| RLA-G03 | 2 | three-way junction | 12 / 193 |
| RLA-G04 | 1 | two paths | 13 / 48 |
| RLA-G05 | 1 | two paths | 14 / 38 |
| RLA-G06 | 1 | two paths | 15 / 36 |
| RLA-G07 | 1 | two paths | 16 / 42 |
| RLA-G08 | 1 | two paths | 17 / 40 |
| RLA-G09 | 1 | two paths | 18 / 32 |
| RLA-G10 | 1 | two paths | 19 / 30 |
| RLA-G11 | 1 | two paths | 20 / 28 |
| RLA-G12 | 1 | two paths | 21 / 24 |
| RLA-G13 | 5 | two-city | 22 / 142 |
| RLA-G14 | 4 | two-city | 23 / 304 |
| RLA-G15 | 4 | two-city | 24 / 130 |
| RLA-G16 | 1 | crossing paths | 25 / 34 |
| RLA-G17 | 1 | parallel curves | 26 / 26 |
| RLA-G18 | 1 | crossing paths | 27 / 46 |
| RLA-G19 | 1 | crossing paths | 28 / 44 |
| RLA-G20 | 2 | two-city | 32 / 124 |
| RLA-G21 | 2 | two-city | 33 / 118 |
| RLA-G22 | 1 | two-city | 34 / 54 |
| RLA-G23 | 1 | two-city special | 35 / 58 |
| RLA-G24 | 1 | two-city special | 36 / 56 |

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
| RLA-P11 | 6 | two-city | 44 / 100 |
| RLA-P12 | 2 | three-city | 46 / 85 |
| RLA-P13 | 1 | three-city special | 47 / 50 |
| RLA-P14 | 1 | four-city special | 48 / 52 |
| RLA-P15 | 1 | crossing paths | 49 / 22 |

### Gray

| ID | 枚数 | 大分類 | source group / image |
|---|---:|---|---|
| RLA-X01 | 3 | two-city | 45 / 91 |
| RLA-X02 | 1 | three-city | 50 / 60 |
| RLA-X03 | 1 | three-city special | 51 / 62 |

### Blue（Bridging Company専用）

| ID | 枚数 | 大分類 | source group / image |
|---|---:|---|---|
| RLA-B01 | 2 | broad curve bridge | 52 / 73 |
| RLA-B02 | 2 | straight bridge | 53 / 79 |
| RLA-B03 | 1 | sharp curve bridge | 54 / 70 |

橋の内訳は紙面p.3、p.13の「broad curve 2、straight 2、sharp curve 1」と一致する。
橋は通常のyellow layの代わりに水上へ置き、アップグレード不可である。

## 5. 次の実装単位

1. 54種類それぞれについて、辺0〜5、都市、junction、交差非接続をベクトル化する。
2. 特殊記号を読み取り、同一記号だけにアップグレードできる系列を作る。
3. revenueとcity slotsを照合する。
4. `TrackTileManifest::TILES` からEngineの `TILES` 定数を生成する。
5. 合計枚数、アップグレード保存、橋の配置制限をspecで固定する。

物理枚数台帳とルート形状を別段階にしたのは、低解像度の部品図から交差接続や特殊記号を
推測して、合法手やアップグレードを誤らせないためである。
