# S6_prompts — dispatch blocks (worker prompts live here; the owner never pastes them)

Model for every worker: `deepseek/deepseek-v4-flash` (owner instruction
2026-09-22; `opencode-go/deepseek-v4.1-flash` is broken). Run from the workspace
root. Reports: `slices/S6-travel/<WorkerID>_report.md`, review `S6-R1_review.md`.
Gate/probe convention: `source ~/.profile && godot --headless --path vajb-orbit
res://tests/headless_runner.tscn --quit-after 1200` — and **every probe/gate
runs against a scratch store** (`XDG_DATA_HOME` or repointed `save_path`; T-93
class). Editor reimports only in quiet windows between the parallel D6 lane's
runs; one editor session.

**Run order: K0 → (K1 ∥ K2 ∥ K3) → R1 → (F1 only on HIGH/MED).** K1 lands
`game.gd`/`sector.gd` seams first; K2 appends before K3 (shared files, ordered).

**Parallel with designer item 7 (D6):** this wave writes `game/**`,
`autoload/player_profile.gd`, `tests/test_s6_*.gd` only. D6 holds `ui/hud/**`,
`assets/**`, `staging/**`, `asset-library/**`, `tests/test_d6_*.gd`. Touch
nothing else; **never `ui/hud/`** — every readout rides `set_prompt`.

## Before the first dispatch (one line)

```bash
cd "$VAJB_WORKSPACE" && python3 staging/verify_wave.py snapshot --name s6_start && git add -A && git commit -m "Record the pre-wave state before the travel wave"
```

## S6-K0 — docs drift check

```bash
VAJB_WORKER_FILES="docs/,vajb-orbit/tests/,vajb-orbit/tools/" crush run "You are worker S6-K0 on the Vajb Orbit workspace (wave S6, brief .agents/gen/slices/S6-travel/S6_BRIEF.md — read it fully, then docs/CONTRACTS.md §19/§6/§7, docs/gameplay/11_galactic_map.md §2/§3/§5, 13_heat_bounty.md §2-§5/§7, 06_loot_drops.md §2-§5/§8, 17_coder_handoff.md §2/§4/§5). Task: read the pinned set against the tree as it stands (D6 runs in parallel and holds ui/hud + assets — its churn is not drift) and report every contradiction, stale line or missing seam the wave will touch. In particular: confirm no station turret entity exists (13 §7 tick 7), confirm the kill seam game/projectile.gd:_shot_down and the transition surface the loading route expects, and check the §19 names against 17 §2's file map. Invent no numbers and fix nothing: deliver .agents/gen/slices/S6-travel/S6-K0_report.md with findings at file:line and their escalation bucket. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S6-K1 — travel core (registry rows, gates, corridors, transitions)

```bash
VAJB_WORKER_FILES="vajb-orbit/game/sector_registry.gd,vajb-orbit/game/gate.gd,vajb-orbit/game/corridor.gd,vajb-orbit/game/game.gd,vajb-orbit/game/sector.gd,vajb-orbit/tests/" crush run "You are worker S6-K1 on the Vajb Orbit workspace (wave S6, brief .agents/gen/slices/S6-travel/S6_BRIEF.md — read it fully, then docs/CONTRACTS.md §19 and docs/gameplay/11_galactic_map.md §2/§5). Task: the travel core exactly as §19 pins. (1) SectorRegistry rows gain neighbours/gate_links (the 1-2-3-4-5-6-7 spine) and corridors, plus GATE_FEE_BASE 150 / GATE_FEE_PER_SECTOR 100 / CORRIDOR_DEPTH 600. (2) game/gate.gd: the fee formula floor((150 + 100*d) x want x lawless) with want 1.5 at Wanted only and lawless 2.0 into sector 7 — reproduce 11 §2.1's worked rows (adjacent 250, two away 350) and §5's 562 row; jump() returns 0/-1 refused (Outlaw, writes nothing)/-2 funds, charges via PlayerProfile transaction law, 2 s charge-up, then the loading transition. (3) game/corridor.gd: 15 s presence hold, exit resets, hull damage does NOT (11 §5 tick 2 as built). (4) Sector transitions through the loading route: fields/pickups reset, hold/hull/heat persist byte-equal (11 §2.3). You own game.gd and sector.gd FIRST in the parallel run: land the seam hooks §19 names (_on_kill, _transition, _poi_table) so K2/K3 can append cleanly, and do not stub their bodies beyond neutral returns. NO ui/hud writes — the gate prompt rides set_prompt (§19's rule). Add ONLY tests/test_s6_travel.gd (the fee worked rows, refusal-write-nothing byte proof, corridor presence/reset, transition persistence). Report .agents/gen/slices/S6-travel/S6-K1_report.md with measured numbers. Hard rules in the brief apply; scratch stores only." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S6-K2 — POIs + loot (after K1's seams; appends before K3)

```bash
VAJB_WORKER_FILES="vajb-orbit/game/poi.gd,vajb-orbit/game/loot_tables.gd,vajb-orbit/game/sector.gd,vajb-orbit/game/game.gd,vajb-orbit/tests/" crush run "You are worker S6-K2 on the Vajb Orbit workspace (wave S6, brief .agents/gen/slices/S6-travel/S6_BRIEF.md — read it fully, then docs/CONTRACTS.md §19, docs/gameplay/11_galactic_map.md §3/§5, docs/gameplay/06_loot_drops.md §2-§5/§8). Task: POIs and loot exactly as §19 pins. (1) game/poi.gd: derelicts (5 s interruptible scan channel, roll 0.40 cache / 0.35 data core / 0.25 magic module per 11 §3.1, one-shot per respawn cycle), anomalies (three kinds at 200 u per 11 §3.2: ore_bloom T+1 cluster of 10 rocks at 2x yield, grave_cache 3-5 pickups one grade up, void_rift draining RIFT_DRAIN 12 shield/s with the T4 exotic and 0.10 magic+ module), beacons (reveal the sector's unscanned POIs). The Hollows rolls rift at 2x weight. (2) game/loot_tables.gd: TABLES = 06 §3.1-§3.4 verbatim, HUNTER_EXTRA = 06 §8's proposed comp_elec table, roll() = 06 §2's procedure with one pickup per unit and caches last and distinct. (3) Scanner soft fog in sector.gd's blips() per 11 §5's mapping (POIs appear once scanned or beacon-revealed; gates and stations always). (4) The kill path in game.gd (K1's _on_kill seam) spawns the wreck site with WRECK_PICKUP_LIFETIME 90 s. WorldClock is the only respawn clock (17 §4). NO ui/hud writes — the scan readout and cache feed ride set_prompt. Add ONLY tests/test_s6_poi_loot.gd (derelict roll over 10000 seeded rolls within 2 pp, anomaly kinds + Hollows weighting + rift drain rate, expected hauls 06 §6 ±5 %, grade caps at load, wreck 90 s despawn). Report .agents/gen/slices/S6-travel/S6-K2_report.md with measured numbers. Hard rules in the brief apply; scratch stores only." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S6-K3 — heat + hunters + bounty (after K2; appends to the shared files last)

```bash
VAJB_WORKER_FILES="vajb-orbit/game/heat.gd,vajb-orbit/game/npc_registry.gd,vajb-orbit/game/npc_brain.gd,vajb-orbit/game/npc_ship.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/game.gd,vajb-orbit/tests/" crush run "You are worker S6-K3 on the Vajb Orbit workspace (wave S6, brief .agents/gen/slices/S6-travel/S6_BRIEF.md — read it fully, then docs/CONTRACTS.md §19, docs/gameplay/13_heat_bounty.md §2-§5/§7). Task: heat enforcement and hunters exactly as §19 pins, appending to game.gd's seams after K2. (1) Witness-gated gains: heat only when a neutral/patrol hull or station sits inside WITNESS_RANGE 900.0 (= ShipStats.BASE_SCAN_RANGE) with the brain's rock-blocking LOS; values come from the existing heat_on_kill() verbatim (+15 trader, +25 patrol, +25 turret-attack, +5 witness extra, -3 pirate) — never re-derive. (2) Decay -1 per minute of play time on the shared clock (no new Timer nodes). (3) PlayerProfile.pay_bounty(faction_id): fine = heat x 25 CR, all-or-nothing per 17 §5, one BOUNTY economy-log line, zeroes that faction's heat; refusals (zero heat, insufficient funds) write nothing. (4) Hunters per-faction per 13 §3: Wanted spawns randi_range(2,3) on next sector entry with the hull map of tick 6 as built (fighter for light/mid players, gunship for heavy), Outlaw perma-tails with 60 s respawn after the wave dies, that faction's space only; hunters drop their band table plus HUNTER_EXTRA. (5) Enforcement: Outlaw dock refusal and gate refusal (writes nothing), trader flee at Suspect+ (the brain's Flee state), patrol scan-on-sight at Suspect+. Station turret: the +25 lands on attacking a station; turret aggro is staged (K0 confirms no entity exists). NO ui/hud writes. Add ONLY tests/test_s6_heat.gd (witness gating 0-without-witness proof, decay rate, fine math incl. 13 §2's 40-heat = 1000 CR row, hunter spawn/respawn/per-faction isolation, every refusal's byte-identical profile). Report .agents/gen/slices/S6-travel/S6-K3_report.md with measured numbers. Hard rules in the brief apply; scratch stores only." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S6-R1 — mandatory review (after K1–K3 report)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md" crush run "You are worker S6-R1, the mandatory reviewer of wave S6 (brief .agents/gen/slices/S6-travel/S6_BRIEF.md; diff findings against docs/CONTRACTS.md §19 and docs/gameplay/11 §2/§3/§5, 13 §2-§5/§7, 06 §2-§5/§8 — never against the brief). Re-measure everything yourself: the fee formula's worked rows (250/350/562) by independent computation; the corridor presence/reset rules by probe; transition persistence byte-equal across the crossing; the derelict roll distribution over 10000 seeded rolls; the anomaly kinds, Hollows rift weighting and rift drain rate; the loot expected hauls vs 06 §6's sums and the grade caps; the witness gate (0 heat without a witness, exact values with one), decay, fine math, hunter spawn/60 s respawn/per-faction isolation; every refusal path's byte-identical profile. Probe the K1↔K2↔K3 seam joins in game.gd and sector.gd by measurement (the W8 method: re-run the builders' own probes byte-identically). No frozen file moved and no ui/hud/asset write happened (staging/verify_wave.py verify --baseline s6_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/gameplay/08_ship_slots_modules.md --tests, the S4-corrected flag form). Gate twice on scratch stores. Tier findings HIGH/MED/LOW with file:line and measured evidence. Write .agents/gen/slices/S6-travel/S6-R1_review.md, append LOW rows to .agents/gen/_state/LOW_BACKLOG.md (next free ids), update docs/CONTRACTS.md §9/§10 measured notes (sequenced after D6's close-out pass). Never fix. Bounded probes only." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S6-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="vajb-orbit/game/sector_registry.gd,vajb-orbit/game/gate.gd,vajb-orbit/game/corridor.gd,vajb-orbit/game/game.gd,vajb-orbit/game/sector.gd,vajb-orbit/game/poi.gd,vajb-orbit/game/loot_tables.gd,vajb-orbit/game/heat.gd,vajb-orbit/game/npc_registry.gd,vajb-orbit/game/npc_brain.gd,vajb-orbit/game/npc_ship.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,docs/CONTRACTS.md" crush run "You are worker S6-F1, the fixer of wave S6 (brief .agents/gen/slices/S6-travel/S6_BRIEF.md; review .agents/gen/slices/S6-travel/S6-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no balance changes. Re-run the gate twice on scratch stores and report .agents/gen/slices/S6-travel/S6-F1_report.md with a finding-by-finding disposition and the gate lines." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```
