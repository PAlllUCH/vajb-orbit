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
stations** — but their rarity rolls span the whole legal range for an exclusive.
Their **floor is Magic** (§5: "Exclusives never spawn Common"), so the proton missile
you covet is never plain: it is a named Magic or a named Rare, and hunting the good
roll is endgame. Until faction stations exist (§8's interim) the auction shelf carries
one tagged `F LOT` of them. *(Corrected 2026-09-22, S3 docs pass: this paragraph used
to read "any of their rarity rolls … may be a plain Common", which §5 and §8
contradict. Reversal: restore the sentence and §9.2's split becomes moot.)*

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

---

## 9. Amendment 2026-09-22 (S3 docs pass — the three exclusives' rows, the F lot)

§5 names three exclusives and §8 makes every auction shelf carry one tagged `F LOT` of
them, but no document gave them a catalogue row: measured before this pass, none of the
three exists in `game/module_catalog.gd` and none has an asset. This section is the
missing content, written by the developer session because the wave cannot be built
without it. **Every value below is proposed by the planner (no price table for these
three exists anywhere), each carries its reversal, and the block as a whole is one
owner tick.**

### 9.1 The rows (proposed)

| Module | Slot | Tier | Draw | Effect | Cost |
|---|---|---|---|---|---|
| `w_proton` | `weapons` | III | 3 | none — no weapon row carries an `effects` dict | 5 200 |
| `w_flak` | `weapons` | III | 3 | none, as above | 5 200 |
| `u_vault` | `utility` | III | 0 | `{&"vault_add": 20}` (§5's own words: "+20 units all vaults") | 4 500 |

Derivations, so each reversal is one edit:

- **Slot** is the id-prefix law the whole catalogue keeps (`w_` weapons, `u_` utility).
- **Tier III** is the faction's top line: 12 §5 calls each exclusive its faction's own,
  and §5 gives them a Rare ceiling.
- **Draw and cost are the family's own tier-III top line** — weapons 3 / 5 200
  (`w_railgun`, 09 §3.1) and utility 0 / 4 500 (`u_holds`, 09 §3.6). The two weapons
  therefore share a price, which is what "the family's top price" means.
- **Icons** use two existing files, so `assets/` stays frozen: both weapons take
  `res://assets/icons/module/icon_module_w_railgun.svg` (16 §3: "`w_proton`/`w_flak`/
  `w_railgun` share family silhouettes") and `u_vault` takes
  `res://assets/icons/service/icon_service_vault.svg` — the same reuse precedent
  STATION_HUB §7.1 records for its two chrome gaps.
- **`u_vault` is a module here and a station technology in 14 §4, and both are true:**
  the row is the U-slot item a player buys and fits (`vault_add: 20`), while 14 §4's
  40-unit Meridian vaults are those stations' own furniture. 14 §4 is not amended.
- **Behaviour:** the two weapons have **no `weapons.gd` `FAMILIES` entry**, so a fitted
  one fires nothing yet — the status the catalogue's `u_refine`, `u_drones` and
  `c_ewar` rows already ship with. Their firing behaviour is a weapon-family pass, not
  S3's (owner tick).

**Reversal:** drop the three rows from `module_catalog.gd` (one table) and set
`AUCTION_FACTION_LOTS_INTERIM := false`; the exclusives then wait for faction stations.

### 9.2 The F lot's rarity split (proposed)

§8 pins "one of the three exclusives, rolled at its Magic+ floor" but §2's auction row
(65/30/5) bans Common for an exclusive and renormalises to no pair. Proposed: **Magic
85 % / Rare 15 %** — §2's own 30:5 ratio renormalised over the two rarities that are
legal for an exclusive (30/35 = 85.7 %, 5/35 = 14.3 %). **Reversal:** one constant pair;
§8's own flag turns the whole lot off.

### 9.3 What an affix does in S3, and what it does not

Affixes are **rolled, stored, priced, named (§7) and displayed** — the two-line stat
block (base stats plus one line per affix) in FITTING's hover per STATION_HUB §5.3.
**No affix changes a flight stat in S3.** That is the pin's own arithmetic (CONTRACTS
§15): a fit cell stores the instance id and `resolved_fit` / `fit_legal` read through
the base id, so the launch path stays byte-identically the base module it always was.
Applying `+10..20 % pool`, `+8..16 % damage` or `−15..25 % ammo consumption` means
teaching `game.gd`'s fit→flight bridge and the weapon-stat families those keys — files
in no S3 worker set. That work is the **staged affix-application wave** (owner tick).

The same rule covers §4's ten suffixes: all ten roll, are named and show their perk
line; **none is applied**, which is what keeps §6's sell formula (`base × rarity × 60 %`)
exactly as pinned while `of the Ledger` reads "+25 % sell value" on the stat line. The
five perks with no system at all (`of Embers`, `of Leeches`, `of Silence`, `of the
Cartograph`, `of the Vault`) are the same shape as §2's crafting, derelict and arena
roll sources: content that ships with no caller until its system does.

**Reversal:** each applied perk is one hook in the affix-application wave; nothing here
has to be undone to add them.
