---
slice: S6
phase: n/a (engine slice 3 = Travel, merged with RPG P3)
lane: code
status: draft
gate_baseline: "578/0 (S5 close; D6 rides parallel and may move it — the brief records S6's working baseline at its snapshot)"
---

# S6 — Travel (engine slice 3 + RPG P3)

## Goal
The player can leave a sector three ways (jump gate, border corridor, death),
cross a living map (derelicts, anomalies, beacons), be hunted for crime
(hunters, bounties, gate/dock refusal), and profit from kills (loot tables,
wreck sites, credit caches) — the whole P3 loop, playable end to end.

## In scope
- Jump gates + fee composition (11 §2.1 + §5), border corridors (11 §2.2 + §5)
- POIs: derelicts (scan channel + roll), anomalies (three kinds + rift drain),
  beacons (soft-fog reveal) — `game/gate.gd`, `game/corridor.gd`, `game/poi.gd`
  (engine §14's named files) + scanner reveal in `sector.gd`
- Sector transitions via the `loading` route (11 §2.3: fields/pickups reset,
  hold/hull/heat persist)
- Heat enforcement (13 §7): witness-gated gains, decay, `pay_bounty`, hunter
  wings, trader panic, gate/dock refusal
- Loot (06 §8): `game/loot_tables.gd`, the drop-roll, wreck sites, credit caches

## Out of scope
- **All of `ui/hud/**`** — every readout rides the frozen `set_prompt` seam (§7
  pin); D6 owns that directory until it closes
- Bosses/arena hooks and affix application (slice 4 / item 13)
- The station turret entity (13 §7 tick 7: staged unless the owner ticks it in)
- Insurance, contracts, vaults (P4); crafting (07, design-gated)
- Faction standing changes from hunters (12 §4 is P4; heat is the only dial here)

## Acceptance criteria
- [ ] AC1 — gates: fee formula reproduces 11 §2.1's examples (adjacent 250, two
      away 350) and §5's multipliers; Outlaw refused with no profile write
- [ ] AC2 — corridors: 15 s presence transitions to the named neighbour; exit
      resets; hull damage does not (tick 2's rule as built)
- [ ] AC3 — POIs: derelict scan roll 40/35/25 over 10 000 rolls ±2 pp; anomaly
      three kinds with the Hollows rift weighting; rift drains at `RIFT_DRAIN`
- [ ] AC4 — transitions: through `loading`, fields/pickups reset, hold/hull/heat
      byte-equal across the crossing
- [ ] AC5 — heat: witness-gated gains (0 without a witness), −1/min decay, fine
      = heat × 25 zeroing that faction's heat, refusals at Outlaw
- [ ] AC6 — hunters: Wanted spawns 2–3 on sector entry; Outlaw respawns 60 s;
      per-faction isolation (Concord hunts only Concord's outlaw)
- [ ] AC7 — loot: `LootTables` reproduces 06 §3's expected hauls ±5 % and the
      grade caps assert at load; wreck sites despawn at 90 s

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S6-K0 | `docs/,vajb-orbit/tests/,vajb-orbit/tools/` | `S6_BRIEF.md` |
| S6-K1 | `game/sector_registry.gd,game/gate.gd,game/corridor.gd,game/game.gd,game/sector.gd,tests/` | `S6_BRIEF.md` |
| S6-K2 | `game/poi.gd,game/loot_tables.gd,game/sector.gd,game/game.gd,tests/` | `S6_BRIEF.md` |
| S6-K3 | `game/npc_registry.gd,game/npc_brain.gd,game/npc_ship.gd,autoload/player_profile.gd,game/game.gd,game/station_catalog.gd,ui/station/launch_panel.gd,tests/` | `S6_BRIEF.md` |
| S6-R1 | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S6_BRIEF.md` |
| S6-F1 | union of K1–K3 sets + `docs/CONTRACTS.md` | `S6_BRIEF.md` |

## References
- `docs/CONTRACTS.md` §19 (this wave's pin), §6 (Sector/SectorRegistry base), §7
  (the frozen `set_prompt` seam), §8.1/§8.2 (the damage/NPC seams it wraps)
- `docs/gameplay/11_galactic_map.md` (incl. §5), `13_heat_bounty.md` (incl. §7),
  `06_loot_drops.md` (incl. §8), `01_economy_core.md` §5.2
- `docs/gameplay/18_engine_spec.md` §14 slice 3 (deliverable line — owner-locked,
  read-only), `docs/gameplay/17_coder_handoff.md` §2/§4/§5 (file map, one-timer,
  transaction law)

## Carries forward
- L130–L140 (S5's LOW rows) ride this wave's fixer if cheap; otherwise next
- The §15 test-checklist contradiction (owner-locked homework) — not this wave
