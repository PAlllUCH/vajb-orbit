---
slice: S37
worker: S37-R1
model: hyper/glm-5.3-flash
status: informational
gate: "n/a — no production file touched (AC3)"
---

# S37-R1 report

## Result
Headless probe walked the station at 1920x1080 (7 decks, both ARMORY modes, open drawer,
tooltip, shell): **245 chrome-bearing surfaces, 180 too small, 109 off-aspect**. Three
mechanical causes, all measured: (1) canvas classes (C1/C2/C5/C9) letterbox — the drawn
*art* is 75 % or less of the slot and its opaque rail band is far thinner than the
icon+text that sits on the full slot; (2) C4/C3 nine-slice rows/chips draw at 1.2–3.1x the
cut's aspect with caps scaled up to 45/57 px, leaving a 4–33 px inner band under 19–64 px
of content; (3) theme plates (`ui_button_plate` 280x56, `ui_panel_frame`) are wired with no
texture margins, so every non-5:1 button smears the whole texture.

## Acceptance list answers
1 — DONE — the probe prints deck/kind/class/flags/slot/drawn/band/need/content/both
deficits/stretch/margins/content-margins/band_ok/node per surface (`probe_s37_r1_scene.gd:206-232`).
2 — DONE — table below covers every drawn<needed family incl. all five owner-named
surfaces; full log `/tmp/s37_probe.log` (245 SURF lines).
3 — DONE — only `vajb-orbit/tests/probe_s37_r1_scene.{gd,tscn}` + this report exist.

## Findings (worst-first; need = icon+font-measured text +10 % on the dominant axis)
| surface | deck | class | drawn rect | band (visible chrome) | need | deficit (need−drawn / −band) | stretch | wiring |
|---|---|---|---|---|---|---|---|---|
| shelf rows ×26 | AUCTION | C4 | 1756x76 | 1524x33 | 1878x60 | +122x / +354x +27y | 3.14 | auction_panel.gd:824 |
| service rows ×3 | OVERVIEW | C4 | 1756x76 | 1524x33 | 1860x60 | +104x / +336x +27y | 3.14 | overview_panel.gd:340 |
| ship row | SHIPYARD | C4 | 338x76 | 294x33 | 462x44 | **+124x (content itself overflows the row by 82)** | 0.60 | shipyard_panel.gd:398 |
| rack barrel-name | ARMORY-batt | plate | 68x86 | 68x86 | 142x54 | +74x | 0.16 | vajb_theme.tres:451 |
| module host | shell | frame | 1872x860 | 1808x796 | 1945x871 | +73x +75y (content 871 > band 796) | 2.18 | vajb_theme.tres:90-99 |
| browser rows ×9 fit | ARMORY | C4 | 864x76 | 750x33 | 897x64 | +33x / +147x +31y | 1.54 | armory_panel.gd:4122 |
| browser rows ×5 batt | ARMORY | C4 | 874x76 | 758x33 | 908x64 | +34x / +150x +31y | 1.56 | armory_panel.gd:4122 |
| board rows ×40 | EXCHANGE | C4 | 784x76 | 680x33 | 793x60 | +9x / +113x +27y | 1.40 | exchange_panel.gd:430 |
| hold rows ×2 | REFINERY | C4 | 686x76 | 596x33 | 701x60 | +15x / +105x +27y | 1.23 | refinery_panel.gd:407 |
| job row (INGOTS·COLLECT) | REFINERY | C4 | 686x56 | 596x25 | 263x24 | fits, but 56 < C4 band-min 64 (band_ok=n) | 1.66 | refinery_panel.gd:707 |
| mode chips ×2 | ARMORY | C3 | 96x32 | 67x4 | 102x19 | +6x / +35x +15y | 1.00 | armory_panel.gd:972-976 |
| drawer plate | drawer | frame | 362x859 | 298x795 | 169x839 | / +44y | 0.42 | vajb_theme.tres:458 |
| hold row ×1 | EXCHANGE | C4 | 558x76 | 484x33 | 527x60 | −31x / +43x +27y | 1.00 | exchange_panel.gd:569 |
| drawer entries ×8 | drawer | C9 | 274x56 | **274x18.6** | ≤168x40 | −110x / **+21.4y** | 1.00 | station.gd:571 |
| tiles ×6 | OVERVIEW | C1 | 567x140 | **567x57** | ≤231x74 | / **+17y** | 1.00 | overview_panel.gd:264 |
| actions ×7 | ARMORY/SHIP/LAUNCH | C2 | 360x56 | 349x16.5 | ≤195x29 | / +12.5y | 1.00 | armory_panel.gd:3104, shipyard_panel.gd:230, launch_panel.gd:210 |
| chips ×~60 all decks | all | C3 | 96x32 | 67x4 | ≤52x19 | / +13..17y (text over caps) | 1.00 | inspect_chip.gd:32 |
| steppers/queue/load/collect/upgrade/sell-all | REF/EXCH | plate | 24x29…360x56 | — | ≤140x32 | +18x (upgrade 179x40); st 0.2–1.29 | 0.20–1.29 | vajb_theme.tres:510 |
| tooltip | tooltip | C7 | 360x194 | 327x148 | 396x80 | +69x (text full-bleed over side caps, cm l/r=0); +114y of bevel padding | 1.24 | tooltip.gd:38, chrome_family.gd:167-173 |
| credits panel | shell | frame | 226x122 | 162x58 | 143x42 | fits (slack) | 1.85 | vajb_theme.tres:458 |
| preview frame | SHIPYARD | frame | 932x635 | 868x571 | 538x593 | / +22y | 1.47 | shipyard_panel.gd |

Measured CLEAN (owner's "stretched slots" exonerated): ARMORY EQ grid plates 48x48
(`SlotButtonWeapon`, glyph 36, stretch 1.000 — vajb_theme.tres:494, armory_panel.gd:3241),
SHIPYARD hardpoint TextureButtons 48x48, LAUNCH cargo slots 40x40, the 20 salvo seg cells
(stretch 1.03), and the console's code-drawn bays 876x116 / cells 92x96 whose slot plate is
drawn at its own 48x48 centred, never stretched (armory_panel.gd:805-817; ConsolePanels
geometry in the log's CONSOLE line).

## Why (per family)
- **Canvas letterbox (C1/C2/C5/C9)** — `make_canvas` keeps the cut's aspect inside the
  slot (chrome_family.gd:205-231). Cut aspects 4.05–6.43 vs slots 4.9–9.9 (or taller) leave
  the art at 42.6/56 (drawer), 57/140 (tiles), 16.5/56 (actions) drawn height; the opaque
  rail inside the cut is thinner still (C9: 49/112 of the cut = 18.6 px drawn). Content is
  laid on the FULL slot rect, so it rides over the art edges — the owner's "text goes over
  them". The fix family is a cut at the slot's own aspect, never a stretch.
- **Nine-slice caps (C3/C4/C7)** — margins scale with the drawn rect
  (chrome_family.gd:131-144): C4 rows draw 45–116 px side caps and 18+25 px bands, so the
  flat band is 25–33 px tall under 24–64 px of content; the middle also stretches 1.2–3.1x
  the cut aspect (the owner's "stretched"). The refinery job row (56 px) is below C4's own
  legal band minimum (64 px, chrome_family.gd:75).
- **Theme plates with no margins** — `ui_button_plate` (280x56) and `ui_panel_frame`
  (192x192) ship as whole-texture styleboxes (no texture margins, vajb_theme.tres:218-220,
  90-99), so any button not at the cut's exact aspect smears the art (stretch 0.16–2.18).

## The owner's five, in his words
- **TERMINAL chromes too small, text goes over** — confirmed: 8 entries, art letterboxed to
  274x42.6 in 274x56, visible rail 18.6 px vs 40 px of icon+text → +21.4 px of content off
  the art. Needs a C9-class cut at the entry's own aspect (~4.9:1), cut band ≥ 44 px.
- **OVERVIEW same** — confirmed: 6 C1 tiles, art 567x140, rail band 57 px vs 74 px content
  (+17 px). The 3 service rows are the worst C4 stretch (3.14x).
- **ARMORY EQ slots stretched** — the 48x48 grid plates are clean; the stretch in EQ is the
  864/874x76 browser rows (1.54x, band 33 px vs 64 px need) in both modes, plus the battery
  barrel-name plate (68x86 drawn from a 5:1 cut, its label 74 px too wide).
- **REFINERY rows ("ALUMINUM 2 INGOTS")** — confirmed: hold rows stretched 1.23x with a
  33 px band under 60 px of content; the job row is out of C4's legal band (56 px) at 1.66x
  stretch, its plate band 25 px under the COLLECT chip.
- **AUCTION the same** — confirmed, worst on the station: 26 shelf rows at 3.14x the cut's
  aspect; band 1524x33 under ≤1708x60 of content, and content+10 % (1878 px) exceeds the
  row itself (1756 px) by 122 px.

## Evidence
```
XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot --headless --path vajb-orbit \
  res://tests/probe_s37_r1_scene.tscn --quit-after 3600 > /tmp/s37_probe.log 2>&1
```
EXIT=0, `[r37] SUMMARY surfaces=245 too_small=180 stretched=109`; cut facts in the 9
`[r37] CUT` lines (C9 720x112 opaque 720x49; C1 1134x280 opaque 1134x114; C4 1120x152;
C3 192x64; C7 720x480; plate 280x56). Probe state: seeded 20/8 ore, one done IRON 2-INGOTS
job, rolled auction shelf — so every owner-named row exists. Note: C5/C6 are wired nowhere
in the station (grep; the console bays keep the flat plate per S36-F1), so no C5/C6 rows.

## Files touched
- `vajb-orbit/tests/probe_s37_r1_scene.gd` — the chrome-fit probe (detector, content union,
  opaque-box scan, band/stretch flags)
- `vajb-orbit/tests/probe_s37_r1_scene.tscn` — its headless wrapper

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| C9/C1 replacement cuts at slot aspect (rail band ≥ content+pad) | fix wave | station.gd:571, overview_panel.gd:264 |
| C4 rows/chips: right-size class or cap-preserving margins; job row off-band | fix wave | refinery_panel.gd:707, auction_panel.gd:824 |
| `ui_button_plate`/`ui_panel_frame` need texture margins or square/small cuts | theme fix | vajb_theme.tres:451, 510 |
| ShipVanguard row content overflows its own 338 px button by 82 px | ticket | shipyard_panel.gd:398 |
| Tooltip: unscaled 50/64 content margins vs 360 cap; text over side caps | ticket | chrome_family.gd:167-173 |
