---
slice: S20
reviewer: S20-R1
verdict: blocked (HIGH remains)
gate: "895/0 → 895/0 (two fresh scratch stores; baseline 887 re-derived)"
---

# S20-R1 review — ARMORY chrome unification & the shell inspector pin

Diffed against **UI_SPEC §3.10 Amendment 4** (A4.1–A4.5, the pin), with A3, §5.3,
§3.1/3.1b, CONTRACTS §23.1/§17/§9 and the brief only as secondary yardsticks. Every AC
re-measured in my own windowed standalone probe (`vajb-orbit/tests/probe_s20_review.gd`,
`XDG_DATA_HOME=$(mktemp -d)`, `--quit-after 900`, `[r1] failures=0`); the live profile is
untouched (`profile.cfg` md5 `d9d878e2178d26f9eac9fec3ebf11b20` before and after every run,
builder's own `d9d878e2…` headline confirmed). Probe captures, cropped live station frame
and the FX error lines: `/tmp/s20_r1_*.png`, `/tmp/s20_r1_probe.log`, `/tmp/s20_r1_gate*.log`.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S20-B1/F1 | HIGH | `tests/test_d7_armory.gd:601-608` (`test_danger_rows_follow_section_3_1_and_3_1b`) | **Row moved off brief §3's list** (bucket 2: the tests-that-move list is a pin): its expected colour changed `accent_danger` → `accent_danger_bright`, matching the pane's own `_style_danger` change. Forced by A4.3's 4.5:1 (probe: `accent_danger`'s best case against pure black is **4.377:1**; the bright pair is **4.855:1**) — the remedy is a list amendment, not a revert. | developer/designer session (list edit); no code revert |
| S20-B1/F2 | HIGH | `tests/test_d7_armory.gd:817-818` (`…_with_the_pinned_metrics`) | **Row moved off the list**: the caption expectations went `Color("#acb2ba")`/`Color("#969da5")` → `ThemeRes.get_color(Tokens/armory_caption[_void])`, values byte-identical (probe: `(0.6745,0.698,0.7294)` = the shipped `#acb2ba`). Forced by A4.3's zero-hex rule, which the brief applies to the wave's files and the builder is the only store (`build_theme.gd` 24 quoted hex, everything else 0). Brief §3's `798-807` range covers the same function but not this subject. | developer session (list edit); no code revert |
| S20-B1/F3 | MED | `ui/armory_panel.tscn:4,27` (pane scene) | **A4.1's retirement is incomplete on disk.** The scene still declares `ui_armory_console.png` as ext_resource `2_console` and still assigns it to `%ConsolePlate.texture`, so the master is loaded with the pane (cleared only at build, `armory_panel.gd:870`); `ASSET_CATALOG.md`'s "leaves the live tree in S20" is true only once the two lines go. No frame draws it (probe: `plate_texture=null` at runtime) — the builder reported this as deviation 1 (hook-blocked from the scene). | **S20-F1** — file set must add `vajb-orbit/ui/station/armory_panel.tscn` (2 lines) |
| S20-B1/F4 | LOW | `armory_panel.gd:_style_danger` | The resting pack-card chip's ink is `Tokens/text_dim` on `armory_chip_bg` = **2.700:1** (probe: `overlay=false` on the in-stock card), the pane's only sub-floor ink now that L227's target is cured; pre-existing (the removal predates S20) and pinned by an unlisted d7 row, so a cure edits bucket-2 ground. → **L234** | ticket only |
| S20-B1/F5 | LOW | `ui/screens/station.gd:_pin_inspector_height` | A4.4's constant block moves the shell's *resting* geometry: the armory pane's host is **(452,204)+1392×606** with the pins and **(452,214)+1392×610** with them cleared at runtime (probe: `collapsed`/`repinned`), i.e. A3's "measured" host sentence now describes a state the shell no longer reaches and the live console is **1360×512** at rest; no suite-pinned number moved (see AC6). → **L235**, folds into L228 | ticket only |
| S20-B1/F6 | LOW | `armory_panel.gd:1096-1102` | The `X` chip's box is **24×29**, not the `Vector2(24, 24)` the pane writes — the `StationButton` plate's own minimum wins (probe: `close_size=(24.0, 29.0)`); the 24 px S10 hit-target floor and the 117×52 cell still hold. → **L236** | ticket only |

**The wave leaves 2 HIGH (both bucket-2 list deviations, no code revert), 1 MED and 3 LOW
(L234–L236)**; L237 above is a pre-existing gate-honesty row found by my runs, not a S20
defect. No fixer pass can take F1/F2 — they are the tests-that-move list, which is a pin.

## AC verdicts (my own measurements, AC1–AC6)

- **AC1 pass** — zero `ui_armory_console` in `armory_panel.gd`/`armory_style.gd`; the
  plate's texture is `null` at build; bays and wells draw `PanelRaised/panel`
  (`ui_panel_frame.png`, texture margins 32, expand 1) and the chrome's box is the very
  resource a sibling `PanelRaised` resolves (probe `ac1`). Residual = F3.
- **AC2 pass** — all 20 cells draw `SlotButtonWeapon/normal`
  (`ui_slot_weapon_normal.png`) and the box is the family's own; the fitted name plate,
  `BUY` and the `X` are `StationButton`/`ui_button_plate_normal` with `flat` gone; state
  chips keep label + 1 px frame (`frame_width==1`) in Tokens tones with the chevron on
  the over-cap chip. A real left click on `BUY` (viewport-routed, station phase at 1:1):
  `hovered=Buy`, `emissions=1`, cargo `0 → 6` units = exactly one rocket pack.
- **AC3 pass** — quoted hex: `armory_panel.gd`/`armory_style.gd`/`station.gd` **0**,
  the four wave suites **0** (the one hit in `test_s20_chrome_unify.gd` is its own
  `"Color(\"#"` needle), `build_theme.gd` 24. All nine palette roles equal
  `Tokens/armory_*`; a `.tres` at the shipped `armory_style_user.tres` path is picked by
  `load_style()` with no argument, the pane applies it, and the probe removed it again
  (tree clean).
- **AC4 pass** — `OVER CAP` label **4.855:1** on `armory_chip_danger_bg` on both the bay
  chip and the pack card (WCAG 2.x computed in the probe); L227's 4.04:1 cured. F4 notes
  the resting sibling.
- **AC5 pass** — inspector height **154.0** and reserved minimum **154.0** at all six
  emitted states (empty, 1, 2 and 4-line bodies plus a wrapped title); `ModuleHost` global
  rect `(400,152)+1496×710` identical in every state; pins title 21.0 / body 45.0 equal the
  labels' own shaped minima; clearing the pins reproduces the S18 collapse (inspector
  130, host `(400,162)+1496×714`) — the fix is real, not a no-op.
- **AC6 pass (F5 noted)** — at the pinned 1392×610 host every A3 number re-measured
  exact: console `(16,68)+1360×516` (`block_size` equal), band `(16,38)+1328×192` with
  five `260×192` bays on a 7 gap, cells `117×52` at `(10,34)` on a 6 gap, ledge
  `(10,150)+240×34`, drums `18×32` on a 20 pitch, wells `648×220` at console-local 286,
  items `320×68` on 8, **0 ink offenders** (no `font_size` override anywhere in the
  pane), caption ratios 5.96/7.47/6.68:1, P5 wording + the four §5.1 tags present, T8's
  ledge untouched.

## Moved rows, as built (old → new)

- `test_d7_armory.gd:325-341`: `plate.texture.resource_path == style.console_path` +
  2× master size + 4× `patch_margin 64` → `plate.texture == null` + master-on-disk +
  `PanelRaised` frame at 32 px. **Listed** (brief §3 `325-327`).
- `test_d7_armory.gd:741`: `probe.console_path = …` retired with the field. **Listed**.
- `test_d7_armory.gd:798-807`: `style.console_path == "…/ui_armory_console.png"` +
  `exists(style.console_path)` → `style.get(&"console_path") == null` +
  `exists("…/ui_armory_console.png")`. **Listed**.
- `test_s15_armory_layout.gd:212-224`: `plate.texture == console_path` + `patch 64` →
  `plate.texture == null` + theme frame at 32 px; master-still-2× row kept. **Listed**
  ("plate rows only"); `CONSOLE_PATH` const kept in use.
- `test_d7_armory.gd:601-608` and `:817-818`: **unlisted** → F1/F2.
- No weakened assertion found: the only dropped assert (master covers its rect at 1:1)
  lost its subject with the pane, and the master's 2× size is still pinned in
  `test_s15_armory_layout.gd`. Per-suite row counts: baseline 887 → 895, the delta
  exactly the new suite's 7 + `test_s11_inspector.gd` 18 → 19; no suite lost a row
  (per-file `func test_` diff against the `s20_start` tree).

## Verified, not findings

- Theme regeneration is the builder's: 9 `Tokens/armory_*` + the 3 recovered
  `rarity_*`; `vajb_theme.tres` differs only by those keys plus one reserialisation of
  `rarity_rare` at identical 8-bit value (`test_s3_auction` 11/11 green).
- `ArmoryStyle` adds no `_init` shadow (`CockpitStyle` has none); the override path,
  the seams and the `&` "§17 transactions" are untouched (no diff outside the wave's
  files; `test_s18` 9/9, `test_s10_armory_input` 6/6, `test_p2b1_outfitting_panel` 13/13).
- **L224 stays open, half-cured:** this wave was the next `armory_style.gd` owner and
  fixed one of the two stale "2720×1072" mentions; `armory_style.gd:70` still reads it
  (the master is 2720×1032), so the row is not retired.
- Visual: live-station crop (`/tmp/s20_r1_live_s.jpg`) shows the framed bays, slot-chrome
  cells, plated `BUY`/`X`, ember `▲ OVER CAP` chip and the framed pack cards on the
  host's own frame.

## Gate

`[SUMMARY] passed=895 failed=0` twice on fresh scratch stores (`XDG_DATA_HOME=$(mktemp
-d)`, exit 0, identical counts, zero `[FAIL]`/`[SKIP]`), 76 → 77 suites, every suite's
`[PASS]` count equal to its own `func test_` count. One script error, in an untouched
suite: `test_weapon_fx_f4.gd:178` calls `_hide_beam` on a rig its own `_clear()` freed,
so that method's last assertion is dead under a printed `[PASS]` (deterministic on both
runs; the S18-F1/L230 class) → **L237**.

## Verified fixes

n/a — no fixer pass has run.
