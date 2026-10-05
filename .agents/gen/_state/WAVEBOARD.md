# WAVEBOARD — one-file agent state

**Session start (read in this order):** 1) this file — header, Living contracts, the queue; 2) `docs/CONTRACTS.md` §n for your wave; 3) `docs/CODE_MAP.md` §n when the task wires into existing scenes or scripts (generated map of what lies where); 4) the slice's `SLICE.md` in `.agents/gen/slices/<SliceID>-<slug>/`; 5) `LOW_BACKLOG.md` only if reviewing or fixing. Old reports are opened only when investigating a regression — slice ID + git tag is how you find the right one.

**Keep this file live-only.** It is read at the start of every orchestrator session, so its size is a recurring cost. It holds the current state, the queue, the living contracts and the enforcement rules — and nothing else. At a wave's close-out, the wave's recap (gate history, deliverables, the gates it raised) is appended to `.agents/gen/MASTER_REPORT.md` §6 and only its one-line outcome stays here. Closed-wave detail moved there on 2026-09-24; do not let it accumulate here again.

**Paths (folder law adopted 2026-09-22):** state files live in `.agents/gen/_state/` — `WAVEBOARD.md` (this file), `LOW_BACKLOG.md`, `_wave_state/` baselines; the folder/ID law and the six templates in `.agents/gen/_templates/`; one folder per slice in `.agents/gen/slices/`, one manifest per phase in `.agents/gen/phases/`. Nothing new is written loose in `.agents/gen/` root. **2026-09-25 clear-outs (owner asks):** every closed slice folder moved to the system trash (last git tree carrying them: `7a081ef`), old session reports live in `_state/_archive/`, and the two dispatch files were purged to live-items-only (2026-09-25 ter). Citation paths into purged trees name historical files.

**Updated 2026-10-04 (S32 closed — ARMORY ships as two modules):** B1
(`hyper/deepseek-v4.1-flash` @ xhigh) → R1 (`hyper/glm-5.3-flash` @ max,
verdict blocked on 1 HIGH) → F1 (as B1). ARMORY is now FIT CELLS (cell grid +
CELL INFO + FITS HERE + BUYABLE THAT FITS) and BATTERY CONFIG (B1–B5 full-width
racks + read-only `W<n> — EMPTY`), AMMUNITION + PWR in one shared foot band.
Gate **1099 → 1110/0** ×2. R1's HIGH (P36's dead space vs the pinned console
rect) cured under the designer's bucket-2 ruling: the console stretches
full-width and 13 geometry rows re-anchor (disclosed); **T-122 closed**. F2–F4
cured with it (`set_mode` pure visibility, `MeterLabel` reverted, containment
row tightened); 2 LOW → **T-129/T-130**. Verify green vs `s32_start`. **Next:
coder 30 (S24 world identity)** after its brief re-check.

**Updated 2026-10-04 (S31 closed — the D20 quick fixes shipped):** B1
(`hyper/deepseek-v4.1-flash` @ xhigh) → R1 (`hyper/glm-5.3-flash` @ max), **no
fixer** (acceptance 1–7 all PASS; 0 HIGH / 0 MED / 4 LOW). N42–N47 live: the
exchange parity cluster (title 232–242 px, both lists on one y, per-book
bands), the armory browser contained (620 half, 160 px ellipsis titles), the
tooltip's 0.5 s linger + readable `text_primary` body. Gate **1093 → 1099/0**
×2, verify green vs `s31_start`; T-118–T-121 closed, T-122 rides S32,
T-127/T-128 filed. The T-101/T-110 input-map rows landed the same close (M,
E + pad X, PageUp/PageDown, T — `project.godot` via `input_map_manage`).
Process lesson: `VAJB_WORKER_FILES` needs trailing slashes or the hook denies
every edit. **Next: coder 38 (S32 armory two-module rework).**

**Updated 2026-10-04 (D20 closed — the owner's own playtest compiled):** two
live game reviews on the same brief (`xiaomi/mimo-v2.6-pro` @ high →
`hyper/glm-5.3-flash` @ max; one game window, shared save profile) merged with
the owner's five notes in `slices/D20-station-playtest/D20_synthesis.md`.
Confirmed: the armory browser overflow (**HIGH** — rows 542–620 px min in a
478 px viewport, INSPECT chips past the window edge) and the exchange hold
cluster (titles 28 px vs 517, header band +109 px off its columns, lists 26 px
apart); TERMINAL/AUCTION verified as the owner reads them (my brief's "right
drawer" wording was wrong — N26 pins left, the build matches). Tickets
**T-118–T-126** filed (6 LOW + 3 owner calls). **Next: the D20 fix wave
five-piece (F1 exchange parity, F2 armory overflow, F3 inspect popup — quick;
F4 the armory 2-module rework — its own wave; F5 the LOW pack) on the owner's
go; coder 30 (S24) stays parked behind it.**

**Updated 2026-10-03 (S29 closed — the overhaul implemented; one provider
incident):** coder 35 ran B1 → B2 → R1 → F1. B1's first dispatch
(`hyper/glm-5.3`) **died on provider credits mid-build** (partial artefacts, no
report); the owner re-routed the resume and B2 to `xiaomi/mimo-v2.6-pro` @
high. Gate chain **1038 → 1063/0** (B1, +25 rows) **→ 1073/0** (B2, +10 rows;
nine moved suites disclosed) — ×2 fresh scratch at every stage, R1's re-run
agreed. The merged ARMORY and SHIPYARD are live (rail 8 → 6), the map deck
with pin navigation and the `e_hyperdrive` module ships. R1: 1 HIGH (the pin
marks drew `Color.WHITE` vs the pinned `text_primary`) + 1 MED (the ESC-open
desync) both cured by F1 — the MED by the designer's bucket-1 ruling (ESC-open
cancel and pin-remove are one operation, reversal recorded); 7 LOW →
**T-100–T-106** (the D13 battery body's keep-or-retire is the owner's tick).
Verify green against `s29_start`. The parallel **D17-P3 test worker died on
the same credits mid-route**; its partial report verifies the S28 menu rows it
reached (quit copy FIXED, Q/E deconfliction FIXED, TURN fold PARTLY) and is
honest about the rest. **Next in the phase: coder 30 (S24 world identity).**

**Updated 2026-10-03 (the parallel pair closed — S28 + D18, first approved
two-wave run):** dispatched back-to-back on disjoint file sets (S28:
`vajb-orbit/ui game tests`; D18: `docs/design staging/mockup`) — **S28-B1**
(`hyper/qwen3.8-flash` @ high) shipped A1–A16 on the survivor panels: the
inspector band clears on every module switch, CONTROLS deconflicts (steal +
worded conflict flag, TURN LEFT/RIGHT behind ADVANCED), the strip never rides
`NO_DAMAGE_REPORT`, shield reads one source (400, the catalogue row),
`StationCatalog.plural()`, DevTuningMenu debug-gated, and P1–P3 button/focus
unification on the survivors — gate **1031 → 1038/0** (B1 ×2 + R1's re-run,
fresh scratch), 7 added rows, every moved row disclosed. **S28-R1**
(`hyper/glm-5.3-flash`): all sixteen pass, **0 HIGH / 0 MED / 2 LOW →
T-98/T-99** (the CAP-vs-CR-EACH tick; three stale doc rows). **D18-A1**
(`hyper/glm-5.3` @ high, the demanding slot) landed the design depth:
UI_SPEC **§10** (map deck + pin detail, **N7–N14**; after the fixer **N15–N23**
blip classes) and STATION_HUB **§17** (merged-panel detail, **P8–P14**, the
P6/P7 law blocks) + three wireframes. **D18-R1**: A1–A6 all pass, **0 HIGH /
3 MED** (pin press precedence, pin-follow vs N14 pan, the toggle→blip-class
mapping) **cured by D18-F1**; 4 LOW → **T-94–T-97** (cite drift rows).
Both verifies green against the shared `s28_start`/`d18_start` baseline
(`"problems": []`). **Next: coder 35 (S29) implements D18's law — its
five-piece is live this session; then the phase's items 30–33.**

**Updated 2026-10-03 (the owner's overhaul ruling — D18/S28/S29 queued, live
this session):** after the two in-game playtest reviews (`slices/D17-playtest-pass/`),
the owner ruled the map/navigation and panel overhaul (`D16_UserInput.md` at the
root, committed verbatim): the minimap grows a **map deck** (expand, pan, zoom,
per-sector filters, **pin navigation** with hold-LMB **hyperdrive** jump — a new
module, none exists today), **ARMORY+FITTING** and **SHIPYARD+REPAIRS** fold into
single panels (drag-and-drop with auction-style slot filter tabs, hover→describe
in the bottom inspector, equipped items shown on hulls), the stale inspector band
is cured, and the whole station chrome pile from the reports is fixed. The pins
landed docs-first: **UI_SPEC §8 (P1–P3 buttons/focus) + §9 (N1–N6 map deck) +
STATION_HUB §16 (P4–P7 consolidation) + 10's 2026-10-03 block (N5 hyperdrive
row)**. Waves: **D18** (design, `slices/D18-map-panels/`) and **S28** (the
mechanical chrome fixes, `slices/S28-station-chrome/`) run **in parallel** (disjoint
file sets); **S29** (implementation of D18's law) follows them; the phase's
items 30–33 shift behind. **Model roster (owner, 2026-10-03): very demanding
work runs `hyper/glm-5.3`; the rest `hyper/qwen3.8-flash` or
`hyper/glm-5.3-flash`.** D18-A1 = glm-5.3 @ high; S28-B1 = qwen3.8-flash @
high; both R1s = glm-5.3-flash @ high.

**Updated 2026-10-03 (D16 closed — station identity & contracts UI design):**
ran A1 → R1 → F1 (fixer pass for the review's two MEDs) on the owner's
2026-10-02 routes (A1 `xiaomi/mimo-v2.6-pro` @ high, R1 `hyper/glm-5.3-flash`
@ high). A1 landed `STATION_HUB.md` §15 (the three service panels, the
nine-place identity treatment, presentation values **U1–U20** with reversals)
+ `UI_SPEC.md` §7 (A5.4 extension rows A5.4-1…6; A5.4-6 answers **L263**'s
four-cell SALVO drum, tick U18, heavy-cadence icon staged pending generation
budget) + four `.md` wireframe mockups in `staging/mockup/` (ruled lawful by
R1). R1 graded A1–A5 all pass — **0 HIGH / 2 MED cured / 2 LOW → L267–L268**.
Tick sheet with the owner: **W3** (nine names) + U1–U20; owner flags: vault
unit totals 40/60/80 vs 20/40/60 (U14), outpost faction = sector primary
(PROPOSED), character line replaces `StationLocation` (U17). `verify
--baseline d16_start` green (`"problems": []`); gate n/a (design only, no row
moved). Slice: `slices/D16-station-ui/`. **Next in the phase: coder 30 (S24
world identity), opening docs-first on the ticked names.**

**Updated 2026-10-02 (owner's auction detour — no wave, developer session):** the
owner ruled two AUCTION fixes outside the slice plan: (1) a listing's hover
inspector now carries **15 §7's stat block** after the description (FITTING's own
statics; `listing_rows` gained `prefixes`/`suffixes`), and (2) every restock draws
**ten extra stock listings** — tier-I rows, 100 % Common, never affixed, hot
eligible — through the new `auction_stock` row in `ModuleCatalog.SOURCE_ROLLS`
(10 §2.1's amendment + 15 §11; CONTRACTS §15 + §10 v0.44). Gate **1030 → 1031/0**
twice hermetic (the s3/s5 shelf-count rows moved to 20; one new inspector row).
Untracked as ever: `staging/compare/`. **The phase's next item is still designer
17 (D16) before coder 30 (S24).**

**Updated 2026-10-02 (S23 closed — content activation; the phase's next item is
designer 17 / D16):** the owner delegated the wave's open values to the developer
(brief §0's V1–V5) and added the F1 credits toggle (A8); the owner then ruled the
wave runs on **dispatched coders, not hands-on** — so it ran B1 → R1 → F1 on
`hyper/glm-5.3-flash`. B1 landed A1–A8 (both exclusive families firing under the
S22.8 cadence law, the three dead-module effects, the sibelon on the corvette
column as `HOSTILE_FILL`'s third entry, the interceptor/turret hull rows, the
per-hull V3 ladder sprites, the loot rows, the F1 CREDITS section); the developer
discharged B1's three bucket-2 disclosures (the V1 pack rows + `AMMO_MAX`, the
three stock fits on `p_core` per 09 §9's developer amendment, 03 §4's
`countermeasure` family) and R1's F3 §8 list amendment; R1 graded **A1–A8**
(2 HIGH + 1 MED, all bucket-2/disclosure class) and **S23-F1 fixed F1/F2** (the
pinned draws keyed, the staged-pack asserts flipped). Gate **1014 → 1030/0**
(×2 at every stage, fresh scratch); `verify --baseline s23_start_b1fix` green
(`"problems": []`). `validate_names --library` cannot run on this host (archives
away) — the disclosed substitute is a 20/20 wired-art loader probe. LOW
**L264–L266** (R1's ticket rows). **Next in the phase: designer 17 (D16 station
identity & contracts UI design, one live session) before coder 30 (S24).**

**Updated 2026-10-01 (S22.8 closed — the weapons-cadence split):** the
owner split the weapons before S23 and delegated the values: the spam tier
(laser/plasma/cannon) fires exactly as shipped, the heavy tier fires one shot and
cools — **railgun 15 s, rocket 12 s, mine 10 s** — with the cooldown *as* the
barrel's cadence (battery gate, held-trigger stream and `Rapid` all read it) and
the railgun's slug the derived **alpha 450**. The HUD counts the selected rack
down and dims cooling batteries; the armory SALVO drum grew a fourth cell for the
10.00–15.00 s figures (L263, owner's eye owed). Gate **1006 → 1014/0** twice
hermetic; new suite `test_s22_8_cadence.gd` (8 rows); pins in 18 §4.1's amendment
+ §13, CONTRACTS §9/§10 v0.42; the S19 seal re-pinned for `weapons.gd`. Slice:
`slices/S22.8-weapons-cadence/`. (Its "next: S23" pointer is superseded by the
block above.)

**Updated 2026-10-01 (S22.7 fix rounds closed; the queue's next item stands):** the
owner played S22.7 and ruled two feel fixes, which the developer landed hands-on (no
worker dispatch): the splash now bills by the last hit (kick 150 → **50**, an impact
factor — mining 0.35, gun chip÷rate÷50 clamped 0.3–2.0 — scaling the child roll and the
ejection vector) and every cleave leaves a **core layer** (the largest kind's first child
stays at the parent's centre on the shape's half alone; XL→L, L→M, M→S, S→pickup burst).
Gate **1006/0** twice hermetic; pins in 02 §5.5/§5.6, 18 §13, CONTRACTS §3/§9/§14/§10
v0.41; LOW **L262** (two tool probes' kick pins). **Next: the owner's weapons-cadence
overhaul (spam vs cooldown split) inserted before S23, then S23 content activation with
the F1 dev-menu credits toggle riding it (owner 2026-10-01).**

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
D15 — closed and ticked 2026-09-29); S24/S25/S26
cite D16's spec. Five-piece: `slices/D16-station-ui/`. **Parked (owner-gated, not
queued):** the S12 ore caps/scale rows (the owner's §10 ticks — do not
implement before that wave is briefed), slice 4's remainder (bosses/arena —
14 §5, blocked on P4 contracts + boss art), the §13 turn/coast column ticks
and slice 2.5's engine-bed/vignette calls, S8's owner gates (O1/O2 FITTING-drag
UX, O3, L168, L169), the chrome art half, the designer candidates (D9-11,
D10-12, D3-1, D3-2a/2b, D4-3/4, blocked 5/6 — parked in
`dispatch_designer.md`), and adopting the D13 layout language across the game
(owner-deferred).

**Updated 2026-09-29 (D15, closed + ticked): the 25-row feel tick sheet is
ruled and S22 may open docs-first** (`slices/D15-flight-feedback/D15-A1_report.md`
carries the tick record; `FX_SPEC.md` §8 + `AUDIO_SPEC.md` §8.6 append-only
amendment blocks and the A5.2 feedback composition landed with it — quadrant
feed, hit-marker strike-X, ram spark, `staging/mockup/out/d15_feedback_composition.svg`).
A1 → R1, **0 HIGH / 2 MED cured / 2 LOW (L250–L251)**; `verify --baseline
d15_start` green, gate **941/0 unmoved**. **Owner ticks 2026-09-29 (interactive
pass): every row y — except T-feel-5, ticked to its REVERSAL (arc onsets at
random 1.6–2.6 s, §6 cadence); the forks resolved as the seeker fuze pair
(`SEEKER_FUSE` 80 u + `SEEKER_FUSE_S` 6 s) and dropping `sfx_weapon_laser_04`
with a staged trim.** The developer lands the flight/§13/CONTRACTS rows in the
owning docs at S22's open. Recap `MASTER_REPORT.md` §6.

**Updated 2026-10-01 (S22.7, closed — coder item 28.7): mass is load-bearing and
rocks knock into each other — gate 990 → 1002/0 twice hermetic + the close-out's
own ×2.** The owner's "everything physics based on mass" landed as the **mass law**
(18 §3.2): the flight forces derive from the **class** mass (`ShipStats.base_mass`
+ a derived `engine_thrust`) and act against the **fitted** mass, so plating's
ponderous half is one mass channel (its `1+|penalty|` now multiplies mass instead
of the three handling times) — a hull is byte-identical at unfitted launches,
`h_composite` resolves ~9 % slower / ~10 % longer-carrying, and `mass_add` finally
slows a hull. Fuel is thrust's receipt: the boost burns §13's eight rates (fighter
2.75 … patrol 3.22, the Vanguard exactly 3.0/s) and the dash spends `25 × mass/110`;
`fuel_max` stays the flat 200 (M5 kept flat). Rocks weigh `ROCK_MASS_DENSITY × r²`
(M anchored 560 t → **S 183 / L 1 383 / XL 2 571**, **L8 closed**), collide with
each other (`COLLISION_MASK` 3, a nudge — no monitor, no damage) behind a
minimum-separation placement pass (margin 8 u, both rings, seed-reproducible), and
every split child leaves at its own random speed — a 0.7–1.3 jitter × a
√(m_M/m_child) weighting, so an S splinter leaves at ~1.75× the base kick and an L
child at ~0.64×. Two builders (B1 ships `846a39d`, B2 rocks `9fc4e6d`), review
**0 HIGH / 0 MED / 4 LOW (L258–L261)**, no fixer; the first B1 dispatch on
`opencode-go` died mid-recon (no artefacts) and the wave re-ran on
**`hyper/glm-5.3-flash`** per the owner's mid-wave route ruling. Verify green
against `s227_start_devdocs` (the pre-correction snapshot's one expected
`02_minerals.md` touch is L261's evidence). Recap `MASTER_REPORT.md` §6.

**Updated 2026-09-30 (S22.6, closed — coder item 28.6): hulls coast and broken rocks
fly — gate 983 → 990/0 twice hermetic** (`"problems": []`; `18_engine_spec.md`'s
§13 row and `CONTRACTS.md` §14 were re-worded by the developer after the snapshot
— L256's cure — and both stay outside `--forbidden` by design). The owner asked why
things stop moving in vacuum; the answer was that nothing coasts: the release is a
scripted constant brake at `max_speed / coast_time` (the body damp is compensated
out, so it is not drag), and the rock's damping was hand-derived so even the
heaviest possible ram leaves it at 10 u/s after one second. Ticked the same day:
**`COAST_TIME_MULT` 2.5 → 5.0** (the nine rows resolve 4.0–14.0 s; the shipped
Vanguard stops in **5.25 s over 1 063.94 u**, the fighter 4.2 s / ~894 u) and
**`LINEAR_DAMP` 3.71 → 0.35** with a new **`FRAGMENT_LINEAR_DAMP` 0.25** on every
cleave child and splinter (a kicked 150 u/s reads **105.6 u/s** after one second
and carries **424.65 u**, a child **595.52 u**, a ram hand-off **1 160.34 u** —
×11.2). §23.5's "one stop, one line" acceptance holds at the new rate and only the
flight-decay numerics re-derived; `test_s22_6_inertia.gd` (7 rows) is the only
growth. Recap `MASTER_REPORT.md` §6.

**Updated 2026-09-30 (S22.5, closed — coder item 28.5): rock toughness and chip
splinters ship — gate 971 → 983/0 twice hermetic** (`"problems": []`;
`docs/gameplay/02_minerals.md` deliberately outside `--forbidden` because the
developer's own `ec6207b` clarifying sentence lands after the snapshot, the LOW
R1 filed as L255 and closed the same way). The owner's ask (2026-09-30),
docs-first as **02 §5.3's A1–A5** and ticked the same day: every rock rolls its own
**0.80–1.60** toughness on the field's seeded RNG; size multiplies it as a
**gun-door divisor** (S 1.5 · M 2.5 · L 4.0 · XL 6.0) so a T1 rock takes
**S 3.61 s · M 6.00 s · L 9.61 s · XL 14.41 s** of `w_laser` at the mean roll
instead of ≈2.0 s for every class; the mining door is untouched (1.2 s/unit
pinned); oreless debris cracks on a **work budget** (S 2.0 · M 3.0 · L 4.5) rather
than the first point of damage, so one chip and a ram no longer delete it; and a
**non-cracking gun hit on an L/XL sheds a real S-class splinter** at 25 %, capped
at 1 per 0.5 s. One builder, `test_s22_5_asteroids.gd` (11 rows) + one dev-menu
Save/Load row = +12; `test_s14_splits`/`test_s16_resplits`/`test_s13_caps`/
`test_s13_mining_batteries` row-identical; Rule A's "no ore minted" holds (a fully
shot family realised 1 unit against the cap). Recap `MASTER_REPORT.md` §6.

**Updated 2026-09-30 (S22, closed — coder item 28): the feel/juice pillar ships —
gate 941 → 971/0 twice hermetic** (`"problems": []` on `--baseline s22_start`,
`--forbidden` on explicit files per L245). Opened docs-first on D15's fully-ticked
sheet: the brief's stale `914` corrected to the measured baseline, five bucket-2
doc edits landed before any code (**CONTRACTS §22's T3 row struck**, **§23.5's
release-ramp row**, **§14's NPC-brake disclosure**, **18 §13's Rocket fuze row**
on the owner's grant, `ship_fit.gd`'s retune comment corrected), **L250/L251
closed**, and the rows already shipped at their ticked values reclassified
**verify-only** rather than rebuilt (A4 mining chip `mining_laser.gd:214-225`,
A8 arcs at the ticked random 1.6–2.6 s, A13 every FX-2 pin, plus the A11/A9
disposition halves). Ran as **three sequential builders** (owner-ruled
2026-09-30): B1 the feedback seams (the `hit_landed` signal, any-hull marker,
ram cue + spark, nose muzzle, `ModuleCatalog` label), B2 the HUD quadrant feed +
the audio pass (the three §4.1 anti-flam rules, a **CC0 mine release cue** sourced
through `assetmcp`, `laser_04` dropped), B3 the flight and balance rows
(`SEEKER_FUSE` 80 u + `SEEKER_FUSE_S` 6 s, the NPC midline-drag twin, `Repairs`
on `ShipFit.resolve`, the damage-conserving proportional spill) plus the S19
byte-seal re-pin (`npc_ship.gd 12ab0ae2…`, `weapons.gd 6f95a9c2…`; the S21 rule:
the last editor re-pins). New suites `test_s22_feedback.gd` (11),
`test_s22_audio.gd` (7), `test_s22_balance.gd` (12) = **+30 rows**, the only
growth. Review: **1 HIGH (bucket 2, L252 — §8's s19 line missing R-S22-1's third
moved row; discharged by the developer at close, no F1) / 0 MED / 2 LOW (L253 the
fuze's no-distance-gate delivery, owner confirm; L254 the anti-flam docstring's
overclaim)**. **Owner ticks: all 25 of D15's rows ticked 2026-09-29** — nothing
in this wave shipped at a proposed default. Recap `MASTER_REPORT.md` §6.

Closed-wave recaps live in `.agents/gen/MASTER_REPORT.md` §6.

## Queued (phase P3 — `phases/P3-content-feel-push/`; one live session, one item per order)

| Pos | Lane item | Wave | Runs after | The collision/dependency that forces the order |
|---|---|---|---|---|
| 1 | coder 27 | S21 stability & playtest fixes (**done 2026-09-29**, 917 → 941/0) | — | — |
| 2 | designer 16 | D15 flight feel & feedback design (**done + ticked 2026-09-29** — sheet → S22) | coder 27 | one live session (L82); its tick sheet is coder 28's input |
| 3 | coder 28 | S22 feel, juice & balance (**done 2026-09-30** — 941 → 971/0; 1 HIGH bucket-2 list closed by the developer, 2 LOW L253/L254) | designer 16 | implements D15's ticks; both touch `ui/hud/` |
| 4 | coder 28.5 | S22.5 asteroid toughness (**done 2026-09-30** — 971 → 983/0; 0 HIGH / 0 MED / 1 LOW L255 closed by the developer) | coder 28 | one builder; shares `vajb-orbit/game/` with 29, so it ran strictly before it (inserted at the owner's ask, not renumbered) |
| 5 | coder 28.6 | S22.6 inertia (**done 2026-09-30** — 983 → 990/0; 0 HIGH / 0 MED / 2 LOW — L256 closed by the developer, L257 pre-existing) | coder 28.5 | one builder; shares `vajb-orbit/game/` with 29, so it ran strictly before it |
| 6 | coder 28.7 | S22.7 mass physics & rock contact (**done 2026-10-01** — 990 → 1002/0 twice hermetic + the close-out's own ×2; then the owner's two fix rounds hands-on, 1002 → **1006/0**; 0 HIGH / 0 MED / 5 LOW L258–L262; **L8 closed**; verify green against `s227_start_devdocs`) | coder 28.6 | two sequential builders (`ship_stats`/`ship_fit`/`player_ship` then `asteroid`/`asteroid_field`); inserted at the owner's ask, not renumbered; **workers on `hyper/glm-5.3-flash`** (owner ruling mid-wave: never `opencode-go`) |
| 7 | coder 29 | S23 content activation (**done 2026-10-02** — 1014 → 1030/0 ×2; 2 HIGH bucket-2 cured, 3 LOW L264–L266) | coder 28.7 | `vajb-orbit/game/` + `tests/` (weapons/projectile/mining seams) |
| 8 | designer 17 | D16 station identity & contracts UI (**done 2026-10-03** — 0 HIGH / 2 MED cured / 2 LOW L267–L268; law for 30/31/32) | coder 29 | one live session; its spec is coder 30/31/32's design law |
| 9 | designer 18 | **D18 map deck & panel consolidation design** (**live**, owner 2026-10-03; `slices/D18-map-panels/`) | designer 17 | inserted at the owner's ask ahead of 30–33; its spec is S29's law |
| 10 | coder 34 | **S28 station chrome quick-fix wave** (**done 2026-10-03** — 1031 → 1038/0 ×2 + R1 re-run; 0 HIGH / 0 MED / 2 LOW T-98/T-99) | beside D18 | disjoint file sets — the only parallel pair, owner-approved |
| 11 | coder 35 | **S29 panel consolidation + the map deck** (**done 2026-10-03** — 1038 → 1073/0 ×2 at every stage; 1 HIGH + 1 MED cured by F1, 7 LOW T-100–T-106; B1 crashed on provider credits, the resume + B2 ran xiaomi/mimo-v2.6-pro) | D18 + S28 (both done) | ran alone |
| 12 | coder 30 | S24 world identity | designer 17 (+ S29 for the rail/pane shape) | `station_catalog` + the station screen (D16 spec first) |
| 13 | coder 31 | S25 contracts board | coder 30 | `ui/station/` + `autoload/player_profile.gd` + S24's `contracts_visible` seam |
| 14 | coder 32 | S26 bosses, arenas, insurance, vaults | coder 31 | `game/` + `player_profile.gd` + S25's Expedition seam |
| 15 | coder 33 | S27 catalog breadth & shipyard | coder 32 | `game/module_catalog.gd`/`loot_tables.gd` + `ui/station/` |
| 16 | designer 19 | **D19 station shell v2 design** (**done 2026-10-03** — UI_SPEC §12 + STATION_HUB §19 + 3 wireframes + the A5.5 census; 2 HIGH + 9 MED cured by F1 under two designer rulings, 6 LOW T-107–T-112 + close-out T-113; gate 1074/0 ×2, verify green vs `d19_start`) | coder 35 (done) | inserted at the owner's ask ahead of coders 30–33; its §12/§19 detail is S30's (coder 36) law, and S30 re-lays `ui/screens/station.*` + `ui/station/` before those coder items touch the panels |
| 17 | coder 36 | **S30 station shell v2 build** (**done 2026-10-04** — 1074 → 1093/0 ×2; 3 HIGH + 7 MED cured by F1, 4 LOW T-114–T-117; B1/B2/F1 `hyper/deepseek-v4.1-flash` @ xhigh, R1 `hyper/glm-5.3-flash` @ max; verify green vs `s30_start`) | designer 19 (done) | ran alone — rail + inspector band deleted, TERMINAL drawer + OVERVIEW + popups shipped |
| 18 | coder 37 | **S31 shell fixes** — the D20 fix wave F1–F3+F5 (`UI_SPEC.md` §13.1 N42–N47) — **done 2026-10-04**: 1093 → 1099/0 ×2; acceptance 1–7 all PASS, 0 HIGH / 0 MED / 4 LOW (T-127/T-128); N42 amended post-review (a book = a list); T-118–T-121 closed, T-122 deferred to S32 | D20 (done) | re-laid `ui/station/exchange_panel.*` + `armory_panel.*` + the tooltip before S32 touches them |
| 19 | coder 38 | **S32 ARMORY two-module rework** (`STATION_HUB.md` §20.1 P32–P37) — **done 2026-10-04**: 1099 → 1110/0 ×2; acceptance 1–7 all PASS; 1 HIGH (P36 dead space) cured by F1 under the designer's bucket-2 ruling (full-width console, 13 rows re-anchored), 2 LOW T-129/T-130; T-122 closed | coder 37 (S31) | rewrote `ui/station/armory_panel.*` sequentially after S31 |
| 20 | designer 20 | **D21 the one true-aspect chrome family** (`UI_SPEC.md` §15 + `UI_CHROME_ASSETS_SPEC.md` amendment; owner ruling 2026-10-05, scope **full**; T-131) — **live this session** | beside coder 39 | `docs/design` + `staging/mockup` only — disjoint from every code wave (the D18/S28 parallel-pair shape) |
| 21 | coder 39 | **S33 shell v3 — armory two sectors + the exchange sell cluster** (`STATION_HUB.md` §21.1 P38–P41 + `UI_SPEC.md` §14.1 N48/N49; T-132) — **live this session** | beside designer 20 | `vajb-orbit/ui` + `tests` only; disjoint from D21; rewrites `armory_panel.*`/`exchange_panel.*` after S32 |
| 22 | coder 40 | **S34 the refinery queue** (`docs/gameplay/04_refinery.md` §7 + `STATION_HUB.md` §21.3 P42–P43; T-133) | coder 39 | strictly after S33 — both land rows in `vajb-orbit/tests/` and the whole-tree verify baselines must not see each other's diffs |

Designer items 16–19 and coders 34–36 are closed — the overhaul round and its
shell-v2 follow-up are **shipped** (station: TERMINAL drawer, OVERVIEW landing
pane, popup descriptions, one skeleton; gate 1093/0). **Next (live
2026-10-05): designer 20 (D21 chrome family) + coder 39 (S33 shell v3) as the
second parallel pair on disjoint file sets (the D18/S28 shape), then coder 40
(S34 refinery queue), then coder 30 (S24 world identity)** — its five-piece
predates shell v2 AND the 2026-10-05 round, so the brief re-checks against
`UI_SPEC.md` §12–§14 + `STATION_HUB.md` §19–§21 before dispatch. Playtest
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
