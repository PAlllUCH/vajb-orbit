---
slice: S7
phase: n/a (engine slice 4's affix half = RPG P4's affix application)
lane: code
status: prepared (queued as dispatch_coder.md item 13; READY)
gate_baseline: "674/0 (S6 close; D7 rides parallel — its mid-wave hud.gd edit currently fails 6 rows in its own held files, see WAVEBOARD in-flight note)"
---

# S7 — Affix application (15 §9.3's staged wave, slice 4's affix half)

## Goal
The stored, named, priced, displayed affixes of S3 actually fly: every fitted
instance's prefixes bend the ship's resolved stats and its own barrel, five suffixes
hook the systems S6 shipped, and the inert `ShipStats.damage_mult` gets its delivery
seam — with five suffixes honestly staged where no system exists.

## In scope
- `Affixes.summary` / `PlayerProfile.affix_summary` (the bridge) + the optional
  `affixes` parameter on `ShipFit.resolve` (CONTRACTS §20)
- All twelve §3 prefixes: ship-stat ones inside `resolve` (Sturdy, Vigilant,
  Lightened, Tempered, Wideband, Surefire, Deep-hold), per-barrel ones through
  `PlayerState.weapon_affixes` (Keen, Rapid, Frugal's fractional `ammo_frac` bank),
  Spry through `ShipStats.booster_cooldown_mult`
- The `damage_mult` delivery wiring (computers' pinned-but-inert +damage goes live)
- Five suffixes: Whale (resolve), Embers (`_deliver`), Leeches (`_on_npc_died`),
  Cartograph (`Sector.reveal_pois` at entry), Ledger (`sell_price` ×1.25)
- Three new suites `tests/test_s7_{affixes,weapon_affixes,suffixes}.gd`

## Out of scope
- **All of `ui/**`, `assets/**`, `staging/**`** — D7 holds them until it closes; a
  display that "needs" a widget is a report, not a write
- **`project.godot`, `docs/gameplay/18_engine_spec.md`** (owner-locked), and any
  `docs/` write beyond K0's disposition pass and R1's §9/§10 measured notes
- The five staged suffixes' hooks (Overflowing, Silence, Vault, Choir/Concord/Ports)
- Quadrants/directional armour (18 §4.5) and bosses/arena (14 §5) — slice 4's
  remaining items, queued beyond this wave
- Faction stations/arenas (12 §5/14 §5, P4) and crafting rolls (07)

## Acceptance criteria
- [ ] AC1 — summary: a fit of mixed instances yields §20's dict (per-prefix magnitudes
      with the stored signs, suffix flags collected once, **one `instances` row per
      fitted instance**); `{}`/standard-fit resolve is byte-identical to pre-S7
      (re-assert a pre-S7 fixture's full stats)
- [ ] AC2 — ship-stat prefixes: worked rows off §20's table (e.g. Sturdy 0.15 on a
      `shield_add: 200` shield = +30 pool before the 3× clamp; Vigilant/Wideband pick
      the best instance's own ×(1+Σ); Tempered joins the summed engine delta under
      1.40; Lightened never crosses 0; Deep-hold adds its units) — every band
      maximum still respects09 §5's clamps
- [ ] AC3 — per-barrel: a two-laser battery Keen in cell 2 only → barrel 2 ×(1+value),
      barrel 1 byte-identical; Rapid divides that barrel's interval; Frugal's bank
      spends exactly `floor(shots × (1+Σ))` integer rounds (20 shots at −0.15 → 17)
- [ ] AC4 — `damage_mult`: a `damage_add: 0.15` computer fitted → delivered damage
      ×1.15 measured at the sink, exactly once, at each of K0's five sites (beam,
      projectile, the two chips, the ram); no computer → byte-identical; a null stats
      argument is a no-op, never a crash
- [ ] AC5 — Spry: afterburner cooldown 8.0 → 6.8 with −0.15 fitted
- [ ] AC6 — suffixes: Whale +50 pre-clamp; Embers heals 10 % of dealt to an NPC sink
      only (both deliveries); Leeches +5 % hull through `_on_npc_died`; Cartograph
      entry-reveals the sector; Ledger sells a 900-cost Common at 675 (540 ×1.25)
      through all three production sites
- [ ] AC7 — staged: Overflowing/Silence/Vault/faction-three rows resolve and price
      byte-identically with them fitted (a test proves the no-op)
- [ ] AC8 — gate `674 + the three new suites, 0 failed`, twice on scratch stores;
      live store untouched; `verify_wave.py verify --baseline s7_start` clean against
      the forbidden set; zero writes outside the S7 sets

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S7-K0 | `vajb-orbit/tests/,vajb-orbit/tools/` (report only; the orchestrator applies its dispositions to §20 before K1) | `S7_BRIEF.md` |
| S7-K1 | `vajb-orbit/game/affixes.gd,vajb-orbit/game/ship_fit.gd,vajb-orbit/game/ship_stats.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | `S7_BRIEF.md` |
| S7-K2 | `vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/game/game.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/game/player_state.gd,vajb-orbit/game/affixes.gd,vajb-orbit/tests/` | `S7_BRIEF.md` |
| S7-K3 | `vajb-orbit/game/game.gd,vajb-orbit/game/sector.gd,vajb-orbit/game/auction.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | `S7_BRIEF.md` |
| S7-R1 | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S7_BRIEF.md` |
| S7-F1 | union of K1–K3 sets + `docs/CONTRACTS.md` | `S7_BRIEF.md` |

## References
- `docs/CONTRACTS.md` §20 (this wave's pin), §15/§16/§11 (the base pins), §2/§3
  (the signatures §20 amends additively), §9 (the gate)
- `docs/gameplay/15_module_affixes.md` §1/§3/§4/§6/§9.3/§10, `09_ship_slots_modules.md`
  §5 (+ §3.4/§3.7 read through §20's table), `06_loot_drops.md` (Leeches' kill seam
  context), `11_galactic_map.md` §3.3 (Cartograph's reveal), `13_heat_bounty.md` §3
  (Silence's missing mechanic), `17_coder_handoff.md` §2 (one owner per file)
- `docs/gameplay/18_engine_spec.md` §14 slice 4's "affix effects (15) flowing into
  `ShipStats`" (deliverable line — owner-locked, read-only)

## Carries forward
- L150–L157 (S6's LOW rows) ride this wave's fixer if cheap; next free LOW id
  **L158**, next free ticket **T-94**
- Owner tick stacks from earlier waves are untouched by this wave (see WAVEBOARD)
- S3's remaining eight owner ticks (brief §Owner ticks notes which ones S7 does not
  depend on — none of them gate the build)
