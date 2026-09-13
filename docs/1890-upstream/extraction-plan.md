# 1890 upstream extraction plan

Prepared 2026-09-13. This is a static code and history audit, not an implementation PR or a playtest certification.

## Fixed references and completed preparation

| Purpose | Reference |
| --- | --- |
| Original branch, retained | `ddsotos/18xx:online-play-cloudflare-tunnel` |
| Source commit | `f876638ed82a4e0e07715fbe4428df1624bf3f15` |
| Preservation branch | `ddsotos/18xx:g1890-full-snapshot-f876638` |
| Upstream baseline | `tobymao/18xx:3027b7bc80a3e79d61cc551c53906a3578630f60` |
| Shared ancestor | `5933dd67853ddcb3a93e9134817a08fd11be8b60` |
| Clean PR 1 starting branch | `ddsotos/18xx:g1890-pr1-base` |
| Preparation documents | `ddsotos/18xx:g1890-upstream-preparation` |

The source is 199 commits ahead and 932 behind the inspected upstream baseline. The source-side diff from the shared ancestor changes 111 paths, with 8,592 added and 290 deleted text lines, plus one binary image. These are fork contributions, not the two-tip diff that would also include missing upstream updates. All 111 paths are classified in `inventory.md`.

The snapshot contains the version published on GitHub. Uncommitted or unpushed files on the user's computer are not included. No existing source branch was reset or rewritten. The PR 1 starting branch contains no extracted implementation yet.

## Upstream conventions verified directly

The current `.github/PULL_REQUEST_TEMPLATE.md` explicitly asks new-game contributors to split implementations into multiple PRs, minimize shared engine changes, base branches on the latest master, and run lint/tests. Titles should carry the affected game tag and `[core]` when shared engine code changes. The Ruby workflow separately runs RuboCop, Opal compilation, and parallel RSpec on Ruby 3.2.

References:

- [PR template](https://github.com/tobymao/18xx/blob/3027b7bc80a3e79d61cc551c53906a3578630f60/.github/PULL_REQUEST_TEMPLATE.md)
- [CI workflow](https://github.com/tobymao/18xx/blob/3027b7bc80a3e79d61cc551c53906a3578630f60/.github/workflows/ruby.yml)
- [Development guide](https://github.com/tobymao/18xx/blob/3027b7bc80a3e79d61cc551c53906a3578630f60/DEVELOPMENT.md)

The user's 18PA/1832 precedents motivate this plan; their historical discussions were not independently re-audited in this preparation. The recommendations below are not a promise of maintainer acceptance.

## Important findings

### Shared changes have different purposes

| Source change | Finding and disposition |
| --- | --- |
| `lib/engine/corporation.rb`, `lib/engine/part/city.rb` | Introduce `ignores_token_blocking?`. Osaka Metro installs a brown-Osaka exception; Kobe Rapid passage wraps that method. Neither hook exists in the inspected upstream versions. Defer to the Metro/Kobe rules, first looking for a suitable existing extension point or game-local subclass. If a core hook remains necessary, include both caller and default behavior plus regression tests. |
| `assets/app/view/game/part/location_name.rb` | Doubles global character width from 8 to 16. Exclude. English labels must be checked using the upstream renderer. |
| `assets/app/view/game/pass.rb` and its spec | Adds hotseat auto-pass for all players. General hotseat improvement, not required game rules. Exclude from this series. Source commit: `facf1c826`. |
| `assets/app/view/game/round/operating.rb` | Handles an absent active step. Commit `1a27d9d0a` specifically relates to JR token skipping. Reproduce with the extracted JR/OR logic; fix game round state first, or submit a narrowly tested UI change if necessary. |
| `assets/app/view/game/route_selector.rb` | Defaults missing history `halts`/`nodes` to hashes. Commit `2bb6d5c11` is a generic history guard. Reproduce with transferred trains before deciding it is required; do not include automatically. |
| `api.rb`, user model/routes, app/user/navigation changes | Friend login, propagation of its flag, and CSP adjustment. Exclude all source hunks. |
| 1889 implementation and tests | Unrelated edits and removed coverage. Preserve current upstream versions, including tutorial and auction coverage. |

### File boundaries do not match rule boundaries

`game.rb` has 913 lines and the game spec has 3,744 lines. `Step::Track` combines ordinary track support, Osaka Metro's first operation, Kobe Rapid blocking refresh, and Hankyu's tile payment. `Step::Dividend` combines minor/JR dividends, Kobe Rapid income, and Kintetsu's special-operation state. `Step::Exchange` combines minor-to-Kintetsu exchanges and Kobe Electric latecomer conversion. `Round::Operating` combines Metro setup and Kintetsu interruption/resumption. Extract relevant methods and hunks rather than copying these files wholesale.

`setup` combines offboard revenue selection and Metro token blocking. `new_stock_round` combines reserved Kintetsu shares and latecomer release. `payout_companies` combines base payout ordering, Keifuku, Semboku, the Expo bonus, and Hankyu. `after_buy_company` combines basic share assignment, minor acquisition, Osaka City Tram, and Kobe Rapid activation.

### English conversion affects identifiers and behavior

The source uses Japanese `sym` values for company and operator identity, generated share identifiers such as `京阪_1`, ability targets, auction order, and logo paths. `Minor#name` and `Corporation#name` are derived from `sym`; changing full display names alone does not translate runtime short names. Location display strings are also used as rule predicates. See `localization.md` for the proposed mapping and dependency updates.

### Source cleanup needed during extraction

- `meta.rb` advertises `:beta` and a beginner option. Do not inherit those declarations into an incomplete skeleton. Upstream defaults to `:prealpha`, also used by inspected 18PA and 1832 metadata.
- Publisher metadata is `:grand_trunk_games` beside a Japanese publisher comment. Treat this as unverified, not an English translation problem. Verify publisher/designer/rules metadata before submission.
- `active_players` looks up company `ER`, which is absent from the 1890 entities. It resembles leftover special-track handling; retain only if a real 1890 requirement is demonstrated.
- Source minor colors include `#F7A1F1F`, which has seven hex digits and is not a valid CSS hex color. Compare with source artwork when fixing it; do not guess a new brand color.
- Map E14 says `茨城・摂津`; the intended place spelling needs comparison with the map/rule source. The BOW comment says Osaka South while its label/upgrade rule points to Osaka West. Record these as source inconsistencies.
- Event keys such as `conversion_to_Kintetsu` and `Osaka_Expo` need consistent Ruby-style normalization with handler names, text keys, and tests.
- `EBUY_PRES_SWAP` and `EBUY_FROM_OTHERS` comments describe behavior opposite to their values. Inspect intended rules when extracting train buying.
- Several debug log messages and commented-out code remain. Remove incidental debug output in the owning PR, preserving useful game logs.

## Proposed PR sequence

This is a dependency plan, not a set of simultaneous open PRs. Prepare locally if useful; submit the next dependent PR after its predecessors merge. Each row includes its focused tests. If a row is still too broad, split helpers from wiring while keeping meaningful tests with both.

| PR | Review responsibility | Source anchors | Dependencies and tests |
| --- | --- | --- | --- |
| 1 | Basic setup and map | `g_1890.rb`; `meta.rb`; `map.rb`; basic portions of `entities.rb`; logos; static portions of `game.rb` | None. English metadata/map, valid assets and references, train/phase/cash/market data, definition loading and map rendering. No custom event registration or active special abilities. |
| 2 | Initial auction, minor acquisition and stock setup | `setup_preround`, `initial_auction_companies`, `new_auction_round`, basic `after_buy_company`, `acquire_minor`, `stock_round`, relevant `BuySellParShares` methods | PR 1. Prescribed packet order, initial bid premium/increments, bid commitment, Arima reduction/free acquisition, pending par and attached shares, float and market limits. Kintetsu formation/operating interruption remains deferred; reserve shares here only if needed to keep stock setup coherent. |
| 3 | Ordinary operation and train lifecycle | minimal `operating_round`, `BuyCompany`, `BuyTrain`, ordinary/minor dividend behavior, operating order, home tokens, end-of-game condition | PR 2. Minor operation, train obligation/purchase/rust/trade-in, round progression, tokenless Hantetsu's use of Daiki connectivity, and ten-turn end condition. Exclude special event side effects and JR-specific dividend/tile behavior. Split ordinary track rules from this PR if large. |
| 4 | Map-specific upgrades and offboard revenue | `upgrade_ignore_num_cities`, `upgrades_to?`, BOW/217 helpers, `Step::Track#upgradeable_tiles`, `configure_offboard_revenue!` | PR 3. Allowed/rejected tile upgrades, topology and phase-dependent offboard revenue. Keep Metro free lays and Hankyu payments out. |
| 5 | Initial private-company abilities and closing rules | relevant `entities.rb` abilities, `SpecialTrack`, `after_sell_company`, private close/revenue changes | PR 2/3. Arima sale-triggered lay, block release, private purchase restrictions and phase-4/5-train exceptions. Split by private if behavior is too large. Metro-specific lifecycle belongs to PR 8. |
| 6 | Latecomer availability and fixed income bonuses | latecomer part of `new_stock_round`, purchasing filters, base payout ordering, Keifuku/Semboku/Kita-Osaka payout branches and Expo event | PR 3. Turn-2 release, bank/owner handling, Kyoto/Sakai conditions, one-time Expo payment. Do not enable Kobe Rapid purchase until PR 9. Three independent bonus PRs are acceptable. |
| 7 | JR operating exceptions | fixed par in `BuySellParShares`, JR home tokens, `tile_lays`, 5-train extra-lay removal, JR methods in `Dividend` | PR 3/4. Four home tokens, fixed par 100, two distinct lays before event, half-pay rounding and withhold, zero-route skip. Reproduce the empty-active-step UI issue here. |
| 8 | Osaka City Tram and Metro | Metro share/lifecycle abilities, setup blocking override, first-operation tile helpers, Metro part of `Round::Operating` and `Step::Track` | PR 3/5. Pending par, closure on Metro train purchase, first free city lay, brown-city blocking exceptions and graph/route effects. Any necessary core hook gets explicit regression coverage. |
| 9a | Kobe Rapid revenue and passage model | `kobe_rapid_*`, `grant_kobe_rapid_passage!`, blocking/marker helpers | PR 4/6; coordinate with PR 8's hook design. Tests for passage price/state, returned tokens, blocking and graph invalidation, owner revenue. May remain unwired. |
| 9b | Kobe Rapid actions and lifecycle wiring | `Step::Token`, Track refresh call, Dividend payout call, purchase activation/filter | PR 9a. Purchase-to-Choose-to-RunRoutes-to-Dividend action flow; marker survives tile upgrade; no duplicate revenue or operator/train obligation. |
| 10 | Kobe Electric latecomer conversion | `latecomerize_kobe_electric!`, certificate count override, relevant `Step::Exchange` choices | PR 3/6. Ownership, asset return, zero value, certificate exemption, repeat action rejection. This rule is independent of Kintetsu even though its specs are nested under Kintetsu in the source. |
| 11a | Kintetsu merger and transfer model | `exchange_share`, `merge_minor!`, train/token/treasury transfer, reserved shares | PR 3. Cash split/rounding, share reservation, duplicate tokens, paid-token exception, operated-train reset. No OR interruption yet. |
| 11b | Voluntary exchanges and forced merger events | `Exchange`, necessary portions of `MinorExchange`, `exchange_minor`, 3-3/4/6 event handlers and train registrations | PR 11a. Phase eligibility, company/minor action identity, Daiki/Hantetsu/Kanan/Nara asset/share exchanges. Only wire event flows that are coherent without unresolved special-operation behavior; otherwise use tested helpers until PR 11c. |
| 11c | Kintetsu special operation and resumption | remaining `Round::Operating`, special-operation flag/dividend methods, complete exchange wiring | PR 11b. Interrupt/resume order, remaining steps, zero/nonzero revenue, transferred train action flow, no duplicate operation. Reproduce route-history fallback need here. |
| 12 | Hankyu and Hanshin bonuses | `payout_companies` Hankyu branch, Track yellow-tile payment, `routes_subsidy` and Nishinomiya predicate | PR 4. Token-conditioned and per-lay payments, one subsidy per OR. Can split into two independent PRs. |
| 13 | Hanshin Tigers optional rule | `HANSHIN_TIGERS_REVENUE`, `hanshin_tigers_*`, `Step::Route`, optional metadata | PR 12. All six outcomes, activation timing, additional revenue and replay determinism. Do not include the unrelated unverified beginner option. |
| 14 | Complete-game integration and release readiness | new complete-game fixtures and English rendering/replay checks | All required standard rules. Actual complete playthrough, long OR/event sequences, final game state, existing-game regression and upstream CI. Optional-rule replay can be separate. Development-stage promotion is a later evidence-based decision. |

## PR 1 concrete extraction contract

Start from `g1890-pr1-base`. Allowed initial implementation paths are `lib/engine/game/g_1890.rb`, `lib/engine/game/g_1890/**`, `public/logos/1890/**`, and focused `spec/lib/engine/game/g_1890/**` tests. Do not interpret this as permission to copy every file beneath them: only basic definitions belong in PR 1. Any loader/renderer changes outside these paths require a concrete dependency explanation.

The skeleton should declare English metadata, `:prealpha`, the map and tile inventory, elementary entity data, and static game data. Omit deferred abilities and custom event registrations instead of leaving calls to absent handlers. Extract the static assertions from `scenario C setup` and `stock market`; that source context also contains behavior tests that do not belong in PR 1. Add loading/reference checks and capture a map screenshot once a Ruby/Opal/browser environment is available. If all entity/logo/train definitions make the initial review unwieldy, reduce PR 1 to metadata/map/minimal loading and move remaining static definitions into a second foundation PR.

Acceptance criteria:

1. Game definitions and map load with the current upstream engine and compile under Opal.
2. Every included logo and ability/share reference resolves; no deferred class or event is invoked.
3. English labels render without the source-wide character-width change.
4. Included static values match the chosen rules/map source; unresolved publisher/color/map spelling questions are explicitly tracked until resolved.
5. No online/authentication/deployment edits, other-game edits, or removed existing tests appear in the diff.
6. Focused tests and upstream gates have recorded results. Incomplete playability is stated in the PR description.

Suggested title: `[1890] Add basic setup and map`.

## Verification completed and limitations

- Verified source/upstream refs and shared ancestor, enumerated all 111 changed paths, inspected shared hunks and relevant history, read all 1890 step/round code and game/entity/map definitions, and mapped spec contexts to features.
- Inspected current upstream metadata defaults, core hook locations, PR template, and CI commands.
- Counted 202 textual RSpec `it` declarations. This is not an executed example count; loops can expand examples. The source status document's older 175-example result is not validation of this snapshot.
- The source's own status document records unfinished full-game and map verification. No complete-game fixture was added in this source-side diff.
- Ruby and Docker are unavailable in this preparation runtime. No game tests, Opal build, browser rendering, or full playthrough were run. Only documentation/manifest consistency and Git branch checks were performed.
- The exact local rules PDF is unavailable. English entity/map names in the localization document are proposed transliterations, not certified official English names. Publisher, map spelling, and invalid colors need source evidence before the affected content is finalized.

Next executable task: use the root instructions to extract PR 1 from the fixed snapshot into the clean PR 1 branch, resolve its primary-source questions, and verify it in a Ruby 3.2 environment. Later PR implementation and upstream submission have not been performed by this preparation task.
