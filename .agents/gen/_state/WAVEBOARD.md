# WAVEBOARD — one-file agent state

**Session start (read in this order):** 1) this file — header, Living contracts, the queue; 2) `docs/CONTRACTS.md` §n for your wave; 3) `docs/CODE_MAP.md` §n when the task wires into existing scenes or scripts (generated map of what lies where); 4) the slice's `SLICE.md` in `.agents/gen/slices/<SliceID>-<slug>/`; 5) `LOW_BACKLOG.md` only if reviewing or fixing. Old reports are opened only when investigating a regression — slice ID + git tag is how you find the right one.

**Keep this file live-only.** It is read at the start of every orchestrator session, so its size is a recurring cost. It holds the current state, the queue, the living contracts and the enforcement rules — and nothing else. At a wave's close-out, the wave's recap (gate history, deliverables, the gates it raised) is appended to `.agents/gen/MASTER_REPORT.md` §6 and only its one-line outcome stays here. Closed-wave detail moved there on 2026-09-24; do not let it accumulate here again.

**Paths (folder law adopted 2026-09-22):** state files live in `.agents/gen/_state/` — `WAVEBOARD.md` (this file), `LOW_BACKLOG.md`, `TICKS.md`, `_wave_state/` baselines; the folder/ID law and the six templates in `.agents/gen/_templates/`; one folder per slice in `.agents/gen/slices/`, one manifest per phase in `.agents/gen/phases/`. Nothing new is written loose in `.agents/gen/` root. **Clear-out history:** the 2026-09-25 and 2026-10-07 owner clear-outs and their extraction files are listed in `_templates/README.md` §"2026-10-07 (owner clear-out)". **2026-10-08 clear-out (owner ask):** the board keeps only the S24–S27 queue — the S36/S37 `Updated` blocks moved to `_archive/waveboard_updates_2026-10-07_to_2026-10-08.md`, the closed S36/S37 slice folders to `_archive/slices/`, the dispatch done sections to `_archive/dispatch_done_2026-10-08.md`, the S36/S37 backlog rows to `_archive/low_backlog_s36_s37_rows_2026-10-08.md`, and the S36 baseline to `_archive/wave_state_baselines/`. Citation paths into moved trees name historical files.

Closed-wave recaps live in `.agents/gen/MASTER_REPORT.md` §6.

## Queued (phase P4 — `phases/P4-station-overhaul/`; one live session, one item per order)

| Pos | Lane item | Wave | Runs after | The collision/dependency that forces the order |
|---|---|---|---|---|
| 1 | **S42 — the OVERVIEW 3×3 grid rework** (P4's first implementation wave, re-cut from D24's amendments) | S42 | the owner's tick sheet (unticked rows implement at their PROPOSED values) | D24 closed 2026-10-12: §23's P44–P47 + T-184 rework `overview_panel.gd` and its nine tiles only — the smallest blast radius of the eight amendment clusters, and TICKS' S41 chrome-token row re-presents with the reworked OVERVIEW. The remaining clusters (buy-confirm doors, Cargo overlay, launch+audio, armory list, refinery/CRAFT, bulk sell, shipyard view) queue after it. Brief pending (the brief loop). |

**Updated 2026-10-12 (D24 the station-overhaul design round closed — P4's opener).**
The owner's nine build-2 asks became pinned design in six docs, every new value
**PROPOSED** with its reversal: STATION_HUB **§23** (P44–P54: the 3×3 nine-tile
grid at `TILE_MIN` (240, 120), the 3.0 s departure sequence, the armory
EQUIPPED list, `LOAD ALL` + the machine strip + the REFINE/CRAFT pair, the
exchange `CheckChip` bulk sell, the shipyard house-style build view;
**T-184** cured by the `text_caption` modulate; T-174/175/176 cures folded;
§23.10 tick table + §23.11 supersession ledger), UI_SPEC **§17/§18** (the
buy-confirmation law A4–A6; the C-key Cargo overlay A7–A9, one surface both
planes), AUDIO_SPEC **§8.7** (S27/S28 cues), **04 §9** R9–R12, **07 §6**
C1–C10 (crafting specced for real), **10 §3.5**. Ran A1 (`hyper/glm-5.3` —
before the owner's mid-wave model directive) → R1 → F1 (both
`xiaomi/mimo-v2.6-pro` @ high): R1 left **no HIGH, 4 MED, 5 LOW** (F2 cured in
review, disclosed); F1 cured F1/F3/F4/F5; 5 LOW → **T-186–T-190**. Gate
**1330/0 ×2 byte-identical**, verify clean vs `d24_start`. The **§23.10 tick
table is the owner's tick sheet** (15 rows + 4 flagged decisions). The P4
implementation waves are staged: **S42 — the OVERVIEW grid rework** (P44–P47
+ T-184) queued first. Full block: `MASTER_REPORT.md` §6's "D24".

**Updated 2026-10-12 (P3 CLOSED — the owner's build-2 playtest ran; P4 opened).**
The exit pass filed **T-184** (the OVERVIEW's ARMORY/LAUNCH tile glyphs not
visible — the two untinted raster icons modulate WHITE against the C1 slab) and
**T-185** (a launch sequence with sound), and ruled on the ten presented ticks:
**caption tone RATIFIED** (UI_SPEC §16.1 A1); **T-174/T-175/T-176 cures
approved** (ride P4); **T-178 closed** ("ok for now" — 10 §3.1's block);
**T-181/T-182 closed** (STATION_HUB §5.7/§15.1 carry the rulings); **the
OVERVIEW tradeoff superseded** by the owner's 3×3-grid ruling; **T-179
postponed** ("didn't test, postpone"); the **S41 chrome tokens stay PROPOSED**
(the reply carried T-184 instead of a ruling; they re-present with the
reworked OVERVIEW). The station-overhaul asks — the armory equipped list, the
C-key Cargo popup, refinery LOAD ALL + machine read + the CRAFT tab, exchange
bulk sell, buy-confirmation popups, the shipyard build rework, the 3×3 grid —
are recorded verbatim in **STATION_HUB §22** and `phases/P4-station-overhaul/`,
queued as **D24** in the design lane (`dispatch_designer.md` item 1). Next free
ticket **T-186**. Full block: `MASTER_REPORT.md` §6's "P3 close — the owner's
playtest of build 2".

**Updated 2026-10-12 (phase-prep pass closed — the developer session, housekeeping
not a wave).** The gate re-read **1330/0 ×2 hermetic on fresh scratch stores,
byte-identical, zero `SCRIPT ERROR` lines**. **T-183 closed:** `staging/gate.py` is
now the gate's mechanical wrapper (the pinned §9 command unchanged; a fresh
`XDG_DATA_HOME` scratch store per run; `[SUMMARY]` byte-identity across `--times 2`;
a hard fail on any `SCRIPT ERROR` line, attributed to the row that follows it —
`EngineDebugger` message capture is measured blind to runtime errors, so no
in-process guard exists; a nil-property canary failed the wrapper while the engine
still printed `[PASS]`, then was removed). `verify_wave.py --tests` routes through
the same check. **Repo hygiene:** the 2026-10-08 owner clear-out (1 009 deletions
plus its doc updates) was never committed — landed now (`d77aba6`), with the five
missing `.uid` sidecars; trash removed (a stray `package-lock.json`, `__pycache__`,
the unreferenced `mine_deploy-mechanical/` extraction). **Playtest build 2
delivered:** `builds/vajb-orbit-0.4-2026-10-12-d77aba6-{linux,windows}/` — v0.4 on
the menu, CHANGELOG 0.4, the tester README re-cut (six of 0.3's eight
ALREADY-KNOWN rows are fixed in code; three live owner-call quirks listed), Linux
smoke-tested clean (Vulkan, exit 0, benign leaks only), Windows verified
structurally, zips + SHA256SUMS written. `19_testing_notes.md`'s 2026-10-12
amendment re-cuts the eye list for build 2. **P3's remaining work is the owner's
alone:** the eye list, the TICKS ratifications, and the rulings T-178/T-179/
T-181/T-182. Full block: `MASTER_REPORT.md` §6's "P3 phase-prep close".

**Updated 2026-10-11 (S41 the composition pass closed — the D23 design audit implemented).**
Gate **1300 → 1330/0** ×2 hermetic on fresh scratch stores (only T-155's salvo
jitter differs), verify clean vs `s41_start`, `build_code_map.py` re-run (126
scenes / 317 scripts). The source is **`slices/D23-panel-audit/D23-R1_audit.md`**
— a visual / UI designer's audit of the ten station decks at 1920×1080 (all ten
renders viewed, every finding source-verified), **16 findings: 1 HIGH, 8 MED,
7 LOW**. Five builders ran: B1 (theme + shell), B2 (overview / exchange /
auction), B3 (armory), B4 (refinery / launch / contracts / shipyard) in parallel
on disjoint file sets, then **B5** — the completion pass the file-set stop forced
(F8's auction chrome needed `auction_panel.gd`; F15's services half needed
`station.gd`), which is the S27 lesson working as designed. **R1**
(glm-5.3-flash, **code and visual**) returned **passed-with-followups**: all 16
findings fixed at their named sites and **visible on ten fresh renders**, the
layout and token laws held, and the gate's §6 rows were unmoved. **T-177 closed**
(the theme generator now preserves the `.tres`'s 19 uid lines; a regeneration is
a byte no-op — proved by R1's own run). One MED is an owner call (B2/F01: the
OVERVIEW hull block now sits below the fold, because all three service rows took
the unscrolled seat); three LOW → **T-180/T-181/T-182** (the tooltip vs a pane's
own header; STATION_HUB §5.7's refinery wording; §19.4's strip height), plus
**T-183** filed at close-out: a suite row that raises a `SCRIPT ERROR` still
reports `[PASS]`, so the gate hid a broken premise (`test_s24_world.gd:383` read
the identity character line S41's F1 retired) until the orchestrator read the gate
log; the row is re-cut and the gate now carries **zero** `SCRIPT ERROR` lines.
Next free ticket **T-184**. Every new chrome value is **PROPOSED** on TICKS. The
queue is still empty — P3's exit is the owner's playtest (build 2).

**Updated 2026-10-10 (S27 catalog breadth & the shipyard closed — item 33, P3's last code wave).**
Gate **1275 → 1300/0** ×2 hermetic on fresh scratch stores (only T-155's salvo
jitter differs), verify clean vs `s27_start`, `build_code_map.py` re-run. Two
builders: B1 landed A1–A7's data (the seven R-S27-2 rows, the 15 tier variants,
the four loot kinds, `game/shipyard.gd`, the tier-4 rider) but its file set was
under-scoped — the flight call sites A2 needs (`weapons.gd:_consume_ammo_at`,
`game.gd:_update_lock`/`_on_npc_died`) and A5's `Shipyard.note_flight` caller sit
outside it, and four pinned rows its own rows obsoleted were in `tests/`; B2
closed both gaps (the brief §7/§8 amendments are the developer's bucket-2
resolution). R1 (glm-5.3-flash) left **no HIGH**, 2 MED and 1 LOW: a Rare could
roll two same-property prefixes (cured by F1 — a `stat`-level dedupe in
`roll_prefixes`) and the Pyre's below-quarter gate was vacuous in flight (cured
by F1 — a `NpcShip.pre_hit_hull_fraction()` store, its AC6 seal re-pinned, the
S22 procedure). F3 → **T-178** (the shipyard build band post-S28). **T-153
closed.** CONTRACTS **§20 S27 block** + §9 + §10 **v0.56/v0.57**; ticks **K1–K3**
shipped PROPOSED, not separately ruled. A post-fix verification review
(**S27-R2**, glm-5.3-flash) returned **clean** — no HIGH, no MED, both fixes
proven (the prefix dedupe over 27k seeded Rare rolls; the Pyre gate in live
flight) — and filed **T-179** (the Pyre ring's own-kill cascade, an owner ruling).
Next free ticket **T-180**. The queue is
now empty — P3's exit is the owner's playtest (build 2).

**Updated 2026-10-10 (owner visibility review — S40).** The owner's follow-up to
playtest #2 (the armory's installed-modules overview has no background; the
OVERVIEW tiles' icons and texts are unreadable on theirs; "a review of visibility
is needed and composition") became the review **`slices/S40-legibility/S40_REVIEW.md`**
— ten decks rendered at 1920×1080 and **607 text labels measured for WCAG contrast
against the framebuffer behind their own ink rect** (`tests/probe_s40_panes.gd`).
It found one root cause repeated 235 times: the shared `SectionHeader` /
`StationCaption` / `FlavourText` variations were wired to `text_dim` `#6b7484`,
which reads **2.85–2.96:1** on the shipped row/plate fills. The cure was already
in the tree on the armory's own path (`armory_caption` `#acb2ba`, §3.10 A4.3);
S40 generalised it as **`text_caption`/`text_caption_void`** (UI_SPEC **§16**),
gave the armory's FitCells left column the flat Tokens box, and moved the OVERVIEW
tile ink onto the caption tone. Measured: below-AA **241/607 (39.7 %) → 34/610
(5.6 %)**, below-3.0:1 **47 → 5**. Gate **1267 → 1275/0** ×2 hermetic; new suite
`tests/test_s40_legibility.gd` (8 rows). **T-171/T-172/T-173 closed**;
**T-174/T-175/T-176** (the launch briefing column, the four header-caption
surfaces, the staged row's 1.61:1) and **T-177** (the theme generator drops the
`.tres` uids) filed open; next free **T-178**. The queue is unchanged — **S27**.
**Updated 2026-10-10 (owner playtest #2 closed — item 36, S39).** The owner's
second eye over the live build filed seven findings, all riders on the wave **S39**
and ticketed **T-164–T-170**, now **closed**: enemies shoot back (a per-archetype
`NPC_WEAPONS` table + the brain's `INTENT_FIRE` consumed on the shipped
`projectile.gd` pipeline); a 180° reversal accelerates at `REVERSAL_ASSIST_MULT`
1.6; Shift is a baseline boost (`BOOST_BASE_MULT` 1.25) that buys **thrust** and
the afterburner stacks on top; a convoy recovers its route (the along-track
`_leg_reached` leg advance); `Impact.KNOCKBACK_FRACTION` drops 0.40 → 0.15; and
the hold is visible in flight (a HUD `CargoBlock`) and at the armory (`HOLD %d/%d`).
Gate **1258 → 1267/0** ×2 hermetic; new suite `tests/test_s39_feel.gd` (9 rows);
`test_s19_quadrants.gd` re-pinned `npc_ship.gd`/`npc_brain.gd`; CONTRACTS **§29** +
§10 **v0.55**; every new number **PROPOSED** with its reversal (awaiting the
owner's fold-in to the owner-locked `18_engine_spec.md`); next free **T-171**. The
queue is now **S27 alone**.
**Updated 2026-10-10 (S26 endgame closed — item 32).** Gate **1237 → 1258/0** ×2
hermetic on fresh scratch stores (the row sets byte-identical; only T-155's salvo
jitter differs), verify clean vs `s26_start`, `build_code_map.py` re-run. B1
landed A1–A8 (+20 `test_s26_endgame.gd` rows); the mandatory review left **1 HIGH
+ 4 MED** (Champion's ×0.8 never reached the premium; the payout's replacement
branch granted an unowned hull and wiped a survivor's fit; the Maw's in-game kill
rolled the ×2.0 tier scale over 06 §3.4's flat table; two §15.4 captions
unrendered) and F1 cured all five at their named sites, moving no test row
(reviewer's probe 80/1 → 81/0). The brief §8's tests-that-move list held exactly
(+20 new, `test_s25_contracts.gd` **+1 net** — three seam rows re-pointed to the
S26 reading, re-cut by the orchestrator before the review, S38's precedent).
2 LOW → **T-161/T-162/T-163** (next free **T-164**); **CONTRACTS §28** added, §10
**v0.54**, and the wave's own numbers landed in `14`'s **2026-10-10 S26 block**;
ticks E1/E2 shipped as PROPOSED. R1's first dispatch no-op'd (a
reasoning-only turn with no tool call) and was re-dispatched unchanged.
**Updated 2026-10-09 (the owner's playtest — the board drew no rows).** The
owner's first eye over S38 reported "there are no contracts available, even when
they refresh". The board **was** rolled, live and undimmed — but the shell's
service host mounted each service pane without a vertical size flag, so the
CONTRACTS pane answered its 173 px minimum and the board's scroll collapsed to
its **2 px** minimum: the deck drew a header, a note and nothing else, with the
countdown the only thing still visible. Fixed at the host (`station.gd:1164`,
`content.size_flags_vertical = SIZE_EXPAND_FILL`, A5.1's own rule), which also
restores the collapsed `MODULE OFFLINE` INSURANCE/VAULTS placeholders. Gate
**1236 → 1237/0**; measured off a rendered 1920×1080 frame (board 568 px, scroll
397 px, five rows drawn plus the sixth on scroll); **T-160** filed and closed;
CONTRACTS §10 **v0.52**. No pinned number or registry signature moved.
**Updated 2026-10-08 (S38 board clock + hub cold start closed — item 35).** Gate
**1226 → 1236/0** ×2 hermetic on fresh scratch stores, **zero** `SCRIPT ERROR`
lines; verify clean vs `s38_start`; B1 +10 rows, one MED (a stale test message)
cured by F1, two LOW → T-158/T-159; **T-156/T-157 closed**; CONTRACTS **§27** +
§10 **v0.50/v0.51**. The wave also exposed the limits of the brief's §8
"tests-that-move" list: H1 reaches seven premises, not three, and the orchestrator
re-cut the four it had missed (`&""` → `&"sector_7"` fixture restorations plus the
`REGISTRY_MD5` re-pin) before the review — disclosed in `S38-B1_report.md` and
CONTRACTS §10. Full block:
`_archive/waveboard_updates_2026-10-07_to_2026-10-08.md`; recap:
`MASTER_REPORT.md` §6.
**Updated 2026-10-08 (S25 contracts board closed — item 31).** Gate **1202 → 1226/0**
×2 hermetic, verify clean vs `s25_start`; R1 blocked on 2 HIGH (the loop had no
production caller; a band-flaky escrow row) + 1 MED (Hunt's flat standing), F1
cured all three with a negative control, 2 LOW → T-156/T-157; **T-138/T-152/T-154
closed**; CONTRACTS **§26** + §9's finished chain + §10 v0.49. Full block:
`_archive/waveboard_updates_2026-10-07_to_2026-10-08.md`; recap:
`MASTER_REPORT.md` §6.
**Updated 2026-10-08 (S28 universal cost law closed — item 34).** Gate 1186 → 1202/0
×2 hermetic; no HIGH, one MED fixed in review, two LOW → T-154/T-155; CONTRACTS
§25; ticks M8–M14 owner-ratified green. Recap: `MASTER_REPORT.md` §6.
**Updated 2026-10-08 (S24 world identity closed — item 30).** Gate 1152 → 1186/0
×2 hermetic; R1's 1 HIGH cured by F1, 2 LOW → T-152/T-153; ticks W1–W3 + V1–V8
owner-ratified green. Recap: `MASTER_REPORT.md` §6.

These two are the whole live queue — every earlier item is closed and archived
(`_archive/dispatch_coder_done_2026-10-07.md` + `_archive/dispatch_done_2026-10-08.md`
+ `MASTER_REPORT.md` §6). Playtest pass #1 (the owner's, `19_testing_notes.md`'s
eye list) runs alongside; build 2 + the tester template are phase exit
criteria. Every brief's §11 tick sheet feeds its wave (unticked rows implement
at their PROPOSED value).

## Living contracts

- `docs/CONTRACTS.md` — pinned interfaces; the merged section pins (§5
  cleaving, §11 ship frames, §12 weapon fit, §13 fitting, §14 runner
  sandbox, §17 armory panel, §18–§27 by wave) are the seams briefs code
  against; **§9 carries the live gate figure (live in CONTRACTS §9)** and
  §10 the changelog. Briefs say "code against CONTRACTS.md §n"; review
  waves own updating it.
- `docs/gameplay/18_engine_spec.md` — the engine contract. §2.1 carries
  owner rulings 8–26. **Owner-locked**: no worker may edit it; owed spec
  edits are the owner's (MASTER_REPORT §3 item 1).
- Universal test gate: run **`staging/gate.py --times 2`** — the pinned §9
  command on fresh scratch stores, `[SUMMARY] passed=<live count> failed=0`
  byte-identical across runs, **and a hard fail on any `SCRIPT ERROR` line**
  (T-183, closed 2026-10-12: an erroring row still prints `[PASS]`, so the
  wrapper is the only eye; CONTRACTS §9's seventh harness limit); §14's runner
  sandbox law and §9's measured block are the authority. Growth history
  (437 → 1330 across the waves) is `MASTER_REPORT.md` §6.
- `staging/verify_wave.py` — mechanical wave gates: `snapshot` before a
  wave, `verify --baseline <tag> [--forbidden ...] [--expect-reports ...]
  [--tests]` after. Baselines live in `.agents/gen/_state/_wave_state/`
  (the wave's brief names its own).
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
