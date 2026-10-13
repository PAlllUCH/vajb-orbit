---
slice: S45
reviewer: S45-R0
verdict: blocked (HIGH remains — F1; the cure is a one-line revert or an owner-ratified key)
gate: "review re-run 1379/0, matched (wave moved 1358 → 1369 → 1379)"
---

# S45-R0 review

Method: both briefs end to end; 04 §7/§9, STATION_HUB §5.6/§23.5/§23.6, 07 §6.1–§6.3,
UI_SPEC §3.10 A5.1–A5.5 / §16.1 / §17 A4–A6 read at their pins; both reports; the full
diff hunks of all six deliverable files; both new suites read whole; the P1 sealed row and
`test_s34_refinery_queue.gd` checked untouched; the confirm seam read at
`station.gd:568-599` and `:1283-1290`; every §6.3 baseline re-checked against the live
catalogues; the gate re-run. Report cites are per-builder snapshots (W0's edits above
V0's regions shifted them ~55 lines); cites below are the current tree. No fixes made.

## Acceptance list — S45-V0 (7/7 pass)

1 — pass — `refinery.gd:469-495` (doc `:460-468` cites 04 §9 R9): catalogue order, each
stack through `load_ore` whole or not at all, cap-stop (`space < 1` break) plus the
whole-stack overflow skip, not all-or-nothing across stacks (the brief's own allowance),
returns `{ok, reason, loaded, input_total}`; `REASON_NOTHING_TO_LOAD` added `:77`; rows
`tests/test_s45_refinery.gd:455-526`.
2 — pass — tscn foot order Collect/LoadAll/Load/Queue = `COLLECT ALL · LOAD ALL · LOAD ·
QUEUE` (primary rightmost); four 360×56 `StationButton` plates, separation 16; QUEUE
ALL/CANCEL still under `RefineBox/ActionGrid`; `%PaneFooter` intact — test `:368-412`
pins order, words, sizes, variation, gutter.
3 — pass — `_on_load_all_pressed` `:1252-1273`; `LOADED · <n> ORE` (`:184/:1263`, the
"LOADED · 48 ORE" wording asserted at test `:431`); `REFUSED · INPUT FULL` (`:176`) /
`REFUSED · NOTHING TO LOAD` (`:185`) through the §5.6 strip; no credits move asserted
(test `:427`); overflow stays (input 48/60, the gold stack still held).
4 — pass — `_build_strip :508` / `_make_strip_chip :540` / `_refresh_strip_countdowns
:572` read `RefineryModule.jobs/slots/pending_count` only (R10: state is data, the strip
computes none); header order pinned at test `:220-225` (SLOTS first … UpgradeButton last;
TitleBox's expand flag makes the tail rightmost); chips are label + 1 px `metal_mid`
frame over `armory_chip_bg` — the A5.4 State-chip fill's own value (`#2e333a` ==
armory_style's "46,51,58" chip_bg); the countdown ticks in place on the 1 Hz `_tick`
(test `:288-306`, the chip node survives the tick).
5 — pass — `_on_upgrade_pressed :1296` emits the seam; A6 verbatim
`ARE YOU SURE YOU WANT TO BUY A REFINERY SLOT FOR 3 000 CREDITS?` (`:150`, test
`:165-173`); OK → `confirm_action :1308` → `_run_upgrade :1315` = the old path unchanged;
the confirmed press still refuses `REFUSED · NOT ENOUGH CREDITS · 3 000 NEEDED` (test
`:185-204`); CANCEL's focus return is the seam's own (`_focus_active_panel`,
`station.gd:599`).
6 — pass — `set_mode :288` / `_apply_mode :298`, P32's idiom (96×32 toggle pair, C3
chrome); exactly one body visible; the switch is pure visibility (child counts asserted
unchanged, test `:351-353`); the CRAFT body is `CraftEmpty` "NOTHING TO CRAFT" and one
child; REFINE shows today's pane unchanged.
7 — pass — `tests/test_s45_refinery.gd`, 11 rows, at least one per item 1–6; the
countdown row drives `_tick` directly (allowed by the brief).

## Acceptance list — S45-W0 (8/8 pass)

1 — pass — `crafting_catalog.gd:37-70`: the `RECIPES` const, ids/inputs verbatim §6.2
(2×`comp_mech_2`+1×`comp_pow_2`+6×`ingot_cobalt` / 1×`comp_ore_2`+3×`ingot_cerulite`+
2×`comp_elec_2` / 2×`comp_weap_2`+4×`ingot_tungsten` / 1×`comp_elec_3`+
5×`ingot_voidglass`), fees exactly 2500/3000/2800/4000, `MIN_FEE` 2000 at `:74`; no
price, fee or effect computed in any panel (every figure a catalogue read); test
`:158-190`.
2 — pass — the AUCTION idiom: `RECIPE · INPUTS · FEE · STATE` band (+ the unnamed chip
seat); `Button` rows at 76 wearing C4 `ui_row_strip`; title + upper-cased stat line with
N45's trim; `<n>× <name>` runs with the 24 px glyph keep-aspect in its own rect; fee
value + `CR LABOUR` caption; state chip label+frame; the C3 `CRAFT` chip — test
`:401-461` pins each.
3 — pass — the row press emits `sheet_requested` `{name, stats}` carrying the full bill
(`:1606-1624`) through the shipped seam (`station.gd:1283-1284` auto-connect →
`_on_panel_sheet :895` → `open_sheet`); shell untouched; the exact bill string and N35's
no-price/no-owned row asserted (test `:463-486`).
4 — pass — `_on_craft_chip_pressed :1628`: title `CONFIRM PURCHASE`, body
`ARE YOU SURE YOU WANT TO CRAFT REACTOR MK3 FOR 2× GENERATOR BLOCK · 1× CAPACITOR BANK ·
6× COBALT INGOT + 2 500 CR LABOUR?` (A6's craft sentence, `<BILL>` the run idiom; test
`:326-336`); OK routes `_run_craft :1645` unchanged and can still refuse —
`REFUSED · MISSING 2× COBALT INGOT` (test `:347-370`).
5 — pass — `craft :137-166`: verify everything → spend the fee → take every input →
grant via `add_module` (`player_profile.gd:735` — `buy_module :788` gives through the
same seam); a mid-take failure restores what was taken and refunds (all-or-nothing); the
refusal names the missing input with its shortfall; one `CRAFT` log line on success,
none on a refusal (test `:222-305`).
6 — pass — `scrap_value :112-114` = floor(half of `materials_value`); the live baselines
re-derive §6.3 exactly (45/40/158/60/572/50/55/180/120/724 verified in the two
catalogues) → 1 078/1 876/830/3 740 → 539/938/415/1 870 (test `:196-216`); no UI door.
7 — pass — `CRAFT_HINT :134` verbatim in the reserved footer cell (`:913`); `CraftEmpty`
renders through the `_build_craft_from :1399` seam when the table source is empty (test
`:373-398`).
8 — pass — `tests/test_s45_craft.gd`, 10 rows, pinning items 1–7 (exceeds the brief's
1–6); the fee and scrap rows read the live catalog.

## The disclosed route reading (graded)

Pass — the same grade S43 gave it. A5 names the §5.2 dialog idiom; the shell has owned
that idiom since S25; `_connect_panel` auto-connects `confirm_requested` for every pane
(`station.gd:1289-1290`), so both new doors flowed with zero shell edits. `confirm_text
"OK"` / `cancel_text "CANCEL"` / title `CONFIRM PURCHASE` ✓; no `message` at either
door; `QUEUE` stays dialog-free (A4's explicit out — its handler is untouched).
Recorded, not a finding: focus returns to the active pane, not the pressed control — the
seam's shipped S25 shape, which the reading itself discloses.

## The builders' disclosures (graded)

- **V0's six — all proceed-correctly.** The suite reshape (one mount, silent field
  writes, `profile_changed` disconnected) is disclosed bucket 1 with the systemic
  message-queue finding and its ticket; the evidence chain (3 cycles land, 4 abort at
  exit, the changes innocent at 1358/1364) is the right shape. The UPGRADE C3 restyle is
  P51's own "ActionInline" wording, not a deviation. The CRAFT footer swap + hidden
  cluster is P52's own foot law ("foot band kept, no cluster, hint …"). LOAD ALL never
  disabling is required by the brief's own measured facts (both refusals ride the
  press). The two CR groupings each keep a pin verbatim (A6's `3 000` vs §21.3's
  `3,000`). The chip-claim order (running first, done fill the rest, overflow done only
  in the job list) is an R10 presentation reading the model leaves open — disclosed with
  its reversal.
- **W0's minted module ids — proceed-correct (bucket 1).** C6 pins the effects and the
  families, not the ids; the shapes follow the catalogue's own idioms: `p_core_mk3`
  continues `p_core`/`p_core_mk2` (`module_catalog.gd:720/:836`), `s_lattice`/
  `c_rail_refit`/`c_deep_scanner` match the `s_`/`c_` family letters (`s_ion :470`,
  `c_scanner :520`; RAIL REFIT is pinned *(computer)*, so `c_` is C6's own assignment).
  The grant is real today: `add_module` records the base-id bag record; the fitting UI
  cannot list it until the ModuleData rows land — the follow-up ticket says exactly that.
- **W0's A6 worked-example note — correct in both halves.** A6's normative law binds
  `<NAME>`/`<BILL>` to the owning catalogue ("never hardcoded"); the example's
  MECHANICAL COMPONENTS / POWER CELL words are stale against the names the house idiom
  resolves (`comp_mech_2` "Generator Block", `comp_pow_2` "Capacitor Bank" —
  `component_catalog.gd:54/:144`). Reported, not changed, bucket 2, follow-up ticket —
  the escalation ladder respected; the owner re-points the example or pins display-name
  overrides. The delivered wording follows the law text, which is what grades here.
- **Also verified, undisclosed-but-fine:** `scrap_value`'s CR-vs-units shape (the staged
  door decides), `_build_craft_from`, CraftEmpty's re-seat keeping V0's row green,
  `CRAFTED · <NAME>` (nothing pins it), the `RowBox` rename (no other suite paths it —
  the gate is green).

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | HIGH | `vajb-orbit/project.godot:201-204` | Outside both file sets: `[memory] limits/message_queue/max_size_mb=64` added in this wave's diff. `project.godot` is hand-edit-locked (AGENTS.md) and the engine calibration is owner-locked (18 §13); V0's own follow-up routed the bump to "the developer's call", no report lists it under Files touched, and W0's suite header misattributes it as "the developer's 64 MB bump" (`test_s45_craft.gd:33`). The brief's rule is mechanical: outside the six files is HIGH regardless of quality. Cure: revert the key and re-prove the gate without it (V0's numbers put 2 refinery mounts under the 32 MB ceiling), or the owner ratifies the key as documented — either way it is not a worker edit. | developer (owner if the key stands) |
| F2 | LOW | `docs/design/STATION_HUB.md:2149` (P50) | The pin's arithmetic line reads "4×360 + 3×16 = 1 408"; the sum is 1 488. The ≤ 1 765 conclusion stands and the delivered cluster matches the pinned plate law (four 360×56, separation 16) — a docs slip, not a build defect. → ticketed, docs fix at the owner's pass. | docs owner |
| — | note | `vajb-orbit/tests/*.uid` | The wave's three new files' `.uid` companions (`crafting_catalog`, `test_s45_refinery`, `test_s45_craft`) are untracked engine-generated companions — they ride the wave-boundary commit per the repo's tracked-`.uid` convention. The untracked `test_s42/43/44` `.uid` leftovers predate this wave (their `.gd` files are committed at `9a7ff23`). | close-out |

## Verified fixes

None yet — F1 awaits the fixer (revert + gate re-prove) or the owner's ratification.

## Gate

`python3 staging/gate.py --times 1` re-run by this review: `[GATE] run 1: ok - [SUMMARY]
passed=1379 failed=0`, exit 0, zero `SCRIPT ERROR` lines — matches the tree's 1379/0
(wave: 1358 → 1369 (V0) → 1379 (W0); `check_wiring.py` not re-run — W0's own run: 1576
hard refs resolve). Pinned rows: `test_p1_refinery.gd` (the sealed row) and
`test_s34_refinery_queue.gd` are untouched by the diff and green inside the gate — the
wave added, never weakened.

## Fixer amendment (developer, 2026-10-12 — post-review)
- **F1 (HIGH) cured by the review's own alternative:** the `project.godot` bump is
  REVERTED (the file is back at its `s45_start` bytes) and the gate re-proved
  **1379/0 ×2 byte-identical** — the proof now comes from the runner frame-yield
  (`tests/headless_runner.gd`: one `process_frame` await per suite, so the
  `queue_free` backlog and the 32 MB message queue drain between suites; the
  measured abort was the no-yield loop, not the cap itself). The runner is the
  developer's harness domain; the change is disclosed here and carries its own
  reversal in the file. `verify --baseline s45_start` shows project.godot clean.
- **F2 (LOW) → T-198** (P50's arithmetic line; the conclusion holds).
