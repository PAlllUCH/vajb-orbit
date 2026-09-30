# WAVEBOARD — one-file agent state

**Session start (read in this order):** 1) this file — header, Living contracts, the queue; 2) `docs/CONTRACTS.md` §n for your wave; 3) `docs/CODE_MAP.md` §n when the task wires into existing scenes or scripts (generated map of what lies where); 4) the slice's `SLICE.md` in `.agents/gen/slices/<SliceID>-<slug>/`; 5) `LOW_BACKLOG.md` only if reviewing or fixing. Old reports are opened only when investigating a regression — slice ID + git tag is how you find the right one.

**Keep this file live-only.** It is read at the start of every orchestrator session, so its size is a recurring cost. It holds the current state, the queue, the living contracts and the enforcement rules — and nothing else. At a wave's close-out, the wave's recap (gate history, deliverables, the gates it raised) is appended to `.agents/gen/MASTER_REPORT.md` §6 and only its one-line outcome stays here. Closed-wave detail moved there on 2026-09-24; do not let it accumulate here again.

**Paths (folder law adopted 2026-09-22):** state files live in `.agents/gen/_state/` — `WAVEBOARD.md` (this file), `LOW_BACKLOG.md`, `_wave_state/` baselines; the folder/ID law and the six templates in `.agents/gen/_templates/`; one folder per slice in `.agents/gen/slices/`, one manifest per phase in `.agents/gen/phases/`. Nothing new is written loose in `.agents/gen/` root. **2026-09-25 clear-outs (owner asks):** every closed slice folder moved to the system trash (last git tree carrying them: `7a081ef`), old session reports live in `_state/_archive/`, and the two dispatch files were purged to live-items-only (2026-09-25 ter). Citation paths into purged trees name historical files.

**Updated 2026-09-27 (P3 planned and queued):** the owner's plan round (focus:
content, bugfixes, playability, feel — pillars A–D all ticked, **no new AI art**,
playtesting owner-first then an external build) landed as phase
**P3-content-feel-push**: docs-first five-pieces for **coder items 27–33**
(S21 stability, S22 feel/juice, S23 content activation, S24 world identity,
S25 contracts, S26 bosses/insurance/vaults, S27 catalog + shipyard) and
**designer items 16–17** (D15 flight-feedback design, D16 station/contracts
UI). The pin rows are the **2026-09-27 P3 blocks** in 01/08/09/10/11/13/14/15
(PROPOSED values + reversals + tick ids M1–M7, C1–C6, W1–W3, J1, E1/E2, K1–K3;
unticked rows implement at their PROPOSED value, the S19 precedent). Manifest:
`phases/P3-content-feel-push/PHASE.md`. **Coder queue: items 27–33 in that
order; designer queue: 16–17 behind live item 15 (D14).**

**Updated 2026-09-26 (S19, closed): ruling 23's directional armour ships — hits
route by `ctx.direction` into four `hull_max/4` pools, the rear 160° arc bites
×1.6 before the shield-first absorb, and an emptied pool runs its breach
malfunction (RCS drift / engine flicker / clipped turn) until repaired.**
Gate **895 → 914/0** twice hermetic (S19's 19 new `test_s19_quadrants.gd` rows +
`test_engine2_damage.gd`'s one corrected row, L240); `verify --baseline s19_start`
green (`"problems": []`). Pin: `09_ship_slots_modules.md` §3.3's 2026-09-26
amendment (P1–P8; owner ticks **T1–T7** stay open, balance deferred) +
`01_economy_core.md` §6's repair note. Five-piece:
`slices/S19-directional-armour/`; recap `MASTER_REPORT.md` §6. Review **1 HIGH
(bucket 2 — the astern shielded row was off the §3 list; S19-F1 moved it onto
P3's own multiplier and wrote the list amendment, L240 closed) / 0 MED / 5 LOW
(L241–L245)**. Ran after S20's close-out per the file-collision law (a first
concurrent dispatch was stopped before writing; baseline re-taken post-S20).
**The coder queue is empty.**

**Updated 2026-09-26 (S20, closed): the owner's S18 playtest feedback became
coder item 25 — ARMORY chrome unification + the hover reflow fix — and it is
done.** The D13 layout stayed frozen; the pane's §3.9 cockpit plates retired for
the **§5.3 chrome family** (`ui_panel_frame` bays/wells/rows, `ui_slot_weapon_*`
cells, `StationButton` plates, `Tokens/armory_*` palette — hex only in
`tools/build_theme.gd`), `ui_armory_console` is unwired on disk and gone from the
pane scene (**L227 closed**, `OVER CAP` 4.855:1), and the station shell's
Inspector reserves a constant height (A4.4 — the "description panel gets bigger /
all shifts up" bug). Pin: `UI_SPEC.md` §3.10 **Amendment 4** (A4.1–A4.5) with the
ticks recorded there (**T1–T4 as briefed, T5 keep, T6 open** = the bay chip's
`▲ OVER CAP` vs `▲ AT CAP` wording — the owner's word owed). Five-piece:
`slices/S20-armory-chrome-unify/`; recap `MASTER_REPORT.md` §6.
**S19 stays coder item 26** (the two collide on `vajb-orbit/tests/` +
`vajb-orbit/tools/`, so they serialize).

**Updated 2026-09-26 (ter): S19 (directional armour & breach malfunctions)
queued as coder item 26** — the owner's direction is gameplay implementation
first, balance later, so ruling 23's quadrants are the wave: `ctx.direction`
routes hits into four armour pools, stern ×1.6, breach malfunctions (RCS
drift / engine flicker / clipped turn), repairs + readouts. Pin:
`09_ship_slots_modules.md` §3.3's 2026-09-26 amendment (P1–P8 PROPOSED with
reversals, tick list T1–T7 — balance deferred, calibrate later). Five-piece:
`slices/S19-directional-armour/`. Gate re-measured this session: **895/0**
(S20 closed 2026-09-26; the S19 wave starts on 895).
The developer session closed its two docs debts: the S18 MED (UI_SPEC §3.10
A3 cell **117×52**) and **L212** (02 §5.2 ter "exactly" → "at most"; rows
stand as history). Roadmap after S19: nebula clouds (ruling 25) → wreck hulks
+ the sibelon seam (art seam) → P4 services; all balance rows stay parked.

**Updated 2026-09-26 (S18): armory rework IMPLEMENTED, reviewed and closed.**
Gate **877/0 → 886/0** (S18's `test_s18_armory_rework.gd` 8 rows + `test_s10`'s
right-click row; six rows renamed 1:1, none lost), twice on fresh scratch
stores; `verify --baseline s18_start` green (`"problems": []`). The ARMORY pane
renders D13's approach B — landscape console 1360×516 at the pinned host, five
2×2-cell bays `B1..B5`, wells band (inventory + pack cards), 13 px ink with zero
`font_size` overrides, captions 4.97–8.56:1, `READY`/`▲ OVER CAP` chip, worded
`HELD n ROUNDS - HOLD n UNITS`, host-derived rects (P6) proven at 1280×720 /
2560×1080 / 1280×1024 in standalone runs; the scripted master re-renders
byte-identical (md5 `b1241913488d4d566e4f670d33d9ca53`, 2720×1032); docs
amendments: UI_SPEC §3.10 **Amendment 3** + STATION_HUB §5.11. Review **0 HIGH
/ 1 MED / 5 LOW (L223–L229)**, plus **two close-out-found silent test aborts the
review missed (L230–L231), cured by one fixer pass (S18-F1: two re-pins, no
assertion weakened, execution proven by value flips)** — the review's MED is
UI_SPEC A3's cell **117×50 → 117×52** (bucket 2, **the developer session owes
the docs fix**).
**L229: the wave's probes booted the owner's live profile and persisted an
auction/exchange band roll at 01:19:16 (T-93 class; no player-owned state
changed)** — run station-mounting probes under `XDG_DATA_HOME=$(mktemp -d)`.
Coder queue: empty. Recap `MASTER_REPORT.md` §6. **Owner fix the same day (live
bug: the pane's text rendered behind its own backgrounds):** the `ConsolePanels`
chrome layer moved under the content and the `DROP HERE` pads into their own grid
slots (L232–L233, both closed, two guards added) — gate **886 → 887/0**.

**Updated 2026-09-25 (quater): D13 armory rework DESIGN closed and verified.**
Gate **877/0 unmoved** (the D13 brief's 866 predates S17's 11 rows), 0 HIGH /
0 MED / 2 LOW **L221–L222**, no fixer; `verify_wave.py verify` green
(`"problems": []`, forbidden `vajb-orbit/ docs/` untouched — `git status`
clean). A0 ran **interactively in the owner's session** (live godot-ai capture
→ analysis against the D12-A0 audit → brainstorm → PIL mockups → owner ticks);
R1 was an in-session re-derivation (byte-identical re-render, findings table,
yardstick; an independent R1 dispatch stays available in `D13_prompts.md`).
**Owner ticks 2026-09-25:** T1 y with the condition **"all resolutions must
work"** (PROPOSED P6 + three canvas proofs 1920×1080 / 2580×1080 / 1920×1536),
**T2 = approach B (full-width dashboard)**, T3–T8 y; adopting the layout
language across the game is **deferred** (owner). Deliverables:
`slices/D13-armory-rework/D13-A0_report.md` (P1–P6 with reversals),
`D13-R1_review.md`, `staging/mockup/armory_mockup_v2.py` + `out/` mockups and
the owner sheet. Recap `MASTER_REPORT.md` §6.

**Updated 2026-09-25 (ter):** dispatch files purged and regenerated per the
owner's ask — the two queues carry exactly two live items: **coder item 17 =
S17 jump gates to sector edges** (`slices/S17-gate-edges/`; docs pin
`11_galactic_map.md` §6 — the border placement at the `FIELD_EDGE_MARGIN` 800
inset, tangent to the corridor band; owner go on "same gates, spawn placement
only") and **designer item 14 = D13 armory rework** (`slices/D13-armory-rework/`;
owner ask: vision + reasoning + brainstorming + mockups; the D12-A0 audit
recap and a live 1920×1080 capture travel inside the slice; design only, the
implementation follows the owner's ticks). **S16 (fragment re-splits) closed
and verified 2026-09-25:** gate 859 → **866/0**, 0 HIGH / 0 MED / 4 LOW
L212–L215, no fixer; recap `MASTER_REPORT.md` §6. **S17 (jump gates to
sector edges, coder item 17) closed and verified 2026-09-25:** gate 866 →
**877/0**, 0 HIGH / 0 MED / 5 LOW L216–L220, no fixer; recap
`MASTER_REPORT.md` §6 — the coder lane's queue is now empty. The owner's earlier
2026-09-25 answers stand (spawn mix kept; the §6/§13/§15 rewording applied on
delegation; the D12 fix wave and D8 item 9 ditched for the armory rework).

**Current state: the universal gate reads `[SUMMARY] passed=941 failed=0`**
(S21's close-out, 2026-09-29: twice on fresh scratch stores, identical on a copy
of the live account, and the live `profile.cfg` byte-identical after; CONTRACTS
§9 carries the authority block, hermetic on scratch stores).

**Updated 2026-09-29 (S21, closed): the P3 bugfix pillar ships — gate 917 →
941/0.** Item 27 ran as **three sequential builders** (owner-ruled 2026-09-28):
B1 the hull and flight scene (A1/A2/A3/A4b/A9a/A9b), B2 the account and station
(A4a/A5/A6/A7/A8), B3 the world bodies, pane copy and harness (A9c/A9d/A10/A11)
plus **two owner-ruled pin moves** — the S19 byte-seal's `npc_ship.gd` hash
re-pinned to the finished tree's `a694170c…`, and A3's reach widened to
NPC-vs-NPC with `LOS_MASK` split out and both moved rows re-pinned. New suite
`tests/test_s21_stability.gd` (23 rows); `verify --baseline s21_start` green
(`"problems": []`); `damage.gd` byte-identical. Review **1 HIGH (bucket 2 — brief
§8's tests-that-move list missing the two `test_s5_*` suites, L246; landed by
S21-F1 as the list amendment on the S19 precedent) / 1 MED (S20's own
silent-abort row at `test_s20_chrome_unify.gd:276`, cured by F1) / 3 LOW
(L247–L249)**. **22 backlog rows closed** (L18/L22/L23/L24/L73/L90/L93/L110/
L114/L122/L124/L130/L131/L136/L150/L152/L153/L154/L176/L215/L237/L243) with
their reversals; the three R-S21 rows ship at their PROPOSED values (ticks
M1/M2/M3 still open). Incident: the first F1 wedged 28 minutes on an **unbounded
Godot `--script` run** and needed a `python3 os.kill` SIGKILL — the shell's
`kill` did not reach it, so bound every worker probe with `--quit-after`. Recap
`MASTER_REPORT.md` §6. **D14 is closed** (owner 2026-09-29; its A5.4 chrome
table landed in `4c0de38`), so the designer lane's live item is **16 = D15**,
which runs next per the queue; coder item 28 (S22) starts on D15's tick sheet.
**Owner-ruled chrome cure, 2026-09-26 (UI_SPEC §3.10 Amendment 5, gate `914/0`
unmoved — no rows added):** after the S19 close-out the owner ruled the ARMORY's
look against AUCTION/SHIPYARD (*"i want all to look this clean"*, *"we always
should use anchors and relative positioning"*). The pane's one frame is the
module host's own `PanelRaised`; bays, well halves, pack rows and inventory rows
wear the flat Tokens box; the cells draw `ui_slot_weapon_*` at its own 48×48
centred (never stretched); the bay chip now reads **`▲ AT CAP`** (T6 ruled);
**L236 closed** (the `✕` accepted at 24×29). A5.2 carries the mechanism as law
(containers/anchors, stylebox chrome, no `_draw` over content) and **AGENTS.md
§Rules** carries the one-line version for every session. The designer slice
**D14** holds the deeper composition questions (its brief + captures are in
`slices/D14-armory-chrome-composition/`).
**S20 (coder item 25) closed 2026-09-26:** the ARMORY wears the §5.3 chrome
family, the shell inspector holds a constant height, `OVER CAP` measures
**4.855:1** (**L227 closed**); gate **887 → 895/0** twice hermetic
(`test_s20_chrome_unify.gd` 7 rows + `test_s11_inspector.gd` +1); 2 HIGH /
1 MED / 4 LOW (**L234–L237**, the last a pre-existing dead guard) — **the MED was fixed by S20-F1** (the pane scene dropped the
retired master's ext_resource) and the **two HIGHs are bucket-2 pin-list items,
L238–L239** (brief §3's tests-that-move list missing two `test_d7_armory.gd`
rows; forced by A4.3, so a list amendment, never a revert — no fixer may take
them); recap `MASTER_REPORT.md` §6.
**Coder queue: empty** — items 25 (S20) and 26 (S19) both closed 2026-09-26;
the next five-piece is the owner's call.
**Live designer item: 17 = D16 station identity & contracts UI** (queued after
D15, closed 2026-09-29 — its tick sheet awaits the owner's ticks); S24/S25/S26
cite D16's spec. Five-piece: `slices/D16-station-ui/`. **Parked (owner-gated, not
queued):** the S12 ore caps/scale rows (the owner's §10 ticks — do not
implement before that wave is briefed), slice 4's remainder (bosses/arena —
14 §5, blocked on P4 contracts + boss art), the §13 turn/coast column ticks
and slice 2.5's engine-bed/vignette calls, S8's owner gates (O1/O2 FITTING-drag
UX, O3, L168, L169), the chrome art half, the designer candidates (D9-11,
D10-12, D3-1, D3-2a/2b, D4-3/4, blocked 5/6 — parked in
`dispatch_designer.md`), and adopting the D13 layout language across the game
(owner-deferred).

**Updated 2026-09-29 (D15, closed): the 25-row feel tick sheet is resolved and
waiting on the owner's ticks** (`slices/D15-flight-feedback/D15-A1_report.md`;
`FX_SPEC.md` §8 + `AUDIO_SPEC.md` §8.6 append-only amendment blocks and the A5.2
feedback composition landed with it — quadrant feed, hit-marker strike-X, ram
spark, `staging/mockup/out/d15_feedback_composition.svg`). A1 → R1, **0 HIGH /
2 MED cured / 2 LOW (L250–L251)**; `verify --baseline d15_start` green, gate
**941/0 unmoved**. **Two bucket-3 forks wait on the owner**: AUDIO-3/L49
(`sfx_weapon_laser_04` drop-then-trim vs keep) and T-feel-1's fuse-vs-orbit.
Unticked rows implement at their PROPOSED value when S22 opens (docs-first).
Recap `MASTER_REPORT.md` §6.

Closed-wave recaps live in `.agents/gen/MASTER_REPORT.md` §6.

## Queued (phase P3 — `phases/P3-content-feel-push/`; one live session, one item per order)

| Pos | Lane item | Wave | Runs after | The collision/dependency that forces the order |
|---|---|---|---|---|
| 1 | coder 27 | S21 stability & playtest fixes (**done 2026-09-29**, 917 → 941/0) | — | — |
| 2 | designer 16 | D15 flight feel & feedback design (**done 2026-09-29** — tick sheet → S22) | coder 27 | one live session (L82); its tick sheet is coder 28's input |
| 3 | coder 28 | S22 feel, juice & balance | designer 16 | implements D15's ticks; both touch `ui/hud/` |
| 4 | coder 29 | S23 content activation | coder 28 | `vajb-orbit/game/` + `tests/` (weapons/projectile/mining seams) |
| 5 | designer 17 | D16 station identity & contracts UI | coder 29 | one live session; its spec is coder 30/31/32's design law |
| 6 | coder 30 | S24 world identity | designer 17 | `station_catalog` + the station screen (D16 spec first) |
| 7 | coder 31 | S25 contracts board | coder 30 | `ui/station/` + `autoload/player_profile.gd` + S24's `contracts_visible` seam |
| 8 | coder 32 | S26 bosses, arenas, insurance, vaults | coder 31 | `game/` + `player_profile.gd` + S25's Expedition seam |
| 9 | coder 33 | S27 catalog breadth & shipyard | coder 32 | `game/module_catalog.gd`/`loot_tables.gd` + `ui/station/` |

Designer item **16 (D15)** is the designer queue's live item (D14 closed
2026-09-29); 17 (D16) follows it. Playtest
pass #1 (the owner's, `19_testing_notes.md`'s eye list) runs alongside pos 1;
build 2 + the tester template are phase exit criteria. Every brief's §11 tick
sheet feeds its wave (unticked rows implement at their PROPOSED value).

## Living contracts

- `docs/CONTRACTS.md` — pinned interfaces; the merged section pins (§5
  cleaving, §11 ship frames, §12 weapon fit, §13 fitting, §14 runner
  sandbox, §17 armory panel, §18–§23 by wave) are the seams briefs code
  against; **§9 carries the live gate figure (895/0 after S20's close)** and
  §10 the changelog. Briefs say "code against CONTRACTS.md §n"; review
  waves own updating it.
- `docs/gameplay/18_engine_spec.md` — the engine contract. §2.1 carries
  owner rulings 8–26. **Owner-locked**: no worker may edit it; owed spec
  edits are the owner's (MASTER_REPORT §3 item 1).
- Universal test gate: `res://tests/headless_runner.tscn` → `[SUMMARY]
  passed=<live count> failed=0`, run **twice on fresh scratch stores**
  (`XDG_DATA_HOME=$(mktemp -d)`), byte-identical; CONTRACTS §14's runner
  sandbox law and §9's measured block are the authority. Growth history
  (437 → 895 across the waves) is `MASTER_REPORT.md` §6.
- `staging/verify_wave.py` — mechanical wave gates: `snapshot` before a
  wave, `verify --baseline <tag> [--forbidden ...] [--expect-reports ...]
  [--tests]` after. Baselines live in `.agents/gen/_state/_wave_state/`
  (e.g. `s16_start`; the wave's brief names its own).
- **`AGENTS.md` §"Designer lane — the output format"** — the standing rule for
  how planning work is delivered: docs amended first, one brief, one prompts
  file, queued in this board and in the lane's dispatch file, handed over
  with the short paragraph template. Read it before planning or dispatching
  anything.
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
