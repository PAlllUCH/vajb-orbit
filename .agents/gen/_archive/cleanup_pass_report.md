# Cleanup pass report — 2026-09-18

Executed per `CLEANUP_PLAN.md` §4 and `CLOSEOUT_PLAN.md` after engine wave 1
closed (review2 clean: 8/8 fixes verified, P1 suite 53/53). No worker was in
flight during any step. The five sealed-archive moves and `_mockup_station.tscn`
deletion are **deferred** (owner-granted `VAJB_ARCHIVE_OK=1` session; S2 live
verification tick) — listed in the open items.

## 1. Executed briefs + uncited run logs deleted (51 files)

Disposition authority: `CLEANUP_PLAN.md` §3; the exact list is preserved at
`.agents/gen/_wave_state/cleanup_delete_list.txt` and in git history
(baseline commit `2a420a7`).

- 30 executed task briefs (`d1..d6`, `m1`, `s1`, `s2`, `p1a..p1r2`, `p1fix`,
  `p1h`, `p1i`, `p1j`, `p1k`, `p1l`, `p1l2`, `fix_wave1`) — every
  `*_report.md` kept (46 remain).
- `engine_wave1_task.md`, `engine_wave1_prompts.md`,
  `engine_brainstorm_notes.md` — engine wave 1 is closed;
  `ENGINE_SPEC.md` + `docs/CONTRACTS.md` are the artifacts.
- 4 named probe scripts (`d6_measure.py`, `d6_preview.py`,
  `w5_probe_source.gd`, `w7_ctex_mips.py`).
- Uncited run logs (boot gates, theme runs, `w7_tests.txt`,
  `w5_game_probe_source.*`): deleted only after a citation check — every file
  a `*_report.md` (or `AGENTS.md`/`ENGINE_SPEC.md`) cites, including
  wildcard citations like `engine_wave1_review2_boot_*.txt`, was kept.
  `headless_sweep.log`, `profile_backup_20260918.cfg`, `previews/` kept.

`.agents/gen/` now holds 119 files: 46 reports, WAVEBOARD, cited evidence
logs, previews, wave-state.

## 2. MAIN_MENU_SPEC merge → supersede

- Boot (§1) + loading (§2) + boot transitions + their acceptance items were
  absorbed **verbatim** into `MAIN_MENU_V2.md` as new **§17** (17.1–17.4).
- `MAIN_MENU_SPEC.md` now carries a SUPERSEDED header pointing to
  `MAIN_MENU_V2.md` §17; it stays in place until the sealed pass moves it to
  the sealed archive together with the reference repointing
  (CLEANUP_PLAN §4.3).

## 3. AGENTS.md doc map + status updated

- Phase-status line records engine wave 1 closed + review evidence.
- Doc map: new workspace-root table (`ENGINE_SPEC.md`, `docs/CONTRACTS.md`,
  `.agents/gen/WAVEBOARD.md`, `CLEANUP_PLAN.md`/`CLOSEOUT_PLAN.md`); agent
  tooling paragraph (verify_wave.py, both hooks, the universal test gate
  command, text-only repo rule); `MAIN_MENU_SPEC.md` row rewritten to
  "superseded, pending archive".

## 4. Reference audit (zero broken references)

Grep over all live `.md`/code (reports excluded as historical) for every
deleted name. Hits found and repointed:

| Live file | Was | Now |
|---|---|---|
| `vajb-orbit/game/sector.gd` comment | `engine_wave1_task.md` items 7–8 | `docs/CONTRACTS.md` §6, ENGINE_SPEC §7 |
| `vajb-orbit/game/sector_registry.gd` comment | brief item 8 | `docs/CONTRACTS.md` §6 |
| `TESTING_NOTES.md` wave-1 evidence | `fix_wave1_task.md` | `fix_wave1_w7_report.md` |
| `IMPLEMENTATION_PLAN.md` §9.x | `fix_wave1_task.md` | `fix_wave1_w7_report.md` |
| `docs/CONTRACTS.md` changelog | names the deleted brief | names the surviving report |
| `AGENTS.md` phase status | claims both mockups pending deletion | menu mockup already deleted; station mockup still gated |

Remaining intentional mentions: `CLEANUP_PLAN.md`/`CLOSEOUT_PLAN.md`
(dispositions of this very pass), spec references to the mockups as
historical design record (`IMPLEMENTATION_PLAN` §9.6, `MAIN_MENU_V2` §10/§15,
`STATION_HUB` §12.6 — still gated on S2), and spec citations to
`MAIN_MENU_SPEC.md` sections that still exist on disk (repointed in the same
sealed pass as the move).

## 5. Verified clean

- `vajb-orbit/tools/`: only `build_theme.gd` + `derive_icon_tints.gd`
  (+ `.uid` sidecars) — W4/W7 probes correctly removed by the workers.
- Zero `*_task.md` anywhere in `.agents/gen/`.
- Test gate not re-run: no game code touched by this pass except two comment
  lines (`sector.gd`, `sector_registry.gd`).

## 6. Deferred (open items for the next pass)

1. **Sealed-archive moves** (needs `VAJB_ARCHIVE_OK=1`): `GENERATION_PLAN.md`,
   `ASSET_EXPANSION_SPEC.md`, `ASSET_EXPANSION_SPEC_E.md`, `PHASE_C_STATUS.md`,
   `ASSET_AUDIT.md` → the sealed archive + README index, **plus** the
   `MAIN_MENU_SPEC.md` move and the citation repointing across
   `IMPLEMENTATION_PLAN`/`ENVIRONMENT_SPEC`/`UI_CHROME`/`UI_SPEC`/`FX_SPEC`/
   `ICONS_SPEC`/`ASSET_CATALOG` in the same run.
2. **`_mockup_station.tscn` + `_mockup_station.gd`** — gated on the live S2
   verification + wave-4 review closing.
3. **`TESTING_NOTES.md`** — kept as the batch-2 playtest lane; absorbed into
   an IMPLEMENTATION_PLAN amendment only after batch-2 items land.
