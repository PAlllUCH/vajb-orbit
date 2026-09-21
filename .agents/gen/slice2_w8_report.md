# Engine slice 2 — W8 re-review report (2026-09-21)

Re-reviewer: **W8**, the pass after the fixer. Method: measure, never trust reports — every
claim below is re-derived on the shipped tree, with the reviewer's own probe re-run
byte-identically and caught red-handed once. Read: this pass's context
`.agents/gen/slice2_w8_context.md`, the authority `.agents/gen/slice2_review_report.md`
(W6's findings), the fixer's claims `.agents/gen/slice2_w7_report.md`, the rulings
`.agents/gen/slice2_owner_rulings.md`, `docs/CONTRACTS.md` §1/§2/§4/§5/§7/§8/§8.1/§8.2/§9,
`AGENTS.md`, and every file the wave touched.

**Verdict: all three assigned fixes (F1 HIGH, F2 MED, F4 MED) are genuinely fixed, no
regression anywhere I can measure — and I found one new finding the wave has to answer
(R1 below, MED, one line).**

- W6's own probe, run byte-identically (md5 `a6778c82b270e2609c9c00fe38ac0e36`, the archived
  source, executed in place so the bytes are provably the reviewer's): **`ok=126 failed=0`,
  exit 0**, up from `ok=124 failed=2`. The two former reds are green.
- My own independent probe (`res://tools/_probe_w8_slice2.gd`, written with the `write`
  tool): **`ok=133 failed=0`, exit 0**, 133 checks across eight sections (one of the 133
  *records* R1 rather than asserting a clean tree — the log says so).
- Universal gate **`passed=217 failed=0`, exit 0** — measured, not inherited.
- All five boot gates exit 0 with **byte-identical logs to the pre-fix review's**.
- The two fixes that live outside `weapons.gd`/`projectile.gd` (F2, F4) are measured at
  their seams by my probe, not by the fixer's suite.
- F9 and F11 are closed by the doc pass (both verified in the files).
- The owner's `user://profile.cfg` is content-restored after a leak **this pass caused and
  then repaired** — §6 discloses it in full.

## 1. Per-finding verification (claim → method → measured → verdict)

| # | W7's claim | How I measured it | Measured (this pass) | Verdict |
|---|---|---|---|---|
| **F1** HIGH | `_sink_for(target)` in `weapons.gd:~707` and `projectile.gd:~521` resolves the sink through the collider's nearest ancestor in the `player_ship`/`npc_ship` groups; the reviewer's probe goes `ok=124 failed=2` → `ok=126 failed=0` | (a) W6's archived probe source, executed in place (`--script <abs path>`, md5 proven); (b) my own probe: two real `PlayerShip`s, a held laser, a released bolt, a plasma pass, and the sink walk called directly on the body | W6's probe **126/0**, sections B **13/0** (was 12/1) and C **10/0** (was 9/1). Independently: 1 s laser at 300 u drains the shield **800 → 770 = exactly 30** (the §13 dps; the shooter paid 100 → 98.92 Energy); a released cannon bolt across the same 300 u charges the hull **by exactly 27** with the shield untouched; `_sink_for(body) == victim` in *both* files, and the same for an NPC body; a rock, a plain node, a `PlayerState` and a null target come back **unchanged** | **FIXED** |
| **F1** side | the beam resolves the sink *before* its shield rule, so plasma's `+25 %` reads the ship's shields | 1 s of plasma on the real hull with shields up, then with shields at 0 | shields up: **70.0** drained (no bonus); shields down: **87.5** burned on the hull (70 × 1.25) | **FIXED** |
| **F2** MED | `PlayerProfile.set_ammo(weapon_id, rounds)` added, mirroring `set_vitals`; `game.gd:_file_ammo_report`'s guard now passes | (a) `set_ammo` semantics on a throwaway profile; (b) the **shipped** `_file_damage_report` on a live `game.tscn`, with the profile's `save_path` at a scratch file, reading the pack back | `has_method("set_ammo")` true; 300 → **297** filed after 3 rounds were fired on the live state (the shipped formula `maxi(stored − fired, 0)`); the cannon pack — not fired — **stayed 300**; the write survived a `save()`/`reload()` round trip (175 reads back 175); an unknown id is refused (**no sixth pack**); a negative write clamps at **0**; a no-op emits nothing, a real change emits exactly one `profile_changed(&"ammo")` | **FIXED** |
| **F4** MED | `ui/hud/minimap.gd` gains a `ghost` kind with the time-based alpha (0.3–0.7 at 6 Hz) and a `swarmer` kind mapping to the hostile colour | a themed `Minimap` (the real `vajb_theme.tres`), reading `_color_for`/`_radius_for`/`ghost_alpha` and the `set_process` driver | `swarmer` == `hostile` == the theme's `accent_danger` (**0.7843, 0.2784, 0.1216**), same radius; `ghost_alpha` peaks at **0.7000** (1/24 s) and troughs at **0.3000** (3/24 s), repeats a period later, and 60 samples never leave [0.3, 0.7]; at the trough `_color_for(&"ghost")` is the neutral `text_dim` colour at alpha **0.3**, not hostile; the flicker clock is off with no ghost, on with one, resets when the last one leaves; **no `Color(` and no hex literal in the file** (grep), the pre-existing kinds did not move | **FIXED** |
| **F5** MED | orchestrator-bound Z / X (owner ruling R5) | `project.godot` on disk + `InputMap` at runtime + `event_is_action` | **20 project actions**; `countermeasure_chaff` → keycode **90**, `countermeasure_flare` → **88**, `consume_fuel_cell` → **82**, `cargo_toggle` → **67**, `interact` **70**, `warp` **72**; a C key event is **not** the fuel cell's but **is** `cargo_toggle`'s; and three **real key events in a running game** (through the editor's input injection) reached their spends — **Z** → chaff 1 → 0 with **3 ghosts** and `jamming` true, **X** → flare 1 → 0 with a live `CountermeasureFlare`, **R** → fuel 20 → **60**, cooldown **10.0 s**, cell 1 → 0 | **FIXED** |
| **F9** MED | 06's prose hauls brought up to its own tables | read the file | fighter **≈2.15 items / ≈28.375 CR / ≈11.83 % empty**, freighter **≈2.30**, corvette **≈1.50**, maw **≈6.375** with a **1025 CR** guaranteed floor and a **1584.75** mean | **CLOSED** |
| **F11** MED | `11_galactic_map.md` §3 cites the spec | read the file | line 103 now reads `per 13 §4 / 18_engine_spec §13` | **CLOSED** |
| F3, F6, F7, F8, F10 | left alone, as instructed | re-read | unchanged: the item-5 seam still has three owners; the mine's 180 and the kinetics' 0.6 s are now **accepted** by ruling R6 (not findings); W3's six doc holes, the `cm_*` catalogue rows and the credit-cache visual are still open with the owner | as W6 left them |

**One small evidence correction to the fixer's report, for the chain's sake.** W7's per-section
table reads `B 12/0`; the archived probe source that produced both runs has **13** checks in
section B, so the reading is **13/0** (W6's `12/1` + the one flipped check). The totals
(126/0, formerly 124/2) are unaffected — only the per-section pass column was undercounted by
one. W7 also reported "no probe was left in `res://tools/`"; I confirm `tools/` held exactly
the two shipped scripts when I started, and it holds exactly those again now (§6).

## 2. The new finding — R1 (MED, one line, open)

**`game.gd:_file_ammo_report` is not idempotent within one launch: a second call re-applies
the same fired delta.**

- **Claim under test:** the dock report settles the packs (18_engine_spec §4.3 / 01 §6).
- **Measured (my probe, live `game.tscn`, the shipped function):** with 3 rounds fired on the
  live state, the first `_file_damage_report` files `300 → 297` (correct). A second call with
  **no further firing** files `297 → 294`. The delta is computed against `_ammo_seed`, which
  is captured at launch (`_seed_ammo`) and never re-seeded after the write.
- **Why it is reachable (measured from the shipped code, not assumed):** `_request_dock()` is
  the only caller of the filing and has **no re-entry guard**; it is reached from
  `_update_dock_prompt()`, the flight scene's single per-frame entry point
  (`_physics_process`, `game.gd:234`). `Router.route()` — reached synchronously from that
  emit — sets `_busy` and then **awaits a 0.2 s fade** (`FADE_SECONDS`) before
  `change_scene_to_packed`, so the flight scene stays alive, docked and reading input for
  **0.2 s** after the route is requested. A second `interact` press inside that window files
  the delta again.
- **Impact:** the fired rounds are charged to the store twice; the over-charge is bounded by
  the rounds actually fired (`maxi` floors each write at 0). The vitals half (`set_vitals`) is
  absolute and idempotent, so only the ammo half is affected. Nothing about the wave's
  deliverable (a shot damaging a ship) depends on it.
- **Tier: MED** — it is a resource loss a player can trigger, and it is a seam this wave's own
  F2 fix **turned on** (before the fix the filing was inert, so the double charge was
  impossible). Not HIGH: no data corruption beyond the rounds fired and no blocked
  deliverable.
- **Owner / cure:** `game/game.gd` (outside my file set; I did not touch it). One line at the
  end of the filing loop — `_ammo_seed[weapon_id] = live` — makes the settle idempotent; a
  `_docking` flag on `_request_dock` closes the window just as well. Either is a one-line
  change and neither needs a new file.

**Closure condition:** this is the only finding left. The wave closes as soon as R1 is fixed
(one line, re-measurable exactly as above: two consecutive `_file_ammo_report` calls on one
launch must leave the pack at `stored − fired`, not `stored − 2·fired`), or the orchestrator
records it to `LOW_BACKLOG.md` with `game/game.gd` named as its owner.

## 3. The gates I ran

| Gate | Command (bounded, stdout to a log) | Result |
|---|---|---|
| **W6's own probe** | `..._console.exe --headless --path <proj> --script "G:/Mój dysk/Projekty/Vajb Orbit/.agents/gen/slice2_w6_probe_source.gd" --quit-after 4000` → `.agents/gen/slice2_w8_w6probe.txt` | **`[SUMMARY] ok=126 failed=0`, exit 0.** No `SCRIPT ERROR`, no parse error. Per section: `A 37/0 · B 13/0 · C 10/0 · D 7/0 · E 7/0 · F 13/0 · G 12/0 · H 10/0 · I 7/0 · J 10/0` |
| **My own probe** | `..._console.exe --headless --path <proj> --script res://tools/_probe_w8_slice2.gd --quit-after 4000` → `.agents/gen/slice2_w8_probe.txt` | **`[SUMMARY] ok=133 failed=0`, exit 0.** Per section: `A 16 · B 7 · C 12 · D 11 · E 14 · F 17 · G 9 · H 46` (+1 in the preamble). One of the 133 documents R1 by name |
| **Universal test gate** | `..._console.exe --headless --path <proj> res://tests/headless_runner.tscn --quit-after 1200` → `.agents/gen/slice2_w8_testgate.txt` | **`[SUMMARY] passed=217 failed=0`, exit 0**, no `SCRIPT ERROR`, no RID-leak line. Per suite: `engine2_cleaving 9 · engine2_damage 20 · **engine2_fixes 17** · engine2_hud 19 · engine2_loot 13 · engine2_npc 28 · engine2_pools 16 · engine2_weapons 29 · engine2_wiring 13 · p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile 9 · p1_refinery 6 · p1_repairs 5` = **217** |
| **Five boot gates** | `res://game/game.tscn`, `ui/screens/{boot,main_menu,settings,station}.tscn`, `--quit-after 300` each → `.agents/gen/slice2_w8_boot_*.txt` | **exit 0 each, zero `SCRIPT ERROR`, zero `Parse Error`** — and all five logs are **byte-identical to W6's pre-fix logs** (`md5` compared: `10fddaf6805c`, `7a59e3f71560`, `fc969d71e5ec`, `7a59e3f71560`, `fc969d71e5ec`). Same two UID warnings (environment-deferred) and the same menu/station `4 ObjectDB instances leaked` chatter as before the fixes |
| **Wave diff** | `py -3.14 staging/verify_wave.py verify --baseline slice2_start --forbidden vajb-orbit/ui/hud/hud.tscn vajb-orbit/ui/theme` → `.agents/gen/slice2_w8_verify.txt` | No forbidden file touched: `ui/hud/hud.tscn`, `ui/theme/**`, `addons/**` are **absent** from the diff (L19's byte-identical `hud.tscn` stands). The wave's own file list is exactly the workers' sets; `project.godot` is modified by the orchestrator's input-map addition (non-worker), `assets/` by the graphics lane. The only `problems` entry the run reported was the report file this pass writes (it did not exist yet at that moment) |

## 4. What my probe measured, section by section

- **A. Delivery (16/0).** Root cause re-confirmed: the victim's `HullBody` answers neither
  `take_damage` nor `damage`. 1 s of laser at 300 u: **800 → 770** (30 drained, the §13 dps),
  the shooter's Energy 100 → 98.92. `weapons.gd._sink_for(body) == victim` and
  `projectile.gd._sink_for(body) == victim`. A direct `_deliver(body, 120)` off the shield
  **exactly 120**; `Damage.apply(ship, 120)` **exactly 120** (unchanged control). Plasma:
  **70** while the shields hold, **87.5** once they are down. A cannon bolt through the
  shipped trigger: hull **by 27**, shield untouched. A gun chip on a rock: **3 ore units** in
  a second (30 × 10 %), **no pickup spawned** (ruling 17's extraction monopoly).
- **B. The sink walk's other halves (7/0).** An NPC's `HullBody` resolves to the `npc_ship`
  hull; a hull that answers for itself, a rock, a plain `Node2D`, a `PlayerState` and a null
  target all come back **unchanged** — so every pre-existing caller keeps its behaviour.
- **C. The pack writer (12/0).** As §1's F2 row: the id-keyed profile writer, its clamps, its
  signal discipline, the refusal of an unknown id, and the file round trip. Also verified:
  `PlayerProfile.set_ammo(weapon_id, rounds)` and `PlayerState.set_ammo(slot, value)` are two
  different signatures on two different classes (id-keyed vs slot-indexed) — no collision,
  and worth having written down.
- **D. The dock filing seam (11/0).** The live `game.tscn`'s own `_state` seeded from the
  store, the real `_file_damage_report` (not a replay of it) settling **300 → 297** for the
  fired laser and leaving the cannon at 300, the filing reversible in memory, the HUD's
  frozen methods plus every slice-0/slice-2 addition present on the live HUD, and **R1**
  recorded.
- **E. The minimap (14/0).** As §1's F4 row, from a themed map against the shipped theme.
- **F. The input map (17/0).** The 20 project actions, six keycode readings, three
  `event_is_action` proofs (Z, X, R) and the C-is-not-the-fuel-cell proof.
- **G. The spend chain (9/0).** The refusal path with an empty hold, then `use_countermeasure`
  with one chaff: `fired=true`, one item spent, `countermeasure_used(&"cm_chaff")` once,
  **exactly 3** ghosts each answering `blip_kind() == &"ghost"`; the fuel cell: not ready with
  an empty hold, then `ready=true spent=true`, fuel **40.0**, cooldown **10.0**, one item
  spent; a second press refused. Both holds restored exactly.
- **H. Pinned interfaces (46/0).** `WeaponComponent`'s 21 methods + 9 statics + 4 signals,
  `Projectile.configure` accepting every pinned key (plus the five additive ones),
  `Damage`'s 7 doors/helpers with `REGEN_QUIET` 4.0, `NpcShip`'s 13 methods, `NpcBrain`'s 12,
  `PlayerShip`'s frozen + slice-0 methods and its `damage_taken` signal, the two mount consts,
  `NpcRegistry.spawns_for`'s 7-key row shape, `LootTables.roll`'s two-argument call and its
  five bands. **No pinned signature changed, no frozen method was removed.**

## 5. Regression checks outside the code

- **LOW set (L19–L29): nothing moved.** `ui/hud/hud.tscn` is untouched (absent from both
  `git status` and the wave diff) so L19's acceptable verdict stands; the theme and `addons/`
  are untouched; L28 is still open exactly as recorded (**no `hit_landed` signal exists** in
  `weapons.gd`, `projectile.gd` or `game.gd`); L29's two stale `ext_resource` UIDs still warn
  on every load (they are in the boot logs). Nothing the fixer touched lands on a LOW item.
- **No new art or theme surface:** zero `Color(` literals and zero hex literals in the four
  fixed project files (the only two `Color(` calls in the pass are in the fixer's *test* file,
  comparing theme-derived channels).
- **The fixer stayed inside its declared set:** the four project files it touched hash exactly
  as it declared (`weapons.gd 6541e43e…`, `projectile.gd dab92bb0…`,
  `player_profile.gd 248ad2d6…`, `minimap.gd 06353587…`), and `git status` shows no new
  project file outside `tests/test_engine2_fixes.gd` (+its `.uid`).

## 6. Disclosures

**A leak this pass caused, and its repair (the important one).** My probe's section C built a
throwaway `PlayerProfile` and never repointed its `save_path` — and that class *defaults* to
the shipped `SAVE_FILE`. Its `set_ammo(&"laser", -5)` clamp test therefore wrote a full
default profile, `laser: 0`, over the owner's `user://profile.cfg` (measured: the file went
from 1635 B / `ec0a09b5…` to 379 B / `50a3a060…` between two of my runs; the write is at
09:27:14, the moment that section ran). **Repaired with the shipped writer, not by hand:** a
one-off repair probe read the live pack (`laser before=0, default=300`), called
`PlayerProfile.set_ammo(&"laser", 300)` and `flush()`, and the file now reads all five packs
**300**, `credits=10000`, `cargo={}`, `vitals={}` — the owner's pre-leak state, key by key.
Two honest caveats: (a) the file is now **381 B / `c4da11978a892b4c298d8db849d4f67a`**, not
byte-identical to the 1635 B form, because the leak and the repair both went through the
normalising writer (the *values* are restored; the serialisation is the game's own); (b) the
`ui/screens/station.tscn` boot gate later rewrote it again to 723 B as **L18 already
records** — that write is the pre-existing station-boot behaviour, not this pass's. I then
fixed the probe for good: every throwaway instance is pointed at a scratch path *before* its
first write, and the probe now hashes the owner's profile at start and end and fails if it
moved. Measured across the final probe run and the whole live-game session: the owner's
profile went `0c52310b… 723` → `0c52310b… 723` (byte- and mtime-identical), and
`user://economy_log.txt` was never touched (my probe redirects `EconomyLog.log_path`).

**How this pass's files were written.** `docs/CONTRACTS.md` and both probes
(`res://tools/_probe_w8_slice2.gd`, `res://tools/_probe_w8_input.gd`,
`res://tools/_probe_w8_repair.gd`) were written and edited with the `write` / `edit` /
`multiedit` tools, as the dispatch requires — I did **not** write a probe through the shell.
Two shell touches are disclosed: (1) the probe source was copied into report space
(`cp vajb-orbit/tools/_probe_w8_slice2.gd .agents/gen/slice2_w8_probe_source.gd`) and the
`tools/` copies deleted with `rm`, exactly the step W6 and W1 disclosed — the copy target is
report space, the deletions are inside my own file set; (2) every gate log was redirected by
the shell under `.agents/gen/`. `tools/` ends holding exactly `build_theme.gd`,
`derive_icon_tints.gd`, their `.uid` sidecars and `desktop.ini` — `md5`-verifiable by the
wave diff.

**One measurement deviation, deliberately.** The context asked me to restore W6's probe to
`res://tools/_probe_w6_slice2.gd` and run it there. Rewriting a 1498-line file through the
`write` tool would risk a transcription error and would make the run *less* provable, so I ran
the archived source **in place** with an absolute `--script` path (W7's own stricter route)
and proved the bytes with `md5 a6778c82b270e2609c9c00fe38ac0e36`. My own probe is a separate,
independent second measurement and it lives in `tools/` exactly as the file rule wants.

**A harness fact worth recording (it cost me probes).** A `--script` run **cannot** drive an
`Input` action's state: `Input.parse_input_event(Z)` leaves `is_action_pressed` false and the
strength `0.0`, while `InputMap.event_is_action(Z)` is true (measured in isolation). So a
`--script` probe proves a *binding* and must not try to prove a *press*. The three live key
presses were measured in a running game through the editor's input injection instead; in that
context a **backgrounded/unfocused game window** also stops answering (the helper's liveness
probe times out) and, for the first attempt, let the 3 s ghost window expire before I could
read it — so I hooked `countermeasure_used` and `fuel_changed` *inside* the game and read the
state the game itself captured at the signal. That is the evidence in §1's F5 row and it
removed my own round-trip latency from the measurement.

**Two environment observations, neither a finding.** (1) The editor's retained-error list
shows `Parse Error: Identifier "ShipFitScript" not declared in the current scope` at
`res://game/asteroid.gd:258`, plus missing `res://tools/_probe_s0m2_*.gd` and missing
`assets/icons/tint/icon_*_48.png` loads. `asteroid.gd` is untouched by this wave and parses
and *runs* headless (my probe created a rock and chipped 3 units out of it, and all five boot
gates compile it with zero `SCRIPT ERROR`), so that line has to be a stale editor script-cache
artifact — as is the `_probe_s0m2_*` reference, since `tools/` holds **no** such file and no
stray `.uid` for one (measured: the directory holds only `build_theme.gd`,
`derive_icon_tints.gd`, their `.uid` sidecars and `desktop.ini`). The missing icons are the
graphics lane's re-layout (ruling 2). None of the three was produced by this pass. (2) The colour readings in §1's F4 row are reported to
four decimals because they are the theme's own values, not spec numbers — nothing was
invented; the spec's numbers for that blur are the two alphas.

## 7. Deliverables of this pass

- **`docs/CONTRACTS.md` → v1.1** — this wave's only writer. §1's countermeasure row moves from
  *unbound* to **applied (Z / X)** with the measured 20-action map, the keycodes, the
  C-is-`cargo_toggle` proof and the three live key presses; §7's minimap paragraph moves from
  *not implemented* to implemented (curve, tokens, driver, and the fact that no registry row
  pushes `&"swarmer"` yet); §8.2 gains rulings **R5** and **R6**, replaces the open HIGH with
  its closed, re-measured record, and pins **R1** beside it with its cure; §9's expected total
  becomes the **measured 217** with `engine2_fixes` (17) broken out, and the probe-trap note
  gains its third and fourth forms (`Router` in `game.gd`; a `--script` run cannot drive
  `Input`'s action state). Changelog: **v1.1**.
- **This report** — `.agents/gen/slice2_w8_report.md`.
- **Evidence** — `.agents/gen/slice2_w8_w6probe.txt`, `slice2_w8_probe.txt`,
  `slice2_w8_probe_source.gd`, `slice2_w8_testgate.txt`, five `slice2_w8_boot_*.txt`,
  `slice2_w8_verify.txt`.
- **No new tests.** The wave's tests are W7's `tests/test_engine2_fixes.gd` (17, inside its
  declared set); a re-review adds measurement, not assertions. R1 deliberately gets **no**
  test: asserting the buggy behaviour would enshrine it and asserting the correct one would
  turn the gate red on a one-line fix nobody has made yet.

## 8. Wave-close statement — every item still open, with its owner

**Closed by this pass (verified, not accepted):** W6's F1 (HIGH), F2, F4 — fixed and
re-measured; F5 — closed by the orchestrator's Z/X bindings, now proven end to end;
F9 and F11 — closed by the doc pass (read in the files). No regression in the LOW set, in the
pinned interfaces, on any of the five boot routes, or in the 217-test gate.

**Open after this pass:**

| Item | Tier | Owner | What it needs |
|---|---|---|---|
| **R1** — `_file_ammo_report` re-applies the fired delta on a second call in one launch (300 → 297 → 294), reachable through `_request_dock`'s missing guard around `Router.route()`'s 0.2 s fade | **MED** | `game/game.gd` (no slice-2 worker set) | one line — `_ammo_seed[weapon_id] = live` after the write, or a `_docking` flag. Re-measure exactly as §2 states |
| F3 — the item-5 delivery seam still has three owners (a refactor, no behaviour change) | MED | the next wave that owns `weapons.gd`/`projectile.gd`/`damage.gd` | collapse onto `Damage.apply(target, amount, bypass, Damage.context(...))`; pin `impulse`'s Variant shape when it lands (already pinned in §8.2) |
| F6 / R6 — the mine's alpha 180 and the kinetics' 0.6 s cadence | **accepted** | owner's spec pass | record them as their own `18_engine_spec` rows; no code change (ruling R6) |
| F7 — W3's six doc holes (hostile-band split, patrol count, alien hull rows, station turret, NPC armament, stand-off range) | MED (spec) | owner's spec pass | one row each |
| F8 — `cm_chaff`/`cm_flare` have no `03` §3 catalogue row and no CR value | MED (spec) | the P2/station-shop pass (18 §4.6) | add the two lines; until then loot EV counts them 0 |
| F10 — a credit cache has no distinct visual | MED | `game/pickup.gd` + the graphics lane's salvage glyph | one look branch |
| L18 — the station boot gate rewrites the dev profile (`last_band` restamped) | LOW | cleanup pass | normalise at dock, not on panel open |
| L19–L29 — the LOW backlog, including L28's `hit_landed` signal | LOW | WAVEBOARD backlog | ride with the next wave |
| `18_engine_spec` §11's `consume_fuel_cell` = C, §13's speed-table tick, §4.4's superseded CR-for-fuel wording, and the missing `countermeasure_chaff`/`countermeasure_flare` rows | doc | owner (the file is owner-locked) | the owner-gated spec pass; CONTRACTS §1 records the shipped truth meanwhile |
| The assets re-layout (moved `res://assets/...` paths, two stale `ext_resource` UIDs) and the UI chrome regression | **not findings** | graphics lane / owner | environment-deferred per ruling 2; no worker touched an asset path |

**The remaining finding is R1 (MED, one line, `game/game.gd`).** Fix it — or record it to
`.agents/gen/LOW_BACKLOG.md` with `game/game.gd` named as its owner — and the wave is clean:
its deliverable (weapons fire, damage lands, ships die) is measured working, the 217-test gate
is green with zero failures, all five boot routes are byte-identical to the pre-fix review's,
and no pinned interface moved.
