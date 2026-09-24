---
slice: S7
worker: S7-K2
model: opencode-go/deepseek-v4.1-flash
status: actionable
gate: "746/0 -> 746/0 (twice, scratch stores; my suite contributes 19 of the 746)"
---

# S7-K2 report — the launch bridge, the per-barrel prefixes, `damage_mult` and Embers

## Result

The launch and barrel half of CONTRACTS section 20 is landed and measured. The
launch now passes `profile.affix_summary(hull)` into `ShipFit.resolve` beside the
base-id fit and writes the per-slot `{keen, rapid, frugal}` dicts plus the suffix
flags onto `PlayerState`; each released barrel reads **its own cell's** dict (Keen
at shot composition, Rapid on that barrel's interval, Frugal through a per-slot
fractional bank); `damage_mult` is applied exactly once at all five measured
delivery sites and is null-tolerant; Embers heals an NPC sink only, on both
deliveries, clamped at `shield_max`; and Spry's `booster_cooldown_mult` multiplies
the afterburner's cooldown (8.0 s → 6.8 s). The gate reads **746/0 twice** on
scratch stores (19 of the 746 are `tests/test_s7_weapon_affixes.gd`); the
pre-K2 tree carried 727 rows (K1's 726 plus one row D7's lane added and then closed
in `12278d2`), so every existing suite is byte-identical and no existing row moved.

## What was built (file:line)

- `game/affixes.gd:88-98` — K1's D5 one-liner: `has_suffix(data, id)` (was
  `summary`); no caller changes, and the `SHADOWED_VARIABLE` warning is gone
  (measured: `--check-only` on the file now reports none).
- `game/game.gd:261` — `_launch_summary`, the one launch var K3's seams read.
- `game/game.gd:456-476` — `_resolve_stats` calls `_affix_summary_for` and passes
  **`_launch_fit`** (the base-id fit, K1's D3) plus the summary to
  `ShipFit.resolve`; `_affix_summary_for` returns `{}` for a profile with no
  `affix_summary` (a stub, a probe).
- `game/game.gd:348-349` — the handshake gains `set_weapon_affixes` +
  `set_affix_flags`, **after** `setup()` (K0's own order note: `setup` re-sizes the
  slot arrays).
- `game/game.gd:557-617` — `_launch_weapon_affixes` walks `_launch_fit[&"weapons"]`
  with `_launch_weapons`'s own `""`-skipping, and `_cell_affixes` reads each cell's
  prefixes out of the summary's `instances` rows (`slot` + `index`), keeping only
  `BARREL_PREFIXES`. `_launch_affix_flags` de-duplicates `KEY_SUFFIXES`.
- `game/player_state.gd:105,111,118` — `weapon_affixes: Array[Dictionary]`,
  `affix_flags: Array[StringName]`, `ammo_frac: Array[float]`; `:159-171` the two
  setters (the affix array is sized to `weapons.size()` with `{}` padding);
  `:178-185` `_resize_ammo` also seeds `ammo_frac` to zeros, so `set_weapons` and
  `setup` are both empty-bank seed points.
- `game/weapons.gd:355-363` — `PREFIX_KEEN`/`PREFIX_RAPID`/`PREFIX_FRUGAL`,
  `FLAG_EMBERS`, `EMBERS_FRACTION`.
- `game/weapons.gd:1105` — the beam frame's `paid[weapon]` is now the summed
  **weight** `Σᵢ(1 + keenᵢ)` instead of a count (`:1231`-adjacent delivery unchanged);
  with no Keen each barrel contributes exactly 1.0.
- `game/weapons.gd:1206-1223,1231` — `_spawn_shot` composes Keen into the shot's
  damage and puts `damage_mult` + `embers` into the `configure` dict.
- `game/weapons.gd:1265` — the beam chip takes `× GUN_CHIP_RATE × _damage_scale()`.
- `game/weapons.gd:1829-1830` — `_deliver` applies `_damage_scale()` once and heals
  Embers before the sink call.
- `game/weapons.gd:1870-1953` — `_damage_scale` (null-tolerant),
  `_barrel_affixes`, `_slot_of_barrel`, `_prefix_magnitude`, `_prefix_factor`,
  `_state_has_flag`, `_heal_embers`.
- `game/weapons.gd:2014-2075` — `_ammo_available_at`, `_consume_ammo_at` (the
  Frugal bank), `_barrel_interval`; `_rack_cycle` uses `_barrel_interval` so the
  rack's salvo gate follows a Rapid member.
- `game/projectile.gd:456-457,509-510` — `damage_mult` / `embers` configure keys;
  `:773` the projectile chip `× damage_mult`; `:913-914` the delivery product;
  `:933-946` `_heal_embers` through `_source.heal_from_damage`.
- `game/player_ship.gd:72` — `EMBERS_FRACTION`; `:940` the ram's peer half
  `× _damage_scale()`; `:987-1004` `_damage_scale` + `heal_from_damage`;
  `:1162,1198` Spry's `_booster_cooldown_scale()` on the afterburner line.
- `tests/test_s7_weapon_affixes.gd` — new suite, 19 tests (854 lines) + its Godot
  `…gd.uid`.

## Judgment calls (bucket 1 unless named)

| # | Call | Why | Reversal |
|---|---|---|---|
| D1 | **L90 is routed around, not fixed globally.** Frugal's spend/gate resolves the barrel's **live slot** (`_slot_of_barrel`, built from `PlayerState.weapons`) **only for a barrel whose Frugal magnitude is non-zero**; every other barrel keeps the shipped `ammo_slot`/`_consume_ammo` path. | Fixing `ammo_slot` globally would change a launched two-same-family battery's total rounds (today both barrels draw the const index's one slot; per-slot spending would double a Lancer's effective ammo) — a gameplay change outside this wave's pin. Scoping the cure to the only barrels that need a position (the bank is per cell) keeps every un-affixed number, and every existing suite, byte-identical. | Gate the live slot on `_state.weapon_affixes` instead of the magnitude, or fix `ammo_slot` itself; both are one-line changes. Reported as **L90's route-around**, not a close. |
| D2 | **Bank vs pack, stated as §20 asks.** The **bank** is `PlayerState.ammo_frac[slot]` (per cell; flight state; seeded `0.0` by `_resize_ammo` at both seed points; never persisted). The **pack** is `PlayerState.ammo[slot]`, the slot's own array entry, and the integer round leaves it through the shipped `set_ammo`. Cost per shot is `1 × (1 + Σfrugal)`; the bank spends `floor(bank)` when it crosses 1, so **20 shots at −0.15 spend exactly 17** (measured). | §20's Frugal row. | — |
| D3 | **≤1 round/cell unfiled at dock is expected**, per the brief: the bank holds the residual fraction and `_file_ammo_report` files only the integer deltas it can see, so at most one round per cell is dropped at a dock and the bank is re-seeded empty on the next launch. Not persisted, not filed. | §20 ("≤1 round/cell unfiled at dock (reported, not persisted)"). | Persist `ammo_frac` in the docking report if the owner ever wants it. |
| D4 | **Keen applies at composition on both paths.** The beam weights the frame by `Σ(1 + keen)` (K0 F11); a travelling barrel composes `shot_damage(weapon) × (1 + Σkeen)` in `_spawn_shot`, so the projectile carries Keen in its own damage and `damage_mult` arrives separately. | §20's Keen row ("that cell's shot damage ×(1+Σown) **at shot composition**") covers every released barrel, not only beams; K0 F11 named the beam's aggregation because that is where the identity was lost. | Fold Keen into `damage_mult` (owner tick 7). |
| D5 | **The chip order is `amount × GUN_CHIP_RATE × damage_mult`** (beam) and `damage × chip × damage_mult` (projectile). | The chip is a player-origin delivered amount (K0 F12) and §20's tick includes rocks; applying the multiplier after the 10 % rate is the reading that keeps the rock's work a fixed fraction of the delivered damage. | Swap the factors (multiplication commutes here; no behavioural difference). |
| D6 | **`EMBERS_FRACTION` is spelled in both `weapons.gd` and `player_ship.gd`.** | §20 routes the two deliveries differently on purpose (beam reads `_state` directly, projectile calls `PlayerShip.heal_from_damage`), so neither file can own both without a new accessor the pin does not name. Both are the same constant and both are documented. | Have `weapons.gd:_deliver` call the host's `heal_from_damage` when the beam's host carries one. |
| D7 | **The launch var is `_launch_summary`** (K3's seam reads it) and the summary is resolved once in `_resolve_stats`. | K2's prompt ("store the summary in one launch var so K3's seams can read it"); the scene is the only object that holds both the fit and the summary. | K3 may re-call `profile.affix_summary` instead — one line. |
| D8 | **`_slot_of_barrel` walks `_state.weapons` counting firing-family entries.** | K0 F8's map is derivable — `_launch_weapons` (the state list) and `fitted_ids` differ only by the family-less `w_mining` drop — so no new plumbing was needed in `game.gd`. With a family-less cell present the barrel count and the slot count stay aligned by construction. | Have `game.gd` push an explicit barrel→slot map onto the component (a new seam). |

## Tests that move

None. Every suite the gate carried before this pass is untouched (D7's own row count
is attributed, never absorbed), and the new suite is the only addition. No existing
assertion flipped, so the K0 flip-list guard held: the multiplier is null-tolerant and
no gate fixture fits a computer.

## Evidence

```bash
# full gate, twice, each on its own scratch store (XDG_DATA_HOME=$(mktemp -d))
source ~/.profile && XDG_DATA_HOME=$(mktemp -d) godot --headless --path vajb-orbit \
  res://tests/headless_runner.tscn --quit-after 1200
# [SUMMARY] passed=746 failed=0   (three runs: 746/746/746, exit 0)
# the tree before my suite: 727 rows (K1's 726 + one row D7's lane added and closed
# in commit 12278d2); my suite contributes exactly 19 -> 746.
grep -h "^func test_" vajb-orbit/tests/test_*.gd | wc -l   # 746

# scoped run, for the suite's own lines
... --quit-after 600 -- --suite=test_s7_weapon_affixes
# [SUMMARY] passed=19 failed=0
# [s7-affixes] frugal: 20 shots at -0.15 spent 17 rounds (bank 0.000000)

# parse + warning ledger of the touched files
godot --headless --path vajb-orbit --check-only --script res://game/affixes.gd
# no SHADOWED_VARIABLE (K1's D5 cleared); game/weapons.gd / game/projectile.gd /
# game/player_ship.gd / game/player_state.gd / game/game.gd parse clean (the only
# `--script` error on game.gd is the pre-existing autoload trap: `Router` at :2106)

# the new test's UID sidecar (the tracked convention, 125/125 tests now carry one)
vajb-orbit/tests/test_s7_weapon_affixes.gd.uid   # uid://r3dl46s6i18c

# live store, untouched by these runs (every run used a scratch XDG_DATA_HOME);
# the 12:54 profile.cfg write is D7's own running editor game (L149's class)
md5sum "$HOME/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg"      # b32fdb7b9c68e132e76d0771660f916b  (12:54, D7 lane)
md5sum "$HOME/.local/share/godot/app_userdata/Vajb Orbit/economy_log.txt"  # bd27929cd7b075e913d07e50a017bbcf  (12:18, unchanged since K1)
```

The `SCRIPT ERROR: Cannot call method 'call' on a previously freed instance.` line in
the full gate is the pre-existing `test_weapon_fx_f4.gd:178` one (it is present in the
first run of this pass, before any K2 edit).

## Files touched

- `vajb-orbit/game/affixes.gd` — +6/-3: the `has_suffix` parameter rename.
- `vajb-orbit/game/game.gd` — +134: `_launch_summary`, the summary bridge, the
  handshake's two setters, the per-cell walk and the summary readers.
- `vajb-orbit/game/player_state.gd` — +46: the three fields, the two setters, the
  bank seed.
- `vajb-orbit/game/weapons.gd` — +220: the consts, the beam weight, `_spawn_shot`'s
  Keen/damage_mult/embers, both chip sites, `_deliver`, the affix helpers, the ammo
  and interval helpers.
- `vajb-orbit/game/projectile.gd` — +58: the two configure keys, the chip product,
  the delivery product, `_heal_embers`.
- `vajb-orbit/game/player_ship.gd` — +54: the ram product, `_damage_scale`,
  `heal_from_damage`, Spry's cooldown scale.
- `vajb-orbit/tests/test_s7_weapon_affixes.gd` (+ `.uid`) — new suite, 19 tests.

No `ui/`, `assets/`, `staging/` or `docs/` write.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| L90 — `ammo_slot` still indexes the const `PlayerState.WEAPONS`; K2 routed around it for Frugal only | LOW (pre-existing, unchanged) | `game/weapons.gd:2201`-class; `.agents/gen/_state/LOW_BACKLOG.md` L90 |
| K3 reads `_launch_summary` for Leeches/Cartograph, or re-calls `profile.affix_summary` | HANDOFF | `game/game.gd:261` |
| The `d7r1_*` tools and the editor-log parse error at `tools/d7r1_probe.gd:397` are D7's lane, not this wave's | ATTRIBUTION | `vajb-orbit/tools/` |
| The ruler/clamp tests for affix magnitudes are K1's (`test_s7_affixes.gd`); this suite is about the delivery, never the resolver | SCOPE NOTE | `tests/test_s7_weapon_affixes.gd` |
