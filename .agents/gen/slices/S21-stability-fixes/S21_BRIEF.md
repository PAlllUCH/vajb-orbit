# S21 — Stability & playtest fixes (wave brief)

**Wave:** S21 (code lane, item 27 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S21-stability-fixes/`
**Baseline:** gate **917/0** (measured 2026-09-28 on a fresh scratch store; S19 closed at 914, and `d3e246e` added `tests/test_wiring_map.gd`'s 3 rows with no gate-figure update); `python3 staging/verify_wave.py snapshot --name s21_start` before the first dispatch.
**Owner go (2026-09-27):** "i want to focus on content, bugfixes, playability and feel" — this wave is the bugfix half, restoring behaviour the docs already pin.

### Amendment 2026-09-28 (owner-ruled, this session)
1. **Baseline corrected `914/0` → `917/0`** — the figure above was stale, not a pin move; reversal is re-reading the number off the gate. `CONTRACTS.md` §9 stays R1's.
2. **The builder is split in three** (§7/§8): one worker for eleven fixes across ~15 files was the size risk the owner named, so `S21-B1`, `S21-B2` and `S21-B3` run sequentially on disjoint file regions and the mandatory review grades the whole A1–A11 across all three reports. The acceptance list, the pins (R-S21-1..3) and the file sets are unchanged; only the ownership of the work is. Reversal: one builder, the original §7 row.
3. **Two owner-ruled pin moves after B1 reported** (bucket 2, ruled in the orchestrator session 2026-09-28):
   - **The S19 byte-seal is re-pinned by `S21-B3`.** `test_s19_quadrants.gd`'s `FORBIDDEN_FILES` pins `res://game/npc_ship.gd`'s hash; A3's accepted authority cannot be written without that file (it is in B1's §7 set), so the owner took the fast route: B3 updates that one string and its comment, keeps the other three hashes, and discloses the move. **Recorded 2026-09-28 (B3's report, deviation (a)):** the shipped pin is the **finished** tree's hash `a694170c9783b44ed1dd91e07d0632288535eef91ef391f4036ff2ede9b889f7`, because this amendment's own mask item edits the same file again — the interim `728268c53526dd8436c236ba923528bffea123b31ec0237438fc2baaa8ab661a` could not survive it and survives in the pin's own comment as the chain. Reversal: `git revert` B3's commit, or restore the pinned value `de8596b1…81be`.
   - **A3's reach widens (owner: "widen").** B1 fixed the pair through the player's mask alone, leaving NPC-vs-NPC unresolved; the owner ruled the NPC mask widens with it, so A3 now means **any** hull pair. The two rows that move are `test_engine2_npc.gd` (~:401) and `test_s6_heat.gd` (~:236) — both on this list by that ruling — and they are re-pinned to the measured truth in the same change. Reversal: unmask the NPC body and restore both rows.

## 1. The law to read, in order
1. `slices/S21-stability-fixes/SLICE.md` — scope, file sets, carries-forward.
2. `.agents/gen/_state/LOW_BACKLOG.md` — **only the rows §3 names**, by range.
3. The spec extract in §5 below (it is the operative law; the big docs are context).
4. `docs/CONTRACTS.md` §14 (runner sandbox) and §9 — by range, via the top index.

## 2. The owner's request (verbatim)
> "right now the fundamentals are there, it needs a bit of playtesting and a lot
> of new content as right now there isnt much … i want to focus on content,
> bugfixes, playability and feel" (2026-09-27 planning round; pillars A–D all
> ticked, **no new AI art**, playtesting = owner first, external build second).

This wave carries the bugfix pillar. A finding that would change a pin is
bucket 2: report it, leave it, stop that item.

## 3. What is already measured (file:line)
| Row | Measured | Site |
|---|---|---|
| L18 | station boot writes the dev profile (market band + `last_band`) | `ui/screens/station.gd` normalisation |
| L122 | AUCTION shelf draws+stamps at boot (`enter_pane` from `_ready`) | `ui/station/auction_panel.gd:145,164-171` |
| L22 | hull body is layer 2/mask 1 — ship-vs-ship never resolves | `player_ship.gd`/`npc_ship.gd` monitors |
| L23 | the 5-min wreck window dies with the flight scene on transition | `game/game.gd:_drop_cargo_at_wreck`, `game/pickup.gd:31` |
| L24 | the hull flies the frames between death and respawn (`_switch_ship_off` only) | `game/game.gd:2522`, `player_ship.gd:1568` |
| L73 | `respawn(now)`'s `now` never reaches `_yield_multiplier` (reads `Clock.now()`) | `game/asteroid_field.gd:153,212,444` |
| L90/L93 | 4 engine2 fixtures are live-profile-coupled (433/4 vs 437/0) | `tests/test_engine2_dock.gd:31,204`, `test_engine2_fixes.gd`, `test_engine2_wiring.gd:243-246` |
| L110/L124 | `module_count` can't sum an instance bag; `_base_id` degrades the strip | `autoload/player_profile.gd:362-374`, `ui/station/outfitting_panel.gd:1295` |
| L114 | hull row never disabled for an owned hull (`disabled = false`) | `ui/station/auction_panel.gd:667-679` |
| L130 | a 1-unit ammo sale nets 0 (the 10 CR floor eats the gross) | `game/exchange.gd:376-388` |
| L131 | auto-load burns the last unit's ≤9-round overshoot | `autoload/player_profile.gd:350-375` |
| L136 | LAUNCH summary reads the pack store, counts 6 weapons | `ui/station/launch_panel.gd:523-533` |
| L150 | heat-decay accumulator is scene-scoped; every crossing discards it | `game/game.gd:215,307-309,2112-2129` |
| L152/L153 | gate jump uncancellable (`cancel_jump` dead code); no-funds refusal silent | `game/gate.gd:142-165`, `game/game.gd:747-780` |
| L154 | stale `_transit_destination` survives an interrupted crossing | `game/game.gd:215,329-335,832-840` |
| L176 | `MOVED ·  · B2` names the barrel after the record write | `ui/station/armory_panel.gd:2051` |
| L215 | `setup` never resets `_cleave_child` (latent infinite split) | `game/asteroid.gd:247,289` |
| L61/L237 | `test_weapon_fx_f4.gd` prints `[PASS]` over a dead assertion | `tests/test_weapon_fx_f4.gd:172-179` |
| L243 | `CTX_DIRECTION` spelled twice, nothing asserts equality | `player_state.gd` vs `damage.gd:56` |
| L229 | probes booted the live profile twice (T-93 class) | `tests/probe_s18_*` precedent — every new probe goes scratch |

## 4. Pinned interface (verbatim) + rules that fix every ambiguity

The seams being modified (signatures stand; bodies are yours to read):

```gdscript
# game/game.gd:2522 — the death entry that gains a real dead state
func _on_ship_died() -> void:
# game/game.gd:2630 — the respawn route the wreck must survive
func _respawn_docked() -> void:
# game/pickup.gd:100 — collection; Pickup.setup gains a lifetime argument (L23's clean seam)
func _collect() -> void:
# game/asteroid_field.gd:153 — now must reach the yield roll (L73)
func respawn(now: int = -1) -> void:   # signature shape per the row; read the file
# game/gate.gd:142-150 — the dead-code cancel that becomes live (L152)
func cancel_jump() -> void:
# autoload/player_profile.gd:368 — the accessor law (L110)
func module_count(base_id: StringName) -> int:
```

Rules:
1. **Restore, don't redesign.** Every fix lands the behaviour the cited doc
   already pins; where a value is new it is one of R-S21-1..3 and nothing else.
2. **One accessor law for bags** (A5): either `module_count` sums instances or
   every caller reads `instances_of` — pick one, state it in the report, keep
   `test_p2b1_outfitting_panel.gd` green.
3. **Death is a state, not a switch-off**: from `died` to the respawn route the
   hull takes no input, applies no force/torque, and its contact monitor charges
   nothing (18 §7's flow is unchanged).
4. **Crash damage is 18 §2.1 row 15, verbatim**: `damage = 0.5 · mass · Δv² ·
   factor` to **both** sides past the existing low threshold; one side (the
   heavier, tie = the initiator) charges both halves so the pair can never
   double-charge (L22's ram-authority shape).
5. **Probes are scratch or they don't run** (L229): `XDG_DATA_HOME=$(mktemp -d)`
   or a repointed `PlayerProfile.save_path` flushed before restore (L17's rule).

## 5. Spec extract (verbatim, cited)
`18_engine_spec.md` §2 (table row 7):
> "**Death: cargo drops.** Cargo spawns as pickups at the wreck with a 5-minute recovery window; hull/fit follow 14 §3 insurance."

`18_engine_spec.md` §7:
> "**Death:** hull 0 → explosion → the wreck spawns with cargo pickups (5-min recovery window; see §2.7), then the 14 §3 flow: respawn docked at the last station visited, insurance decides what comes back, mercy clause once per profile, heat persists."

`18_engine_spec.md` §2.1 (rows 15-16):
> "**Crash damage, always.** Every body-body impact past a low threshold deals kinetic damage to both sides: `damage = 0.5 · mass · Δv² · factor`."
> "**Push physics, all of it.** Recoil on every shot, impact knockback (40 % of remaining kinetic energy), explosion shockwaves with `I(d) = P₀ / (1 + d²)` over a 0.2 s window."

`11_galactic_map.md` §2:
> "Flying into the ring opens a confirm prompt: **JUMP TO <SECTOR> — <fee> CR**. Pay, 2 s charge-up FX, arrive at the destination sector's gate."
> "Sector transition resets asteroids/pickups (fields respawn per 02 §8), keeps the hold, hull and heat."

`13_heat_bounty.md` §2:
> "Decay: **−1 per minute of play**, anywhere. Heat cools by itself; hunters make "lie low" an active choice, not a timeout."

`05_exchange.md` §5:
> "**2 % of each sale, minimum 10 CR per transaction**, rounded up."

`01_economy_core.md` §3:
> "| S4 | Enemy wreck drops that are pure credit caches (rare) | Flat amounts | 06 §5 |"

`01_economy_core.md` + `10_ship_acquisition.md` **2026-09-27 P3 blocks**: rows
**R-S21-1** (ammo sales skip the floor — proposed, tick M2), **R-S21-2** (pack
round remainder — proposed, tick M3), **R-S21-3** (owned hull row shows an
`OWNED` plate — proposed, tick M1).

## 6. Acceptance list (numbered; the report answers each with a cite)
- **A1 (death state, L24):** from `died` until the respawn route lands, the hull
  is inert — no input, no forces, no contact damage, and the explosion/wreck
  order is exactly §7's. Proven by a probe over the death frames.
- **A2 (wreck window, L23):** a wreck's cargo pickups keep their 5-minute window
  (`DROP_WINDOW` 300 s) across a sector transition and the respawn route; the
  `Pickup.setup` lifetime seam carries it. Proven with a fake-clock probe.
- **A3 (crash damage, L22):** ship-vs-ship contacts resolve; both halves take
  row-15 damage exactly once per impact (no double-charge), rocks/other bodies
  unchanged.
- **A4 (profile hygiene, L18/L122/L154):** booting the station writes nothing to
  `user://` (market normalise at dock; the shelf rolls at pane switch); a stale
  `_transit_destination` cannot survive an interrupted crossing (cleared on
  `_exit_tree` / non-game route target). Proven by profile md5 before/after a
  boot-only run.
- **A5 (hermetic gate, L90/L93):** the four fixtures build their own fit and read
  slot order from `_state.weapons`; the gate reports one count on live and
  scratch `user://`.
- **A6 (bag reads, L110/L124):** one accessor law (rule 2) with the instance-bag
  and stacked cases measured; a fitted instance with a missing bag record still
  renders one battery row (the `_base_id` fallback).
- **A7 (money edges, L130/L131/L136):** R-S21-1 and R-S21-2 land as written
  (ticks M2/M3 default PROPOSED); LAUNCH's summary reads the hold's units and
  counts the fit's real weapons.
- **A8 (owned hull row, L114):** R-S21-3 as written (tick M1).
- **A9 (world-sim, L73/L150/L152/L153/L215/L176):** `respawn(now)` threads `now`
  into the yield roll; the heat accumulator survives scene rebuilds (13 §2's
  "anywhere"); `cancel_jump()` fires on zone-exit/damage/death and the prompt
  ladder gains `GATE REFUSED — NOT ENOUGH CR`; `setup` resets `_cleave_child`;
  the armory `MOVED` line names the barrel.
- **A10 (harness, L61/L237/L243):** `test_weapon_fx_f4.gd`'s dead assertion runs
  (re-ordered, proven by one temporary value flip) and one assert row pins
  `PlayerState.CTX_DIRECTION == Damage.CTX_DIRECTION`.
- **A11 (summary):** every new const tabled with value + reversal; `damage.gd`
  byte-identical; no gate row outside §8's list moved.

## 7. Worker table (three builders — amendment 2026-09-28)
Every builder carries the same `VAJB_WORKER_FILES` as the original row; the split is
by **region and acceptance subset**, not by file set. Run order is **B1 → B2 →
B3 → R1 → F1** — strictly sequential, each writing on its predecessor's output.

| ID | Role | Acceptance subset | Regions it owns (nobody else edits these) | Deliverable |
|---|---|---|---|---|
| S21-B1 | coder (builder) | A1, A2, A3, A4b (the sticky route flag), A9a (heat), A9b (gate) | `game/game.gd`, `game/player_ship.gd`, `game/npc_ship.gd`, `game/pickup.gd`, `game/gate.gd` | A1/A2/A3/A4b/A9a/A9b landed + their rows in `tests/test_s21_stability.gd` + `S21-B1_report.md` |
| S21-B2 | coder (builder) | A4a (boot writes nothing), A5, A6, A7, A8 | `ui/screens/station.gd`, `ui/station/auction_panel.gd`, `ui/station/launch_panel.gd`, `ui/station/fitting_panel.gd` (B2's report (b): L124's site today; the brief's §3 row still quotes the older `outfitting_panel.gd` path), `autoload/player_profile.gd`, `game/exchange.gd`, `tests/test_engine2_dock.gd`, `tests/test_engine2_fixes.gd`, `tests/test_engine2_wiring.gd` | those five items landed + their rows in `tests/test_s21_stability.gd` + `S21-B2_report.md` |
| S21-B3 | coder (builder) | A9c (asteroids), A9d (the `MOVED` line), A10, A11 + the two owner-ruled pin moves (amendment 3) | `game/asteroid_field.gd`, `game/asteroid.gd`, `ui/station/armory_panel.gd`, `game/npc_ship.gd` (the mask only), `tests/test_weapon_fx_f4.gd`, `tests/test_s19_quadrants.gd`, `tests/test_engine2_npc.gd`, `tests/test_s6_heat.gd` | those items landed + their rows + the whole `tests/test_s21_stability.gd` green + `S21-B3_report.md` |
| S21-R1 | reviewer | grades **A1–A11 across all three reports** | `vajb-orbit/tests/`, `vajb-orbit/tools/`, `docs/CONTRACTS.md`, its report | `S21-R1_review.md` + CONTRACTS §9/§10 rows + LOW rows |
| S21-F1 | fixer (only on HIGH/MED) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S21-stability-fixes/` | `S21-F1_report.md` |

## 8. Run order + the tests that move
**B1 → B2 → B3 → R1 → F1 only on HIGH/MED.** Each builder ends with one gate run
on a fresh scratch store and records its own `[SUMMARY]` line; the close-out's two
hermetic gate runs measure the finished tree. A builder who finds a defect in
another's region **reports it and leaves it** (it rides that region's builder, or
R1's LOW rows). Expected gate growth: **+ `test_s21_stability.gd`
rows (one per AC)** and `test_s19_quadrants.gd` +1 (A10's assert); `test_weapon_fx_f4.gd`
keeps its count (the dead row only starts executing). Candidate rows that could
move and their verdicts:

| Suite | Why it is a candidate | Verdict |
|---|---|---|
| `test_engine2_dock.gd`, `test_engine2_fixes.gd`, `test_engine2_wiring.gd` | A5's fixture rework | counts unchanged (rows rebuilt, not removed) |
| `test_p2b1_outfitting_panel.gd` | A6's accessor law | unchanged by construction |
| `test_p1_market.gd`, `test_s3_auction.gd`, `test_p2b_services.gd` | A7/A8 money edges | unchanged (asserts read pinned prices) |
| `test_engine2_fixes.gd` respawn rows, `test_s13_mining_batteries.gd` | A9's fixes | unchanged |
| `test_weapon_fx_f4.gd` | A10 re-order | same `[PASS]` count, the dead row now executes |
| `test_s19_quadrants.gd` | A10's assert row **and** amendment 3's byte-seal re-pin | +1 row (A10); the seal row stays, its `npc_ship.gd` string moves |
| `test_engine2_npc.gd`, `test_s6_heat.gd` | amendment 3's NPC-mask widening | 1 row each, re-pinned to the measured truth (counts unchanged) |
| `test_s5_ammo_cargo.gd`, `test_s5_commerce.gd` | **Missed at brief time, added by S21-F1 (2026-09-29) per L246 (S21-B2/F1):** R-S21-1 moved the ammo rows' pinned fee/paid (`test_s5_ammo_cargo.gd:465-489` 10→1, 50→59; `:538-544` 50→59, 46→55) and R-S21-3 the auction helper's action plate (`test_s5_commerce.gd:493-497`, `BUY`→`OWNED` iff owned) | counts unchanged; the values are correct as built, so this is a list amendment, never a revert |

Any other suite count moving is a **bucket-2 pause**: report it, leave it, stop.

## 9. Hard rules
- Docs are read-only (the amendments are landed); a wrong number is reported,
  never edited. `--forbidden` at verify: `docs/`,
  `vajb-orbit/project.godot`, `vajb-orbit/addons/`, `vajb-orbit/game/damage.gd`.
- Bounded Godot runs (`--quit-after`), self-quit probes, scratch `XDG_DATA_HOME`
  per run (rule 5); shell edits are forbidden (hook gap) — edit tools only.
- Signals travel UP, calls travel DOWN; cross-file scripts by preload path.

## 10. Staged / deferred
- L168/L244 (repair figure), L169 (magazine model), L242 (spill) → S22 (ticks
  M4/M5/M7). L57 → D15. The T-93 systemic write guard stays owner-gated.

## 11. Owner tick list (unticked ⇒ the PROPOSED value ships)
| Tick | Row | Question | PROPOSED |
|---|---|---|---|
| M1 | R-S21-3 | owned hull row: `OWNED` plate or the press-refusal? | `OWNED` plate |
| M2 | R-S21-1 | ammo sales skip the 10 CR floor? | yes |
| M3 | R-S21-2 | packs split the last unit (round remainder)? | yes |

## 12. Close-out (the orchestrator)
1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s21_start --forbidden
   vajb-orbit/project.godot docs/ vajb-orbit/addons/ vajb-orbit/game/damage.gd
   --tests --expect-reports .agents/gen/slices/S21-stability-fixes/S21-B1_report.md
   .agents/gen/slices/S21-stability-fixes/S21-B2_report.md
   .agents/gen/slices/S21-stability-fixes/S21-B3_report.md
   .agents/gen/slices/S21-stability-fixes/S21-R1_review.md`
3. WAVEBOARD + `dispatch_coder.md` one-liners; `MASTER_REPORT.md` §6 recap.
4. Wave-boundary commit.
