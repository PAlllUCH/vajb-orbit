---
slice: S41
reviewer: S41-R1
verdict: passed-with-followups
gate: "1300/0 → 1330/0 (re-run on a fresh scratch store; +30 = the four new suites' rows)"
---

# S41-R1 review

Read: brief end to end, D23-R1 audit, all five builder reports (B1–B4 plus B5,
the completion builder the dispatch queue added — its report is in the slice
folder and its rows are graded here too). Every finding re-measured on the
shipped tree; all ten probe renders viewed (downscaled 1200 px JPEG) plus
2–3× right-edge crops for the scroll-affordance check.

## Acceptance list

- **A1 — pass.** All 16 findings fixed at their named sites (each re-measured
  below); none silently dropped. B4's F15 services half NOT DONE was completed
  by B5 (`station.gd:119-127,1143-1147,1208-1211`) — the file-set stop worked
  as designed. T-177 fixed (see A6).
- **A2 — pass.** No added line writes `position`/`offset_*` from code (diff
  scan over every touched file; the only added `position` reads are
  `auction_panel.gd:462`'s topmost-section read). New filler flags sit on
  slack-owning containers/spacers: `FitLeftBox` (`armory_panel.tscn:121`,
  F2's own prescription, named by B3), `ServiceSlack`
  (`overview_panel.gd:362-366`), `TradeSlack`/`TradeTail`
  (`exchange_panel.tscn:166-179`), `CardEscrow`
  (`contracts_panel.gd:376`, horizontal), `PaneActions`
  (`station.gd:1181-1185`). F11 *removes* a filler (`BriefSpacer`).
- **A3 — pass.** No hex literal added or changed anywhere; F7/F9 reuse
  `metal_mid`/`text_meta`/`metal_dark` (B1's PROPOSED table), B5's chip ink is
  read off the theme (`station.gd:1209`), B2/B3/B4 touch no theme file.
- **A4 — pass, proved.** `test_s41_panels_a.gd:75-99` asserts per row
  `global_position.y + size.y <= pane.end.y`, `scroll_vertical == 0` and
  `not scroll.is_ancestor_of(row)` — measured CONTRACTS 656..732,
  INSURANCE 738..814, VAULTS 820..896 inside pane 214..970. The assertion is
  load-bearing by construction (a row inside the scroll cannot pass it).
- **A5 — pass.** REFINERY and ARMORY clusters are `360×56` `StationButton`s in
  `PaneFoot/ActionsRow` on the same anchor EXCHANGE uses
  (`refinery_panel.tscn:283-311`, `armory_panel.tscn:234-265` vs
  `exchange_panel.tscn:195-218`); QUEUE rightmost in both.
- **A6 — pass, re-proved by R1.** I ran the generator myself:
  `[build_theme] uids preserved: 19 (1 resource + 18 ext_resource)`, and the
  `.tres` md5 is byte-identical before/after (`md5sum -c` OK); the working-tree
  diff is the wave's own 20 lines, nothing more.
- **A7 — pass.** New suites carry real geometry/theme assertions, no `await`
  anywhere in the four files; every `call()` targets a method that exists
  (`player_profile.gd:412/588/594/675/1021/1071/2048` — the older suites'
  precedent), never a variable read. Each worker revert-proved its own rows;
  I read the A4/F14/F13 assertions and they measure the pinned property, not
  a proxy.
- **A8 — pass.** My own gate run: `passed=1330 failed=0`. Per-suite counts off
  the log: `s40_legibility` 8, `ui_slot_layout` 12, `s18_armory_rework` 9,
  `s32_armory_modes` 23, `d7_armory` 11, `p2b_fitting_panel` 27,
  `p2b_services` 15, `s25_contracts` 26, `s27_catalog` 25, `d7_status` 8,
  `d7_cockpit` 18, `p2b1_outfitting_panel` 13 — all §6 rows unchanged; the
  delta is exactly the four new suites (14+6+6+4=30). Note: brief §6 says
  "the three new suites' rows" but §3 lists four test files — a brief slip,
  not a moved row.

## Visual re-audit — is the fix visible on the render?

| Finding | Visible? | What the render shows |
|---|---|---|
| F1 | **yes** | All three service rows sit unscrolled at the pane's fold; identity block is one name line; the F9 grabber is the visible scroll cue above them. |
| F2 | **yes** | The left sector's roofed box runs full height to the PWR meter; no raw BG-1 half. |
| F3 | **yes** | Battery band reads `MODULE / STATE / HELD` over `FITTED`/`OWNED ×n` rows. |
| F4 | **yes** | `EMPTY CELLS · 0` and the BATTERY CONFIG block are caption-high plates, not 92 px boxes. |
| F5 | **yes** | `IN INPUT` sub-header separates the hold stacks from the five LOADED rows. |
| F6 | **yes** | The quote readout floats in the column's lower half between two equal slack owners; the dead backdrop is balanced. |
| F7 | **yes** | Disabled plates (refinery LOAD/COLLECT ALL, shipyard IN SERVICE) keep a visible 1 px edge at 1200 px. |
| F8 | **yes** | Under ALL, one sticky caption+band rides the topmost section; the fold cuts a row mid-row, never a header. |
| F9 | **yes** | Grabber + dark track unmistakable in the OVERVIEW/AUCTION/ARMORY right-edge crops at 2×. |
| F10 | **yes** | The Vanguard sprite owns the preview frame (~60 %), not a 150 px island. |
| F11 | **yes** | The cargo note sits under the cargo list mid-column; the foot band carries footer + live confirm only. |
| F12 | **yes** | `ONE SERVICE AT A TIME · ESC BACK` prints once (the pane's own hint). |
| F13 | **yes** | Active cards are two stack rows; CANCEL sits right-aligned on the action row, clear of the reward. |
| F14 | **yes** | Both moved clusters read as the exchange's foot-band idiom at 360×56. |
| F15 | **yes** | Shipyard plates and services segments wear the 32 px chip height/ink; counts kept. |
| F16 | **yes** | Probe tooltips render with their top at ~y189 (below the 163 band); code + suite row pin it. |

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S41-B2/F01 | MED | `overview_panel.gd` (`%ServiceHost`) | **The F1 tradeoff needs the owner's eye:** with the services block outside the scroll, the hull block (hull/shield readouts + the pane's only REPAIR chip) now lives below the fold inside `BlockScroll` — gone from the unscrolled OVERVIEW on the render. B2 declared it with its reversal; P22/P26 pins are satisfied, so this is bucket 3 (taste/owner). **No fixer edit** — route to TICKS; reversal path is B2's own. | owner |
| S41-B5/F02 | LOW | `ui/components/tooltip.gd:25,133-134` | The F16 guard pins the *shell* band's 163 px; a pane's own header row sits below it, so on REFINERY/AUCTION the probe tooltip still lands over the deck title line. A later pass can pin the pane header's bottom instead. → ticketed **T-180**, not fixed here. | — |
| S41-B4/F03 | LOW | `docs/design/STATION_HUB.md` §5.7 | The deck law still words the refinery actions as "`REFINE N`, `REFINERY ALL` and `CANCEL`, all three 88 px" — the shipped cluster is QUEUE/LOAD/COLLECT ALL at 360×56 in the foot band with QUEUE ALL/CANCEL mid-column (brief-law). [DOC] → ticketed **T-181**. | — |
| S41-B5/F04 | LOW | `docs/design/STATION_HUB.md` §19.4 | The service-strip row pins the three buttons at min (0, 56); F15 ships 32 px chip chrome. [DOC] → ticketed **T-182**. | — |

## Verified fixes

Pre-fixer review — nothing verified-fixed yet. If the fixer runs, its scope is
empty unless the owner rules on B2/F01.

## Gate

`[SUMMARY] passed=1330 failed=0` (R1's own run, fresh `XDG_DATA_HOME`,
`--quit-after 2400`). Baseline 1300/0 + 30 new rows; zero moved §6 rows; zero
failures. B1's mid-wave residual (`test_d7_armory` 6 fails) is gone in the
final tree.

## CONTRACTS edit (the one wrong pin)

§25 (S28 block) quoted the refinery footer format `"FEE %d CR QUEUED"`;
B4's incidental fix makes it `%s` (the shipped `%d` blanked the footer
whenever the input was queueable — visible in the render: the footer prints).
Corrected in place with the dated note; no other CONTRACTS text contradicts
the shipped tree.

## Notes for close-out

- Tickets filed: **T-180** (tooltip vs pane header), **T-181** (STATION_HUB
  §5.7 cluster wording), **T-182** (STATION_HUB §19.4 strip height); next free
  **T-183**. The D23 findings themselves close as this wave's evidence — file
  their closure rows per brief §7 step 4.
- B2/F01 (the hull block below the fold) is an owner decision, already queued
  in B2's follow-ups — put it on TICKS, not on the fixer.
- The wave's doc pass (owner's "update all docs") should sweep T-181/T-182 and
  re-read STATION_HUB §19.1/§19.4's OVERVIEW arithmetic against the new
  `%ServiceHost` skeleton.
