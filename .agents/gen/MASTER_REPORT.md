# Master report — what the workers did, and what is still wrong (2026-09-21)

> Folder-law note (2026-09-22): state files live in `.agents/gen/_state/`
> (`WAVEBOARD.md`, `LOW_BACKLOG.md`, `_wave_state/`), templates in
> `_templates/`. On 2026-09-22 the archived wave reports, briefs, evidence
> logs, dispatch scripts and the two dispatcher files were purged to the
> system trash (recoverable there) — only this report, the newest session
> report and the folder-law skeleton remain. Citations below and in `docs/`
> name the pre-purge paths; the files are recoverable from trash, not from
> git (the last tree that carried them is `3f5688b`).

One file that answers "what happened" without reading the per-wave reports.
**2026-09-21 cleanup:** per-worker report chains, task briefs, prompt files,
dispatch scripts and probe/boot/gate logs were deleted from `.agents/gen/`
(≈270 files, git-tracked so the history survives in git); kept were the
wave-level + review reports below, the LOW backlog, `ui_chrome_regression.md`
(the art-lane handover), the two dispatcher files, `previews/`,
`batch2_evidence/` and the verify baselines. **2026-09-22 purge:** the whole
keep-set was then removed too (see the folder-law note above) — the summaries
below are now the only record of what each wave delivered.

**State in one line:** engine wave 1 (fly-and-mine), engine slice 0 (Physics &
Fuel) and engine slice 2 (Fight) are all **CLOSED and review-verified clean**;
batch-2, the two doc lanes and the Phase G graphics lane closed beside them;
the universal gate reads **219 tests, 0 failures, exit 0**; the last commit
`c24ed3f` closes slice 2. Nothing is in flight.

---

## 1. What the workers did

### Engine wave 1 — fly-and-mine (closed, review-verified)

| Workers | Did | Evidence |
|---|---|---|
| W0–W5 | doc amendments, flight fit, mining, sector population, HUD | `engine_wave1_w0..w5_report.md` |
| W6/W8 | review + re-review: 8/8 fixes verified, 40/40 probe checks, boot gates exit 0 | `engine_wave1_review_report.md`, `engine_wave1_review2_report.md` |
| W7 | fixes H1–H4, M1–M3 | `engine_wave1_w7_report.md` |

Git baseline `2a420a7` pushed to `origin/main`.

### Engine slice 0 — Physics & Fuel (closed 2026-09-21; gate 78/0)

Workers M0→M6, orchestrator-owned interventions for owner rulings and the input map.

- **Delivered:** the hull on a real `RigidBody2D` (forces/torque, contact damage,
  recoil, knockback, `I(d)` shockwave — new `game/impact.gd`); the energy/fuel
  reactor chain (10 E → 1 F, boost 3.0 fuel/s, fuel-cell on **R**); asteroid
  cleaving (L→2–3 M→2 S→1–2 pickups, fragments are field members, rocks now
  560 t bodies); free instant refuel/recharge at stations; **save schema v3**;
  HUD energy/fuel bars + EMERGENCY FLIGHT banner. +25 tests.
- **Review (M4) found 1 HIGH + 6 MED; M5 fixed; M6 re-verified all clean.**
  The HIGH was a stale save-v2 assertion; the MEDs were the reactor chain's
  *unwired seams* (thrust not gated on empty fuel, afterburner burning nothing,
  `PlayerState.tick` and `consume_fuel_cell` unreachable) — M1/M2/M3 each
  implemented their slice correctly and each left the seam between them dead.
- Owner rulings R1–R4 (`slice0_owner_rulings.md`): refuel/recharge FREE (the
  §13 CR rate does not exist); asset-tree failures environment-deferred;
  `consume_fuel_cell` = R (C stays `cargo_toggle`); owner strikes the
  superseded "fuel for CR" wording in their own spec pass.
- Wave report: `slice0_report.md`; chain `slice0_m0..m6_report.md`.

### Engine slice 2 — Fight (closed 2026-09-21; gate 219/0)

Workers W0→W9, plus one closing fixer.

- **Delivered:** `WeaponComponent` (six families, lock seam, countermeasures,
  guns-on-rocks, recoil), `Projectile` (ballistic + 2.2 rad/s homing, mine
  arm/trigger, flare retarget, knockback + blast), `Damage` pipeline (§4.2
  item-5 context/bearing, shield rule, `REGEN_QUIET`), NPC registry (9
  archetypes + sector bands) / brain (one state set, leash, AGGRO_COOLDOWN) /
  ship (RigidBody2D on the player's physics law, `died`), loot tables (4 tables,
  EV drift ≤ 0.65 % over 20 000 seeded rolls), HUD lock ring + radial
  speedometer + hit marker + ghost blips, countermeasures Z/X, death → respawn
  docked. +139 tests (six new suites).
- **Review (W6) found 1 HIGH + 10 MED; W7 fixed F1/F2/F4, W9 fixed R1, W8
  re-verified all clean.** The HIGH: *no weapon damaged a real ship* — both
  delivery sites handed hits to a bare `HullBody` with no damage-sink
  resolution; fixed by `_sink_for` (measured: laser 800 → 770 = exactly 30).
  W8 caught the F2 fix *turning on* a latent double ammo charge (R1, 297 → 294);
  W9's one-line seed update closed it with a negative control (297 → 297).
- Owner rulings R5–R8 (`slice2_owner_rulings.md`): chaff = **Z**, flare = **X**;
  mine alpha 180 / kinetic cadence 0.6 s accepted as their own spec rows owed;
  chrome re-cut routed to the art lane; backdrops target 4K (2× cuts owed).
- Wave report: `slice2_report.md`; chain `slice2_{w0,w0b,w1..w9}_report.md`,
  review `slice2_review_report.md` + `slice2_w8_report.md`.

### Batch-2 playtest lane (closed)

- **B2-3 minimap zoom inversion was a real code defect** — fixed in
  `ui/hud/hud.gd` (deltas renamed to the direction they mean, bindings swapped;
  measured `%ZoomPlus` → radius 3200→2400).
- **B2-1 (hover look) and B2-2 (soft backdrops) are art-side, not code** — the
  2026-09-21 00:17 chrome re-cut replaced whole sheet cells where the theme and
  scenes still carry the 2026-09-18 geometry (§2 below). Measured, recipe
  written, routed to the graphics lane. Reports `batch2_report.md`,
  `batch2_docs_report.md`, handover `ui_chrome_regression.md`.

### Doc lanes (closed)

- `slice2_lootdocs_report.md`: landed the reviewer-measured 06 figures
  (2.15 / 28.375 / 11.83 %, 2.30, 1.50, 6.375, floor 1025 CR, mean 1584.75) and
  the `11 §3` → `18 §13` pointer (F9, F11).
- `batch2_docs_report.md`: `19_testing_notes.md` B2-3 ticked, B2-1/B2-2
  annotated; the `IMPLEMENTATION_PLAN.md` §9.8 follow-up line.

### Graphics lane — Phase G (closed for this run; `designer_phase_g_report.md`)

- **65 files shipped and imported:** alien hull sheets (Swarmer — unblocks
  slice-2 W3's visual pass, Sibelon, Apex), the **human roster reworked — 14
  hulls** (core five owner-approved "look good, go ahead", plus
  `ASSET_EXPANSION_SPEC.md` §3 classes 7–15), and 7 Phase G FX.
- `fx_shield_shatter` retired by owner ruling (`fx_shield_break` covers it).
- **Pipeline lessons now law** (`staging/phase_g/`): panel order is render →
  find objects → cut each → key each → trim (panel-level keying ate a hull,
  the 2×2 grid clipped two); a 2×2 sheet's fourth cell is often a second front,
  not a rear (silhouette IoU vs front > 0.80 = refuse; `refit_panels.py`
  enforces); `cells` in `wave_g.py` is the authority, `cuts` derived.
- **Still on the old art:** MMO/faction liveries (`ship_*_mmo`, `_concord`,
  `_meridian`, `_choir`), the six boss hulls, `ship_vanguard_damaged` — i2i
  re-liveries that wait on the owner's naming overhaul.
- The assets re-layout also **healed slice 0's environment fallout**:
  `asset_path_fallout.md` now reports **181 asset literals, 0 unresolvable**;
  the Small-rock pickup burst measures green again (`ok=25 failed=0`, spawn
  half; full spawn→collect chain still unproven).

---

## 2. Known errors and live defects (measured, not fixed)

The authoritative defect list is `ui_chrome_regression.md` (art) and
`LOW_BACKLOG.md` (L1–L29, code/spec/harness). Headlines:

### Art / chrome (routed to the graphics lane, rulings R7/R8)

| Defect | Measured |
|---|---|
| Button plates | 1041×1087 cell stretched into a 350×70 plate → renders **287.1 × 8.6 px, 90 % transparent** |
| Menu wordmark | crop `AtlasTexture Rect2(44,707,1961,615)` holds **0 ink pixels** of the new 2170×823 art |
| Minimap bezel | nine-patch frame band draws **3.0 px** instead of 16 |
| Bar caps, slot families, panel frame | same cell-vs-box class of defect |
| Backdrops | every `@2x` cut deleted → 1.25× upscale at 1440p, 1.875× at 4K |
| Tint stencils | 1 080 files lost the F.1/F.2 import settings (`mipmaps/generate=false`) |
| HUD zoom buttons | 3.43 texels/px minification; `_48` cuts are the fix |

**Owner gates still open:** B2-1 hover direction (flicker / directional glow /
ember) needs the owner's pick from a standalone 1080p + 1440p look; B2-2's
display target decided (4K, R8). Nine-slice margins cannot fix this art; the
fix is a tight re-cut + re-pull + re-import.

### Code/spec/harness (backlog, none blocking)

- **Mining laser's 5 E/s beam drain has no code owner** (L11/L26 — still open
  after two waves; route in the next wave owning `mining_laser.gd` or
  `player_ship.gd`).
- **Ships do not pair with ships** (L22): hull layer 2 / mask 1 — ship-vs-ship
  rams are nobody's job; needs a ram authority (design decision, slice 4).
- **Wreck window doesn't survive a scene transition** (L23) and the **hull
  flies for frames between death and respawn** (L24) — both slice 4.
- **Q cycles marks, not locks** (L27 — self-consistent reading, owner's call);
  **hit-marker only fires for the marked target** (L28 — needs a
  `hit_landed` signal on the components).
- **`hud.tscn` byte-identical**, widgets built in code (L19 — W6 ruled
  acceptable; revisit with the next HUD/theme pass); **`HULL_SCALE` has three
  homes** (L20); **NPC flight maths duplicated** from `player_ship.gd` (L21 —
  values single-owner, code shape is not).
- **The station boot gate writes the dev profile** (L18: normalises the market
  band on panel open); `test_engine2_pools.gd` also triggers a normalisation
  write of `user://profile.cfg` (attributed in `slice2_w7_profile_hygiene.md`;
  content normalisation, no data loss). Fix shape: normalise at dock.
- **Stale `ext_resource` UIDs** in `player_ship.tscn` / `game.tscn` warn on
  every load (L29 — clears when the editor next re-saves the scenes).
- **Unpinned values** behind the "report, never guess" rule: mine alpha 180 and
  kinetic cadence 0.6 s (R6, accepted), `HIT_RADIUS` 4.0, `SHOT_MASS` 1.0, and
  a seeker has no fuse radius (min turn radius 409 u → a beam lock inside that
  distance is orbited, not struck — owner blesses orbiting or adds a row).
- **Spec self-contradictions** for the next spec pass: §6's fragment tier vs
  §13's mineral+tier/yield (ruled: §13 + §12 item 12 win); the §13 rock mass is
  an inference (4 × `ship_miner` 140 t); 09/11/14 column-form items (L1–L5).

---

## 3. Open items, ranked

1. **Owner (spec is owner-locked, nobody else may touch it)** — one
   `18_engine_spec.md` pass covering: strike the superseded refuel-for-CR
   wording (§2.1 ruling 13, §4.4, §12 item 8); §11 `consume_fuel_cell` C → **R**
   + the missing `countermeasure_chaff`/`countermeasure_flare` rows (Z/X); the
   §13 speed-table-v2 △ tick; the mine-alpha-180 / kinetic-cadence-0.6s rows
   (R6); the §6 fragment wording; a §13 rock-mass row; bless-or-fix the seeker
   orbit (L25) and the Q-marks reading (L27).
2. **Graphics lane** — the chrome re-cut (R7) + 4K 2× backdrop cuts (R8) + tint
   import settings + `_48` zoom buttons; B2-1 owner approval gate; F10's credit
   cache salvage glyph.
3. **Spec/economy, none blocking** — F3's three-owner delivery-seam refactor,
   F7's six doc holes (human/alien split, patrol count, alien/turret rows, NPC
   armament, stand-off, turret scan radius), F8's `cm_*` rows in `03`,
   the REPAIRS panel's free-service rows, HUD pool blocks into `hud.tscn`.
4. **Next engine wave — slice 2.5 (Feel) is READY**: motion blur + camera
   pull-back + dust streaks (§3.4), damage smoke/ripple/shatter (FX_SPEC §6),
   dash charge FX (FX_SPEC §7). No new gameplay systems; every number already
   in §13; all signals it needs exist (`velocity()`, `set_speedometer`, the
   damage pipeline, `hit_marker`, `set_lock_progress`). Snapshot + commit
   before its first dispatch.
5. **Backlog code items** (§2 list above) ride with whichever wave next owns
   the file; the probe-hygiene rule (L17) goes into the next brief.

## 4. Housekeeping facts

- **2026-09-21 cleanup executed:** `.agents/gen/` shrank from ~300 evidence
  files to the keep-set described in the header (≈270 deletions, staged in
  git at the next commit; history survives in git). `docs/` citations to the
  deleted chains were repointed to this file.
- Evidence chain per wave: the surviving wave-level + review reports listed in
  §1; baselines in `.agents/gen/_state/_wave_state/` (`wave1_closed`, `slice0_start`,
  `slice2_start`).
- The test gate grew 53 → 78 (slice 0) → 219 (slice 2). Current contract:
  `res://tests/headless_runner.tscn` → `[SUMMARY] passed=219 failed=0`.

---

## 5. Update 2026-09-24 — items 8–13, designer 7–8, the independent QA pass (supersedes the "State in one line" and §3/§4 above)

**State in one line:** thirteen coder waves + the designer cockpit waves are
CLOSED and review-verified; the universal gate reads **`passed=753 failed=0`**
(measured twice on scratch stores by the developer session, `problems: []` on
`verify --baseline s7_start`); nothing is in flight; coder **item 14 = S8 QA
fixes is READY** (CONTRACTS §21); the designer queue carries the QA's items
9–12. The detailed record for this period is
`.agents/gen/session_2026-09-24_items_8_to_13_report.md` plus `WAVEBOARD.md`
§Closed (per-wave numbers, reviews, incidents, ticks).

Compact record: **8 S2.6** 437→457 (owner requests #5–#7: outward kick 150.0,
scatter disc, `BEAM_SINK` 0.45); **9 S3** 457→493 (instances + AUCTION, §15;
one live-`user://` probe incident, T-93 class, restored); **10 S4** 493→524
(batteries, §16 v0.8.0; 1 HIGH + 1 MED cured, the HIGH re-reproduced at
close-out); **11 S5** 524→578 (the owner's ten playtest findings, §17; 2 MED
cured); **12 S6** 608→674 (travel, §19; K0's 21 pre-build contradictions; 0/0/8);
**13 S7** 711→753 (affix application, §20; K0's 17 pre-build contradictions;
0/0/5 L163–L167); **D6** 578→608 (cockpit instruments, §18; 18 masters) and
**D7** 674→727 (cockpit rework + battery window; 1 HIGH + 1 MED cured;
`CockpitStyle`, Mockup v7/A/C). Lows of the period: L107–L167.

**The independent QA playtest** (2026-09-24,
`.agents/gen/slices/S7-affix-application/S7_QA_playtest_review_2026-09-24.md`)
drove the next batch: 2 HIGH / 6 MED + copy/composition findings, triaged into
coder item 14 (S8, CONTRACTS §21 + 05 §9) and designer queue items 9–12; two
owner ticks (refinery hide-behaviour, `REFINE ALL` — the latter is docs-pinned)
plus its live-`user://` write disclosure. **Cleanup 2026-09-24:** every closed
slice holds `SLICE.md` + `_archive/` (briefs/prompts/reports/reviews/logs
moved, git-tracked; the 2026-09-22 purge record in this file's header still
applies to the older chains); next free LOW **L168**, ticket **T-94**,
changelog **v0.19** at S8's close-out.

## 6. Wave closure history (moved out of WAVEBOARD.md 2026-09-24)

Verbatim from the board when the closed waves' detail was moved here, so the
board stays small enough to read at the start of every orchestrator session.
Nothing below is live state.

### D7 (designer item 8) — **DONE 2026-09-24 — gate 727/0, detail §Closed** (the
notes below are the dispatch record; owner feedback on D6): docs-first landed (UI_SPEC §3.6 heading-tick retirement
+ §3.7 rework + §3.9 instrument language + §3.10 battery window, UI_CHROME §12,
ASSET_NAMING §12, STATION_HUB §5.11); brief + prompts in
`slices/D7-cockpit-rework/`; write set `ui/hud/**`, `ui/station/**`,
`assets/ui/**`, `assets/icons/**` provenance, `staging/**`, `asset-library/**`,
`tests/test_d7_*.gd` + the §3.6 heading-tick rows + `test_d6_cluster.gd`'s
compass rows — **disjoint from S7's** (prepared below); run order A0 → owner
sheet approval → A0b → C1 → C2 → R1 → F1 only on HIGH/MED. Handoff block in
`dispatch_designer.md`. **Cross-lane gate reading (developer session, 2026-09-24
mid-C-wave):** a gate run on the live tree reads `668/6` — total 674 as at S6's
close, and **all six failures are D7's held files** (one compile break,
`ui/hud/hud.gd:694 _build_cockpit`, failing 5 `test_d6_cluster.gd` rows + 1
`test_engine2_hud.gd` §3.6 row). Attribute, never fix; S7's brief carries the rule.

### S7 (coder item 13) — **DONE 2026-09-24 — gate 711 → 753/0, detail §Closed.** The
prepared five-piece was landed docs-first (CONTRACTS **§20** + changelog **v0.15**, 15 §10,
09 §5's dated note; slice at `slices/S7-affix-application/`, brief + prompts with
K0 → K1 → K2 → K3 → R1 → F1; queued in `dispatch_coder.md` item 13); S3 tick 6 ("schedule
or park") was answered by the owner's 2026-09-24 dispatch instruction (reversal: park). Write
set (`game/**`, `autoload/player_profile.gd`, `tests/test_s7_*`) was disjoint from D7's —
parallel-legal (the S5∥D6 precedent); the two close-outs sequenced on the shared CONTRACTS
§9/§10, D7 writing v0.16 first and S7 v0.17 on top.

**Coder item 12 = S6 Travel (engine slice 3 + RPG P3): DONE 2026-09-24 — gate
608 → 674/0, detail §Closed.** **Designer item 7 = D6 cockpit instruments: DONE
2026-09-24 — gate 578 → 608/0, detail §Closed.** **Coder item 11 (S5) closed
2026-09-24** (§Closed). The next coder item is **slice 4's remainder** (quadrants/directional
armour and bosses/arena hooks), **not yet briefed**. The
graphics lane's open
items live in the table of `dispatch_designer.md` (D3-1 chrome re-cut —
owner-gated, D3-2a painted rail icons, D3-2b tint rework, D4-3 backdrops, D4-4
hover — owner pick); **D2 is DONE 2026-09-22** (detail §Closed; its job block is
archived at `slices/D2-icon-unification/_archive/D2_dispatch_block.md`).
Owner ticks open: the
`18_engine_spec.md` §6/§13/§15 cleaving amendment (owner-locked — the wave shipped,
the spec text lags; it now also covers `FRAGMENT_OUTWARD_KICK` and the two
  flight multipliers `ACCEL_TIME_MULT`/`COAST_TIME_MULT`), the §13 turn/`coast_time`
column ticks, slice 2.5's two calls (engine bed, vignette strength), L83's icon-size pick,
**S3's nine** and **S2.6's four** (both in §Closed; S2.6's new one is the
`STEER_WITHOUT_THROTTLE` supersession), **S6's fourteen** (fee composition,
corridor rules, derelict scan range, rift drain, bounty surface, hunter hull map
+ the 900 u aggro, station turret, hunter extra table, data-core credits, gate
placement, POI reward content, heat/hunter copy + the 600 u spawn radius, the
quadrant/sibelon deferrals — see §Closed), **S5's three** still owed
(`ROUNDS_PER_CARGO_UNIT` 10, fire-along-facing vs hold-until-aligned, the
`track_dps` taste table), **S7's nine** (all measured at close-out — the brief's list:
S3 tick 6 as answered, Overflowing, Silence, Vault, the faction trio, `damage_mult`'s
live reading incl. rocks **and the ram**, Keen per barrel, Lightened's sign-flip, Ledger
×1.25; see §Closed, LOW rows L163–L167), **D6's five + its MED-2 geometry call** (D6 reported
2026-09-24 — see §Closed; the MED-2 call is the 396×190-content vs 340×152-interior pin), and
**D7's three escalations** (D7-R1, added by the developer session 2026-09-24 at review: the
battery lamp band is **5** while the armory rack map reaches **7** — racks 6/7 light no lamp,
per §3.7's five-lamp pin, owner call; the status plate covers its well union at **99.73 %**,
2 logical px short at the box's bottom — A1's reported note; and the armory's
`OWNED ×n` / `HELD-MAX` copy rows if the owner wants wording changes).
P2-A/P2-B1/P2-B
proper tick lists are resolved.

**Owner requests queued 2026-09-22 — all seven landed** (record kept verbatim;
1–4 in P2-B proper, 5–7 in S2.6):

1. ~~Shipyard — hovering a module shows what it is and how many the player owns.~~ **DONE** in
   P2-B proper (the hover line, `shipyard_panel.gd`).
2. ~~OUTFITTING — an inventory of every item the player owns.~~ **DONE** in P2-B proper (the
   FITTING pane's OWNED MODULES section).
3. ~~OUTFITTING — the same ship module/slot-grid layout the shipyard shows.~~ **DONE** in
   P2-B proper (FITTING's SLOT LAYOUT reuses the shipyard's own plate recipe, cell for cell).
4. ~~LAUNCH / REPAIRS — a REFUEL button beside the existing service actions.~~ **DONE** in
   P2-B proper (REFUEL and RECHARGE rows in LAUNCH, `Repairs.refuel`/`recharge`).
5. ~~Rock cleave follow-up — after a rock breaks, its fragments should move a bit
   outward from the centre (radial motion on top of today's 360° spread).~~ **DONE**
   in S2.6 (`FRAGMENT_OUTWARD_KICK` 150.0).
6. ~~Weapon FX — a beam's hit should spawn its impact FX somewhat randomly across
   the struck surface instead of at one fixed point.~~ **DONE** in S2.6 (the
   `clamp(0.35 × radius, 8, 48)` u scatter disc).
7. ~~Weapon FX — a laser beam should connect to more of the middle of the object
   (its termination point, for the beam itself, not only the hit FX of #6).~~ **DONE**
   in S2.6 (`BEAM_SINK` 0.45).

### Closed (details in MASTER_REPORT.md)

- **S7 affix application (engine slice 4's affix half, 15 §9.3) — DONE 2026-09-24**
  (gate 711 → **753, 0 failed**, exit 0; the orchestrator measured it twice on two scratch
  stores at close-out plus once inside `verify_wave.py`, R1 twice plus once inside the
  verifier — identical counts, `problems: []`, **no forbidden hit at all**; the live account
  pair was byte-identical across a full gate run —
  `profile.cfg` `908418c1204abc6df6c76418d77ec8e8`, `economy_log.txt`
  `05377d9791ed8c281052571d9e8b1920`, with the pair's own movement over the session
  attributed to the editor's running game, never to S7, whose every run used a scratch
  `XDG_DATA_HOME`; reports `.agents/gen/slices/S7-affix-application/S7-K{0,1,2,3}_report.md`,
  `S7-R1_review.md`, close-out logs in that folder's `_closeout/`; model
  `opencode-go/deepseek-v4.1-flash` per the owner's order): **the affixes S3 stored now fly
  — the ship's resolved stats, each barrel, the damage delivery and five suffix seams.**
  **K0's drift pass found 17 contradictions before a builder ran** (the summary shape could
  not express its own per-instance law; the projectile delivery was a second sink seam in a
  file no worker owned; the Ledger term as pinned paid nobody; the ram was an unnamed
  fourth path) and they landed as dated dispositions in CONTRACTS §20, the brief, the
  prompts and 17 §2 — including `game/projectile.gd` joining K2's file set and the one
  existing assertion the Ledger term flips (`test_s3_instances.gd`'s fixture) being
  ratified as an edit. **Builders:** K1 summary + resolve + 15 tests (**726/0**), K2 launch
  + barrels + `damage_mult` + Embers + 19 (**746/0**), K3 Leeches/Cartograph/Ledger + 7
  (**753/0**); each builder's judgment calls were dispositioned in §20's K1/K2/K3 blocks.
  **Review: 0 HIGH, 0 MED, 5 LOW** (L163–L167: five new `position`-shadowing warnings in
  `weapons.gd`, `EMBERS_FRACTION` spelled twice, the auction pane's stale 60 % copy, one
  integer-division warning, and the id/changelog rebase note — D7's close had taken
  L158–L162 and v0.16) — no fixer pass was owed. Measured highlights R1 re-derived:
  Sturdy's counter-example 1370 not 1450; every clamp (speed floor 180.0, pools 2700, hull
  6600, engine 1.40); `{}` byte-identical across nine hulls and against a `faa24ad`
  worktree; Keen isolated per barrel (27.0 / 31.05) and `damage_mult` once at all five
  sites (35.7075, not the cube); Frugal `floor(20 × 0.85) = 17`; Spry 8.0 → 6.8; Ledger
  540 → 675 at all three production sites; the staged five byte-identical no-ops. Owner
  ticks: the brief's nine (S3 tick 6 as answered, Overflowing, Silence, Vault, the faction
  trio, `damage_mult`'s live reading incl. rocks and the ram, Keen per barrel, Lightened's
  sign-flip, Ledger ×1.25).
  **Post-close, the independent QA playtest (2026-09-24, godot-ai driven, recorded at
  `slices/S7-affix-application/S7_QA_playtest_review_2026-09-24.md`):** ran the whole
  route on a HEAD-equivalent tree at 753/0 and found **2 HIGH** (launch ammo seeds 0 —
  briefing vs flight vs HUD disagree; ship-status cells disagree with FITTING — duplicated
  weapon, armour in a W row), **6 MED** (rock-ram physics-flush refusals 16–24/ram; raw
  `MINERAL_CHROMIUM` ids in sale copy; an un-honored confirm quote 8 → 5; current > max in
  two panes; the off-brand close-X; the 3 s arm window), a copy/naming/hygiene LOW list and
  a composition/vision section — plus its tooling appendix disclosing that **its playtest
  wrote the live `user://` profile** (owner note: restore wanted?). Triage: H1/H2/M4/M1/M2
  measured HEAD-equivalent (the QA's tree ≡ `1a1f57a`, ship commit added no code) → coder
  **item 14 = S8** (CONTRACTS §21); composition/visibility items → designer queue **9–12**;
  refinery-hide and `REFINE ALL` → owner ticks (the latter is docs-pinned in 04 §5 +
  STATION_HUB §12.3). **The owner's same-day follow-up added six verbatim findings
  (§21's O1–O6 table):** FITTING drag + weapon groups (measured: FITTING has zero drag
  code; the ARMORY racks + `set_battery_groups` are the only route → O1/O2 into S8-Q0
  with the UX call routed to the owner), ram strength (→ S8, measured factor + tick),
  torque/slow-down + strafe/inertia (→ **coder item 15, owner-gated flight-feel pass**),
  and the station scene rework (→ **designer item 13**, mockup-gated).

- **S6 travel (engine slice 3 + RPG P3) — DONE 2026-09-24** (gate 608 → **674, 0 failed**,
  exit 0; the orchestrator measured it twice on two scratch stores at close-out and R1 four
  times on four, identical counts; the live account byte-stable across every run —
  `profile.cfg` `06f5660a4f884c5d799311287721f78f`, `economy_log.txt`
  `ca40fe2c0ab3bd0f2047723a2d737d9a`; reports
  `.agents/gen/slices/S6-travel/S6-K{0,1,2,3}_report.md`, `S6-R1_review.md`; model
  `opencode-go/deepseek-v4.1-flash` per the owner's order): **gates, corridors, POIs,
  scanner, sector transitions, heat, hunters and loot, playable end to end.** K0's drift
  pass found 21 contradictions before a builder ran; the owner ratified three scope calls
  (quadrants deferred to slice 4, the `sibelon` superseded by 11 §3.2's three anomaly kinds,
  K3's set grown to ship the LAUNCH bounty row) and the rest landed as dated dispositions in
  CONTRACTS §19 (the fee's worked row is **750**, not the additive reversal's 562; the band
  roll is additive `roll_band`/`roll_hunter_extra` so the shipped test-pinned `roll()` keeps
  its shape; the kill/transition seams are named as they exist; decay gets a real play-time
  accumulator; heat clamps 0–100; the two refusal axes split by doc; `heat.gd` dropped).
  **Builders:** K1 travel core + 18 tests (`626/0`), K2 POIs + loot + 25 (`651/0`), K3 heat +
  hunters + bounty + 23 (`674/0`); the wave's only existing test edit is
  `test_engine2_wiring.gd`'s minimap-feed row (derived from `gates()`/`beacons()`), ratified
  in the pin. **Review: 0 HIGH, 0 MED, 8 LOW** (L150–L157: scene-scoped decay, the rift's
  module granted to the bag, the uninterruptible paid jump, no short-funds readout, a stale
  `_transit_destination`, the gate's inert layer-1 `Area2D`, two doc/citation drifts fixed at
  close-out, the `s6_start` cross-lane note) — no fixer pass was owed. Owner ticks: the
  brief's fourteen (fee composition, corridor rules, derelict scan range, rift drain, bounty
  surface, hunter hull map + 900 u aggro, station turret, hunter extra table, data-core
  credits, gate placement, POI reward content, heat/hunter copy + 600 u spawn radius, the two
  deferrals).

- **D6 cockpit instruments — DONE 2026-09-24** (gate 578 → **608, 0 failed**, exit 0,
  measured twice on two scratch stores at close-out, live `profile.cfg` md5s unmoved;
  reports `.agents/gen/slices/D6-cockpit-instruments/D6-M0_report.md` (phases a+b),
  `D6-M1_report.md`, `D6-M1b_report.md`, `D6-M2_report.md`, `D6-R1_review.md`,
  `D6-F1_report.md`): the owner's NMS-style cockpit ask. **18 art masters** shipped
  (10 render cuts + 8 authored-SVG fallbacks — needle, glass, all 12 digit cells; 9 × 2K +
  16 keys ≈ $0.53 against the $0.20 budget; review sheet `staging/phase_g/_review/d6_masters.png`
  owner-approved), the bottom-left **404×216** cluster (§3.6 dial byte-identical with the
  face/needle sprites under the code-drawn marks, rotating compass, five 4-cell readout rows)
  and the **720×520** `ship_status` modal (toggle behind `InputMap.has_action`; the key **U**
  row applied to `project.godot` at close-out, the `weapon_6`/`weapon_7` precedent). The
  owner's mid-wave 4-digit SPD ruling is landed (SPD 4 cells clamp 9999 — UI_SPEC §3.7 and
  the CONTRACTS §18 mirror amended with dated reversal notes). Review: **0 HIGH, 2 MED,
  9 LOW** (L141–L149; L142 retired by F1's cure). R1-MED-1 (the 11 hardpoint markers drew
  133.67/64.57 px off the hull — render-box vs marker-space mismatch) cured by F1 with the
  drawn-rect test guard; **R1-MED-2 is bucket 2 — pinned 396×190 content vs pinned 340×152
  frame interior (the 340×184 compact reversal cannot hold the bays at all) — owner's call.**
  Digit QC (AC5): containment 1.0000 on all 12 cells, `blank` 0.0000 < `1` 0.1329 < `8`
  0.3671, no by-segment inversions; the literal 1…8 monotone is geometrically impossible
  (L145's §11 wording candidate). Cross-lane note for S6's review: later gate runs on the
  tree while S6's builders hold uncommitted `game/` edits read 607/1 / one hard fail at the
  pre-existing L61 leak lines (`test_weapon_fx_f4.gd:178`, `test_slice2_5_feel.gd:203` —
  `player_ship.gd:1378` also fails to parse mid-edit), none of it in D6's write set.
  Owner ticks owed: the brief's five (NMS palette/teal, placement + size, HULL/SHLD points
  vs %, key U, the per-module damage model) plus the MED-2 geometry call.
- **D7 cockpit rework + battery window — DONE 2026-09-24** (gate 674 → **727,
  0 failed** on the D7 write set, twice on scratch stores; reports
  `slices/D7-cockpit-rework/D7-A0_report.md` (A0+A1+A1b+A2 sections),
  `D7-C1_report.md`, `D7-C2_report.md`, `D7-C3_report.md`, `D7-C4_report.md`,
  `D7-R1_review.md`, `D7-F1_report.md`, plus the owner-approved
  `D7_DESIGN_REPORT.md` and the mockups under `staging/mockup/out/`): the
  owner-mockup-loop product — cluster v7 (compass ditched for two FUEL/ENRG
  dials, full-height readout well, `B1..B5` lamps, SPD/HULL/SHLD/AMMO rows),
  the Mockup A armory console (SALVO centiseconds), the Mockup C status modal,
  the old HUD column + the §3.1b pool bars retired, and **CockpitStyle**
  (palette/layout/assets + `cockpit_style_user.tres` override — user-modifiable
  per the owner's rule). 23 art masters incl. the glyph-only `ui_seg_*` family
  (AC5 containment 1.0000 ×12). Review: 1 HIGH (the status render-box clamp +
  its blind test) and 1 MED (the armory console aspect — UI_SPEC §3.10
  Amendment 2 ruled it, closed as measured), both cured; 5 LOW **L158–L162**.
  Art spend ≈ $1.85 real (A0 $0.50 + A1 $0.47 + A2 $0.45 + keys). Open owner
  ticks: the D6 carry-overs (NMS teal, HULL/SHLD %, key U, per-module damage)
  + the §12 aspect-rule wording (A2's Deviation 6, measured twice).

- **S5 playtest fixes — DONE 2026-09-24** (gate 524 → **578, 0 failed**, exit 0 in two
  consecutive hermetic runs plus the close-out verify's own gate pass, identical counts, the
  live account byte-identical across every run — `profile.cfg`
  `539de5b7af59c77b6bffc477413161da`; reports
  `.agents/gen/slices/S5-playtest-fixes/S5-J{0,1,2,3,4}_report.md`, `S5-R1_review.md`,
  `S5-F1_report.md`): **the owner's ten playtest findings.** The J0 docs pass found ten
  contradictions and measured that three required edits sat outside every worker set; the
  owner ruled (railgun own pack **150/360/150**, ammo rows stay in the **ARMORY**, no shipyard
  class icon, label `ARMORY`), and the docs were amended first (CONTRACTS §17 dispositions +
  §16's pointer, STATION_HUB §5.2/§5.11, 09 §8) with three dispatch sets grown (J2 +=
  `exchange.gd`/`component_catalog.gd`/`station_catalog.gd`; J3 += `station.gd`/`game.gd`/
  `hud.gd`; J4 += 09 §11). The worker file-set hook was repaired en route (L92a's recorded
  cure: absolute Linux paths now normalise against the workspace — until then every worker
  `write` was denied). Built: **J1** the AUCTION's ten family tabs as display grouping (the
  S3 draw's arithmetic byte-identical across the 10-tab tour) + the SHIPYARD as hangar
  (owned-only, select-writes-nothing, `SET ACTIVE` the sole commit); **J2** ammo as cargo
  (six `ammo_*` items, units = rounds/10, launch auto-load once per family, EXCHANGE buys at
  60 % of the per-unit list, fuel-cell delist asserted); **J3** `ARMORY` + drag-and-drop mixed
  batteries (`GROUPS_MAX` 7 with its three consumers, the v7 `batteries` record and the
  in-memory v6→v7 migration, the slowest-cycle salvo gate, and an S4 latent dropped-shot bug
  fixed); **J4** `ShipFit.HARDPOINTS` (nine hulls measured off the renders — 4 thruster rows
  + 29 mounts), FX anchors, per-barrel `track_dps` tracking and the 5° beam cone. Review:
  **no HIGH, 2 MED** (the HUD readout indexed a rack ordinal into the per-barrel array; one
  suite's HUD half silently never ran) — both fixed by F1, gate 578/0. Owner ticks consumed:
  the `ARMORY` label, the railgun numbers, the shipyard icon dropped. Still owed:
  `ROUNDS_PER_CARGO_UNIT` 10, fire-along-facing vs hold-until-aligned, the `track_dps` taste
  table (09 §3.1), the standing debt. LOW rows `L130`–`L140`. The D6 designer lane ran in
  parallel with a disjoint file set.
- **S4 weapon batteries — DONE 2026-09-23** (gate 493 → **524, 0 failed**, exit 0 in two
  consecutive hermetic runs at close-out, identical counts, the live account byte-identical
  before and after every run and every probe — `profile.cfg`
  `3e6ee8d7e7145c4e37bbd8dc90f62f9b`, `economy_log.txt`
  `eef2929404d1b3b2a4f30565e7b183b2`; reports
  `.agents/gen/slices/S4-weapon-batteries/S4-H{0,1,2,4}_report.md` + `S4-H3_review.md`):
  **grouped weapon systems in OUTFITTING, fired as batteries.** The wave opened with a docs
  drift check that found the pin **could not be built as written** (4 HIGH — `fitted()` called
  "unchanged, per barrel" while `set_fitted` drops duplicates and `tick` fires one weapon;
  `battery()` asked for W-cell indices from a seam handed a flat id list with no cell indices;
  "the ammo slot each barrel already owns" when ammo is one pack per **family**; and
  STATION_HUB §5.1 — the strip's actual owner — never amended for batteries; 5 MED on the
  batch's instance pairing, its rollback scope, the refusal copy's home, the unreachable
  mandatory refusal and a dedupe assertion the brief's test list omitted), so the developer
  session amended the docs first (**CONTRACTS §16 rewritten as v0.8.0**, 09 §10's dated
  amendment, STATION_HUB §5.1's battery anatomy + §5.10's summary, brief/prompts **v2**,
  `game/projectile.gd` dropped from H2's set). Built: **H1** the battery strip —
  `PlayerProfile.fit_battery`/`clear_battery` (instances paired from `instances_of` in creation
  order into ascending cells, one composed transaction per cell, atomic over the fit **and** the
  bag) and OUTFITTING's one-row-per-battery strip (`3× LASER MKII · W1·W2·W3 · OWNED ×<n>`,
  read-only `W<n> — EMPTY` lines for the empty cells, `FIT ALL`/`REMOVE ALL`/`SWAP ALL`, the `▸`
  expander restoring every single-cell action, the fixed 7-row/253-node set never rebuilt,
  `tests/test_s4_batteries.gd` 15); **H2** the volley — per-barrel `fitted()`, `battery_ids()`,
  `battery()`, one trigger arming the whole battery with per-barrel release offsets inside
  `BATTERY_STRUM_MS := 40`, one round per barrel out of the family's one pack, per-barrel damage
  and recoil, one timer per barrel (`test_engine2_weapons.gd` 29 → 42). Reviewer: **one HIGH, one
  MED** — HIGH-1 a held trigger fired **one** salvo then went silent for every travelling family
  (measured 3 shots in a 3.0 s hold) and MED-1 a refused bulk action still stored a fit on a hull
  that had none; both cured by the fixer pass (re-arm on the frame the salvo is spent, `edge` and
  beam carve-outs; preview-then-seed with `_unseed_fit`), each with a regression test that is red
  pre-fix, gate 521 → 524. **Independently reproduced at close-out:** the review's own archived
  probe re-run under a scratch `XDG_DATA_HOME` gave **15 shots in a 3.0 s hold** (five salvos
  ~0.6 s apart) against the review's 3. Measured by the reviewer, not taken on trust: rules 1–3
  (`[w_mining, w_laser]` → `fitted()` `[laser]` / `battery()` `[0]` while that laser is cell 1),
  rules 7–8's rollback **byte-compared on both branches** (2 and 3 `FIT_MODULE` lines committed
  before the refusals, `fit_for`+`modules()` and `fits()` `[] → []`), the refusal copy (the three
  literals byte-equal to `fitting_panel.gd`, `13 / 11 PWR — OVER BY 2` reachable and rendered
  through a battery on the Gunship), the fixed node set, the expander's per-cell REMOVE, and
  `verify_wave` `problems: []` twice. Wave convention note: this wave's evidence is **one shipped
  probe inside `vajb-orbit/tests/` (`probe_s4h4_stream.gd`, header-guarded, not in the gate) plus
  ten probes archived as text** in `_review_probes/` — the "is a probe evidence or a deliverable"
  question stays open as **L121**. LOW rows **L123–L129**. **Owner ticks owed: none new** (the
  mount semantics were ruled 2026-09-22); two readings the owner may overrule — the strip's
  read-only `W<n> — EMPTY` lines (reversal: drop them) and `SWAP ALL`'s whole-list refusal when
  the bag cannot cover every barrel (reversal: cut the list or disable the plate below the cell
  count) — plus the standing `BATTERY_STRUM_MS := 40` with reversal 0.

- **S3 the item economy — DONE 2026-09-23** (gate 457 → **493, 0 failed**, exit 0 in two
  consecutive hermetic runs at close-out plus one under a scratch root, identical counts;
  the live account byte-identical across every check — reports
  `.agents/gen/slices/S3-module-affixes/S3-K{0,1,2,3,4,5}_report.md` + `S3-K4_review.md`):
  **module instances with affixes and the AUCTION.** The wave opened with a docs drift
  check that found the wave **could not be built as pinned** (7 HIGH: no `count` on the
  record, no store for a shelf, a buy call that could not be told the price shown, a fitted
  instance that could not come back intact, no affix→stat owner, 15 §4's Ledger contradicting
  the sell formula, and the three faction exclusives with **no price, tier, draw, effect or
  art anywhere in the tree**), so the developer session landed a docs pass first
  (CONTRACTS **§15 v0.7.3**, `15 §9`'s three exclusive rows + the F-lot split + the
  "stored, named, priced, displayed — **not applied**" rule, `10 §2.2`'s six-vs-chance
  reconciliation, `10 §2.4`, `17 §3`, STATION_HUB §5.1/§5.3/§5.8/§5.10) and rebuilt the
  wave's own verify command (its comma-joined flags had made the frozen-file guard inert).
  Built: **K1** the instance core — `{instance_id, base_id, rarity, prefixes[], suffixes[],
  count}` with `count` 1 in the bag / 0 fitted and never erased, the `mod_%04d` counter, the
  two new top-level keys, the seven 15 §2 source tables and all 12 prefixes + 10 suffixes,
  `roll_instance`/`buy_instance(id, cost)`/`sell_instance`/`take_instance`/`restore_instance`/
  `auction`/`set_auction`, `SAVE_VERSION 6` with the idempotent v5→v6 Common migration, and
  `base_fit` — the id→base translation that stops `fit_legal` scoring an instance as draw 0
  (`tests/test_s3_instances.gd` 9, `test_s3_migration.gd` 5); **K2** the AUCTION —
  `game/auction.gd` (lazy 20-minute band rotation off the shared clock, 6 hulls + 10 rolled
  listings, the F lot first at 85/15, one hot slot), `auction_panel.gd/.tscn` and rail index 3
  with the three `rarity_*` tokens, and OUTFITTING's seven module rows retired
  (`test_s3_auction.gd` 11); **K3** rolled identity everywhere a fit is read — `OWNED ×<n>`
  aggregated by base id with a `▸` expander of instances, 15 §7's rolled name in its rarity
  tint plus the two-line stat block in FITTING's hover and the shipyard's, instance-true
  install/remove round trips (27 + 14 tests). Reviewer: **one HIGH, no MED** — the legacy
  OUTFITTING strip's REMOVE banked a base-keyed Common instead of the fitted instance (and
  could duplicate a unit in the bag); fixed by the fixer pass (`outfitting_panel.gd:664` now
  calls the composed `clear_fit_slot`) with two regression tests that are red on the pre-fix
  panel. Measured by the reviewer, not taken on trust: the roll tables row by row (six seeded
  outcomes reproduced exactly), the migration's idempotence, L80's identity, 2 000 seeded
  shelves (exactly 6 + 10 every draw, F lot first 400/400, tier weights 0.5072/0.3403/0.1525),
  prices 0 mismatches over 35 rows × 3 rarities, `verify_wave` `problems: []`, and no affix
  touching a flight stat. LOW rows **L107–L122**. **Incident (owner data, T-93/L107's
  neighbour):** K1's first dispatch ran an instrument against the live `user://` — it refined
  and sold the owner's mined ore and rewrote the account as save v6; the pre-probe state was
  exactly recoverable from the economy log, restored and re-verified through the engine's own
  loader, and every remaining builder prompt now forbids touching the live store
  (`slices/S3-module-affixes/_incident/README.md`). **Owner ticks owed:** 1) the three
  exclusive rows' numbers (`15 §9.1`: tier III, draw 3/3/0, cost 5 200/5 200/4 500, the two
  icon fallbacks); 2) the F lot's 85/15 split (`15 §9.2`); 3) the v5 stock migration's
  Common default vs a retro-roll (one call); 4) the F-lot interim flag; 5) the AUCTION's rail
  position; 6) **whether to schedule the affix-application wave** (`15 §9.3` — the wave
  stores, prices, names and displays affixes but applies none); 7) the rarity tints'
  one-accent exception into STYLE_BIBLE; 8) `10 §2.2`'s exactly-six-vs-the-chance-column word;
  9) the Windows-host copy of the account (unchanged since S2.6's incident).

- **S2.6 truth-and-feel — DONE 2026-09-22** (gate 437 → **457, 0 failed**, on the owner's own
  live `user://` twice, byte-identical, plus once on a mutated copy under a scratch root; the
  live account byte- and mtime-identical across all three runs — reports
  `.agents/gen/slices/S2.6-truth-and-feel/S2.6-R{0..7}_report.md` + `S2.6-R6_review.md`):
  **the gate is hermetic at last** — `tests/headless_runner.gd` creates `user://_gate_scratch/`,
  repoints the profile store there, resets the in-memory profile and seeds the deterministic
  default before the first suite, and re-sandboxes the economy log around every suite; the four
  live-coupled engine2 fixtures build their own fit (index-guarded) instead of reading the live
  save. The owner's seven feel rulings landed: fragments burst outward from a still rock
  (`FRAGMENT_OUTWARD_KICK 150.0` in `asteroid_field.gd:_cleave`; AC2 over 681 fragments, lowest
  radial 149.520 u/s), a beam line sinks into the middle of what it strikes (`BEAM_SINK 0.45`)
  and its contact FX scatter in a `clamp(0.35 × radius, 8, 48) u` disc (exactly three readers —
  chip sparks ×2, shield ripple), the mining beam finally draws its chip sparks (L65), hulls
  take double the time to 90 % of `max_speed` (`ACCEL_TIME_MULT 2.0`; t_90 ratio 1.99–2.00 per
  class) and keep their carry (`COAST_TIME_MULT 2.0`, the documented revert onto §13's own
  column) **without** the sideways skid growing (`LATERAL_DAMP_MULT 1.0`, the forward/lateral
  split), the cursor steers at zero throttle so a neutral turn no longer thrusts
  (`STEER_WITHOUT_THROTTLE` supersedes §4's W-gate — 360° at 0.000000 u displacement), and the
  motion blur skips the player hull shader-side, chromatic split included, leaving the
  hull-critical vignette over it. Reviewer: **no HIGH, two MED** — MED-1 (two yardstick rows in
  `test_flight_beam_g2.gd` / `test_weapon_fx_f4.gd` still pinned the FX *exactly* on the hit
  point the jitter moves) fixed by the fixer pass, and MED-2 the **incident below**; R1 was the
  wave's own HIGH-cured defect (the first harness run wrote the live account — see
  `slices/S2.6-truth-and-feel/_incident/README.md`, backlog **L106**). LOW rows **L94–L106**.
  **Owner ticks owed:** 1) the `18_engine_spec.md` §6/§13/§15 dated amendment (owner-locked,
  now also covering `FRAGMENT_OUTWARD_KICK`, `ACCEL_TIME_MULT`, `COAST_TIME_MULT` and the
  `coast_time` revert); 2) flight taste — `ACCEL_TIME_MULT` 2.0, `COAST_TIME_MULT` 2.0,
  `LATERAL_DAMP_MULT` 1.0, one constant each; 3) **confirm the steering supersession** (the
  cursor now steers at zero throttle; reversal is the W-gate); 4) slice 2.5's two calls (engine
  bed, vignette strength under alpha).
- **P2-B proper fitting panel — DONE 2026-09-22** (gate 389 → 402 → 420 → 431 → 437; reports
  `.agents/gen/p2b_proper_{d0,w1,w2,w3,r1,f1,f2}_report.md`): the station now has a **FITTING**
  pane where it had the pre-module UPGRADES rows — the UPGRADES rail entry becomes FITTING
  and its pane files are gone, the active hull's own slot grid renders with the shipyard's
  plate recipe and **selectable cells**, and per-cell install / swap / remove go through the
  two new composed profile transactions (`fit_module_at`, `clear_fit_slot`) with the power
  meter showing the candidate's arithmetic before commit and the pinned refusals
  (`13 / 11 PWR — OVER BY 2`, `MANDATORY CELL — SWAP ONLY, NEVER EMPTY`, `REFUSED · FIT
  ILLEGAL`) in the footer. The **save v5 flag day** retires the six legacy upgrade rows: each
  installed row migrates to its 09-lineage successor module (`upgrade_generator` → `p_mk2`,
  `upgrade_shield` → `s_heavy`, `upgrade_engine` → `e_ion`, `upgrade_module` → `c_scanner`,
  `upgrade_extra` → `u_cargo`, `upgrade_drone` → `u_drones`), idempotently, with `has_upgrade`
  / `install_upgrade` deleted (measured: a v4 file with all six reads back as six inventory
  modules and a second migration call returns 0). The owner's four station requests shipped:
  the shipyard hover line (`W1 · LASER MKII · OWNED ×3`), the OWNED MODULES inventory, the
  shipyard-recipe grid, and LAUNCH's REFUEL/RECHARGE rows (free and instant, no credits move).
  Reviewer: **no HIGH, two MED** — MED-1 (the pane previewed the launch's fallback fit while
  the profile committed against the stored fit, so FITTING was dead on any hull with no
  stored fit; cured profile-side with `resolved_fit`, the fit the launch would fly, so preview
  and commit read one shape) and MED-2 (a refusal's footer line outlived the successful action
  that followed it) — both fixed by F1 (+6 tests). Eight LOW → `LOW_BACKLOG.md` L85–L92. The
  orchestrator's F2 then cured a **pre-existing** fixture assumption R1 diagnosed (three
  engine2 dock/fixes tests resolved the ammo slot from the catalogue order while the launched
  fit sizes it, which the owner's own cannon-first Vanguard exposed): 434/3 → **437/0** on the
  canonical gate with the live profile — **corrected 2026-09-22**: the live-profile
  gate reads 433/4 (L93; S2.6-R0/F10 confirms 433/4 on a byte-copy of the live
  profile); F2's cure was measured against a profile state that no longer holds. **Owner ticks: 1–5 as briefed (§7) — the rail entry,
  the six-row retirement table, the pinned strings, the four requests, and affixes next —
  all measured landed; one measured residual rides to the backlog (a bare hull's delivered
  mandatory cell offers REMOVE and refuses with the pinned wording — W2's disclosed reading).**
- **P2-B1 weapon fit surface — DONE 2026-09-22** (gate 378 → 387 → 389; reports
  `.agents/gen/p2b1_{d0,w1,w2,r1,f1}_report.md`): OUTFITTING now sells the weapon modules
  into the profile inventory and installs/swaps/removes them through `ShipFit.fit_legal` —
  `PlayerProfile.buy_module` (refusals reuse `purchase_failed`; one `BUY_MODULE` economy-log
  line), the `MODULES` rows + `FITTED WEAPONS` strip, the two pinned refusal wordings
  (`11 / 8 PWR — OVER BY 3` on 09 §2's own format, `W SLOTS FULL — SWAP OR REMOVE FIRST`),
  and the mandatory engine/reactor set untouchable. Measured by R1: round trip + persistence
  re-read out of the file (credits 20 000 → 14 600, swap hands the laser back, reload
  identical), W2's probe byte-identical, 25 signatures 0 drift, 21 format-law byte checks 0
  failures, gate 387 measured twice. Reviewer: **no HIGH, two MED** — MED-1 (a module's
  unaffordable refusal named a fabricated `0 NEEDED`; `station.gd`'s `_entry` chain gained
  `ModuleCatalog`) and MED-2 (**`w_mining` had no row** — the mining laser, the launch-fit
  gate's symptom 2, was unobtainable; the brief's §1/§3 contradicted each other and D0 left
  it standing) — both fixed by F1, which landed the **seventh row** and two guards
  (`test_p2b1_outfitting_panel.gd` 7 → 9, gate 389). Eight LOW → `LOW_BACKLOG.md` L76–L83
  (plus D0's two stale cross-references as L84). **Owner launch-fit gate: both symptoms now
  closed.** **Owner ticks: the seven-row set (one-constant reversal), the refusal wordings,
  INSTALL = first empty W cell, and L78's ACTION precedence.** One incident worth the board:
  R1's first two dispatches appeared stalled for hours — the real cause was one of its own
  probes running an unbounded `while` loop (an inverted empty-cell search) at 100% CPU; the
  fixer of that was the orchestrator (bounded loop) and the probe now exits 0 in 20 s. Lesson
  for the probe-hygiene rule: every probe needs its own hard bound, not just `--quit-after`
  on the runner.
- **Rock cleave — DONE 2026-09-22** (gate 372 → 378; reports
  `.agents/gen/rock_cleave_a{1,2,3}_report.md`): every depletion now draws FX_SPEC §1.4's
  explosion at the rock's centre (`clamp(1.2 × diameter, 96, 224) u`, five frames, MIX,
  self-freeing), plays S4's rock cue through the new four-take `CUE_POOLS` row, and shoves
  reachable bodies with the shipped `Impact.apply_shockwave`; fragments are a uniform **2–5**
  on both cleaving tiers in **uniform 360°** directions at the shipped ×1.2 speed (measured:
  Large {2:80, 3:69, 4:72, 5:79}, Medium {2:78, 3:69, 4:70, 5:83}; widest fragment pair
  179.8°; 529/529 at exactly ×1.2); a Small keeps its 1–2 pickups; a yield-0 rock cracks
  bare but still plays the break read. Reviewer: no HIGH, one MED (`CONTRACTS.md` §5's
  retired cleaving sentence) fixed by A3 (+ v1.4 changelog), four LOW → L72–L75. **Owner
  tick owed: the §6/§13/§15 dated amendment (spec owner-locked).**
- **P2-A ship slot frames — DONE 2026-09-21** (gate 311 → 372; reports
  `.agents/gen/p2a_{d0,w1,w2,w3,w4,w5,r1,f1}_report.md`): every class owns its slot count and
  layout — nine matrices (shipyard grids 4×3 → 5×6, columns 4×8 + 5, plates
  8/11/12/13/13/15/14/17/23), the engine set (1–3 cells by §13 mass band, summed deltas with
  the 1.40 ceiling; single-engine snapshots byte-identical to HEAD), profile fits at save v4
  with v1–v3 loading clean, the nine-hull `StationCatalog` roster, the launch resolving the
  active hull's own fit (measured: Vanguard `[laser]` 300 rounds, Lancer `[laser, laser]` 600,
  was five families / 1500), and the station/HUD layout displays. Reviewer no HIGH, one MED
  (a shadowing const in `test_p2a_ship_roster.gd:10`) fixed by F1 (+2 tests), six LOW →
  `LOW_BACKLOG.md` L66–L71. **Owner launch-fit gate: symptom 1 closed at root cause;
  symptom 2 (the mining-laser swap) opens with P2-B1.** Owner ticks (brief §8) resolved, all
  six kept.
- **Slice 2.5 (Feel) — DONE 2026-09-21** (gate 294 → 311, `test_slice2_5_feel` 13): S1 shipped
  all nine deliverables (motion blur via `game/speed_fantasy.gd` + `speed_blur.gdshader`, the
  camera pull-back composed with the wheel zoom, dust streaks, the hull-critical vignette,
  low-hull arcs, the thruster trail behind a `thruster_anchors()` seam, the S16 thruster bed
  with its speed curve and 0.15/0.10 hysteresis, the boost cue and the dash charge). S2's review
  reproduced the gate and S1's probe byte-identically and blocked the close with **2 HIGH, 0 MED,
  6 LOW (L66–L72)**: the thruster bed held a voice but never loaded a stream (a fresh voice was
  silent, a reused one played the previous bed's file), and the trail drew at the master's native
  1401 × 86 px because `GPUParticles2D.scale` is inert for the drawn quad. The owner then re-cut
  every effect as per-frame RGBA sheets (`fx_<effect>_f1..fN.png`, true alpha, cropped to the
  effect's bounds) beside the untouched v1 masters, added `fx_mine.png`, and ruled the beam stays
  an engine-drawn line. **S3 (resumed with those facts) closed both HIGHs and re-wired all 15
  FEEDBACK rows plus the vignette to the per-frame sheets with alpha blending** — measured: the
  bed's voice plays its own cue from frame 1 on a fresh and a re-used voice, and the trail draws
  **22 × 6 px at ratio 0.15 → 54 × 6 at 1.0** (spec 24–56 × 6) where the node-scale lever still
  reads 159 × 26, `fx_mine` is the mine family's sprite and burst. Reports
  `.agents/gen/slice2_5_s{1,2,3}_report.md`. **Two owner calls raised:** which engine bed
  (`sfx_ship_engine_01` vs `_02_loop`) and whether the vignette under alpha needs a strength
  compensation (it draws 0.41× its additive reading, one line to reverse).
- **Flight feel & beam polish wave** (2026-09-21, gate 277 → 294): G1 the nose follows the
  cursor while `thrust_forward` is held (heading holds otherwise), A/D strafe derived from
  the class's own `max_speed`/`accel_time`, the nine `turn_rate` rows ×0.50 (Vanguard 3.0 →
  1.5 rad/s) and the two strafe actions in the Controls list; G2 the beam stops on the point
  its ray resolved (was drawn to the aim point, so it passed through), a laser chipping a
  rock plays the chip cue and the 4-frame burst, a held beam's feedback repeats, plus 29
  shadowing warnings cleared; G3 the UI/game warning sweep (75 → 65 raw rows); G4 reviewed
  with no HIGH (two MED, both fixed by G5) and found the gate's `SCRIPT ERROR` is pre-existing
  in `tests/test_weapon_fx_f4.gd:176`; G5 recorded the behaviours in CONTRACTS v1.3 and cleared
  the wave's own three new warning sites. Reports `.agents/gen/flight_beam_g{1..5}_report.md`.
  **Owner ticks owed:** `18_engine_spec.md:67` and `IMPLEMENTATION_PLAN.md:231` still say
  "A/D turn", and §13's turn column needs the ×0.50 tick.
- **Weapon FX & audio wiring wave** (2026-09-21, gate 236 → 277): F1 fire & travel, F2 impact
  & death, F3 review (1 HIGH, 3 MED, 11 LOW), F4 closed all four. Reports
  `.agents/gen/weapon_fx_f{1,2,3,4}_report.md`; the 11 LOW items are L48–L59 in
  `LOW_BACKLOG.md`. No balance number moved.
- **Combat/collision repair wave** (2026-09-21, gate 226 → 236): C1–C3 measured, C5
  fixed (rock `collision_mask` 0 → 2, the rock's ram sink on the shipped
  `GUN_CHIP_RATE`, plasma's live-shield bonus, the mine's cadence fallback, and the
  owner's nine `coast_time` rows ×0.50), C6 reviewed with no HIGH, C7 corrected
  CONTRACTS §4/§5/§8.2/§9 and wrote the v1.2 changelog, T1 gave the import tool its
  `--only` scope. Reports `.agents/gen/combat_repair_*_report.md`.
- **UI-chrome wave, code lane** (2026-09-21, gate 219 → 226): W1–W4 built the D3
  `TextureButton` size guard (six sites, measured shipyard strip 6184 → 360 px and
  launch panel 4781 → 952 px with the oversized art still on disk, new
  `tests/test_ui_slot_layout.gd` 7 tests), repaired the D4 stale `ext_resource` UIDs
  through the editor writer, ran the D5 lint pass (23 warning rows across nine files,
  including a latent `push_overlay` Callable trap it caught itself) and landed the D6
  doc ticks. W5 reviewed with no HIGH (two MED, ten LOW — all LOW now in
  `LOW_BACKLOG.md` as L30–L37), W6 closed both MEDs. Reports
  `.agents/gen/ui_chrome_w{1..6}_report.md`. The art half of the same blocker is the
  graphics lane's and stays owner-gated on the slot review sheet.
- **Engine wave 1** (fly-and-mine): W0–W5 built, W6/W8 reviewed clean
  (8/8 fixes, 40/40 probe checks), W7 fixed H1–H4 + M1–M3. Baseline `2a420a7`
  on `origin/main`.
- **Engine slice 0** (Physics & Fuel, 2026-09-21, gate 78/0): M0→M6. Hull on
  RigidBody2D, reactor chain, cleaving, free refuel, save v3. Review 1 HIGH +
  6 MED, all fixed and re-verified. Rulings R1–R4.
- **Engine slice 2** (Fight, 2026-09-21, gate 219/0): W0→W9. Weapons,
  projectiles, damage, NPCs, loot, HUD widgets, countermeasures Z/X, death →
  respawn. Review 1 HIGH + 10 MED; the HIGH (no weapon damaged a real ship)
  fixed by W7's `_sink_for`; W9 closed W8's R1 double-charge with a negative
  control. Rulings R5–R8.
- **Batch-2 lane:** B2-3 minimap zoom fixed; B2-1/B2-2 art-side, measured,
  routed. **Doc lanes:** 06 figures + 11 §3 pointer (F9/F11); B2 doc close-out.
- **Graphics lane, Phase G:** 65 files shipped (alien + 14 human hulls, 7 FX);
  `fx_shield_shatter` retired by owner ruling; `asset_path_fallout.md` empty
  (181 literals, 0 unresolvable).
- **Phases C, D, P1, F.1/F.2** — earlier, all closed (AGENTS.md has the state).

### Historical state recap (moved out of WAVEBOARD.md 2026-09-24)

**Engine waves closed as below
(slice 0 + slice 2 review-verified clean; gate `passed=311 failed=0`). A full-loop live
playtest (2026-09-21, godot-ai driven) verified the whole menu → station → launch →
space structure but found the `ui_slot_*` chrome shipping as whole sheet cells
(880×876 / 873×864). The **UI-chrome code lane is Done** (D3 guard, D4 stale UIDs, D5
lint, D6 docs; reports `.agents/gen/ui_chrome_w{1..6}_report.md`; no HIGH, two MED
fixed, ten LOW; measured: shipyard strip 6184 → 360 px, launch panel 4781 → 952 px
with the oversized art still on disk, gate 219 → 226). **Its art half is owner-gated**:
the graphics lane measured that the shipped alpha holds only the silhouette (the paid
matte keyed the plate out), so no crop recovers it — the pre-redesign cells came back
from Godot's import cache and await approval on
`staging/phase_f/_preview/review_slots.png`. The **combat/collision repair wave is Done**
(reports `.agents/gen/combat_repair_{c1,c2,c3,c5,c6,c7,t1}_report.md`; reviewer verdict
no HIGH, two MED — one an orchestrator record error, one the contract's own stale pins —
both fixed). Measured and fixed: the rock's `collision_mask` 0 → 2 (the pair solved as
immovable; a ram now hands the rock 72.821 u/s and 20.323 u), the rock's missing ram
sink (rides the shipped `GUN_CHIP_RATE` 0.10, no new constant), plasma's +25 % bonus
through a live shield (`NpcShip.shield_up()`), the mine's borrowed kinetic cadence, and
the owner-ruled drag retune (nine `coast_time` rows ×0.50: Vanguard t10 1.890 → 0.945 s,
carry 430.32 → 216.85 u, §13 tick pending). **Owner gates from this wave:** the §13
`coast_time` table (still open), and the launch fit, which **P2-A closed at its measured root
cause** — the launch now resolves the active hull's own fit and files ammo per fitted weapon
(measured: Vanguard `[laser]` 300 rounds, Lancer `[laser, laser]` 600; was five families /
1500), with the mining-laser swap (symptom 2) opening with P2-B1.  The **weapon FX & audio wiring wave is Done** (reports
`.agents/gen/weapon_fx_f{1,2,3,4}_report.md`, gate 236 → 277): a projectile now draws its
shipped sprite (bolt, slug, missile-trail sheet or mine ember) additively and turns to its
bearing, the instant families draw an engine-side beam line, a four-frame muzzle flash fires
per release, and every family plays its cue through a new cue-pool API (`sfx_weapon_laser`
round-robin 01–04 with ±10 % pitch / −3..0 dB, cannon tiers, the rocket's +80 ms warhead
layer); hits play `sfx_impact_{rock,hull,shield_hit}` plus the shield bed and spawn the
explosion/arc/ripple/break/plume sheets, a beam's own hits now read (the reviewer's one HIGH,
fixed in the fixer pass), and the mining shaft carries its beam bed. The reviewer verified by
measurement — every event's node, blend mode, sheet master, cue resolution and the absence of
any moved damage/cadence/range/Energy/ammo number. Evidence:
`.agents/gen/owner_playtest_findings_20260921.md`, `.agents/gen/playtest_fullloop_20260921.md`.
**P2-A (2026-09-21): the owner's per-class slot/layout request shipped — DONE** (gate
311 → 372). Every class owns its slot count and layout: the nine matrices, the engine set
(1–3 cells by mass band, summed deltas with the 1.40 ceiling), profile fits at save v4, the
nine-hull `StationCatalog` roster, the launch resolving the active hull's own fit, and the
station/HUD layout displays. Reviewer: no HIGH; one MED fixed; six LOW (L66–L71). The
owner's §8 tick list is resolved (all six kept); the one follow-up is the 7-W capital's
`weapon_6`/`weapon_7` input-map extension (an owner `project.godot` pass). Full entry under
§Closed.
