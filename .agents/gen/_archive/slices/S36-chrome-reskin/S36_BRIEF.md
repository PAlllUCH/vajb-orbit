---
slice: S36
worker: S36-B1
role: coder
status: ready
tier: paid — hyper/deepseek-v4.1-flash @ xhigh (owner 2026-10-05: "for coding run deepseek on x-high")
---

# S36-B1 — wire the chrome family (the swap map) + the census suite

## 0. The owner's request (verbatim, 2026-10-05/06)

"panels stretched out of proportion … full redesign with different aspect
ratios … unify the panels in all the game" — and the review-sheet call on the
four hard classes, verbatim: **"for rack bay i like both. new a bit better.
drawer entry new. action button i like both. overview new."** The keep-list:
"keep the chromes from main menu, terminal side panel, CANCEL, SELL buttons,
all the ones that are native not stretched look good."

## Context (read in this order)

1. `docs/design/UI_SPEC.md` §15 (by range — the census §15.1, aspect law §15.2,
   margins law §15.3, supersedes §15.4) + §15.6 (the four hard classes ship the
   rail look; the keep-restore; the swap map is your scope).
2. `slices/D21-chrome-family/S36_proposal.md` — the keep table + swap map
   (the scope statement in one page).
3. `docs/CODE_MAP.md` (by range) — where the station panes, OVERVIEW tiles and
   the exchange tooltip live.
4. `slices/D21-chrome-family/D21-G2_report.md` + `D21-G2-R1_review.md` — the
   landed cuts' measured numbers (R1's measured-margins table is the N51
   wiring input).

## Spec extract (the pinned law, verbatim)

**`UI_SPEC.md` §15.2 — the aspect law:** A1 every plate is drawn at its class's
true aspect, respected always (a surface wears the class whose true aspect is
its own measured use aspect); A2 caps, corners and rivets never stretch; A3
nine-slice stretch only in the flat bands §15.3 declares, within range; A4 a
surface the family cannot cover gets a new plate reported, never a stretch; A5
C12 is the one aspect-free class (square art, uniform edge bands, corners
fixed); A6 whole-face plates (C6 + keep anchors) contain, never stretch or
slice; A7 states derive by `modulate` and stylebox tint — never size, never
position, never an in-flow `visible`.

**`UI_SPEC.md` §15.3 — the margins law (measure from each cut per N51; the
declared values are the default):** C1 16 all sides (±10 % of 567×140); C2
margins 20 caps / 12 top-bottom (band 272→450 wide, 56→88 tall); C3 8 (80→160
wide); C4 12/8 (band 320→1765 wide, 64→84 tall, flat end to end); C5 10, no
stretch (fixed 260×192); C6 no margins, no stretch (contain); C7 12 (280→360
wide, 120→400 tall); C9 16/8 (272→360 wide, 56 fixed); C12 64 at the 192
master (edge bands tile, corners fixed); C13 opaque cover-fit at 1765:753, no
stretch. **Pinned: caps, corners and rivets never stretch (A2).**

**`UI_SPEC.md` §15.6 — the four hard classes (owner's words):** the rails' air
is the accepted look — `ui_tile_slab` / `ui_action_bar` / `ui_drawer_entry` /
`ui_rack_bay_card` draw at their slot rects as cut (pad canvas included,
uniform scale, NEVER cropped to "fill"). The keep-restore line: `ui_slot_*`
faces, `ui_bar_caps`, `ui_minimap_bezel` stand shipped — **never touch them**
(the gate's `test_s20` AC2 + `test_d8` 12 px floor rows guard this).

## Task

Wire the swap map across the station panes, the OVERVIEW tiles and the
exchange tooltip, then add the chrome-census regression suite.

| Surface | Cut (in `vajb-orbit/assets/ui/`) | Wiring |
|---|---|---|
| OVERVIEW tiles (567×140 ±10 %) | `ui_tile_slab.png` | stylebox at the tile rect (the rail+air canvas is the look) |
| Data/service row strips (320–1765 × 64–84) | `ui_row_strip.png` | StyleBoxTexture nine-slice, margins 12/8 |
| Armory console face | `ui_armory_console.png` | contain (A6) |
| Rack bay cards (260×192) | `ui_rack_bay_card.png` | uniform canvas at the bay rect (square card + side air) |
| Inline chips beyond the keep-list (INSPECT, mode switch, MAX/0) | `ui_inline_chip.png` | margins 8 |
| Action bars beyond the keep-list (BUY, REPAIR, QUEUE…) | `ui_action_bar.png` | SELL/CANCEL stay native (keep-list) |
| Tooltip frame (280–360 × 120–400) | `ui_tooltip_frame.png` | margins 12 |
| Pane frames (any rect) | `ui_panel_frame.png` | nine-slice, margins 64 at the 192 master |
| Drawer entries (TERMINAL rows 272–360 × 56) | `ui_drawer_entry.png` | the drawer SURFACE stays native |
| BG-1..4 pane backdrops | `ui_backdrop_{armory,refinery,market,dock}_deck.png` | new TextureRect layer behind pane content, cover-fit at the 1765×753 content box, `mouse_filter` IGNORE |

BG assignment (§13.3): BG-1 ARMORY · BG-2 REFINERY · BG-3 EXCHANGE + AUCTION ·
BG-4 SHIPYARD + LAUNCH + OVERVIEW. The shell's `ui_backdrop_hangar` stands
outside the panes (keep-list).

## Acceptance list

1. Every swap-map surface wears its class cut per the table (cite each:
   `file:line`), and nothing outside the table moved.
2. The nine-slice margins are measured from each cut's own rivet/bevel band
   (N51) and reported measured-vs-declared per class.
3. A1 holds: every drawn rect's aspect matches its class master within 1 %
   (the rails' slot-rect draws included — the canvas is the cut's aspect).
4. A2/A3 hold: no stretch crosses a cap, corner or rivet; stretch only inside
   §15.3's declared bands and ranges.
5. A6 holds: the console face and whole-face plates contain, never stretch.
6. A7 holds: every hover/pressed/disabled state derives by `modulate` or
   stylebox tint — zero size, position or `visible` changes for states.
7. The keep-list is untouched: `ui_slot_*`, `ui_bar_caps`, `ui_minimap_bezel`,
   main menu chromes, the TERMINAL drawer surface, CANCEL/SELL, cockpit/status
   faces, `ui_backdrop_hangar` (asserted in the suite's keep group).
8. BG-1..4 land per the assignment, cover-fit at 1765×753, behind content,
   `mouse_filter` IGNORE (no hit-testing interference).
9. The rails' air is preserved — the four hard-class cuts draw at their slot
   rects as cut (no pad cropping to fill).
10. `vajb-orbit/tests/test_s36_chrome_census.gd` ships with four assertion
    groups (class-aspect, no-smear bands, keep-group untouched, backdrops) and
    the gate reads 1138 + N / 0 with every existing row still passing.
11. The report answers 1–10 item by item with cites (≤ 120 lines).

## Hard constraints

- File set: `vajb-orbit/ui/,vajb-orbit/tools/,vajb-orbit/tests/,.agents/gen/slices/S36-chrome-reskin/` (dispatch sets `VAJB_WORKER_FILES`; trailing slashes are load-bearing).
- Do not touch: `docs/`, `docs/archive/` (sealed), `addons/`, `vajb-orbit/autoload/`, `vajb-orbit/game/`, `vajb-orbit/assets/`, `staging/compare/`, other workers' files.
- A finding that would change a doc or a pinned number: report it, leave it (escalation-ladder bucket 2 — the developer/designer owns the yardstick).
- Every Godot run bounded (`--quit-after`); probes self-quit; never leave a command in the background.
- No asset regeneration — the cuts are final (§15.6).

## Output contract

- Report: `.agents/gen/slices/S36-chrome-reskin/S36-B1_report.md` (from `_templates/REPORT.md`).
- Gate: run the universal test gate before and after; record both `[SUMMARY]` lines; every moved row disclosed with its reason.
- Deviations: what, why, the one-line reversal.

## Model guidance

B1 `hyper/deepseek-v4.1-flash` @ xhigh (owner-pinned). R1 `hyper/glm-5.3-flash` @ max (standing reviewer). F1 = B1's model, only on HIGH/MED.

## Paste block

```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/,vajb-orbit/tools/,vajb-orbit/tests/,.agents/gen/slices/S36-chrome-reskin/" crush run "<the S36-B1 body>" -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE"
```
