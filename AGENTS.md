# 1890 upstream extraction instructions

## Goal and source of truth

Extract the existing 1890 implementation into small, sequential, reviewable PRs against `tobymao/18xx`. Translate contributed game content into English. Exclude all fork-specific hosting, Cloudflare Tunnel, friend-login, and local deployment changes.

- Frozen source: `ddsotos/18xx`, commit `f876638ed82a4e0e07715fbe4428df1624bf3f15`.
- Preservation branch: `g1890-full-snapshot-f876638`. Never move, rewrite, or delete it during extraction.
- Initial upstream baseline: `3027b7bc80a3e79d61cc551c53906a3578630f60`.
- PR 1 branch: `g1890-pr1-base`, initially identical to that baseline.
- Planning branch: `g1890-upstream-preparation`. Its documents are working instructions, not upstream deliverables.
- Read `docs/1890-upstream/extraction-plan.md`, `inventory.md`, and `localization.md` before implementing.

The snapshot is a behavioral reference, not proof of rule correctness. The source documents reference a user-local `1890rule.pdf` which has not been provided in this workspace. Existing tests and requirements are secondary evidence. Record the rule source and section for each extracted behavior; do not invent a rule or metadata when primary evidence is missing.

## Branch and scope discipline

Start each submitted PR from the latest fetched upstream `master`, after its dependencies have merged. Preserve the source branch and all unrelated user changes. Do not merge the full source branch into a PR branch, copy the entire source tree, or cherry-pick mixed commits without inspecting every hunk.

The current authorized preparation task is to preserve the source, inventory changes, and write these instructions. For the next implementation task, extract PR 1 only unless the user requests a wider scope. Do not publish upstream PRs or contact maintainers merely because a preparation branch exists.

Do not merge this planning branch into a game PR. To use these instructions on a PR branch, supply this file as task context or an untracked local instruction file that does not overwrite an existing instruction file. Review the staged diff to keep preparation documents out of submitted PRs.

## Extraction constraints

1. Prefer 1890-local subclasses, modules, and existing engine extension points.
2. A shared engine or UI change needs a demonstrated 1890 dependency, an explanation of its impact, and focused regression coverage. Check the current upstream implementation before introducing a new hook.
3. Do not carry any source edits to authentication, API/CSP, deployment, dependencies, online scripts, 1889 implementation, or 1889/tutorial tests into the game PRs. Retain upstream versions. The inventory distinguishes online changes from other excluded changes.
4. Do not remove, skip, or weaken existing tests to make an extracted feature pass.
5. Translate each feature while extracting it. Keep entity IDs, share IDs, ability targets, logos, event handlers, and tests consistent with the mapping in `localization.md`. Do not translate engine API identifiers or alter monetary values, timing, routes, or ownership semantics.
6. Eliminate rule comparisons against translated location display strings where practical, using the same source hex IDs. Verify equivalent behavior. Ruby `Minor#name` and `Corporation#name` are based on `sym`; full display names are separate. Update these references deliberately.
7. Translate SVG text as well as filenames. Check logo references and rendered layout. Preserve attribution and do not invent publisher metadata.
8. A PR may leave the game incomplete, but must load cleanly, avoid references to missing classes/events/abilities, and meet upstream checks for its scope. Use `:prealpha` for the initial skeleton, consistent with upstream metadata defaults; do not copy the source's local-play `:beta` requirement or advertise unimplemented optional rules.
9. Include feature tests in the same PR. If helpers precede wiring, test their contracts in that PR. Add edge-case coverage with the behavior it protects. Add complete-game replay only once its dependencies exist.

## PR 1 boundary

Add the game entry point, metadata, English map/tile definitions, basic company/corporation/minor definitions and logos, and a small game class containing static cash, certificate, stock-market, train, and phase data. Start with the map and entry point if the static payload is still too large for one review.

Do not copy the 913-line source game class or the 3,744-line spec. Omit train event registrations whose handlers are deferred; introduce each registration with its tested event. Defer private abilities, exchanges, special OR logic, special revenue selection, and token-blocking hooks to their owning PR. Include only the setup necessary to load and inspect the skeleton; do not quietly implement a later PR to satisfy an unrelated full-game test.

## Verification and reporting

Read current upstream `DEVELOPMENT.md`, `.github/PULL_REQUEST_TEMPLATE.md`, and `.github/workflows/ruby.yml`. During development run focused tests for the extracted feature; exercise affected shared behavior when shared code changes. Before submission run the upstream lint, Opal compilation, and test gates where available:

```sh
bundle exec rake rubocop
bundle exec rake compile_all
bundle exec rake spec_parallel
```

The documented Docker verification entry point is `docker compose exec rack rake`; it does not replace checking the CI compilation requirement. Report exact commands, outcomes, and unavailable gates. Do not claim tests passed from historical source documentation. This preparation environment has no Ruby or Docker executable, so runtime verification has not been performed here.

PR titles use `[1890]`; prepend `[core]` if shared engine code changes, per upstream guidance. Describe the rule and reference, added scope, deferred scope, reused code, validation, and known limitations. Review the complete diff against the PR base for unrelated files, Japanese remnants in contributed content, stale logo paths, unimplemented events, test weakening, and hosting changes.
