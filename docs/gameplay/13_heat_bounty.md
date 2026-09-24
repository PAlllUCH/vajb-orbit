# 13 — Heat, Bounties and Hunters

**Status:** Ready to code.
**Depends on:** 11 (sectors), 12 (factions, standing).
**Consumed by:** patrols, hunter spawns, gate/dock refusal.

---

## 1. The loop in one breath

Crime is a **per-faction resource**, not a flag. Killing innocents in a
faction's space earns *heat* with that faction; heat spawns bounty hunters;
killing pirates and paying fines burn heat down. Heat and standing (12 §4)
are two dials on the same relationship: standing is your *reputation*
(slow, commercial), heat is your *wanted level* (fast, violent).

## 2. Heat mechanics

- One heat value per faction: **0–100**, persisted (`PlayerProfile.heat`).
- Gains (only in the victim faction's territory):

| Crime | Heat |
|-------|------|
| Kill a trader or freighter (neutral hull) | +15 |
| Kill a patrol ship | +25 |
| Kill a station-turret | +25 |
| Witness survives (any crime) | +5 extra — loose ends matter |

- Decay: **−1 per minute of play**, anywhere. Heat cools by itself; hunters
  make "lie low" an active choice, not a timeout.
- Reduction (the redemption path):
  - Kill a pirate in that faction's space: **−3** per kill (capped at floor
    0; pirates never forgive themselves).
  - **Pay the bounty** at any of that faction's stations: `fine = heat ×
    25 CR` (so 40 heat costs 1 000 CR). Paying zeroes heat instantly.
    Outlaws (12 §4.1) cannot dock to pay — that is the trap that makes the
    pirates' own space attractive.

## 3. Heat tiers and enforcement

| Tier | Heat | Effect |
|------|------|--------|
| Clean | 0–19 | nothing; patrols ignore you |
| Suspect | 20–49 | patrols scan you on sight (slow, breakable line-of-sight check); traders flee from you |
| Wanted | 50–79 | **bounty hunter wing** spawns on your next sector entry (2–3 hunter hulls, fighter band, tuned to your class tier); gate fees +50 % |
| Outlaw | 80–100 | hunters perma-tail you in that faction's space (respawn 60 s after a wave dies); denied docking (12 §4.1); gates refuse you (11 §2.3) |

- Hunter waves are **per-faction**: outlaw of the Concord? Concord space
  hunts you; Meridian still sells you missiles. The political chessboard
  from 12 §4 is enforced here.
- **Hunters drop loot** like pirates of their band (06 tables) plus their
  `comp_elec`-weighted table — killing your pursuers is *profitable*, which
  is the fun trap: going full outlaw is a viable (dangerous, poor-rep)
  playstyle, and 12 §4's standing bands keep it from being strictly better
  than honesty.

## 4. Pirates (the grindable crime)

- Pirates exist per-sector per 11 §3's spawn rules; their density
  multiplies by tier band (S1 rare, S7 swarming).
- Per-sector NPC counts (the density shape's numbers live in
  18_engine_spec §13): S1 0–1 · S2 1–2 · S3 2–3 · S4 3–4 · S5 3–5 ·
  S6 4–6 · S7 6–8, patrols only in owned space, one convoy per inhabited
  sector.
- Killing pirates in faction X's space: +1 standing, −3 heat with X. This
  is the intended "honest income" loop of the fighter lifestyle: pirate
  hunting pays loot (06), standing and heat-clearing.
- Pirates do **not** respect faction borders; their heat effects are nil
  (they are already everyone's enemy).

## 5. Enforcement details (for the coder)

- **Witness rule:** heat gains only fire if a neutral/patrol ship (or
  station turret) has line-of-sight within scan range when the kill lands.
  Solo kills in dead space are free. This rewards planning and makes the
  scanner computer defensively useful.
- **Trader panic:** neutral traders in the sector gain `flee` behaviour
  while your Suspect+ tier is active — killing fleeing traders is slower
  (they run) but nobody said crime was efficient.
- **Station turrets:** stations defend themselves; attacking one is an
  instant +25 and turret aggro until you leave scan range. The Choir's
  stations have the meanest turrets (their tech identity).
- Persistence: heat and standing both save with the profile; death does
  **not** clear heat (14 §4's insurance handles death costs; crime is not
  laundered by dying).

## 6. Balance hooks

- Hunter wave budget: hunters use the 09 §6 reference-fit math for their
  class tier — a Wanted-tier player in a Cutter faces fighter-band hunters
  they can beat; an Obliterator draws gunship-band wings. Escalation is
  automatic by fit value, not by cruelty.
- Fine math check: at the 01 §5.3 net of ≈1 200 CR/session, a full
  Suspect→pay cycle (≈40 heat = 1 000 CR) costs about one session of
  profit. Crime should feel *expensive but survivable*; if playtests show
  outlaw runs out-earning miners, heat gains +50 % before touching the fine
  rate.

## 7. Amendment 2026-09-24 (wave S6 — the enforcement pin)

Wiring rules for §2/§3/§5 where they needed a seam or a number. The heat
plumbing already exists (`PlayerProfile.heat()`, `NpcRegistry.heat_tier()`,
`NpcShip.heat_on_kill()`); this wave adds enforcement + hunters. CONTRACTS §19.

- **Witness rule (§5):** the witness scan range is `WITNESS_RANGE := 900.0` =
  `ShipFit.BASE_SCAN_RANGE` (the only scan range in the tree — **derived**,
  not proposed; the constant lives on `ShipFit`, `game/ship_fit.gd:40`, and
  `ShipStats` carries only the per-instance `scan_range`). LOS is the NPC brain's
  own rock-blocking check. A crime with
  no witness inside range adds nothing.
- **Gain bound:** heat is clamped to **0–100** per faction on every gain (§2's
  bound, unimplemented before this wave).
- **Decay (§2):** −1/minute of **play time**, accrued by a float play-time
  accumulator on the game scene's own tick (`game.gd`, seconds in play; no Timer
  node — 17 §4's one-timer rule; `WorldClock` stays the station-band clock and
  keeps its five consumers), floored at 0.
- **Pay the bounty (§2):** `PlayerProfile.pay_bounty(faction_id) -> bool`
  (17 §5 transaction law; one `BOUNTY` economy-log line). Surface: a
  `PAY BOUNTY (n CR)` row in LAUNCH beside the REFUEL/RECHARGE rows (owner-ratified
  set growth 2026-09-24: `ui/station/launch_panel.gd` + a
  `StationCatalog.SERVICES` row join this wave's write set; reversal: REPAIRS'
  action column). Owner tick 5. Shown for the docked station's faction
  whenever heat > 0 for it; Outlaws never see it (they cannot dock).
- **Hunter wing (§3/§6):** spawns on the next sector entry while Wanted, and
  perma-tails while Outlaw (60 s respawn after a wave dies, that faction's
  space only). Size `randi_range(2, 3)`. Hull = one band below the player's
  active hull: **proposed map** — player `ship_fighter`/`ship_interceptor`/
  `ship_patrol`/`ship_miner` → `ship_fighter`; `ship_vanguard`/`ship_trader`/
  `ship_corvette` → `ship_fighter` (elite fit); `ship_gunship`/
  `ship_destroyer`/`ship_freighter` → `ship_gunship`. Fit = the 09 §6
  reference fit of the player's class tier (§6). Reversal: always `ship_fighter`
  ×2–3 (§3's literal reading). Owner tick 6. The archetype row flips off
  `SEAM_SLICE_4`; `KEY_TIER` stays 1 (test-pinned) and the hull map lives in
  `KEY_MEMBERS`; aggro/scan radius `900.0` (**proposed** — the pirate fighter
  band's own radius, `game/npc_registry.gd:220`; reversal 1200.0).
- **Enforcement points:** **dock refusal reads standing** (`PlayerProfile.standing()
  <= -51`, 12 §4.1's Outlaw band), **gate refusal reads the heat tier**
  (`NpcRegistry.heat_tier() == &"outlaw"`, 13 §3 / 11 §2.3) — two axes, each from
  its own doc, both writing nothing; trader `flee` (Suspect+, the brain's existing
  Flee state), patrol scan-on-sight (Suspect+, slow breakable LOS check = the
  brain's Scan state), station turret: the +25 heat and aggro stand, but no turret
  entity is spawned in the tree (the archetype row is `SPAWN_STATION` and has no
  consumer) and a station has no damage sink — the +25 lands on attacking a station
  and turret aggro is **staged** (reversal: ship the turret
  as a station-attached NPC). Owner tick 7.
