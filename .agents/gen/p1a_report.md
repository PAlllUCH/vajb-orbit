# P1a report — mineral + component catalogues

Worker: coder. Status: **done**. Deliverables: exactly two new files, nothing else touched.

## Deliverables

| File | Lines | Contents |
|---|---|---|
| `vajb-orbit/game/mineral_catalog.gd` | 331 | `MineralCatalog` (RefCounted): 20-row `MINERALS`, `TIER_TINTS`, `SECTOR_TIER_MIX`, `TIER_BASE_YIELD`, `YIELD_VARIANCE_MIN/MAX`, 12 static helpers (lookups, id mapping, tier rolls) |
| `vajb-orbit/game/component_catalog.gd` | 216 | `ComponentCatalog` (RefCounted): 18-row `COMPONENTS`, `GRADE_TINTS`, 4 static helpers |

Style follows `game/station_catalog.gd`: `class_name` + `RefCounted`, `##` header citing the
docs, `const` typed arrays of dictionaries, tabs, `_find` / `_ids` helper shape.
Temporary probe `tools/_probe_p1a.{gd,tscn}` was deleted after the final run (no `.uid`
sidecars were created; none existed to delete).

## Commands run

1. Parse + value gate (both catalogues):

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1a.tscn --quit-after 300
```

Observed: `PROBE OK (8782 checks)`, `EXIT=0`. The 8 `ERROR: Couldn't find the given section
"profile" and key ...` lines come from `autoload/player_profile.gd:547` (missing default keys
in `user://` profile) — pre-existing, unrelated to P1a; stdout carries no `SCRIPT ERROR`.

2. Mandated final run after the last edit, same command with stdout redirected to a scratch log,
   then filtered with `py -3.14` for `PROBE` / `SCRIPT ERROR` / `Parse Error`:

Observed: `EXIT=0`, `PROBE OK (8782 checks)`, no `SCRIPT ERROR`, no `Parse Error`.
(Scratch log deleted.)

`--check-only --script` was not used, per the brief.

## Probe coverage

`_probe_p1a.gd` preloads both scripts (no reliance on the global class cache) and asserts, per
the brief: exactly 20 minerals / 18 components; every row's id, name, tier/grade, all four
currency values and both unit weights against the doc tables; the 20 ore ids and 20 ingot ids
resolve and round-trip through `mineral_id_of_item` / `entry_for_item` / `is_ore` / `is_ingot`;
unknown ids return `{}` / `&""`; `TIER_TINTS`, `GRADE_TINTS`, `SECTOR_TIER_MIX`,
`TIER_BASE_YIELD` non-empty; all seven tints parse to the exact §8.6 hex
(`Color("#RRGGBB")` survives const folding, so no float-form fallback was needed);
`sector_mix` returns `{}` for 0 and 8 and the exact doc mix for 3 and 7; `roll_tier(1) == 1`
over 200 rolls and `roll_tier(6)` stays inside `{3,4}` (4000 rolls, both tiers well represented);
`roll_mineral` respects tier and returns `{}` for tiers 0 and 5; 500 `roll_yield` rolls per tier
stay inside `[maxi(1, base×0.5), round(base×1.5)]` and straddle the base; every component's
family, grade, value, units and family icon; `family_components` = 3 per family,
`grade_components` = 6 per grade.

## Doc values I could not reproduce (no value was invented or "fixed")

- **Krillum slug.** 02 §2 names the mineral "Krillum" but its ids are `mineral_krilium` /
  `ingot_krilium` (ICONS_SPEC §8.1 lists `krilium` too). I used base id `&"krilium"` with
  name `"Krillum"`, i.e. the docs' id, not the display spelling.
- **02 §5's sector table is superseded** by 11 §1.1, as the brief states. The two disagree in
  substance (02: sectors 4–6 = T2 40 %/T3 60 %; 11: 4 = `{2:60,3:40}`, 5 = `{2:35,3:65}`).
  Only the §1.1 values are in the file.
- **Tier boundaries also disagree** between 02 §2's section headings and 11 §1.1 (02: T2 in
  2–4, T3 in 4–6, T4 in 6+; 11 §1.1: T2 in 2–5, T3 in 4–7, T4 in 6–7). The per-entry `tier`
  tags from 02 §2 are unaffected; flagging it in case the headings should be amended.
- **Grade I/II tint hexes are unspecified by 03 §4.1** ("Grade I steel, Grade II
  gunmetal-bright, Grade III ochre `#8A6A50`"). Per the brief I reused ICONS_SPEC §8.6's
  sanctioned hexes: `1: #565C63`, `2: #8D939B`, `3: #8A6A50`. 02 §6 similarly defers to
  "ICONS_SPEC §1" for the tint palette, but the hexes only exist in §8.6.
- **Thousands separators.** 02 §2 writes `1 080` / `1 730` with a non-breaking space; stored as
  plain ints `1080` / `1730`.

## Reviewer notes

1. **`is_ore` / `is_ingot` policy (my interpretation).** They test the item id *form*, so
   `mineral_iron` is an ore, `ingot_iron` is an ingot, and the bare id `iron` is neither
   (`mineral_id_of_item` is the helper that accepts all three). Recorded in the file header.
2. **`roll_yield` on an unknown tier.** The brief gives the formula only, so
   `TIER_BASE_YIELD.get(tier, 0)` makes an out-of-range tier return `1` (`maxi(1, round(0))`).
   Say the word if it should return `0` instead.
3. `roll_tier` accumulates weights in ascending tier order (1→4) rather than dictionary order,
   so the roll is order-independent and reproducible from a seeded `RandomNumberGenerator`.
4. `ore_id` / `ingot_id` validate against `MINERALS` and return `&""` for unknown minerals, per
   contract; `ORE_ID_PREFIX` / `INGOT_ID_PREFIX` are exposed as consts because both id
   helpers and `mineral_id_of_item` need them.
5. **Concurrent workers were active during this run**: `game/economy_log.gd` and
   `tools/_probe_p1c.{gd,tscn}` appeared mid-session. Neither was touched.
6. Icons are the v1 fallback paths from 02 §6 / 03 §4.1, all six files verified present in
   `vajb-orbit/assets/icons/`. The Phase E swap stays a data edit.
