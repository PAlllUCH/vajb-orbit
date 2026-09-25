---
slice: D11
worker: D11-R1 (mandatory review)
status: complete
gate: "812/0 twice on fresh scratch stores (+ targeted 53/0 S6+d11 run + verify's run = 3 green gates); verify --baseline d11_start exits 0, problems: []; live profile.cfg md5 byte-identical"
---

# D11-R1 review — AC1–AC7 re-measured on the shipped tree (W8's method)

**Verdict: 0 HIGH · 2 MED · 7 LOW → F1 runs.** Every number below was re-measured by this review (never copied from a worker report). Findings are diffed against ENVIRONMENT_SPEC §11 + §1.1/§6 and CONTRACTS §21's O6, never against the brief. Tools: `vajb-orbit/tools/r1_d11_pixels.py` (this review's pixel probe), two gate runs, one targeted suite run, `wave_d11.py qc`, `git diff`, source reads.

## AC1 — the approved sheet is the baseline (pins quoted verbatim)

Quoted from the approved sheet of record (`staging/phase_g/_review/d11_mockup.png`, baked text = `D11-A0_report.md` §Proposed pins):
- **Hero scale:** "today's footprint x 2.2 — frame `298.8 u` across (half `149.4`), effective `STATION_SCALE 0.0663 x 2.2 = 0.1459`"; today's pin `135.8 u` (half `67.9`).
- **Inventory:** "static x6 kinds / 12 instances … moving x3 kinds — approach strobe positions (5), shuttle loop (2 shuttles), crane slew arc (1 pivot)".
- **Motion:** "`STROBE_PERIOD := 1.2` s · `SHUTTLE_SPEED := 30.0` u/s · `SLEW_RATE := 4.0` deg/s".
- **Paths:** strobe dots `y=160,215,270,325,380` (55 u apart); loop `l-255 r+340 t-225 b+190 corner90` → `1866 u`, `62 s` lap; slew arc `±60°` at `4°/s`. **Ring:** A `120` vs B `175` (owner tick, unresolved).

Approval trail: A0 rendered **0** paid calls before the gate, A1 ran only after it, and the owner's 2026-09-25 playthrough records "the D11 station scene renders its full element table" (`.agents/gen/session_2026-09-25_findings.md`). No file carries a verbatim v2 approval line → **L189**.

## AC2 — shipped inventory (all re-measured)

- **Hero footprint:** `env_station_hero.png` 2048², `HERO_SCALE 0.1459` (`game/station_scene.gd:18`) → frame half **149.40 u = 2.2003 × 67.9** ✓ floor; content bbox `(54,72,1993,1975)` → content half **141.45 u = 2.36 ×** the old content half (59.90 u). Against the old file's *true* 2060 px width the frame ratio is **2.188×** (< 2.2 by 0.6 %; `sector.gd:61`'s "2048 × 2048" comment is stale) → **L185**.
- **Static kinds 6 ≥ 6 ✓** (arm/mast/gantry/windows/plate/lamp); instances **11 at rest + gantry_b on the slew pivot = the plan's 12** (the sheet counted gantry_b twice — as static and as the pivot; every planned instance is present). **Moving kinds 3 ≥ 3 ✓** (5 strobes + 2 shuttles + 1 slew = 19 elements, `station_scene.gd:69-122`).
- **QC re-run:** `uv run --with numpy --with scipy python staging/phase_g/wave_d11.py qc` → **15 files, 15 green, 0 fail**, matching A1's table cell-for-cell. This review's independent probe reproduces every column: transparency 51.9–75.7 % (all > 10 %), hot share hero 0.00197 / lamp_a 0.01060 / lamp_b 0.00190, **every other row ≤ 0.00013 < the 0.0005 fail line**, accent ≤ **0.00065 < 0.001** everywhere. (Plain `python3` cannot run the script here — no numpy/pip on the host interpreter → **L186**; A1's literal evidence line doesn't reproduce as written.)
- **§6 one-emissive (pixel check):** hot pixels exist only on hero + the two lamp runs; 86–100 % of them fall in the ember hue window (mean hot hue 20–25°); no glow rows anywhere else; `windows_a/b` pass 2 measure hot 0.0 ✓.
- **§9 negative list:** accent scan clean (above) + this review's visual pass of `_review/d11_ship.jpg` — no text, no watermark, no grid lines, no planet/nebula, desaturated gunmetal/rust only ✓.
- **§1.1 value step:** measured and **inverted** → **MED-1**.
- **Generation log:** `vajb-orbit/assets/env/generation_log_d11.md` present — 15 rows with prompt, job id, model, date, key route + the two re-prompts ✓.
- **Spend:** 17 `*_render*.json` (15 pass-1 + 2 r2) = **170 cr = $0.85** ≤ the $1.50 ceiling. Import settings spot-checked (`env_station_hero.png.import`: `compress/mode=0`, `mipmaps/generate=true`, `detect_3d/compress_to=0`) ✓.
- **§11 naming:** all 15 shipped names match §11's list, but §11's "ASSET_NAMING rows at ship" did not land → **MED-2**.

## AC3 — invariants (re-run, not trusted)

- **Group:** `setup()` joins `&"station"` on the root (`station_scene.gd:136`); `test_station_draws_composed_not_one_sprite` + `test_spawn_swap_keeps_centre_group_and_dock_radius` **PASS** (group survives, node named `Station`, parent == sector).
- **DockZone sibling + world radius:** sector child at `centre` (`sector.gd:549-561`), `CircleShape2D.radius = DOCK_RING_RADIUS = 120.0` (`sector.gd:73,554`), `global_scale == (1,1)` — all asserted **PASS**; never parented under the scaled art.
- **Centre:** `station_position() == CENTRE` **PASS**.
- **Dock/blips:** 119 u in / 121 u out, `blips()` = 1 `friendly` row at the centre **PASS**; `blips()`/`dock_zone_contains` untouched by the diff.
- **S6 rows re-run:** targeted scratch run `--suite=test_d11_station,test_s6_poi_loot,test_s6_heat` → **53/0**, including `test_blips_apply_the_soft_fog`, `test_an_allowed_dock_files_the_report_and_the_docked_faction`, `test_the_gate_reads_heat_and_the_dock_reads_standing` — green untouched.

## AC4 — motion, two frames

`test_motion_two_frames_under_the_constants` **PASS**: after `step_motion(1.3)` the shuttle's position and the slew pivot's rotation change and `strobe_lit` advances `0 → 1`; `test_reversal_valued_constants_stand_still` **PASS** (0-valued constants park every rule). No `Timer` nodes anywhere in the wave's files (grep). Constants at `station_scene.gd:24-26`; motion rides the scene node's own `_process` (`station_scene.gd:174`) — §11's "the sector's own `_process`" read as the frame loop (no timer, constants in the new file), the only shape compatible with AC5's diff scope. The strobe row asserts the pure static, not the lit dot's `visible` flag on the tree → **L188**.

## AC5 — diff scope

`git diff`: `sector.gd` **two hunks** (`@@ -113` the `_station` type line 116, `@@ -533` the `_spawn_station` body) + new `game/station_scene.gd`, `tests/test_d11_station.gd`, plus A0/A1's staging/assets adds. No `ui/**`, no `project.godot`, no `docs/gameplay/*`, `ENVIRONMENT_SPEC.md` unmodified (verify confirms). The line-116 type change is disclosed in C1's report and mechanically required by the swap → **L184**.

## AC6 — gate twice, scratch stores, cross-lane attribution

- Run 1 **`[SUMMARY] passed=812 failed=0`**, run 2 **`passed=812 failed=0`** — two fresh `XDG_DATA_HOME=$(mktemp -d)` stores, exit 0 both, identical counts; the worktree's `func test_` total is **812**.
- **Growth 807 → 812** = `test_d11_station`'s **5** rows (the brief's "753 + test_d11_station" formula predates S8/S10/S11's closes; 807 is CONTRACTS §9's baseline with S8's 17 rows inside it — S8 is closed, so no S8 row failed mid-wave). A1's mid-wave `790/5` belonged to the then-live coder lane (exchange_panel parse, s11 inspector, s7 ×2, engine2 weapons, ship_grids); all green now, **attributed, never fixed** by this lane.
- Live store untouched: `profile.cfg` md5 `f8a95c7c8985f5ce09b823df3f82b8d2` byte-identical before and after every run.
- `probe_g3_shadow` (not in the gate) reads `passed=19 failed=6` — both `sector.gd` rows byte-identical at HEAD, so the red pre-dates D11; C1's "its rows pass" claim is false → **L187**.

## AC7 — owner ticks, each with its measured value

| # | Tick | Measured value |
|---|---|---|
| 1 | Mockup approval (the A0 stop) | Sheet `staging/phase_g/_review/d11_mockup.png` (v2); A1 gated on it; **no verbatim v2 approval line on file** (L189) |
| 2 | Hero scale as approved | `0.1459 = 0.0663 × 2.2`, frame half **149.40 u = 2.2003 × 67.9** (true-pixel 2.188×, L185; content 2.36×) |
| 3 | Element inventory | **6 static kinds** (11 at rest + gantry_b slewing = 12) · **3 moving kinds** (5+2+1) · 19 elements |
| 4 | Motion constants | `STROBE_PERIOD 1.2` / `SHUTTLE_SPEED 30.0` / `SLEW_RATE 4.0` (`station_scene.gd:24-26`); both reversal rows green |
| 5 | The `game/` grant | Dispatch handoff carries it; diff = `sector.gd` (2 hunks, L184) + two new files only |
| 6 | **Ring A vs B** (A0's open tick) | Shipped **A = 120 unchanged** (`sector.gd:73`); hero content half **141.45 u** → the ring sits **21.4 u inside the hull**; B = 175 needs its own ratification (outside C1's grant) |
| 7 | `class_name` ratify/reverse (C1's deviation) | §11/O6 pin no `class_name` (that pin was the brief's interface block only) → **no spec finding**; collision corroborated: **8** pre-existing `const StationScene :=` sites (4 tests + 4 probes) + `test_p2a_lint_shadow`'s rule. Accepted against the spec; reversal = restore the registration once the 8 consts are renamed upstream |

## Findings by tier

**HIGH — none.**

**MED-1 — The shipped station art inverts §1.1's value rule: the environment now reads *brighter* than the ships it must sit behind.** §1.1/§1.3 ("Environment reads one value step darker than ships so ship silhouettes always dominate") — measured over opaque pixels (max-channel/255): hero **mean 0.237 / median 0.208**, the old shipped station **0.166 / 0.137**, the player's hull `ship_vanguard_side` **0.175 / 0.176**. Not hero-only: the 14 element rows mean **0.215–0.277**, all above the vanguard (docking arms **0.277/0.274** ≈ +0.10 ≈ two palette bands), while regular ships span 0.136–0.210 mean and the old station sat *darker* than the vanguard — the old relationship flips across the whole family. A0's own plan row for `env_station_hero` carried the "one value step darker than ships" phrase; the renders missed it and A1's QC has no value-step check. Files: `vajb-orbit/assets/env/poi/env_station_*.png` (fix = local value grade or re-render; layout pins untouched).

**MED-2 — §11's "ASSET_NAMING rows at ship" clause did not land.** `docs/design/ENVIRONMENT_SPEC.md:168-172` names the 15 files and says they become ASSET_NAMING rows at ship; `docs/design/ASSET_NAMING_SPEC.md` still holds **zero** `env_station_*` entries (its D6/D7 amendments show the convention). D11's brief forbade `docs/` writes beyond §11's ticks and R1's §9/§10, so no worker could land them — **escalation bucket 2**: the developer session adds the amendment (or the owner amends §11 to defer the rows with the host-deferred `validate_names --library` pass). Not F1's file set.

**LOW — L184–L190** appended to `.agents/gen/_state/LOW_BACKLOG.md` (ids read from the file at write time; L167's lesson): L184 AC5's second `sector.gd` hunk (line 116); L185 hero ratio 2.188× vs the old file's true 2060 px + the stale `sector.gd:61` comment; L186 `wave_d11.py qc` needs `uv run --with numpy --with scipy` here; L187 C1's false `probe_g3_shadow` claim (pre-existing `19/6`); L188 strobe row asserts the static, not the tree's `visible`; L189 no verbatim v2 approval line; L190 the 15 new `.import` sidecars + 2 `.uid` files untracked (tracked-text siblings are committed — include at the wave boundary).

## Close-out performed / owed

Performed by this review: gate ×2 scratch stores (812/0, 812/0), targeted S6+d11 run (53/0), the mandated `verify --baseline d11_start … --tests --expect-reports` run (**exit 0, `"problems": []`** — its modified list is S10/S11's and the owner rulings' post-snapshot commits plus D11's own `sector.gd`, no forbidden hit), QC re-run (15 green), independent pixel probe, live-store md5 before/after, AC1–AC7 re-measurement, this file, LOW rows L184–L190, CONTRACTS §9 expected count + §10 changelog row **v0.24** (next free read from §10, sequenced after S8's v0.20 and every later row).
Owed by the orchestrator: WAVEBOARD row + `MASTER_REPORT.md` §6 recap, wave-boundary commit (including the untracked `.import` sidecars and `.uid` files), and routing **MED-1** to F1 and **MED-2** to the developer session.
