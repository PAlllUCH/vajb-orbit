---
slice: S22.8
phase: P3
lane: code
status: done
gate_baseline: "1006/0 → 1014/0"
---

# S22.8 — The weapons-cadence split

## Goal
Heavy guns stop being machine guns: laser/plasma/cannon stay hold-to-fire spam,
while the railgun, the rocket and the mine fire one shot and cool down (15/12/10 s),
so combat rewards timing shots and rotating batteries. The HUD shows the cooldown.

## In scope
- The cadence split (owner 2026-10-01, verbatim in 18 §4.1's amendment block):
  `game/weapons.gd` `FAMILIES` rows + `interval_of` reading a row's `cooldown`.
- The railgun's slug becomes alpha 450 (derived `dps × half the cooldown`).
- HUD feedback: the selected weapon's readout counts the cooling barrel down;
  cooling batteries' weapon cells dim (`ui/hud/hud.gd`, read-only on `weapons.gd`).
- The 09 P3 rows read through the law: `w_proton` joins the cooldown tier (12 s),
  `w_flak` stays spam (0.55 s) — recorded in 18 §4.1's amendment.
- New suite `tests/test_s22_8_cadence.gd` + the re-derived cadence pins in
  `test_engine2_weapons.gd` and wherever a heavy barrel's rate is pinned.

## Out of scope
- Damage rebalance beyond the railgun's alpha (laser/plasma/cannon figures frozen).
- Ammo pack sizes/costs/`AMMO_MAX` (economy untouched; heavy packs last longer).
- NPC guns (the brain's fire flag stays consumerless — mechanics belong to no wave).
- New art of any kind.

## Acceptance criteria
- [x] AC1 — the spam tier fires exactly as today: laser/plasma beams and the
      cannon's 0.35/0.25 burst carry no cooldown row and pass their existing pins.
- [x] AC2 — a cooldown-tier barrel fires one shot, then its cadence timer holds
      the family's cooldown (railgun 15, rocket 12, mine 10); a held trigger
      repeats one shot per cooldown (the stream law intact).
- [x] AC3 — the battery cycle of a mixed rack is its heavy member's cooldown;
      switching batteries mid-cooldown is possible and each battery cools
      independently (per-barrel timers).
- [x] AC4 — shot damage: railgun slug 450 (alpha), rocket 180, mine 180,
      cannon/laser/plasma unchanged.
- [x] AC5 — the mine keeps its edge law under the cooldown: one drop per pull,
      never sooner than 10 s since the last drop.
- [x] AC6 — `Rapid` divides the cooldown (the affix law reads the new interval).
- [x] AC7 — the HUD readout shows the selected cooldown family's remaining
      seconds and the cooling batteries' cells dim; no cooldown family selected
      changes nothing.

Closed 2026-10-01, hands-on (no dispatch): gate **1006 → 1014/0** twice hermetic;
the armory drum grew a fourth cell for the 10.00–15.00 s figures (L263, owner's
eye owed); the S19 seal re-pinned for `weapons.gd` (the S21/S22 rule).

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S22.8-V0 (the developer, hands-on) | `vajb-orbit/game/weapons.gd, vajb-orbit/ui/hud/hud.gd, vajb-orbit/tests/` | this SLICE + 18 §4.1's amendment block |

## References
- `docs/gameplay/18_engine_spec.md` §4.1 amendment (2026-10-01) + §13's two rows
- `docs/CONTRACTS.md` §10 v0.42
- The cadence machinery: `game/weapons.gd` (`interval_of`, `_barrel_interval`,
  `_rack_cycle`, `_release_battery`, the stream/edge laws)

## Carries forward
- `w_proton`/`w_flak` firing rows land with S23 and inherit this law.
