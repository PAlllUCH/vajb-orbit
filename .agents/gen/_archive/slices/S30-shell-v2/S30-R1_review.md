---
slice: S30
reviewer: S30-R1
verdict: blocked
gate: "1074/0 → 1089/0"
---

# S30-R1 review

Law: UI_SPEC §11/§12 (+§8, §5.1/§5.2), STATION_HUB §18/§19 (+§3.1/§3.4), the
three D19 wireframes — every judgement below re-measured off the shipped files,
never off the builders' reports. Probes: `tests/probe_s30_review{,2,3,4}.gd`
(self-quitting, scratch store; not gate suites). Gate re-run twice on fresh
stores; all moved rows diffed against HEAD and matched to the disclosure lists.

## Acceptance list

**S30-B1**
- A1 — drift: N27/N28 built and wired to the chain with the pinned sizes and
  N32/N33/N35/N36 details (tooltip.gd:17-21, inspect_sheet.gd:20-40); but the
  popup layers carry no theme (F4) and `_fit()` breaks the sheet's own anatomy
  at open (F3).
- A2 — drift: rows 1–3, 5–7 cured and verified (zero `tooltip_text` writes left
  in `ui/`; no `_row_hint` callers); row 4 legal-equivalent (non-autowrap,
  fill-width labels); row 16's focus route still rebuilds (F6); the P6 idle
  summary re-arms the tooltip (F5).
- A3 — drift: REFINERY/EXCHANGE/AUCTION/OVERVIEW conform (probe: PaneHeader
  y 214, foot band 914..970); ARMORY ships no shared band (F8); LAUNCH's band
  is 35 px high under the legacy ConfirmStrip (F9); SHIPYARD reflows the shell
  (F1).
- A4 — pass: hover-never-moves green on every pane — 28 hovers across all 7
  panes at 1920×1080 plus 12 more (ARMORY/SHIPYARD/LAUNCH) at 1440×1080, 0
  moves (probe 1). B1's gate row covers ARMORY only; the bar held anyway.
- A5 — pass: s11 retargeted with the 8 new rows; the 7 retargeted suites all
  match the disclosure list (diffed against HEAD).
- A6 — pass: gate claimed twice on fresh stores; my re-runs read 1089/0 twice
  (post-B2 tree), exit 0, identical pass lists.

**S30-B2**
- A1 — drift: the header trio, the one-pane body and the P29 footer ship and
  the ModuleRail/Inspector subtrees are gone (no such nodes; the AC5 row pins
  it) — but the shipyard pane reflows the whole shell off the pinned bands
  (F1) and the drawer plate geometry is broken (F2/F4).
- A2 — drift: the drawer's structure, motion (0.18/0.12 TRANS_CUBIC EASE_OUT),
  the N40 Body-band scrim, the focus trap and P19's unwind all check out
  (station.gd:390-525, :855-917, :1208-1221) — but the plate is 594 px too
  tall with LOG OUT off-screen (F2), on default chrome at a 338 px content box
  (F4), and TERMINAL's toggle is blocked while open (F10).
- A3 — pass: all five blocks verified block by block (probe: TileGrid 3 cols
  sep 16, six tiles min 300×140, P23 captions verbatim, REPAIR chip 96×32 with
  a chevron mark, three U2 rows 76 tall with OPEN chips, P27 flavour verbatim,
  P22's scroll wrapping the stack); P24 lands on SHIPYARD with
  `focus_repair()`; vault base 40 PROPOSED with reversal; SERVICES a
  placeholder per P26's deferral.
- A4 — pass: P20 wraps the six and enters at ARMORY/LAUNCH from OVERVIEW
  (probe + test rows); raw-key fallbacks for T/E/PgUp/PgDn/shoulders
  (station.gd:317-350); the confirm flow is unchanged.
- A5 — pass: 12 rows cover A5's list; every moved row matches B2's table; the
  frozen-clock fixture implements T-105's ruling (assert_eq on the frozen
  clock, test_s21_stability.gd:909-922).
- A6 — pass: 1089/0 twice claimed; reproduced twice on fresh stores, exit 0.

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | HIGH | `ui/station/shipyard_panel.gd` skeleton | The pane's min height (862: ShipyardBody 741 + PaneHeader/PaneFoot + separations) exceeds the host content box (753) and reflows the whole shell — probe: Layout 1920×1186, Header at y −29 (identity plate half off-screen), Footer at y 1091..1109; §12.4's "bands keep §3.1's boxes exactly" and P15 break; the wave's own fixed-shell purpose defeated (tiered HIGH: the shell bands move, not just one pane's origins). Driver: `StatsBox` min 741. | S30-F1 |
| F2 | HIGH | `ui/screens/station.gd` drawer plate | The plate ships `offset_bottom = 594` (anchors 0..1 set before `add_child`, :454-455) → plate 362×1453, RailBox 1429 tall, LOG OUT at y ≈1548 — below the viewport: the drawer's LOG OUT (P16, the shell's only logout route) is invisible and pointer-unreachable. | S30-F1 |
| F3 | HIGH | `ui/components/inspect_sheet.gd` `_fit()` | `reset_size()` (:164) runs on the sheet ROOT, whose min is 0 (its only child is anchor-laid-out) — every open collapses the root to 0×0 and the CenterContainer centers the 420×524 panel on (0,0): the sheet opens half off-screen at the top-left corner (probe: SHEET_ROOT 0,0, panel gpos −210,−58; probe 4 pins the cause to `open()`). | S30-F1 |
| F4 | MED | popup scenes theme | `tooltip.tscn`/`inspect_sheet.tscn` ship no root theme and the drawer plate is code-built — under their CanvasLayers `TooltipPanel`/`PanelRaised` resolve to a default StyleBoxFlat (probe 3: content margins 0, tex null) vs ModuleHost's StyleBoxTexture: every popup renders default chrome; dialog.tscn:14's root-theme idiom missed. | S30-F1 |
| F5 | MED | shipyard/launch idle summary | The P6 idle summary re-arms the N27 tooltip on unhover/pane-show (shipyard_panel.gd:969,1154,1370, launch_panel.gd:222 emit through the chain on `shown=false`), so the tooltip opens ~0.25 s after the pointer leaves (N33's unhover dismissal defeated); §18's ledger sends idle fills pane-internal, not to the hover sink. | S30-F1 |
| F6 | MED | `shipyard_panel.gd` census 16 | The cure is incomplete on the focus route: `_on_row_focused` (:1133) → `_preview_row` → `_refresh_preview` → `_set_layout_grid` (:539) rebuilds the slot matrix on every focus move (no same-hull early-out); the census cure: focus keeps colour/`modulate` and never touches the tree. | S30-F1 |
| F7 | MED | `armory_panel.gd` N28 chips | The hand-positioned rows (ammo cards, inventory rows) carry no INSPECT chip — N28's amended trigger ("rows carry the inline chip") unmet there; disclosed (deviation 3) but the acceptance bar needs it closed (the positioning pass or an owner tick). | S30-F1 |
| F8 | MED | `armory_panel` skeleton | No shared foot band: MeterLabel/SelectionLine sit inside Split/GridHalf and ActionsRow is a direct child (armory_panel.tscn:98,211) — §19.3's hint-in-band shape unmet; disclosed (deviations 4/7), still A3 drift. | S30-F1 |
| F9 | MED | `launch_panel` skeleton | The foot band sits at y 878..934 (35 px high) with the legacy ConfirmStrip below it (946..970) — §19.3's band box and "and nothing else" unmet; the §19.4 cluster (REFUEL+RECHARGE+LAUNCH) ships as LAUNCH-only (B2's deviation 10). | S30-F1 |
| F10 | MED | `station.gd` drawer root | The full-rect `MOUSE_FILTER_STOP` drawer root blocks the header while open: TERMINAL's toggle is dead while the drawer is up (N40's "header stays live"; the test emits `pressed` directly, test_s30_shell.gd:147, so the gate cannot see it). | S30-F1 |
| F11 | LOW | four panes `_row_hint` | Dead code: the census-7 hint helpers remain defined with no callers (shipyard:1240, auction:1150, exchange:590, armory:1857). → ticketed as **T-114**. | — |
| F12 | LOW | STATION_HUB §19.4 vs code | ARMORY's pinned hint keeps `CANDIDATE` while the shipped meter words the preview `IF FITTED` (D17-P1's unticked PROPOSED, armory_panel.gd:219-220) — reconcile at the docs batch. → ticketed as **T-115**. | — |
| F13 | LOW | auction foot band | The band ships §5.10's two-label footer (RestockLabel + StatusLabel) instead of §19.4's one-line hint cell — two pins disagree; reconcile at close-out. → ticketed as **T-116**. | — |
| F14 | LOW | drawer content box x | R-S30-1's box lands at x 69..341 (plate at x 24) vs the pin's 68..340 — 1 px, disclosed (B2's deviation 2); owner tick at close-out. → ticketed as **T-117**. | — |

## Notes on the disclosure check and accepted judgements
- Every moved gate row is disclosed: s11 by B1/B2, s20 AC5 by B2, s29 :239/:324
  by B1 (the second row's cite drifted to :330 after B2's edits — still listed),
  p2b_services ×3, p2b1_outfitting, p2b_fitting ×2, s5_ammo_cargo by B1; s3_auction,
  s5_batteries_v2, s21_stability by B2. No unlisted moves; no orphaned rows.
- Accepted bucket-1 (stated with reversals, no finding): B1's deviations 2/5/6/8;
  B2's deviations 3/4/5/6/7/9/10; the drawer→sheet layer order actually conforms
  (the sheet's layer is added after the drawer's, so the sheet is topmost).
- F4 (the missing theme) also explains the flat chrome and the 338 px content
  box inside F2's evidence; F2's height (the anchors preset) and F3
  (`_fit()`'s `reset_size`) are independent bugs needing their own fixes.

## Verified fixes
No fixer has run; F1–F10 pending S30-F1.

## Gate
- `[SUMMARY] passed=1089 failed=0` — run 1, `XDG_DATA_HOME=/tmp/s30r1-f1`, exit 0.
- `[SUMMARY] passed=1089 failed=0` — run 2, `XDG_DATA_HOME=/tmp/s30r1-f2`, exit 0.
- Negative control: probe 4 — a full-rect root under a fresh CanvasLayer sizes
  to 1920×1080 (code-created and scene-instantiated alike), pinning the sheet's
  0×0 to `_fit()`'s `reset_size()` and not to the layer mechanism.
