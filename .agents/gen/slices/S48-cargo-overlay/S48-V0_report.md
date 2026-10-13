---
slice: S48
worker: S48-V0
model: hyper/glm-5.3-flash
status: actionable    # the flight half of A7 is owed (bucket-2, see Deviations)
gate: "1396/0 → 1404/0"
---

# S48-V0 report

## Result
The C-key cargo overlay ships as one shared scene/script
(`ui/dialogs/cargo_overlay.gd` + `.tscn`) and the station half of A7 is fully
wired: C opens it from any pane in its layer-19 seat (above the panes, below the
drawer/sheet/dialog layers), and C again / ESC (the shell's own `_handle_cancel`
step) / the scrim close it, with focus returning to the trigger. The five A9
groups read the pinned seams only. Gate 1396/0 → 1404/0 (`--times 1`; the new
suite's 8 rows are the delta). **The flight half of A7 is NOT landed** — this
session's `VAJB_WORKER_FILES` names `vajb-orbit/game.gd`, which is not a repo
file, so the file-set hook refused every `game/game.gd` edit (bucket 2). The
exact hunks are prepared in `S48-V0_game_gd_patch.md` beside this report.

## Acceptance list answers
1 — DONE — the surface is the N28 idiom in the shared scene: full-rect STOP root
    → void_base 60 % dimmer → CenterContainer → `PanelRaised` panel → margin 16 →
    VBox 12, size-to-content in the 420/720 band under the 80 %-viewport scroll
    (`cargo_overlay.gd:31-38,381-412`; pinned by `test_the_surface_is_the_n28_idiom`).
2 — DONE — title `CARGO — <n>/<cap> UNITS`, `<n>` the summed hold (the
    `_cargo_used` exemplar) and `<cap>` = `Catalog.ship(active).cargo` (08 §3;
    `cargo_overlay.gd:41,252-266`; pinned by `test_the_title_carries_the_hold_...`).
3 — DONE — the five `StationCaption` bands in A9's order with the pinned row
    words; glyphs 24 at their own rect (A5.2(iii)); the 02 §6 tier tint on
    ore/ingots, the 03 §4.1 grade tint on components/fuel cells, weapon glyphs
    the dedicated art untinted; `NONE HELD` on an empty group; every figure
    reads `cargo_items()`/`ammo_of()` only (no price, no quote) — pinned by
    `test_the_five_groups_carry_the_pinned_rows` +
    `test_an_empty_group_reads_none_held` (builders at `cargo_overlay.gd:172,276,317,339`).
4 — DONE — the overlay builds zero `BaseButton` nodes (pinned by
    `test_no_transactional_control_inside`); the only close affordances are the
    pinned implicit ones.
5 — DONE — the shell handles `cargo_toggle` from any pane
    (`station.gd:451-454` C branch → `_toggle_cargo`, `station.gd:1078-1091`);
    the seat is its own CanvasLayer 19, below the drawer/sheet/confirm layers
    (`station.gd:234-239,509-513`); ESC is the shell's step inside
    `_handle_cancel` after the drawer, per §12.2's stack law read topmost-first
    (`station.gd:2036-2038`); C again/scrim/ESC close; focus returns via the
    overlay's own N39 memory (`cargo_overlay.gd:438-445`); envelope
    `MOTION_SECONDS` 0.18 ≤ 0.2 s. Pinned by
    `test_the_shell_handles_c_from_any_pane` and
    `test_the_ladder_keeps_the_higher_overlays_in_front`.
6 — NOT DONE — the flight host (`game.gd` layer-20 CanvasLayer, the poll
    rewrite, the ESC topmost step, the mirror) is blocked: the declared file set
    names `vajb-orbit/game.gd`, the repo file is `vajb-orbit/game/game.gd`, and
    the hook denies the edit (bucket 2 — a pinned set change is not mine to
    make). Prepared verbatim in `S48-V0_game_gd_patch.md` (6 hunks + the flight
    test rows); a fixer with the corrected set lands it in one pass.
7 — PARTIAL — `tests/test_s48_cargo_overlay.gd` pins items 1–5 and A7's C
    binding (8 rows, all passing); the flight rows listed in the patch file
    remain to be added with hunk 1–6.

## Deviations from SLICE.md
- **Bucket 2 (the pause):** `VAJB_WORKER_FILES` says `vajb-orbit/game.gd`; the
  brief's Hard constraints say `vajb-orbit/game/game.gd`. The hook enforces the
  env, so the flight half is unlanded. Remedy: correct the dispatch env (or
  hand the fixer the patch file) and re-dispatch; nothing else blocks it.
- Bucket-1 calls, made and reported: (a) C is refused while the
  drawer/sheet/confirm is up or the departure sequence runs — the overlays
  above the cargo seat own the input (§5.2 one-at-a-time; §12.2's stack);
  (b) an open overlay live-refreshes on the profile's `cargo`/`ammo` keys so a
  pickup landing in flight cannot show a stale hold (`cargo_overlay.gd:148-159`);
  (c) rows wear the `StationCaption` 13 px variation with a `text_primary` ink
  override (the sheet's own variation+override pattern; §16.1's legibility
  lesson), bands keep the variation's ratified `text_caption` ink; the
  `ESC · CLOSE` hint row is §12.3's row 6, which the N28 idiom carries;
  (d) AMMUNITION dedupes to one row per fitted weapon family (two barrels share
  one pack; a per-barrel row would double-show one figure), in cell order;
  (e) group rows follow 05 §8's catalogue order (the exchange hold's own law);
  an id no catalogue answers is not drawn (§5.8's rule).

## Evidence
- Baseline: `python3 staging/gate.py --times 1` → `[SUMMARY] passed=1396 failed=0`.
- After: same command → `[SUMMARY] passed=1404 failed=0` (the wrapper's
  SCRIPT-ERROR scan clean).
- Suite alone: `... headless_runner.tscn ++ --suite=test_s48_cargo_overlay` →
  `[SUMMARY] passed=8 failed=0`.
- A throwaway `/tmp` probe (since removed from the suite) confirmed the built
  node names and that a staged hold reads through `cargo_items()`.

## Files touched
- `vajb-orbit/ui/dialogs/cargo_overlay.gd` — new: the shared read-only surface,
  A9's five groups, the N28/N32/N29 laws, N39 focus return, live refresh.
- `vajb-orbit/ui/dialogs/cargo_overlay.tscn` — new: the scene shell (the sheet's
  shape; scroll under the 80 % rule).
- `vajb-orbit/ui/screens/station.gd` — the C branch in `_unhandled_input`, the
  `_handle_cancel` cargo step, the layer-19 seat built in `_build_popups`,
  `_toggle_cargo`/`_cargo_open`.
- `vajb-orbit/tests/test_s48_cargo_overlay.gd` — new: 8 rows pinning items 1–5
  plus the `cargo_toggle`→C binding.
- `.agents/gen/slices/S48-cargo-overlay/S48-V0_game_gd_patch.md` — the prepared
  flight hunks for the fixer (not a repo code file).

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Land A7's flight half from `S48-V0_game_gd_patch.md` (host, poll, ESC step, mirror) and add the suite's flight rows | feature | `vajb-orbit/game/game.gd`, `tests/test_s48_cargo_overlay.gd` |
