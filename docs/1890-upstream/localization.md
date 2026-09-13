# English localization and reference migration

This is a proposed implementation mapping. No source code or artwork has been translated yet. Prefer official English terminology from the exact game edition when available; the names below are working translations/transliterations. Japanese appears here only as source evidence for the conversion.

## Entity identities

Use ASCII IDs consistently in `sym`, runtime identity comparisons, share prefixes, ability targets, initial auction order, fixtures, and tests. Preserve the same ID for the company certificate and its operating minor. IDs are proposed stable keys, not claims about official abbreviations.

| Source ID | Proposed ID | Proposed English full name |
| --- | --- | --- |
| 有電 | `ARIMA` | Arima Railway |
| 神電 | `KCT` | Kobe City Tram |
| 堺電 | `HANKAI` | Hankai Electric Railway |
| 阪国 | `HNK` | Hanshin Kokudo Tramway |
| 京津 | `KEISHIN` | Keishin Railway |
| 市電 | `OCT` | Osaka City Tram |
| 京福 | `KEIFUKU` | Keifuku Railway |
| 神高 | `KRT` | Kobe Rapid Railway |
| 北急 | `KOK` | Kita-Osaka Kyuko Railway |
| 泉北 | `SEMBOKU` | Semboku Rapid Railway |
| 河南 | `KANAN` | Kanan Railway |
| 大軌 | `DAIKI` | Osaka Electric Railway |
| 阪鉄 | `HANTETSU` | Osaka Railway |
| 奈良 | `NARA` | Nara Electric Railway |
| 神戸 | `KOBE` | Kobe Electric Railway |
| 南海 | `NANKAI` | Nankai Electric Railway |
| 京阪 | `KEIHAN` | Keihan Railway |
| 山陽 | `SANYO` | Sanyo Electric Railway |
| 阪神 | `HANSHIN` | Hanshin Electric Railway |
| 阪急 | `HANKYU` | Hankyu Railway |
| 近鉄 | `KINTETSU` | Kintetsu Railway |
| JR | `JR` | JR |
| メトロ | `METRO` | Osaka Metro |

For `阪国`, check the edition terminology before finalizing the working name "Hanshin Kokudo Tramway". Official/historical company names must not be inferred from a modern railway brand.

### Required reference updates

- `京阪_1` -> `KEIHAN_1`; `阪神_1` -> `HANSHIN_1`; `メトロ_0` -> `METRO_0`; `近鉄_0` -> `KINTETSU_0`. Also migrate any generated share IDs appearing in tests/fixtures.
- Translate `INITIAL_AUCTION_ORDER` using the same mapping without changing order.
- Translate corporation targets in `exchange`, `close`, `shares`, reservation, and other ability definitions.
- `Minor#name` and `Corporation#name` use the short `sym` identity, while `full_name` holds the supplied long name. Company identity is also referenced through `sym`/`id`. Inspect all `name ==` comparisons; do not assume `name` always means the long display label.
- Use proposed IDs for all existing logo basenames (for example `1890/近鉄` -> `1890/KINTETSU`) and update both `logo` and `simple_logo`.
- Rename SVG files and replace their Japanese text nodes together. Nankai has path artwork rather than Japanese text in the scan; inspect its appearance before deciding any artwork change.
- Translate descriptions and event/choice/log strings without changing rules, amounts or timing. Remove accidental debug messages in the owning feature PR.
- Historical snapshots stay unchanged. If old games are used as fixtures, migrate entity/share references before comparing replay results. Do not claim old save compatibility without a verified migration.

## Location names

| Hex | Source label | Proposed English label |
| --- | --- | --- |
| A14 | 山陰・丹波 | Sanin / Tamba |
| A20 | 中部 | Chubu |
| B7 | 山陰・丹波 | Sanin / Tamba |
| B17 | 京都 | Kyoto |
| B21 | 東海 | Tokai |
| C18 | 伏見 | Fushimi |
| D3 | 三木 | Miki |
| D5 | 谷上 | Tanigami |
| D7 | 有馬 | Arima |
| D9 | 宝塚 | Takarazuka |
| D15 | 高槻 | Takatsuki |
| D19 | 宇治 | Uji |
| E10 | 伊丹 | Itami |
| E12 | 豊中 | Toyonaka |
| E14 | 茨城・摂津 | Ibaraki / Settsu (source spelling needs verification) |
| E16 | 枚方 | Hirakata |
| F1 | 姫路・山陽 | Himeji / Sanyo |
| F3 | 明石 | Akashi |
| F5 | 神戸 | Kobe |
| F7 | 芦屋 | Ashiya |
| F9 | 西宮 | Nishinomiya |
| F11 | 尼崎 | Amagasaki |
| F13 | 吹田 | Suita |
| F15 | 寝屋川 | Neyagawa |
| G12 | 大阪北 | Osaka North |
| G14 | 守口・門真 | Moriguchi / Kadoma |
| G16 | 大東・四条畷 | Daito / Shijonawate |
| H11 | 大阪西 | Osaka West |
| H13 | 大阪東 | Osaka East |
| H15 | 東大阪 | Higashi-Osaka |
| H19 | 奈良 | Nara |
| I12 | 大阪南 | Osaka South |
| I18 | 郡山 | Koriyama |
| J11 | 堺 | Sakai |
| J15 | 柏原 | Kashiwara |
| J19 | 天理 | Tenri |
| K10 | 泉大津 | Izumiotsu |
| K18 | 桜井 | Sakurai |
| K20 | 伊勢・東海 | Ise / Tokai |
| L9 | 岸和田 | Kishiwada |
| M6 | 関西空港 | Kansai Airport |
| M8 | 泉佐野 | Izumisano |
| M14 | 高野山 | Koyasan |
| N7 | 和歌山 | Wakayama |

### Predicates that must move with the labels

Prefer these exact existing hex identities over localized display strings when preserving the current rule:

| Source predicate | Stable hex | Owning feature |
| --- | --- | --- |
| Token at 京都 | B17 | Keifuku bonus |
| Token at 堺 | J11 | Semboku bonus |
| Token at 宝塚 | D9 | Hankyu bonus |
| Brown 西宮 stop | F9 | Hanshin subsidy / Tigers option |
| 神戸 route stop | F5 | Kobe Rapid revenue |

Changing these comparisons to coordinates is intended to preserve the source board meaning. Test the relevant token/route cases and exclusion cases. Do not change the map geometry during translation.

## Event key normalization

| Source key | Proposed key |
| --- | --- |
| `conversion_to_Kintetsu` | `conversion_to_kintetsu` |
| `kanan_merge_to_Kintetsu` | `kanan_merge_to_kintetsu` |
| `nara_merge_to_Kintetsu` | `nara_merge_to_kintetsu` |
| `remove_extra_tile_lay_from_JR` | `remove_extra_tile_lay_from_jr` |
| `Osaka_Expo` | `osaka_expo` |

Update each `TRAINS` event type, matching `event_<key>!` method, `EVENTS_TEXT` key, direct test call, and assertion together. Rename `recalculate_order_when_merge_Kintetsu` and `@Osaka_Expo_timing` consistently in the owning PR. Preserve action names belonging to the shared engine.

## Text needing source verification

- Metadata: proposed designer display `Shinichi Takasaki`, location `Osaka, Japan`. Verify against the edition; current publisher declaration and adjacent Japanese comment are inconsistent.
- E14 place spelling, BOW comment/Osaka West identity, and seven-digit color values require map/artwork evidence.
- Translate game company ability descriptions from the source rule wording. The instructions document does not certify those descriptions as correct.
- Do not advertise the source `beginner_game` option until its complete behavior is verified. Add the Tigers option only with its implementation.

## Japanese text inventory

Counts below are lines containing Hiragana, Katakana, or CJK ideographs in relevant Ruby/SVG files. They are a scoping aid, not a count of translations or proof that all non-English content was found.

| File | Matching lines |
| --- | ---: |
| `lib/engine/game/g_1890/entities.rb` | 105 |
| `lib/engine/game/g_1890/game.rb` | 55 |
| `lib/engine/game/g_1890/map.rb` | 61 |
| `lib/engine/game/g_1890/meta.rb` | 3 |
| `lib/engine/game/g_1890/round/operating.rb` | 3 |
| `lib/engine/game/g_1890/step/buy_sell_par_shares.rb` | 2 |
| `lib/engine/game/g_1890/step/dividend.rb` | 2 |
| `lib/engine/game/g_1890/step/exchange.rb` | 8 |
| `lib/engine/game/g_1890/step/track.rb` | 2 |
| `public/logos/1890/メトロ.svg` | 1 |
| `public/logos/1890/京阪.svg` | 1 |
| `public/logos/1890/大軌.svg` | 1 |
| `public/logos/1890/奈良.svg` | 1 |
| `public/logos/1890/山陽.svg` | 1 |
| `public/logos/1890/河南.svg` | 1 |
| `public/logos/1890/神戸.svg` | 1 |
| `public/logos/1890/近鉄.svg` | 1 |
| `public/logos/1890/阪急.svg` | 1 |
| `public/logos/1890/阪神.svg` | 1 |
| `public/logos/1890/阪鉄.svg` | 1 |
| `spec/lib/engine/game/g_1890/game_spec.rb` | 201 |

Before completing each PR, scan contributed files and filenames for Japanese text, inspect descriptions/logs visually, and verify every asset/reference resolves. Currency symbols such as `¥` are valid and should be preserved. Do not translate unrelated upstream files.
