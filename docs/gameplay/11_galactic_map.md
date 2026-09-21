# 11 — Galactic Map: Sectors, Travel, and Population

**Status:** Ready to code.
**Depends on:** 02 §5 (sector tier ranges — amended here), 08 §4 (sector-based
content), 12 (faction ownership).
**Consumed by:** 12, 13, 14, 15; the game scene's spawn tables.

---

## 1. The map

Seven sectors. Each has an owner (12), a tier band (mineral mix, enemy
mix), and its own population of asteroids, anomalies, wrecks and stations.
The player always knows which sector they are in (HUD sector label already
exists).

| # | Sector | Owner | Tier band | Feel |
|---|--------|-------|-----------|------|
| 1 | Halcyon Reach | Concord of Iron | T1 | home space. Patrols frequent, pirates rare, prices fair |
| 2 | Iron Marches | Concord of Iron | T1–T2 | industrial belt. Heavy traffic, first escorts run here |
| 3 | Meridian Span | Meridian Free Ports | T2 | trade crossroads. Richest stations, softest laws |
| 4 | Ashveil Expanse | Meridian Free Ports | T2–T3 | contested edge. Pirates work the fringes |
| 5 | Cinder Verge | Ember Choir | T3 | exotic territory. Strange rocks, stranger prices |
| 6 | The Hollows | Ember Choir | T3–T4 | deep exotic belt. Every rock is guarded |
| 7 | Maw Belt | unaligned (12 §2) | T4 | no law, no patrol, the arena, the Maw |

**One arena size.** Every sector is the same size (`SECTOR_SIZE`, ENGINE_SPEC
§13) with the same layout budget — fields, wrecks, anomalies, beacons, gates,
station(s) near centre. Sectors are differentiated by backdrop/palette, owner,
the tier mix in §1.1, enemy mix and density, and hazards, **never by size**
(ENGINE_SPEC §2 decision 4, §8). The per-sector tier table in §1.1 stays
authoritative.

**Nebula gas clouds (2026-09-20, 18_engine_spec §8 / ruling 25).** The hazard
set gains the nebula gas cloud: 0–2 per sector as a registry row, a
desaturated blue-grey/teal wash (STYLE_BIBLE §7.2 — no new palette) that
tints hulls inside and **degrades radar and locks**: passive tags inside
refresh slowly and a lock channel cannot complete while its line crosses the
cloud. Escaping into a cloud breaks an enemy's channel — cover is a tactic.
Pricing/placement stay engine-side; no station or gate rule changes.

### 1.1 Amendment to 02 §5

The abstract range table in 02 §5 is superseded by these per-sector tier
mixes (weights follow 02 §5's shape):

| Sector | T1 | T2 | T3 | T4 |
|--------|---:|---:|---:|---:|
| 1 | 100 | — | — | — |
| 2 | 55 | 45 | — | — |
| 3 | 20 | 80 | — | — |
| 4 | — | 60 | 40 | — |
| 5 | — | 35 | 65 | — |
| 6 | — | — | 55 | 45 |
| 7 | — | — | 40 | 60 |

## 2. Travel: two ways out of every sector

### 2.1 Jump gates (the fast way)

- Every inhabited sector has a **gate structure** near its primary station —
  a large ring, visible from across the sector, marked on the minimap.
- Flying into the ring opens a confirm prompt: **JUMP TO <SECTOR> —
  <fee> CR**. Pay, 2 s charge-up FX, arrive at the destination sector's gate.
- **Fee: 150 CR base + 100 CR per sector of distance** (adjacent = 250,
  two away = 350, …). Dead-head jumps into lawless space cost ×2 (the only
  gate that goes to sector 7 is a Meridian "expedition gate" that charges
  for the privilege).
- Gates are faction infrastructure: 13's outlaw heat tier refuses gate use
  in that faction's space.

### 2.2 Flying by hand (the slow way)

- Each sector has 1–2 **border corridors** (map-edge zones marked by
  nav buoys). Holding course in a corridor for 15 s transitions to the
  neighbouring sector — free, but the corridor is where pirates ambush and
  where your scanner matters.
- Manual flight is how a broke player moves; gates are how everyone else
  does. The fee is deliberately cheap enough to never gate progress and
  real enough to appear in the session ledger (01 §5.2 gets a new line:
  travel, 0–500 CR).

### 2.3 Rules

- No fuel mechanic in v1: the gate fee *is* the fuel cost.
- Sector transition resets asteroids/pickups (fields respawn per 02 §8),
  keeps the hold, hull and heat.
- The player can only jump to **adjacent sectors by hand-corridor**; gates
  connect 1↔2↔3↔4↔5↔6↔7 linearly in v1 (one spine, no shortcuts — the map
  stays a ladder so tier progression is geographic).

## 3. Making space not empty

Per-sector population targets (spawn densities, not hard counts):

| Feature | Density rule | What it is |
|---------|--------------|------------|
| Asteroid fields | 4–8 per sector | per 02 §5/§8 |
| Wreck fields | 1–3 per sector | 3–6 non-interactive hulks + 1 **scannable derelict** (§3.1) |
| Anomalies | 1–2 per sector | §3.2 |
| Nav beacons | 1 per corridor + 1 per gate | flight aids; scanning one reveals its sector's POIs (§3.3) |
| Stations | 1 primary + 0–1 outpost | per 14 §2 |
| Pirates | per 13 §4 / 18_engine_spec §13 | the risk tax |
| Patrols | Concord/Meridian/Choir space only | ambience + heat enforcement (13 §3) |
| Trade convoys | 1 active per inhabited sector | escort contract targets (14 §6) |

### 3.1 Derelicts (scannable wrecks)

- One per wreck field. Requires any C-slot scanner (or the Deep Scanner's
  legacy effect) at close range: a 5 s scan channel, interruptible.
- Reward: one roll — 40 % a small ore/component cache (already specced
  pickup types), 35 % a data core (03 `comp_elec` + credits), 25 % a
  **magic-rarity module** (15 §5). Derelicts are one-shot per respawn cycle
  (sector re-rolls them on the 20-minute clock).
- This is what makes `c_scanner` worth a slot outside combat.

### 3.2 Anomalies

- Visible as a shimmering distortion; flying within 200 units triggers a
  one-roll event, then the anomaly despawns (respawns on the sector clock):
  - **Ore bloom** — spawns a rich T+1 asteroid cluster (10 rocks, 2× yield).
  - **Grave cache** — 3–5 pickups: components one grade above the sector band.
  - **Void rift** — pure hazard + prize: drains shields slowly inside, holds
    1 exotic pickup (T4 ore or a rare affix module at 10 %) at its heart.
- Anomalies are the "slightly different economy" flavour of space itself:
  the Hollows' anomalies are twice as likely to roll the rift.

### 3.3 Scanning and the minimap

- The minimap gains three blip classes: friendly (stations, gates,
  beacons), neutral (derelicts, convoys, anomalies when scanned), hostile
  (pirates, hunters — existing behaviour).
- **POI reveal:** beacons and the scanner computer reveal unscanned POIs in
  the current sector. Fog of war stays *soft* in v1: nothing is hidden that
  matters, but unexplored sectors show only stations and gates until the
  player visits or scans. This keeps the map readable and the scanner
  useful without building a full FOW system.

## 4. What this gives the coder

- One `sector_registry` data table: id, name, owner faction, tier weights
  (§1.1), neighbours, gate links, spawn densities.
- Spawn tables reference the existing catalogues (02, 03) — nothing new to
  balance except densities and the anomaly roll table (§3.2).
- The gate fee and travel lines slot into the 01 §5.2 ledger shape (which
  now carries travel and insurance lines); a typical 250–500 CR of
  gate fees plus the flat insurance premium lowers net income ≈10–15 %,
  which is intentional (the original ledger was tuned rich).
