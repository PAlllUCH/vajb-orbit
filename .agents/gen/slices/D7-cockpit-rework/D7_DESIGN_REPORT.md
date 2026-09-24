# D7_DESIGN_REPORT — the approved cockpit look (for the implementing developer)

**Status: design complete, owner-approved 2026-09-24.** Mockup v4 approved
("Mockup looking good"); **v5** is the same look with a measured containment fix
(no look change). Implement from this report + the pinned docs it points to; the
mockup script is the geometry source of truth.

## Artifacts

| What | Where |
|---|---|
| Approved mockup (928×512 = the 464×256 box at 2×) | `staging/mockup/out/cockpit_mockup_v5.png` (viewer `.jpg`) |
| Mockup script (geometry + palette reference) | `staging/mockup/cockpit_mockup.py` |
| The pins (law) | `docs/design/UI_SPEC.md` §3.6/§3.7 **as amended 2026-09-24** incl. the "Mockup v5 approved" block, §3.9 (the language), §3.10 (battery window) |
| Shipping art prompts + QC | `docs/design/UI_CHROME_ASSETS_SPEC.md` §12 (+ its post-mockup amendment) |
| Names | `docs/design/ASSET_NAMING_SPEC.md` §12 |
| Wave mechanics (workers, files, tests, close-out) | `D7_BRIEF.md` + `D7_prompts.md` (this slice folder) |

## What ships (the cluster)

One painted metal panel (`ui_cockpit_panel`, 928×512 master, fill-fit — no
nine-slice) with bolt heads and three recessed wells. Palette: Panel-Steel
`#2A2E35` family, Bone `#C9CDD2` glyphs, `text_dim` labels, ember `#C8461B`/
`#E8703A` for danger + the lit battery lamp. No glass, no screens (§3.9).

**Geometry (logical / 2× measured from the mockup):**

| Element | Logical | 2× (mockup px) |
|---|---|---|
| Panel outer / interior / band | 464×256 / 400×192 / 32 | 928×512 / 800×384 / 64 |
| Left bay | gauge well Ø120 + lamps row + AMMO strip | gauge centre (190,172) r 112+rim |
| Speed dial | 120×120 in its well | face r 106; 10 rim wedges 270° (gap bottom); 8 graduated ticks (longer toward top); prograde needle; **no heading tick** |
| Battery lamps | 5 × 22×22, 3 gaps, 122 wide, above AMMO | (70,302)–(314,346), lamps 44² gap 6 |
| AMMO strip | 126×36 (label 36 + 4 drums) | recess (64,370)–(316,442); lit glyphs x 213–307 |
| Compass bay | rose 96×96 in Ø108 well + HDG strip 104×36 | centre (434,172); cardinals at r 84; recess (330,370)–(538,442); glyphs x 481–531 |
| Readout stack | 5 rows × 36, 2 pitch, 150×190 well | (558,62)–(858,442); rows pitch 76; glyphs ENRG row x 669–806 |
| Foot band | all foot drums y 375–437 identical (2×) | bottoms lined up across AMMO / HDG / ENRG |

**Digit drums:** bare seven-segment glyphs (no per-cell plates — the D6 cells are
re-authored glyph-only under the same `ui_seg_*` names, UI_CHROME §12 amendment),
fill-fitted to 20×36 on a 22 px pitch, **leading blanks never zeros**. `%` cell
only on FUEL/ENRG. Semantics: SPD `round(prograde.length())` 4 cells 0..9999;
HULL/SHLD points 4 cells; FUEL/ENRG percent 3 cells + `%`; AMMO loaded rounds
4 cells 0..9999; HDG 0..359 3 cells. Digits never recolour.

**Danger rows (demoed on FUEL 15 %):** label `accent_danger(_bright)` + 1 px
code-drawn frame; overdrive (`ratio > 0.9` strict) frames SPD and modulates the
needle. §3.1/§3.1b verbatim.

**Compass:** engraved rose rotates `-heading.angle()`, fixed lubber triangle,
**N/E/S/W as engine `Label`s** at r 42 rotating with the card (text upright; N
`text_primary`, rest `text_dim`) — owner's 2026-09-24 ruling, reverses the old
staged-out call. `compass()`/`compass_heading()`/`readouts()`/`cockpit()` all
survive (CONTRACTS §18).

**Battery lamps:** `B1..B5` = the in-flight rack selector (`weapon_1..5` state).
Lit: dark-ember fill + `accent_danger_bright` border + bright label. Unselected:
`void_panel_raised` + `metal_dark` border + `text_dim`. The family name reads on
`ship_status` (§3.8), not in the cluster. Code-drawn.

**Gone:** the dial's heading tick (§3.6 amendment), the readout glass + frame in
the cluster, the old HUD column (§3.1 crest bars, §3.2 `AmmoPanel`, §3.4 cargo
block). Every §7 frozen method keeps its signature.

## What ships (the battery window)

Armory BATTERY RACKS window on the same language (§3.10): `ui_armory_console` +
`ui_armory_rack_plate` per rack + `ui_armory_row_plate` rows, SALVO cycle as a
3-cell drum (proposed seconds ×10; plain `Label` is the recorded fallback).
Transactions, drag-drop and refusals untouched. **The armory has no mockup round
yet** — same language as the cluster; a look round can run the same loop on
request before A0.

## Acceptance checks (probe-able)

1. Lit-glyph containment: no glyph crosses its well (fixture boxes above).
2. Foot band: AMMO / HDG / ENRG drum groups share identical bottom edges.
3. The dial draws no heading tick; the compass is the only heading instrument.
4. Cardinal Labels exist at the rotating rim positions; none baked in art.
5. Lamps map to the selected rack; exactly one lit.
6. Old HUD column absent; HULL/SHLD/AMMO read from the cluster.
7. `test_engine2_hud.gd` §3.6 rows byte-green except the retired heading-tick
   rows; `test_p2b*`/`test_s5_*` byte-green; no frozen file moved.

## Owner ticks

Resolved by this design: compass survivor (rose), look + box (464×256), battery
group (lamps + AMMO), foot unification, cardinal values IN. Open: SALVO drum
format (proposed seconds ×10), armory mockup round (optional), and the D6
carry-overs (NMS teal, HULL/SHLD %, key U, per-module damage).

## The approved mockup set (owner 2026-09-24: "Looks good. lets do this")

| Mockup | Artifact | What it pins |
|---|---|---|
| Cockpit cluster | `staging/mockup/out/cockpit_mockup_v5.png` | the geometry table above (already in this report) |
| **A — battery window** | `staging/mockup/out/armory_mockup.jpg` | §3.10's approved SALVO drum format (seconds ×10 — `073` = 0.73 s) + bay geometry: 4+3 grid, bay 97×91, 4 slot recesses 20×22 on a 22 pitch, `B#` + key-hint Labels, engraved ledge, SALVO strip; selected bay carries the §3.2 ember frame; inventory rows 22 tall, ammo rows 32 tall with the danger treatment |
| **B — game context** | `staging/mockup/out/context_mockup.jpg` | the in-flight composition: the cluster at bottom-left, minimap bottom-right, **no old HUD column anywhere**; reticle brackets + micro-bar stay |
| **C — ship status** | `staging/mockup/out/status_mockup.jpg` | §3.8 restyle (**now in wave scope**, staging reversed): `ui_status_panel` console, left well (24,60)–(300,428) with the aspect-fit hull render + bone-ringed ember hardpoint dots + damaged-cut swap, right well (316,60)–(696,348) with the 5×3 slot grid (60×74 cells, 72×88 pitch, `W1..W5` Labels), footer strip (24,444)–(696,494) `HULL/SHLD/PWR` cur-max Labels, title + close box |

`ui_status_panel` joins the §12 batch (run 5, master 1440×1040); the wave's art
cost is 5 × 2K ≈ $0.25. All four mockups' textures are procedural stand-ins for
the §12 painted renders; proportions and states are exact.

## Notes for the wave runner

- The wave is `dispatch_designer.md` item 8; run order A0 → owner sheet → A0b →
  C1 → C2 → R1 → (F1 on HIGH/MED). The D7_BRIEF pins predate this report's three
  deltas + cardinals — where they conflict, **this report + UI_SPEC §3.7's
  "Mockup v5 approved" block win**.
- Mockup textures (brushed noise, wells, bolts) are procedural stand-ins; shipping
  surfaces are the §12 painted renders. The mockup's proportions and states are
  exact.
- This design package rides the wave's pre-dispatch `git add -A` snapshot (the
  D7_prompts.md line) unless committed earlier at the owner's word.
