# Fix Wave 1 — W7 fix cycle report (2026-09-18)

Author: W7 (fix cycle after the W6 review). Inputs: `.agents/gen/fix_wave1_review_report.md`
(issues W6-1 … W6-6), the owner's scope rulings relayed with this brief, `AGENTS.md`,
`docs/design/IMPLEMENTATION_PLAN.md` §9.8. Scope: fix all six issues, keep the diff minimal,
disturb nothing the review passed.

Method: every fix was re-measured on the shipped files after the edit, not asserted. One
throwaway probe (`res://tools/_probe_w7.gd` + `.uid`) was written, run and deleted; `tools/`
now holds `build_theme.gd` and `derive_icon_tints.gd` (+ their `.uid`) only. Engine:
`C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe`, `--headless --path
"G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"`. No editor was launched and no graphical game
was run; the editor that was already open (session `vajb-orbit@b6e49ec4e2c3dce2`, pid 20228)
picked up the one asset-import change on its own, see §6.

---

## 1. Rulings applied

| Issue | Ruling | Fix |
|---|---|---|
| W6-1 (HIGH) | Empty the focus stylebox for the **`MenuButtonPlate` variation only**; the base `Button` and `StationButton` boxes stay (station rail and dialogs depend on them) | `tools/build_theme.gd`: new `FOCUSLESS_PLATE_VARIATIONS` list registers a `StyleBoxEmpty` as that variation's `focus`; theme regenerated |
| W6-2 | Scene is the one owner of the drift slack; stale spec values corrected | `main_menu.tscn` `offset_right/bottom` 24 → **96**; `_reserve_drift_slack()` + its `_ready()` call deleted; the drift/slack figures in four documents corrected |
| W6-3 | Scene owns all three action heights | `refinery_panel.tscn` secondary plates 56 → **88**; `ACTION_MIN_HEIGHT` + `_fit_action_buttons()` (and its call) deleted; comments rewritten |
| W6-4 | Threat colour follows the data, not the panel | `hud.gd`: the static tint line is gone; `_apply_threat_tint()` colours the label from `THREAT_HOSTILE` inside `_apply_target_info()` |
| W6-5 | Mipmaps in the `.import` for `ship_interceptor_side`, editor reimport reported | `mipmaps/generate=false` → `true` (reimport state in §6) |
| W6-6 | Defensive guard on the display role | `build_theme.gd`: `assert(font is FontVariation)` for every `FONT_ROLES` entry whose role is `DISPLAY_ROLE` |

No hex literal was added outside `tools/build_theme.gd`; no per-node font-size override was
introduced; `project.godot`, `addons/godot_ai/` and `assets/` (other than the one `.import`
file) are untouched.

---

## 2. W6-1 — the focus rectangle is gone, plates only

`tools/build_theme.gd` now carries the ruling as data rather than as a special case buried in
a loop:

```gdscript
const FOCUSLESS_PLATE_VARIATIONS: Array[StringName] = [&"MenuButtonPlate"]
...
	var no_focus: StyleBoxEmpty = StyleBoxEmpty.new()
	for variation: StringName in PLATE_VARIATIONS:
		for name: StringName in boxes:
			theme.set_stylebox(name, variation, boxes[name])
		if FOCUSLESS_PLATE_VARIATIONS.has(variation):
			theme.set_stylebox(&"focus", variation, no_focus)
```

`_report()` gained a `FOCUS_PROBE` block (plus a `_box_label()` helper) so every build prints
what each family draws. Generator output, run 1 and run 2 (identical):

```
[build_theme] focus Button/focus = StyleBoxFlat border=1 colour=(0.9098, 0.3843, 0.1647, 1.0) draw_center=false
[build_theme] focus MenuButton/focus = StyleBoxFlat border=1 colour=(0.9098, 0.3843, 0.1647, 1.0) draw_center=false
[build_theme] focus MenuButtonPlate/focus = StyleBoxEmpty
[build_theme] focus StationButton/focus = StyleBoxFlat border=1 colour=(0.9098, 0.3843, 0.1647, 1.0) draw_center=false
[build_theme] focus TabContainer/tab_focus = StyleBoxFlat border=1 colour=(0.9098, 0.3843, 0.1647, 1.0) draw_center=false
```

Probe B, on the effective runtime theme chain of the mounted screen (the exact test W6 used,
now passing):

```
plate=Button variation=MenuButtonPlate has_focus=true has_focus(true)=true override=false focus_box=StyleBoxEmpty focus_min=(0.0, 0.0)
```

`has_focus(true)` is still `true` (so Godot's `Button::_notification(NOTIFICATION_DRAW)`
branch runs), there is no node override, and the stylebox it asks for has zero minimum size
and no paint. Blast radius measured, not assumed: `theme_type_variation = &"MenuButtonPlate"`
appears in exactly one place in the project, `ui/components/menu_button.tscn:36`, and that
component is instanced in exactly one screen, `ui/screens/main_menu.tscn` (the three verbs).
The dialogs and the station rail use the base `Button` / `StationButton`, whose boxes are
unchanged, as ruled. `ItemList/cursor`, `Tree/cursor` and `TabContainer/tab_focus` still take
the 1 px box (they are list cursors, not button focus rings).

**Theme delta proof.** Toggling the ruling off (`FOCUSLESS_PLATE_VARIATIONS = []`) and
re-running the generator reproduces the pre-W7 artifact byte for byte:
`sha256 B92C03A5AB96573361BBE573A7A1E67AFE505CB5BA13AD28BD5CE14C287ADE59`, 25 708 bytes,
i.e. exactly the file W5 shipped (the hash W6 measured). With the ruling on the file is
25 771 bytes, `sha256 7CC0AA02260E9FAE9294D39F86F8E3CD4C1100AAB43AC7C63140E12B34A8A9BD`
(+63 bytes: one new `[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_4e6di"]` block, plus
the `MenuButtonPlate/styles/focus` reference repointed to it). Nothing else in the theme moved.

**Determinism.** Four consecutive generator runs of the shipped source:
`7CC0AA02…A8A9BD` (run 1), `7CC0AA02…A8A9BD` (run 2), the same hash for the snapshot taken
before the guard experiment and for the run after it, all 25 771 bytes. The shipped `.tres` is
byte-identical to that snapshot.

---

## 3. W6-2 — one owner for the backdrop slack, and the stale numbers

`main_menu.tscn` `Backdrop`: `offset_right` / `offset_bottom` `24.0` → **`96.0`**;
`main_menu.gd` lost `_reserve_drift_slack()` (5 lines + doc comment) and its `_ready()` call.
No other scene or code mirrors the value, so a maintainer who edits the offsets now sees the
effect. Probe B, after two frames of the mounted screen:

```
backdrop offsets right=96.0 bottom=96.0 size=(2016.0, 1176.0)
```

i.e. the scene value survives to layout and the plate is viewport + 96 px per axis, matching
`DRIFT_DISTANCE` (96.0) and covering the edge at the end of the leg.

Stale spec values corrected (all were "24 px / 40 s" written for the pre-W1 drift):

| File | Where | Now |
|---|---|---|
| `MAIN_MENU_V2.md` | §6.1 `Backdrop` plate height, §7 art map, §8 motion table, §12 constants (`DRIFT_DISTANCE = 96`, `DRIFT_SECONDS = 20`), §13 keep-list, §15.1 "unchanged on purpose", §15.2 21:9 row count | 2016 × 1176, (−96, −96) over 20 s, 1176 drawn rows |
| `MAIN_MENU_V2.md` | §16 item 2 | no longer claims `_reserve_drift_slack()` exists; states the scene is the single owner |
| `MAIN_MENU_SPEC.md` | §5 item 1 | 96 px over 20 s |
| `ENVIRONMENT_SPEC.md` | §2 animation support | 96 px / 20 s |
| `IMPLEMENTATION_PLAN.md` | §4.3 controller line | 96 px over 20 s, cross-referenced to §9.8 item 3 |

The wave-1 brief forbade worker edits under `docs/`; this brief explicitly asked for the stale
spec values to be fixed, so the five documents were corrected in place rather than left to a
later orchestrator pass.

---

## 4. W6-3 — the scene owns the three heights

`refinery_panel.tscn`: `RefineAllButton` and `CancelButton` `custom_minimum_size = Vector2(0, 56)`
→ `Vector2(0, 88)`. `refinery_panel.gd` lost `ACTION_MIN_HEIGHT` and `_fit_action_buttons()`
(plus its `_ready()` call); the class comment now records that all three heights are scene
values and names the W6-3 reason, so the file no longer contradicts itself about being "the one
source". Probe C, standalone mount:

```
RefineButton     text='REFINE 1'     size=(360.0, 88.0) min=(0.0, 88.0) global.y=295.0
RefineAllButton  text='REFINERY ALL' size=(360.0, 88.0) min=(0.0, 88.0) global.y=395.0
CancelButton     text='CANCEL'       size=(360.0, 88.0) min=(0.0, 88.0) global.y=495.0
```

Identical width (360 px, the box width) and height (88 px), same axis, 100 px apart, with no
code path setting them. `STATION_HUB.md` §5.7 ("`REFINERY ALL` (56 px), `CANCEL` (56 px)") and
`IMPLEMENTATION_PLAN.md` §9.8 item 3 were corrected to 88 px so the spec and the scene agree
again.

---

## 5. W6-4 — the threat label is coloured by its data

`hud.gd`: the unconditional `_set_text_alert(_target_threat_label, true, TOKEN_DANGER)` left
`_refresh_static_tints()` (which is now genuinely static tints only) and became:

```gdscript
func _apply_threat_tint() -> void:
	if _target_threat_label == null:
		return
	var hostile: bool = _target_info_set and _target_info_threat == THREAT_HOSTILE
	_set_text_alert(_target_threat_label, hostile, TOKEN_DANGER)
```

called from `_apply_target_info()` before its early return, so the hidden panel also drops the
override. New constant `THREAT_HOSTILE := "HOSTILE"`. Probe D:

```
HOSTILE text='HOSTILE' override=true  colour=(0.7843, 0.2784, 0.1216, 1.0)   # accent_danger #c8471f
NEUTRAL text='NEUTRAL' override=false colour=(0.4196, 0.4549, 0.5176, 1.0)   # theme text_primary
cleared override=false panel_visible=false
```

A non-hostile reading (or no reading) now prints the theme colour instead of hostile-red, which
is what W3 item 6 intended and what the review asked for.

---

## 6. W6-5 — mipmaps on `ship_interceptor_side`, and what "pending" turned out to be

`assets/ships/ship_interceptor_side.png.import`: `mipmaps/generate=false` → **`true`**
(the file is 979 bytes, LF endings, all other params untouched).

**The reimport is not pending: it already happened.** The editor that was open on this project
(pid 20228) reimported the changed source at 15:06:12, twelve seconds before its last recorded
heartbeat (`last_seen 2026-09-18T13:06:24Z`). Evidence, all measured:

- `.import`, `.ctex` and `.md5` all carry the same mtime `18.09.2026 15:06:12–13`, and the
  `.md5` sidecar is in sync with the current bytes (`source_md5=7fb7dbc3…533a` = MD5 of the
  PNG, `dest_md5=dd2f6b83…19b9` = MD5 of the `.ctex`).
- The `.ctex` header now carries the mipmap flag. A `Texture2D.has_mipmaps()` call is **not** a
  usable instrument here (it returns `false` for `icon_zoom_plus_96.png` too, which
  `ICONS_SPEC` §9.8 keeps mipmap-on), so the flag was read from the file:

```
ship_interceptor_side.png-7a6f7c6f….ctex  GST2 940x107  format=0x0D800000  has_mipmaps_bit=True   # W6-5 fix
ship_vanguard_side.png-6fdecd49….ctex      GST2 905x387  format=0x0D000000  has_mipmaps_bit=False  # Player, open
icon_zoom_plus_96.png-f351c932….ctex       GST2  96x96   format=0x0C800000  has_mipmaps_bit=True   # control, per ICONS_SPEC
icon_zoom_plus_48.png-89f98bd9….ctex       GST2  48x48   format=0x0D000000  has_mipmaps_bit=False  # control
```

`0x00800000` is `FORMAT_BIT_HAS_MIPMAPS`: the two `_96`/`_48` controls bracket the instrument
(mipmap-on assets set the bit, mipmap-off assets do not), and the interceptor cut now sets it.
The `.ctex` path is `md5(source path text)`, not `md5(settings)`, so the pending-dest-path trap
does not apply: `7a6f7c6fbdf2a5b8d3d1b39a410292dc` = MD5 of
`res://assets/ships/ship_interceptor_side.png` (`.agents/gen/w7_md5.ps1`), i.e. the same
`dest_files` entry, rewritten in place. A `filesystem_manage reimport` would only repeat it.

---

## 7. W6-6 — the display role cannot silently be a hairline face

`build_theme.gd` `_register_fonts()` now guards the role:

```gdscript
		if FONT_ROLES[variation] == DISPLAY_ROLE:
			assert(font is FontVariation, "build_theme: the display role for %s must be a FontVariation over the variable face, got %s" % [String(variation), _font_label(font)])
```

Falsification test (temporarily resolving `display` to the Rajdhani `FontFile`, then reverting):

```
SCRIPT ERROR: Assertion failed: build_theme: the display role for ScreenTitle must be a FontVariation over the variable face, got res://assets/fonts/Rajdhani-Regular.ttf
   at: _register_fonts (res://tools/build_theme.gd:214)
```

The guard fires and names the variation and the offending face. Two honest limits, both worth
knowing before anyone relies on it: `assert` is stripped from export templates, and in a
headless run Godot reports the failure **without halting**, so that run went on to write a
broken theme (`589DBB98…7C3D`). The shipped theme was regenerated afterwards from the restored
generator and is byte-identical to the pre-test snapshot. Changing the assert into a hard
`printerr` + `return` before `ResourceSaver.save` would make the build refuse outright; that is
a one-line upgrade if the owner wants it (see §10).

---

## 8. Files changed

| File | Change | After |
|---|---|---|
| `tools/build_theme.gd` | W6-1 (`FOCUSLESS_PLATE_VARIATIONS`, empty-box registration, `FOCUS_PROBE` report, `_box_label`), W6-6 (`DISPLAY_ROLE` guard) | 23 761 B, 566 lines |
| `ui/theme/vajb_theme.tres` | regenerated by the generator (never hand-edited) | 25 771 B, 573 lines, `7CC0AA02…A8A9BD` (was 25 708 B, `B92C03A5…ADE59`) |
| `ui/screens/main_menu.gd` | `_reserve_drift_slack()` and its call deleted | 13 130 B, 358 lines |
| `ui/screens/main_menu.tscn` | backdrop slack 24 → 96 | 8 109 B, 276 lines |
| `ui/station/refinery_panel.tscn` | two secondary action heights 56 → 88 | 6 715 B, 211 lines |
| `ui/station/refinery_panel.gd` | `ACTION_MIN_HEIGHT` + `_fit_action_buttons()` deleted, comment corrected | 24 517 B, 714 lines |
| `ui/hud/hud.gd` | `THREAT_HOSTILE`, `_apply_threat_tint()`, static tint line removed | 18 978 B, 567 lines |
| `assets/ships/ship_interceptor_side.png.import` | `mipmaps/generate` false → true | 979 B |
| `docs/design/MAIN_MENU_V2.md`, `MAIN_MENU_SPEC.md`, `ENVIRONMENT_SPEC.md`, `IMPLEMENTATION_PLAN.md` (§4.3, §9.8 items 1 and 3), `STATION_HUB.md` (§5.7) | stale drift/slack/focus/button values corrected | — |

This workspace has no VCS, so "before" sizes exist only where they were measured: the theme
(25 708 → 25 771 B) and the `.import` (`false` → `true`, one byte shorter). Everything else is
the after-state; each edit is described by the exact old → new text above.

## 9. Verification runs

| Check | Result |
|---|---|
| Theme determinism | 4 shipped-source runs, identical `sha256 7CC0AA02…A8A9BD`, 25 771 B; the ruling-off run reproduces the pre-W7 artifact exactly |
| Probe (deleted) | `tools/_probe_w7.gd` → `.agents/gen/w7_probe.txt`: sections A (theme focus items), E (ship imports), B (menu plate + backdrop), C (refinery buttons), D (threat tint) |
| Test suite | `res://tests/headless_runner.tscn` → `[SUMMARY] passed=53 failed=0`, exit 0, no `SCRIPT ERROR` (`.agents/gen/w7_tests.txt`) |
| Scene boots | `main_menu.tscn`, `station.tscn`, `game.tscn` with `--quit-after 90` → exit 0, no parse/resource/node errors; the menu and station teardown notice (4 leaked ObjectDB instances, 2 resources in use) is the pre-existing `AudioManager` stream retention W1/W6 already attributed (`.agents/gen/w7_boot_*.txt`) |
| `--check-only --script` | `build_theme.gd` exit 0. `main_menu.gd`, `refinery_panel.gd`, `hud.gd` exit 1 with `Identifier not found: AudioManager / SettingsManager`; reproduced identically on the untouched `ui/station/shipyard_panel.gd`, so it is the command's limitation (autoloads are not registered in that mode), not a file fault. Substitute gate: the probe `load()`ed and instantiated all three scenes inside a live tree, and the suite ran clean |
| `tools/` clean | `build_theme.gd`, `build_theme.gd.uid`, `derive_icon_tints.gd`, `derive_icon_tints.gd.uid`; no `_probe_w*` file anywhere in the project |
| Theme report counts | 12 tokens, 19 variations, 45 sub-resources, 15 base stylebox items, 28 font-size items (23 per type + RichTextLabel's 5), `default_font = res://assets/fonts/Rajdhani-Regular.ttf` |

## 10. Open points for the owner

1. **The new mip chain is generated but not yet sampled (W6-5 residual).** Mipmaps only change
   the image when the sampler asks for them, and `project.godot` sets no
   `rendering/textures/canvas_textures/default_texture_filter` (engine default: Linear), while
   neither `Player` nor `TargetBody` sets `texture_filter`. The shimmer W6 measured therefore
   persists until one of the two lands: `texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`
   on the two sprites (`game.tscn`, outside this brief's file scope), or the project-wide
   filter that `docs/gameplay/17_coder_handoff.md:68-70` already carries as an open item
   ("the project canvas texture filter is the default Linear, not Linear Mipmap, so the mips
   are generated but not sampled until that setting lands").
2. **`ship_vanguard_side.png` (the `Player` cut) still has `mipmaps/generate=false`** and the
   same 15× minification. It was outside the W6-5 instruction; it is the other half of the
   family-wide gap.
3. **The W6-6 guard is a debug-only, non-halting check.** If a hairline display face must never
   ship, upgrade it to `printerr` + `return` ahead of `ResourceSaver.save` (one line).
4. **The station rail keeps its 1 px focus box, as ruled.** That box is the rail's only keyboard
   focus affordance; it is the colour the main menu no longer draws, so the retired cue is still
   visible on the station and in the dialogs.

---

## 11. Evidence left on disk

`.agents/gen/`: `w7_theme_run1..4.txt` (the generator's full build report, one file per run), `w7_theme_focusless_empty.txt` (the ruling-off run that reproduces the pre-W7
hash), `w7_assert_test.txt` (the guard firing), `w7_probe.txt` (the deleted probe's output),
`w7_tests.txt` (the 53-test suite), `w7_boot_menu.txt` / `w7_boot_station.txt` /
`w7_boot_game.txt`, `w7_ctex_mips.py` (the `.ctex` header reader) and `w7_md5.ps1` (the
`.ctex` name derivation). Scratch files written outside the project were deleted; the probe
and its `.uid` are gone, so `tools/` holds `build_theme.gd` and `derive_icon_tints.gd` only.
