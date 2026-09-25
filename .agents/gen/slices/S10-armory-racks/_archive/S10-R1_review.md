---
slice: S10
reviewer: S10-R1
verdict: passed-with-followups
gate: "770/0 → 775/0 (twice on fresh scratch stores; live md5 pair unchanged throughout)"
---

# S10-R1 review — the ARMORY fixes

Diffed against `docs/design/STATION_HUB.md` §5.11/§5.1, `docs/gameplay/09_ship_slots_modules.md`
§11, `docs/CONTRACTS.md` §17/§16/§9 and `docs/design/UI_SPEC.md` §3.9/§3.10 — never the
brief. Every acceptance was re-measured through **real input** (`Input.parse_input_event`
→ `Viewport` hit-test/drag routing) on the shipped tree; a handler-calling probe counts
as no evidence. **No HIGH, no MED** — no fixer pass owed. Tree: `66bd28f` (pre-B1
`c8a6b5d`, snapshot `s10_repro_start`); the shipped tree was never reverted to measure
anything.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | LOW | `ui/station/armory_panel.gd:1682-1685` | The restored `x` box is 28×28 (`_d(14.0)`) inside the pinned 20×22 slot (UI_SPEC §3.10), so it covers the chip's **geometric centre** — 28 of 40 wide, 28 of 44 tall (probe `station frame`). A press at the block's centre is therefore a remove-click, not a drag; the drag handles are the chip's left column and its lower 16 px strip. Measured drag from the block commits (`[[0,1,2]] → [[2,0,1]]`). D7's own mockup geometry, not B1's; moving it moves §3.10's pinned slot → owner tick (bucket 2/3). Filed `L172`. | owner |
| F2 | LOW | `ui/station/armory_panel.gd:1676-1679` | The plate's own rect is **build-order dependent**: the pane's first build leaves `Name` at `(40,16)` with its centre inside the `x`; every rebuild gives it `(11,44)` — "the rest of the row" the new comment claims. Probe: `station frame` vs `suite settle_layout`/`settle + 6 real frames` (11×44 persists). Both states keep every acceptance (3 drag handles + `x` measured). Filed `L173`. | next file-owning wave |
| F3 | LOW | `ui/station/armory_panel.gd:236-241` | A motion-less press on a fitted cell's block is **consumed by the chip**: no selection, no drag, no remove (`PRESS block of a fitted cell … selected=2 … status=[]`), while the same bay's own plate press selects it (`selected=0`) and `weapon_1..7` work. Selecting a fitted bay is reachable only on its plate area or the keys. Filed `L174`. | owner tick |
| F4 | LOW | `tests/probe_s10_a0_armory.gd:228-231,252-259` | A0's probe's barrel points are **stale after the fix**: the chip's and the plate's assigned centres now land inside the `x` box, so the probe reads `drag_data=<null>` and its click at `(529,446)` *removes* a barrel mid-run, then raises twice on the freed node (`_name_of` :150, `global_position` :257). Harness only; repoint Q2 at the block. Filed `L175`. | next tests/-owning wave |
| F5 | LOW | `ui/station/armory_panel.gd:2051` | B1-D4's follow-up: the success line names the moved barrel from the record **after** the write, so a between-rack body drop reads `MOVED ·  · B2`. Pre-existing, unpinned wording; orchestrator already staged it. Filed `L176`. | next file-owning wave |
| F6 | LOW | `tests/test_s10_armory_input.gd`, `tests/probe_s10_r1_armory_hits.gd` | The new test files carry **no `.uid`** (created without the editor, same as A0's probe), so the next editor pass mints them and the next `verify_wave.py` snapshot reports them as added. Filed `L177`. | next editor pass |

## AC re-measurement (W8 method)
- **AC1 hit targets — passed.** `tests/test_s10_armory_input.gd` re-run byte-identically
  (`-- --suite=test_s10_armory_input`): **5/5**, exit 0. Reviewer probe on the shipped
  station mount: chip `40×44`, `Name (40,16)`/`Close (28,28)` at `P(609,424)`; a real
  press/move/release **commits** from the block, the plate's left column **and** (settled
  layout) the plate's centre — `[[0,1,2]] → [[2,0,1]]` + `MOVED · LASER MKII · B1` each
  time; a real `x` click empties the cell (`["", "mod_0012", "mod_0013"]`, groups
  `[[0,1,2]] → [[1,2]]`, `REMOVED · LASER MKII · BACK IN INVENTORY`).
- **AC2 the drum — passed.** A0's probe re-run, byte-identically: the rack holding the
  dragged **cannon instance** now reads `fig=60 salvo=060` where the pre-fix reading was
  `---`; the two laser instance racks stay `---` (interval 0, correctly no cadence). The
  new suite's row reads `060` for `mod_*` and `060` for the mixed base+instance rack.
- **AC3 selection — passed.** Real input on the shipped station: bay-2 click → `sel=1`,
  bay-4 → `sel=3`; probe: bay-3 click → `2` + `marked3=true`, `weapon_5` → `4`,
  `weapon_1` → `0`, frames follow. **No profile write:** fit/bag/racks records equal and
  the scratch `profile.cfg` md5 `9f0935d3… → 9f0935d3…` with `_dirty` `false → false`
  (the suite's own row asserts the same three records).
- **AC4 no pin moved — passed.** `git diff c8a6b5d HEAD`: `armory_panel.gd` **+64/−5** and
  the new suite **+473**, nothing else in `vajb-orbit/`. Every pinned constant's **text is
  identical** (`REFUSAL_W_SLOTS_FULL` :174, `RACK_KEY` :132, `RACK_SALVO`/`RACK_READY`,
  `SALVO_MAX` :142/`SALVO_DIGITS` :143) — only line numbers shift; `RACK_ACTION` is B1's
  new key-format const. No hunk touches `_style_bay`/`BayMarks` (the §3.2 ember frame).
  `tests/test_d7_armory.gd` sha256 `e78b82e8…` identical at `c8a6b5d`/HEAD/`s10_repro_start`
  → unmoved; **11/11 rows PASS** in both gate runs, same row set.
- **AC5 scope — passed.** No `.tscn`, `docs/`, `assets/` or `fitting_panel.gd` in the
  diff. No shell-edit residue in the shipped artifacts: no `*~`/`.bak`/`.orig`, no trailing
  whitespace, no CRLF (`file`: ASCII / UTF-8). The only untracked non-`.agents` file is
  `staging/mockup/station_mockup.py`, the parallel D11 lane's own script
  (`D11-A0_report.md:13`) — not S10's.

## Red state, independently (worktree, never a checkout)
`git worktree add --detach /tmp/s10_r1_pre c8a6b5d` + the suite copied in (assets and
`.godot` linked from the shipped tree), fresh scratch store, `-- --suite=test_s10_armory_input`:
**`passed=0 failed=5`, exit 1** — `test_s10_armory_input.gd:376` (the name plate is the drag
handle, hovered `Barrel3`), `:397` (the chip's own drag data committed the swap), `:411`
(the `x` is its own hit target, hovered `Barrel1`), `:435` (the instance-keyed rack reads
the cannon's 0.6 s in hundredths), `:462` (a real click moves the selection to B3). The same
worktree with the suite removed reads **`769/1`** = **770 rows**, matching §9's pre-B1 pin;
its one failure is `test_p2a_ship_roster.gd`'s `ship_fighter_side.png is on disk`, an
environment artifact of the linked `assets/`/`.godot` (the shipped tree passes that row).
Growth `770 → 775` = the new suite's 5 rows, nothing else.

## Gate
- `775/0` twice on fresh `XDG_DATA_HOME` stores, exit 0 both times, stderr byte-identical
  across the two runs and to the pre-B1 set (`data.tree` null, the `EconomyLog`
  missing-dir warning, `test_weapon_fx_f4.gd:178`'s freed instance, 12-resources-at-exit).
- Live pair `profile.cfg` `acf3161108605c9cc30f710099a11e24` / `economy_log.txt`
  `77f4f61a55e4bbe116fd4631b20c2056` — unchanged after every probe, suite and gate run.
- `staging/verify_wave.py verify --baseline s10_repro_start --forbidden vajb-orbit/project.godot
  docs/gameplay/18_engine_spec.md docs/design/STATION_HUB.md docs/design/UI_SPEC.md --tests
  --expect-reports …S10-A0_report.md …S10-B1_report.md …S10-R1_review.md` → exit 0,
  **`problems: []`** (its internal gate run included), **no forbidden hit** — the four
  protected files appear in neither `modified` nor `added`. `modified` holds only this wave's
  two artifacts (`armory_panel.gd`, `docs/CONTRACTS.md`), this review's `LOW_BACKLOG.md` row
  set and the parallel D11 lane's own files; `added` holds the S10 reports/briefs, the new
  suite, A0's probe (both predate `s10_repro_start`, so the baseline cannot carry them) and
  the review's probe. The live pair above is unchanged after this run too.

## Owner ticks this wave leaves
The `x` box vs the block's centre and the chip press semantics (F1/F3); what a rack
selection should *mean* beyond the frame and the per-battery ammo/stats readout (A0's
bucket 3, unpinned); the between-rack success line (F5); plus S8's still-open list
(O1/O2's FITTING UX call, O3, `L168`/`L169`, `REFINE ALL`, the refinery hide, the
live-profile restore, the trailing rack, seven racks on a 3-W hull).
