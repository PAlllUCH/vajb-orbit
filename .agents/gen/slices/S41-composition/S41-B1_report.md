---
slice: S41
worker: S41-B1
model: "deepseek-v4.1-flash (hyper)"   # the session model this worker ran on
status: informational
gate: "1300/0 → 1304/10 twice (identical), then 1306/14 and 1321/2 as B3/B4 landed work; this worker's 12 rows green in all four"
---

# S41-B1 report

## Result
T-177: the generator preserves the committed `.tres`'s 19 `uid://` lines and a regeneration is a byte no-op.
F7: every disabled plate keeps a 1 px `metal_mid` edge. F9: the grabber is `text_meta`, the track gains a
`metal_dark` edge, the grabber floor is 48 px. F12: the shell's duplicate SERVICES hint is gone. F16: the
tooltip clears the 163 px header band. `tests/test_s41_shell.gd`: 12 rows, 0 failures.

## Acceptance list answers
1. **A1** — fixed at their named sites: T-177 `build_theme.gd:238,250,261,282,305`; F7 `:133` + the three
   plates (`:419` tabs, `:542` Tree, `:569` Button); F9 `:137,521-523,660-666`; F12 `station.gd:122-125,1175-1185`;
   F16 `tooltip.gd:25,133-134`. Nothing was silently dropped.
2. **A2** — no fix writes `position`/`offset_*`; no `size_flags_vertical = 3` was added. The one flag added is
   `size_flags_horizontal = EXPAND_FILL` on `PaneActions` (`station.gd:1181-1185`), an empty `HBoxContainer`
   that owns the foot band's slack — a container, not a visual box.
3. **A3** — every colour is written once in `build_theme.gd` and regenerated; no token *value* changed,
   so no contrast re-measurement is owed. Table below.
4. **A4 / A5** — not this worker's set: F1–F6, F8, F10, F11, F13–F15 belong to B2/B3/B4 (brief §3).
5. **A6** — proved: `[build_theme] uids preserved: 19 (1 resource + 18 ext_resource)`, then a second run leaves
   the file byte-identical. The suite runs the generator itself and asserts the same, with a precondition that
   the input carries uid lines, so a stripped input cannot pass vacuously.
6. **A7** — reverting all five fixes and re-running turned 8 of 12 rows red: `f7_a_disabled_plate_keeps_a_visible_edge`,
   `f7_the_edge_is_not_the_fill_it_used_to_be`, `f9_the_grabber_and_the_track_read_at_1080p`, `f9_the_grabber_answers_the_48_px_floor`,
   `f9_the_grabber_left_the_track_tone`, `f12_the_services_deck_prints_its_hint_once`, `f16_the_tooltip_clears_the_header_band`, and on
   the T-177 revert alone `t177_a_generator_run_is_a_no_op...` ("first differing line 1"). The 4 that stayed green are the controls
   (`f7_the_disabled_ink_is_untouched`, `f16_an_ordinary_placement_is_untouched`, `t177_the_generated_theme_keeps_its_uid_lines`,
   `t177_the_strip_this_wave_prevents_is_detectable`). Reads use `get()`; no row awaits.
7. **A8** — no §6 suite's count moved: per-suite counts are identical across the two full runs of this session (109 suites →
   110, the extra being B2's `s41_panels_a`), and `1300 + 12 (mine) + 1 (s41_armory) + 1 (s41_panels_a) = 1314 = 1304 + 10`.
   `s40_legibility` stays 8 rows, `d7_status` 8, `d7_cockpit` 18, `p2b_services` 15, `s25_contracts` 26, `s27_catalog` 25,
   `ui_slot_layout` 12, `s32_armory_modes` 23.

## Tokens (A3) — all PROPOSED, the owner ratifies shared-chrome tones
| Token | Where it now lands | Value | Reversal |
|---|---|---|---|
| `metal_mid` (existing) | the disabled plate's edge, all three sites | `#2a313c` | `DISABLED_EDGE` → `&"metal_dark"` (one const) |
| `text_meta` (existing) | `VScrollBar` grabber + `grabber_highlight` fill | `#9aa3b0` | the two `_c(&"text_meta")` → `_c(&"metal_light")` |
| `metal_dark` (existing) | `VScrollBar` track's 1 px edge | `#1b2028` | `scroll`'s 2nd arg → `_c(&"metal_mid")` |
| `SCROLL_GRABBER_MIN_HEIGHT` (new, `build_theme.gd:137`) | the grabber floor, as 24+24 content margins (a `StyleBoxFlat`'s minimum is its content margins, not the border) | 48 px | zero the two margins in `_scroll_grabber_box` |
| `DISABLED_EDGE` (new, `:133`) | names F7's edge token once | — | inline `&"metal_mid"` |
| `HEADER_BAND_BOTTOM` (new, `tooltip.gd:25`) | the pane header band's bottom, UI_SPEC §19.3's own number | 163 px | delete the two guard lines |

## Deviations from SLICE.md
- **F7 scope.** The audit cites `build_theme.gd:317` (the TabContainer disabled plate) but names the
  refinery's disabled *Buttons* as the symptom, so the edge went to all three `_flat(metal_dark,
  metal_dark)` sites. Reversal: keep only `boxes[&"button_disabled"]`.
- **F9 also moved `grabber_highlight`'s fill** to `text_meta`, keeping its ember border: the audit says
  "the grabber family's fill". Reversal: that one line back to `metal_light`.
- **F12 retired the whole label**, not just its `text` write: an empty `StationCaption` node in the band
  would be F4's own "caption-only empty plate" defect. The empty action slot took the label's expanding
  seat (`alignment = END` + `EXPAND_FILL`) so the band's right-aligned cluster seat (§19.3, §8 P1)
  survives. Reversal: restore the label block.
- **T-177 is a text post-pass** over the file the save wrote: the engine cannot recover the uids headless
  (loading the committed theme and re-saving strips them *and* re-ids 160 lines of sub_resources). A new
  `ext_resource` takes its uid from the editor's next save. Reversal: drop the two calls in `_run`.
- **One-time token reorder.** The first regeneration re-sorts `Tokens/colors/text_caption`,
  `text_caption_void`, `text_dim` — S40 hand-inserted them out of the saver's alphabetical order
  (`git show a979233`). Values unchanged; every later run is a no-op.

## Evidence
- `--script res://tools/build_theme.gd` → `[build_theme] uids preserved: 19 (1 resource + 18
  ext_resource)`; a second run leaves the file byte-identical (`md5sum -c` OK).
- Gate, fresh `XDG_DATA_HOME` per run, `--quit-after 2400`: `passed=1304 failed=10`, `passed=1304 failed=10`
  (the identical pair), then `passed=1306 failed=14` and `passed=1321 failed=2` as B3/B4 landed work
  mid-run. My 12 rows: 12 PASS / 0 FAIL in all four.
- The residual failures are **not this worker's**: `test_d7_armory.gd` fails 6 rows *identically* with my
  four files at HEAD (`git checkout HEAD -- …`, `--suite=test_d7_armory` → `passed=5 failed=6`) — B3's
  in-flight `armory_panel.tscn/.gd`; the lint row names `test_s41_panels_b.gd:28-29`.
- Revert run (all five fixes backed out): `passed=4 failed=8`, the rows named in A7; F16 reads `y=8.0` reverted
  against `y=318.0` fixed, F12 reads 2 visible hints reverted against 1. `w5_uidcheck.py` → `stale=0`.

## Files touched
- `tools/build_theme.gd` — T-177 uid pass; F7 `DISABLED_EDGE`; F9 scroll chrome + grabber floor
- `ui/theme/vajb_theme.tres` — regenerated (3 disabled edges, track edge, grabber fill + margins)
- `ui/screens/station.gd` — F12: `SERVICES_HINT` and its label retired; the action slot keeps the seat
- `ui/components/tooltip.gd` — F16: the `HEADER_BAND_BOTTOM` guard in `_place`
- `tests/test_s41_shell.gd` — new, 12 rows (T-177 ×3, F7 ×3, F9 ×3, F12 ×1, F16 ×2)

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| The confirm dialog's title sets `font_size 18` inline instead of a theme size token (D23-R1 A3's note, filed as no finding) | ticket | `ui/screens/station.gd:531` |
