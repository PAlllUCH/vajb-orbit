# Fix Wave 1 — W6 review report (2026-09-18)

Reviewer: W6. Brief: `.agents/gen/fix_wave1_task.md` §W6. Rulings: `docs/design/IMPLEMENTATION_PLAN.md`
§9.8 items 1–5. Reports reviewed: `.agents/gen/fix_wave1_w1_report.md` … `fix_wave1_w5_report.md`.

Method: **every claim below was re-measured or re-read from the shipped files, not taken from the
worker reports.** Three throwaway probes were written, run and deleted (`res://tools/_probe_w6.gd`,
`_probe_w6b.gd`, `_probe_w6c.gd` + their `.uid`); `tools/` now holds only `build_theme.gd` and
`derive_icon_tints.gd` (+ `.uid`). No source file was edited by this review. Engine:
`C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe`, `--headless --path
"G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"`, `--fixed-fps 60` for frame-accurate runs.

**Verdict: the wave is functionally complete except for one high-severity miss — the focus ring is
still drawn, now by the theme instead of by `menu_button.gd`.** One fix cycle is required; the other
six findings are low severity (consistency, latent traps, one aliasing risk).

---

## 1. Issue list

### W6-1 — HIGH — the focus ring is not gone: the theme draws it

| Field | Value |
|---|---|
| Files | `vajb-orbit/ui/theme/vajb_theme.tres` (generated), `vajb-orbit/tools/build_theme.gd` (`_focus_box()` :417, `_register_wiring()` :228, `_register_plate_variations()` :316, `_make_boxes()` :389) |
| Area | IMPLEMENTATION_PLAN §9.8 item 1 — "no red rectangle is ever drawn for focus, on any screen" |
| Problem | W1 removed the ring from `menu_button.gd`, but `Button`-derived controls still draw a 1 px `accent_danger_bright` (`#e8622a`) rectangle on focus — Godot's own `Button::_notification(NOTIFICATION_DRAW)` draws the theme's `focus` stylebox, and this theme defines that stylebox to be exactly the retired ring. The visible result at the owner's finding is unchanged. |

Evidence (measured, probe A, all on the effective runtime theme chain):

```
main menu PLAY plate (after _focus_verb) [MenuButtonPlate]: has_focus=true has_focus(true)=true
    focus_box=StyleBoxFlat border=1 colour=(0.9098, 0.3843, 0.1647, 1.0) draw_center=false
station rail (after grab_focus)          [StationButton]:    has_focus=true has_focus(true)=true
    focus_box=StyleBoxFlat border=1 colour=(0.9098, 0.3843, 0.1647, 1.0) draw_center=false
theme: Button/focus        = flat border=1 colour=(0.9098, 0.3843, 0.1647, 1.0) draw_center=false
theme: MenuButtonPlate/focus = flat border=1 colour=(0.9098, 0.3843, 0.1647, 1.0) draw_center=false
```

`0.9098, 0.3843, 0.1647` = `#e8622a` = `Tokens/accent_danger_bright`, the exact colour and width of the
retired `FOCUS_BORDER`. In `vajb_theme.tres` the same box (`StyleBoxFlat_2f3rr`) is registered for
`Button/styles/focus` (:383), `MenuButton/styles/focus` (:432), `MenuButtonPlate/styles/focus` (:446),
`StationButton/styles/focus` (:505) and `TabContainer/styles/tab_focus` (:534); the plate variations
(`MenuButtonPlate` on every menu plate, `StationButton` on all 19 station buttons, plain `Button` on
every panel row) all inherit it. No node overrides it (`theme_override_styles/focus` appears nowhere in
`ui/`, no `StyleBoxEmpty` anywhere in the project).

Engine side, read from `godotengine/godot scene/gui/button.cpp`, `NOTIFICATION_DRAW`:

```cpp
Ref<StyleBox> style = _get_current_stylebox();
if (!flat) { style->draw(ci, Rect2(Point2(), size)); }   // state plate
if (has_focus(true)) { theme_cache.focus->draw(ci, Rect2(Point2(), size)); }   // focus overlay, on top
```

and `Viewport::_gui_control_has_focus(p_control, p_ignore_hidden_focus) { return (!p_ignore_hidden_focus ||
!gui.hide_focus) && gui.key_focus == p_control; }` — `grab_focus()` is called with the default
`p_hide_focus = false`, so the focus indicator is *not* hidden and the box is drawn. `has_focus(true)`
was measured `true` on the focused plate and rail entry.

Suggested fix (next fix cycle):
1. In `tools/build_theme.gd`, give the **Button family** an empty focus box: add e.g.
   `boxes[&"button_focus"] = StyleBoxEmpty.new()` in `_make_boxes()` and register it for `Button` in
   `_register_wiring()` (:228), and set `boxes[&"focus"] = boxes[&"button_focus"]` in
   `_register_plate_variations()` (:316) so `MenuButton`/`MenuButtonPlate`/`StationButton` lose it too.
   Keep `_focus_box()` for `ItemList/cursor` (:349), `Tree/cursor` (:361) and `TabContainer/tab_focus`
   (:254) — those are list cursors, not button focus rings.
2. Regenerate the theme with the generator (twice, compare sha256), then re-run the W1 ring probe.
3. **Owner decision needed before shipping the empty box as-is:** the station rail's *only* keyboard
   focus affordance is that box (`station.gd` `_make_rail_entry()` :245-250 sets `toggle_mode` and the
   active module is shown via `set_pressed_no_signal()` :375 — pressed, not focused). An empty focus box
   leaves the station keyboard-invisible. Options: (a) accept it (letter of §9.8 item 1), or (b) swap the
   Button-family focus box to a non-red 1 px border (`metal_light`/`text_primary`) so focus stays visible
   while no red rectangle is ever drawn, and keep the menu's cue as the tick + emblem pulse. Option (b)
   satisfies §9.8 item 1's wording ("no red rectangle") and does not regress keyboard use.

### W6-2 — LOW/MEDIUM — the backdrop drift slack has two sources of truth (and the specs are stale)

| Field | Value |
|---|---|
| Files | `vajb-orbit/ui/screens/main_menu.gd:117,253-259` (`_reserve_drift_slack()`), `vajb-orbit/ui/screens/main_menu.tscn:46-47` (`offset_right/bottom = 24.0`) |
| Area | W1 item 3 (`DRIFT_DISTANCE` 24 → 96, `DRIFT_SECONDS` 40 → 20) |
| Problem | The scene still declares the *pre-W1* 24 px oversize; `_ready()` overwrites both offsets with `DRIFT_DISTANCE` (96). The scene values are dead, and a maintainer who edits them (or re-saves the scene) sees no effect. The docs are now a third answer: `MAIN_MENU_V2.md` :335/:560/:565/:608/:738 still say "1944 x 1104 (1920 x 1080 + 24 px of drift slack)" and "24 px over 40 s", `MAIN_MENU_SPEC.md:74` and `ENVIRONMENT_SPEC.md:37` likewise, and `IMPLEMENTATION_PLAN.md:312` still records "dust drift … 24 px over 40 s". |

Evidence (measured): runtime `backdrop offsets right=94.7 bottom=94.7 size=(2016.0, 1176.0)` — i.e.
viewport + 96 px per axis, no edge uncovered at either end of the leg (pos −96 → right edge 1920).

Suggested fix: pick one owner — set `offset_right/offset_bottom = 96.0` in `main_menu.tscn` and delete
`_reserve_drift_slack()` (plus its `_ready()` call at :117), then regenerate/re-save nothing else; the
doc corrections (drift 96 px / 20 s, plate 2016×1176) belong to the orchestrator, since the wave brief
forbids worker edits under `docs/`.

### W6-3 — LOW — REFINERY action-button heights: scene and code disagree

| Field | Value |
|---|---|
| Files | `vajb-orbit/ui/station/refinery_panel.gd:53-57` (`ACTION_MIN_HEIGHT := 88.0`), `:189-192` (`_fit_action_buttons()`), comment at `:49-51`; `vajb-orbit/ui/station/refinery_panel.tscn:189,196,203` |
| Area | W2 item 3 (three action buttons share one size) |
| Problem | The fix is correct at runtime (measured), but the scene still declares `Vector2(0, 88)` for `RefineButton` and `Vector2(0, 56)` for `RefineAllButton`/`CancelButton`, and the panel's own comment two screens above insists "the RefineBox geometry … live[s] in the scene file as the one source and [is] not mirrored here" — which is no longer true for the two secondary heights. Two sources, one dead value. |

Evidence (measured, standalone mount of `refinery_panel.tscn` in a 1560×900 visible harness):

```
RefineButton     text='REFINE 1'     global=(1200.0, 582.0) size=(360.0, 88.0) min=(0.0, 88.0)
RefineAllButton  text='REFINERY ALL' global=(1200.0, 682.0) size=(360.0, 88.0) min=(0.0, 88.0)
CancelButton     text='CANCEL'       global=(1200.0, 782.0) size=(360.0, 88.0) min=(0.0, 88.0)
```

All three: identical `size.x = 360.0` (full column width) and `size.y = 88.0`, same axis, 100 px apart.
Acceptance met.

Suggested fix: move the height into the scene (`refinery_panel.tscn`: the two secondary buttons to 88)
and drop `ACTION_MIN_HEIGHT`/`_fit_action_buttons()`, or amend the :49-51 comment to name the code side
as the owner of the two secondary heights.

### W6-4 — LOW — the HUD target window colours the threat label unconditionally

| Field | Value |
|---|---|
| Files | `vajb-orbit/ui/hud/hud.gd:400` (inside `_refresh_static_tints()`) |
| Area | W3 item 6 (`set_target_info`, threat in `accent_danger`) |
| Problem | `_set_text_alert(_target_threat_label, true, TOKEN_DANGER)` runs from the *static* tint pass, so the threat label is always `accent_danger`, including while the panel is hidden and for any future non-hostile threat string (a `NEUTRAL` or `SCANNING` value would print hostile-red). The colour is currently applied from module state instead of from the data it describes. |

Evidence (measured): fed `threat="HOSTILE"` → label colour `(0.7843, 0.2784, 0.1216, 1.0)` =
`accent_danger` `#c8471f` (correct for this value), but the assignment is unconditional and
`_apply_target_info()` (`:455-470`) writes only the text, never the colour.

Suggested fix: move the alert call into `_apply_target_info()` and key it on the value
(`_set_text_alert(_target_threat_label, threat == "HOSTILE", TOKEN_DANGER)`), leaving
`_refresh_static_tints()` to the genuinely static tints.

### W6-5 — LOW — the new mock-target sprite (and the player) is minified 15× with no mipmaps

| Field | Value |
|---|---|
| Files | `vajb-orbit/game/game.tscn:49-51` (`TargetBody`), `vajb-orbit/assets/ships/ship_interceptor_side.png.import` |
| Area | W3 item 3 (mock target gets a body) |
| Problem | `ship_interceptor_side.png` is 940×107 drawn at `scale = 0.0663` → 62.3×7.1 px on a 1080p canvas (a 15.1× reduction), and the cut has `mipmaps/generate = false` with no `texture_filter` override on the sprite, so linear minification aliases/shimmer as the body orbits. The pre-existing `Player` sprite has the same combination (905×387 at the same scale, 15×), so this is a family-wide issue the wave extended to one more node, not one it introduced. |

Evidence (measured): `assets/ships/ship_interceptor_side.png` = 940×107 RGBA, `.import`
`mipmaps/generate = false`; `game.tscn` `TargetBody … scale = Vector2(0.0663, 0.0663)`;
`project.godot` sets no `rendering/textures/canvas_textures/default_texture_filter`.

Suggested fix: enable mipmaps for the ship side cuts (import setting + reimport) or set
`texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` on `Player` and `TargetBody`. The `_96`-style
mipmap precedent already exists for icons (`apply_import_settings.py`), so the ship cuts are the gap.

### W6-6 — LOW — Oxanium's default instance is ExtraLight, not Regular

| Field | Value |
|---|---|
| Files | `vajb-orbit/assets/fonts/Oxanium[wght].ttf`, `vajb-orbit/tools/build_theme.gd:191-206` (`_load_fonts()`) |
| Area | W5 item 1 (titles in Oxanium wght 700) |
| Problem | The variable font's default/legacy name is "Oxanium ExtraLight" (`fvar` wght axis min 200 / default **200** / max 800; name ID 1 = "Oxanium ExtraLight", ID 16 = "Oxanium", ID 17 = "ExtraLight"). Any consumer that resolves the bare `FontFile` instead of the `display` `FontVariation` gets a hairline face. Contained today: all six display variations carry the variation (verified), `default_font` is Rajdhani-Regular, and no scene uses an unvaried Oxanium. |

Evidence (measured): `build_theme` output `font=FontVariation over res://assets/fonts/Oxanium[wght].ttf
({ &"wght": 700 })` for `ScreenTitle`, `HeroTitle`, `StationPanelTitle`, `DialogTitle`, `HudReadout`,
`MenuButtonPlate`; no other variation resolves to Oxanium.

Suggested fix (defensive, optional): assert in `build_theme.gd` that every entry of `FONT_ROLES` with
role `display` resolves to a `FontVariation`, so a future variation cannot silently pick up ExtraLight.

---

## 2. Per-file review (every file the brief lists)

| File | Verdict | Note |
|---|---|---|
| `ui/components/menu_button.gd` | **pass** | Ring branch and all its plumbing gone: `FOCUS_BORDER` absent from the constant map, `_focus_color`/`_focused`/`_set_focused`/`accent_danger_bright` 0 occurrences, `draw_rect` count 2 (hover/idle). Behaviour otherwise untouched. Consumer check: no `_focused`/`_set_focused` reference survives in `ui/`. |
| `ui/screens/main_menu.gd` | **pass, with W6-2** | `DRIFT_DISTANCE` 96.0, `DRIFT_SECONDS` 20.0, pulse constants 2.35/0.10/0.30, resting brighten 2.0; pulse envelope reproduced (see §3). `_reserve_drift_slack()` is the W6-2 duplication. |
| `ui/screens/station.gd` | **pass** | `BACKDROP_DIM_ALPHA` 0.84 (runtime `%BackdropDim.color.a` = 0.84 after the entry tween); `GRAIN_*` 0.06/0.11/5.0 untouched; `MODAL_DIM_ALPHA` 0.72 untouched. |
| `ui/station/outfitting_panel.gd` | **pass** | Header fit holds the four columns at +0.00 in four measured states (§3); reverts exactly when the cell does; no sticky width, no accumulation. |
| `ui/station/refinery_panel.gd` | **pass, with W6-3** | Three buttons 360×88 measured. |
| `ui/hud/hud.gd` | **pass, with W6-4** | `set_target_info` public, `clear_target` hides the panel synchronously, zoom hover tint via `text_dim`/`text_primary`, `_format_int` grouping; no hex literals, no font-size overrides. |
| `ui/hud/hud.tscn` | **pass** | `TopRight` target panel (caption `TARGET` + `StationValue` name + `HudHullBar`/`HudShieldBar` + distance + threat), `visible = false` in the scene; `BottomCenter` `DockHint`; zoom buttons 28×28 with the `_96` cuts, `ignore_texture_size`, `stretch_mode = 5`; `SectorLabel` on `FlavourText`. |
| `game/game.gd` | **pass, with W6-5** | `ACCELERATION` 420, `DRAG` 120, `MAX_SPEED` 420, `TURN_RATE` 2.6, `BOOST_MULTIPLIER` 2.1; wheel zoom clamped 0.70/1.50 with a 0.18 s SINE/EASE_OUT tween settling at exactly 0.70; `set_target_info` in `HUD_METHODS`; mock-data comments present. |
| `game/game.tscn` | **pass, with W6-5** | `TargetBody` (`Sprite2D`, cutter-scale 0.0663) between `Player` and `Camera`; reticle stays on the HUD `CanvasLayer` layer 10. |
| `ui/station/repairs_panel.gd` / `.tscn` | **pass** | `hull_render()` intact/damaged logic verified in 6 cases incl. negative and unknown hull; frame = `PanelRaised` + `HullMargin` + `HullCenter` + `HullImage` (`expand_mode 1`, `stretch_mode 5`), contain-fit exactly 0.7000 of the frame width. |
| `ui/station/launch_panel.gd` / `.tscn` | **pass** | Intact cut only; caption `VANGUARD — READY` format fed the active hull's upper-cased name (measured live: `LANCER — READY` for the profile's active hull); `DESTINATION_LINES[&"game"] = "OPEN SPACE · HELIOS DRIFT"`; briefing rows unchanged. |
| `ui/screens/station.tscn` | **pass** | Subline `DOCKING RING 04 · HELIOS DRIFT · HULL TRAFFIC LOW` on `FlavourText`; the two `Color(...)` values present are pre-existing (the file's only change is the +2-byte string swap and W5's −3-byte variation swap). |
| `tools/build_theme.gd` | **pass, with W6-1/W6-6** | Typography block, `FONT_ROLES`, `FlavourText` (13 px, `text_dim`), `_first_font()` fallback, and the superseded "default_font intentionally unset" line replaced by a self-reporting print. The Button-family `focus` box is the W6-1 gap. |
| `autoload/router.gd` | **pass** | `FONT_SIZE_ITEMS` 27 → 28 with `FlavourText`; two-way coverage against the theme is exact (28 = 28, both difference sets empty). |
| `ui/theme/vajb_theme.tres` (regenerated) | **pass, with W6-1** | 28 font-size items, 19 variations, `default_font` Rajdhani-Regular; display/body/flavour assignment exactly as ruled; deterministic (§4). |
| `assets/fonts/` | **pass** | Five TTFs + one OFL text per family (Oxanium, Rajdhani, Saira Stencil One) + `README.md`; TTFs parse, family/weight names match their filenames, all five imported (`font_data_dynamic`) with uids referenced correctly; Oxanium carries one `wght` axis 200–800 (see W6-6). |

No file outside the wave's declared set was touched: an mtime sweep of `vajb-orbit/**` (excluding
`addons/`, `.godot/`) shows only the files above plus the font folder; `project.godot` is at 13:15,
i.e. untouched, and `docs/` is untouched.

---

## 3. Acceptance measurements (W6 checklist)

| W6 check | Result | Evidence |
|---|---|---|
| Ring truly gone everywhere | **FAIL** | W6-1. The script's rect is gone; the engine-drawn theme `focus` box is not. |
| No new hex literals | pass | `#[0-9a-fA-F]{3,8}` scan of all nine changed `.gd` files: none. The changed `.tscn` files add one text string, one variation name and two plain nodes — no colour or size literal. |
| No per-node font-size overrides | pass | `add_theme_font_size_override` / `theme_override_font_sizes` appear only under `addons/godot_ai/`. |
| Alignment measurement evidence | pass | Probe C, OUTFITTING at 1920×1080, header-vs-row left edges, `delta = header.x − max(cell.x, first-label.x)`: `Icon +0.00, TitleBox +0.00, Held +0.00, Price +0.00, Status +0.00` in all four states — as built (`grid x=441 w=1414`), HELD cell grown 130 → 143 px (`Held w=143`), panel resized to 1600×900 (`panel=1120, grid w=1094`), and after the cell reverted to 130 (no sticky width). Margin overrides resolve to `L=13 R=13` = the scroll's 1 px border + the row's 12 px `RowInner` inset. Probe A reproduces the same five `+0.00` deltas from the full `station.tscn`. |
| Button sizes | pass | Refinery 360×88 ×3 (§1 W6-3). |
| Minimap hit areas | pass | `ZoomMinus` rect `(1847,1039)` 28×28, `ZoomPlus` rect `(1879,1039)` 28×28 — `custom_minimum_size = (28,28)`, `ignore_texture_size = true`, texture 96×96, `stretch_mode = 5`; the 36×36 alpha map of both cuts shows a framed plate with a clear horizontal bar (minus) and a clear cross (plus), glyph stroke ≈ 10-13 px of the 96 px cut (≈3 px at the 28 px draw size). Wiring re-verified by W3's probe B path (`pressed` → radius 3200→2400/4000, clamped 800/6400); the HUD-side radius also reads 3200 at rest and the minimap control follows `set_minimap_scale`. |
| Zoom clamps | pass | 41 wheel-ups → target `1.50`; 60 wheel-downs → `0.70`; tween settles at `camera.zoom = (0.7, 0.7)`; `CAMERA_ZOOM_SECONDS = 0.18`; `project.godot` untouched; no input-map change. |
| HUD `set_target_info` wired in `HUD_METHODS` | pass | `HUD_METHODS = [bind, set_sector_name, set_minimap_scale, set_minimap_blips, set_target, set_target_info, clear_target, set_cargo_open]`; fed panel renders `name='RAIDER INTERCEPTOR' distance='1 240 m' threat='HOSTILE' hull=0.62 shield=0.6` at rect (1694,12)–(1908,165), i.e. 12 px from the top-right edge; `clear_target` hides it synchronously (`visible=false` on the same frame). |
| Damaged / intact render logic | pass | `hull_render`: `missing=0 → ship_vanguard_side.png`, `250 → ship_vanguard_damaged_side.png`, `-4 → …_side.png`, `ship_fighter/300 → ship_fighter_side.png` (no damaged cut on disk), `ship_destroyer/1 → …_side.png`, unknown id → `''`. On the mounted panel: intact → `ship_fighter_side.png` (profile's active hull), after `_refresh_preview(vanguard,250)` → `ship_vanguard_damaged_side.png` (907×389), then back to the 905×387 intact cut. |
| Determinism of the theme build | pass | Two consecutive `--script res://tools/build_theme.gd` runs, exit 0 both: `sha256 B92C03A5AB96573361BBE573A7A1E67AFE505CB5BA13AD28BD5CE14C287ADE59` both times, 25 708 bytes, **byte-identical to the shipped `.tres`** (compared against a pre-review copy). |
| `tools/` clean | pass | Holds `build_theme.gd`, `derive_icon_tints.gd` and their `.uid` only; all probes and scratch files (this review's included) deleted. |
| Parse checks re-run | pass, with the documented limitation | `--check-only --script`: `menu_button.gd` exit 0, `build_theme.gd` exit 0, `router.gd` exit 0; the eight scripts that name an autoload fail with `Compile Error: Identifier not found: AudioManager/Router/SettingsManager` — reproduced on the untouched `ui/station/shipyard_panel.gd`, so it is the command's limitation, not a file fault. Substitute gate: `load()` of all eleven changed scripts inside a live tree (`probe B`) → `ok` for every one, plus clean scene runs (`main_menu.tscn`, `station.tscn`, `game.tscn` with `--quit-after` — no parse, resource or node errors; the menu/station teardown lines are the pre-existing `AudioManager` stream retention W1 attributed) and the project suite `res://tests/headless_runner.tscn` → `[SUMMARY] passed=53 failed=0`. |

Emblem pulse (W1 item 2), re-measured at `--fixed-fps 60`, `_set_active_verb(1)` from rest:

```
0:2.0000 1:2.0906 2:2.1750 3:2.2475 4:2.3031 5:2.3381 6:2.3500 7:2.3195 … 23:2.0013 24:2.0000 25:2.0000
```

Peak `2.3500` at frame 6 = **0.100 s**, back to `2.0000` at frame 24 = **0.400 s**, resting value
exactly 2.0 — the brief's envelope to the frame. Station backdrop dim settles at 0.84, not 0.72.

---

## 4. Verification gaps (honest limits of this review)

1. **The scrollbar-visible OUTFITTING state was not reproduced.** Shrinking the station to 1600×900
   gave `panel=1120, grid w=1094` with `scrollbar=false` — the 12 rows still fit, so the vertical
   scrollbar never appeared. The branch is verified by reading (`outfitting_panel.gd:350` connects
   `VScrollBar.visibility_changed → _queue_header_fit`, and `_fit_header():379-382` takes both margins
   from the grid's own box), not by measurement.
2. **The "longest HELD caption" state was simulated, not produced by data.** Writing
   `META_ADVISORY` into the live caption label is reverted by the next `_refresh_row()` (which rewrites
   every caption from the profile), so the state was forced by growing the row's HELD cell to 143 px —
   the same mechanism (`cell.get_combined_minimum_size().x` → header cell minimum). Deltas stayed
   `+0.00` and the header reverted when the cell did.
3. **Pre-fix baselines are re-derived, not measured.** This workspace has no VCS, so the "before"
   numbers in §1 (e.g. the refinery 56 px heights, the −14 px pre-fix HELD drift) are read from the
   shipped scene/reports; only the post-fix states are measured here.
4. **No pixel capture.** Headless runs use no rasteriser, so the ring finding rests on the effective
   theme item + `has_focus` state + the engine's documented draw path (two independent sources:
   `button.cpp` and `viewport.cpp`) rather than on a rendered frame. A graphical `project_run` +
   `editor_screenshot(source="game")` on the main menu would close that last gap if the owner wants a
   pixel-level before/after, at the cost of launching the game.
5. **Audio/determinism of music, GPU-level animation quality, and the 7 px mock-target silhouette**
   are outside what a headless review can judge; the target's on-screen height (62.3×7.1 px) follows
   the brief's own 0.0663 factor and is an owner art call (W3 flagged it).

---

## 5. Clean-up and integrity

- Probes `tools/_probe_w6.gd`, `_probe_w6b.gd`, `_probe_w6c.gd` and their `.uid` sidecars deleted;
  `tools/` = `build_theme.gd`, `build_theme.gd.uid`, `derive_icon_tints.gd`, `derive_icon_tints.gd.uid`.
- Scratch files written outside the project (`tmp_w6_*.txt`, a pre-review theme copy at the workspace
  root) deleted; the pre-existing `tmp_comp.txt` left alone.
- The only project file this review rewrote is `ui/theme/vajb_theme.tres`, by running the generator
  twice; the output is byte-identical to the file W5 shipped (sha256 above), so the artifact is
  unchanged.
- No source file was edited. The issue list above is the fix-cycle input.
