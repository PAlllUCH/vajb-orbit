# WAVEBOARD — one-file agent state

**Session start (read in this order):** 1) this file — header, Living contracts, Queued; 2) `docs/CONTRACTS.md` §n for your wave; 3) the slice's `SLICE.md` in `.agents/gen/slices/<SliceID>-<slug>/`; 4) `LOW_BACKLOG.md` only if reviewing or fixing. Old reports are opened only when investigating a regression — slice ID + git tag is how you find the right one.

**Keep this file live-only.** It is read at the start of every orchestrator session, so its size is a recurring cost. It holds the current state, the queue, the living contracts and the enforcement rules — and nothing else. At a wave's close-out, the wave's recap (gate history, deliverables, the gates it raised) is appended to `.agents/gen/MASTER_REPORT.md` §6 and only its one-line outcome stays here. Closed-wave detail moved there on 2026-09-24; do not let it accumulate here again.

**Paths (folder law adopted 2026-09-22):** state files live in `.agents/gen/_state/` — `WAVEBOARD.md` (this file), `LOW_BACKLOG.md`, `_wave_state/` baselines; the folder/ID law and the six templates in `.agents/gen/_templates/`; one folder per slice in `.agents/gen/slices/`, one manifest per phase in `.agents/gen/phases/`. Nothing new is written loose in `.agents/gen/` root. **2026-09-22 purge:** the executed-wave reports, briefs and evidence were removed from `.agents/gen/` (recoverable from the system trash; the last git tree carrying them is `3f5688b`) — the historical record is `MASTER_REPORT.md` plus the newest session report, and older citations below name the purged paths.

**Updated: 2026-09-25 (**designer item 13 = **D11 station scene CLOSED** — gate 807 →
**812/0** (`test_d11_station`'s 5 rows), 0 HIGH / 2 MED both cured (MED-1 value grade by
F1, all 15 files to mean 0.160; MED-2's naming rows landed as `ASSET_NAMING_SPEC` §13 by
this session) / 7 LOW L184–L190; owner ticks recorded below; recap in
`MASTER_REPORT.md` §6). Coder item 19 = **S12 ore budget CLOSED 2026-09-25** (no gate row moved; 0 HIGH
/ 2 MED bucket-2 docs cured at close-out / 7 LOW L191–L197; the tables + §10
ticks are with the owner — no cap implemented).** Coder item 20 = **S13 ore
caps + mining batteries + dev tuning IN FLIGHT** (implements the owner's ticks:
`GUN_BURST_SHARE` 0.10, `FRAGMENT_CORE_SHARE` 0.25, multi-mining stacking, the
F1 slider overlay, `DOCK_RING_RADIUS` 175; Rule B deferred and forbidden).** Waves of record: item 16 = S10 ARMORY CLOSED gate 770 → **775/0** (0 HIGH / 0 MED /
6 LOW L172–L177); item 14 = S8 CLOSED gate 753 → **770/0** (0 HIGH / 0 MED /
4 LOW L168–L171); item 13 = S7 CLOSED gate 711 → **753/0** (0 HIGH / 0 MED /
5 LOW L163–L167); designer item 8 = D7 CLOSED gate 727/0. CONTRACTS §20 (S7), §21 (S8),
§22 (item 15's proposals), §18 (D7) are the pins;
changelog **v0.23** (S11) is the newest row — close-outs take the next free rows
read at close-out (v0.22+; L167's lesson for LOW ids too). The QA input stays loose at
`slices/S7-affix-application/S7_QA_playtest_review_2026-09-24.md` (it is S8's brief input);
every other closed slice now holds only `SLICE.md` + `_archive/` (cleanup 2026-09-24).
This session's
end-to-end record — items 4–7, their numbers, the incidents and the open items — is
`.agents/gen/session_2026-09-22_items_4_to_7_report.md`; items 8–13 + D6/D7 + the QA pass
are `.agents/gen/session_2026-09-24_items_8_to_13_report.md`. Full history of what every worker
did, with known errors and open findings, now lives in
`.agents/gen/MASTER_REPORT.md` — this board keeps only current state,
contracts, enforcement and the queue. Executed-wave reports, briefs and
evidence were purged to the system trash (2026-09-22) and archived to the slices'
`_archive/` folders (2026-09-24) —
citation paths of the form `.agents/gen/<report>.md` name the purged files.

**Current state: sixteen coding waves closed (chrome, combat repair, weapon FX wiring, flight
feel & beam polish, slice 2.5 Feel, P2-A ship slot frames, Rock cleave, P2-B1 weapon fit,
P2-B proper fitting panel, **S2.6 truth-and-feel**, **S3 the item economy**,
**S4 weapon batteries**, **S5 playtest fixes**, **S6 travel**, **S7 affix application**,
**S8 QA playtest fixes**, **S10 ARMORY interactivity**,
**S11 station legibility, space gunnery, one-vector inertia**; gate
`passed=578 failed=0` at S5, **`passed=608 failed=0`** after the D6 design wave,
**`passed=674 failed=0`** after S6, **`passed=753 failed=0`** after S7 (the 711 at S7's
`s7_start` snapshot = S6's 674 + D7's in-flight 37), **`passed=770 failed=0`** after S8
(753 + its two new suites' 17 rows; 0 HIGH / 0 MED / 4 LOW), **`passed=775 failed=0`** after S10
(770 + its real-input suite's 5 rows; 0 HIGH / 0 MED / 6 LOW), **`passed=807 failed=0`** after S11
(775 + its three new suites' 32 rows; 0 HIGH / 0 MED / 6 LOW), **`passed=812 failed=0`** after D11
(807 + `test_d11_station`'s 5 rows), hermetic). The queue of record is
`dispatch_coder.md`: items 4–16 and 18 are all DONE — **item 16 = S10 ARMORY CLOSED**
(gate 770 → **775/0**, 0 HIGH / 0 MED / 6 LOW L172–L177; A0's real-input audit
reproduced the owner's report as a **D7 regression** — the barrel `Name` plate and
the `✕` collapsed to 0 px — plus selection wired to nothing and a SALVO drum blank
for rolled instances; B1 fixed all three, R1 re-measured every AC through real
input and proved the red state in a worktree); **item 18 = S11 station legibility, space
gunnery, one-vector inertia — CLOSED 2026-09-24** (gate 775 → **807, 0 failed**, 0 HIGH /
0 MED / 6 LOW L178–L183; six builders + the review, all on `deepseek/deepseek-flash`; the
station inspector reads the hovered item's description above the status strip, the HUD
carries credits, the four non-missile weapon families reach 30 000 u, and a released hull
decays as one velocity vector; §23 + v0.22 docs-first, §9/§10 by R1 as v0.23). **Item 15 is
closed by absorption into §23.5.** **Owner ask 2026-09-24 — jump
gates to sector edges (same gates, spawn placement only) — is the coder lane's next
free item (17)**: brief at its dispatch-prep; its `game/sector.gd` seam is **free** as of
D11's close-out 2026-09-25. **Owner ruling 2026-09-25 — "it should be able to shoot asteroids but mining should
always be more profitable", plus bigger/clustered/fielded asteroids — landed as
`01 §5.6` + `02 §5.1` (numbers PROPOSED, owner-tick-gated) and is the coder lane's
item 19 (`slices/S12-ore-budget/`) — **CLOSED 2026-09-25**: the two read-only
probes measured laser out/in **4.07×** (T1) / **3.83×** (T3) the field's spawn budget on the
re-rolling cascade; gun racks deliver the **same 25 units at 3 and 7 barrels** and 0.714
of a rock's own yield (7× the proposed `GUN_BURST_SHARE` 0.10); R1 replayed byte-identical;
the caps wait on the owner ticks the tables feed. Beyond it: **slice 4's
remainder** — quadrants/directional armour (18 §4.5 + ruling 23, deferred from S6) and
bosses/arena hooks (14 §5, blocked on the P4 contract type and boss-hull art) — **not yet
briefed**. **S8's owner gates:** O1/O2's FITTING-drag UX call (port / point at ARMORY /
unify), O3's site + symptom + mask (the shipped masks never resolve player→NPC contact, so
no factor was written), L168 (`game/repairs.gd`'s transaction still caps at the base row),
L169 (a same-family battery's per-cell seed — 2× magazine). Designer queue:
item 13 = **D11 CLOSED** (numbers in the Updated line, its two owner ticks below);
items 1/4/10/11/12
picked 2026-09-24 (briefs at dispatch-prep), item 9 still awaits its mockup gate).
**D12 readability audit LANDED** (`slices/D12-ui-readability/D12-A0_report.md`, owner ask
2026-09-24: 5 HIGH / 4 MED / 3 LOW, ARMORY first, every finding lane-tagged). The four
graphics findings are this lane's work — ARMORY ink 9-13 px with per-node overrides that
escape `ui_scale`, `text_dim` captions on painted metal at **1.9-2.8:1**, the ember state tag
at **1.8:1**, and the pane's ammunition half sitting **below the fold at 1920x1080** with
37 % of its host empty — and any fix that edits `ui/station/armory_panel.gd` lands **after**
S11-B1 (which holds that file for the hover wiring). Raised to the owner as a notice; its
own fix wave is not briefed.
Owner gates:
the chrome art half, the **`18_engine_spec.md` §6/§13/§15 cleaving amendment** (owner-locked; §15
is the test checklist and now contradicts the shipped suite), the launch fit (**both symptoms
closed** — symptom 1 by P2-A, symptom 2 by P2-B1's `w_mining` row), four spec ticks, the §13
turn column, the engine-bed / vignette-strength calls slice 2.5 raised, **D11's two ticks RESOLVED 2026-09-25** (`class_name StationScene` drop
ratified — the four suite consts stay; dock ring radius **175**, implemented by
S13), **S12's §10 tick list was answered 2026-09-25 and is in flight as item 20** (S13).**

Closed-wave recaps (gate histories, per-wave deliverables and the older owner
gates they raised) live in `.agents/gen/MASTER_REPORT.md` §6 — moved there
2026-09-24 so this header stays the live state only.
## Living contracts

- `docs/CONTRACTS.md` — pinned interfaces; **§11 (P2 ship frames) landed by P2-A
  2026-09-21**, **§5's cleaving sentence merged by Rock cleave (v1.4, 2026-09-22)**, and
  **§12 (the weapon-fit pin) landed by P2-B1 and resolved at its close-out (v0.4,
  2026-09-22 — the MODULES row set is seven, `w_mining` included, and MED-1's shell price
  reads the module catalogue)**, and **§13 (the fitting pin) landed by P2-B proper and
  corrected at its close-out (v0.5/v0.6, 2026-09-22 — the composed `fit_module_at` /
  `clear_fit_slot` transactions, the six-row retirement table, save v5 and `resolved_fit`,
  the fit the launch would fly)**; the §10 changelog carries the v0.2, v1.4, v0.3, v0.4,
  v0.5 and v0.6 entries (plus v0.7.x for the item economy and v0.8.0 for the weapon
  batteries), and §9's gate figure is the measured **493**. Briefs say "code
  against CONTRACTS.md §n"; review waves own updating it.
- `docs/gameplay/18_engine_spec.md` — the engine contract. §2.1 carries owner
  rulings 8–26. **Owner-locked**: no worker may edit it; the six owed spec
  edits are the owner's (MASTER_REPORT §3 item 1).
- Universal test gate: `res://tests/headless_runner.tscn` → `[SUMMARY]
  passed=457 failed=0` **on any `user://`, including the owner's live one, twice,
  byte-identical, with the live account present and never written** (S2.6, 2026-09-22:
  CONTRACTS §14's runner sandbox — the gate had read 437/0 only on a fresh `user://`
  and 433/4 against the live save, L90/L93; **the scratch-`XDG_DATA_HOME` workaround
  is retired** — §9 of CONTRACTS carries the measured block). (exact command in
  CONTRACTS.md §9; grew 53 → 78 → 219 → 226
  with the UI-chrome wave's `test_ui_slot_layout.gd`, 236 with the combat repair wave's
  `test_engine_c3_flight_decay.gd` and `test_combat_repair_c5.gd`, 277 with the weapon FX
  wave's `test_weapon_fx_f{1,2,4}.gd` suites, 294 with the flight/beam wave's
  `test_flight_feel_g1.gd` and `test_flight_beam_g2.gd`, 311 with slice 2.5's S3 pass, and
  **372 with P2-A's suites** — `test_ship_grids.gd` (27), `test_p2a_profile_fits.gd` (11),
  `test_p2a_launch_fit.gd` (12), `test_p2a_ship_roster.gd` (4), `test_ui_slot_layout.gd`
  rewritten 7 → 12, `test_p2a_lint_shadow.gd` (2)), then 378 with Rock cleave's
  `test_engine2_cleaving.gd` 9 → 15 (the only suite whose count moved; the rock brief's
  311 was stale — its baseline measured 372 against a stashed tree), then **389 with P2-B1**
  (`test_p2b1_outfitting_panel.gd` 0 → 7, then 7 → 9 with F1's two guards; W1's profile
  refusals ride `test_p1_profile.gd`'s +47 assertions and the row count's 6 → 7 move rides
  F1's seventh row), then **437 with P2-B proper** (`test_p2b_retirement.gd` 13,
  `test_p2b_fitting_panel.gd` 18 → 20 with F1's two, `test_p2b_services.gd` 11 → 12 with F1's
  one; F1's profile-fallback tests ride the retirement suite, and F2 cured three pre-existing
  engine2 fixture assumptions to take the **live-profile** gate from 434/3 to 437/0 —
  that live-profile reading did **not** reproduce: 433/4 measured twice on
  2026-09-22 (L93; S2.6-R0/F10 confirms 433/4 on a byte-copy of the live profile)), and
  then **457 with S2.6** (`test_s2_6_gate_hygiene.gd` 3, `test_s2_6_burst.gd` 4,
  `test_s2_6_beam.gd` 4, `test_s2_6_flight.gd` 5, `test_s2_6_blur.gd` 2 — no existing
  count moved; the wave's own two yardstick rows live in `test_flight_beam_g2.gd` and
  `test_weapon_fx_f4.gd`, re-derived by the fixer pass).
- `staging/verify_wave.py` — mechanical wave gates: `snapshot` before a wave,
  `verify --baseline <tag> [--forbidden ...] [--expect-reports ...] [--tests]`
  after. Baselines live in `.agents/gen/_state/_wave_state/` (`wave1_closed`,
  `slice0_start`, `slice2_start`, `pipeline_v2_start`, `cleanup_delete_list`).
- **`AGENTS.md` §"Designer lane — the output format"** — the standing rule for
  how planning work is delivered: docs amended first, one brief, one prompts
  file, queued in this board and in `dispatch_coder.md`, handed over with the
  short paragraph template. Read it before planning or dispatching anything.
- **`AGENTS.md` §"Slice / folder law"** and `.agents/gen/_templates/README.md` —
  the IDs, the folders, the six templates and the brief/slice lifecycle. Read
  before opening a slice or writing any agent file.

## Enforcement protocol (how workers are held to CONTRACTS/WAVEBOARD)

Three layers, in order of reliability:

1. **Injection, not reading** — the orchestrator copies the relevant
   `CONTRACTS.md` section *into* each prompt (source of truth stays
   CONTRACTS.md). A worker never has to go find the contract, so it cannot
   skip it. Review waves diff their findings against CONTRACTS.md, not against
   the brief.
2. **Prevention hook** — `.crush/hooks/enforce_worker_files.py` (registered in
   workspace `crush.json` for `edit|write|multiedit`). The dispatch sets
   `VAJB_WORKER_FILES=<comma-separated rel paths, "dir/" allowed>` and the hook
   denies any write outside that set (fail-open when unset; `.agents/` always
   allowed for reports). Known gap: bash writes bypass it — briefs forbid
   shell-based file edits.
3. **Detection (always applies)** — `staging/verify_wave.py` snapshot before /
   verify after the wave surfaces every touched file; `--forbidden` fails on
   protected files, `--expect-reports` fails on missing reports. Review workers
   also grep pinned signatures across all changed files to catch interface
   drift.

Dispatch template (worker waves, bash form):

```bash
VAJB_WORKER_FILES="vajb-orbit/game/hud.gd,vajb-orbit/ui/hud/hud.tscn" \
  crush run "<prompt>" -m opencode-go/<model> --cwd "<project>"
```

PowerShell form: `$env:VAJB_WORKER_FILES='...'; crush run "<prompt>" -m opencode-go/<model> --cwd "<project>"`

## Review rules for the next waves

- Findings tiering: **HIGH blocks the wave; MED gets one fixer pass; LOW goes
  to a backlog file and rides with the next wave.** Max one fix+re-review
  cycle per wave unless HIGH findings remain.
- Every dispatch sets `VAJB_WORKER_FILES`.
- Review waves diff against `docs/CONTRACTS.md`, not against the brief.
- **Lesson of the last two waves:** workers each implement their slice
  correctly and leave the *seam between them* unwired (slice 0: the reactor
  chain never ticked; slice 2: no weapon damaged a real ship). Reviewers must
  probe at the seams by measurement, never by trusting reports — W8's method
  (re-run the reviewer's probe byte-identically; it caught the fixer once).
- Probe hygiene (L17): a probe that repoints `PlayerProfile.save_path` must
  stop/flush the 0.5 s debounce before restoring `save_path`.

## Closed

Wave closure history lives in `.agents/gen/MASTER_REPORT.md` §6 (moved there
on 2026-09-24 so this file stays the live state only). Git history carries the
version that was here before the move.
