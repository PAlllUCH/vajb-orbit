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
