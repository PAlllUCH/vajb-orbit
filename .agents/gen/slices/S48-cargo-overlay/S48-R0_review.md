---
slice: S48
reviewer: S48-R0
verdict: clean
gate: "1409/0 → 1409/0 (re-measured, --times 1)"
---

# S48-R0 review — the C-key Cargo overlay (UI_SPEC §18 A7–A9, STATION_HUB §23.2)

Scope: the V0 brief's seven acceptance items graded against the landed tree —
the V0 report's station half plus F0's flight half (landed verbatim from
`S48-V0_game_gd_patch.md`; the dispatch env's file-set typo is not graded, the
tree is). Grade first, then the diff.

## Acceptance list
1 — pass — one scene serves both planes: preloaded by `station.gd:38` and
    `game.gd:49`; the tscn is the N28 chain verbatim (root full-rect
    MOUSE_FILTER_STOP `cargo_overlay.tscn:6-15` → dimmer :17-24 →
    CenterContainer :26-34 → `PanelRaised` :36-40 → margin 16 :42-48 →
    VBox 12 :55-59); width size-to-content clamped 420/720, height capped at
    80 % viewport with the scroll stepping in only past the cap
    (`cargo_overlay.gd:381-403`).
2 — pass — `CARGO — %d/%d UNITS` (`cargo_overlay.gd:41,164`); `<n>` sums the
    hold (`:252-256`), `<cap>` = `Catalog.ship(active_ship()).cargo`
    (`:261-266`; the 08 §3 cargo column, `station_catalog.gd:116-171`); pinned
    `test_s48_cargo_overlay.gd:266-274`.
3 — pass — the five `StationCaption` bands in A9's order (`cargo_overlay.gd:165-169`);
    the A9 row words off `cargo_items()`/`ammo_of()` (`:276-359`); glyphs 24 at
    their own rect (`:195-205`); 02 §6 tier tint / 03 §4.1 grade tint
    (`:362-371`); `NONE HELD` on an empty group (`:177-181`); pinned
    `test_s48_cargo_overlay.gd:277-343`.
4 — pass — zero `BaseButton` in the built tree (`test_s48_cargo_overlay.gd:348-360`);
    the overlay only reads the profile (`cargo_overlay.gd:237-271`) and writes
    nothing — no priced row, no quote, no transaction anywhere in the file.
5 — pass — C joins the shell's ladder from any pane (`station.gd:451-454` →
    `_toggle_cargo` `:1074-1091`); the seat is CanvasLayer 19, above the panes,
    below drawer/sheet/confirm (all 20 — `station.gd:236-240,243,509-515`);
    ESC is the ladder's cargo step below the overlays above it
    (`station.gd:2053-2058`); the Router-overlay guard stands (`:446-447`);
    C again / the scrim close; N39 focus return (`cargo_overlay.gd:438-444`);
    envelope 0.18 s ≤ 0.2 s (`cargo_overlay.gd:36`).
6 — pass — the flight host is the game scene's own layer-20 CanvasLayer
    (`game.gd:54,2560-2570`), above the HUD's layer 10 (`hud.tscn:35`), and no
    other CanvasLayer exists above it in the flight tree; the poll is the one
    driver through `_set_cargo_open` (`game.gd:1711-1737`), the mirror and the
    HUD's frozen setter stay in step (`hud.gd:2229-2235`; the retired panel
    latched hidden; hud.gd untouched in the diff); ESC closes as the one step
    before the map-deck step (`game.gd:1051-1056`); nothing pauses (pinned
    `test_s48_cargo_overlay.gd:469-474`).
7 — pass — 13 rows pin items 1–6 (8 station + 5 flight), the flight rows
    driving the polls directly per the brief's allowance.

## Diff audit
`git diff --name-only` over the repo tree names exactly the brief's five files;
every hunk in both screens is the cargo seam and nothing else — station.gd =
the preload, the layer consts/vars, the C branch, the seat build,
`_toggle_cargo`/`_cargo_open`, the ladder step; game.gd = patch hunks 1–6
verbatim (preload + `OVERLAY_LAYER`, seat vars, `_ready` build call, the poll
rewrite, the ESC step, the host builder), no number or name rewritten. The
tracked diff also carries one `.agents/` line — the V0 brief's own
gate-baseline correction (1330/0 → 1396/0), already present before the F0
dispatch and outside every `VAJB_WORKER_FILES` set, so it is dispatch prep in
the slice's own lane, not a worker overreach; recorded here, not graded.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | LOW | `station.gd:451` | The C branch lacks ESC's `Router.overlay_depth()` guard (`:446`): with a Router overlay pushed over the station, C opens the cargo overlay on layer 19 beneath it and it lingers after the pop. Harmless (read-only, closes by C/ESC) | → ticketed as T-201, not fixed here (close-out correction: T-201 was the free slot; this row's first-printed "T-202" is superseded and nothing else referenced it) |

## Bucket-1 calls accepted (reported by the builders, re-verified here)
- AMMUNITION dedupes to one row per fitted weapon family in cell order
  (`cargo_overlay.gd:288-297`) — two barrels share one pack; "one row per
  weapon" read per kind, the alternative double-shows one figure.
- C is refused while the drawer/sheet/confirm is up or the departure sequence
  runs (`station.gd:1079-1082`) — §5.2's one-at-a-time; the rows pin it.
- `cargo_qty()` itself is unreferenced: the quantities come off the dictionary
  `cargo_items()` returns — the same seam's own numbers
  (`player_profile.gd:646-651`); the no-recomputation law holds.
- The title's `<n>` counts every held id while an id no catalogue answers draws
  no row (§5.8's rule, V0 call (e)) — both clauses pin-faithful.
- The overlay live-refreshes on the profile's `cargo`/`ammo` keys while open
  (`cargo_overlay.gd:148-152`) — a read cannot go stale mid-flight.

## Verified fixes
None — no fixer pass in this review; F1 is the only finding and it is LOW.

## Gate
Dispatch baseline: 1409/0. Re-measured `python3 staging/gate.py --times 1` →
`[SUMMARY] passed=1409 failed=0` — exact match, wrapper-clean (no SCRIPT ERROR).
