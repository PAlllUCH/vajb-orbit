# Vajb Orbit - Station Hub (D5)

**Status:** written 2026-09-18 (D5b) from the live mockup `vajb-orbit/ui/screens/_mockup_station.tscn` +
`_mockup_station.gd`. Every number below was measured in the 1920x1080 renderer unless it says otherwise.
**Amendment 2026-09-18 (P1 economy):** the rail gains three modules — REFINERY, EXCHANGE and REPAIRS
(section 2 table updated; specs in sections 5.7 to 5.9). All three panels are strict reuses of the measured
patterns in section 3.1: same pane construct, same 76 px row grid, same 130/110/160 value columns, same 360 px
action column, same refusal path. No new measurements and no new theme items are introduced. Data sources:
`MineralCatalog`, `ComponentCatalog`, `game/exchange.gd`, `game/refinery.gd`, `game/repairs.gd`; state stays in
`PlayerProfile` (including the `vitals` section the repairs panel reads, 01 §6 extension).
**Amendment 2026-09-22 (P2-B proper — the FITTING surface).** Transcribed from
`.agents/gen/p2b_proper_wave_task.md` §3; every number in it is 08 §3.2's, 09 §8's, section 5.1's own or the
pin's, and none is this pass's. The rail's UPGRADES module retires: `Module.UPGRADES` becomes
`Module.FITTING` and its label becomes `FITTING`, keeping the retired entry's rail position, its icon path
and its tint (section 2's table, section 5.3). The retired `ui/station/upgrades_panel.gd` and `.tscn` are
deleted and nothing else in the rail moves. Section 5.3 is the pane's whole spec; section 5.4's DECK CONTROL
gains `REFUEL` and `RECHARGE`; section 5.2's shipyard plates gain the same line the fitting surface shows
for its selected cell; section 7.1's art map records the reused icon; sections 8, 10, 11 and 12 follow the
new name and the two new profile keys. **Reversal (owner tick 1 of the wave brief):** restore the label, the
entry and the pane files. Two references stay as the retired mockup's own record and do not describe the
FITTING pane: section 3.1's `Upgrades*` node rows and its `UPGRADES` column set (the deleted table pane) and
section 13's verification table (the mockup it measured).
**Implements (future):** `vajb-orbit/ui/screens/station.tscn` plus module panels under `vajb-orbit/ui/station/`.
**Contract sources:** `IMPLEMENTATION_PLAN.md` section 9.2, 9.4, 9.5, 9.6; `STATION_SPEC.md`; `UI_SPEC.md`;
`THEME_AUDIO_EXTENSION.md`; `ASSET_AUDIT.md` sections E.2 and F; `MAIN_MENU_V2.md` (the sibling screen, for
identity consistency).
**Consumes:** `PlayerProfile` (autoload), `StationCatalog`, the theme items listed in section 8, and the
`ui/theme/vajb_theme.tres` slot/plate chrome. Route `&"station"` does not exist yet (section 11).

---

## 1. Intent

The player arrives from `loading{destination: &"station"}` and leaves through LAUNCH or LOG OUT. The screen is
the account's physical home: a docking ring where ammunition, hulls and refits are bought with the credits the
player earned in space. It is the only place in the game where the player spends anything, so it must make two
things obvious without a tutorial:

1. **What I have and what it costs.** A credits readout that never leaves the frame, and one row per catalogue
   entry showing its real name, price and the consequence of buying it (`HELD / MAX`, `INSTALLED`, `ACTIVE`).
2. **Which of the four things I came here for.** Ammunition (OUTFITTING), hulls (SHIPYARD), fitting (FITTING),
   leaving (LAUNCH). The rail keeps all four visible at once, so a player who bounced in for a resupply is one
   press from undocking.

Feeling: cold, functional, industrial. The hangar backdrop is architecture, not sky. Chrome is gunmetal and
1 px; the single ember accent (`accent_danger`) appears only where something is denied, armed or broken. Same
metal housing, same caption style and same ember discipline as `_mockup_main_menu.tscn`, one screen later in
the flow.

## 2. Navigation model

**Pattern: a persistent module rail plus a single module host.** The rail is a `PanelContainer` (360 px wide)
holding seven `StationButton` entries and, below a spacer, LOG OUT. The host is the framed console panel that
every module draws into. There are no tabs and no nested pages.

| Module | Entry | Leaves the station? | Payload |
|---|---|---|---|
| OUTFITTING | rail entry 1 | no | 6 weapon modules + 5 ammo packs, `ModuleCatalog` / `StationCatalog.AMMO_PACKS` (amendment, section 5.1) |
| REFINERY | rail entry 2 | no | the player's ore stacks, the 3:1 conversion stepper (amendment, section 5.7) |
| EXCHANGE | rail entry 3 | no | the hold, the market board, sell and SELL ALL RAW (amendment, section 5.8) |
| SHIPYARD | rail entry 4 | no | 4 hulls, `StationCatalog.SHIPS`, plus the preview and the stat comparison |
| FITTING | rail entry 5 | no | the active hull's own SLOT LAYOUT grid and the module inventory's OWNED MODULES rows, `ShipFit.grid_cells` / `PlayerProfile.modules` (amendment, section 5.3) |
| REPAIRS | rail entry 6 | no | the damage report and the repair fee (amendment, section 5.9) |
| LAUNCH | rail entry 7 | yes, `route_requested(&"loading", {destination: &"game"})` | the flight briefing, the cargo hold and the two-press launch control |
| LOG OUT | session group, below the spacer | yes, `route_requested(&"main_menu")` | a confirm dialog first (LOG OUT is destructive of nothing, but it is the way out of the session) |

The seven entries fit the existing rail stack without a new measurement: seven 56 px entries with 6 px
separation measure 428 px inside the 769 px rail content box (section 3.1); the spacer absorbs the remainder.

**Why the rail, not tabs or cards.** Shopping at a station is not a linear task: the player buys ammo, then
notices the hull is worse than a hull they can afford, then checks whether a module fits their grid, then buys
more ammo. Tabs hide the siblings and force a return trip through the tab bar every time; cards make the four
modules compete for the same canvas and cannot show a 6 row list and a 480 px ship at once. A fixed rail plus
one host keeps the two things a shopping player needs at all times in the same screen position (the exit and
the balance) while the host is free to be a table (OUTFITTING, FITTING), a two-column yard (SHIPYARD) or a
briefing (LAUNCH). It also gives the pad a stable meaning: shoulder buttons cycle modules from anywhere.

**How the player moves between modules.**
- The rail entry itself (mouse or `ui_accept` on a focused rail entry).
- `PageUp` / `PageDown` cycle modules from anywhere in the host, wrapping at the ends.
- Gamepad shoulder buttons: `JOY_BUTTON_LEFT_SHOULDER` / `JOY_BUTTON_RIGHT_SHOULDER`.
- `Tab` / `Shift+Tab` walk the focus order, which crosses the rail and the active host pane (section 10).

**Escape (proposed semantics, three steps).** `ui_cancel` never leaves the station by itself:
1. A confirm overlay is open: close it and return focus to the rail entry that opened it.
2. LAUNCH is armed: disarm, restore the confirm strip text and the button colour, keep focus.
3. Otherwise: move focus out of the host pane and onto the current rail entry. A second `ui_cancel` on the rail
   opens the "LEAVE THE STATION" confirm (STAY DOCKED focused, LOG OUT second), and only LOG OUT leaves.

**LAUNCH.** The module is a briefing plus a two-press control: the first press arms (button colour becomes
`accent_danger_bright`, `modulate.a` pulses 1.0 -> 0.70 -> 1.0 twice, the strip reads
`ARMED · PRESS LAUNCH AGAIN WITHIN 3 s TO UNDOCK`), a 3 s one-shot `Timer` disarms it, and the second press
inside the window fades the whole screen to `Tokens/void_fade` and hands off to the loading bridge. The
shipping screen replaces the fade with `route_requested(&"loading", {destination: &"game"})` and leaves the
fade to `Router`.

**What the mockup cannot do.** It does not route, it does not save and it does not read `PlayerProfile`: it
holds a local stub state and prints `HANDOFF · loading -> game (the mockup does not route)` into the status
strip instead. Section 11 lists every value to replace.

## 3. Composition

Base render target 1920x1080, stretch `canvas_items`, aspect `expand`. The layout is one full-rect
`MarginContainer` safe area, one `VBoxContainer` of three bands, and containers below that. Nothing on the
screen is placed by a hand-tuned offset; the only full-rect overlay is the leave confirm, which is centred by a
`CenterContainer`.

### 3.1 The grid, measured at 1920x1080

| Region | Carrier | Container / anchor | `size_flags` | `custom_minimum_size` | Measured box |
|---|---|---|---|---|---|
| Screen root | `Station`, `Control` | preset 15, `grow_*` 2 | n/a | n/a | 0..1920 x 0..1080 |
| Safe area | `Layout`, `MarginContainer` | preset 15, margins 24 | n/a | n/a | x 24..1896, y 24..1056 |
| Bands | `Page`, `VBoxContainer`, separation 16 | child of `Layout` | fill | none | 1872 x 1032 |
| Header band | `Header`, `HBoxContainer`, separation 16 | child of `Page` | v 0 | `(0, 76)` | y 24..147 (123 tall: the credits housing, not the 76 px minimum, sets it. Title ink y 58..95, location caption ink y 110..128) |
| Body band | `Body`, `HBoxContainer`, separation 16 | child of `Page` | v 3 | none | y 163..1022, measured frame bands 163..170 top and 1015..1021 bottom |
| Footer band | `Footer`, `HBoxContainer`, separation 16 | child of `Page` | v 0 | none | y 1038..1056 (status ink y 1041..1052) |
| Module rail | `ModuleRail`, `PanelContainer`, `PanelRaised` | child of `Body` | v 3 | `(360, 0)` | x 23..384, y 163..1021 (frame bands 23..30, 377..384, 163..170, 1015..1021) |
| Module host | `ModuleHost`, `PanelContainer`, `PanelRaised` | child of `Body` | h 3, v 3 | none | x 399..1896, y 163..1021 (frame bands 399..406, 1889..1895) |
| Panes | `Outfitting` / `Shipyard` / `Fitting` / `Launch`, `VBoxContainer`, separation 12 | child of `HostMargin` | fill | none | content box x 453..1842, y 216..969 |
| Credits housing | `CreditsPanel`, `PanelContainer`, `PanelRaised` with `CreditsMargin` 16/8 | child of `Header` | v 4 | none | x 1709..1896, y 23..147 (frame bands 1709..1716 and 1889..1895) |

The rail's own grid:

| Region | Node | Container | `size_flags` | Min size | Measured box |
|---|---|---|---|---|---|
| Rail content | `RailMargin`, `MarginContainer` | child of `ModuleRail` | n/a | content + 24 | content box x 69..339, y 208..977 |
| Rail stack | `RailBox`, `VBoxContainer`, separation 10 | child of `RailMargin` | fill | none | 270 wide |
| Module caption | `RailCaption`, `Label` (`StationCaption`) | child of `RailBox` | fill | text | y 208..226 (derived) |
| Module list | `ModuleButtons`, `VBoxContainer`, separation 6 | child of `RailBox` | fill | 4 x 56 | y 236..478 (derived) |
| One rail entry | `Button` (`StationButton`), `toggle_mode` | child of `ModuleButtons` | fill | `(0, 56)` | x 69..339, 56 tall |
| Rail spacer | `RailSpacer`, `Control` | child of `RailBox` | v 3 | none | absorbs all rail slack |
| Session caption | `SessionCaption`, `Label` (`StationCaption`) | child of `RailBox` | fill | text | ink y 899..907 |
| Session list | `SessionButtons`, `VBoxContainer`, separation 6 | child of `RailBox` | fill | 1 x 56 | 270 x 56 |
| LOG OUT | `Button` (`StationButton`), `toggle_mode` | child of `SessionButtons` | fill | `(0, 56)` | plate band measured y 924..974, x 71..325 |

The row grid inside a host pane (OUTFITTING and UPGRADES):

| Region | Node | Container | `size_flags` | Min size | Measured box |
|---|---|---|---|---|---|
| Column header strip | `HeaderMargin` 12/10/12/0 -> `OutfittingHeader` / `UpgradesHeader`, `HBoxContainer`, separation 12 | child of the pane | fill | text | header ink y 292..303 |
| Row list | `OutfittingScroll` / `UpgradesScroll`, `ScrollContainer` | child of the pane | v 3, `horizontal_scroll_mode = 0` | none | y 318..945 (derived from the pane content box) |
| Rows | `OutfittingRows` / `UpgradeRows`, `VBoxContainer`, separation 6 | child of the scroll | h 3 | none | row 1 measured y 322..397, pitch 82 |
| One row | `Button` (base `Button` theme, `toggle_mode`) | child of the rows VBox | fill | `(0, 76)` | x 453..1842 (1390 wide), 76 tall |
| Row inner | `RowInner`, `MarginContainer` 12/8 | child of the row | full rect | none | x 465..1830 |
| Pane footer | `PaneFooter`, `Label` (`StationCaption`) | child of the pane | fill | text | ink y 957..965 |

Column widths, left to right (all fixed pixels, they never scale with the aspect):

| Column | OUTFITTING | UPGRADES | SHIPYARD row | LAUNCH brief |
|---|---|---|---|---|
| icon | 40 | 40 | none | none |
| title block | `size_flags_horizontal 3` (absorbs the slack) | h 3 | h 3 | n/a |
| value column 2 | `HELD / MAX` 130 | `EFFECT` 300 | `STATUS` 130 | value 220 (right aligned) |
| value column 3 | `PRICE` 110 | `PRICE` 110 | (slack) | n/a |
| value column 4 | `STATUS` 160 | `STATUS` 160 | n/a | n/a |

SHIPYARD's three-column body and LAUNCH's two-column body:

| Region | Node | `size_flags` | Min size | Measured box |
|---|---|---|---|---|
| Ship list | `ShipListBox`, `VBoxContainer`, separation 8 -> `ShipScroll` -> `ShipList` | h 0 | `(340, 0)` | x 453..791 (the focused Lancer row measured x 453..790, y 308..383) |
| Preview housing | `PreviewFrame`, `PanelContainer`, `PanelRaised` -> `PreviewMargin` 16 -> `PreviewBox` | h 3, v 3 | `(260, 0)` | x 809..1461, y 383..963 |
| Ship image | `PreviewCenter` (`CenterContainer`, v 3) -> `PreviewImage` (`TextureRect`) | fill | computed | ship ink x 928..1350, 423 px wide (see 7.2) |
| Stat column | `StatsBox`, `VBoxContainer`, separation 10 | h 0 | `(300, 0)` | x 1477..1842 |
| Slot layout grid | `HardpointSlots`, `GridContainer`, separation 4 | h 0 | `(matrix width) x 48` | rebuilt per selection in the stat column (x 1477..1842); one cell per matrix cell of the selected hull, `columns` = the matrix width (08 §3.2: 4 for eight hulls, 5 for the Destroyer). Supersedes the fixed seven-plate strip's measured box (x 1484..1843, y 498..546, pitch 52) |
| Brief column | `BriefBox`, `VBoxContainer`, separation 8 | h 0 | `(560, 0)` | x 453..1013 |
| Cargo strip | `CargoSlots`, `HBoxContainer`, separation 6 | fill | 5 x 40 | x 452..675, y 570..610 (5 cells of 40 px, pitch 46) |
| Cargo manifest | `CargoList`, `ItemList` | fill | `(0, 110)` | x 453.., y 612..722, selected band bg `metal_mid` measured |
| Deck control | `LaunchActionBox`, `VBoxContainer`, separation 12 | h 0 | `(360, 0)` | x 1477..1842 |
| Launch button | `LaunchButton`, `Button` (`StationButton`), `toggle_mode` off | fill | `(0, 88)` | x 1484..1843, y 815..900 (focus ring measured there) |

SHIPYARD's first row sits at y 308 rather than the table panes' 322, because the shipyard pane has no column
header strip above its list.

### 3.2 Proportions at 1920x1080

| Landmark | Fraction of width | Fraction of height |
|---|---|---|
| Safe-area margins | 1.25 % left and right | 2.2 % top, 2.2 % bottom |
| Header band | full | 2.2 % to 13.6 % |
| Rail housing | 1.2 % to 20.0 % | 15.1 % to 94.6 % |
| Host housing | 20.8 % to 98.8 % | 15.1 % to 94.6 % |
| Row 1 | 23.6 % to 95.9 % | 29.8 % to 36.8 % |
| Ship preview housing | 42.1 % to 76.1 % | 35.5 % to 89.2 % |
| Footer status line | 1.2 % to 15.5 % | 96.4 % to 97.4 % |

Read as composition: the left fifth is the console (rail), the right four fifths is the working surface, the
top 9 percent carries identity and the balance, the bottom 3 percent carries state and key hints, and the only
large image on the screen (the ship) sits in the middle of the working surface so it never competes with
either the rail or the numbers.

### 3.3 Responsive rule per region

`canvas_items` + `expand` computes `scale = min(window_w / 1920, window_h / 1080)` and the viewport is
`window / scale`, so exactly one axis keeps its 1920 or 1080 extent and the other gains room.

- **Uniform 16:9 (1600x900, 2560x1440, any 16:9 window):** the viewport stays 1920x1080 and every number in
  3.1 holds; the stretch scales the whole screen by 0.833 or 1.333. Nothing else happens.
- **Extra width (21:9).** Measured on a real 2560x1080 window (capture `previews/d5_station_shipyard_window_2560x1080.png`):
  the viewport becomes 2560x1080, the rail's frame band stays at x 23..30 and its right edge at 377..384, the
  host's left band stays at 399..406 and its right band moves to 2529..2536, and every vertical measurement
  (row 1 at y 322..397, the pane's bottom edge at 1015..1021) is unchanged. All 640 extra pixels are taken by
  `ModuleHost` (`size_flags_horizontal = 3`). The header's `Spacer` and the footer's `FooterSpacer` absorb the
  same extra width inside their bands, so the title stays left and the credits readout stays pinned to the
  right safe margin.
- **Extra height (4:3).** Measured on a real 1440x1080 window (capture `previews/d5_station_shipyard_window_1440x1080.png`):
  the viewport becomes 1920x1440 at scale 0.75, so the whole screen is drawn at 0.75 and the extra 360 viewport
  pixels go to `Body` (`size_flags_vertical = 3`) alone: the rail's left frame band starts at screen y 122
  (= 163 x 0.75) and the panels' bottom bands measure y 1031..1036 on screen, i.e. the Body spans 163..1382 in
  viewport pixels against 163..1022 at 16:9, so the panels grow by exactly the 360 px the header and footer
  gave up. The rail's `RailSpacer` keeps the SESSION group and LOG OUT pinned to the bottom of the rail, and
  each pane's own vertical spacer (`Slack`, `StatsSpacer`, `BriefSpacer`, `ActionSpacer`) absorbs the extra
  height inside the pane, so the content stays top-aligned and the primary action stays bottom-aligned.
- **Never scaled by the layout:** the 24 px safe margin, the 360 px rail, the 76 px row, the 48/40 px slot
  plates, the 56 px rail entry, the 88 px launch button, the 110 px manifest and the 12/13/14/16/18/20/22/48 px
  font sizes. They are fixed pixel values that the stretch scales once, uniformly. The only `size_flags` that
  ask for slack are `Spacer`, `FooterSpacer`, `RailSpacer`, `StatsSpacer`, `BriefSpacer`, `ActionSpacer`,
  `Slack` (all `SIZE_EXPAND_FILL` on one axis) and the `ModuleHost` / pane / preview / stat column expansions
  named above. There is no proportional split anywhere else.

### 3.4 The `PanelRaised` content inset (a stylebox gotcha worth knowing before coding)

`PanelRaised` is a `StyleBoxTexture` built from `ui_panel_frame.png` with `texture_margin_* = 32`. A
`StyleBoxTexture` that never had explicit content margins uses its texture margins as content margins, so every
`PanelRaised` container insets its child by `32 + expand_margin 1 = 33` px per side, *before* the screen's own
`MarginContainer` margins apply. That is why several boxes above are not the naive arithmetic, and it is
measurable:

- The host's content box starts at `400 + 1 + 32 + 20 = 453` px, which is exactly where the row 1 outline
  measures (x 453..1842).
- The rail's content box starts at `24 + 1 + 32 + 12 = 69` px, which is where the rail entry plate art starts
  (measured x 71).
- The credits housing's minimum height is 16 (its margins) + 43 (icon and two text lines) + 64 (two 32 px
  content margins) = 123 px, so the housing, and not the header's `custom_minimum_size.y = 76`, sets the header
  band's height: the measured header is y 24..147 and the Body therefore starts at 163.

The coder needs this when reproducing the composition: the panel's own inner margin and the stylebox's content
margin are additive. A tighter inset means either regenerating the frame art at a smaller `texture_margin` or
shrinking the inner `MarginContainer` to compensate.

## 4. Node tree (exact)

```
Station (Control, preset 15, grow 2/2, theme = vajb_theme.tres, script = _mockup_station.gd)
├─ Backdrop (TextureRect, preset 15, mouse_filter IGNORE, texture ui_backdrop_hangar.png,
│            expand_mode EXPAND_IGNORE_SIZE, stretch_mode KEEP_ASPECT_COVERED)
├─ BackdropDim (ColorRect, unique %BackdropDim, preset 15, mouse_filter IGNORE,
│               colour pushed from Tokens/void_base at alpha 0.72)
├─ Grain (TextureRect, unique %Grain, preset 15, mouse_filter IGNORE, modulate (1,1,1,0.06..0.11),
│          texture grain.tres, expand_mode EXPAND_IGNORE_SIZE, stretch_mode TILE, texture_repeat ENABLED)
├─ Layout (MarginContainer, preset 15, margins 24/24/24/24)
│  └─ Page (VBoxContainer, separation 16)
│     ├─ Header (HBoxContainer, unique %Header, min (0,76), separation 16)
│     │  ├─ StationMark (TextureRect, min (48,48), v4, icon_map_node_station_48.png)
│     │  ├─ TitleBox (VBoxContainer, v4, separation 2)
│     │  │  ├─ StationName (Label, HeroTitle)
│     │  │  └─ StationLocation (Label, StationCaption)
│     │  ├─ Spacer (Control, h3, mouse_filter IGNORE)
│     │  └─ CreditsPanel (PanelContainer, unique %CreditsPanel, v4, theme_type_variation PanelRaised)
│     │     └─ CreditsMargin (MarginContainer, 16/8/16/8)
│     │        └─ CreditsRow (HBoxContainer, separation 10)
│     │           ├─ CreditsIcon (TextureRect, unique %CreditsIcon, min (28,28), v4,
│     │           │              texture icons/tint/icon_credits_48.png, modulate Tokens/text_primary)
│     │           └─ CreditsBox (VBoxContainer, v4, separation 0)
│     │              ├─ CreditsLabel (Label, StationCaption)
│     │              └─ CreditsValue (Label, unique %CreditsValue, StationValue)
│     ├─ Body (HBoxContainer, v3, separation 16)
│     │  ├─ ModuleRail (PanelContainer, unique %ModuleRail, min (360,0), v3, PanelRaised)
│     │  │  └─ RailMargin (MarginContainer, 12/12/12/12)
│     │  │     └─ RailBox (VBoxContainer, separation 10)
│     │  │        ├─ RailCaption (Label, StationCaption, "MODULES")
│     │  │        ├─ ModuleButtons (VBoxContainer, unique, separation 6)      4 x rail entry
│     │  │        ├─ RailSpacer (Control, v3, mouse_filter IGNORE)
│     │  │        ├─ SessionCaption (Label, StationCaption, "SESSION")
│     │  │        └─ SessionButtons (VBoxContainer, unique, separation 6)     1 x rail entry (LOG OUT)
│     │  └─ ModuleHost (PanelContainer, unique %ModuleHost, h3 v3, PanelRaised)
│     │     └─ HostMargin (MarginContainer, 20/20/20/20)
│     │        ├─ Outfitting (VBoxContainer, unique %Outfitting, separation 12)
│     │        │  ├─ PaneHeader (HBoxContainer, separation 12)
│     │        │  │  ├─ PaneIcon (TextureRect, min (40,40), v4, icon_equip_module_48.png)
│     │        │  │  ├─ TitleBox (VBoxContainer, h3 v4, separation 2)
│     │        │  │  │  ├─ PaneTitle (Label, StationPanelTitle)
│     │        │  │  │  └─ PaneSubtitle (Label, StationCaption)
│     │        │  │  └─ PanelTag (Label, StationCaption, v4)
│     │        │  ├─ HeaderMargin (MarginContainer, 12/10/12/0)
│     │        │  │  └─ OutfittingHeader (HBoxContainer, unique %OutfittingHeader, separation 12)
│     │        │  ├─ OutfittingScroll (ScrollContainer, v3, horizontal_scroll_mode 0)
│     │        │  │  └─ OutfittingRows (VBoxContainer, unique %OutfittingRows, h3, separation 6)
│     │        │  └─ PaneFooter (Label, StationCaption)
│     │        ├─ Shipyard (VBoxContainer, unique %Shipyard, hidden, separation 12)
│     │        │  ├─ PaneHeader (as above, ShipyardIcon unique, tint/icon_hull_48.png tinted)
│     │        │  ├─ ShipyardBody (HBoxContainer, v3, separation 16)
│     │        │  │  ├─ ShipListBox (VBoxContainer, min (340,0), separation 8)
│     │        │  │  │  ├─ ShipListCaption (Label, SectionHeader)
│     │        │  │  │  └─ ShipScroll (ScrollContainer, v3, horizontal_scroll_mode 0)
│     │        │  │  │     └─ ShipList (VBoxContainer, unique %ShipList, h3, separation 6)
│     │        │  │  ├─ PreviewFrame (PanelContainer, unique %PreviewFrame, min (260,0), h3 v3, PanelRaised)
│     │        │  │  │  └─ PreviewMargin (MarginContainer, 16/16/16/16)
│     │        │  │  │     └─ PreviewBox (VBoxContainer, separation 8)
│     │        │  │  │        ├─ PreviewCaption (Label, unique %PreviewCaption, StationCaption, autowrap)
│     │        │  │  │        ├─ PreviewCenter (CenterContainer, unique %PreviewCenter, v3, mouse IGNORE)
│     │        │  │  │        │  └─ PreviewImage (TextureRect, unique %PreviewImage, mouse IGNORE,
│     │        │  │  │        │                  expand_mode EXPAND_IGNORE_SIZE, stretch KEEP_ASPECT_CENTERED)
│     │        │  │  │        └─ PreviewName (Label, unique %PreviewName, StationPanelTitle)
│     │        │  │  └─ StatsBox (VBoxContainer, min (300,0), separation 10)
│     │        │  │     ├─ StatsCaption (Label, SectionHeader)
│     │        │  │     ├─ ShipStats (VBoxContainer, unique %ShipStats, separation 6)  1 header + 5 stat lines
│     │        │  │     ├─ HardpointCaption (Label, StationCaption, "SLOT LAYOUT · n CELLS · m ENGINES")
│     │        │  │     ├─ HardpointSlots (GridContainer, unique %HardpointSlots, h0, separation 4)  1 cell per matrix cell
│     │        │  │     ├─ StatsSpacer (Control, v3, mouse IGNORE)
│     │        │  │     ├─ PriceCaption (Label, StationCaption)
│     │        │  │     ├─ ShipPrice (Label, unique %ShipPrice, StationValue)
│     │        │  │     └─ ShipAction (Button, unique %ShipAction, min (0,56), StationButton)
│     │        ├─ Upgrades (VBoxContainer, unique %Upgrades, hidden, separation 12)
│     │        │  ├─ PaneHeader / HeaderMargin -> UpgradesHeader (unique) / UpgradesScroll ->
│     │        │  │  UpgradeRows (unique, VBoxContainer, h3, separation 6) / PaneFooter
│     │        └─ Launch (VBoxContainer, unique %Launch, hidden, separation 12)
│     │           ├─ PaneHeader (PaneIcon icon_map_route_48.png)
│     │           ├─ LaunchBody (HBoxContainer, v3, separation 16)
│     │           │  ├─ BriefBox (VBoxContainer, min (560,0), separation 8)
│     │           │  │  ├─ BriefCaption (Label, SectionHeader, "FLIGHT BRIEFING")
│     │           │  │  ├─ BriefRows (VBoxContainer, unique %BriefRows, separation 6)  9 caption/value lines
│     │           │  │  ├─ CargoCaption (Label, SectionHeader)
│     │           │  │  ├─ CargoSlots (HBoxContainer, unique %CargoSlots, separation 6)  5 x 40 plate
│     │           │  │  ├─ CargoList (ItemList, unique %CargoList, min (0,110))
│     │           │  │  ├─ BriefSpacer (Control, v3, mouse IGNORE)
│     │           │  │  └─ BriefNote (Label, StationCaption, autowrap)
│     │           │  ├─ LaunchSpacer (Control, h3, mouse IGNORE)
│     │           │  └─ LaunchActionBox (VBoxContainer, min (360,0), separation 12)
│     │           │     ├─ ActionCaption (Label, SectionHeader, "DECK CONTROL")
│     │           │     ├─ ActionSpacer (Control, v3, mouse IGNORE)
│     │           │     ├─ LaunchButton (Button, unique %LaunchButton, min (0,88), StationButton)
│     │           │     └─ ConfirmStrip (Label, unique %ConfirmStrip, StationValue, autowrap)
│     └─ Footer (HBoxContainer, unique %Footer, separation 16)
│        ├─ StatusBeacon (ColorRect, unique %StatusBeacon, min (12,12), v4, Tokens/accent_danger)
│        ├─ StatusLabel (Label, unique %StatusLabel, StationCaption, v4)
│        ├─ FooterSpacer (Control, h3, mouse IGNORE)
│        └─ HintLabel (Label, StationCaption, v4)
├─ LeaveConfirm (Control, unique %LeaveConfirm, preset 15, mouse_filter STOP, hidden)
│  ├─ LeaveDimmer (ColorRect, unique %LeaveDimmer, preset 15, mouse IGNORE, void_base at 0.72)
│  ├─ LeaveCenter (CenterContainer, preset 15, mouse IGNORE)
│  │  └─ LeavePanel (PanelContainer, min (520,0), PanelRaised)
│  │     └─ LeaveMargin (MarginContainer, 20/20/20/20)
│  │        └─ LeaveBox (VBoxContainer, separation 16)
│  │           ├─ LeaveTitle (Label, StationPanelTitle)
│  │           ├─ LeaveBody (Label, StationCaption, autowrap)
│  │           └─ LeaveButtons (HBoxContainer, separation 10, alignment 2)
│  │              ├─ LeaveCancel (Button, unique %LeaveCancel, min (190,52), StationButton)
│  │              └─ LeaveLogout (Button, unique %LeaveLogout, min (190,52), StationButton)
└─ Fade (ColorRect, unique %Fade, preset 15, mouse IGNORE, colour pushed from Tokens/void_fade at alpha 0)
```

**Rail entry anatomy** (`_make_rail_entry`): a `Button` (`StationButton`, `toggle_mode`, `FOCUS_ALL`,
`custom_minimum_size (0, 56)`) -> `RowInner` (`MarginContainer` 16/8, forced to the button rect, mouse IGNORE)
-> `HBoxContainer` (separation 12) -> a 40 px `TextureRect` icon + a `Label` (`StationPanelTitle`,
`size_flags_horizontal 3`, vertically centred, mouse IGNORE). The button keeps `mouse_filter` default so it
owns its own clicks; the inner nodes ignore the mouse so the button hit box is the whole 337 x 56 cell.

**Row anatomy** (`_make_row`): a `Button` (base `Button` theme, `toggle_mode`, `FOCUS_ALL`,
`custom_minimum_size (0, 76)`, `CURSOR_POINTING_HAND`) -> `RowInner` (`MarginContainer` 12/8) ->
`HBoxContainer` (separation 12) -> [40 px icon `TextureRect`] -> `TitleBox` (`VBoxContainer`, separation 2,
`h3`, `SIZE_SHRINK_CENTER`) -> [optional value columns: `VBoxContainer` with `custom_minimum_size (width, 0)`,
`SIZE_SHRINK_CENTER`, separation 2, holding a `StationValue` and a `StationCaption`]. The rows are `Button`s
and not `ItemList` entries because each row carries an icon, a two-line title block and up to two numeric
columns; the one `ItemList` on the screen is the LAUNCH cargo manifest, where a plain text list is the right
control. Both use theme items, so neither falls back to engine defaults.

## 5. Per-module spec

Data source for every row, in the shipping screen: `StationCatalog.AMMO_PACKS`, `StationCatalog.SHIPS`
(ids, names, prices, stats and icon paths are the catalogue's, never literals); the FITTING pane reads
`ShipFit`, `ModuleCatalog` and `PlayerProfile` instead (section 5.3).
State source: `PlayerProfile`. The mockup's local copies are listed in section 11.

### 5.1 OUTFITTING (buy ammunition and weapon modules)

Three groups, in render order: the FITTED WEAPONS strip, the MODULES rows, then the five ammo packs.

**Amendment 2026-09-22 (S3 — the MODULES rows retire into the AUCTION).** §5.10's
shelf sells the rolled instances, so this pane returns to ammunition. Read the
sentence above from this pass as **two groups, in render order: the FITTED WEAPONS
strip, then the five ammo packs.** The `MODULES` caption, the seven rows, their
`MODULE_ROWS`/`EFFECT_TEXT`/`STATUS_*` constants and their focus slot go with the
retirement; `PlayerProfile.buy_module` and `ModuleCatalog` stay as the price source
with no new UI caller (10 §2.4, CONTRACTS §12/§15). The strip, the ammo rows, the
refusal wordings (§5.6, 09 §2's `<n> NEEDED`) and the audio hooks are untouched.
**Reversal:** restore the P2-B1 amendment above and its row set — the rows and their
tests are in git history at the S3 wave boundary.

**Amendment 2026-09-22 (P2-B1 — the weapon fit surface: the MODULES section and the FITTED WEAPONS
strip).** Transcribed from `.agents/gen/p2b1_weapon_fit_wave_task.md` §3; every number in it is 09
§3.1's and none is this pass's.

- The pane gains a `MODULES` caption and seven weapon rows above the ammo packs,
  one per module in 09 §3.1's table order (`w_laser` 900 first, then `w_cannon`
  1 200, `w_rocket` 2 400, `w_mine` 1 800, `w_plasma` 4 800, `w_railgun` 5 200,
  `w_mining` 600 — seven rows since the P2-B1 close-out: `w_mining` is 09 §4
  item 7's mining laser and the launch-fit gate's mining swap needs its door, so
  the brief's §1 list is the row set; reversal is one constant, `MODULE_ROWS`),
  each row: 48 px module icon, name, `W SLOT · DRAW n` meta, the 09 §3.1 effect
  text (09 §4 item 7's own words for `w_mining`), PRICE, STATUS, ACTION.
- STATUS: `FITTED (Wk)` when installed on the active hull, `OWNED ×n` in the
  inventory, `FOR SALE` when affordable, `LOCKED` otherwise.
- ACTION per state: `BUY` (buy_module) → `INSTALL` (first empty W cell; none
  empty → the row offers SWAP, the displaced module returns to inventory) →
  `SWAP` → `REMOVE`.
- Above the rows, a **FITTED WEAPONS** strip: one line per W cell of the active
  hull — `W1 LASER MKII` / `W2 — EMPTY` — each fitted line carrying REMOVE; the
  strip reads `ShipFit.grid_cells` + `PlayerProfile.fit_for` and never mutates
  directly (panels request, the profile mutates — STATION_HUB §12.4).
- Refusals render in the footer strip the panel already owns
  (`status_requested`), never a dialog.
- Focus order: the fitted strip first, then the module rows, then the ammo rows
  (Tab order, STATION_HUB §10).

Refusal wordings (owner tick 2 of the wave brief, its own two lines; 09 §2's over-by format is the
first): the power overload renders `13 / 11 PWR — OVER BY 2` (Σ draws / output — over by) and a swap
with no empty W cell renders `W SLOTS FULL — SWAP OR REMOVE FIRST`; both land in the footer strip
(`status_requested`), never a dialog.

Reversal: delete the `MODULES` caption, the six module rows and the fitted strip and restore the
ammo-only pane; the ammo rows below are untouched by this amendment either way.

**The ammo rows.** One row per ammo pack, five rows, in catalogue order (`PlayerState.WEAPONS` order).

| Column | Source | Render |
|---|---|---|
| icon | `pack.icon` | 40 px `TextureRect`, painted icons at full colour, the three flat glyphs from the derived `icons/tint/` stencil moderated with `Tokens/text_primary` |
| title | `pack.name` | `StationValue`, 18 px |
| meta | `pack.rounds` | `StationCaption`: `"<rounds> ROUNDS PER PACK"` |
| `HELD / MAX` | `PlayerProfile.ammo_of(id)` / `ammo_max(id)` | `StationValue` `"300 / 300"` plus a `StationCaption` state line (below) |
| `PRICE` | `pack.cost` | `StationValue`, `Tokens/text_primary` when affordable, `Tokens/accent_danger` when not, caption `CREDITS` |
| `STATUS` | derived | `StationValue`: `EMPTY`, `IN STOCK`, `AT CAP`, `OVER CAP` |

State lines (measured in the OUTFITTING render): `held <= 0` -> `EMPTY` / `NO ROUNDS HELD`; `held > max` ->
`OVER CAP` / `CAPACITY IS ADVISORY`; `held == max` -> `AT CAP` / `NO PURCHASE CAP`; else `IN STOCK` /
`BELOW CAPACITY`. `ammo_max` is advisory only (`STATION_SPEC.md` section 2.3): the screen displays the
comparison, `buy_ammo` never clamps, and the pane footer says so in words (`HOLD CAPACITY IS ADVISORY ·
A PURCHASE IS NEVER CLAMPED`).

Action: `ui_accept` on a row (or a click) calls `PlayerProfile.buy_ammo(pack.id, pack.rounds, pack.cost)`.
Success -> the credits counter animates to the new balance, the status strip reads
`PURCHASED · LASER CELLS · +300 ROUNDS`, the held count and the tag refresh. Refusal -> the refusal path in
5.6. Empty state: none (the catalogue always has five packs). Error state: an id the catalogue does not know
is not drawn at all; the coder must render a disabled `STOCK UNAVAILABLE` row instead of a blank one, because
a catalogue that lost an entry is a content bug the player should not have to debug.

### 5.2 SHIPYARD (buy and switch hulls)

Left: the hull list, one row per ship, `STATUS` column only. Right: the preview housing over the stat column.

| Column | Source | Render |
|---|---|---|
| title | `ship.name` | `StationValue` |
| meta | `ship.hull`, `ship.hardpoints` | `StationCaption` (`META_FORMAT`): `"%d HULL · %d SLOTS"`, e.g. `"1000 HULL · 11 SLOTS"` |
| `STATUS` | derived from profile | `ACTIVE`, `OWNED`, `FOR SALE` (owned-or-affordable), `LOCKED` (unaffordable and not owned) |
| `PRICE` (stat column) | `ship.cost` | `StationValue`, `accent_danger` when above the balance |
| ship image | `ship.preview` | `TextureRect`, native sprite scaled as in 7.2 |
| description | `ship.description` | `StationCaption`, autowrap, above the image |
| name under the image | `ship.name` | `StationPanelTitle` |
| comparison rows | `ship.hull` / `ship.shield` / `ship.cargo` / the hull's engine count / the hull's slot cell count (08 §3's table through `ShipFit.grid_counts(hull)`) vs the active ship | two right-aligned `StationValue` columns of 110 px: `SELECTED` (the row's ship) and `ACTIVE`; the selected value turns `Tokens/text_dim` when it is lower than the active one |
| slot layout grid | `ShipFit.grid_cells(hull)`, `ShipFit.grid_size(hull)`, `ShipFit.grid_counts(hull)` | a `GridContainer` of one cell per matrix cell, `columns` = the matrix width, `separation` 4; a gap is an empty 48x48 `Control` with no plate, a slot cell a 48 px disabled `SlotButtonWeapon` plate carrying that type's slot glyph (`assets/icons/slot/icon_slot_<type>_48.png`); caption `SLOT LAYOUT · <n> CELLS · <m> ENGINES` (`_hardpoint_caption`; `n` = the hull's slot count, 08 §3's Total — gaps are not cells — and `m` its E count) |
| action | derived | `ShipAction`: `IN SERVICE` (disabled) when the row is the active hull, `SET ACTIVE` when owned, `BUY` when not owned |

Actions: selecting a row sets the preview (focus or click). `ui_accept` on a ship row, or `ShipAction`, calls
`set_active_ship(id)` when owned and `buy_ship(id, cost)` when not; a successful purchase does not make the
hull active (`STATION_SPEC.md` section 2.4), so the status strip says `PURCHASED · BULWARK · NOT ACTIVE UNTIL
YOU SET IT` and `ShipAction` becomes `SET ACTIVE`. Empty state: `StationCatalog.ship(preview)` returning `{}`
means the preview cannot be drawn: show `NO HULL IN THE CRADLE` in `PreviewName`, blank the image and leave
the stat rows at `0`. Error state: a hull id with no matrix (`ShipFit.grid_cells` empty — an unknown or an NPC
hull) draws no cells at all and leaves the grid and its caption empty; the caption never reads a stale hull.
Rendered states in one frame: `OWNED` + `ACTIVE` + two `LOCKED` (measured in
`previews/d5_station_shipyard_1920x1080.png`).

**Amendment 2026-09-21 (P2-A — the hull's own layout grid).** The fixed seven-plate
hardpoint strip and the `hardpoints`-driven meta are superseded: the strip is now the
selected hull's own layout, one cell per 08 §3.2 matrix cell with `columns` = the matrix
width, a gap drawn as an empty 48x48 `Control` carrying no plate, and a slot cell a
disabled 48 px `SlotButtonWeapon` plate carrying its type's slot glyph. The caption reads
`SLOT LAYOUT · <n> CELLS · <m> ENGINES` (the pin's `_hardpoint_caption`), the list meta
becomes `META_FORMAT` `"%d HULL · %d SLOTS"`, and the stat rows become
HULL / SHIELD / CARGO / ENGINES / SLOT CELLS. The unique names (`%HardpointSlots`,
`HardpointCaption`) and the `SlotButtonWeapon` theme item are kept, so the 48 px plate
guard and the D3 properties (section 12.3, section 13) do not move. Reversal: restore the
7-plate `HBoxContainer` and the `hardpoints`-driven meta, and drop 08 §3.2's matrix as the
display's source.

**Amendment 2026-09-22 (P2-B proper — the plates' hover line, owner request 1).** The shipyard's slot
layout plates gain the fitting surface's own line: a plate reads
`<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>` on hover, resolving the cell's module from the selected
hull's own `fit_for` entry (`PlayerProfile.fit_for`, the same source the grid is built from; the line is
section 5.3's, and `shipyard_panel.gd` is its owner). The grid stays a display: no plate becomes selectable,
none carries a focus ring, and none mutates anything (section 12.4). Reversal: drop the hover line from
`shipyard_panel.gd`; the plates, the caption and `STAT_ROWS` do not move.

### 5.3 FITTING (fit, swap and remove modules per cell)

**Amendment 2026-09-22 (P2-B proper — FITTING replaces UPGRADES).** Transcribed from
`.agents/gen/p2b_proper_wave_task.md` §3.2; every number in it is the shipyard recipe's, section 5.1's or the
pin's (CONTRACTS §13), and none is this pass's.

**The rail.** `Module.UPGRADES` becomes `Module.FITTING`; the label becomes `FITTING`; the entry keeps the
retired entry's rail position, its icon path and its tint. The retired `ui/station/upgrades_panel.gd` and
`.tscn` are deleted; nothing else in the rail moves.

**Anatomy** — the section 5.1 host-pane construct, two stacked sections:

- **SLOT LAYOUT** — the active hull's grid, **the shipyard's own recipe** (`ShipFit.grid_cells`,
  `SlotButtonWeapon` 48 px plates, gaps as empty `Control`s, the type's slot glyph, the caption
  `SLOT LAYOUT · <n> CELLS · <m> ENGINES`). Unlike the shipyard's display, these cells are **selectable**:
  one selected at a time, `FOCUS_ALL`, the selected cell carrying the theme's focus ring; a cell's identity
  is its `slot_key` + `index` (09 §4.5's layout index). The recipe is shared with the shipyard (lift it into
  a helper both panes call, or duplicate it byte-equivalently); the reviewer checks both grids render
  identically.
- **OWNED MODULES** — one row per owned **base id** (aggregated by base id), ordered by
  `ShipFit.FIT_SLOT_KEYS` then catalogue order: 48 px module icon, name, the meta `SLOT <TYPE> · DRAW <n>`,
  `OWNED ×<n>`, and ACTION. **Amendment 2026-09-22 (S3 — instances):** the aggregation is by
  `base_id` (the shipped reader already resolves each inventory key through
  `PlayerProfile.base_module_id`), and a row whose base id owns **more than one instance**
  carries a `▸` expander: opening it lists one indented sub-row per instance, each showing
  the 15 §7 full rolled name, the rarity-tinted name cell (§5.10's three tints) and the
  instance's own ACTION. A base id the account holds exactly one of shows no expander, so
  today's single-instance surface is unchanged in shape. Two same-base instances stay
  distinguishable by their rolled names and their ids, which is what makes L80's
  remove/swap round trip observable. **Reversal:** collapse the sub-rows to the aggregate
  row (one constant).

**ACTION per state:** `FIT` when a cell of the module's own type is selected and the module is legal there
(calls `fit_module_at`); `SWAP` when that cell already holds another module (same call; the displaced one
returns to the inventory); `SELECT A CELL` (disabled) when no cell is selected or the module's type has no
selected cell.

**The power meter** (footer strip, always visible): idle `PWR <Σ draws> / <out + power module>`; with a cell
selected, the candidate's own line `PWR <Σ> / <out> · CANDIDATE <Σ'> / <out>`; when the candidate is over
budget the same line renders in the danger colour and ends `— OVER BY <n>`. The numbers are `fit_legal`'s own
`power` dictionary.

**Hover / selection info (owner request 1):** the selected cell's line reads
`<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`; the shipyard's plates gain the same line on hover
(`shipyard_panel.gd`), reading the selected hull's `fit_for` entry (section 5.2's amendment).
**Amendment 2026-09-22 (S3):** where the cell holds an **instance**, the name in that line is
15 §7's full rolled name in its rarity tint and the pane adds the instance's stat block below it —
the base module's catalogue stats plus one line per rolled affix (15 §7's two-line block). The
`OWNED ×<n>` tail keeps counting the base id's held instances. The stat lines are **display**: no
affix changes a flight stat in S3 (15 §9.3). **Reversal:** print the base name and hide the block.

**Refusals** (footer strip, never a dialog): `13 / 11 PWR — OVER BY 2` (09 §2's own format, already pinned),
`MANDATORY CELL — SWAP ONLY, NEVER EMPTY` (new this pass), and `REFUSED · FIT ILLEGAL` as the catch-all for
a fit illegal for any other reason (L77's guard, now named here as the third pinned refusal). The footer is
never blank.

**Focus order:** the SLOT LAYOUT cells first (row-major), then the OWNED MODULES rows, then the pane's own
footer, then the rail (section 10).

**Empty states:** an account that owns no modules shows one disabled row
`NO MODULES OWNED · BUY THEM IN OUTFITTING`; a hull with every cell filled and nothing selected shows the
meter and the grid, no refusal. A fitted instance keeps its record at `count` 0 and is not
owned-visible until it is removed again (CONTRACTS §15), so a hull fitted full can still read
`NO MODULES OWNED` — correct, not a bug.

**The per-cell transactions.** The pane only requests; the profile mutates. Install and swap are the one
composed call `PlayerProfile.fit_module_at(ship_id, slot_key, index, module_id)` and remove is the composed
`clear_fit_slot(ship_id, slot_key, index)`; a candidate that fails `ShipFit.fit_legal` is refused before any
write, a module the inventory does not hold is refused, and a cell whose key is in
`FitData.MANDATORY_SLOT_KEYS` (`[&"engines", &"power"]`) is never emptied (09 §4 items 9 to 13, CONTRACTS
§13).

**The retirement and its reversal.** The six legacy `UPGRADES` rows retire with their effects migrated into
the module catalogue, one successor module per row, carried by `PlayerProfile.LEGACY_UPGRADE_MODULES`; a v4
file with all six installed loads as six inventory modules (one each) and no upgrade records, and the profile
no longer carries `has_upgrade` / `installed_upgrades` / `install_upgrade` or the `upgrades` record at all
(CONTRACTS §13). Reversal (owner ticks 1 and 2 of the wave brief): restore the label, the entry and the pane
files, and restore the mapping constant plus the catalogue rows.

### 5.4 LAUNCH (leave the station)

Left: the flight briefing and the cargo hold. Right: DECK CONTROL.

| Row | Source | Render |
|---|---|---|
| `DESTINATION` | route destination | `OPEN SPACE · SECTOR K-9` |
| `ACTIVE HULL` | `PlayerProfile.active_ship()` -> `StationCatalog.ship(id).name` | upper case |
| `HULL LIMIT` / `SHIELD LIMIT` / `ENGINES` / `HARDPOINTS` / `SLOT CELLS` | the active ship's stats | integers: `HARDPOINTS` is the hull's W count, `ENGINES` its E count and `SLOT CELLS` its slot count (08 §3's table through `ShipFit.grid_counts(active_hull)`), so the three move with the hull |
| `CARGO` | `cargo_items()` summed vs the ship's `cargo` | `"35 / 40"` |
| `AMMUNITION` | `ammo_of()` summed over the five weapons | `"800 ROUNDS ACROSS 5 WEAPONS"` |
| cargo strip | `cargo_items()` | 5 `SlotButtonCargo` plates of 40 px, the first `n` carrying the item icon (24 px inset 8), the rest `disabled` |
| manifest | `cargo_items()` | `ItemList`, one item per stack as `"<name>   <qty>"`, first item auto-selected |
| `REFUEL` | `Repairs.refuel(profile, active_ship)` | an action in DECK CONTROL, for the active hull: the service's own result in the pane's status line (`fuel_max` on success; the service's refusal reason otherwise) |
| `RECHARGE` | `Repairs.recharge(profile, active_ship)` | as `REFUEL`, for `energy_max` |
| launch control | - | two-press arm/fire per section 2 |

Actions: the LAUNCH button arms then fires. Empty state: an empty hold shows a single disabled `HOLD EMPTY`
item in the manifest and leaves all five plates disabled (the mockup shows the stub manifest with two spare
plates disabled). Error state: no destination is a routing bug, not a screen state; the screen still arms and
`route_requested` is the only thing that can fail.

**Amendment 2026-09-21 (P2-A).** `BRIEF_ROWS` becomes
`destination, hull_name, hull, shield, engines, hardpoints, slots, cargo, ammo` — `ENGINES`
and `SLOT CELLS` join `HARDPOINTS` in the stat row above (9 caption/value lines, section 4's
node tree), all three read from the active hull's matrix through `ShipFit.grid_counts`. The
cargo plate strip and its five 40 px plates do not change. Reversal: drop the two rows and
the `ShipFit` source, and read the three stats from the frozen `StationCatalog` columns again.

**Amendment 2026-09-22 (P2-B proper — the two service rows, owner request 4).** Transcribed from
`.agents/gen/p2b_proper_wave_task.md` §3.3. DECK CONTROL gains the `REFUEL` and `RECHARGE` actions for the
active hull, calling `Repairs.refuel(profile, active_ship)` / `Repairs.recharge(profile, active_ship)` and
rendering the service's own result in the pane's status line (`fuel_max` on success; `energy_max` for
`RECHARGE`; the service's refusal reason otherwise). The services are free and instant: **no price column
and no credits move** (14 §1's rate; `FREE_FEE` is 0). Already-full and no-damage-report states are the
service's own refusals, rendered and never hidden: the button stays pressable and the footer says why (the
full tank is `REASON_FUEL_FULL`; `recharge` has no full case). Reversal: drop the two actions, their
`Repairs` calls and their status-line writes; the brief, the cargo strip, the manifest and the launch control
do not move.

### 5.5 LOG OUT (leave the session)

The rail's session entry opens the `LeaveConfirm` overlay: `Tokens/void_base` at alpha 0.72 over the whole
screen, a 520 px `PanelRaised` centred by a `CenterContainer`, a title, a body line that names the two ways
out (`To fly instead, stay docked and use LAUNCH`) and two 190 x 52 `StationButton`s: STAY DOCKED (focused on
open) and LOG OUT. STAY DOCKED closes the overlay and returns focus to the current rail entry. LOG OUT
declares `route_requested(&"main_menu")`.

### 5.6 What happens when the player cannot afford something

Three channels, no dialog:
1. **Before the press:** the price is drawn in `Tokens/accent_danger` and the `STATUS` cell reads `LOCKED`.
2. **On the press:** the call (`buy_ammo` / `buy_ship` / `install_upgrade`) returns `false`, the screen shows
   `REFUSED · NOT ENOUGH CREDITS · <cost> NEEDED` in the status strip in `accent_danger`, and both the price
   cell and the credits housing run the 4-step `modulate.a` pulse (1.0 -> 0.35 -> 1.0 -> 0.35 -> 1.0).
3. **Already owned / already active:** the same strip and pulse with `REFUSED · ALREADY INSTALLED · <name>` or
   `REFUSED · ALREADY THE ACTIVE HULL · <name>`.

The row stays selected and focus does not move, so the player can press again or move on. The screen never
pre-computes a refusal it can let the profile decide: it greys the price and the tag for presentation, and it
always reacts to the returned `bool` and to `PlayerProfile.purchase_failed(reason, id)`.

### 5.7 REFINERY (turn ore into ingots) — amendment 2026-09-18

Source contract: `docs/gameplay/04_refinery.md` section 5. Data: `MineralCatalog` rows, `Refinery` constants
and transactions; the panel computes no price itself and hardcodes no number.

Body: two columns, `RefineryTable` (h 3) + `RefineBox` (h 0, min 360 — the LAUNCH deck-control width).

`RefineryTable` reuses the OUTFITTING/FITTING construct exactly (column strip, scroll, rows, 76 px pitch,
one row per mineral with 3 or more ore held, per 04 section 5):

| Column | Source | Render |
|---|---|---|
| icon | `mineral.icon_ore`, tinted with `MineralCatalog.TIER_TINTS[tier]` | 40 px `TextureRect`, flat glyph moderated with the tint |
| title | `mineral.name` | `StationValue`; meta `StationCaption`: `"<ore_qty> ORE HELD"` |
| `ORE` | `cargo_qty(ore_id)` | `StationValue` (130 px column) |
| `INGOTS` | `Refinery.convertible(profile, id)` | `StationValue` (110 px) |
| `FEE` | `Refinery.fee_for(n)` | `StationValue` `"<n> CR"` (160 px) |

Rows are toggle buttons like OUTFITTING's; selecting one sets the stepper maximum and the totals.

`RefineBox` (vertical, separation 12): caption `CONVERSION`; selected name; stepper row (`-` / `"<n>
CONVERSIONS"` / `+`, 48 px buttons — the measured plate size, section 12.3), min 1, max
`Refinery.convertible`; totals rows in the LAUNCH brief row style (value column 220, right aligned) reading
`ORE IN`, `INGOTS OUT`, `FEE`; then `REFINE N`, `REFINERY ALL` and `CANCEL`, all three 88 px (the
LaunchButton height) and the full 360 px width of the box — Wave-1 W2.3 raised the two secondary
plates from 56 px so the column stops stacking an 88 px plate over two 56 px ones, and the three
heights live in `refinery_panel.tscn` as the one source. No stepper tick is a transaction; only the
two action buttons are.

Actions: `REFINE N` calls `Refinery.refine(profile, id, n)`; `REFINERY ALL` calls `Refinery.refine_all(profile)`.
Success -> the credits counter animates to the new balance and the rows rebuild (a stack that fell below 3 ore
disappears), status strip `REFINED · GOLD · 3 INGOTS · 45 CR FEE`. Refusal -> section 5.6
(`REFUSED · NOT ENOUGH CREDITS · 45 NEEDED`). Empty state: no stack has 3 ore -> a single `NO ORE TO REFINE`
caption row, box disabled, footer becomes `BRING RAW ORE FROM THE BELT` (the P1h panel's measured copy; the
default footer `3 ORE = 1 INGOT · FEE 15 CR PER CONVERSION` is shown whenever any stack is convertible).

### 5.8 EXCHANGE (sell your hold) — amendment 2026-09-18

Source contract: `docs/gameplay/05_exchange.md` sections 4 to 6 and 8. Data: `MineralCatalog`,
`ComponentCatalog`, `game/exchange.gd`. Every displayed price comes from `Exchange` (the one pricing function,
05 section 8); the panel never recomputes a price from a baseline. Clock: the panel calls
`Exchange.evaluate_market(profile, WorldClock.now())` on entry and before every quote or sale, and never runs a
Timer (17 section 4).

Body: three columns: `HoldBox` (min 340, rows seat 500 at 1920x1080) | `MarketBoard` (h 3, takes the slack,
548 measured) | `TradeBox` (min 360).

**Column correction (P1i measurements, 2026-09-18).** The exchange is denser than the single-column panes, so
the section 12.3 full-width column set cannot be reused here: a 130/110/160 row needs 512 px of cells, and two
such rows plus the 360 px trade column leave 24 px for both title blocks. The row cells below are sized to the
widest measured value each carries under the shipped theme (in pixels): `1 354 800` is 82, `COOLING` is 83,
`ELECTRONICS` is 119, `40 / 40` is 58; add the 12 px row-gap rhythm. Titles use `OVERRUN_TRIM_ELLIPSIS` and the
selected stack's full name is repeated in `TradeBox`, so no name is unreadable.

| List | Cells (left to right) |
|---|---|
| hold rows | icon 40; title (min 136); `QTY` 70; `UNIT` 80; `TOTAL` 100 |
| mineral board rows | icon 40; title (min 189); `PRICE` 80; `DEMAND` 60; `TREND` 95 |
| component board rows | icon 40; title (min 154); `STOCK` 80; `FAMILY` 130; `GRADE` 60 |

`HoldBox`: caption `YOUR HOLD`, scroll, one selectable row per sellable stack in `cargo_items()` on the 76 px
grid: icon 40; title `StationValue` with meta `StationCaption` (`ORE`, `INGOT`, or the component family's
label); `QTY` (`Exchange`-free read of `cargo_qty`); `UNIT` (`Exchange.exchange_price(id, demand)`); `TOTAL`
(the paid figure of `Exchange.quote`). Unknown ids are not drawn. Selecting a row arms `TradeBox`.

`MarketBoard`: caption `MARKET BOARD`, scroll, non-interactive rows (`focus_mode` NONE) on the same anatomy:
- one row per mineral: icon tinted per tier; name; `PRICE` (the ingot form's `Exchange.exchange_price`, the
  form 05 section 3 publishes); `DEMAND` (`"1.2x"`); `TREND` as `COOLING` / `STEADY` / `HOT` from the last band
  re-roll. The section 6 sketch's arrow glyphs are rendered as these words: the theme font set does not
  guarantee the arrow glyphs. Owner may amend.
- one row per component: icon tinted per grade; name; `STOCK` (`"12 / 15"`, remaining quota for this cycle);
  `FAMILY`; `GRADE`. The stock bar sketch is rendered as this text: bars would need new theme items, which this
  amendment does not add.

`TradeBox` (vertical, separation 12): caption `SALE`; selected item title; stepper row (`-` / `"<n> UNITS"` /
`+`, 48 px buttons, max the held quantity, default all per 05 section 6); the `ConfirmStrip` (`StationValue`)
reading `SELL 10 INGOT_GOLD — GROSS 4740 · FEE 95 · YOU GET 4645` (05 section 6 shape, numbers from
`Exchange.quote`); `SELL` (88 px); `SELL ALL RAW` (56 px); `CANCEL` (56 px).

Actions: `SELL` calls `Exchange.sell(profile, id, n, Clock.now())`. Success -> credits counter animates, rows
rebuild, strip `SOLD · 10 INGOT_GOLD · +4645 CR`. Surplus over quota -> strip `STOCK FULL · 12 UNITS QUEUED`
(05 section 4); queued units pay out at the next band evaluation. `SELL ALL RAW` sells every ore stack and
every surplus-book component within quota in one confirmed action (05 section 6); ingots sell stack by stack,
never through the shortcut. Refusal -> section 5.6 plus `REFUSED · HOLD EMPTY`. Empty state: empty hold -> a
single `HOLD EMPTY` caption row, `TradeBox` disabled. Footer: `THE STATION BUYS · IT NEVER SELLS IN V1`.

### 5.9 REPAIRS (restore hull and shield) — amendment 2026-09-18

Source contract: `docs/gameplay/01_economy_core.md` section 6. Data: `game/repairs.gd` (fee and transaction),
`PlayerProfile.vitals_of(active_ship)`, `StationCatalog.ship(active_ship)` for the maxima. The panel computes
no fee itself; the fee line shows `Repairs.fee(profile, id)` verbatim.

Body: two columns: `DamageReportBox` (min 560, the LAUNCH brief width) | `RepairBox` (min 360).
`DamageReportBox` uses the brief value rows (value column 220, right aligned): `ACTIVE HULL` (catalogue name),
`HULL` (`"200 / 1000"`), `SHIELD` (`"300 / 600"`), `MISSING` (`"800 HULL · 300 SHIELD"`), `FEE`
(`"500 CR"`, `accent_danger` above the balance).

`RepairBox`: the `REPAIR` button (88 px, the LaunchButton height) over the caption
`OPTIONAL · A DAMAGED HULL LAUNCHES FROM THE LAUNCH DECK`. States:
- no vitals record -> report rows read `NOT REPORTED`, button disabled, caption `UNDOCK AND DOCK TO FILE A
  DAMAGE REPORT`;
- hull and shield both at maximum -> `ALL SYSTEMS NOMINAL`, button disabled;
- hull at maximum, shield at 90 % or more but below maximum -> fee 0 by the section 6 exemption; the button
  stays enabled and the strip reads `SHIELD TOP-UP · NO FEE`; the press restores the shield for 0 CR;
- otherwise the fee is charged once for the whole repair (`verify -> spend -> restore vitals -> log`, 01
  section 7) and the active ship's vitals return to maximum.

Success -> strip `REPAIRED · 500 CR · ALL SYSTEMS NOMINAL`, credits counter animates. Refusal -> section 5.6.
Footer: `FEE · 1 CR PER 2 MISSING HULL · 1 CR PER 3 MISSING SHIELD`.

### 5.10 AUCTION (the house broker) — amendment 2026-09-22 (S3 + S4)

Transcribed from `docs/gameplay/10_ship_acquisition.md` §2/§2.4, 15 §7/§8 and 09 §10;
every number below is one of those documents', none is this pass's.

**The rail.** `Module.EXCHANGE` gains a neighbouring `Module.AUCTION`; label `AUCTION`;
same icon family and tint as EXCHANGE. No other entry moves (owner tick: position).

**Anatomy** — the section 5.1 host-pane construct, two stacked sections:

- **HULLS (6)** — one row per listed hull: 48 px class icon slot, name, class,
  `LIST <n> CR` (08 §2 column), the hot-slot line `WAS <n> CR` when discounted, ACTION
  `BUY` (10 §2.3's buyout; refusal `<n> NEEDED` per §5.6). Fighter and Cutter are
  always listed. **No class icon ships** (measured: `station_catalog.gd`'s nine rows
  carry `preview` only and there is no `assets/icons/ship/`), so the slot draws each
  hull's own `preview` exactly as the shipyard row does (§5.2) — no new art.
- **MODULES (10)** — one row per listed **rolled instance**: 48 px module icon, the
  15 §7 full rolled name, the meta `SLOT <TYPE> · DRAW <n> · <RARITY>`, price (09 list
  × 15 §1's rarity multiplier, −20 % after for the hot slot), ACTION `BUY`. Rows are
  tinted by the rarity table below. The three exclusives (15 §5) carry the tag
  `F LOT` while 15 §8's interim is on; **the F lot's rarity split is 15 §9.2's
  85 % Magic / 15 % Rare**, and its catalogue rows are 15 §9.1.

**Rotation footer:** `NEXT RESTOCK <m:ss>` (20-minute station clock, 10 §2.1) and the
hot slot's marker on its row. The shelf persists with the save (10 §2.1). **Amendment
2026-09-22 (S3):** the `m:ss` is computed **at pane entry** from `WorldClock.now()` and
its `BAND_SECONDS` 1200 — the clock ships exactly four statics (`now`, `bands_between`,
`set_override`, `clear_override`), has no remaining-time accessor, and its own header
forbids a per-consumer Timer (05 §8's rule, restated for the same clock). The line is a
**reading, not a countdown**; a wave that wants it to tick must add the accessor and
change that rule first. **Reversal:** one computed line.

**Selling:** a `SELL MODULES` sub-list of the player's inventory rows (the §5.3 OWNED
MODULES anatomy, aggregated by `base_id`) with `SELL` at `base × rarity × 60 %`
(15 §6). Hull sell-back keeps 10 §2.3's 60 %.

**Batteries in the FITTED WEAPONS strip (S4, 09 §10).** §5.1's strip rows group by
`base_id`: `3× LASER MKII · W1·W2·W3 · OWNED ×<n>` with `FIT ALL` / `REMOVE ALL` /
`SWAP ALL` and a per-barrel expander (`▸`) restoring the single-cell actions. The
bulk actions loop the composed transactions per cell (CONTRACTS §13/§15); a batch
that fails any cell rolls back to its starting fit and names `REFUSED · FIT ILLEGAL`
or `13 / 11 PWR — OVER BY 2` as §5.3 does.

**Rarity tints (the one-accent law, STYLE_BIBLE §2):** Common = the theme's default
label colour; Magic = `#565C63` (Steel Highlight); Rare = `#E8703A` (Ember Glow).
Only Rare touches the accent — rarity escalates toward the one danger colour. The
values live in the theme as `rarity_common` / `rarity_magic` / `rarity_rare`
(fallback to the hexes above when a token is missing). **Reversal:** three constants.

**Focus order:** the two lists in row order (HULLS then MODULES), then the sell
sub-list, then the footer, then the rail (§10).

**Amendment 2026-09-22 (S3 — the footer is the pane's own).** The AUCTION owns its
refusal/status strip the way FITTING does, not the station shell's: `station.gd`'s copy
prices by catalogue id (`Catalog.ammo_pack` → `Catalog.ship` → `ModuleCatalog.module`)
and an instance id resolves to `{}`, so it would render `0 NEEDED` and the raw id as the
name (`station.gd:456-492`). The wordings are unchanged — §13's three plus 09 §2's
`<n> NEEDED` — only their owner is. **Reversal:** route the strip back through the
shell once the shell can price an instance.

## 6. Type scale

Every text element uses a theme variation. There are no per-node font sizes anywhere in the mockup (verified:
no `add_theme_font_size_override`, no `theme_override_font_sizes`).

| Element | Theme item | Size | Colour | Measured contrast |
|---|---|---|---|---|
| Station name (`StationName`) | `HeroTitle` | 48 | `text_primary` | 11.94:1 on the dimmed backdrop |
| Pane title (`PaneTitle`), ship name (`PreviewName`), dialog title | `StationPanelTitle` | 20 | `text_primary` | as below |
| Row title, value cells, `ShipPrice`, `ConfirmStrip` | `StationValue` | 18 | `text_primary` (rows), `accent_danger` for a refused price | 11.89:1 on the row, 3.41:1 for the orange price (section 14 item 1) |
| Column headers, group captions (`SectionHeader`) | `SectionHeader` | 16 | `text_dim` | 4.12:1 on the pane |
| Row meta, captions, subtitles, `PaneFooter`, `BriefNote`, `HintLabel` | `StationCaption` | 13 | `text_dim` | 3.89:1 on a selected row, 4.05:1 on the void backdrop |
| Rail entries, `ShipAction`, `LaunchButton`, dialog buttons | `StationButton` | 22 | `text_primary` (`text_dim` disabled) | plate art carries the label |
| Ammo row titles and any plain `Button` label | `Button` | 14 | `text_primary` | 12.09:1 (measured on the sibling menu) |
| Cargo manifest items | `ItemList` | 14 | `text_primary`, `metal_mid` selected band | measured band luminance 49.6 |

`Router.FONT_SIZE_ITEMS` carries all eight of these items (`HeroTitle`, `StationButton`, `StationPanelTitle`,
`StationValue`, `StationCaption`, `SectionHeader`, `Label`, `Button`, `ItemList`), so `ui_scale` reaches every
text element on the screen. Measured at `ui_scale` 1.4 through Router's live theme: the 48 px title's ink
height grows from 36 to 50 px (a factor of 1.39), no container clips and the slot layout grid still fits the
stat column (see `previews/d5_station_shipyard_uiscale140_1920x1080.png`).

## 7. Art map

Every path below exists on disk and appears in `ASSET_AUDIT.md` section E.2 or F.1.

### 7.1 Chrome, backdrop and icons

| Asset | Role | Size on screen | Blend |
|---|---|---|---|
| `res://assets/ui/ui_backdrop_hangar.png` | full-screen hangar backdrop | 1920x1080, `KEEP_ASPECT_COVERED` (2048x1152 source) | normal, dimmed by `BackdropDim` at `void_base` 0.72 |
| `res://ui/theme/grain.tres` | film grain over everything | tiled, `modulate (1,1,1,0.06..0.11)` | normal (a `NoiseTexture2D`, not a generated image) |
| `res://assets/ui/ui_panel_frame.png` | the framed panel backing for every `PanelRaised` (theme item, `texture_margin` 32) | frame band measures 7 px + 1 px `expand_margin` = 8 px | normal, opaque interior |
| `res://assets/ui/ui_button_plate_normal.png`, `_hover`, `_pressed`, `_disabled` | the `StationButton` plate, four states, wired in the theme | 280x56 source, stretched to each button's rect | normal |
| `res://assets/ui/ui_slot_weapon_normal.png`, `_hover`, `_pressed`, `_disabled` | slot layout plates (theme `SlotButtonWeapon`) | 48x48 each, one plate per non-gap matrix cell of the selected hull | normal |
| `res://assets/ui/ui_slot_cargo_normal.png`, `_hover`, `_pressed`, `_disabled` | cargo plates (theme `SlotButtonCargo`) | 40x40 each, 5 cells | normal |
| `res://assets/icons/icon_map_node_station_48.png` | station mark, header | 48x48 | normal |
| `res://assets/icons/tint/icon_credits_48.png` | credits readout glyph | 28x28, `modulate` `text_primary` | normal |
| `res://assets/icons/tint/icon_logout_48.png` | LOG OUT rail icon | 40x40, tinted | normal |
| `res://assets/icons/icon_equip_module_48.png` | OUTFITTING icon | 40x40 | normal |
| `res://assets/icons/tint/icon_hull_48.png` | SHIPYARD icon (gap G1 has no dedicated drydock glyph) | 40x40, tinted with `text_primary` | normal |
| `res://assets/icons/icon_equip_generator_48.png` | the FITTING rail entry's icon: the retired UPGRADES entry's own icon path and tint, reused (amendment 5.3; no new art) | 40x40 | normal |
| `res://assets/icons/icon_map_route_48.png` | LAUNCH icon (gap G2 has no dedicated bay glyph) | 40x40 | normal |
| `res://assets/icons/tint/icon_weapon_cannon_48.png`, `..._mine_48.png`, `..._plasma_48.png` | the three ammo rows whose catalogue icon is a flat Phase B glyph (audit anomaly C16) | 40x40, tinted | normal |
| `res://assets/icons/icon_ammo_laser_48.png`, `icon_ammo_rocket_48.png` | painted ammo rows, used untinted | 40x40 | normal |
| `res://assets/icons/module/icon_module_<id>_48.png` for every module id except the five base weapons, which use `res://assets/icons/weapon/icon_weapon_<family>_48.png` (`w_laser`→`laser`, `w_cannon`→`cannon`, `w_rocket`→`rocket`, `w_mine`→`mine`, `w_plasma`→`plasma`) | the MODULES rows' icons (amendment 5.1; the rule is CONTRACTS §11's icon rule) | 48x48 | normal |
| `res://assets/icons/icon_equip_engine_48.png`, `_shield_gen_48.png`, `_module_48.png`, `_extra_48.png`, `_drone_48.png` | the retired UPGRADES row icons (no live pane draws them; the FITTING rows draw `icon_module_<id>_48.png`) | 40x40 | normal |
| `res://assets/icons/tint/icon_cargo_ore_48.png`, `icon_cargo_data_core_48.png`, `icon_cargo_salvage_48.png` | cargo plate art and manifest glyphs | 24 px inside a 40 px plate | normal |
| `res://assets/ships/ship_fighter_side.png`, `ship_vanguard_side.png`, `ship_gunship_side.png`, `ship_destroyer_side.png` | the shipyard preview, per catalogue `preview` | see 7.2 | normal |

### 7.2 The ship preview, sized

| Sprite | Native | Drawn |
|---|---|---|
| `ship_fighter_side.png` (Lancer) | 817x290 | 480x170 |
| `ship_vanguard_side.png` (Vanguard) | 905x387 | 480x205 |
| `ship_gunship_side.png` (Bulwark) | 859x385 | 480x205 |
| `ship_destroyer_side.png` (Obliterator) | 982x217 | 480x205 |

Rule: `PREVIEW_SCALE` 0.70 of the native size, clamped to `PREVIEW_MAX_WIDTH` 480 px, then clamped again to the
`PreviewCenter` box if the pane is narrower (that second clamp is what protects 4:3 and `ui_scale` 1.4). The
result is 25 percent of the screen width for every hull, measured as 423 px of hull ink (x 928..1350) in the
centre of a 620 px wide frame interior, which reads as a ship rather than a thumbnail.

### 7.3 Additive blending

**No asset on this screen is additive.** The station uses opaque architecture and normal-blended chrome only.
The one asset in the project that is RGB on void black and must be blended additively
(`res://assets/fx/fx_ember_pulse.png`) belongs to the main menu screen, not here. If a later pass adds the
hangar lamp bloom, it must be wired as `CanvasItemMaterial.blend_mode = ADD` the same way the menu wires the
ember pulse, and the FX must not be alpha-keyed. The two `ColorRect`s the screen tints (the backdrop dim and
the leave dimmer) are drawn from `Tokens/void_base`, normal blend, no FX.

## 8. Theme items used (all present in `vajb_theme.tres`)

| Item | Used by |
|---|---|
| `PanelRaised` (`PanelContainer`, `panel` = `panel_frame` `StyleBoxTexture`) | `ModuleRail`, `ModuleHost`, `PreviewFrame`, `CreditsPanel`, `LeavePanel` |
| `StationButton` (+ `normal`/`hover`/`pressed`/`disabled`/`hover_pressed`/`focus`) | rail entries, `ShipAction`, `LaunchButton`, `LeaveCancel`, `LeaveLogout` |
| `HeroTitle` | station name |
| `StationPanelTitle` | pane titles, preview name, dialog title |
| `StationValue` | row titles, values, prices, confirm strip |
| `StationCaption` | captions, subtitles, footers, hints, dialog body |
| `SectionHeader` | column headers, group captions |
| `SlotButtonWeapon`, `SlotButtonCargo` | the slot layout plates (the shipyard's display and FITTING's selectable grid, section 5.3) and the cargo plates |
| `ItemList` (`panel`, `selected`, `hovered`, `cursor`, `font_size`) | the cargo manifest |
| `ScrollContainer` (`panel`), `VScrollBar` (`scroll`, `grabber`, `grabber_highlight`) | the three list scrolls |
| `Tokens/void_base`, `void_fade`, `void_panel_raised`, `metal_dark`, `metal_mid`, `metal_light`, `text_primary`, `text_dim`, `accent_danger`, `accent_danger_bright` | all colour, pushed in script through `get_theme_color(token, &"Tokens")` |

Two implementation notes that are not the mockup's to fix: the `ScrollContainer`'s `horizontal_scroll_mode` is
set to `0` on all three lists because the theme registers no `HScrollBar` chrome (a horizontal bar would fall
back to the engine default); and the `VScrollBar` chrome is configured but was never seen in a render, because
five or six 76 px rows never overflow a 690 px scroll area at 1080p.

## 9. Motion table

`Tween` only, never `_process`. Every tween is created with `create_tween()` from the screen node, held in a
local array and killed in `_exit_tree()` when it is still valid. Curves are Godot's `TRANS_*` / `EASE_*`.

| Beat | Target | Property | From -> To | Time | Transition / ease |
|---|---|---|---|---|---|
| Entry | `BackdropDim` | `color:a` | 0 -> 0.72 | 0.45 | linear |
| Entry | `Header` | `modulate:a` | 0 -> 1 | 0.30 | linear, delay 0.06 |
| Entry | `ModuleRail` | `modulate:a` | 0 -> 1 | 0.30 | linear, delay 0.12 |
| Entry | `ModuleHost` | `modulate:a` | 0 -> 1 | 0.30 | linear, delay 0.18 |
| Entry | `Footer` | `modulate:a` | 0 -> 1 | 0.30 | linear, delay 0.24 |
| Entry | `CreditsValue` | counting 0 -> balance | 0.60 | `TRANS_CUBIC` / `EASE_OUT` (measured: settled by frame 40, 0.66 s) |
| Module switch | outgoing pane | `modulate:a` | 1 -> 0 | 0.12 | `TRANS_QUAD` / `EASE_IN`, then `hide()` |
| Module switch | incoming pane | `modulate:a` | 0 -> 1 | 0.18 | `TRANS_CUBIC` / `EASE_OUT`, then focus the module's first row |
| Row hover | row icon | `modulate:a` | 0.72 -> 1.0 | 0.09 | linear |
| Row hover out | row icon | `modulate:a` | 1.0 -> 0.72 | 0.09 | linear |
| Row focus / select | row | `button_pressed` + theme `focus` ring | instant | - | ring = 1 px `accent_danger_bright`, measured as a 1390x76 outline of 2940 px |
| Credits change | `CreditsValue` | counting old -> new | 0.35 | `TRANS_CUBIC` / `EASE_OUT` |
| Refusal pulse | price cell + `CreditsPanel` | `modulate:a` | 1.0 -> 0.35 -> 1.0 -> 0.35 -> 1.0 | 0.12 / 0.16 / 0.12 / 0.16 | `TRANS_SINE` |
| Launch arm | `LaunchButton` | `font_color` override + `modulate:a` | `accent_danger_bright`, 1.0 -> 0.70 -> 1.0 -> 0.70 -> 1.0 | 0.16 x4 | `TRANS_SINE` |
| Launch arm expiry | `LaunchButton`, `ConfirmStrip` | colour reset + text | at 3.0 s (`ARM_SECONDS`) | - | one-shot `Timer` |
| Launch fire | `Fade` | `color:a` | 0 -> 1.0 | 0.45 | `TRANS_CUBIC` / `EASE_IN` |
| Launch fire | `Fade` | hold | - | 0.75 | `tween_interval` |
| Launch fire | `Fade` | `color:a` | 1.0 -> 0 | 0.60 | `TRANS_SINE` / `EASE_OUT`, then the strip resets |
| Idle (ambient) | `Grain` | `modulate:a` | 0.06 -> 0.11 -> 0.06 | 5.0 + 5.0 | `TRANS_SINE`, looping |
| Idle (ambient) | `StatusBeacon` | `modulate:a` | 1.0 -> 0.35 -> 1.0 | 2.4 + 2.4 | `TRANS_SINE`, looping (measured: rgb 78.7 -> 181.0 across frames 20..36) |

## 10. Focus and input

| Input | Context | Effect |
|---|---|---|
| `ui_down` / `ui_up` | any focused control | Godot's default focus neighbour walk (tree order), which stays inside the visible pane and then crosses to the next pane or the rail |
| `Tab` / `Shift+Tab` | anywhere | next / previous focusable in tree order: rail entries (the shipped order is OUTFITTING, REFINERY, EXCHANGE, **AUCTION**, SHIPYARD, FITTING, REPAIRS, LAUNCH, plus LOG OUT — `station.gd`'s `MODULE_LABELS`) then the active pane's controls (rows, or the cargo `ItemList` and `LaunchButton`), then wraps |
| `Tab` / `ui_down` / `ui_up` | the FITTING pane | the SLOT LAYOUT cells first (row-major), then the OWNED MODULES rows, then the pane's own footer, then the rail (section 5.3) |
| `ui_accept` | a row | buy / install / set active / select the hull for the preview |
| `ui_accept` | a rail entry | switch module (the rail entry is a `toggle_mode` button; the pressed state is pushed with `set_pressed_no_signal`) |
| `PageUp` / `PageDown` | anywhere | previous / next module, wrapping (mockup reads `KEY_PAGEUP`/`KEY_PAGEDOWN` directly because `station_prev_module` / `station_next_module` are not in the input map yet, section 14 item 6) |
| `JOY_BUTTON_LEFT_SHOULDER` / `RIGHT_SHOULDER` | anywhere | previous / next module |
| `ui_cancel` | confirm open / armed / elsewhere | close / disarm / focus the current rail entry, then open the leave confirm (section 2) |
| mouse move over a row | - | icon `modulate:a` to 1.0 and the mouse cursor becomes a pointing hand |
| mouse click on a row | - | select and act (the row is a `Button`, so the click is the `pressed` signal) |

One focus ring only: the theme's shared `focus` `StyleBoxFlat` (1 px `accent_danger_bright`, no fill),
measured on the focused row as a single 1390 x 76 outline and on the LAUNCH button as a 360 x 85 outline. The
selected row adds a second, non-colour channel: the row's background switches to the `Button` pressed
`StyleBoxFlat` (`void_panel_raised`, measured (16,21,29) against (27,32,40) on an unselected row), so
"selected" survives a colour-blind reading.

## 11. Audio hooks

`AudioManager` (`autoload/audio_manager.gd`) resolves a cue only inside the directory mapped to its bus key
(`Paths.AUDIO_DIRS`), with an exact-name-first, `_01`-fallback, `.ogg`-only lookup.

| Moment | Call | File it resolves |
|---|---|---|
| Station entered | `play_ambience(&"amb_station_room_01", 2.0)` | `res://assets/audio/ambience/amb_station_room_01.ogg` |
| SHIPYARD entered | `play_ambience(&"amb_station_pump_loop_01", 1.0)` | `res://assets/audio/ambience/amb_station_pump_loop_01.ogg` |
| FITTING entered | `play_ambience(&"amb_station_noise_loop_01", 1.0)` | `res://assets/audio/ambience/amb_station_noise_loop_01.ogg` (the retired UPGRADES module's cue, kept under the new label) |
| Module switched (rail, PageUp/Down, shoulder) | `play_sfx(&"sfx_station_breaker_on_01")` | `res://assets/audio/sfx/sfx_station_breaker_on_01.ogg` |
| Row hover / focus move | `play_ui(AudioManager.UiCue.HOVER)` | `res://assets/audio/ui/ui_hover.ogg` |
| Row press, rail press, dialog button | `play_ui(AudioManager.UiCue.CLICK)` | `res://assets/audio/ui/ui_click.ogg` |
| Purchase or install succeeds | `play_sfx(&"sfx_station_hum_loop_01")` today; should be `ui_confirm_01` (see below) | `res://assets/audio/sfx/sfx_station_hum_loop_01.ogg` |
| Refusal (`purchase_failed`) | should be `ui_denied_01` (see below) | `res://assets/audio/ui/ui_denied_01.ogg` (on disk, unreachable) |
| List scrolled | should be `ui_scroll_01` (see below) | `res://assets/audio/ui/ui_scroll_01.ogg` (on disk, unreachable) |
| LAUNCH armed | `play_sfx(&"sfx_station_breaker_on_01")` | the breaker file above |
| LAUNCH fired | `play_sfx(&"sfx_ship_boost_01")` then `play_sfx(&"sfx_ship_jump_01")` | `res://assets/audio/sfx/sfx_ship_boost_01.ogg`, `res://assets/audio/sfx/sfx_ship_jump_01.ogg` |
| LOG OUT confirmed | `play_ui(AudioManager.UiCue.CLICK)` then `stop_ambience(1.0)` | `ui_click.ogg` |
| Idle machinery | `play_sfx(&"sfx_station_machine_loop_01")` at low volume under the ambience | `res://assets/audio/sfx/sfx_station_machine_loop_01.ogg` |

**Reachability gap (matches `ASSET_AUDIT.md` section D.1).** `UiCue` has exactly two members, `CLICK` and
`HOVER`, and `play_sfx` searches only `assets/audio/sfx/`, so the three UI files that live in
`assets/audio/ui/` (`ui_confirm_01.ogg`, `ui_denied_01.ogg`, `ui_scroll_01.ogg`) cannot be played by any
current call. Either add three `UiCue` members (and three `UI_CUE_NAMES` entries) or add a `play_ui_cue(cue:
StringName)` that searches the `ui` directory; until then purchase, refusal and scroll are silent.

## 12. Implementation notes for the coder

**12.1 Files to create.**

| Path | Contents |
|---|---|
| `vajb-orbit/ui/screens/station.tscn` | `Control` root, preset 15, `extends Screen`, bakes `theme = vajb_theme.tres` (Router replaces it with the live theme). Contains the backdrop, the grain, the safe area, the header, the rail, the host and the footer, and hosts one panel per rail entry (the panels are loaded from `MODULE_FILES`, so adding AUCTION needs no `station.tscn` edit). |
| `vajb-orbit/ui/station/outfitting_panel.tscn` | OUTFITTING: header, columns, scroll, rows, footer. |
| `vajb-orbit/ui/station/shipyard_panel.tscn` | SHIPYARD: hull list, preview housing, stat column. |
| `vajb-orbit/ui/station/fitting_panel.tscn` | FITTING: the SLOT LAYOUT grid (the shipyard's recipe with selectable cells, section 5.3), the OWNED MODULES rows, the power meter and the footer strip. |
| `vajb-orbit/ui/station/launch_panel.tscn` | LAUNCH: brief, cargo strip, manifest, deck control. |
| `vajb-orbit/ui/station/refinery_panel.tscn` | REFINERY: ore table, conversion stepper, totals, actions (amendment 5.7). |
| `vajb-orbit/ui/station/exchange_panel.tscn` | EXCHANGE: hold, market board, trade column (amendment 5.8). |
| `vajb-orbit/ui/station/repairs_panel.tscn` | REPAIRS: damage report, fee, repair control (amendment 5.9). |
| `vajb-orbit/ui/station/auction_panel.tscn` | AUCTION: the HULLS and MODULES lists, the `SELL MODULES` sub-list, the rotation footer (amendment 5.10). |
| `vajb-orbit/ui/paths.gd` (edit) | add `&"station": "res://ui/screens/station.tscn"` to `ROUTES`. |
| `vajb-orbit/ui/screens/loading.gd` (edit) | map `destination == &"station"` to the station route. |

**12.2 Build order.** Backdrop and grain first (they are the only full-rect layers), then the safe area and the
three bands, then the rail (it is the navigation contract and the focus entry point), then the host and one
panel, then the other panels by copying the first. Do not build the header credits housing before the
rail: the rail's 56 px entry height and the 360 px rail width are the two numbers the rest of the screen is
aligned to.

**12.3 Constants (carried from the mockup, keep them as named constants).**

| Constant | Value | Meaning |
|---|---|---|
| safe margin | 24 | all four sides of `Layout` |
| band separation | 16 | `Page` vertical separation |
| header height | 76 | `Header.custom_minimum_size.y` |
| rail width | 360 | `ModuleRail.custom_minimum_size.x` |
| rail entry height | 56 | each rail `Button` |
| rail/host inner margin | 12 / 20 | `RailMargin` / `HostMargin` |
| pane separation | 12 | the pane `VBoxContainer` |
| row height / gap | 76 / 6 | `ROW_HEIGHT` / `ROW_GAP` |
| row inner margin | 12 / 8 | `RowInner` |
| columns | icon 40, held 130, effect 300, price 110, status 160, ship status 130, brief value 220 | fixed pixel widths |
| ship list / preview / stat min widths | 340 / 260 / 300 | shipyard body |
| brief / action min widths | 560 / 360 | launch body |
| slot layout / cargo plates | 48 / 40 | separation 4 / 6: the grid's cell count and `columns` come from the selected hull's matrix (08 §3.2), the cargo strip is 5 cells |
| preview scale / max width | 0.70 / 480 | ship image |
| arm window | 3.0 s | `ARM_SECONDS` |
| entry / module / hover / credits timings | 0.30 / 0.12 + 0.18 / 0.09 / 0.60 + 0.35 s | section 9 |

**12.4 Data wiring (replace every stub).** The panels read `StationCatalog` and `PlayerProfile`; the screen
never writes `user://profile.cfg` and never mutates a catalogue entry.

- Panels get the profile by `get_node_or_null(^"PlayerProfile")` (autoload names are not resolvable
  identifiers until the project patch lands, the same reason `router.gd` looks services up by name).
- `profile_changed(key)`: `&"credits"` refreshes the readout and every price/tag; `&"ammo"` rebuilds
  OUTFITTING's held counts; `&"ships"` rebuilds SHIPYARD; `&"fits"` and `&"modules"` rebuild FITTING's grid,
  OWNED MODULES rows and power meter; `&"cargo"` rebuilds LAUNCH's manifest and plate strip.
- `purchase_failed(reason, id)`: map `&"insufficient_credits"` -> `REFUSED · NOT ENOUGH CREDITS`,
  `&"already_owned"` -> `REFUSED · ALREADY OWNED` / `REFUSED · ALREADY ACTIVE`, `&"unknown_id"` ->
  `REFUSED · NOT FOR SALE`, write it into the status strip in `accent_danger`, run the 4-step pulse on the
  credits housing, and leave focus and the selection alone. Never open a dialog for a refusal.
- Affordability is presentation only: grey the price with `can_afford(cost)` and the tag with `owns_ship` /
  `module_count`, but always let the profile make the decision.
- `LAUNCH` declares `route_requested(&"loading", {destination: &"game"})`; `LOG OUT` declares
  `route_requested(&"main_menu")`. The screen does not call `change_scene`, does not import `PlayerState` and
  does not seed it (that is `game.gd`'s job).
- `ui_scale`: nothing else to do. Router assigns the live theme to the routed root, and every text node names
  one of the section 8 variations, so all 27 font-size items scale together. Do not add a per-node font size
  override; the mockup's cmdline scale stand-in was removed for exactly this reason.

**12.5 Values the mockup copies and the coder must read instead (all of them).** Every ammo pack
(`id`, `name`, `rounds`, `cost`, `icon`), every ship (`id`, `name`, `cost`, `preview`, `hull`, `shield`,
`cargo`, `hardpoints`), the five advisory hold
capacities, the stub credit balance 4900, the owned ships `[ship_vanguard, ship_fighter]`, the active ship
`ship_vanguard`, the ammo counts
`{laser 300, cannon 140, rocket 60, mine 300, plasma 0}` and the cargo manifest
(`ore_fragment` 22, `data_core` 2, `salvage_plate` 11). None of these are literals in the shipping screen:
they are `StationCatalog` reads and `PlayerProfile` calls. The mockup also hard-codes two strings the real
screen computes: the destination line and the `IDS laser · cannon · rocket · mine · plasma` panel tag.

**12.6 Delete when the real screen lands:** `ui/screens/_mockup_station.tscn`, `_mockup_station.gd`,
`_mockup_station.gd.uid`, the two `--station-module` / `--station-credits` debug arguments and the local stub
constants above.

## 13. Verification performed on the mockup

| Check | Result |
|---|---|
| Headless load, 300 frames, no input | exit 0, stdout carries only the vendored `[godot_ai game_helper]` line |
| Rendered frames at 1920x1080, four module states plus a zero-credit state | `previews/d5_station_*.png` |
| Slot layout grid (supersedes the 2026-09-18 slot plate row) | the fixed 7-plate strip this row used to measure — 7 weapon cells of exactly 48 px (x 1484..1843, pitch 52), cells 1-3 brighter than 4-7 — is replaced by the selected hull's own grid (amendment 5.2): one 48 px plate per non-gap matrix cell of 08 §3.2, `columns` = the matrix width, gaps drawn as empty cells, each plate carrying its type's slot glyph. The cargo half is unchanged: 5 cargo cells of exactly 40 px (x 452..675, pitch 46) with the first 3 carrying icons |
| Focus ring | one 1390 x 76 outline of 2940 px in exact `accent_danger_bright`, and a 360 x 85 outline on LAUNCH |
| Selected row channel | pressed `StyleBoxFlat` background (16,21,29) against (27,32,40) unselected |
| Panel chrome | `PanelRaised` frame band measures 7 px + 1 px expand margin = 8 px on the rail, host, preview, credits housing and dialog, and it insets its child by 33 px per side (3.4) |
| Contrast | 11.94:1 title, 11.89:1 row values, 4.12:1 column headers, 4.05:1 footer, 3.89:1 row meta, 3.41:1 orange price (item 1 of section 14) |
| `ui_scale` 1.4 | title ink 36 -> 50 px (x1.39), nothing clips, plates still fit |
| 21:9 | rail fixed at x 23..384, host right edge 2529..2536, all vertical metrics unchanged |
| 4:3 | rail frame band starts at screen y 122 and x 17..22, panels end at screen y 1031..1036, i.e. the Body absorbed all 360 extra viewport px |
| Entry motion | near-white ink rises 0 -> 8406 -> 13151 -> 13157 px across frames 16/24/32/40 and holds |
| Idle motion | beacon rgb 78.7 -> 181.0 over frames 20..36, looping |

## 14. Open questions for the owner

1. **The orange price measures 3.41:1** against a row background, below the 4.0 floor the `text_dim` labels
   sit on. Keep `accent_danger` (the `LOCKED` tag is the second channel, so colour is never the only cue), or
   render an unaffordable price in `text_dim` and reserve the ember for damage and armed states only?
2. **Caption repetition.** Every price cell repeats the word `CREDITS` under the value and every upgrade cell
   repeats `EFFECT`, while the column header already says `PRICE` / `EFFECT`. Keep the two-line cell rhythm or
   drop the redundant captions (which would make the price cell one line, centred)?
3. **OUTFITTING leaves about a third of the host pane empty** with only five packs. Fill it (cargo hold strip,
   station notice line, a bigger row height) or accept the slack as honest emptiness?
4. **Catalogue id mismatch.** `STATION_SPEC.md` section 5 names the cargo upgrade `upgrade_extra_cargo` while
   `game/station_catalog.gd` ships `upgrade_extra`. The mockup only copies names and prices, so nothing renders
   wrong, but which id is the contract for the coder wave?
5. **Escape from a pane.** The mockup walks disarm -> rail -> leave dialog. Should the first `ui_cancel` inside
   a module instead return to the module the player came from (a back stack), or is "get out to the rail" the
   intended reading?
6. **Two module input actions, one naming gap.** The mockup reads `KEY_PAGEUP`/`KEY_PAGEDOWN` directly and the
   shoulders from `InputEventJoypadButton` because `station_prev_module` / `station_next_module` are not in the
   input map. Add both actions (and rebindable entries) in the coder wave?
7. **Unreachable cue files.** `ui_confirm_01.ogg`, `ui_denied_01.ogg` and `ui_scroll_01.ogg` exist on disk but
   no `AudioManager` call can resolve them (`UiCue` has `CLICK` and `HOVER` only). Add the three enum members,
   or a `play_ui_cue(cue: StringName)` that searches the `ui` directory?
8. **Frame thickness parity with the menu.** This screen's `PanelRaised` renders an 8 px frame band (7 px
   painted plus the 1 px `expand_margin`), while `_mockup_main_menu.tscn` draws the same art through a
   `NinePatchRect` at 7 px. Unify on one number, or accept the 1 px difference?
9. **The rail at `ui_scale` 1.4.** The rail is a fixed 360 px, so its 22 px labels grow to 31 px inside a
   56 px entry and stay legible, but the rail could scale its width too. Is a fixed rail the contract, or
   should the rail width follow the font scale?
10. **The 33 px `PanelRaised` inset.** Every framed panel loses 33 px per side to the stylebox's content
   margin (3.4), which makes the credits housing 123 px tall and sets the header band's height. Keep it (the
   frames read as thick housing, which matches the menu), shrink the inner margins to compensate, or regenerate
   `ui_panel_frame.png` at a smaller `texture_margin` (14 px would give the 7 px painted frame plus a normal
   1 px border footprint)?
