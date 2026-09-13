# Source-side change inventory

All paths changed between the shared ancestor and the frozen source are listed below. Line counts refer to that source-side diff, not a proposed PR. Every row was assigned a disposition; no directory-only exclusion is used for shared UI/core changes.

| Disposition | Paths |
| --- | ---: |
| EXCLUDE_ENVIRONMENT | 5 |
| EXCLUDE_MIXED | 1 |
| EXCLUDE_ONLINE | 57 |
| EXCLUDE_UNRELATED | 7 |
| EXTRACT | 31 |
| REFERENCE_ONLY | 6 |
| REVIEW_DEPENDENCY | 4 |

Total: 111 paths. `REFERENCE_ONLY` files remain available in the snapshot. `REVIEW_DEPENDENCY` means conditional inclusion after a reproducer, not automatic inclusion.

| Path | Added | Deleted | Disposition | Destination / reason |
| --- | ---: | ---: | --- | --- |
| `.dockerignore` | 1 | 0 | EXCLUDE_ENVIRONMENT | Fork environment/dependency/ignore change; retain upstream version. |
| `.env.online.example` | 8 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `.gitignore` | 6 | 0 | EXCLUDE_ENVIRONMENT | Fork environment/dependency/ignore change; retain upstream version. |
| `AGENTS.md` | 58 | 0 | REFERENCE_ONLY | Local-play instructions superseded for this extraction by preparation instructions. |
| `Gemfile` | 3 | 0 | EXCLUDE_ENVIRONMENT | Fork environment/dependency/ignore change; retain upstream version. |
| `Gemfile.lock` | 8 | 0 | EXCLUDE_ENVIRONMENT | Fork environment/dependency/ignore change; retain upstream version. |
| `api.rb` | 3 | 1 | EXCLUDE_ONLINE | Friend-login/CSP/app integration; retain upstream version. |
| `assets/app/app.rb` | 2 | 2 | EXCLUDE_ONLINE | Friend-login/CSP/app integration; retain upstream version. |
| `assets/app/user_manager.rb` | 7 | 0 | EXCLUDE_ONLINE | Friend-login/CSP/app integration; retain upstream version. |
| `assets/app/view/game/part/location_name.rb` | 1 | 1 | EXCLUDE_UNRELATED | Global character width 8 -> 16; use upstream English rendering. |
| `assets/app/view/game/pass.rb` | 3 | 1 | EXCLUDE_UNRELATED | General hotseat auto-pass; not a 1890 rule. |
| `assets/app/view/game/round/operating.rb` | 2 | 0 | REVIEW_DEPENDENCY | JR zero-route/empty step; PR 7 only if reproduced. |
| `assets/app/view/game/route_selector.rb` | 2 | 2 | REVIEW_DEPENDENCY | Transferred train history; PR 11c only if reproduced. |
| `assets/app/view/navigation.rb` | 3 | 0 | EXCLUDE_ONLINE | Friend-login/CSP/app integration; retain upstream version. |
| `assets/app/view/user.rb` | 18 | 0 | EXCLUDE_ONLINE | Friend-login/CSP/app integration; retain upstream version. |
| `docker-compose.online.yml` | 75 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `docker-compose.windows.yml` | 19 | 0 | EXCLUDE_ENVIRONMENT | Fork environment/dependency/ignore change; retain upstream version. |
| `docs/1890-implementation-status.md` | 123 | 0 | REFERENCE_ONLY | 1890 research/playtest reference; do not copy raw planning notes into game PR. |
| `docs/1890-kobe-rapid.md` | 283 | 0 | REFERENCE_ONLY | 1890 research/playtest reference; do not copy raw planning notes into game PR. |
| `docs/1890-requirements.md` | 159 | 0 | REFERENCE_ONLY | 1890 research/playtest reference; do not copy raw planning notes into game PR. |
| `docs/1890.webp` | - | - | REFERENCE_ONLY | 1890 research/playtest reference; do not copy raw planning notes into game PR. |
| `docs/cloudflare-tunnel-runbook.md` | 254 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `docs/friend-access-guide.md` | 53 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `docs/online-play-plan.md` | 166 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `docs/online-play-quickstart.md` | 101 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `docs/プレイしての指摘.txt` | 10 | 0 | REFERENCE_ONLY | 1890 research/playtest reference; do not copy raw planning notes into game PR. |
| `lib/engine/corporation.rb` | 4 | 0 | REVIEW_DEPENDENCY | PR 8/9; minimal core hook only if game-local/current engine alternatives insufficient. |
| `lib/engine/game/g_1889/game.rb` | 35 | 0 | EXCLUDE_UNRELATED | 1889 edits or removed tests; retain upstream version. |
| `lib/engine/game/g_1889/meta.rb` | 1 | 1 | EXCLUDE_UNRELATED | 1889 edits or removed tests; retain upstream version. |
| `lib/engine/game/g_1890.rb` | 8 | 0 | EXTRACT | PR 1 game entry point. |
| `lib/engine/game/g_1890/entities.rb` | 374 | 0 | EXTRACT | PR 1 basic definitions; abilities with owning feature. |
| `lib/engine/game/g_1890/game.rb` | 913 | 0 | EXTRACT | Split methods across PRs 1-14; never copy whole file. |
| `lib/engine/game/g_1890/map.rb` | 269 | 0 | EXTRACT | PR 1 map data; upgrade/revenue behavior in PR 4. |
| `lib/engine/game/g_1890/meta.rb` | 38 | 0 | EXTRACT | PR 1 English prealpha metadata; optional rule only in PR 13. |
| `lib/engine/game/g_1890/round/operating.rb` | 51 | 0 | EXTRACT | Metro PR 8; Kintetsu PR 11c; ordinary round support only if needed in PR 3. |
| `lib/engine/game/g_1890/step/buy_company.rb` | 19 | 0 | EXTRACT | PR 3 minor skip; private purchase rules in PR 5. |
| `lib/engine/game/g_1890/step/buy_sell_par_shares.rb` | 35 | 0 | EXTRACT | PR 2 attached shares; JR fixed par in PR 7. |
| `lib/engine/game/g_1890/step/buy_train.rb` | 18 | 0 | EXTRACT | PR 3; justify unconditional can-buy override. |
| `lib/engine/game/g_1890/step/dividend.rb` | 59 | 0 | EXTRACT | PR 3 minors; PR 7 JR; PR 9b Kobe; PR 11c Kintetsu. |
| `lib/engine/game/g_1890/step/exchange.rb` | 119 | 0 | EXTRACT | PR 10 Kobe Electric; PR 11b/c Kintetsu. |
| `lib/engine/game/g_1890/step/minor_exchange.rb` | 56 | 0 | EXTRACT | PR 11; verify helper callers and remove unused copied methods. |
| `lib/engine/game/g_1890/step/route.rb` | 28 | 0 | EXTRACT | PR 13 Tigers optional rule. |
| `lib/engine/game/g_1890/step/special_track.rb` | 31 | 0 | EXTRACT | PR 5 Arima sale-triggered tile. |
| `lib/engine/game/g_1890/step/token.rb` | 63 | 0 | EXTRACT | PR 9b Kobe Rapid passage actions. |
| `lib/engine/game/g_1890/step/track.rb` | 101 | 0 | EXTRACT | PR 3 ordinary track; PR 4 upgrades; PR 8 Metro; PR 9b Kobe; PR 12 Hankyu. |
| `lib/engine/game/g_1890/step/waterfall_auction.rb` | 27 | 0 | EXTRACT | PR 2 auction. |
| `lib/engine/part/city.rb` | 1 | 0 | REVIEW_DEPENDENCY | PR 8/9; minimal core hook only if game-local/current engine alternatives insufficient. |
| `models/user.rb` | 4 | 0 | EXCLUDE_ONLINE | Friend-login/CSP/app integration; retain upstream version. |
| `public/logos/1890/JR.svg` | 5 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `public/logos/1890/メトロ.svg` | 5 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `public/logos/1890/京阪.svg` | 5 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `public/logos/1890/南海.svg` | 62 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `public/logos/1890/大軌.svg` | 5 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `public/logos/1890/奈良.svg` | 5 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `public/logos/1890/山陽.svg` | 5 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `public/logos/1890/河南.svg` | 5 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `public/logos/1890/神戸.svg` | 5 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `public/logos/1890/近鉄.svg` | 5 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `public/logos/1890/阪急.svg` | 5 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `public/logos/1890/阪神.svg` | 5 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `public/logos/1890/阪鉄.svg` | 5 | 0 | EXTRACT | PR 1; translate filename and SVG text, validate color and references. |
| `routes/user.rb` | 27 | 0 | EXCLUDE_ONLINE | Friend-login/CSP/app integration; retain upstream version. |
| `scripts/online/README.md` | 56 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/check-public.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/check-public.ps1` | 49 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/collect-diagnostics.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/collect-diagnostics.ps1` | 61 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/db-backup.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/db-backup.ps1` | 46 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/db-list-backups.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/db-list-backups.ps1` | 20 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/db-restore.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/db-restore.ps1` | 73 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/dev-down.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/dev-down.ps1` | 19 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/dev-up.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/dev-up.ps1` | 51 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/doctor.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/doctor.ps1` | 87 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/env.ps1` | 56 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/init-env.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/init-env.ps1` | 49 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/logs.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/logs.ps1` | 29 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/online-down.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/online-down.ps1` | 16 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/online-up.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/online-up.ps1` | 30 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/overview.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/overview.ps1` | 42 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/play-start.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/play-start.ps1` | 49 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/play-stop.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/play-stop.ps1` | 20 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/preflight.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/preflight.ps1` | 78 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/status.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/status.ps1` | 19 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/tunnel-down.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/tunnel-down.ps1` | 23 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/tunnel-logs.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/tunnel-logs.ps1` | 32 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/tunnel-up.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/tunnel-up.ps1` | 32 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/wait-local.cmd` | 2 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `scripts/online/wait-local.ps1` | 38 | 0 | EXCLUDE_ONLINE | Personal online deployment or tunnel support. |
| `spec/assets/app/view/game/pass_spec.rb` | 46 | 0 | EXCLUDE_UNRELATED | General hotseat auto-pass; not a 1890 rule. |
| `spec/assets_spec.rb` | 14 | 49 | EXCLUDE_MIXED | Contains friend-login test and removed 1889/tutorial coverage; retain upstream version. |
| `spec/lib/engine/game/g_1889/game_spec.rb` | 0 | 128 | EXCLUDE_UNRELATED | 1889 edits or removed tests; retain upstream version. |
| `spec/lib/engine/game/g_1890/game_spec.rb` | 3744 | 0 | EXTRACT | Split contexts and shared helpers into owning PRs; remove local-beta expectation. |
| `spec/lib/engine/round/auction_spec.rb` | 0 | 105 | EXCLUDE_UNRELATED | 1889 edits or removed tests; retain upstream version. |

## Reproduce the inventory

```sh
git diff --numstat 5933dd67853ddcb3a93e9134817a08fd11be8b60 f876638ed82a4e0e07715fbe4428df1624bf3f15
git diff 5933dd67853ddcb3a93e9134817a08fd11be8b60 f876638ed82a4e0e07715fbe4428df1624bf3f15 -- lib/engine/corporation.rb lib/engine/part/city.rb
```

For PR review, separately compare the extracted branch against its actual latest upstream base. A clean upstream starting tree is the primary exclusion mechanism; a keyword scan alone cannot prove online changes are absent.
