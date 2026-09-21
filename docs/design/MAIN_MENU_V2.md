# Vajb Orbit - Main Menu v2 (spec for the shipping screen)

**Status:** design contract, written 2026-09-18 from the approved-look mockup
`vajb-orbit/ui/screens/_mockup_main_menu.tscn`, revised the same day after the owner's five
decisions (section 14). Supersedes the layout, motion and focus sections of
`MAIN_MENU_SPEC.md` sections 3 to 6 for this screen; everything in `UI_SPEC.md` section 1
(tokens), section 2 (theme/focus law) and `STYLE_BIBLE.md` stays binding. The mockup is
throwaway and gets deleted when `main_menu.tscn` is rebuilt to this spec.

**Revision pass (D4b, 2026-09-18).** The metal housing (`ui_panel_frame.png`) is gone from
this screen and no frame or border device replaces it; the version stamp reads
`VAJB ORBIT v0.2` in `text_primary`; the emblem stands in a lightweight header group
aligned to the plate edge; the three footer read-outs are unchanged; the vertical plate
stretch at `ui_scale` 1.4 is accepted. Renders and measurements: `.agents/gen/d4b_report.md`
and `.agents/gen/previews/d4b_menu_v2_rev_*.png`.

**Final revision (D4c, 2026-09-18).** Two owner decisions are applied and one defect is
fixed. The verb stack is scaled up about 25 percent (plates 350 x 70, emblem 50 x 58, tick
6 x 60, read-out on the theme's `HudReadout` item), the emblem is brightened with a
documented `modulate` multiplier, and the row height is now font-driven, which removes the
`ui_scale` 1.4 plate stretch and the 3 px stack gap. Section 15 records every property that
changed and what stayed; section 12 carries the row-height rule the coder must implement.
Renders and measurements: `.agents/gen/d4c_report.md` and
`.agents/gen/previews/d4c_menu_v2_*.png`.

**Art source of truth:** `ASSET_AUDIT.md` section E.1 `MENU_V2_SHORTLIST` and section F.
Every `res://` path below is from that shortlist and was verified to exist on disk
(list in `.agents/gen/d4b_report.md`).

---

## 1. Intent

The screen is the first thing a pilot sees after preflight and the last gate before the
station hub, so it has to work as a cold, deliberate piece of industrial machinery: three
riveted verbs floating in the void on a scrimmed vista. The vista behind them is the wreck
field from the last battle, still burning in one place, and the screen does not apologise
for it or cover it. The feeling this must produce is *arrival at a place that is not
welcoming but is honest*: the wordmark is scarred, the buttons are riveted plates, the only
warm colour in the frame is the wreck and the state of whatever the keyboard is touching.
Nothing is glossy, nothing is framed, nothing pulses for decoration. Every moving thing on
the screen is either a slow ambient breath (dust drift, wreck ember) or a direct answer to
the player's input (entrance, hover, focus, press).

The company mark survives the housing: one 50 x 58 neutral insignia sits above the verb
stack, flush with the plates' left edge, and carries the only brand statement on the
screen. It has no caption (section 5 explains why).

---

## 2. What changed from the Phase C menu, and why

| Phase C (`main_menu.tscn`) | v2 | Reason |
|---|---|---|
| `Title`, `MenuButtons`, `VersionLabel` placed by point anchors with fixed pixel offsets (`offset_left = -312`, `anchor_left = 0.08`, `anchor_top = 0.58`) | every region is placed by a container inside one full-rect `MarginContainer` safe area | the old screen desynced on any aspect other than the one it was eyeballed on; nothing on the new screen is positioned by a hand-tuned offset |
| verbs float directly on the backdrop | the verb plates float directly on the scrimmed vista, with a 50 x 58 insignia above them and two `void_base` scrims under them | the audit lists the insignia as unwired art worth spending; the scrims (not a frame) carry legibility; the owner's revision decision 1 removed the housing |

### 2.1 What the revision pass changed (owner decisions, all five applied)

| Owner decision | Effect on this spec |
|---|---|
| 1. Drop the metal housing panel | `RailPanel`, `RailFrame`, `RailContent`, `RailStack`, the three 6 px row tails, the `StyleBoxEmpty` rail style and the `ui_panel_frame.png` reference are gone from the scene. No substitute frame, and the panel frame is not used anywhere else on this menu. The plates now sit at x 118..398 with the 280 px plates of that pass (x 118..468 after the D4c scale-up); the left edge, x 118, is the number that matters. Sections 3, 4, 7, 8 and 13 reflect this. |
| 2. `VAJB ORBIT v0.2`, brighter | the string changed and the stamp's `font_color` is now `Tokens/text_primary` (measured 11.9:1 against the pixels behind it, floor 4.5:1). The `Version` theme item (13 px) is unchanged; the colour is a node-level override read from the theme token in code. Section 6. |
| 3. Keep the three footer read-outs | unchanged, byte for byte, in the mockup's `READOUT` array and in section 13.3. |
| 4. Accept the vertical plate stretch at `ui_scale` 1.4 | recorded in section 12, with the measured magnitude (1.196x, about 20 percent) and the reason. **Superseded by D4c**: the scale-up puts the row height (70 px) above the font-driven plate minimum at 1.4 (67 px), so the stretch and the 3 px gap are gone. Sections 12 and 15. |
| 5. Keep the insignia emblem | the emblem stays, re-composed as a lightweight header group with no panel behind it, its left edge flush with the plate edge (118 px). Section 5. |

---

## 3. Composition

Base render target 1920 x 1080 (`project.godot` `display/window/size/viewport_*`),
stretch `canvas_items`, aspect `expand`. Every box below was read from the running scene
(`Control.get_global_rect()` dump, `.agents/gen/d4c_report.md` section 3 and
`.agents/gen/d4b_report.md` section 3.3), not derived.

### 3.1 The grid

| Region | Carrier | Anchor preset / container | `size_flags` | `custom_minimum_size` | Box at 1920 x 1080 |
|---|---|---|---|---|---|
| Screen root | `MockupMainMenu` -> `MainMenu`, `Control` | preset 15 (full rect), `grow_*` = 2 | n/a | n/a | 0..1920 x 0..1080 |
| Safe area | `SafeArea`, `MarginContainer` | preset 15 | n/a | n/a | x 96..1824, y 64..1032 |
| Bands | `Bands`, `VBoxContainer` | child of `SafeArea`, `layout_mode = 2` | h / v fill (default) | none | 1728 x 968 |
| Header band | `HeaderBand`, `HBoxContainer` | child of `Bands` | `vertical = 0` (shrink begin) | none | y 64..240 (176 tall) |
| Logo | `Logo`, `TextureRect` | child of `HeaderBand` | `h = 0` (shrink begin), `v = 4` (shrink centre) | `(560, 176)` | x 96..656 |
| Middle band | `MiddleBand`, `HBoxContainer` | child of `Bands` | `vertical = 3` (expand fill) | none | y 240..1006 (766 tall) |
| Command column | `CommandColumn`, `VBoxContainer`, separation 16 | child of `MiddleBand` | `h = 0`, `v = 4` (shrink centre) | 372 x 312 (content) | 372 x 312 at (96, 467) |
| Middle spacer | `MiddleSpacer`, `Control` | child of `MiddleBand` | `h = 3` (expand fill) | none | x 468..1824 |
| Footer band | `FooterBand`, `HBoxContainer`, separation 24 | child of `Bands` | `vertical = 8` (shrink end) | none | y 1006..1032 (26 tall) |
| Read-out | `FocusReadout`, `Label` | child of `FooterBand` | `h = 3`, `v = 4` | none | x 96..1700, ink measured (97, 1013, 314, 1026) |
| Version stamp | `VersionLabel`, `Label` | child of `FooterBand` | `h = 8` (shrink end), `v = 4` | none | 100 x 18 at (1724, 1010), ink measured (1724, 1015, 1823, 1027) |

The command column's own grid, top to bottom:

| Region | Node | Container | `size_flags` | Min size | Box at 1920 x 1080 |
|---|---|---|---|---|---|
| Header row | `CommandHeader`, `HBoxContainer`, separation 16 | child of `CommandColumn` | `v = 0` | 72 x 58 | x 96..468, y 467..525 |
| Header gutter | `HeaderGutter`, `Control` | child of `CommandHeader` | `h = 0` | `(6, 0)` | x 96..102 |
| Emblem | `InsigniaBadge`, `TextureRect` | child of `CommandHeader` | `h = 0`, `v = 4` | `(50, 58)` | x 118..168, ink measured (119, 468, 167, 522) |
| Verb stack | `VerbStack`, `VBoxContainer`, separation 14 | child of `CommandColumn` | `v = 0` | 372 x 238 | x 96..468, y 541..779 |
| One verb row | `PlayRow` / `OptionsRow` / `ExitRow`, `HBoxContainer`, separation 16 | child of `VerbStack` | `v = 0` | 70 tall | 372 x 70, tops at 541 / 625 / 709 |
| Tick | `PlayTick` / `OptionsTick` / `ExitTick`, `ColorRect` | child of its row | `h = 0`, `v = 4` | `(6, 60)` | x 96..102, measured accent bbox x 96..101, y 546..605 |
| Plate | `PlayButton` / `OptionsButton` / `ExitButton`, `menu_button.tscn` instance | child of its row | default fill | `(350, 70)` | x 118..468, measured plate band x 118..467 |

**The gutter is not decoration.** `HeaderGutter` occupies the same 6 px column as the three
focus ticks and uses the same 16 px separation, so the emblem's left edge lands on x 118,
exactly the plate column's left edge (plates x 118..468 at 1.0). It carries no art and never
receives input. The plates are 28 px left of where they sat inside the housing. The D4c
scale-up made the column 312 px tall (58 + 16 + 238) and moved the rows up: tops are now
541 / 625 / 709 instead of 559 / 629 / 699, because the taller column still centres in the
766 px middle band (the band lost 6 px when the footer band grew from 20 to 26 px, the
read-out having moved to the 18 px `HudReadout` item). The placement rule is unchanged: the
column is centred in the band and nothing on this screen is positioned by a hand-tuned
offset.

### 3.2 Responsive rule per region

`canvas_items` + `expand` computes `scale = min(window_w / 1920, window_h / 1080)` and the
viewport is `window / scale`, so exactly one axis keeps its 1920 or 1080 extent and the
other gains room. Consequences, in order of how they are carried:

- **Uniform scale only** (1600 x 900, 2560 x 1440, any 16:9 window): the viewport stays
  1920 x 1080 and every number above is unchanged; the whole screen is scaled by 0.833 or
  1.333 by the stretch. Nothing else happens. Verified at 1600 x 900: every measured ink box
  is the 1920 x 1080 box multiplied by 0.8333 (section 5 of the D4c report, read-out ink
  97..313 x 1013..1026 -> 81..261 x 845..855, stamp 1724..1822 -> 1437..1520, plate band
  x 118..467 -> x 98..389).
- **Extra width** (21:9, e.g. a 2560 x 1080 window: viewport 2560 x 1080, scale 1.0): the
  extra 640 px all goes to `MiddleSpacer`, so every left-anchored region keeps its x in
  viewport pixels (the console still at 96..468) and the vista is cropped vertically (the
  `KEEP_ASPECT_COVERED` backdrop shows 1176 of its 1453 drawn rows, the plate height after
  §16 item 2's 96 px slack). The footer read-out
  keeps the left safe margin and the version stamp stays pinned to the right safe margin.
  Verified: the 21:9 windowed run rendered exactly this.
- **Extra height** (4:3, e.g. a 1440 x 1080 window: viewport 1920 x 1440, scale 0.75): the
  extra 360 px all goes to `MiddleBand`, so the column stays vertically centred in the band
  and moves 180 px down relative to the canvas top; `HeaderBand` and `FooterBand` stay
  pinned to the safe area's top and bottom edges; the vista is cropped horizontally
  (329 px of the 2602 drawn columns off each side). Note the wreck therefore lands at
  about 0.89 of the viewport width instead of 0.79, which is why the ember pulse must be
  re-anchored on resize (section 8).
- **Never**: the safe margins (96 / 64 / 96 / 48), the plate size, the tick size, the emblem
  size (50 x 58) or the logo size are scaled by the layout. They are fixed pixel values that
  the stretch scales once, uniformly. No `size_flags` anywhere asks for a proportional
  split except `MiddleSpacer` (all horizontal slack) and `MiddleBand` (all vertical slack).

### 3.3 Proportions

Everything above is authored in pixels on the 1920 x 1080 canvas; the proportions are a
consequence, and they are what the layout preserves when the aspect changes. As fractions
of the 1920 x 1080 canvas:

| Landmark | Fraction of width | Fraction of height |
|---|---|---|
| Safe-area margins | 5.0 % left and right | 5.9 % top, 4.4 % bottom |
| Safe-area content box | 90.0 % | 89.6 % |
| Wordmark | 29.2 % (x 5.0 % to 34.2 %) | 16.3 % (y 5.9 % to 22.2 %) |
| Command column | 19.4 % (x 5.0 % to 24.4 %) | 28.9 % (y 43.2 % to 72.1 %) |
| Verb plate column | 18.2 % (x 6.1 % to 24.4 %) | 22.0 % (y 50.1 % to 72.1 %) |
| Footer text line | 5.0 % to 94.8 % | y 93.1 % to 95.6 % |

Read as composition: the left 24 percent of the frame is the console, the top 22 percent
carries the wordmark, the bottom 6 percent carries status text, and the remaining 76 x 72
percent is the vista, whose single warm point (the wreck) sits at (0.79, 0.62) of the
frame, to the right of the console and below the wordmark, so it never competes with
either. Removing the housing removed the only rectangle in the frame: the plates are now
the only hard-edged shapes on the screen, and the eye goes to the wreck first and the
verbs second, in that order.

---

## 4. Node tree (exact)

```
MainMenu (Control, full rect preset 15, grow 2/2, theme = vajb_theme.tres, script = main_menu.gd)
├─ BackdropLayer (Control, preset 15, grow 2/2, mouse_filter IGNORE, clip_contents true)
│  ├─ Backdrop (TextureRect, unique %Backdrop, preset 15, offsets +24 right/bottom, mouse_filter IGNORE,
│  │           texture env_menu_bg, expand_mode EXPAND_IGNORE_SIZE, stretch_mode KEEP_ASPECT_COVERED)
│  │  └─ EmberPulse (TextureRect, unique %EmberPulse, anchors l/t/r/b = 0.791/0.618/0.791/0.618,
│  │                  offsets -250/-250/+250/+250, material CanvasItemMaterial blend_mode ADD,
│  │                  modulate (1,1,1,0.25), expand_mode EXPAND_IGNORE_SIZE, mouse_filter IGNORE)
│  ├─ LeftScrim (TextureRect, unique %LeftScrim, preset 15, mouse_filter IGNORE, expand_mode EXPAND_IGNORE_SIZE)
│  └─ BottomScrim (TextureRect, unique %BottomScrim, preset 15, mouse_filter IGNORE, expand_mode EXPAND_IGNORE_SIZE)
├─ GrainLayer (TextureRect, preset 15, mouse_filter IGNORE, modulate (1,1,1,0.08), texture grain.tres,
│              expand_mode EXPAND_IGNORE_SIZE, stretch_mode TILE, texture_repeat ENABLED)
├─ SafeArea (MarginContainer, unique %SafeArea, preset 15, mouse_filter IGNORE,
│             margins left 96 / top 64 / right 96 / bottom 48)
│  └─ Bands (VBoxContainer, separation 0, mouse_filter IGNORE)
│     ├─ HeaderBand (HBoxContainer, size_flags_vertical 0, mouse_filter IGNORE)
│     │  └─ Logo (TextureRect, unique %Logo, min (560,176), size_flags h0 v4, mouse_filter IGNORE,
│     │           texture AtlasTexture(logo_vajb_orbit, Rect2(44,707,1961,615), filter_clip true),
│     │           expand_mode EXPAND_IGNORE_SIZE, stretch_mode KEEP_ASPECT_CENTERED)
│     ├─ MiddleBand (HBoxContainer, size_flags_vertical 3, mouse_filter IGNORE)
│     │  ├─ CommandColumn (VBoxContainer, separation 16, size_flags h0 v4, mouse_filter IGNORE)
│     │  │  ├─ CommandHeader (HBoxContainer, unique %CommandHeader, separation 16,
│     │  │  │                 size_flags_vertical 0, mouse_filter IGNORE)
│     │  │  │  ├─ HeaderGutter (Control, min (6,0), size_flags h0, mouse_filter IGNORE)
│     │  │  │  └─ InsigniaBadge (TextureRect, unique %InsigniaBadge, min (50,58), size_flags h0 v4,
│     │  │  │                   mouse_filter IGNORE, modulate set from EMBLEM_BRIGHTEN at ready,
│     │  │  │                   texture ui_insignia_neutral, expand_mode EXPAND_IGNORE_SIZE,
│     │  │  │                   stretch_mode KEEP_ASPECT_CENTERED)
│     │  │  └─ VerbStack (VBoxContainer, separation 14, size_flags_vertical 0, mouse_filter IGNORE)
│     │  │     ├─ PlayRow (HBoxContainer, separation 16) -> PlayTick, PlayButton
│     │  │     ├─ OptionsRow                       -> OptionsTick, OptionsButton
│     │  │     └─ ExitRow                          -> ExitTick, ExitButton
│     │  └─ MiddleSpacer (Control, size_flags_horizontal 3, mouse_filter IGNORE)
│     └─ FooterBand (HBoxContainer, size_flags_vertical 8, separation 24, mouse_filter IGNORE)
│        ├─ FocusReadout (Label, unique %FocusReadout, size_flags h3 v4, mouse_filter IGNORE,
│        │                theme_type_variation HudReadout)
│        └─ VersionLabel (Label, unique %VersionLabel, theme_type_variation Version,
│                        size_flags h8 v4, text "VAJB ORBIT v0.2", mouse_filter IGNORE)
└─ QuitStandIn (Control, unique %QuitStandIn, preset 15, visible false)   [mockup only, see section 10]
   ├─ EscScrim (ColorRect, unique %EscScrim, preset 15, mouse_filter IGNORE, colour set from the theme)
   └─ QuitCenter (CenterContainer, preset 15, mouse_filter IGNORE)
      └─ QuitPanel (PanelContainer, min (420, 0))
         └─ QuitMargin (MarginContainer, margins 16)
            └─ QuitStack (VBoxContainer, separation 12)
               ├─ QuitTitle (Label, theme_type_variation DialogTitle, "QUIT SESSION")
               ├─ QuitBody (Label, "END THE SESSION AND RETURN TO THE DESKTOP")
               └─ QuitActions (HBoxContainer, separation 8, alignment END)
                  ├─ QuitCancelButton (Button, unique %QuitCancelButton, "CANCEL")
                  └─ QuitConfirmButton (Button, unique %QuitConfirmButton, "QUIT")
```

`PlayButton`, `OptionsButton`, `ExitButton` are instances of
`res://ui/components/menu_button.tscn` (`Control` -> `Glow` -> `Button` with
`theme_type_variation = &"MenuButtonPlate"`). Nothing in this design requires a new
button component; the existing one already carries the plate states, the breathing idle
border, the hover halo, the press scale and the focus ring. **The component's own
`custom_minimum_size` is (280, 56), so every instance must override it: (350, 70) on this
screen (section 15.1). The mockup sets it per instance; the shipping scene must do the same,
or the component must be updated for every other screen at the same time.**

Unique names: `%Backdrop`, `%EmberPulse`, `%LeftScrim`, `%BottomScrim`, `%Logo`,
`%CommandHeader`, `%InsigniaBadge`, `%PlayTick`, `%OptionsTick`, `%ExitTick`, `%PlayButton`,
`%OptionsButton`, `%ExitButton`, `%FocusReadout`, `%QuitStandIn`, `%EscScrim`,
`%QuitCancelButton`, `%QuitConfirmButton`. In the shipping screen the mockup-only nodes are
dropped (section 10).

**Gone in this revision** (do not rebuild them): `RailPanel` (`PanelContainer` with a
`StyleBoxEmpty` override), `RailFrame` (`NinePatchRect` over `ui_panel_frame.png`, 7 px
patch margins), `RailContent` (28 px padding), `RailStack`, `RailHeader`, `CommandCaption`
(`COMMAND`), and the three 6 px `*Tail` spacers that only existed to optically centre the
plates inside a 380 px housing. The scene no longer references `ui_panel_frame.png` at all.

---

## 5. Type scale

| Element | Node | Theme item / variation | Size | Colour | Why this item |
|---|---|---|---|---|---|
| Wordmark | `Logo` | none (art) | 560 x 176 | art | the hero title of this screen is the metal lockup, not type |
| Verbs PLAY / OPTIONS / EXIT | inner `Button` of each `menu_button.tscn` | `MenuButtonPlate` | 34 | `text_primary` | frozen by `IMPLEMENTATION_PLAN.md` section 3.11 / 9.5; measured 8.1:1 peak over the plate metal |
| Focus read-out | `FocusReadout` | `HudReadout` (`font_sizes/font_size` 18, `colors/font_color` `text_primary`) | 18 | `text_primary` | a one-line status that must stay readable over the vista; measured 12.08:1. It grows with the verb stack (section 15.1): 17.5 px was asked for, and the closest existing item is `HudReadout` at 18 px (the theme's readout item, the 18 px row in `UI_SPEC.md`'s type scale), so the achieved growth is 1.286x rather than 1.25x |
| Version stamp | `VersionLabel` | `Version` | 13 | `Tokens/text_primary` via a node override | `Version` is the frozen 13 px stamp item; the owner's revision decision 2 requires 4.5:1, which `text_dim` cannot reach under the grain (section 6), so the stamp's own `font_color` is overridden from the existing `text_primary` token at runtime. No hex, and no new theme item. |
| Quit stand-in title | `QuitTitle` | `DialogTitle` | 18 | `text_primary` | `UI_SPEC.md` section 5.2 |
| Quit stand-in body | `QuitBody` | base `Label` | 14 | `text_primary` | dialog body |
| Quit stand-in buttons | `QuitCancelButton`, `QuitConfirmButton` | base `Button` | 14 | `text_primary` | `UI_SPEC.md` section 5.2 uses plain `Button`s in dialogs, not menu plates |

**The `COMMAND` caption is deliberately gone.** It was the `SectionHeader` 16 px `text_dim`
label beside the emblem. With the housing removed it labelled a console that no longer
exists, and it measured 3.86:1 against the scrimmed vista behind it (peak ink 115, local
background 21.4), below the 4.0:1 floor `UI_SPEC.md` section 1 documents for `text_dim` and
well below the 4.5:1 the owner required of the stamp in the same pass. It was removed rather
than brightened, because brightening it would be a second theme change the owner did not ask
for. If it is wanted back, it needs the same treatment as the stamp (a brighter token), see
section 14.

**Deliberately unused.** `HeroTitle` (48): the wordmark art owns the hero role; a 48 px
text title beside it would be a second, competing title. `SectionHeader` (16): its only
customer was the removed caption; the theme item stays for other screens. `StationButton`,
`StationPanelTitle`, `StationValue`, `StationCaption`: those are station-hub items
(`THEME_AUDIO_EXTENSION.md` section 2.1) and none of them describes a menu surface.
`ScreenTitle` (22): no screen title text exists on this screen.

**No per-node font sizes anywhere.** Every size above is a theme item, so `ui_scale`
reaches all of them (section 12). Nothing in the scene or the script calls
`add_theme_font_size_override`. The one node-level override on this screen is the stamp's
`font_color`, and it is read from the theme. The read-out's growth (section 15.1) is an item
selection, not an override: it moves from the base `Label` item to `HudReadout`, and both are
in `Router.FONT_SIZE_ITEMS`, so the accessibility scale still reaches it.

---

## 6. Legibility, measured

Contrast ratios below are computed from the rendered 1920 x 1080 frame (WCAG relative
luminance, `(L1+0.05)/(L2+0.05)`), not from the token values in isolation. "Local
background" is the median of the pixels in the same region with the text pixels excluded
(details and raw boxes in `.agents/gen/d4c_report.md` section 4 and
`.agents/gen/d4b_report.md` section 3.4).

| Text | Rendered ink box | Ink peak (sRGB luma) | Local background | Measured contrast | Floor |
|---|---|---|---|---|---|
| `FocusReadout` (18 px `text_primary`) | (97, 1013, 314, 1026) | 208.1 | 18.9 | **12.08:1** peak and ink mean | 12.9:1 on pure `void_base` |
| Verb labels (34 px `text_primary`) | PLAY glyphs, window x 210..330, y 545..600 at 1.0 | 208.1 | 53.9 (plate metal) | **7.85:1**, identical at 1.0, 1.2 and 1.4 (the sampling window moves it between 7.8 and 9.0) | 8.9:1 on pure plate token |
| `VersionLabel` (13 px `text_primary`) | (1724, 1015, 1823, 1027) | 208.1 | 20.5 | **11.89:1** peak, 11.43:1 ink mean | 4.5:1 (owner) |
| Emblem art (graphic, brightened) | (119, 468, 167, 522) | 255.0 (clipped) | 23.6 | **17.81:1** peak, 8.86:1 at the p90 ink; the footprint median is luminance 63.6, which is 1.73:1 and is the art's own tonality (section 15.3) | n/a (graphic) |
| Wordmark art | ink x 101..648, y 64..224 | 246 (rim highlight) | 26.2 | **16.08:1** at the highlights; the letterforms' *mean* ink is luminance 80, about 2.5:1, which is the art's own design | n/a (graphic) |

Three measured facts the coder needs:

1. **The stamp's fix is a token change, and it clears the floor with 7 points of headroom.**
   `text_dim` is luminance 115, which caps at 4.17:1 even on a fully black backing; under the
   grain lift it measured 3.88:1 in the first pass. `text_primary` (luminance 208) over the
   same pixels measures 11.89:1. The owner accepted `text_primary`; the token is applied to
   the stamp's own `font_color` and no other text changed colour.
2. **The scrims are doing measurable work.** In the console band the raw backdrop's 99th
   percentile is 29.5; composited through a 0.55 `void_base` scrim it falls to 16.5, which is
   what brings dim text back to the 4.0 floor (`UI_SPEC.md` section 1). The scrim's measured
   effect on the left column is a 15 to 35 percent reduction of the backdrop's luminance
   depending on x (alpha 0.62 at x = 0, 0 at x = 0.68 of the width).
3. **The film grain lifts the whole screen by about +10 luminance.** Measured: an unscrimmed
   backdrop patch of mean 18.98 renders at 28.66; a scrimmed patch of raw 15.78 renders at
   21.53, which fits `composite = scrim(raw) + grain_lift` with `grain_lift = 0.08 x 127 =
   10.2` within 0.5 luminance across four regions. This is why every `text_dim` label on this
   screen sits at 3.9 to 4.1:1 and nothing dimmer than `text_primary` can be asked to clear
   4.5:1. The owner declined the grain change, so the grain stays at 0.08 and the rule for
   this screen is: **`text_primary` for anything that must clear 4.5:1, `text_dim` only for
   large or decorative labels.**
4. **The emblem's highlights clear the floor, its body does not, and that is the art.**
   Measured against the actual backdrop-plus-grain behind the badge (median luminance 23.6 at
   1.0): the brightened emblem's peak highlight is 17.81:1 and its p90 ink 8.86:1, both clear
   of the 4.5:1 floor; its footprint median is luminance 63.6, which is 1.73:1, because
   `ui_insignia_neutral.png` is itself a dark asset (ink median 34.5, mean 37.9 of 255). A
   `modulate` multiplier is a linear multiply, so lifting the body to 4.5:1 would need a gain
   of about 11x and would clip the whole stamp to white. Section 15.3 records the value used,
   the achieved ratios and the shortfall.

---

## 7. Art map

| Role | `res://` path | Size in scene | Blend | Why it earns its place |
|---|---|---|---|---|
| Full-screen backdrop | `assets/env/env_menu_bg.png` | `Backdrop` rect 2016 x 1176 (1920 x 1080 + 96 px of drift slack), `KEEP_ASPECT_COVERED` from the 2048 x 1152 source | normal (RGB, opaque) | audited as the vista with the burning wreck at anchored (0.792, 0.618) and the correct warmth budget; the drift wants the 96 px of slack |
| Wreck ember pulse | `assets/fx/fx_ember_pulse.png` | 500 x 500 box centred on the wreck, `modulate.a` 0.25 to 0.45 | **additive** (`CanvasItemMaterial.blend_mode = 1`); the file is RGB with no alpha, so additive is the only correct blend | it is the single accent point the `STYLE_BIBLE.md` section 7.4 asks for, and it is the only thing on the screen that moves without input other than the drift |
| Company insignia | `assets/ui/ui_insignia_neutral.png` | `InsigniaBadge`, 50 x 58 box, `KEEP_ASPECT_CENTERED`, ink measured (119, 468, 167, 522), drawn at `modulate` = `EMBLEM_BRIGHTEN` (2.0) | normal (RGBA) | the screen is pre-login, so of the four insignia the neutral one is the only correct choice; after the housing was dropped it is the screen's only brand mark and the header group's only content. The multiplier is the owner's D4c decision 2 and is applied in the mockup's `_ready()` (section 15.3): the art is dark by design, so a brightener has to come from the node, not the theme. Anomaly C3: it ships with a white matte fringe (outer alpha band luminance 212 to 252) and the multiplier clips it to 255; the defringe pass in audit recommendation 4 must land before this is treated as colour-accurate. Measured highlights reach 17.81:1 after the brightening, so it reads without the frame. |
| Title lockup | `assets/ui/logo_vajb_orbit.png` | `AtlasTexture` region `Rect2(44, 707, 1961, 615)`, `filter_clip = true`, drawn 560 x 176 | normal (RGBA) | the frozen Phase C crop, verified to keep the drop shadow (12 px pad) and to contain the ember crack that ties the wordmark to the wreck |
| Verb chrome, 4 states | `assets/ui/ui_button_plate_normal.png`, `_hover.png`, `_pressed.png`, `_disabled.png` | 350 x 70, drawn from the 280 x 56 art as a **uniform 1.25x stretch**, via the theme's `MenuButtonPlate` `StyleBoxTexture`s | normal (RGBA) | already themed and audited as 1:1 with the menu button size; the plates are the only painted detail the verbs need, and after the housing was dropped they are the only chrome on the screen. The theme's plate `StyleBoxTexture`s carry no patch margins (only the panel frame is a nine-patch, at 8 px), so the whole art including its painted bevel scales with the box; the screen's 1 px border is the component's own focus ring, which is size-independent and measured at exactly 1 px at 1.0, 1.2 and 1.4 (section 15.4). |
| Film grain | `ui/theme/grain.tres` (`NoiseTexture2D`) | full rect, `TILE` + `texture_repeat = ENABLED`, `modulate.a = 0.08` | normal | `STYLE_BIBLE.md` section 4 asks for grain on every frame; a texture, not a generated file, so there was nothing to source |
| Left scrim, bottom scrim | none (built in the spec's script from the `Tokens/void_base` colour) | full rect each | normal | the legibility device of section 6, item 2. It cannot live in the theme (a `Theme` carries no gradient texture) and it may not be a hex literal, so it is built from the token at runtime |

**`ui_panel_frame.png` is off this screen for good** (owner decision 1). It is not used by
the menu, no other node takes its place, and nothing new was drawn to fill the gap. Two
consequences to keep straight: the audit's "chrome" role is knowingly given up here, and the
anomaly C1 trap (the theme's `PanelRaised` bakes 32 px patch margins on a 7 px frame) no
longer has any bearing on this screen, though it still applies to the station hub's panels
until brief G3 regenerates the file.

`assets/ui/ui_backdrop_login.png` was considered as the v2 backdrop (audit E.1's mood
alternative, mean luminance 37.5, safer text contrast) and rejected: `STYLE_BIBLE.md`
section 7.4 specifies the main menu background as the wreck-strewn vista, and the login
plate contains no warm pixel, so the screen would lose its single accent and its ember
pulse anchor. `ui_backdrop_hangar.png` stays reserved for the station hub.

---

## 8. Motion table

Every row is a `Tween` created on the owning node (the screen, or `menu_button` for its
own rows). No UI node runs `_process`. Tweens are killed in `_exit_tree()`.

| Element | Property | From | To | Duration | Transition | Easing | Trigger |
|---|---|---|---|---|---|---|---|
| `Backdrop` | `position` | (0, 0) | (-96, -96) | 20 s | SINE | IN_OUT | ambient loop, ping-pong (the vista is not seamless, so it must not wrap) |
| `EmberPulse` | `modulate:a` | 0.25 | 0.45 | 4 s | SINE | IN_OUT | ambient loop, ping-pong, 8 s period |
| `Logo` | `modulate:a` | 0 | 1 | 0.40 s | SINE | OUT | entrance, t = 0 |
| `Logo` | `scale` | (1.03, 1.03) | (1, 1) | 0.55 s | CUBIC | OUT | entrance, t = 0 |
| `CommandHeader` | `modulate:a` | 0 | 1 | 0.30 s | SINE | OUT | entrance, t = 0.10 s |
| `CommandHeader` | `scale` | (0.99, 0.99) | (1, 1) | 0.45 s | CUBIC | OUT | entrance, t = 0.10 s |
| Verb i (0, 1, 2) | `modulate:a` | 0 | 1 | 0.26 s | SINE | OUT | entrance, t = 0.30 + 0.10 i s |
| Verb i | `scale` | (0.97, 0.97) | (1, 1) | 0.36 s | CUBIC | OUT | entrance, t = 0.30 + 0.10 i s |
| Tick i | `modulate:a` | current | 1 | 0.14 s | SINE | OUT | verb i takes focus |
| Tick i | `modulate:a` | current | 0 | 0.10 s | SINE | OUT | verb i loses focus |
| Verb plate | border colour | `metal_mid` | `metal_light` | 4 s ping-pong | LINEAR method (cosine phase) | n/a | idle loop, per-instance phase offset within +/- 0.6 s (`menu_button.gd`) |
| `Glow` underlay | `visible` | false | true | instant | n/a | n/a | mouse hover only (`menu_button.gd`); 6 px `menu_glow` halo |
| Verb component | `scale` | 1 | 0.98 then 1 | 0.08 s each way | SINE | OUT | `button_down` / `button_up` (`menu_button.gd`) |
| `FocusReadout` | `text` | previous line | the focused verb's line | instant | n/a | n/a | focus change; the motion is carried by the tick and the ring, a status line should not fade |
| `FocusReadout` | `text` | the verb's line | the intent line | instant, held 1.6 s | n/a | n/a | verb activated (mockup only, section 10) |
| `QuitStandIn` | `modulate:a` | 0 | 1 | 0.12 s | SINE | OUT | Esc opens the stand-in |
| `QuitStandIn` | `modulate:a` | 1 | 0 | 0.12 s | SINE | OUT | Esc, CANCEL or QUIT closes it |

Entrance timing: fully presented at **0.86 s** (0.30 + 0.20 + 0.36). The backdrop and the
scrims are at full opacity from frame 0, so a screenshot taken at any time shows a
presentable screen; only the logo, the header group and the plates animate in.

Implementation constraints that shaped this table:

- Containers own the `position` and `size` of their children, so the entrance never
  tweens `position` on a container child. It tweens `modulate:a` (always safe) and
  `scale` (containers do not write scale), and it sets `pivot_offset = size * 0.5` on each
  scaled node once layout is valid.
- The header group is `CommandHeader`, an `HBoxContainer` two levels inside `MiddleBand`;
  scaling it is safe for the same reason, and it is what makes the emblem and the plates
  share one left edge at rest.
- The raw `backdrop` drift is the only `position` tween, and `Backdrop` is a child of a
  plain `Control`, so nothing overwrites it.
- The ember pulse is a child of `Backdrop` so it drifts with the plate and stays on the
  wreck. Anchoring it to the screen would slide it off at every aspect (section 3.2).
- The pulse's anchor is computed per resize, because `KEEP_ASPECT_COVERED` crops the
  vista differently per aspect. The formula (in the mockup's `_reanchor_ember`) is: with
  `cover = max(rect.w / 2048, rect.h / 1152)`, `drawn = (2048, 1152) * cover`,
  `origin = (rect - drawn) / 2`, position `= origin + drawn * (0.791, 0.618) - size / 2`.
  Verified numerically at 1920 x 1080: the computed pulse centre is (1543, 682) and the
  measured warm centroid of the rendered wreck is (1544, 677). The audit's literal
  `(0.791, 0.618)` anchor is correct **only** at 16:9 (at 4:3 the wreck sits at about
  0.89 of the width and an anchored pulse misses by about 190 px on a 500 px sprite).

---

## 9. Focus and input

| Input | Behaviour |
|---|---|
| Enter / Space (`ui_accept`) | activate the focused verb |
| Tab / Shift+Tab | next / previous verb in container order: PLAY -> OPTIONS -> EXIT |
| Up / Down arrow | same as Tab (vertical container default) |
| Esc (`ui_cancel`) | if no overlay is open: `overlay_requested(&"quit_confirm", {})`. If an overlay is open, the overlay owns it (`dialog.gd` maps Esc to CANCEL) and the menu ignores it while `Router.overlay_depth() > 0` |
| Mouse motion | hovering a verb grabs focus on it, so the tick, the read-out and the plate state follow the pointer and there is only ever one "current" verb |
| Mouse click | press feel (0.98 scale over 0.08 s, hover halo dropped, pressed plate art) then activate |
| Gamepad | D-pad / left stick = arrows, A = `ui_accept`, B = `ui_cancel`; no shoulder groups exist because there is one container |

Focusable nodes, in order: `PlayButton`, `OptionsButton`, `ExitButton`, then the stand-in
dialog's `QuitCancelButton`, `QuitConfirmButton` while it is visible. Labels, the read-out,
the stamp, the scrims, the emblem and the header gutter take no focus
(`mouse_filter = IGNORE` on every decorative node; Godot skips invisible subtrees, so the
stand-in's buttons are not reachable while it is hidden). `HeaderGutter` is a bare `Control`
with `mouse_filter = IGNORE`: it aligns the emblem and is not a hit target.

Default focus on entry is PLAY. On overlay pop, focus returns to the verb that opened the
overlay (Phase C hard-coded EXIT for `quit_confirm`; generalise it by remembering the
focused verb index when a verb emits an overlay intent, which still satisfies
`MAIN_MENU_SPEC.md` section 6 and also fixes the OPTIONS path).

**Why the focus state is unmistakable and why it is not colour alone.** Three cues, two of
them geometric: (1) the component's 1 px `accent_danger_bright` ring, which at 1920 x 1080
on a 55 cm wide display viewed at 1 m is about 1.1 arcmin wide, resolvable but thin;
(2) the 6 x 60 px tick in the gutter, 6 px of that across, about 6.4 arcmin, plus a change of silhouette;
(3) the read-out line changing text. Hover, by contrast, is the 6 px `menu_glow` halo
(light spreading *outside* the plate, a different silhouette) and the border brightening
to `text_primary`; hover never shows the tick unless it has also taken focus, which the
hover handler does deliberately.

---

## 10. The mockup's local stand-ins (not part of the shipping screen)

The mockup renders standalone, with no autoloads and no router, so two behaviours are
faked locally. Both are documented here so nobody mistakes them for the contract:

1. **Esc.** Esc toggles `%QuitStandIn`: a full-rect `void_base` scrim at alpha 0.60 plus a
   centred `PanelContainer` (base `panel` stylebox, min width 420, margins 16) holding
   `DialogTitle` "QUIT SESSION", a body line and CANCEL / QUIT buttons, with CANCEL taking
   default focus. This stands in for `quit_confirm.tscn`; the real dialog is a `Screen`
   configured through `DialogManager` and is not loaded by the mockup.
2. **Activation.** Pressing a verb does not route. It calls nothing and it prints nothing;
   it swaps the read-out for 1.6 s to a line that names the intent, for example
   "MOCKUP: PLAY REQUESTS loading WITH destination station". The shipping screen emits the
   intents in section 13.4 instead and leaves the read-out alone.

---

## 11. Audio hooks

The mockup makes no audio calls (autoloads are out of bounds for it). The shipping screen
owns these, all through `AudioManager`, naming only files that exist:

| When | Call | Resolves to |
|---|---|---|
| screen enters (`on_route` / `_ready`) | `play_music(&"mus_menu_theme", 1.5)` | `assets/audio/music/mus_menu_theme_01.ogg` (205.2 s, looped by the API) |
| a verb is hovered, or takes keyboard focus | `play_ui(AudioManager.UiCue.HOVER)` | `assets/audio/ui/ui_hover.ogg` (live today; guard against the double fire when a hover also grabs focus) |
| a verb is pressed down | `play_ui(AudioManager.UiCue.CLICK)` | `assets/audio/ui/ui_click.ogg` (live today) |
| PLAY is activated | `play_ui(AudioManager.UiCue.CONFIRM)` | `assets/audio/ui/ui_confirm_01.ogg` (needs the `CONFIRM` member added to `UiCue` and `UI_CUE_NAMES`; audit D.1 item 10) |
| Esc opens the quit confirm, or CANCEL closes it | `play_ui(AudioManager.UiCue.CLICK)` | `assets/audio/ui/ui_click.ogg` |
| EXIT is activated | `play_ui(AudioManager.UiCue.CLICK)` | `assets/audio/ui/ui_click.ogg`; the real dialog's confirm does the quit |
| a verb list is scrolled by the keyboard (future lists) | `play_ui(AudioManager.UiCue.SCROLL)` | `assets/audio/ui/ui_scroll_01.ogg` (needs the `SCROLL` member; audit D.1 item 11) |
| the screen routes away | `stop_music(0.6)` | n/a |

The music bed is 1.036 peak on decode (audit anomaly C7) and clips; normalise it before
this ships.

---

## 12. `ui_scale`

The screen must look correct at `ui_scale` 1.0, 1.2 and 1.4. `Router.live_theme()` rewrites
`default_font_size` plus the 27 per-type font-size items; nothing else scales. Every font
size on this screen is one of those items, so nothing is left behind when the scale changes.
Font items and the geometry they drive, read from the engine with `Router`'s own scaling
applied (`roundi(base * scale)`, rect dump in `.agents/gen/d4c_report.md` section 3):

| Item used | 1.0 | 1.2 | 1.4 | Effect on this screen |
|---|---|---|---|---|
| `MenuButtonPlate/font_size` | 34 | 41 | 48 | the plate's inner `Button` minimum height grows 47 -> 57 -> 67 px; the plate's own minimum height is `max(70, that)`, so the row is 70 px at all three scales and the `Button` fills it (measured 350 x 70 at offset 0, no overflow) |
| `HudReadout/font_size` | 18 | 22 | 25 | the read-out grows; its rendered ink box went (97, 1013, 314, 1026) -> (98, 1009, 362, 1025) -> (98, 1006, 398, 1024) |
| `Version/font_size` | 13 | 16 | 18 | the stamp grows; the footer band grows 26 -> 31 -> 35 px, which is absorbed by `MiddleBand` (766 -> 761 -> 757) |
| `DialogTitle/font_size`, `Button/font_size` | 18, 14 | 22, 17 | 25, 20 | the stand-in dialog grows around its centre; the real dialog does the same |
| `SectionHeader/font_size` | 16 | 19 | 22 | not used on this screen any more (the caption was removed) |

### 12.1 The row-height rule (implementation instruction)

**No pinned row height in the shipping scene.** A verb row takes its height from the plate's
minimum size, and the plate's minimum height is
`max(PLATE_MIN_HEIGHT, plate_button.get_minimum_size().y)`, re-derived whenever the theme
changes. The reason is measured: the inner `Button`'s font-driven minimum height is 47 px at
1.0, 57 at 1.2 and 67 at 1.4, and the pinned 56 px row of the first pass underflowed it at
1.4, which drew a 280 x 67 plate inside a 56 px row, stretched the art 1.196x vertically and
closed the visible gap between plates from 14 px to 3 px. The mockup implements the rule in
`_sync_plate_minimum()`, called from `_ready()` and from `NOTIFICATION_THEME_CHANGED` so a
runtime `ui_scale` change re-derives it. `PLATE_MIN_HEIGHT` is the plate art's designed
height and acts as a floor, never as a row height.

Verified, engine rect dump (`.agents/gen/d4c_report.md` section 3):

| Measure | 1.0 | 1.2 | 1.4 | 2.0 |
|---|---|---|---|---|
| inner `Button` font-driven minimum height | 47 | 57 | 67 | 93 |
| plate minimum height (`max(70, ...)`) | 70 | 70 | 70 | 93 |
| row height | 70 | 70 | 70 | 93 |
| stack pitch (row top to row top) | 84 | 84 | 84 | 107 |
| visible gap between plates | 14 | 14 | 14 | 14 |

The 2.0 column is the proof that the height follows the font and not a constant: there the
font's minimum (93) overtakes the floor (70), the row grows to 93, and the separation is
still 14 px.

### 12.2 What happens at 1.0, 1.2 and 1.4, measured

- The sticky values do not move: the safe margins, the row separation (14), the plate width
  (350), the tick (6 x 60), the emblem (50 x 58) and the header gutter (6 x 0) are unchanged,
  and the column only shifts 5 px up (467 -> 464 -> 462) because the footer band grows from
  26 to 31 to 35 px.
- **The plate art is no longer stretched at any of the three scales.** The plate box is
  350 x 70 at 1.0, 1.2 and 1.4 and the art is drawn into it at the box's size, a uniform 1.25x
  of its 280 x 56 source at every scale (measured: the art's top bevel profile is identical
  row for row at 1.0 and 1.4).
- The stack pitch stays 84 px and the visible gap 14 px at all three scales (measured: 14 rows
  of backdrop between the plate bands in each of the three renders).
- The tick stays 6 x 60 and, because it is `v = 4`, stays centred in its row (measured at 1.0:
  y 546..605 inside the 70 px row at y 541..610).
- Nothing clips and nothing leaves the frame at 1.4: the column is 312 of 757 px, the footer
  band fits inside the safe area, and the stamp's right edge stays on the safe margin
  (measured x 1685..1822 against the 1824 margin).

Consequences to accept, stated so nobody treats them as bugs:

- The safe margins, the stack separations (14 / 16), the tick (6 x 60), the emblem (50 x 58)
  and the header gutter (6 x 0) are not font-size items and do not scale.
- The emblem's `modulate` multiplier is not a font-size item and does not scale.
- Nothing is hard-coded per node, so no font size is left behind when the scale changes.

---

## 13. Implementation notes for the coder

### 13.1 Keep from `main_menu.tscn` / `main_menu.gd`

- The `AtlasTexture` logo crop `Rect2(44, 707, 1961, 615)` with `filter_clip = true`.
- `env_menu_bg.png` as the backdrop with `expand_mode = 1`, `stretch_mode = 6`, plus the
  96 px right/bottom slack in the scene (the scene is its only owner; the screen no longer
  reserves it in code) and `clip_contents = true` on the layer.
- `fx_ember_pulse.png` with the additive `CanvasItemMaterial` (`blend_mode = 1`) and the
  0.25 to 0.45 alpha range; re-anchor it per resize as in section 8.
- The grain layer exactly as shipped (`grain.tres`, `TILE`, `texture_repeat = 2`,
  `modulate.a = 0.08`).
- The 20 s drift with `TRANS_SINE` / `EASE_IN_OUT`, 96 px.
- `menu_button.tscn` for the three verbs, 350 x 70, with `text` set on the instance. The
  component bakes `custom_minimum_size = (280, 56)`, so each instance overrides it (section
  15.1), and the screen must keep the plate's minimum height font-driven (section 12.1).
- `theme_type_variation = &"Version"` on the stamp, plus `font_color` overridden from
  `Tokens/text_primary` (`get_theme_color` / `add_theme_color_override`), and the string
  "VAJB ORBIT v0.2".
- The Esc to `overlay_requested(&"quit_confirm", {})` path and the overlay-pop focus
  restore (generalised to the opener).
- `AudioManager.play_ui(UiCue.HOVER)` on hover and `UiCue.CLICK` on press.
- The `Screen` base class and the intent signals. The shipping screen extends `Screen`;
  only the mockup extends `Control` so it can stand alone.

### 13.2 Delete or replace

- `Title`, `MenuButtons` and `VersionLabel` as point-anchored nodes with pixel offsets
  (`offset_right = 392`, `offset_left = -312`, `anchor_left = 0.08`, `anchor_top = 0.58`,
  `anchor_top = 0.12`). Replaced by the safe area, the bands and the command column.
- The hard-coded `%EmberPulse` anchor offsets as the only positioning (keep them as the
  16:9 default, replace the runtime anchor with the resize formula).
- The assumption that 8 percent of the screen's left edge is a text field. Replaced by the
  scrimmed console column.
- The housing: do not port `RailPanel`, `RailFrame`, `RailContent`, `RailStack`,
  `RailHeader`, the `COMMAND` caption or the row tails. The screen must not reference
  `ui_panel_frame.png` at all.

### 13.3 Constants

```
SAFE_MARGIN_LEFT        = 96      SAFE_MARGIN_TOP    = 64
SAFE_MARGIN_RIGHT       = 96      SAFE_MARGIN_BOTTOM = 48
LOGO_SIZE               = (560, 176)
CONSOLE_SEPARATION      = 16      HEADER_SEPARATION       = 16
HEADER_GUTTER_SIZE      = (6, 0)  BADGE_SIZE              = (50, 58)
VERB_STACK_SEPARATION   = 14      VERB_ROW_SEPARATION     = 16
PLATE_SIZE              = (350, 70)  PLATE_MIN_HEIGHT      = 70
TICK_SIZE               = (6, 60)
EMBLEM_BRIGHTEN         = 2.0
FOOTER_SEPARATION       = 24
DIALOG_MIN_WIDTH        = 420     DIALOG_MARGIN = 16
DIALOG_STACK_SEPARATION = 12      DIALOG_ACTION_SEPARATION = 8
EMBER_ANCHOR            = (0.791, 0.618)   EMBER_BOX = 500
EMBER_ALPHA_MIN         = 0.25    EMBER_ALPHA_MAX = 0.45   EMBER_HALF_PERIOD = 4.0
DRIFT_DISTANCE          = 96      DRIFT_SECONDS = 20
GRAIN_ALPHA             = 0.08
LEFT_SCRIM_ALPHA        = 0.62    LEFT_SCRIM_SPAN = 0.68
BOTTOM_SCRIM_ALPHA      = 0.70    BOTTOM_SCRIM_START = 0.70
QUIT_SCRIM_ALPHA        = 0.60
STAMP_VARIATION         = Version      STAMP_COLOUR_TOKEN = text_primary
READOUT_VARIATION       = HudReadout
LOGO_FADE 0.40 / LOGO_POP 0.55 from 1.03
HEADER_DELAY 0.10 / HEADER_FADE 0.30 / HEADER_POP 0.45 from 0.99
VERB_DELAY 0.30 / VERB_STAGGER 0.10 / VERB_FADE 0.26 / VERB_POP 0.36 from 0.97
TICK_IN 0.14 / TICK_OUT 0.10 / QUIT_FADE 0.12
READOUT   = ["ENTER THE STATION HUB", "OPEN SYSTEM AND INTERFACE SETTINGS", "END THE SESSION"]
```

### 13.4 Intents

| Verb | Signal | Payload |
|---|---|---|
| PLAY | `route_requested` | `&"loading"`, `{&"destination": &"station"}` (`IMPLEMENTATION_PLAN.md` section 9.2) |
| OPTIONS | `overlay_requested` | `&"settings"`, `{}` |
| EXIT | `overlay_requested` | `&"quit_confirm"`, `{}` |
| Esc | `overlay_requested` | `&"quit_confirm"`, `{}` when no overlay is open |

### 13.5 Gotchas

1. Do not tween `position` or `size` of a container child. `modulate:a` and `scale` are
   safe; `pivot_offset` must be set after layout for a centred pop.
2. The stamp's brightness is a colour override, not a font-size override: keep `Version`
   (13 px) as the item so `ui_scale` still reaches it, and set only `font_color`. Never
   write a colour literal; read `Tokens/text_primary`.
3. Nothing on this screen may print. The only line a run emits today is the vendored
   `[godot_ai game_helper]` registration from the plugin's autoload, which appears for
   every scene in this project.
4. The tick's colour comes from `Tokens/accent_danger_bright`; the scrim and the Esc
   scrim come from `Tokens/void_base` with an alpha override. No hex anywhere.
5. `%QuitStandIn` must stay hidden by default so the screen is complete with zero input.
6. `HeaderGutter` must keep `mouse_filter = IGNORE` and stay 6 px wide with a 16 px
   separation: change either and the emblem stops lining up with the plates.
7. **No pinned row height** (section 12.1). A verb row takes its height from the plate's
   minimum size, and the plate's minimum height is `max(70, inner_button.get_minimum_size().y)`,
   re-derived on `NOTIFICATION_THEME_CHANGED`. Pinning the row to a constant is what produced
   the 1.196x plate stretch and the 3 px stack gap at `ui_scale` 1.4.
8. The emblem's brightness is a `modulate` multiplier on `InsigniaBadge`, set once in
   `_ready()` from `EMBLEM_BRIGHTEN` (section 15.3). Do not move it to the entrance tween: the
   entrance animates `CommandHeader`'s `modulate:a`, and the badge's own alpha must stay 1.0
   so the multiplier survives the fade.

---

## 14. Resolved decisions

All five came from the owner's review of the first render (the mockup sheet was
never committed to git and is gone since the 2026-09-21 `.agents/gen` cleanup;
the decisions below carry the measurements). Each row records what was done and
what it measured.

| # | Decision | Outcome | Evidence |
|---|---|---|---|
| 1 | Drop the metal housing panel | Applied. `RailPanel`, `RailFrame`, `RailContent`, `RailStack`, `RailHeader`, the three row tails, the `StyleBoxEmpty` rail style and the `ui_panel_frame.png` reference are gone; no frame or border device replaces them and the panel frame is not reused anywhere else on this menu. The plates float on the scrimmed vista and moved 28 px left (x 118..398 with the 280 px plates of that pass, x 118..468 after the D4c scale-up) | the four bands where the rail's border used to be (x 94..104 at y 700..780, x 466..478 at y 700..780, x 200..300 at y 466..478, x 200..300 at y 774..786) now measure mean luminance 19.0 / 19.9 / 20.5 / 19.3 with median rgb `#101318`/`#10141a`/`#11151b`/`#101319`, i.e. the same as a backdrop reference patch at x 700..900 (21.8). The old render measured 42.4 / 39.4 / 42.2 / 35.5 there, plus a 7 px bright run on the left border and a 6 px run on the top border; the new frame has **zero** runs at those positions |
| 2 | Version stamp reads `VAJB ORBIT v0.2` and clears 4.5:1 | Applied. The string changed and the stamp's `font_color` is now `Tokens/text_primary` (the existing token, no new theme item, no change to `Version`'s 13 px size) | measured ink x 1724..1823, y 1018..1029, ink peak 208.1 against a local background of 20.3: **11.91:1** (mean-ink 11.67:1). The old `text_dim` stamp measured 3.88:1 |
| 3 | Keep the three footer read-outs | Unchanged, character for character: `ENTER THE STATION HUB`, `OPEN SYSTEM AND INTERFACE SETTINGS`, `END THE SESSION` | present in the mockup's `READOUT` array and in section 13.3; the rendered read-out ink is x 97..265, y 1017..1027 at 12.08:1 |
| 4 | Accept the vertical plate stretch at `ui_scale` 1.4 | **Superseded by D4c** (section 15.1): the scale-up puts the row height (70 px) above the font-driven plate minimum at 1.4 (67 px), so the 1.196x vertical stretch and the 3 px gap are gone, and the visible gap is 14 px at 1.0, 1.2 and 1.4. No second plate asset is needed | engine rect dump: inner `Button` 280 x 67 at offset -5.5 with `MenuButtonPlate` font 48 was the D4b defect; D4c measures the inner `Button` 350 x 70 at offset 0, font 48, in a 70 px row |
| 5 | Keep the insignia emblem | Applied. The emblem survives the housing as a lightweight header group with no panel behind it, its left edge flush with the plate column | engine rect dump: `InsigniaBadge` global x 118 = `PlayButton` global x 118 at 1.0 and at 1.4; rendered ink x 119..153, y 498..541 with highlights at 11.00:1 against a 24.5 local background, so it reads without the frame |

**The caption.** The brief left `COMMAND` to judgement. It was **dropped**: the render shows
it labelling a console that no longer exists, and it measured 3.86:1, below the 4.0:1 floor
`UI_SPEC.md` documents for `text_dim` and the 4.5:1 the owner required of the stamp in the
same pass. The emblem stayed (decision 5). Details in section 5 and in the report.

### Open questions for the owner (new list, this revision)

1. **The insignia's white matte fringe.** `ui_insignia_neutral.png` still carries the C3
   fringe (visible in the render as a light rim on the hex). Confirm the defringe pass
   (audit recommendation 4) lands before the screen is judged on colour. Carried over from
   the first pass, still unanswered.
2. **Where the stamp's brighter colour should live.** It is a node-level override today
   (`Version` 13 px + `font_color` from `Tokens/text_primary`), which keeps the theme and
   `Router.FONT_SIZE_ITEMS` untouched. If the owner prefers a declarative item, the
   alternative is a 13 px stamp variation carrying `text_primary`, which means editing
   `tools/build_theme.gd`, regenerating `vajb_theme.tres` and adding the new font-size item
   to `Router.FONT_SIZE_ITEMS`.
3. **Should the `COMMAND` caption come back?** It was dropped for contrast (3.86:1) and for
   redundancy. If it is wanted, it needs a brighter token, i.e. the same kind of theme
   change the stamp avoided, and the spec's type scale and node tree would regain the
   `SectionHeader` row.
4. **Closed by D4c: the plate stretch.** The scale-up removed it. The row is 70 px at
   `ui_scale` 1.0, 1.2 and 1.4 while the font-driven plate minimum is 67 px at 1.4, so the art
   is no longer stretched vertically and the visible gap between plates is 14 px at all three
   scales (measured). Sections 12.1 and 15.1.
5. **The read-out grew by 1.286x, not 1.25x.** 17.5 px does not exist as a theme item, and the
   closest is `HudReadout` at 18 px (the theme's readout item). A second read-out item at
   exactly 17.5 px would mean editing `tools/build_theme.gd`, regenerating `vajb_theme.tres`
   and adding a font-size entry to `Router.FONT_SIZE_ITEMS`. Confirm 18 px is acceptable.
6. **The emblem's body is still under 4.5:1.** Its highlights clear the floor with headroom
   (17.81:1 peak, 8.86:1 at the p90 ink) and its footprint median luminance went 26.4 -> 63.6,
   but that median is 1.76:1, because `ui_insignia_neutral.png` is a dark asset. A multiplier
   cannot fix the body: its footprint median (63.6 luma after the 2.0 multiplier) would need a
   further 4.2x to reach 4.5:1, and the darker half of the art about 19x, at which point the
   highlights and mid-tones clip to white and the stamp flattens into a white shape. The fix is
   an art pass (a brighter insignia, plus the defringe pass in audit recommendation 4), not a
   bigger multiplier. Section 15.3.

---

## 15. D4c: the two final decisions applied

### 15.1 Decision 1: the verb stack scaled up about 25 percent

The stack keeps its left alignment (the plates' left edge stays x 118) and its placement rule
(left in the console column, centred in the middle band); only geometry grows. Every number
below is from the engine rect dump in `.agents/gen/d4c_report.md` section 3 or from the
rendered frames.

| Property | Before (D4b) | After (D4c) |
|---|---|---|
| `PlayButton` / `OptionsButton` / `ExitButton` `custom_minimum_size` | (280, 56) | **(350, 70)**, set per instance |
| Plate minimum height | 56 (pinned) | **`max(70, inner Button minimum height)`**, re-derived on theme change (section 12.1) |
| `InsigniaBadge` `custom_minimum_size` | (40, 46) | **(50, 58)** |
| `PlayTick` / `OptionsTick` / `ExitTick` `custom_minimum_size` | (6, 48) | **(6, 60)**: the width stays 6 px, so the gutter stays 6 px and the plate edge stays x 118 |
| `FocusReadout` theme item | base `Label`, 14 px | **`HudReadout`, 18 px** (the only type consequence; section 5) |
| Command column | 302 x 258 at (96, 497) | **372 x 312 at (96, 467)** |
| Verb stack | 302 x 196, tops 559 / 629 / 699 | **372 x 238, tops 541 / 625 / 709** (pitch 84, gap 14) |
| Middle band / footer band | 772 / 20 | **766 / 26** |
| Emblem ink box | x 119..153, y 498..541 (threshold 90) | **(119, 468, 167, 522)** (threshold 60) |
| Read-out ink box | x 97..265, y 1017..1027 | **(97, 1013, 314, 1026)**: 1.286x wider, 1.30x taller |
| Plate art as drawn | 280 x 56, 1:1 with the art | **350 x 70, a uniform 1.25x of the art** |
| Tick ink box | x 96..101, y 563..610 | **x 96..101, y 546..605** (6 x 60, centred in the 70 px row) |

Unchanged on purpose: the safe margins (96 / 64 / 96 / 48), `CONSOLE_SEPARATION` (16),
`HEADER_SEPARATION` (16), `HEADER_GUTTER_SIZE` (6, 0), `VERB_STACK_SEPARATION` (14),
`VERB_ROW_SEPARATION` (16), `FOOTER_SEPARATION` (24), `LOGO_SIZE` (560, 176) and the logo crop,
the backdrop and its 96 px slack, the grain (0.08), the scrims (0.62 / 0.70), the ember (anchor
(0.791, 0.618), 500 px box, alpha 0.25 to 0.45), the drift (96 px over 20 s, §16 item 2), every entrance
timing, `MenuButtonPlate/font_size` (34), the stamp's `Version` item, string and colour, the
`READOUT` strings, the focus order and the Esc stand-in.

**The one thing that moved.** The column is 54 px taller, so the verb rows sit 18 px higher
(tops 541 / 625 / 709). The placement rule did not change: the column is still centred in the
middle band, and its centre is still the band's centre. A pinned y would be the only way to
hold the old tops, and this screen does not position regions with offsets.

### 15.2 Decision 1's other half: the row height follows the font

Section 12.1 carries the rule and the proof. In the mockup the change is `_sync_plate_minimum()`
plus `PLATE_MIN_HEIGHT`, called from `_ready()` and from `NOTIFICATION_THEME_CHANGED`. The
measured outcome: the row is 70 px and the gap 14 px at 1.0, 1.2 and 1.4, and at 2.0 the
font-driven minimum (93 px) overtakes the floor and the row grows to 93 px, which is what
"font-driven" has to mean.

### 15.3 Decision 2: the emblem brightened

**Mechanism.** A documented `modulate` multiplier on `InsigniaBadge`,
`EMBLEM_BRIGHTEN = 2.0`, applied once in `_ready()`. No theme token reaches the target: every
`Tokens` colour is a dimmer (`text_primary` is (0.79, 0.82, 0.86), `void_base` is
(0.03, 0.04, 0.05)), so a token used as a `modulate` darkens the art rather than brightening
it. The multiplier is white with a factor, so no colour is introduced, and no panel, frame,
glow or second texture was added behind the stamp.

**Measured** against the actual backdrop-plus-grain behind the badge (median luminance 23.6 at
1.0), badge at 50 x 58:

| Measure | Before (D4b, 40 x 46, no multiplier) | Test at 1.35 | Chosen at 2.0 |
|---|---|---|---|
| Peak highlight luminance | 204.0 | 255.0 (clipped) | 255.0 (clipped) |
| Peak contrast | 11.21:1 | 17.82:1 | **17.81:1** |
| p90 ink contrast | 9.15:1 | 10.77:1 | **8.86:1** |
| Footprint median luminance | 26.4 | 43.4 | **63.6** |
| Footprint median contrast | 1.05:1 | 1.27:1 | **1.76:1** |

The gate the owner set is met: the highlights clear 4.5:1 with 13.3 points of headroom at the
peak and 4.4 at the p90 ink. **The shortfall is the body.** The art is dark by design
(`ui_insignia_neutral.png`: ink median luminance 34.5, mean 37.9, mean rgb `#252525`), so a
multiplier lifts it without making it a bright mark: the footprint median rises from 26.4 to
63.6 luma (1.76:1), and 4.5:1 needs 127.8 luma, a further 4.2x on top of the 2.0 already
applied (about 8.4x in total); the darker half of the art would need about 19x more (about 38x
in total). At either the highlights and mid-tones clip to white and the stamp flattens into a
white shape. The multiplier clips the C3 white matte fringe (204 -> 255) as a side effect;
the fringe is an artifact the defringe pass is already scheduled to remove. The honest reading
is therefore: the highlights now read (peak 17.81:1, p90 8.86:1), the body improved 2.4x in
luminance but is still 1.76:1, and the fix for the body is an art pass, not a bigger number.

### 15.4 What this pass did not do

- No panel, frame, glow, border device or second texture behind the emblem.
- No theme edit, no `tools/build_theme.gd` run, no `router.gd` edit, no `project.godot` or
  `addon` change, no `menu_button.tscn` or `main_menu.tscn` change. The theme's item count and
  `Router.FONT_SIZE_ITEMS` (27) are untouched.
- No patch-margin override on the plate styleboxes. The 1 px border on this screen is the
  component's focus ring (`menu_button.gd` draws it at `BORDER_WIDTH`), and it is measured at
  exactly 1 px on all four sides at 1.0, 1.2 and 1.4: exact-token runs of one row at the top
  (y 541 / 538 / 536) and one row at the bottom (y 610 / 607 / 605), one column on the left
  (x 118) and one on the right (x 467), with the neighbours measuring backdrop or plate art.
  The theme's plate `StyleBoxTexture`s carry **no** patch margins (the only nine-patch in the
  theme is the panel frame, at 8 px), so the art itself is a stretched quad and its painted
  bevel band, 5 rows in the 280 x 56 source, measures 7 rows at 350 x 70. If the painted bevel
  is ever required to stay at its authored thickness, the fix is patch margins on the theme's
  plate styleboxes or a plate art re-authored at 350 x 70, not a layout change.

---

## 16. Wave-1 amendment (2026-09-18) — cue, drift, fonts

Owner rulings from the live walkthrough crosscheck, recorded in full in
`IMPLEMENTATION_PLAN.md` §9.8; execution evidence in `.agents/gen/fix_wave1_*`.

1. **The focus ring is retired.** No red rectangle is drawn for focus on the plates, from
   either source: the component's `_draw` ring is deleted and the theme's `focus` stylebox
   for the `MenuButtonPlate` variation is emptied so Godot's automatic focus draw paints
   nothing. §9's "three cues" paragraph and §15.4's ring measurement are superseded. The
   selection cues are now: (1) the 6 x 60 px tick band (unchanged), (2) the read-out line,
   (3) the emblem pulse — `InsigniaBadge` brightens 2.0 -> 2.35 over 0.10 s and returns over
   0.30 s every time focus lands on a different verb (§15.3's resting 2.0 is the base of the
   pulse). Hover is unchanged. The station rail, dialogs and other Buttons keep their focus
   boxes — the ruling targeted the menu plates.
2. **Backdrop drift retuned.** `DRIFT_DISTANCE` 24 -> **96 px**, `DRIFT_SECONDS` 40 -> **20 s**,
   same two-leg sine ping-pong. The backdrop slack is 96 px right/bottom, declared once, in
   `main_menu.tscn` (`offset_right` / `offset_bottom`); the screen's `_reserve_drift_slack()`
   helper that mirrored the constant there was deleted in the Wave-1 W7 fix cycle (W6-2), so
   the scene is the single owner and editing it takes effect. Every other "24 px" drift or
   slack figure in §7, §8, §12, §13 and §15.1 has been corrected in place to 96 px / 20 s.
3. **Fonts adopted** (plan §9.8 item 2): the type scale of §5 gains families — Oxanium
   (`FontVariation` wght 700) on `ScreenTitle`, `HeroTitle`, `StationPanelTitle`,
   `DialogTitle`, `HudReadout` and `MenuButtonPlate`; Rajdhani as the body face
   (`default_font` Regular, `StationValue` SemiBold); Saira Stencil One on the new
   `FlavourText` variation (13 px, `text_dim`) for the read-out line and the `Version` stamp.
   Sizes do not change; the theme remains generated (`tools/build_theme.gd`, deterministic,
   `Router.FONT_SIZE_ITEMS` 27 -> 28).

## 17. Boot and loading (absorbed from `MAIN_MENU_SPEC.md`)

These are the only sections of the Phase-A `MAIN_MENU_SPEC.md` still live; the
menu-layout sections it once carried are superseded by this spec (§3–§9).
Transcribed 2026-09-18 from `MAIN_MENU_SPEC.md` §1–§2 and §7; the source file
moves to the sealed archive in the next cleanup pass.

### 17.1 Boot sequence (total ≤ 3 s)

Scene: `vajb-orbit/ui/screens/boot.tscn`. Root `Control` full-rect,
`vajb_theme.tres`, bg `void_base` (full-rect `ColorRect`).

| t (s) | What happens |
|---|---|
| 0.0–0.5 | Solid `void_base`. Nothing else. |
| 0.5–1.4 | Logo fades in (alpha 0→1, 0.9 s, ease out). The logo is the generated lockup art (UI_CHROME spec). |
| 1.4–1.7 | One "ember flicker": logo modulate briefly (0.15 s) toward `accent_danger_bright` then back — single pulse, never looping. |
| 1.4–2.4 | Thin 2 px progress line under the logo, width 240, centred. Fill `metal_light`; 3 scripted ticks (25 % / 60 % / 100 %) with 0.3 s gaps — preflight is cosmetic in v1 (no server). |
| 2.4–3.0 | 0.6 s crossfade to Main Menu (`Tween` on a full-rect black `ColorRect` alpha 0→1→0 across the scene swap). |

- Any key press during boot is ignored (sequence is short by design).
- Skip guard: if the engine reports load already finished, jump to t=1.4 immediately.

### 17.2 Loading screen (the only bridge into gameplay)

Scene: `vajb-orbit/ui/screens/loading.tscn`. Same skeleton as boot.

- Background: generated splash backdrop (UI_CHROME spec) at 40 % opacity over `void_base`.
- Centred: destination label — "ENTERING SECTOR — <name>" in Blaec 22 px `text_primary`; placeholder v1: "ENTERING SPACE".
- Lower third: progress bar 260×14 (`progress_bg`/`progress_fill` styleboxes from UI_SPEC §2.1). In v1 fill tweens 0→100 % over the 1.2 s minimum display time — real asset streaming replaces this later. Background: `env_loading_bg.png` (ENVIRONMENT_SPEC §3 — the wreck vista at 40 % opacity; UI_CHROME's `ui_loading_backdrop.png` plate is parked as fallback).
- Minimum display time 1.2 s (anti-strobe). Fade-out 0.4 s into the game scene.
- No cancel button in v1 (cancel exists only for return-to-hangar direction, which is future scope).

### 17.3 Boot-related transitions

| From → To | Style |
|---|---|
| Boot → Menu | 0.6 s black crossfade (§17.1) |
| Menu → Loading | 0.4 s fade to `void_base`, then the loading scene handles its own fade-in |

### 17.4 Boot/loading acceptance items

- [ ] Boot ≤ 3 s end-to-end; no interactive elements during boot.
- [ ] Exactly one accent colour visible; ember appears only as: logo flicker,
      button hover bloom/focus ring, background wreck pulse.
