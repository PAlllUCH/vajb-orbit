# D18-A1 mockup — the MapDeck and the navigation pin (wireframe)

Design law: `docs/design/UI_SPEC.md` §9 (N1–N6) + §10 (this wave's detail) +
§3.10 A5.1–A5.4 (composition/chrome). Wireframes, not rendered plates: the wave
is design-only (D16 precedent). Sizes schematic; ruled numbers live in the law
blocks. `ui_minimap_bezel.png` (ASSET_CATALOG.md:443, 200×200, band 16) is the
compact map's own chrome and does not move.

## The MapDeck pane (M · corner button · ESC — N1)

`PanelContainer` on A5.4 `Pane outer edge` chrome (`ui_panel_frame`,
ASSET_CATALOG.md:444, 96×96, band 32), centred at 80 % of the viewport.
Inside: one `HBoxContainer` — the map viewport (expand) beside the filter
column (`custom_minimum_size (240, 0)`, PROPOSED; reversal `(180, 0)`).

```
+============================================================================+
||  [ MAP VIEWPORT — zoom 25%–400%, cursor-centred (N2) ]   ||  MAP FILTERS  ||  [1]
||                                                          ||  ------------ ||
||        ◇ S3 outpost        ◇ S4 gate                     ||  STATIONS  ON ||  [2]
||                                                          ||  GATES     ON ||
||              ( self blip, rose, contact blips —          ||  AST. FIELDS ON||
||                the compact map's own classes )           ||  POIS      ON ||
||                                                          ||  HOSTILES  ON ||
||              ◆ DIST 4 512   ← the nav pin (N4)           ||  FRIENDLY  ON ||
||                  and its edge bearing arrow →            ||  CARGO &    OFF||
||                                                          ||    WRECKS     ||
||                                                          ||  CONTRACTS OFF||
||                                                          ||                ||
|+----------------------------------------------------------+----------------+|
||  ZOOM 100% · DRAG PAN · WHEEL ZOOM · CLICK PIN · HOLD JUMP  [ − ][ + ] [EXPAND]|| [3][4]
+============================================================================+
```

Compact minimap, corner EXPAND button = a 36×36 `TextureButton` beside the
shipped `ZoomMinus`/`ZoomPlus` (`hud.tscn:409-431`, the footer's own idiom).

## Element law

| # | Surface | Chrome (A5.4 row) | Asset / theme cite | Tick |
|---|---|---|---|---|
| 1 | deck pane | A5.4 `Pane outer edge` | `ui_panel_frame` (ASSET_CATALOG.md:444); N1's 80 % | N1 |
| 2 | filter column: caption + toggle rows (56 min, label + trailing `ON`/`OFF` state, never colour alone — N3) | A5.4-2 service-strip button (theme cite, no asset) | base `Button` bevel + `StationValue` label (the auction tab idiom, `auction_panel.gd:98-100`); persistence through `PlayerProfile` (`user://profile.cfg`, 01 §7) | N3, N7 |
| 3 | deck footer: zoom read + hint line | A5.4-3 caption strip | theme `StationCaption` 13 | N8, N9 |
| 4 | zoom/expand buttons | compact map's own footer idiom | `icon_zoom_plus/minus.svg` (ASSET_CATALOG.md:310-311), 36×36 `TextureButton` (`hud.tscn:409`) | N2 |
| — | STATION/GATE blips always drawn (N6): the exemption rides `KIND_STATION`/`KIND_GATE` (UI_SPEC §10 N15/N16, PROPOSED — until they ship nothing is exempt); `KIND_SELF` carries no toggle and is never filterable | — | `minimap.gd` blip classes | N6 |

Pan/zoom (N2): LMB drag pans (8 px threshold before a drag counts — N14);
wheel zooms 25 %–400 % centred on the cursor; arrow keys pan in 64 px steps.
Toggle→blip-class mapping: `docs/design/UI_SPEC.md` §10 (N15–N23).

## The navigation pin (N4) — states

```
PRESS-DOWN (deck, no drag yet)     RELEASE < 0.5 s           HOLD ≥ 0.5 s
+---------------------------+      +---------------------+   +----------------------+
|  pin ◆ placed here        |      |  autopilot order to |   |  N5 installed:       |
|  (placed at press-down;   |      |  pin — the          |   |  HYPERDRIVE SPOOLING |
|  never follows cursor)    |      |  existing API       |   |  1 s → jump flash    |
+---------------------------+      |  set_move_target()  |   +----------------------+
                                   +---------------------+   |  no N5:              |
        CLICK ON THE PIN                                    |  NO HYPERDRIVE       |
        +---------------+    STICK INPUT (any)              |  INSTALLED           |
        | pin removed,  |    cancels the order              |  (caption under pin) |
        | order stays   |    (player_ship.gd:816)           +----------------------+
        +---------------+
```

- Hit-test precedence (UI_SPEC §10): a press that hits the pin is a **remove
candidate and never a place or move**; place/move applies only to a press that
misses the pin.
- Short press on the deck (missing the pin) = place **and** issue the order:
one action, one press (`set_move_target`, `player_ship.gd:419`;
`cancel_orders`, `:426`). Short press **on the pin** = remove.
- The pin is placed at press-down and never follows the cursor: a held move
past N14's 8 px threshold is a pan (N2), not a pin move.
- The hold path is armed from press-down (pin already placed), so hold-to-jump
  works on fresh pins and on the existing pin alike.

## The pin's reads

| Read | Where | Wording (tick) |
|---|---|---|
| diamond mark | deck at the pin; compact map if the pin is in view | code-drawn mark in its own child rect, A5.2(iii) — `text_primary`, 6 px (friendly blips are 3 px, `minimap.gd` FRIENDLY_RADIUS; PROPOSED, reversal: `accent_ember`) |
| edge bearing arrow | compact map, clamped to the bezel's inner edge when the pin is out of view | code-drawn mark in its own child rect, A5.2(iii) |
| distance read | deck, under the pin; compact map, appended to the footer's `SectorLabel` (`hud.tscn:401`) | `DIST <n>` — **N10** |
| no-hyperdrive caption | under the pin | `NO HYPERDRIVE INSTALLED` — N4's own wording |

## Hyperdrive (N5) — spool, cooldown, arrival

```
deck footer while the module is fitted:
  idle            JUMP READY                       (N12)
  spool           HYPERDRIVE SPOOLING 1 s  ▓▓▓░░   (N11; N5's 1 s)
  cooldown        JUMP COOLDOWN 12 s               (N12; N5's 30 s)
  arrival         ARRIVED · S4 OUTPOST             (N13, ~2 s, then idle)
```

The spool/cooldown/arrival reads live in the deck footer's caption strip
(A5.4-3); the compact map carries none of them (it ships as today plus the pin
arrow and the N6 blips). The arrival **FX** is staged on the art budget
(D18_BRIEF.md §10) — this wave's arrival state is the read + the blip
re-centring only. A jump while the cooldown runs is refused with the cooldown
read itself (label + state, never colour alone).
