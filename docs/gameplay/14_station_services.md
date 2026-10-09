# 14 — Station Services: Contracts, Insurance, Storage, Boss Arenas, Escorts

**Status:** Ready to code.
**Depends on:** 01 (ledger/sinks), 05 (exchange), 08–10 (ships), 11 (map),
12 (factions), 13 (heat).
**Consumed by:** station UI amendments; game-scene spawns (convoy, arena).

---

## 1. The station as a service deck

The station gains a **SERVICES** rail entry beside the existing modules.
Every service below is a panel under it; availability and price multipliers
come from the owning faction (12 §2). One station per faction is the
"capital" offering the full menu; outposts offer a subset (§8).

| Service | Concord capital | Meridian capital | Choir capital |
|---------|-----------------|------------------|---------------|
| Contracts board | ✔ | ✔ (best rates) | ✔ |
| Refuel / recharge | ✔ | ✔ | ✔ (2026-09-20: every station; free and instant, no CR charged; owner ruling 2026-09-21) |
| Insurance | ✔ (cheapest) | ✔ | ✖ (the Choir does not believe in accidents) |
| Storage rental | ✔ | ✔ (largest vaults) | ✔ |
| Boss arena contract | ✖ | ✔ (expedition desk) | ✔ (rite of the Choir) |
| Bounty payment (13 §2) | ✔ | ✔ | ✔ |

## 2. Contracts board

Data-driven job list; new jobs roll on the 20-minute station clock.

| Type | Example | Reward shape |
|------|---------|--------------|
| **Haul** | "40× `ingot_titanium` to S4 outpost" | spot value ×1.25 + 300 CR, faction standing +2 |
| **Hunt** | "Destroy 5 pirates in S2" | 800 CR + loot as normal, +1 standing per kill extra |
| **Gather** | "20× `mineral_cobalt` ore (raw)" | ×1.4 ore value, +2 standing |
| **Escort** (§6) | "Protect convoy 7 to S4 gate" | 1 200 CR, +5 standing |
| **Expedition** (§7) | arena contract | arena payout, +3 standing |

Rules:

- **Faction-tied:** every contract belongs to a faction; rewards use that
  faction's demand biases so hauling to Meridian pays differently than to
  the Choir (12 §3).
- **No instant-fail timers in v1** except escort (its timer is the convoy's
  hull). Haul/gather contracts have no deadline; they occupy **cargo or
  standing slots** (max 3 active contracts) instead.
- Materials delivered for a contract come from the hold as normal; the
  board pays *over* the exchange's buy price (that's the point) but locks
  the goods at accept-time (escrow: quantity reserved from the manifest,
  removable by cancelling for a 100 CR fee).
- Standing gates (12 §4.1): Shunned players see no contracts; Outlaws see
  none either. Redemption must precede employment.

## 3. Insurance

Death in space is now expensive — but opt-in expensive.

- **Premium:** flat per class, charged at launch, covers **one** hull loss
  (ship + installed modules at full value):

| Hull class | Premium per launch |
|------------|-------------------:|
| Fighter | 200 |
| Cutter | 250 |
| Delver / Trader / Corvette | 300 |
| Hauler / Gunship | 400 |
| Frigate | 500 |
| Destroyer | 700 |

  A Cutter's premium is ≈1.4 % of its list price — a real line item, never
  a punishment. Champion standing multiplies the premium ×0.8 (12 §4.1).
  The Choir sells no insurance at all (their stations bet on you dying).
- **Uninsured loss:** hull and **all installed modules** are gone. The
  standard fit courtesy (09 §7) does not apply to replacements.
- **One-death rule:** the payout covers one loss; the policy does not renew
  mid-flight. A Destroyer run with a 700 CR premium is a real decision.
- **Payout flow:** on death you respawn docked at the last station visited
  in a *base* hull of your class tier's cheapest ship, minus anything
  uninsured. Insurance pays the hull+fit back into your dock. (The starter
  Lancer is never fully losable: if you have no other hull, the Concord
  reissues a bare Fighter — mercy clause, once per profile.)
- Heat (13) is unaffected by death — no crime laundering.

## 4. Storage rental

- Stations rent hold space: **one vault per station, 20 units base,
  +20 per upgrade tier** (tiers 1–3: 500 / 1 200 / 2 400 CR one-off per
  station).
- **Meridian's `u_vault` tech (15 §2):** their stations rent 40-unit vaults
  and the rental tiers cost 25 % more (they know what a vault is worth).
- The vault holds any cargo type (ore, ingots, components); deposits and
  withdrawals are free; **contents persist per-station** (the vault is
  furniture, not a pocket — hauling your own hoard between stations is a
  hauler-fleet gameplay loop).
- Vault contents do **not** count against cargo on launch.
- Purpose: enables bulk trading runs (buy low across sessions), hoarding
  exotic ore for crafting (07), and a permanent credit/material sink. It is
  the quiet hero of the economy.

## 5. Boss arenas (visible, contracted, repeatable)

- Each arena is a **physical place**: a marked, barricaded zone in its
  sector (S3: "The Boneyard" — Meridian arena; S6: "The Pyre" — Choir
  arena), visible from any distance as a lit ring of nav pylons. No hidden
  bosses.
- **Contracts, not buttons:** the arena run is a contract type (§2) taken at
  the faction's expedition desk: accept → arena opens (a 60 s window to fly
  there) → boss fight → payout on return-to-station, win or lose.
- Two bosses: **Boneyard Behemoth** (S3, gunship-tier fit, 15 k CR + magic
  module roll) and **The Pyre Hierophant** (S6, frigate-tier fit, 40 k CR +
  guaranteed rare-module roll, 15 §5). The Maw (S7) remains the roaming
  endgame boss with its 06 §3.4 table — three difficulty beats, all visible
  from across the sector.
- Arena cooldown: one run per boss per 20-minute clock (per profile).
- Kill credit requires **you** landing the last hit — escorts and drones
  don't steal your glory.

## 6. Escort contracts

- Spawn point: the accepting station. A **trade convoy** (1 hauler-class AI
  hull + 1–2 fighter escorts) flies a fixed route to a target sector's gate
  at freighter speed.
- Win: convoy hull survives to the gate → payout at destination station.
- Lose: convoy destroyed → no payout, −5 standing, and the pirates who did
  it keep the loot (which you can... recover. Aggressively).
- Pirates ambush at the corridor midpoint (11 §2.2) — the contract literally
  routes through the dangerous part.
- Convoy hulls use the Hauler stats (08 §2) with 50 % of hold filled with
  visible cargo pods; a *pirate player* (13) can hunt convoys as income —
  same system, both directions.

## 7. Bounty payment window

- Any faction station with heat > 0 shows a **PAY BOUNTY** strip in the
  services deck (13 §2 fine math). Paying is a single confirm; the log
  records it like any transaction.

## 8. Outpost subset

Secondary stations (S2 outpost, S4 outpost, S5 shrine) offer: contracts
(their faction's), bounty payment, and vault tier 1. No insurance (fly to a
capital), no arenas. This makes capitals worth the trip and gives outposts
a reason to exist without diluting the service deck.

## 9. What this gives the coder

- `contract_registry`: 5 types × parameterized tables; contracts are
  Resource-style dictionaries like everything else.
- `PlayerProfile` new persisted state: `active_contracts` (max 3),
  `vaults` (`station_id -> {tier, contents}`), `insured: bool`,
  `mercy_used: bool`.
- One 20-minute station clock drives: exchange bands (05), auction rotation
  (10), contract re-roll, arena cooldowns, sector respawn (11) — one timer,
  five consumers.

## 2026-09-27 — P3 wave pins (waves S24/S25) — S24's tick W3 owner-ratified 2026-10-08; S25's J1 still open

### S24 — the nine docking places get names (amends §1/§8)

Service menus stand exactly as §1/§8's matrix. Names and character were not
stated; proposed (tick **W3** covers the whole set) — **owner-ratified
2026-10-08**:

| Place | PROPOSED name | Character (one line) |
|---|---|---|
| S1 primary (Concord capital) | **Halcyon Anchorage** | forge-grey bastion, the full menu |
| S2 primary (Concord) | **Ironworks Depot** | mill-town market floor |
| S2 outpost | **Marchgate Post** | a dock and a vending wall |
| S3 primary (Meridian capital) | **Spanport Meridian** | the merchant's harbour, best contract rates |
| S4 primary (Meridian) | **Ashveil Exchange** | free-port chaos, component prices |
| S4 outpost | **Rimward Depot** | caravan stop |
| S5 primary (Choir) | **Cinder Gate** | incense and plasma scorch |
| S5 shrine (outpost) | **The First Ember** | the Choir's smallest rite |
| S6 primary (Choir capital) | **Emberlight** | cathedral dark, meanest turrets |

Reversal for any name: rename in the registry row.

### S25 — the contracts board (amends §2)

| Row | Change | PROPOSED value | Reversal | Tick |
|---|---|---|---|---|
| R-S25-1 | Board size and the Expedition seam | 6 rows visible per board, re-rolled on §9's 20-minute clock; Haul/Hunt/Gather/Escort ship in S25, **Expedition is a seam row** until S26's arenas | board-size edit | **J1** |

§2's reward shapes, the escrow + 100 CR cancel fee, the max-3 rule and the
standing gates are the operative law and are not amended here.

## 2026-10-08 — S24: the station entity and the nine places (amends §1/§8)

The nine docking places become **rows** in one registry
(`game/station_registry.gd`), the shape `11 §4`'s sector registry uses. A row
carries `id`, `sector` (1–7), `kind` (`primary`/`outpost`), `faction`, the
§1's-2026-09-27 `name` + `character` verbatim (tick W3), the §1/§8 service
matrix below, the owner's multipliers (`12`'s 2026-10-08 V1–V7 block) and the
shelf-bias hook. S7 has no station (`11 §1`: no law, no patrol).

| `id` | Place | Sector | Kind | Faction | §1/§8 services offered |
|---|---|---|---|---|---|
| `s1_primary` | Halcyon Anchorage | 1 | primary | concord | contracts, refuel/recharge, insurance, vaults, bounty (**no arena** — §1) |
| `s2_primary` | Ironworks Depot | 2 | primary | concord | as above |
| `s2_outpost` | Marchgate Post | 2 | outpost | concord | contracts, bounty, vault tier 1 (**§8's three**) |
| `s3_primary` | Spanport Meridian | 3 | primary | meridian | **the full menu** (§1: best contract rates, largest vaults, the expedition desk) |
| `s4_primary` | Ashveil Exchange | 4 | primary | meridian | the full menu |
| `s4_outpost` | Rimward Depot | 4 | outpost | meridian | §8's three |
| `s5_primary` | Cinder Gate | 5 | primary | choir | contracts, refuel/recharge, vaults, arena, bounty (**no insurance** — §1: "the Choir does not believe in accidents") |
| `s5_shrine` | The First Ember | 5 | outpost | choir | §8's three |
| `s6_primary` | Emberlight | 6 | primary | choir | as `s5_primary` |

**Only the primary of a sector spawns today** (`game/sector.gd:_spawn_station`
spawns `densities.stations`, one node). The three outpost rows are accessor- and
test-reachable and their §8 subset is proven there; **spawning an outpost node is
staged** (the per-station POI-flavour item). Reversal: spawn the outpost row as a
second station node with its own dock zone id.

**The docked-station seam.** `PlayerProfile` gains `docked_station` /
`set_docked_station` beside the shipped `docked_faction` (both transient, not save
keys), filed by `game.gd` at dock; the station screen resolves the place through
`StationRegistry.docked_station(profile)`. Reversal: derive the place from the
sector's primary row instead.

**The identity plate lands.** The shell header's plate (`STATION_HUB` §15.5,
`UI_SPEC` §12.4) already ships; S24 fills its two labels — `StationName`
(`HeroTitle`) and `StationLocation` (`StationCaption`) — from the row's
`name`/`character` (`ui/screens/station.tscn:125,131`'s placeholder strings
retire). The SERVICES pane's §15.2–§15.4 panels stay S25/S26's; S24 makes the
**matrix** readable and shows the unavailable state on OVERVIEW block 4's rows
(§15.1 U2's disabled plate + reason caption). Reversal: the placeholder strings
return.

## 2026-10-08 — S28: payouts price in sessions (amends §2/§7)

*(S28's block; ticks M10/M11 owner-ratified green 2026-10-08. 01's 2026-10-08
block owns the law — SC(t) = 1 100 / 1 500 / 3 000 / 6 000.)*

**§7's arena bosses.** 15 000 and 40 000 CR are flat numbers from the
pre-S28 economy: the Pyre's 40 000 read ≈36 sessions of §5.3's own pace. They
re-price as ≈2 × SC of the arena's sector tier:

- **Boneyard Behemoth: 6 000 CR** + the magic module roll (was 15 000).
- **The Pyre Hierophant: 12 000 CR** + the guaranteed rare (was 40 000).
  Reversal: the flat numbers (**M10**). These land with S26 — its brief's
  R-S26-1 extract re-cuts against this block before dispatch.

**§2's flat contract rewards.** Hunt 800 / Escort 1 200 are the T1 values; a
board that pays them in S7 is furniture. Each sector's flat rewards scale
**×SC(t)/SC(1)** by 11 §1's sector tier — Hunt **800 / 1 100 / 2 200 / 4 400**,
Escort **1 200 / 1 600 / 3 300 / 6 500**, rounded to 100 CR (Haul's spot×1.25
and Gather's ×1.4 already scale with the goods). Reversal: flat bases at every
sector (**M11**). These land with S25 — R-S25-1's extract re-cuts likewise.

**§3's insurance premiums stay** the per-class flats (200–700); **M14** holds
the optional 1.5 %-of-list re-derivation (135–1 080) for S26's implementation.

## 2026-10-08 — S38: the board's clock and the hub's cold start (amends §2/§9)

*(S38's block, from the owner's playtest finding verbatim: "there is 20 minute
refresh timer for contrats but i cannot see in real time how much time is left
for refresh and there should be contracts on the start". Ticks **H1–H3**,
PROPOSED until the owner ticks them; each row carries its reversal.)*

**H1 — the hub's cold start.** The main menu's PLAY routes straight to the
station hub (`ui/screens/main_menu.gd:223`), and nothing on that path files the
docked place: only `game.gd:_file_docked_station` (`:1458`, called from the
docking route `:1440`) writes it. Measured on the real scene with a fresh
profile (`vajb-orbit/tests/probe_s38_start_board.tscn`): the profile's
`docked_station()` empty, `StationRegistry.docked_station` `{}`,
`ContractRegistry.board({}, 0)` **0 rows**, the panel reading U8's
`NO OPEN JOBS …` state, and the header plate falling back to the scene's
mockup-era copy (`ui/screens/station.tscn:129` `ORBITAL DRYDOCK KEPLER-9`,
`:135` `DOCKING RING 04 · HELIOS DRIFT · HULL TRAFFIC LOW` — a sector name 11 §1
does not carry).

- **An empty filed id means "no run has filed a place" and nothing else.** A
  sector with no station files its **own sector id** (`game.gd:_file_docked_station`
  writes `_sector_row_id` when the sector has no primary row), so S7 keeps the
  readers' existing no-place fallback and the sentinel cannot be read as a cold
  start.
- **The starting place is the starting sector's primary.** `SectorRegistry` gains
  `DEFAULT_SECTOR_ID := &"sector_1"` — the game scene's own default
  (`game.gd:113 SECTOR_ID_DEFAULT`), moved to the registry that owns sectors,
  with `game.gd` reading it. `StationRegistry` gains
  `starting_station() -> Dictionary` = `primary_for(SectorRegistry.DEFAULT_SECTOR_ID)`,
  and **both** `docked_station` and `docked_station_id` answer it when the
  profile's id is empty, so every reader (the plate, the OVERVIEW service matrix,
  the price law, the vault record, the contracts board) agrees, with no write
  from a screen.
- Measured after: the board reads **6 rows** (first row `haul · 4 500 CR · 40×
  ingot_aluminium to Marchgate Post`) and the plate reads the row's own name and
  character line.
- Reversal: every reader falls back to nothing again and the scene's placeholder
  copy returns (**H1**).

**H2 — the countdown.** The roll is invisible today and nothing re-rolls at the
boundary: `ui/station/contracts_panel.gd` carries no timer and no time readout,
and its board re-derives from `band_index()` only on `_refresh()` (mount and
profile writes). Measured: `WorldClock.BAND_SECONDS` **1200**, `elapsed = now %
1200`, `remaining = 1200 − elapsed` (the probe read `remaining=667`), and the
next band's board differs (`next_roll_differs=true`).

- The U3 header strip's right end carries **`NEW JOBS IN mm:ss`** (the countdown
  at `WorldClock.BAND_SECONDS − now % WorldClock.BAND_SECONDS`, two-digit minutes
  so the maximum reads `20:00`), ticking at **1 Hz** — the refinery panel's own
  `TICK_SECONDS` idiom (`ui/station/refinery_panel.gd:57/250/272`).
- Reversal: the U8 caption alone, no countdown (**H2**).

**H3 — the re-roll at zero.** When the countdown reaches 0 the panel re-rolls its
own board (one `_refresh()`, so the next band's rows appear and the readout
restarts at `20:00`) with no scene change and no player action. Reversal: the
board changes only on the next mount (**H3**).

## 2026-10-10 — S26: the arenas, the bosses, insurance and the vaults (amends §3/§4/§5)

*(S26's block, landed with the wave; gate `1237 → 1258/0` ×2 hermetic. The two
re-pricings it implements — §5's boss payouts at **M10** (6 000 / 12 000) and
§3's premium at **M14** (1.5 % of list, 135–1 080) — are already tabled in the
**2026-10-08 S28 block** above and are owner-ratified green; nothing here
restates them. The rows below are the ones no earlier block carried, each with
its reversal. Ticks **E1** (the three hull rows, 08's P3 block) and **E2** (the
Maw's roam) are **PROPOSED — unticked as of this writing**.)*

**§5's geometry — an arena is a place, and now it has a size.** The ring, its
props and the arena's spawn are new values; `game/npc_registry.gd` owns them and
`game.gd:_build_arena_zone` builds the zone as a sector child.

| Value | Shipped | Site | Reversal |
|---|---|---|---|
| Ring radius | 1 200 u | `npc_registry.gd:ARENA_ZONE_RADIUS` | the sector origin, no ring |
| Ring centre offset | `(0, −2600)` from the sector centre | `:ARENA_ZONE_OFFSET` | the sector centre |
| Nav pylons / barricades | 8 + 8, on the ring | `:ARENA_ZONE_PYLONS`/`:ARENA_ZONE_BARRICADES` | a bare ring |
| Entry window | 60 s | `:ARENA_ENTRY_WINDOW` (§5's own text) | no window |
| Cooldown | 1 200 s (one run per boss per 20-minute clock) | `:ARENA_COOLDOWN_SECONDS` | no clock |
| Arena reward pool | the priced non-exclusive module catalogue | `module_catalog.gd:arena_pool()` | the full catalogue |
| Boss spawn points | the ring centre; The Maw at `(0, −4200)` | `game.gd:_spawn_arena_boss`/`_spawn_maw` | the sector origin |

**§5's E2 — the Maw's roam.** PROPOSED until the owner ticks E2: The Maw
respawns on the 20-minute clock after a death, roams S7's field band at **0.5×
freighter speed** and aggros within **600 u**; its loot rolls 06 §3.4 **flat**
(`loot_tables.gd:MAW_BAND` + `cache_scale_for`, which pins the band's cache
scale at 1.0 so S7's tier-4 ×2.0 multiplier does not inflate the table's
1 025 CR floor / 1 584.75 EV). Reversal: the staged boss row and
`cache_scale(tier)` at the kill site.

**§5's kill credit.** The last hit must be the **player's**: the kill is latched
and only the player's own `hit_landed` consumes it (`game.gd:_on_player_hit`), so
an escort's or a drone's kill never pays. Reversal: pay on the boss's death
whoever fired.

**§3's policy bookkeeping.** The premium is charged **at launch only** (a sector
crossing is not a launch), covers exactly one loss, and the payout replaces into
the tier's cheapest base hull with hull + fit paid back into the dock; the
replacement is gated on the policy being live, so an **uninsured** loss grants no
hull (and a surviving hull keeps its own fit); Champion's ×0.8 reaches the charge
through `station_registry.gd:insurance_multiplier` (S24's seam); Choir sells
none; the mercy clause reissues a bare Fighter **once per profile**. The
per-boss run clock is the new save key `arena_runs`
(`player_profile.gd:arena_ready/arena_mark_run`). Reversal: the pre-fix flow in
`CONTRACTS.md` §28's v0.54 entry.

**§4's vaults.** One vault per station in the shipped `{tier, contents}` record
(20 units base, +20 per tier, tiers 500/1 200/2 400; Meridian 40 units at ×1.25
tier prices), deposits and withdrawals free, contents persistent per station and
**outside launch cargo**; `u_vault` adds +20 to every vault (§5's own row in
`15`). Reversal: the flat 40-unit reading (**T-162** tracks the OVERVIEW row's
disagreement at tier 0).

**§2's seam closes.** `R-S25-1`'s "Expedition is a seam row until S26's arenas"
is now spent: the Expedition row is **live at an arena station** (S3, S6) and
stays the greyed `STAGED` seam everywhere else, so `REASON_STAGED` is reachable
only off an arena. Reversal: leave the row staged (breaks the arena loop).

**Panels.** §15.3's INSURANCE and §15.4's VAULTS panel laws are unchanged by
this wave; **T-161** records that §15.3's premium *rows* still quote the §3
flats the M14 implementation superseded (and the per-row keying question), for
the deck law's next touch.
