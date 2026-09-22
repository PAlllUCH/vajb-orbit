# 15 — Module Affixes: Common, Magic, Rare

**Status:** Ready to code.
**Depends on:** 09 (module catalogue, tiers), 10 (auction rotation), 12
(faction exclusives), 14 §5 (arena rare rolls), 11 §3.1 (derelict rolls).
**Consumed by:** module inventory, fitting panel, auction shelf.

---

## 1. The rarity contract (user decision, ARPG-shaped)

Every module instance rolls 0–2 affixes:

| Rarity | Affixes | Example |
|--------|---------|---------|
| **Common** | 0 prefix / 0 suffix | Light Shield — plain catalogue stats |
| **Magic** | 1 prefix / 1 suffix | Sturdy Light Shield of the Whale |
| **Rare** | 2 prefixes / 2 suffixes | Vigilant Keen Light Shield of the Choir of Vigilance |

- **Prefixes = stat modifiers** (§3); **suffixes = identity/named perks**
  (§4). Both roll from the module's own family so a shield never rolls
  "+cargo".
- **Rarity multiplies value:** Common ×1.0, Magic ×1.6, Rare ×2.6 (applied
  to the 09 list price; the auction's hot-slot −20 % applies after).
- The 09 catalogue stat blocks are **Common stats** — the baseline every
  affix modifies. Tiers (I–III) and rarities are orthogonal axes: a Rare
  Tier I can out-price a Common Tier II; that's the fun.

## 2. Where each rarity comes from

| Source | Common | Magic | Rare |
|--------|--------|-------|------|
| Auction purchase | 65 % | 30 % | 5 % |
| Shipyard build (10 §3) | 100 % | — | — (building is reliable, not lucky) |
| Enemy/hunter drops (06) | 70 % | 25 % | 5 % |
| Boss/arena rewards (14 §5) | 20 % | 40 % | 40 % |
| Derelict roll (11 §3.1) | — | 75 % | 25 % |
| Crafting (07, later) | 40 % | 45 % | 15 % |

Faction exclusives (12 §5): `w_proton` and friends **only spawn at faction
stations** — but any of their rarity rolls. The proton missile you covet may
be a plain Common or a named Rare; hunting the good roll is endgame.

## 3. Prefixes (stat modifiers)

Roll values within a band by tier: T1 modules roll low, T3 roll high
(values shown as T1/T2/T3). Exactly 1 (Magic) or 2 (Rare) prefixes; the two
prefixes of a Rare must be **different properties**.

| Prefix | Applies to | Effect | Value band |
|--------|-----------|--------|-----------|
| Sturdy | shields | +pool | +10/+15/+20 % |
| Vigilant | shields | +regen | +15/+25/+35 % |
| Keen | weapons | +damage | +8/+12/+16 % |
| Rapid | weapons | +fire rate | +8/+12/+16 % |
| Frugal | weapons | −ammo consumption | −15/−20/−25 % |
| Lightened | armour | −speed penalty (multiplicative) | −4/−6/−8 pp |
| Tempered | engines | +speed | +5/+8/+12 % |
| Overflowing | power | +output | +1/+1/+2 |
| Wideband | computers | +scanner | +15/+20/+25 % |
| Surefire | computers | +damage (same family as Keen, for C slots) | +5/+8/+10 % |
| Spry | boosters | −cooldown | −15/−20/−25 % |
| Deep-hold | utility | +cargo | +5/+8/+12 units |

## 4. Suffixes (named perks — the personality)

One line each, always the same perk for the same name. 1 (Magic) or 2
(Rare); a Rare's two suffixes must differ. Suffixes are **binary boons**,
never numbers — they are the memorable part of a drop.

| Suffix | Perk | flavour |
|--------|------|---------|
| of the Whale | +50 max hull structure | |
| of Embers | 10 % of damage dealt returns as shield | Choir-flavoured |
| of the Ledger | sell value +25 % | Meridian-flavoured |
| of Silence | hunters take 2× time to detect you (13 §3) | outlaw's friend |
| of the Cartograph | reveals sector POIs without scanning (11 §3.3) | explorer's friend |
| of Leeches | kills restore 5 % hull | aggressive sustain |
| of the Vault | cargo spill on death −50 % (insurance-adjacent) | cautious soul |
| of the Choir | +1 power output | only rolls in Choir space |
| of the Concord | +5 % armour effect | only rolls in Concord space |
| of the Ports | +10 % booster duration | only rolls in Meridian space |

Faction-bound suffixes only roll at that faction's stations/arenas — a light
mechanical reason to shop the whole map (12 §4's chessboard, again).

## 5. Faction exclusives (the 15 §2 promise, fulfilled)

| Module | Faction | Rarity floor |
|--------|---------|--------------|
| `w_proton` — proton missile launcher | Choir | Magic+ |
| `w_flak` — flak battery (anti-drone/anti-swarm cone) | Concord | Magic+ |
| `u_vault` — expanded station vault access (14 §4: +20 units all vaults) | Meridian | Magic+ |

Exclusives never spawn Common; their floor is Magic, their ceiling is Rare
with the faction suffix. This is the "proton missiles only in one faction"
rule the map was built to deliver.

## 6. Rules and edge cases

- **Affixes roll at creation** (drop/purchase/build), never re-roll: a
  module is an *item instance*, not a catalogue row. The module inventory
  (10 §6) stores per-instance records `{base_id, rarity, prefixes[],
  suffixes[]}`; catalogue modules (09) remain the shared stat source.
- **Refitting respects instances:** the fitting panel shows the full rolled
  name and stat line; two "Light Shields" can differ.
- **Power draw never changes with rarity** — affixes bend the good stats,
  never the budget. Keeps 09 §4's arithmetic stable.
- **Sell value:** base × rarity multiplier × 60 % (10 §2.3's rule, now
  rarity-aware). A rare module is genuinely worth selling when it doesn't
  fit your build.
- **No rerolls, no sockets, no crafting-of-affixes in v1** — 07 §4 already
  holds those questions for the crafting pass. Affix inflation is the
  thing we do NOT want; the multipliers in §1/§2 are the whole economy of
  rarity.

**Note 2026-09-22 (P2-B proper): affixes are the next wave.** This wave's
fitting surface aggregates the module inventory **by module id** (`OWNED ×<n>`,
STATION_HUB.md §5.3) and stores base ids: the per-instance records of this
section's first bullet (`{base_id, rarity, prefixes[], suffixes[]}`) are not
created yet, and no roll happens at purchase or drop. The ripple this defers is
the one pinned above: a fit may later store a 15 §6 instance id, which §11's
`set_fit_slot` already tolerates. Reversal: none owed; the instance shape is
this document's own.

## 7. Naming grammar (for UI text)

`[Prefix1] [Prefix2] <Module Name> of <Suffix1> of <Suffix2>` — e.g.
**Vigilant Keen Heavy Shield of Embers**. Common modules show their plain
09 name. The grammar is fixed; the UI panel spec will lay out the two-line
stat block (base stats + affix lines) when the fitting screen is designed.

---

## 8. Amendment 2026-09-22 (S3 — instances ship with the AUCTION)

Dated numbers for the wave that implements §1–§7; each carries its reversal.

- **Instance identity.** A module instance is `{instance_id, base_id, rarity,
  prefixes[], suffixes[]}` (§6's own shape) with `instance_id` = `mod_%04d` from
  one per-profile counter. Fits may hold `instance_id` values;
  `set_fit_slot`/`fit_module_at` already tolerate them (§6's note).
  **Reversal:** fits store base ids again; `instance_id` remains the inventory key.
- **Save v6.** `modules` becomes `instance_id -> record`; a fit cell stores the
  `instance_id`. The v5→v6 migration turns each `{base_id, count}` record into
  `count` **Common** instances (no affixes — v5 stock was never rolled),
  idempotently, in the P2-B flag-day pattern. **Owner tick (proposed):** Common is
  the honest default; the fun alternative (retro-roll v5 stock through its source
  table) is one function call at migration. **Reversal:** v6→v5 is lossy —
  collapses to base ids and drops affixes; restore the v5 saver to roll back.
- **Roll timing.** A roll happens when an instance is **created**: enemy drops at
  the drop (§2's 70/25/5), auction modules when the shelf is **drawn at restock**
  (§2's 65/30/5 — the rolled name and price are visible on the shelf, which is
  what "hunting the good roll" means; §2's "Auction purchase" row reads as the
  listing roll), derelict/arena at their own rolls when those systems ship.
  Shipyard builds stay always-Common (§2). Rolls read the global RNG; outcomes
  persist in the record and never re-roll (§6); tests seed the RNG first.
  **Reversal:** roll-at-purchase is one flag for the auction.
- **Faction lots (interim).** §5's exclusives (`w_proton`, `w_flak`, `u_vault`)
  need faction stations (12 §5), which do not exist yet. Until they ship, every
  auction shelf carries **one tagged F LOT** — one of the three exclusives, rolled
  at its Magic+ floor (§5). Gate: `AUCTION_FACTION_LOTS_INTERIM := true`.
  **Reversal:** set false and the exclusives wait for faction stations.
- **Sell value.** §6's `base × rarity multiplier × 60 %` is the auction's sell
  side too (10 §2.3's garage-sale rule, rarity-aware).
