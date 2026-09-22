# CLOSEOUT_PLAN — wave 1 → cleanup → git → speed-up (2026-09-18)

Wave 1 is closed: `engine_wave1_review2_report.md` verified all eight fixes
(40/40 probe checks, boot gates exit 0, P1 suite 53/53, theme deterministic).
This plan sequences the post-wave work. Execution happens phase by phase, with
owner inputs marked ⏸. Authority for the cleanup details is `CLEANUP_PLAN.md`
§3–§4; this file only sequences it.

## Phase A — closure verification (no inputs needed)

- [x] Review2 report read: clean, two observations, no unresolved findings.
- [x] `tools/` ends clean (only `build_theme.gd` + `derive_icon_tints.gd`;
      W4/W7 probes correctly deleted).
- [ ] `verify_wave.py snapshot --name wave1_closed` — the pre-cleanup baseline
      every future wave diffs against.
- [ ] Skim W7 report §B5 rulings (M4–M7) for anything owed to the docs;
      route to W0-style doc amendments if found.

## Phase B — git baseline ⏸ owner inputs

1. ⏸ Owner sets identity (or approves one): `git config user.name/user.email`.
2. Commit 1: wave-1-closed state (pre-cleanup, safety snapshot). Message
   documents what the state is.
3. ⏸ Owner authorizes push to `github.com/PAlllUCH/vajb-orbit` — recommended,
   since it is also the Ubuntu migration vehicle. No push without the word.
4. Commit 2 after Phase C: the cleaned tree.

## Phase C — cleanup (per CLEANUP_PLAN.md §4)

Order chosen so the sealed archive is the last thing touched:

1. Delete executed briefs + probe/boot logs in `.agents/gen/`
   (`*_task.md`, `p1*_task.md`, `p1l*, p1k*…`, `*_probe*.txt`,
   `*_boot_*.txt`, `*_probe_source.*`, engine_wave1 task/prompts/brainstorm
   notes). **All `*_report.md` and `*_review_report.md` stay** (evidence chain).
   Keep `_fringe_backup/`, `_preview/`, `previews/`.
2. Merge `MAIN_MENU_SPEC.md` boot/loading content into `MAIN_MENU_V2.md`,
   then retire MAIN_MENU_SPEC (references updated).
3. TESTING_NOTES.md ⏸ owner tick: keep as-is until batch-2 lands
   (recommended — items are the parked playtest lane), or absorb the open
   items into an IMPLEMENTATION_PLAN amendment now.
4. AGENTS.md single edit: doc map update (new: `docs/CONTRACTS.md`,
   `.agents/gen/_state/WAVEBOARD.md`, `staging/verify_wave.py`, hook
   `enforce_worker_files.py`, test-gate command, enforcement protocol;
   removed: retired docs) — this is also the "agents inherit it" wiring.
5. Zero-broken-references grep across docs/AGENTS.md after the moves.
6. Sealed-archive moves ⏸ **requires `VAJB_ARCHIVE_OK=1` session** (the hook
   cannot be self-granted — it just proved that by blocking a plan draft that
   named the path). Targets per CLEANUP_PLAN §3: GENERATION_PLAN, the two
   ASSET_EXPANSION_SPECs, PHASE_C_STATUS, ASSET_AUDIT + archive README index.
   Options: owner restarts the session with the env granted, or defer these
   five moves to the Ubuntu session (hook re-registered there anyway).
7. `_mockup_station.tscn` ⏸ owner tick: deletion is gated on the live S2
   verification + wave-4 review closing (CODING_REPORT §7). `_mockup_main_menu`
   is already gone. If S2 is verified live, delete + note in report.
8. Write `.agents/gen/cleanup_pass_report.md`; commit 2.

## Phase D — speed wiring (same pass, no extra wave)

- Findings-tier rule into WAVEBOARD: HIGH blocks the wave; MED = one fixer
  pass; LOW → backlog file, rides with the next wave.
- Pre-brief slice 2 (combat) from `ENGINE_SPEC.md` §14: brief + paste-ready
  prompts, CONTRACTS sections inlined, `VAJB_WORKER_FILES` per worker → the
  gap between "review closes" and "dispatched" shrinks to minutes.
- Batch-2 lane brief (B2-1 hover, B2-2 backdrops, B2-3 minimap zoom) prepared
  as the parallel lane for the next engine wave.

## Phase E — Ubuntu migration notes (for the switch)

- Moving part: `git push` (Phase B) → clone on Ubuntu. Everything needed is in
  the repo; `assets/` binaries stay on Google Drive (regenerable + cataloged).
- Windows-only config that needs an Ubuntu twin in the project:
  `crush.json` hooks (`py -3.14` → `python3` paths), godot-ai MCP (uvx path),
  assetmcp venv path, gdscript LSP bridge path, Godot binaries
  (`C:\Godot_4_7_2\…` → Linux editor binary), AGENTS.md engine table row.
- `.gitattributes` reviewed for line endings before commit 1 so the Ubuntu
  clone is LF-clean.
- WAVEBOARD + CONTRACTS are plain files — they migrate with the repo unchanged.
