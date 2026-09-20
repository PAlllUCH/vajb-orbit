# Fix Wave 1 — W8 re-review report (2026-09-18)

Reviewer: W8 (re-review after the W7 fix cycle). Inputs: `.agents/gen/fix_wave1_review_report.md`
(W6 issues W6-1 … W6-6) and `.agents/gen/fix_wave1_w7_report.md`. Rulings: owner scope ruling relayed
with the wave brief, `docs/design/IMPLEMENTATION_PLAN.md` §9.8 items 1–5.

**Method: every claim below was re-measured or re-read from the shipped files; no worker-report number
is reused without an independent measurement.** Instruments: one throwaway headless probe
(`res://tools/_review2_probe.gd`, output kept at `.agents/gen/fix_wave1_review2_probe.txt`, probe and
its scratch deleted afterwards), two generator runs, one headless test-suite run, a Python read of the
`.ctex` headers, and file reads. Engine:
`C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe`, `--headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"`.
No source file was edited by this review; no inline fix was applied.

**Verdict: all six issues are fixed as ruled. No regression found in any of the eight checklist areas.**
Five residual/new findings remain, none blocking: one MEDIUM (W6-5's *visible* defect survives the flag
change because nothing samples the mip chain) and four LOW (a non-halting display guard, a stale
contract-table row, a duplicated hostility literal, and the still-visible retired cue on the station).

---

## 1. Issue-by-issue verification

### W6-1 — menu focus rectangle — **FIXED**

| Claim | Independent measurement |
|---|---|
| `MenuButtonPlate/focus` is empty | Probe A, effective runtime theme (`Router.live_theme()`): `MenuButtonPlate/focus = StyleBoxEmpty min=(0.0, 0.0)` |
| The engine still asks for it (so the empty box is what stops the draw) | Mounted `main_menu.tscn`, `%PlayButton/Button` (variation `MenuButtonPlate`) after `grab_focus()`: `has_focus=true has_focus(true)=true`, `focus_box=StyleBoxEmpty min=(0.0, 0.0)`, `has_theme_stylebox_override("focus")=false` |
| Base `Button`, `MenuButton`, `StationButton` keep the ring | Probe A: `Button/focus`, `MenuButton/focus`, `StationButton/focus` = `StyleBoxFlat border=1 colour=(0.9098, 0.3843, 0.1647, 1.0) draw_center=false`; a plain `Button` in a live tree resolves the same box; the focused station rail entry (variation `StationButton`, 23 such nodes in `station.tscn`) resolves the same box |
| List cursors / tab bar are untouched | `TabContainer/tab_focus`, `ItemList/cursor`, `Tree/cursor` unchanged (same red box); `LineEdit/focus` unchanged (`metal_light`) |
| No node overrides the box | `theme_override_styles|StyleBoxEmpty` outside `addons/`: only the theme itself (`vajb_theme.tres` `StyleBoxEmpty_4e6di`, referenced once, by `MenuButtonPlate/styles/focus`) and the generator |
| Plate still renders its four states | `theme.get_stylebox_list("MenuButtonPlate") = [disabled, focus, hover, hover_pressed, normal, pressed]` |
| No layout delta | Plate `Button` rect `(350, 70)` = its root Control's rect and min size `(350, 70)`; the Box is a full-rect child of a Control whose size comes from `custom_minimum_size` in `menu_button.tscn`, so a `(0,0)` focus box cannot move it |
| The menu still cues focus | Ticks after `_focus_verb(VERB_PLAY)`: `1.0 / 0.0 / 0.0` |
| `menu_button.gd` is clean | `FOCUS_BORDER` appears nowhere in the project; `_set_focused`/`_focused` absent; `draw_rect` only in the hover/idle branch (`menu_button.gd:82,84`) |

Theme-delta proof (structural, independent of the worker's hashes): the pre-W7 artifact recorded by W6
was 25 708 B; the shipped file is 25 771 B, Δ = **+63**, and the two edits predict exactly 63 bytes
(`[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_4e6di"]\n\n` = 62 B, plus
`StyleBoxFlat_06e4h` → `StyleBoxEmpty_4e6di` = +1 B in the reference line). Every other focus item sits
at the value W6 recorded.

### W6-2 — backdrop drift slack, one owner — **FIXED**

- `main_menu.tscn:46-47` `offset_right`/`offset_bottom` = `96.0`; `_reserve_drift_slack()` and its
  `_ready()` call are gone (`main_menu.gd` has `DRIFT_DISTANCE 96.0`, `DRIFT_SECONDS 20.0`, and no
  offset write anywhere; a project-wide grep for `offset_right|offset_bottom` in `ui/**/*.gd` shows
  only unrelated HUD/launch-panel code).
- Runtime, mounted menu: `Backdrop size=(2016.0, 1176.0)`, `offset_right=95.99 offset_bottom=95.99`
  against a 1920×1080 viewport, i.e. viewport + 96 px per axis, with the two-leg position tween running
  (pos −0.013 at sample time). No code can override it.
- Spec corrections are present in the files: `MAIN_MENU_V2.md` §6.1 (2016 × 1176), §12
  (`DRIFT_DISTANCE = 96` / `DRIFT_SECONDS = 20`), §16 item 2 (names the scene as single owner and
  records the deletion), `MAIN_MENU_SPEC.md:74`, `ENVIRONMENT_SPEC.md:37`,
  `IMPLEMENTATION_PLAN.md:312` and §9.8 item 3 — all read "96 px / 20 s", and no stale `1944` /
  "24 px of drift slack" figure survives anywhere under `docs/`.

### W6-3 — REFINERY action heights, scene-owned — **FIXED**

- `refinery_panel.tscn:189,196,203` = `Vector2(0, 88)` for all three; `ACTION_MIN_HEIGHT` and
  `_fit_action_buttons()` occur nowhere in the project (only in `.agents/gen/*_report.md`).
- Measured on a standalone mount: `RefineButton`, `RefineAllButton`, `CancelButton` =
  `size (360.0, 88.0)`, `min (0.0, 88.0)`, parent `VBoxContainer`, `has_theme_stylebox_override("focus")=false`
  on all three. No code path can change them.
- The class comment (`refinery_panel.gd:49-56`) now states the heights are scene values and cites W6-3,
  so the file no longer contradicts itself; `STATION_HUB.md` §5.7 (line 500) and
  `IMPLEMENTATION_PLAN.md` §9.8 item 3 read 88 px.

### W6-4 — threat tint follows the data — **FIXED**

`hud.gd`: the unconditional alert left `_refresh_static_tints()` (now genuinely static:
`_hull_icon`, `_shield_icon`, `_cargo_toggle`, both zoom buttons, `_cargo_close`) and became
`_apply_threat_tint()` (`:480-484`), called from `_apply_target_info()` (`:462`) before its early
return. Measured on a mounted HUD:

```
HOSTILE  text='HOSTILE' override=true  colour=(0.7843, 0.2784, 0.1216, 1.0)  panel_visible=true
NEUTRAL  text='NEUTRAL' override=false colour=(0.4196, 0.4549, 0.5176, 1.0)
cleared  override=false colour=(0.4196, 0.4549, 0.5176, 1.0) panel_visible=false
```

Producer/consumer agreement checked (the conditional tint depends on the caller's string):
`game/game.gd:66` `TARGET_THREAT := "HOSTILE"` == `ui/hud/hud.gd:57` `THREAT_HOSTILE := "HOSTILE"`.

### W6-5 — mipmaps on the mock target — **FIXED AS RULED, defect still visible (see N-1)**

- `assets/ships/ship_interceptor_side.png.import:26` `mipmaps/generate=true`. Of the 92 ship
  `.import` files, this is the **only** one set to true (the other 91 read false, including
  `ship_vanguard_side.png`, the `Player` cut).
- The import actually ran and produced a mip chain: `.godot/imported/ship_interceptor_side.png-7a6f7c6f….ctex`
  header `GST2 v1 940x107 fmt=0x0D800000`, format bit `0x00800000` set (`True`). Instrument validated
  against two controls whose state is independently known: `icon_zoom_plus_96.png-…` = `0x0C800000`
  (bit set, the `_96` band is mipmap-on per ICONS_SPEC §9.8) and `icon_zoom_plus_48.png-…` =
  `0x0D000000` (bit clear). `ship_vanguard_side.png-6fdecd49….ctex` = `0x0D000000` (clear).
- The `.md5` sidecar is in sync with both sides (`source_md5=7fb7dbc3c6cb0f8ceb0db452f5ce533a` = MD5 of
  the PNG, `dest_md5=dd2f6b831a0838b7a9b02b8212f519b9` = MD5 of the `.ctex`), and the `.ctex` name is
  still `md5(res://assets/ships/ship_interceptor_side.png)`, so the reimport rewrote the same
  `dest_files` entry. Nothing is pending.
- W6's note that `Texture2D.has_mipmaps()` is not a usable instrument is reproduced: it returns
  `false` for all four textures tested, including the known-mipmapped `icon_zoom_plus_96.png`.

### W6-6 — Oxanium display role — **FIXED AS RULED (guard is weak, see N-2/N-3)**

- Premise reproduced: the bare `FontFile` `res://assets/fonts/Oxanium[wght].ttf` reports
  `name='Oxanium ExtraLight'`, `style='ExtraLight'`, `weight=200`,
  `supported_variations={ &"wght": (200, 800, 200) }` — the variable font's default instance is the
  hairline face.
- Shipped theme: all six display variations resolve to `FontVariation over res://assets/fonts/Oxanium[wght].ttf
  { &"wght": 700 }` (`ScreenTitle`, `HeroTitle`, `StationPanelTitle`, `DialogTitle`, `HudReadout`,
  `MenuButtonPlate`); `default_font` = Rajdhani-Regular; `StationValue` = Rajdhani-SemiBold;
  `SectionHeader`/`StationCaption` = Rajdhani-Medium; `Version`/`FlavourText` = SairaStencilOne. No
  variation resolves to an unvaried Oxanium.
- Guard present at `tools/build_theme.gd:210-214` inside `_register_fonts()`, applied to every
  `FONT_ROLES` entry whose role is `DISPLAY_ROLE` (the six above), naming the variation and the
  offending face on failure.

---

## 2. Regression checks (the brief's eight areas + house rules)

| Check | Result | Evidence |
|---|---|---|
| Theme determinism | **pass** | Two consecutive `--script res://tools/build_theme.gd` runs (exit 0) both produce `sha256 7CC0AA02260E9FAE9294D39F86F8E3CD4C1100AAB43AC7C63140E12B34A8A9BD`, 25 771 B — byte-identical to the shipped file, whose hash was taken before the runs. Log: `.agents/gen/fix_wave1_review2_theme_run.txt`. (The review's runs moved the file's mtime; its bytes are unchanged.) |
| `MenuButtonPlate` empty, `Button`/`StationButton` keep their boxes | **pass** | §1 W6-1 (probe A + mounted menu plate + focused rail entry) |
| Scene-owned button heights | **pass** | §1 W6-3 (3 × 360×88, no code path, no overrides) |
| Single-owner drift slack | **pass** | §1 W6-2 (scene 96, no mirror, 2016×1176 at runtime) |
| Conditional threat tint | **pass** | §1 W6-4 (HOSTILE red / NEUTRAL none / cleared none) |
| Mipmaps flag | **pass (with N-1)** | §1 W6-5 (`.import` true, `.ctex` bit set, reimport complete) |
| Oxanium display-role guard | **pass (with N-2/N-3)** | §1 W6-6 (guard present, premise and effect verified) |
| No new hex literals | **pass** | `#[0-9a-fA-F]{3,8}` over `ui/**/*.gd` → no match; over `game/**/*.gd` → only the two pre-existing P1 catalogues (`game/mineral_catalog.gd:265-268`, `game/component_catalog.gd:193-195`), both untouched by this wave (mtimes 11:17/11:31 vs the wave's 15:02–15:11). `tools/build_theme.gd` remains the only wave file with hex, as its contract requires. |
| No per-node font sizes | **pass** | `theme_override_font_sizes` / `add_theme_font_size_override` across `.gd` + `.tscn` occur only under `addons/godot_ai/`. |
| `tools/` holds only the two generators | **pass** | `build_theme.gd` (+`.uid`), `derive_icon_tints.gd` (+`.uid`); the review probe and its scratch were deleted (`glob **/_review2*` → none). |
| Router ↔ theme font-size table | **pass** | Probe H: theme 28 items, `Router.FONT_SIZE_ITEMS` 28, `missing_in_router=[]`, `extra_in_router=[]` (FlavourText is in both). |
| Test suite | **pass** | Independent run of `res://tests/headless_runner.tscn` → `[SUMMARY] passed=53 failed=0`, exit 0, no `SCRIPT ERROR` (`.agents/gen/fix_wave1_review2_tests.txt`). |
| Changed scripts parse and run | **pass** | The probe loaded and instantiated `main_menu.tscn`, `station.tscn`, `refinery_panel.tscn` and `hud.tscn` in one live tree with no parse/resource/node errors; `build_theme.gd` exits 0 twice. |
| Scope | **pass** | mtime sweep of `vajb-orbit/**` (excluding `addons/`, `.godot/`) shows wave-window writes only on the eleven declared files plus `ui/theme/vajb_theme.tres` (regenerated by the generator runs above). `project.godot`, `addons/`, and all other assets are untouched. |
| Docs follow the code (lead rule) | **pass, one stale table (N-4)** | Drift/slack, focus scope, button heights and typography amendments are in the specs (§9.8 items 1–3, MAIN_MENU_V2 §16, STATION_HUB §5.7). `IMPLEMENTATION_PLAN.md:99` still contradicts the shipped theme. |

---

## 3. New / residual issues

| ID | Severity | Files | Problem and evidence | Suggested action |
|---|---|---|---|---|
| **N-1** | **MEDIUM** | `game/game.tscn:45-51` (`Player`, `TargetBody`), `project.godot` | **W6-5's visible defect survives the flag change.** The mip chain now exists (§1 W6-5) but nothing samples it: `project.godot` sets no `rendering/textures/canvas_textures/default_texture_filter` (engine default Linear) and neither sprite sets `texture_filter`. Both cuts are still minified ~15× (`scale = Vector2(0.0663, 0.0663)`; interceptor 940×107 drawn 62.3×7.1 px), so the linear-minification aliasing/shimmer W6-5 described is unchanged. | Land one of the two: `texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` on `Player` and `TargetBody`, or the project-wide canvas filter (`docs/gameplay/17_coder_handoff.md:68-70` carries it as an open item). Follow-up: `ship_vanguard_side.png` (the `Player` cut) still has `mipmaps/generate=false` and the same 15× minification — W6-5 named the Player as affected, this wave fixed the interceptor only. |
| **N-2** | LOW | `tools/build_theme.gd:214` | **The display guard cannot fail a build.** It is an `assert`, stripped from export templates and non-halting in a headless run — reproduced independently: a probe `assert(font is FontVariation, …)` with a Rajdhani `FontFile` printed `SCRIPT ERROR: Assertion failed …` and execution continued (`I reached code after the failing assert`), i.e. a broken build still reaches `ResourceSaver.save` and writes a hairline theme. | Upgrade to `printerr(...)` + `return` before `ResourceSaver.save` (W7's own open point 3, one line). |
| **N-3** | LOW | `tools/build_theme.gd:210-214` | **The guard checks the type, not the face.** Any `FontVariation` passes, including one over Rajdhani with no `variation_opentype` (hairline-free but wrong family) or one pinned to a different `wght`. | Assert the resolved `base_font` is the Oxanium face and `variation_opentype` carries `wght == TITLE_WEIGHT`. |
| **N-4** | LOW | `docs/design/IMPLEMENTATION_PLAN.md:99`, `docs/design/UI_SPEC.md:48,59` | **Stale contract text.** The frozen §3.2 table still reads `` `MenuButtonPlate` … focus = 1 px `accent_danger_bright` `StyleBoxFlat` `` and UI_SPEC §2.1/§2.2 still say every interactive Control draws the shared `focus` stylebox. Both are now false for `MenuButtonPlate`; the exception is recorded only in §9.8 item 1 and `MAIN_MENU_V2.md` §16. A worker reading §3.2 as the contract would re-add the ring. | Amend §3.2 line 99 and UI_SPEC §2.1/§2.2 to name the `MenuButtonPlate` exception and point at §9.8 item 1. |
| **N-5** | LOW | `game/game.gd:66`, `ui/hud/hud.gd:57` | **The hostility string has two owners.** The tint is now conditional, so the coupling is live: the producer (`TARGET_THREAT`) and the consumer (`THREAT_HOSTILE`) are independent literals that happen to agree (`"HOSTILE"`). A producer-side change silently disables the red threat read-out with no error. | Share one constant (e.g. move it next to the HUD API the game already calls, or have `game.gd` use `Hud.THREAT_HOSTILE`). |
| **N-6** | INFO | `ui/theme/vajb_theme.tres` | The theme carries two byte-identical red focus sub-resources (`StyleBoxFlat_2f3rr` for base/`Button`/list cursors/`tab_focus`, `StyleBoxFlat_06e4h` for the plate variations). Pre-existing, harmless duplication from the two generator paths, not a W7 regression. | Optional dedupe in `build_theme.gd`. |
| **N-7** | INFO / owner scope | `IMPLEMENTATION_PLAN.md:393` | The retired cue is still on screen outside the menu: the station rail (23 `StationButton` nodes) and the dialogs draw the same 1 px `accent_danger_bright` rectangle §9.8 item 1's heading calls retired ("no red rectangle is ever drawn for focus, on any screen"). The shipped state matches the *scope* sentence in the same item ("covers the `MenuButtonPlate` variation only"), so this is a wording/UX coherence question, not a code defect. | If the owner's finding was global, the §9.8 item-1 heading should be narrowed to the menu in the same pass that documents the rail's affordance; otherwise leave as ruled. |

---

## 4. Verification gaps (limits of this review)

1. **No pixel capture.** Every run was headless (no rasteriser), so the focus finding rests on the
   effective theme item, the `has_focus(true)` state, the absence of node overrides and the engine's
   documented `Button::_notification(NOTIFICATION_DRAW)` path — not on a rendered frame. A graphical
   run plus `editor_screenshot(source="game")` would close it if the owner wants the pixel.
2. **The mip chain is not sampled *visually* here** either; N-1 is argued from the absence of a
   sampler (`texture_filter`) and from `game.tscn`/`project.godot` reads, plus the measured 15×
   minification factors.
3. **No VCS.** The pre-W7 theme bytes (25 708 B) exist only as W6's recorded number and hash; the
   +63 B delta was verified arithmetically against the two textual edits, not by diffing the two
   artifacts.
4. **The station rail's keyboard affordance was not exercised by input.** The rail entry's focus box
   was read from the effective theme after `grab_focus()`, not by walking focus with key events.
5. `--check-only --script` remains unusable for autoload-referencing scripts (documented
   limitation); the substitute gates were the live-tree scene mounts and the 53-test suite.

---

## 5. Evidence left on disk, and integrity

- `.agents/gen/fix_wave1_review2_probe.txt` — the probe's full output (sections A–I: theme items, menu,
  station, refinery, HUD, fonts, `.ctex`/texture facts, router coverage, assert semantics).
- `.agents/gen/fix_wave1_review2_theme_run.txt` — full generator report of the determinism run.
- `.agents/gen/fix_wave1_review2_tests.txt` — the 53-test suite output.
- `tools/` = `build_theme.gd` (+`.uid`), `derive_icon_tints.gd` (+`.uid`); the probe `.gd` was deleted
  and no `_review2*` file remains anywhere in the workspace. Scratch (theme baseline copy, second
  probe log, second generator log) was deleted after use.
- No source, scene, asset, theme or document was edited by this review. The only file this review
  rewrote is `ui/theme/vajb_theme.tres`, by running the generator twice; the output is byte-identical
  to the file that was on disk, so the artifact is unchanged apart from its mtime.
