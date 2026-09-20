# Fix Wave 1 — task brief (2026-09-18)

Owner-approved fixes from the live walkthrough crosscheck (main menu, station screens,
flight loop). The owner rulings are recorded here and in `docs/design/IMPLEMENTATION_PLAN.md`
§9.8 — implement them exactly, do not redesign, do not widen scope.

Waves: **W1–W4 run in parallel** (disjoint file sets). **W5 (fonts) runs after W1–W4 land**
(theme + several of the same files). **W6 = mandatory review** after W5.

---

## Global rules (all workers)

- Engine: Godot 4.7.2, GDScript. Project code lives in `vajb-orbit/` under the workspace root
  `G:/Mój dysk/Projekty/Vajb Orbit`.
- Read first: `AGENTS.md`, `docs/design/IMPLEMENTATION_PLAN.md` §9.8, then your section below.
- Match each file's existing style: static typing, tab indentation, `##` doc comments,
  theme colours read via the local `_token()` helper. Keep diffs minimal.
- Do **not** edit: `project.godot`, `addons/godot_ai/`, `ui/theme/vajb_theme.tres`
  (generated — W5 regenerates it via the generator), `tools/build_theme.gd` (W5 only),
  anything under `docs/`, anything under `assets/` not listed in your section.
- No hex literals outside `tools/build_theme.gd`. No per-node font-size overrides.
- The Godot editor may be open with the project, and a game may be playing. Do **not**
  launch the editor or the graphical game. Parse-check scripts with the console binary:
  `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --check-only --script res://<file>.gd`
  (repeat per changed script; `--check-only` exits without running).
- Throwaway probes (`extends SceneTree`, `quit()`-terminated) are allowed for measurement,
  must live at `res://tools/_probe_wN.gd`, and must be deleted with their `.uid` sidecar
  before your report; `tools/` ends holding only `build_theme.gd` + `derive_icon_tints.gd`
  (+ their `.uid`).
- Write your report to `.agents/gen/fix_wave1_<id>_report.md`: files changed with byte
  sizes before/after, exact commands run with their output, acceptance evidence
  (measurements, not assertions), deviations or open points. The reports in `.agents/gen/`
  are the standard to match.

---

## W1 — main menu

Files: `vajb-orbit/ui/components/menu_button.gd`, `vajb-orbit/ui/screens/main_menu.gd`.

1. **Delete the focus ring.** `menu_button.gd` `_draw()` draws a 1 px rectangle for the
   focused state (`FOCUS_BORDER` = `accent_danger_bright`). Remove that branch entirely:
   focused buttons draw exactly what idle/hover draw (breathing border, hover border).
   Remove the `FOCUS_BORDER` / `_focus_color` plumbing if it becomes unused — check
   `_refresh_colors()` and the header comment. The ring was contract in §3.11; §9.8 item 1
   retires it. The ring is removed everywhere `MenuButton` is used (settings, quit dialog
   included) — that is intended.
2. **Emblem pulse as the new cue.** Keep the left band (`_ticks`) exactly as it is.
   In `main_menu.gd`, when focus lands on a verb (`_set_active_verb` / the focus chain),
   pulse the emblem's brighten modulate: 2.0 → 2.35 over 0.10 s (TRANS_SINE EASE_OUT),
   then back to 2.0 over 0.30 s. Kill a previous pulse tween before re-triggering.
   The emblem is the 50×58 insignia above the verb stack, currently modulated by the
   `EMBLEM_BRIGHTEN` constant (2.0) — tween that same property/colour, introduce no new
   token, and leave the resting value at 2.0.
3. **Backdrop drift retune.** `DRIFT_DISTANCE` 24.0 → **96.0**, `DRIFT_SECONDS` 40.0 →
   **20.0**. Keep the two-leg sine ping-pong shape. Acceptance: motion is clearly
   perceptible, and no pop/seam appears across a full cycle.
4. Report the before/after constants and the ring-removal diff summary.

## W2 — station readability, alignment, refinery buttons

Files: `vajb-orbit/ui/screens/station.gd`, `vajb-orbit/ui/station/outfitting_panel.gd`,
`vajb-orbit/ui/station/refinery_panel.gd`.

1. **Backdrop contrast.** `station.gd` `BACKDROP_DIM_ALPHA` 0.72 → **0.84**. Do not touch
   the grain constants. Acceptance: captions over the backdrop area read clearly at
   1920×1080 (it is the owner's "gray on gray" finding).
2. **OUTFITTING header alignment.** The header row (`OutfittingHeader` inside `HeaderMargin`,
   margins 12) sits *outside* the `ScrollContainer`, while rows sit *inside* it. The theme
   gives `ScrollContainer` a `panel` stylebox with content margins (`SCROLL_CONTENT_MARGIN`
   5.0 in `tools/build_theme.gd`), so every row is inset ~5 px relative to the header and
   each caption drifts off its column ("HELD / MAX" finding). Fix so the header caption's
   left edge equals the value label's left edge for every column — either give the header
   the same inset, or add a local `add_theme_stylebox_override` on this panel's scroll
   zeroing its content margins (do not change the global theme box; W5 owns the generator).
   **Verify by measurement**: a headless probe that loads the scene, forces a 1920×1080
   root, lays it out, and prints the global x of each header caption vs its value label —
   all four columns must match. Delete the probe afterwards.
3. **REFINERY button sizes.** The three action buttons (`REFINE 1` / `REFINERY ALL` /
   `CANCEL`) must share identical width and height — full width of the control column,
   same height. Keep the existing emphasis (primary plates vs CANCEL) — the defect is the
   SIZE mismatch, not the style. Verify: same `size.x` and `size.y` at 1920×1080 (probe or
   arithmetic on the container setup, state which in the report).
4. Nothing else in these files changes.

## W3 — flight scene

Files: `vajb-orbit/ui/hud/hud.gd`, `vajb-orbit/ui/hud/hud.tscn`,
`vajb-orbit/ui/hud/minimap.gd`, `vajb-orbit/game/game.gd`, `vajb-orbit/game/game.tscn`.

1. **Minimap zoom controls usable.** `ZoomMinus` / `ZoomPlus` in the minimap footer are the
   "minimap not responsive" finding — they currently render as ~8 px specks. Give each a
   hit area of at least 24×24 px and a clearly visible glyph, with hover feedback from
   existing tokens. Keep the wiring (`minimap_zoom_changed` → game.gd radius step 800,
   clamp 800–6400). Acceptance: at 1920×1080 both buttons read as controls and clicking
   them visibly changes the map scale.
2. **ESC dock hint.** Add a bottom-centre hint to the HUD: text `ESC · DOCK AT KEPLER-9`,
   `StationCaption` styling (13 px, `text_dim`), bottom margin ≥ 16 px. Flight HUD only.
3. **Mock target gets a body.** Add a `Sprite2D` under the `Game` root carrying
   `res://assets/ships/ship_interceptor_side.png`, positioned at the mock target's orbit
   position, rotated to face along its direction of travel, sized to match the player's
   on-screen scale (player uses the 905×387 `ship_vanguard_side.png` at scale 0.0663).
   The HUD reticle stays on top of the world layer.
4. **Inertia.** `game.gd`: `ACCELERATION` 520.0 → **420.0**, `DRAG` 260.0 → **120.0**.
   Keep `MAX_SPEED` 420.0, `TURN_RATE` 2.6, `BOOST_MULTIPLIER` 2.1. Acceptance: releasing
   thrust coasts roughly 3 s before stopping (420 / 120), reading as coasting, not braking.
5. **Camera zoom.** Mouse wheel zooms the flight camera: `Camera2D.zoom` target within
   **0.70–1.50** (wheel up = zoom in), smoothly interpolated ~0.18 s. Implement in
   `game.gd` via `_unhandled_input` on `InputEventMouseButton` wheel events — do **not**
   touch the input map or `project.godot`. Acceptance: wheel visibly zooms with smoothing,
   value stays clamped.
6. **Target preview window.** New `TopRight` block in `hud.tscn`: a `PanelContainer` with
   caption `TARGET`, name label (`StationValue`), hull + shield `ProgressBar`s reusing the
   `HudHullBar` / `HudShieldBar` style types, a distance label (e.g. `1 240 m`) and a
   threat label (`HOSTILE`, `accent_danger`). Hidden when there is no target. New HUD API
   `set_target_info(info: Dictionary)` with keys `name`, `hull` (0–1), `shield` (0–1),
   `distance_m`, `threat`; `clear_target` also hides the panel. `game.gd` `_update_target`
   feeds it from the mock target: name `RAIDER INTERCEPTOR`, hull = `_target_hull`,
   shield 0.6, distance = `round(_target_position.distance_to(_player.position) / 10) * 10`,
   threat `HOSTILE`. Add `set_target_info` to `HUD_METHODS`. Comment in code: mock data,
   P2 replaces it with real ship data.
7. Report: every constant change, the probe/parse evidence, and how the zoom buttons were
   made usable.

## W4 — repairs + launch panels

Files: `vajb-orbit/ui/station/repairs_panel.gd` + `.tscn`,
`vajb-orbit/ui/station/launch_panel.gd` + `.tscn`, `vajb-orbit/ui/screens/station.tscn`.

1. **REPAIRS**: the large empty framed area inside `RepairControl` gets the active-hull side
   render — `res://assets/ships/ship_vanguard_side.png`; when the damage report shows
   missing hull > 0 use `res://assets/ships/ship_vanguard_damaged_side.png`. Resolve the
   active hull the same way `shipyard_panel.gd` resolves its preview (read it; reuse or
   mirror its small mapping). Contain-fit to ~70 % of the frame width, centred. All
   existing behaviour, strings and fee math stay untouched. Acceptance: no report /
   repaired → intact render; damaged → damaged render.
2. **LAUNCH**: the same empty frame gets the active-hull side render (intact) with a caption
   `VANGUARD — READY` (active hull name uppercase) beneath it. Briefing rows unchanged.
3. **Interim sector naming** (§9.8 item 5): `launch_panel.gd` (`game` destination string)
   `OPEN SPACE · SECTOR K-9` → `OPEN SPACE · HELIOS DRIFT`; `station.tscn` header subline
   `DOCKING RING 04 · SECTOR K-9` → `DOCKING RING 04 · HELIOS DRIFT`. Only those strings.
4. No new art. Captions use existing theme variations.

## W5 — fonts (after W1–W4)

Files: `vajb-orbit/tools/build_theme.gd`, `vajb-orbit/autoload/router.gd` (only if a new
font-size item is added), regenerated `vajb-orbit/ui/theme/vajb_theme.tres`, plus four
small applies: `ui/screens/main_menu.gd` (readout), `ui/screens/station.tscn` (subline,
coordinate with W4's string change already landed), `ui/hud/hud.tscn` (minimap sector
label), version stamp usage.

Fonts are already copied to `vajb-orbit/assets/fonts/` (owner-downloaded, OFL, licences
beside them): `Oxanium[wght].ttf`, `Rajdhani-Regular.ttf`, `Rajdhani-Medium.ttf`,
`Rajdhani-SemiBold.ttf`, `SairaStencilOne-Regular.ttf`.

1. **Titles — Oxanium** (variable). Build a `FontVariation` on base `Oxanium[wght].ttf`
   with `variation_opentype = {"wght": 700}`; assign as the font of: `ScreenTitle`,
   `HeroTitle`, `StationPanelTitle`, `DialogTitle`, `HudReadout`, `MenuButtonPlate`.
2. **Body — Rajdhani.** `theme.default_font = Rajdhani-Regular`; `StationValue` =
   Rajdhani-SemiBold; use Rajdhani-Medium where a caption needs more presence
   (SectionHeader/StationCaption) — your judgement, keep it to these faces.
3. **Flavour — Saira Stencil One.** New variation `FlavourText` (base `Label`, size 13,
   `text_dim`; reuse the existing 13 px size — if you add a font-size item you MUST mirror
   it in `Router.FONT_SIZE_ITEMS` and say so). Apply to: `Version` variation (font swap),
   the main-menu read-out label, the station header subline, the HUD minimap sector label.
4. Regenerate the theme with
   `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/build_theme.gd`
   and verify determinism: run it twice, identical `.tres` sha256. Report before/after
   font-size item counts and the variation list.
5. The `default_font intentionally unset` print/comment in the generator is superseded —
   update that line's wording.

## W6 — review (mandatory, after W5)

Reviewer reads every changed file against this brief and §9.8. Structured issue list
(file, area, problem, suggested fix); no inline edits. Check: ring truly gone everywhere;
no new hex literals; no per-node font-size overrides; alignment measurement evidence;
button sizes; minimap hit areas; zoom clamps; HUD `set_target_info` wired in `HUD_METHODS`;
damaged/intact render logic; determinism of the theme build; `tools/` clean; parse checks
re-run. Fix cycle follows for any real issue, then re-review until clean (max 3 cycles).
