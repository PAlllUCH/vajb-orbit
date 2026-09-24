# Vajb Orbit — UI & Theming Spec

**Status:** draft 2026-09-17. Final UI/theming spec, screen by screen, mapped to concrete Godot 4.7 Control node types so the coding pass is mechanical.

**Scope rules inherited from the project:** Godot 4.7.2, Forward+, window stretch mode `canvas_items`, aspect `expand`. All UI lives under a `CanvasLayer` (UI is screen-space; the game world never scales UI anchors). Layer Cake: signals travel up, calls travel down — UI emits signals, gameplay connects.

---

## 1. Colour Tokens

All colours are defined once as theme colours on the base `Theme` (see §6) and referenced by name everywhere. No literal hex values in scenes or scripts except inside the theme file.

| Token | Value (hex) | Meaning |
|---|---|---|
| `void_base` | `#07090d` | Near-black blue void — the only background for full-screen UI |
| `void_panel` | `#0b0f15` | Raised surface for panels/dialogs |
| `void_panel_raised` | `#10151d` | Hover/highlight surface on top of `void_panel` |
| `metal_dark` | `#1b2028` | Desaturated gunmetal — bevel shadow side, inactive slots |
| `metal_mid` | `#2a313c` | Gunmetal mid — default slot/panel edge fill |
| `metal_light` | `#3d4654` | Gunmetal light — bevel highlight side, enabled borders |
| `text_primary` | `#c9d1dc` | Body text, readable contrast on all `void_*` and `metal_*` |
| `text_dim` | `#6b7484` | Secondary labels, disabled text |
| `accent_danger` | `#c8471f` | Single burnt orange-red accent — damage, danger, alerts, active fire mode |
| `accent_danger_bright` | `#e8622a` | Same hue one step brighter — hover state of danger elements only |
| `accent_nav` | `#6fb8c4` | Prograde-needle cyan (§3.6, added 2026-09-20) — velocity-vector navigation read, never a glow, never a danger colour |

**Rules:**

- Exactly one accent colour (`accent_danger`). No rainbow. Success/info states are expressed with `metal_light` + `text_primary`, not green/blue.
- `accent_nav` (2026-09-20) is the single navigation-exception colour: it colours only the speedometer prograde needle (§3.6) and nothing else; it is desaturated steel-cyan so it reads as an instrument, not a glow.
- Contrast floor: `text_primary` on `void_base` ≈ 11:1; `text_dim` on `void_base` ≈ 4.0:1 (large text / labels only, never body).
- Danger is reserved: if it is not damage, an alert, or an armed weapon, it is not orange.
- Thin bevels: 1 px only. Bevels are drawn by StyleBox borders (`metal_light` top/left, `metal_dark` bottom/right), never gradients.

## 2. Theme Architecture

One base theme resource: `vajb-orbit/ui/theme/vajb_theme.tres`, assigned once on the root `Control` of every screen (and cascading to all descendants). Per-control overrides are forbidden except for one-off special cases documented in this spec.

### 2.1 Theme resource contents

The `.tres` defines, per theme type:

- **StyleBoxes** — every StyleBox is a `StyleBoxFlat` except panel chrome, which uses `NinePatchRect`-backed textures where specified (§5). All StyleBoxFlat corners use radius 0 (hard sci-fi) or 2 px max; border width 1 px (`border_width_all = 1`).
  - `panel` — bg `void_panel`, border `metal_mid`
  - `panel_raised` — bg `void_panel_raised`, border `metal_light` top/left, `metal_dark` bottom/right (the bevel)
  - `button_normal` — bg `metal_dark`, bevel border as above
  - `button_hover` — bg `metal_mid`, border `metal_light`
  - `button_pressed` — bg `void_panel_raised`, inset bevel (borders flipped: `metal_dark` top/left)
  - `button_disabled` — bg `metal_dark`, border `metal_dark`, content margin +2
  - `focus` — 1 px border `accent_danger_bright`, no bg fill, `expand_margin` 0. **Amended 2026-09-18:** the menu plate variation no longer draws this box; the station rail, dialogs, lists and tabs keep it (IMPLEMENTATION_PLAN §9.8 item 1)
  - `lineedit` / `lineedit_focus` — bg `void_base`, border `metal_mid` / `metal_light`
  - `slider_groove`, `slider_grabber` — groove 4 px tall bg `metal_dark` border `metal_mid`; grabber 12×12 bg `metal_light` border `text_dim`
  - `progress_bg`, `progress_fill` — bg `void_base` border `metal_mid`; fill solid `accent_danger` (see §3.3 for variant overrides)
  - `tooltip_panel` — bg `void_panel` (90 % alpha), border `metal_mid`
- **Fonts and sizes.** A single font family (fallback: Godot default; **amended 2026-09-18:** three OFL families per IMPLEMENTATION_PLAN §9.8 item 2 — Oxanium titles, Rajdhani body, Saira Stencil One flavour). Font size scale via the base theme `default_font_size = 14`, with sizes registered per type: `Label` 14, `Button` 14, `LineEdit` 14, `RichTextLabel` (`normal_font_size`) 13, tooltips 13, HUD value readouts 18, screen titles 22. One `font_size_scale` factor is applied globally at runtime through `ThemeDB`/project setting `gui/theme/custom_font_size`-style scaling so a future accessibility slider changes all sizes together (no per-node `add_theme_font_size_override`).
- **Colours** — the §1 tokens registered as theme colours on the relevant types (e.g. `Label/colors/font_color = text_primary`, `font_disabled_color = text_dim`).
- **Icons** — 16×16 line icons in `text_dim` except danger icons in `accent_danger`. No multicolour icons.

### 2.2 Focus & input conventions

- Every interactive Control shows the shared `focus` stylebox on keyboard focus; `focus_mode = FOCUS_ALL` on buttons, sliders, line edits. **Amended 2026-09-18:** the menu plates are exempt — their focus cue is the tick band plus the emblem pulse (IMPLEMENTATION_PLAN §9.8 item 1).
- Tab order follows visual order (containers guarantee this); no manual focus neighbours except where noted (§5 rebinding list).
- Hover states: `button_hover` + a 1 px accent border is used *only* on armed/critical buttons; regular hover keeps gunmetal. **Amendment 2026-09-17 (menu hover-glow policy, see STYLE_BIBLE §7.3):** on menu and screen-level scenes only (`main_menu.tscn`, `loading.tscn`, dialogs), button hover adds a 6 px soft Ember Glow `#E8703A` outer halo (60 % alpha, implemented as a glow underlay `Panel` behind the plate or a shader — one implementation for all buttons) plus the hover plate art's baked ember under-light. HUD controls never use the halo.

### 2.3 Scene layout convention

Every screen scene:

```
ScreenName (Control, full rect, theme = vajb_theme.tres)
└─ UILayer (CanvasLayer, layer 10)          # HUD screens only
   └─ MarginContainer (margins 12)
      └─ ... layout per section below
```

Dialogs (§5) are separate scenes instantiated under a dedicated `CanvasLayer` (layer 20) so they always stack above HUD.

## 3. In-Game HUD

Scene: `vajb-orbit/ui/hud/hud.tscn`. Root: `Control` (full rect, `mouse_filter = IGNORE`) → `CanvasLayer` (layer 10) → four zone containers.

```
HUD (Control, MOUSE_FILTER_IGNORE, full rect)
└─ CanvasLayer (layer 10)
   ├─ TopLeft (MarginContainer, anchors top-left, margins 12)
   │  └─ VBoxContainer
   │     ├─ HullBlock (VBoxContainer)
   │     │  ├─ HBoxContainer (Label "HULL" + Label value "812/1000")
   │     │  └─ ProgressBar (hull)
   │     └─ ShieldBlock (VBoxContainer)
   │        ├─ HBoxContainer (Label "SHIELD" + Label value)
   │        └─ ProgressBar (shield)
   ├─ BottomLeft (MarginContainer, anchors bottom-left, margins 12)
   │  └─ VBoxContainer
   │     ├─ AmmoPanel (PanelContainer → VBoxContainer)
   │     │  ├─ Label weapon name + ammo "Laser MkII  240/300"
   │     │  └─ GridContainer 5×1 (weapon slot TextureButtons)
   │     └─ CargoToggle (TextureButton, collapsed cargo icon)
   ├─ BottomRight (MarginContainer, anchors bottom-right, margins 12)
   │  └─ MinimapPanel (PanelContainer → VBoxContainer)
   │     ├─ MinimapView (Control, custom _draw, 200×200)
   │     └─ HBoxContainer (Label sector name, TextureButton zoom +/-)
   └─ CenterOverlay (Control, anchors full, MOUSE_FILTER_IGNORE)
      ├─ TargetReticle (Control, custom _draw, follows target)
      └─ CargoPanel (PanelContainer, hidden by default, see §3.4)
```

### 3.1 Hull & shield bars

- Both are `ProgressBar`. `show_percentage = false`; custom font display in the sibling `Label` above (value as current/max).
- **Hull**: min 0, max from ship stats. Style override (the one sanctioned deviation from pure tokens): fill stylebox bg `accent_danger`; when hull fraction < 25 % the fill switches to `accent_danger_bright` and the value label turns `accent_danger_bright` (done in script, no new tokens).
- **Shield**: fill stylebox bg `metal_light` (shield is not a danger state — it regenerates; orange stays reserved). Border `metal_mid`, bg `void_base`.
- Both bars: size 260×14, `progress_bg`/`progress_fill` styleboxes from §2.1, corner radius 0.

### 3.1b Energy & fuel bars (rulings 10/14, 2026-09-20)

Amends the TopLeft `VBoxContainer`: below `ShieldBlock` sit two more blocks,
same pattern:

- **Energy**: `ProgressBar` 260×14, fill `metal_light` (the buffer is not a
  danger state — same reasoning as shield), label `ENERGY` with the
  current/max readout. Emergency Flight Mode (fuel 0): the fill turns
  `accent_danger` while the mode lasts.
- **Fuel**: fill `metal_mid`; at ≤ 15 % of max the fill and label turn
  `accent_danger`. Label `FUEL`. While fuel == 0 an `EMERGENCY FLIGHT`
  banner Label appears above the blocks in `accent_danger_bright`.
- HUD API: `set_pool(kind: StringName, value: float, maximum: float)` with
  `kind` ∈ `&"energy" | &"fuel"`; `set_emergency(active: bool)`.
- No new tokens: every colour above is an existing token role.

**Amendment 2026-09-24 (wave D7 — owner word "looks good" on the A1 sheet +
C1's finding that the bars duplicate the new dials):** the two `ProgressBar`
blocks (Energy + Fuel) and their labels **retire from the flight HUD** — the
cluster's FUEL/ENRG value dials (§3.7 Mockup v7) are the pool readouts now. The
**`EMERGENCY FLIGHT` banner stays** (fuel == 0, `accent_danger_bright`, in the
TopLeft column where the blocks were). The HUD API is unchanged:
`set_pool(kind, value, maximum)` and `set_emergency(active)` keep their frozen
§7 signatures and feed the dials. Reversal: restore the two blocks (the text
above).

### 3.2 Ammo & weapon slots

- `AmmoPanel` is a `PanelContainer` with the `panel_raised` stylebox; inner `VBoxContainer` separation 4.
- Weapon name/ammo `Label` uses size 18 readout styling; ammo turns `accent_danger` at ≤ 10 % of magazine.
- Weapon slots: `GridContainer` with 5 columns, each cell a `TextureButton` (48×48) with the four texture states from the generated art set:
  - `texture_normal` — gunmetal slot plate, weapon silhouette in `metal_light`
  - `texture_hover` — plate brightened one step (`metal_mid` plate)
  - `texture_pressed` — plate darkened to `void_panel_raised`
  - `texture_disabled` — silhouette at 40 % alpha, plate `metal_dark` (weapon not owned / on cooldown with a cooldown overlay drawn in `_draw` as a sweeping `accent_danger` wedge)
- Active weapon additionally gets a script-drawn 1 px `accent_danger` frame on top (not a fifth texture; keeps textures palette-neutral).
- Slot keys: number keys 1–5 bound in the controls settings (§4); each slot shows its number as a tiny `Label` overlay in the corner of the cell.

### 3.3 Minimap

- `MinimapPanel` (`PanelContainer`, `panel` stylebox) anchored bottom-right; 200×200 map `Control` with custom `_draw()` — dots for ships/POIs, `accent_danger` for hostiles, `text_dim` for neutral, `text_primary` for self.
- Zoom is two `TextureButton`s (16×16) in the footer `HBoxContainer`; sector name `Label` in `text_dim`.
- **Chaff ghosts (2026-09-20, engine spec §4.6):** blip kind `&"ghost"` — a
  dim `text_dim` dot that flickers (alpha 0.3–0.7 at 6 Hz) for the 3 s ghost
  window; never hostile-red, so ghosts are distinguishable at a glance.

### 3.4 Cargo panel

- Toggleable `PanelContainer` (default hidden), anchored to the right edge below the minimap: `Control` full-rect anchor right, script positions it under the minimap footer.
- Content: `GridContainer` 5 columns of 40×40 `TextureButton` cells (same texture states as §3.2, item art instead of weapons), plus an `HBoxContainer` footer: `Label` "CARGO 12/40" and a close `TextureButton` (16×16).
- Full-cargo state: footer label turns `accent_danger`.

### 3.5 Target reticle

- `TargetReticle` is a bare `Control` with custom `_draw()`, repositioned each frame to the target's screen position (script projects world→screen via `get_viewport().get_screen_transform()` chain from the camera node).
- Drawing: corner brackets (4 × 8 px L-shapes) in `accent_danger`, 1 px, with a target-hull micro-bar (60×4 `ProgressBar`, `show_percentage = false`) underneath bracketed by a `VBoxContainer` inside the reticle `Control`. When no target: hidden.
- `mouse_filter = IGNORE` on everything in `CenterOverlay` so the reticle never eats clicks.
- **Lock channel ring (2026-09-20, engine spec §4.1):** while the lock
  channel runs, the reticle draws a thin arc around the brackets —
  Steel Highlight `#565C63`, completing clockwise over the 1.2 s; the arc
  completes to `metal_light` and stays for the lock's lifetime. HUD API:
  `set_lock_progress(progress: float)` (empty hides).

### 3.6 Radial speedometer (ruling 19, 2026-09-20)

- Anchored bottom-centre inside `BottomLeft`'s parent column (below the
  ammo panel), a 120×120 `Control` with custom `_draw()`, `mouse_filter =
  IGNORE`.
- **Dial:** 10 segments across 270° (gap at the bottom); segment `i` filled
  with `metal_mid` when `speed_ratio ≥ i/10`, the current topmost segment
  filled `accent_danger` only while `speed_ratio > 0.9` (overdrive read).
- **Prograde needle:** a 10 px cyan line from centre at the ship's actual
  velocity bearing. **The needle cyan is the HUD's one sanctioned cyan** —
  it marks the velocity vector (navigation read, not danger), mirroring the
  shield-ripple steel exception in STYLE_BIBLE §3. `#2BE8E8` is NOT used;
  the needle colour is a new HUD-only token `accent_nav` — added to §1
  tokens with this amendment (`accent_nav = #6FB8C4`, desaturated so it
  never reads as a glow).
- **Heading marker:** a 6 px white (`bone_text`) tick at the ship's facing
  bearing on the same dial.
- HUD API: `set_speedometer(ratio: float, prograde: Vector2, heading: Vector2)`
  (angles in radians, world space); hidden while docked.

**Amendment 2026-09-24 (wave D7 — owner: "I dont get why there are two compasses
that seem to work the same?"):** the **Heading marker** bullet is **retired**.
The dial draws no heading tick; heading lives once, in §3.7's compass bay
(`ui_compass_rose` + the HDG row, same `heading` feed — the §7 API survives
unchanged). `ui_gauge_face` is re-cut with an **8-tick graduated speed scale**
(longer ticks toward the top of the 270° arc, no numbers — UI_CHROME §1.7)
instead of the uniform tick ring, so the dial reads as a speed instrument and
never as a second compass. `test_engine2_hud.gd`'s §3.6 rows move exactly where
they assert the heading tick — the yardstick moves with this amendment; the
segment/needle/overdrive rows stay byte-green. Reversal: restore the 6 px
`bone_text` tick and the old face.

### 3.7 Cockpit instrument cluster (amendment 2026-09-23, wave D6 — owner's NMS-style ask)

Replaces the bare §3.6 dial with a framed instrument cluster and adds sprite
surfaces. **§3.6's contract survives byte-identical** — `set_speedometer(ratio,
prograde, heading)`, `SEGMENTS` 10, `SWEEP` 1.5π, `OVERDRIVE` 0.9, the 120×120
gauge box and every read-back (`speedometer_ratio()`, `filled_segments()`,
`overdrive_segment()`, `needle_colour()`) — only the gauge's **surface** changes:
the painted `ui_gauge_face`/`ui_gauge_needle` sprites sit under the marks, while
the segment fill, the prograde needle and the heading tick stay code-drawn in
their tokens (`metal_mid`, `accent_nav`, `text_primary`): state-driven marks are
never baked (§3.2's "keeps textures palette-neutral" precedent). The
gauge now lives inside the cluster; the dial's old bottom-centre/bottom-left
discrepancy (`hud.gd`'s own report note) is resolved **bottom-left** (the owner's
word 2026-09-23: "all in one nice looking cockpit menu at bottom left maybe").
Reversal: move the cluster to the column foot as a bare dial (§3.6 verbatim).

- **Cluster box:** 404×216 logical, framed by `ui_cockpit_frame` (nine-slice,
  64 px band on a 192×192 master — the §10 `@2x` recipe made primary, one master,
  per the D2 ruling: no size-variant families). Reversal: 340×184 compact.
- **Layout:** left bay = gauge 120×120 (box unchanged); middle bay = compass
  96×96 rose + a 3-cell `HDG` readout beneath it; right bay = five readout rows.
- **Readout rows** (right bay), label column 34 px + digits:
  `SPD` 4 cells (u/s) — **amended 2026-09-24 (owner: "in the cockpit if all
  clocks are 4 digits make the speed 4 digits as well"); was 3 cells**,
  `HULL` 4 cells (current points), `SHLD` 4 cells (current
  points), `FUEL` 3 cells + `%` cell, `ENRG` 3 cells + `%` cell. Digit cell
  20×36 logical (7-seg aspect ≈ 1:1.8), 2 px gaps, leading blanks
  (`ui_seg_blank`) not leading zeros. Row labels 12 px `text_dim` (new §6 row
  "Instrument row label"; reversal: 14 px). Reversal on hull/shield: show %.
- **Digit semantics:** SPD = `int(round(prograde.length()))` clamped 0..9999
  (**2026-09-24 owner ruling** — SPD is 4 cells like every other row, so every
  readout row is 4 cells wide; the staged 4th-digit item is pulled forward.
  Reversal: 3 cells, clamp 0..999);
  HULL/SHLD = `int(round(current))`; FUEL/ENRG = `int(round(100 × value/max))`,
  clamped 0..100. The `%` cell lights only on the FUEL/ENRG rows.
- **State colours (digits never recolour):** danger reads exactly as §3.1/§3.1b
  but as (a) the row label turning `accent_danger` (hull < 25 %:
  `accent_danger_bright`; fuel ≤ 15 %: `accent_danger`) and (b) a script-drawn
  1 px `accent_danger` frame on the row (§3.2's on-top-frame precedent). SPD overdrive
  (`ratio > 0.9`): the needle modulates `accent_danger_bright` and the SPD row
  gets the frame. Fuel == 0: the `EMERGENCY FLIGHT` banner (§3.1b) plus the FUEL
  row frame in `accent_danger_bright`.
- **Compass:** `ui_compass_rose` rotates opposite the ship's facing
  (`-heading.angle()`), a fixed `ui_compass_lubber` triangle at top; `HDG` shows
  `int(round(rad_to_deg(heading.angle())))` mapped to 0..359. No cardinal letters
  baked (UI_CHROME §1.7 no-text law); engine `Label` cardinals are staged out.
  **Amended 2026-09-24 (owner: "The compass needs values … compass has NSWE
directions"):** N/E/S/W ship as engine `Label`s at the rose rim — r **42** from
  the rose centre, positions rotating with the rose, text upright, `N` in
  `text_primary` and E/S/W in `text_dim` (the staged-out call is reversed; the
  no-baked-text law holds — they are Labels, never art).
- New HUD read-backs (the probe precedent): `cockpit()`, `compass()`,
  `compass_heading()`, `readouts() -> Dictionary {spd, hull, shield, fuel_pct,
  energy_pct}` as drawn (post-clamp ints). **No new setters** — the cluster derives
  everything from feeds §7 already carries (speed u/s from `prograde.length()`,
  heading from `heading`, pools from `set_pool()` and the hull/shield handlers).

**Amendment 2026-09-24 (wave D7 — owner review of D6: "I dont like the cockpit
background, it looks like a computer screen while we have analog clocks etc, make
sure that everything looks analog, so they are placed on a metal panel of
something like that"; "there is overlap and generaly doesnt look too pleasing to
the eye"; "all of old HUD should be gone i think"):**

- **Instrument language (see §3.9):** every cluster surface becomes a painted
  metal instrument face. `ui_readout_glass` and `ui_cockpit_frame` retire from
  the cluster (`ui_cockpit_frame` stays in service on §3.8); the backing is the
  new full painted panel **`ui_cockpit_panel`** — one master **928×512** (2× the
  box), **no nine-slice** (the D3 1041×1087-stretched-plate defect class is
  avoided by sizing the master to the pinned box). Gauge, compass and readout
  rows mount into the panel's recessed wells. Reversal: the glass readout plate
  + nine-slice frame.
- **Box (this resolves the D6 review's R1-MED-2 as one call):** outer **464×256**
  logical, painted interior **400×192**, band **32** (the §10 `@2x` recipe's
  logical half of the 64 px master band). Reversal: 404×216 (the measured 396×190
  content overflowed its 340×152 interior — that is the defect being cured); the
  340×184 compact reversal is **dead by measurement** (cannot hold the bays).
- **Bays:** left **126** (gauge 120×120 + the battery readout beneath it), middle
  **104** (compass 96×96 + the HDG row), right **156** (the five rows at 122),
  **7 px** gutters. Reversal per bay: none needed — these are the D6 numbers plus
  the battery readout in the gauge bay's measured spare height.
- **Battery readout (left bay foot; absorbs the old §3.2 ammo panel):** one
  engine `Label` line `B1 · CANNON` (12 px `text_dim`, the §3.7 row-label style;
  rack ordinal + family resolved by the same tables the ammo panel used) + one
  **`AMMO` row**: 34 px label + **4 cells** (clamp 0..9999, leading blanks,
  `ui_seg_*`) carrying the active rack's loaded rounds on the existing ammo feed
  (§7 unchanged). Reversal: no battery readout (ammo on §3.8 only).
- **Digit fit law (the overlap cure):** every `ui_seg_*` sprite is drawn
  **fill-fitted to its 20×36 logical cell** — never at master size — on a 22 px
  cell pitch (20 + 2). `test_d7_cockpit.gd` asserts the drawn glyph rects are
  pairwise disjoint and inside their row; the blind-spot class that let the
  overlap ship dies here. Reversal: none — this is a defect cure.
- **The old HUD column dies:** §3.1's crest bars, §3.2's `AmmoPanel` and §3.4's
  cargo block are **removed from the flight HUD** (HULL/SHLD live in the cluster
  rows, ammo in the battery readout, cargo + fitted modules read on §3.8). The
  §3.3 minimap and §3.5 target reticle stay. **The §7 frozen API survives
  callable** — every frozen method keeps its signature; the widgets they drove
  are gone (S5-R1's ammo rack-ordinal MED dies with the panel). Reversal: restore
  the column widgets behind a debug flag.

**Mockup v5 approved by the owner 2026-09-24**
(`staging/mockup/out/cockpit_mockup_v5.png`, script
`staging/mockup/cockpit_mockup.py`) — three owner deltas apply on top of the
bullets above:

1. **Foot band unified:** the AMMO strip, the HDG strip and the readout stack
   share one **36 px** band at the interior foot (mockup y 370–442 at 2×): every
   readout row is 36 tall and all three elements' bottoms line up.
2. **The battery group is five lamp squares** `B1`..`B5` (**22×22**, **3 px**
   gaps, 122 wide) above the AMMO row, replacing the `B1 · CANNON` Label line.
   Lit lamp (the selected rack — the `weapon_1..5` state): dark-ember fill +
   `accent_danger_bright` border + bright label (the §3.2 active-weapon
   precedent). Unselected: `void_panel_raised` fill, `metal_dark` border,
   `text_dim` label. The lamps are the in-flight battery selector; the family
   name reads on §3.8, not here. Code-drawn — no masters.
3. **Label zone 36** (was 34) and row-label type 11 px so 4-letter labels fit;
   drums stay 20×36 on a 22 pitch.

Row containment is a hard check (the mockup's measured lit-glyph boxes at 2×,
all inside their wells): AMMO x 213–307, HDG x 481–531, ENRG x 669–806; every
foot drum group spans y 375–437 identically.

**Mockup v7 approved by the owner 2026-09-24** ("Okay looks golde"; v6: "we ditch
the compass entirely. and put instead of it two smaller clocks for FUEL and
ENERGY"; v7: "make the 7 segment screens segment go from bottom edge of top frame
to current bottom position … and space out the dials a bit"). **This block
supersedes the v5 block's bay content where they differ:**

- **The compass is gone entirely** — rose, lubber, cardinal Labels, the HDG row
  and the heading tick all retire from the cluster. `compass()` /
  `compass_heading()` survive callable as stubs (CONTRACTS §18 keeps its
  signatures; heading has no readout until a future wave wants one).
- **Middle bay = two value dials** `FUEL` and `ENRG` in the §3.6 dial language
  (270° arc of 10 thin wedges + needle + hub; name as a 12 px `Label` over the
  lower face). **36 px radius** each (72×72), centres (214, 78) and (214, 181)
  in panel coords — **23 px clear between rims**. Values:
  `round(100 × value / maximum)` 0..100 over the sweep (`maximum == 0` reads 0).
  Danger (fuel ≤ 15 %, and == 0): needle `accent_danger_bright`, lit arc
  `accent_danger` — state marks stay code-drawn.
- **Right well = full interior height** (the 7-seg screens segment runs from the
  top frame's bottom edge to the same bottom): four rows **SPD / HULL / SHLD /
  AMMO** spread evenly through it (pitch 50.7 px, row 36), bottom row in the
  foot band. The FUEL/ENRG digit rows retire (the dials carry them); **AMMO
  moves up** into the stack; the left foot keeps **only** the battery lamps band.

### 3.8 Ship status screen (amendment 2026-09-23, wave D6)

A HUD-internal overlay ("computer screen with current ship layout"), hidden by
default, in flight only (hidden while docked like §3.7). Toggled by the
`ship_status` input action — **guarded by `InputMap.has_action`**; the
`project.godot` row is orchestrator-applied at close-out (proposed key **U**;
reversal: any free key). Never routes (MENU_FLOW §3.8: signals up).

- **Box:** 720×520 logical centred modal, `ui_cockpit_frame` nine-slice body;
  close via the toggle action or a `icon_close` button (Esc stays Pause-only,
  MENU_FLOW §3.9). Reversal: 640×448.
- **Left:** the active hull's side render, 320 px wide, swapping to the
  `_damaged_side.png` cut by exactly `repairs_panel.gd`'s suffix rule when damage
  is reported (hull < max). Overlaid hardpoint markers (code-drawn, 1 px
  `metal_light`/`text_dim`) when `ShipFit.HARDPOINTS` carries the hull: thruster
  anchors as small triangles, weapon mounts as 3 px circles with a facing tick.
- **Right:** the hull's slot grid (the shipyard plate recipe, cell for cell —
  the FITTING precedent) with each fitted module's glyph and cell ref from
  `resolved_fit`/`set_hull_slots`; rows read `ModuleCatalog` names.
- **Footer:** HULL/SHLD `cur / max` (18 px HUD readout) + POWER draw / capacity.
- **Per-module damage is NOT in the sim** (measured 2026-09-23: damage is
  hull/shield only, `repairs.gd` reads hull/shield pairs; no module condition
  field exists anywhere in `game/`). v1 shows the module list + powered state;
  a module-condition model is **staged** (owner tick — it needs an
  `18_engine_spec.md` amendment, which is owner-locked).

**Amendment 2026-09-24 (wave D7 — Mockup C approved by the owner,
`staging/mockup/out/status_mockup.jpg`):** the screen restyles onto the §3.9
instrument language and **joins the D7 wave** (the D7 brief staged it — that
staging is reversed). One painted console panel **`ui_status_panel`** (master
2× the 720×520 box, no nine-slice) replaces `ui_cockpit_frame` here. Layout
(logical px — the mockup is 1:1): left well (24,60)–(300,214+...)
(276×368) carries the hull side render **aspect-fit into the well** (the old
320 px render pin is superseded by the mockup's well-fit) with the damaged-cut
swap rule unchanged; the hardpoint markers are code-drawn bone-ringed ember dots
(§3.9's state rule) over the render; right well (316,60)–(696,348) carries the
slot grid on the shipyard plate recipe — 5×3 cells 60×74 on a 72×88 pitch, the
`W1..W5` refs as 10 px Labels, fitted modules as glyph plates; a footer strip
(24,444)–(696,494) carries `HULL  cur / max`, `SHLD  cur / max`, `PWR  draw /
capacity` Labels (the fitting panel's own arithmetic, unchanged). Title
`Label` + close box top-right. Reversal: the D6 `ui_cockpit_frame` modal look.

### 3.9 Cockpit instrument language (amendment 2026-09-24, wave D7)

The owner's ruling, verbatim: "I dont like the cockpit background, it looks like
a computer screen while we have analog clocks etc, make sure that everything
looks analog, so they are placed on a metal panel of something like that." Every
cockpit-family surface obeys this language (the cluster §3.7, the battery window
§3.10, and any later instrument):

1. **Analog first.** Readouts are painted metal instrument faces: dials with
   needles, engraved compass roses, mechanical seven-segment drums (the drum
   cells are analog machinery, not screens). No glass, no screen glow, no
   holographic or CRT/LCD framing anywhere.
2. **Everything mounts on metal.** Every widget sits in a recessed well of a
   painted panel (`ui_cockpit_panel`, the §3.10 armory plates) in STYLE_BIBLE's
   painted-metal treatment: Bone/Panel-Steel palette, ember `#C8461B`/`#E8703A`
   only for danger. Bolt/rivet heads echo `ui_cockpit_frame`'s corners.
3. **No baked text.** Engraved scales are tick marks only (UI_CHROME §1.7);
   words and numbers are engine `Label`s or `ui_seg_*` cells.
4. **State is code-drawn.** Fills, needles, ticks and danger frames stay
   code-drawn in theme tokens over the painted faces (§3.2's palette-neutral
   textures precedent). Digits themselves never recolour.
5. **Everything is user-modifiable** (owner 2026-09-24: "make sure that it is
   easily modified by the user in the future, like different styles, layout
   etc"): every colour, layout metric and asset path these surfaces use lives in
   one **`CockpitStyle`** Resource (`vajb-orbit/ui/hud/cockpit_style.gd`,
   `class_name CockpitStyle`) with `@export` groups **palette** (panel/metal/
   bone/dim/ember tokens), **layout** (box, band, bay widths + gutters, row
   pitch, label zone, drum cell size, dial radii, lamp size) and **assets**
   (panel/face/plate texture paths). Defaults = this spec's numbers, shipped as
   the built-in default; dropping in `res://ui/hud/cockpit_style_user.tres`
   overrides everything with **no code edit** (surfaces load it if present).
   Reversal: hardcoded tokens (the D6 status quo).

Reversal: the D6 `ui_readout_glass` glass look (recorded in §3.7's amendment).

### 3.10 Battery selection window (ARMORY) cockpit restyle (amendment 2026-09-24, wave D7)

Owner, verbatim: "While we are designing, lets go out of the developer loop and
rework the gun battery selection window to new cockpit like one." The window is
the ARMORY pane's BATTERY RACKS group (STATION_HUB §5.11, 09 §11,
`armory_panel.gd`: `B1..B7` drop zones + INVENTORY + AMMUNITION). **Surface
only** — the transactions, drag-drop behaviour, the refusal-writes-nothing rule
and the panel contract (`status_requested`/`refresh_profile`/`focus_primary`,
STATION_HUB §12.4) are untouched; 09 §11 and CONTRACTS §17 stay the seams.

- The pane mounts as a painted metal console **`ui_armory_console`** (2× the
  pane's own measured content rect; the rect is measured in code and reported —
  nothing is invented), its three groups as recessed wells (§3.9).
- Each rack `B1..B7` is a **rack bay plate `ui_armory_rack_plate`** (2× the
  rack bay's measured rect): bolted corners, the W cells as machined slot
  recesses, and a thin mechanical readout ledge carrying the rack's SALVO cycle
  figure as `ui_seg_*` **3 cells** — **approved 2026-09-24 (Mockup A, owner:
  "Looks good")** **seconds ×100** (0.73 s reads `073`; corrected from the
  proposed ×10 by D7-C2's measurements — 0.6 s ⇒ `060`, 1.2 s ⇒ `120`, no cadence
  ⇒ blanks) with a 12 px `Label` "SALVO s". Reversal: the plain `Label` the pane
  shows today.
  **Mockup A geometry (`staging/mockup/out/armory_mockup.jpg`):** rack bays in a
  **4+3 grid**, bay **97×91** logical (194×182 at 2×), **4 slot recesses 20×22**
  per bay on a 22 pitch, `B#` + key-hint Labels at the top, engraved ledge,
  SALVO strip beneath; the selected rack's bay carries the §3.2 ember frame
  (matching the cluster's lamp). Inventory rows 22 tall (20×18 icon slot + name
  + `OWNED ×n`); ammunition rows 32 tall, danger rows per §3.1/§3.1b (label +
  1 px frame).

**Amendment 2 (2026-09-24 — the D7-R1 MED-1 ruling):** the console's canvas is
**872×956** (2× 436×478 logical) — Mockup A's rack/inventory layout plus an
ammunition well grown to **136** (2× 68) because the pane ships **six packs**
(two rows of the approved 32-tall row spec); the Mockup A "44" note was
illustrative and retires (well heights derive from content). The master mounts
**unstretched** (the D3 stretched-plate defect class): `ui_armory_console` is
re-rendered at **1744×1912** (2× the ruled canvas) and the wells sit at Mockup
A's coords plus the 136-tall ammo well. Reversal: the 872×908 one-row-ammo
canvas (which forced the 1.0529 fill-stretch R1 measured).
- INVENTORY and AMMUNITION rows ride a brushed-metal row plate
  **`ui_armory_row_plate`** — nine-slice allowed here (flat fill bands only, no
  painted detail in the stretch zone; the D3 defect class is about painted
  plates).
- Danger/insufficient/refusal states reuse §3.1/§3.1b verbatim as row
  treatments (label + 1 px code-drawn frame; digits never recolour).

## 4. Settings

Scene: `vajb-orbit/ui/screens/settings.tscn`. Root `Control` full-rect, bg `void_base` drawn by a full-rect `PanelContainer` with the `panel` stylebox (or `ColorRect` with `void_base` as first child — spec choice: `PanelContainer` for consistency).

```
Settings (Control, full rect)
├─ PanelContainer (full rect, stylebox panel)
│  └─ MarginContainer (margins 24)
│     └─ VBoxContainer
│        ├─ HBoxContainer (header)
│        │  ├─ Label "SETTINGS" (size 22)
│        │  └─ spacer (Control, EXPAND)
│        │  └─ Button "BACK"
│        ├─ TabContainer (EXPAND_FILL both axes)
│        │  ├─ Graphics (VBoxContainer)   # tab title "GRAPHICS"
│        │  ├─ Audio (VBoxContainer)
│        │  ├─ Controls (VBoxContainer)
│        │  └─ ...
│        └─ (TabContainer owns the bottom edge; no footer bar)
```

Tab titles: "GRAPHICS", "AUDIO", "CONTROLS", "INTERFACE" (interface reserved for HUD scale/opacity toggles later).

### 4.1 Graphics tab

`VBoxContainer` of setting rows; each row is an `HBoxContainer` (label left, control right, separation 16):

- Resolution — `OptionButton` (listed for completeness; `OptionButton` is a themed `Button` subclass, uses the same styleboxes)
- Display mode — `OptionButton` (windowed / fullscreen / borderless)
- V-Sync — `CheckButton`
- Render scale — `HSlider` (0.5–2.0, step 0.05) + `Label` value readout
- Shadow quality / effects quality — `OptionButton`

### 4.2 Audio tab

Same row pattern:

- Master / Music / SFX / UI volume — four `HSlider`s (0.0–1.0, step 0.01) each with a `Label` percentage. Sliders bind to audio bus volumes via `AudioServer`.

### 4.3 Controls tab — key rebinding list

```
Controls (VBoxContainer)
├─ ScrollContainer (EXPAND_FILL vertical)
│  └─ VBoxContainer (rebind rows)
│     └─ RebindRow (HBoxContainer, per action)
│        ├─ Label action name ("THRUST FORWARD")
│        ├─ spacer
│        ├─ Button key binding ("W")     # opens listen-mode
│        ├─ Button alt binding ("▲")
│        └─ Button reset ("↺")           # 24×24 TextureButton alternative
└─ HBoxContainer (footer)
   ├─ Button "RESET ALL"
   └─ spacer
   └─ Button "SAVE"
```

- Bind buttons are `Button` (not TextureButton) — text shows the current key; pressed state enters **listen mode**: the button text changes to "PRESS KEY…", next `InputEventKey`/`InputEventJoypadButton` captured via `_input`, conflicts highlight both rows' labels in `accent_danger`.
- Focus neighbours: within a row, left/right arrows walk binding buttons; `ui_up/ui_down` walk rows — the `ScrollContainer` scrolls the focused row into view (`ensure_control_visible`).
- Joypad bindings use the same buttons; event display string comes from a shared `InputEvent → display name` helper.
- Rebind rows are created from the project's action list at runtime (data-driven; the scene ships one template row).

## 5. Tooltips, Dialogs & Nine-Patch Panels

### 5.1 Tooltips

- Custom tooltip scene `tooltip.tscn`: root `PanelContainer` with `tooltip_panel` stylebox → `RichTextLabel` (`bbcode_enabled = true`, `fit_content = true`, width capped at 320 px via custom minimum size x).
- Attached via `Control.set_tooltip` replacement: a small autoload/helper that instantiates the tooltip scene and positions it offset (12, 12) from the mouse, clamped to the viewport, on `mouse_entered` with a 0.25 s delay (script-driven; Godot's default `get_tooltip()` path is bypassed because default tooltips are not themeable enough).
- Content grammar (BBCode): item name line in `text_primary` bold, stats in `text_dim`, danger warnings in `[color=#c8471f]`. Tooltip text sources come from item `Resource` data (`Resource` pattern — tooltip_string property), never hardcoded in scenes.
- Item tooltips (equipment/hangar, §5.3) additionally include the slot-type line and drag hint ("DRAG TO EQUIP").

### 5.2 Dialogs (confirm / message)

Scene: `dialog.tscn` (modal confirm/prompt, used for rebinding conflicts, selling confirmation, reset-all):

```
DialogRoot (Control, full rect, MOUSE_FILTER_STOP)     # blocks input behind it
├─ ColorRect (full rect, void_base at 60 % alpha)      # dimmer
└─ CenterContainer (full rect)
   └─ PanelContainer (min size 420×0, stylebox panel_raised)
      └─ MarginContainer (margins 16)
         └─ VBoxContainer (separation 12)
            ├─ Label title (size 18)
            ├─ Label body (autowrap, text_primary)
            └─ HBoxContainer (alignment END, separation 8)
               ├─ Button "CANCEL"
               └─ Button "CONFIRM" (danger styling: normal stylebox border accent_danger)
```

- Instantiated under `CanvasLayer` layer 20. Only one dialog at a time; the helper autoload queues requests.
- Dialogs grab focus on open (`CONFIRM` default focus) so Escape/Enter work; Escape maps to CANCEL.

### 5.3 NinePatchRect panels (hangar/equipment chrome)

The hangar and equipment screens use a textured metal-frame chrome for the main panels (bevelled plates with riveted corners — generated art), implemented as `NinePatchRect`:

- Scene `metal_panel.tscn`: `NinePatchRect` with `patch_margin_*` values baked from the source texture's frame thickness. Baseline for the generated frame texture (32 px frame in a 96×96 source): `patch_margin_left/top/right/bottom = 32`. Coding pass must confirm the actual frame width from the final texture and set all four margins to it; if the texture ships a 16 px frame, margins become 16.
- Usage: as the visual background **behind** a `PanelContainer` whose `panel` stylebox is set to a transparent `StyleBoxEmpty` — the NinePatchRect provides pixels, the PanelContainer provides layout:

```
SlotPanel (PanelContainer, stylebox_override = StyleBoxEmpty)
├─ NinePatchRect (full rect, metal frame texture, patch margins = frame width)
└─ MarginContainer (margins 24)   # content inset inside the frame
   └─ ... slot grid / list
```

- Same pattern for the dialog chrome variant (optional swap for `panel_raised`).

### 5.4 Equipment & Hangar screens

Scene: `vajb-orbit/ui/screens/hangar.tscn` (equipment is a tab/panel of hangar; single screen, two views).

```
Hangar (Control, full rect)
├─ PanelContainer (full rect, panel stylebox)         # screen background
└─ MarginContainer (margins 16)
   └─ HBoxContainer (separation 16)
      ├─ LeftColumn (VBoxContainer, EXPAND_FILL)
      │  ├─ HBoxContainer header (Label "HANGAR" / "EQUIPMENT" + credits Label)
      │  └─ ViewSwitch (HBoxContainer, two TextureButtons: HANGAR / EQUIPMENT)
      ├─ ShipPreview (Control, custom _draw of ship silhouette + equipment overlay anchors)
      │  └─ HardpointMarkers (8 × Control, positioned by data; each holds a 40×40 TextureButton slot)
      └─ RightColumn (VBoxContainer, min width 380)
         └─ MetalPanel (PanelContainer + NinePatchRect per §5.3)
            └─ MarginContainer (16)
               └─ VBoxContainer
                  ├─ HBoxContainer (filter OptionButton + search LineEdit)
                  ├─ SlotGrid (ScrollContainer → GridContainer 6 columns)
                  │  └─ ItemSlot (TextureButton 56×56) × N
                  └─ Footer (HBoxContainer: selected item stats RichTextLabel + action Buttons)
```

- **Slot grids**: `GridContainer` columns = 6 (hangar inventory) / 5 (equipment hardpoints as a grid alternative view). Each `ItemSlot` is a `TextureButton` (56×56) with the §3.2 texture states; equipped-state adds a script-drawn `accent_danger` corner triangle (armed/relevant accent only when the item is a weapon being compared).
- **Drag & drop** (hints + implementation notes for the coding pass):
  - Slots set `texture_disabled`-style dimming when a drag from an incompatible slot type hovers over them (drag preview via `Control.get_drag_data()` returning `{ "type": "item", "id": ... }` + a `set_drag_preview(TextureRect)` of the item icon at 50 % alpha).
  - `can_drop_data()` validates slot type + level; on invalid, the slot draws a 1 px `accent_danger` border (script `_draw` on hover) — this is the only sanctioned use of orange outside danger semantics, because a failed drop *is* a warning state.
  - `drop_data()` emits `item_moved(from_slot, to_slot)` up to the hangar controller (signals up).
  - Keyboard fallback: focus a slot, press Enter to "pick up", Enter on another slot to place — mirrors drag; documented in the tooltip hint line.
- **Hangar ship list** (left column, when in HANGAR view): `ItemList` (themed via `panel` + `item_selected` styles) or a `VBoxContainer` of custom rows — spec choice: `VBoxContainer` of rows for full theming control; rows are `Button`s with `alignment = LEFT`.

## 6. Font & Sizing Reference (coding checklist)

| Element | Node | Size / notes |
|---|---|---|
| Screen titles | `Label` | 22 px, `text_primary` |
| Menu button title | `Button` | 34 px Blaec, `text_primary` — menu-screen exception (MAIN_MENU_SPEC §3) |
| Section headers | `Label` | 16 px, `text_dim` |
| Body / buttons | `Button`, `Label` | 14 px |
| Tooltips | `RichTextLabel` | 13 px, width ≤ 320 |
| HUD readouts | `Label` | 18 px |
| HUD bar height | `ProgressBar` | 14 px |
| Weapon slots | `TextureButton` | 48×48 |
| Cargo slots | `TextureButton` | 40×40 |
| Inventory slots | `TextureButton` | 56×56 |
| Margins (HUD zones) | `MarginContainer` | 12 |
| Margins (screens) | `MarginContainer` | 16–24 |
| Dialog min width | `PanelContainer` | 420 |
| NinePatch margins | `NinePatchRect` | = texture frame width (32 default) |
| Focus ring | stylebox | 1 px `accent_danger_bright`, all interactive controls |
