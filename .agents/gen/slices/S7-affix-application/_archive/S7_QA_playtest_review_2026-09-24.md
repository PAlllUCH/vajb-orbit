# S7 QA — independent playtest review, 2026-09-24

Reviewer: independent tester session (godot-ai driven, live editor, Linux host).
Tree: `bdfaace` + uncommitted S7 work (`autoload/player_profile.gd`, `game/auction.gd`,
`game/game.gd`, `tests/test_s3_instances.gd`, `tests/test_s7_suffixes.gd`) — **not** the
committed baseline, so anything below is attributed to "the working tree", not to a commit.
Gate on this tree: **`passed=753 failed=0`** (headless runner). Route: boot → menu → station
(all 8 modules) → launch → space flight/mining/targeting → ship status → ESC.

## HIGH

**H1 — a launched gun has no ammo, and the briefing lies about it.**
- Launch briefing (station) reads `AMMUNITION 1 941 ROUNDS ACROSS 6 WEAPONS` (`launch_panel.gd`).
- In flight the HUD ammo panel reads `Cannon MkI  0/300`; holding Space spawns no projectile
  (no projectile node appears anywhere under `/Game/Sector`), and the cluster's `AMMO` row reads `0000`.
- Contradicts the recorded P2-A behaviour (WAVEBOARD: "Vanguard `[laser]` 300 rounds; was five
  families / 1500"). Prime suspect: S7's uncommitted `player_profile.gd` / `game.gd` edits (launch
  ammo resolution). Needs the launch-fit/ammo seam probed by measurement, not by report.

**H2 — the resolved fit disagrees with the Fitting panel.**
- Station Fitting lists `Standard Drive`, `Cannon Mk1`, `Railgun`, `Mining Laser` (each OWNED ×1).
- Ship Status (U) lists `W1 · B1 · Cannon Mk1` **and** `W2 · B1 · Cannon Mk1`, `W3 · Light Plate`
  — a duplicated weapon and no Railgun/Mining Laser.
- Same 3 hardpoints / 11 slot cells as the fitting panel, so it is not a different hull.
- Likely the same root cause as H1 (fit resolution / instance expansion). S7's blast radius.

## MED

**M1 — every rock ram logs 16–24 engine errors; cleave spawns shapes inside the physics callback.**
Trace (`logs_read(source="game", include_details=true)`): `player_ship.gd:940 _on_hull_body_entered`
→ `asteroid.gd:262 apply_collision_damage` → `:248 apply_work` → `:309 _crack` →
`asteroid_field.gd:271 _on_rock_cracked` → `:365 _cleave` → `:255 _new_rock` → `asteroid.gd:232 setup`
→ `:347 _build_look`, where `body_set_shape_disabled` / `body_set_shape_as_one_way_collision` are
refused ("Can't change this state while flushing queries"). Fragments do appear (measured
`Fragment11`, `Fragment13` in `Field6`), so the cost is error spam plus an unverified shape on the
fragments. Cure: defer the new rock's body/shape setup (`set_deferred`/`call_deferred`).

**M2 — raw catalogue ids leak into player-facing copy (Exchange).** Confirm strip
`SELL 1 MINERAL_CHROMIUM — GROSS 18 · FEE 10 · YOU GET 8` and status bar `SOLD · 1 MINERAL_CHROMIUM · +5 CR`.
`exchange_panel.gd:107 CONFIRM_FORMAT`, name resolved at `:277` with `String(mineral_id)` fallback
to upper — the mineral's display name is not reaching that path (the hold row itself renders
"CHROMIUM ORE" correctly).

**M3 — the sale preview is not price-locked.** Preview promised `YOU GET 8`; the commit credited
**+5** (credits 5986 → 5991) because the market moved between preview and press. The market is live
and rolls fast (IRON 67 CR / 1.0x HOT → 57 CR / 0.9x COOLING inside ~30 s, bands flip). No hint that
the shown payout is indicative.

**M4 — current shield exceeds its own displayed maximum, in two independent panels.**
- Ship Status footer: `HULL 1250 / 1250` but `SHIELD 800 / 600`.
- Station Repairs: `HULL 1250 / 1000`, `SHIELD 800 / 600` (`repairs_panel.gd:177-188` computes
  `hull_max`/`shield_max`, then prints `current / max`).
- So either the maxima are base (`1000/600` from `station_catalog.gd`) while the resolved ship is
  `1250/800`, or the current values are inflated. Either way the player sees an impossible ratio,
  and it is the same family of accounting H1/H2 sit in.

**M5 — Ship Status close affordance is a ~100 px white "X"** overhanging the plate's top-right
corner. Off-brand against every other glyph in the theme; reads as a placeholder.

**M6 — the two-press launch confirm's 3 s window is unforgiving.** It expired between two of my UI
round trips and the panel only reports afterwards (`ARMING EXPIRED · PRESS LAUNCH TO ARM AGAIN`).
No countdown, no progress feedback while armed.

## LOW — copy, naming, hygiene

- `REFINERY ALL` reads as a heading, not a verb; stepper/status say `1 CONVERSIONS`
  (`refinery_panel.gd:80-81` formats). Expected: `REFINE ALL`, `1 CONVERSION`.
- Refinery **hides** any stack with less than one conversion left: after refining chromium
  4 → 1 ore, the chromium row vanished from the Refinery entirely (`stacks()` lists only
  convertible minerals; `test_p1_refinery.gd:192` asserts exactly that) while the ore was still
  in the Exchange hold. By design per the test, but it reads as data loss to a player.
- The same item is spelled three ways: `CANNON MK1` (Armory inventory), `Cannon Mk1` (Fitting),
  `Cannon MkI` (HUD ammo panel — capital I instead of digit 1); `Railgun`/`RAILGUN` likewise.
- Target panel uses metres (`860 m OUT OF RANGE`) where the docs and mining range use units.
- Auction: `NEXT RESTOCK 20:00` states no unit; the hull thumbnails in its rows are ~16 px and
  near-black (previews are unreadable at a glance).
- Engine warnings present in the tree: `module_catalog.gd:636/643/651 INTEGER_DIVISION`
  (decimal discarded — sits in the affix/module area S7 is editing); `projectile.gd:1485/1489/1759`
  and many `weapons.gd` rows `SHADOWED_VARIABLE[_BASE_CLASS]`.
- `tools/d7r1_probe.gd:397` fails to parse ("Expected statement, found `_`") — untracked scratch
  file that errors on every editor load.
- Stale-editor-log note, not a defect: `player_ship.gd:1378` "too many arguments for
  `sync_thruster_trails()`" is a reload entry from an older revision; the call on disk (`:1427`,
  five args) matches the five-param definition (`projectile.gd:1514`).

## Composition and vision clarity

- **Repeated dead zones.** Content anchors left/top and leaves the right third black: Armory's plate
  is 872 px inside a 1392 px host (~520 px void), Fitting puts the slot grid left with ~800 px empty
  right, Repairs carries a 440 px `BodySpacer` between the damage report and the box it belongs to,
  Launch a 440 px `LaunchSpacer`. Armory's clipped third inventory row also sits under a fold.
- **The player's own ship is the least visible object on screen** — dark hull, ~40 px at flight
  zoom, against dark rocks and a black void; only the engine glow reads. Consider a rim light,
  brighter player tint, or a scale bump for the player's own hull.
- **HUD state is bottom-left only.** `TopLeft/Blocks` still holds `HullBlock`/`ShieldBlock`/
  `EnergyBlock`/`FuelBlock` but all are hidden (`hull_vis=false`, `Blocks` size `0×0`); every number
  lives in the cluster (seven-seg `SPD/HULL/SHLD/AMMO` + FUEL/ENRG gauges). The top-left quadrant is
  empty while hull/shield state is the thing a player needs mid-fight. (Retraction of my first read:
  shield *is* displayed — the third cluster row is `SHLD 0800`, not `RAD`.)
- **Minimap** shows blips and a corridor circle with no legend; two small glyphs at its bottom-right
  are unreadable at 1080p.
- **Rocks are the standout**: varied silhouettes, warm ore speckles, believable size spread, good
  contrast against the void. Menu composition (logo top-left, three verbs left, burning wreck right)
  is balanced; its only oddity is the 50×58 `InsigniaBadge` floating unlabelled above PLAY.
- Shipyard reads well as a screen (hero side view + comparison table). Targeting reads well
  (`TARGET / Lancer / HULL bar / SHIELD bar / 860 m OUT OF RANGE / HOSTILE`).

## Playability — what verified clean

- Menu → station → all eight modules → launch → flight → ESC all navigate; `Enter` confirms on the
  menu, `U` toggles Ship Status, ESC closes it.
- Flight: thrust, turn, strafe, thruster trails, deceleration to 0, speed readout, sector boundaries.
- Mining works: `Rock1.work` accumulated to `0.79` with the cursor over the field; hold went
  `21/40` (launch) → `22/40`, so mined/cleaved ore reaches cargo. The mining beam `Line2D` existed in
  one run and not in another (spawns lazily), so the beam's on-screen visibility needs a dedicated pass.
- Rock ram → cleave works (fragments spawn), at the cost of M1's errors.
- Live market, live auction (`Delver` 16 000, `Mule` `WAS 24 000 CR`), shipyard comparison, repairs.
- **Economy loop verified end-to-end and persisted across a process restart**: refine chromium
  (4 ore → 1 ore, +1 ingot, −15 CR), sell 1 chromium ore (+5 CR) — credits 6001 → 5986 → 5991 with
  hold `ingot_chromium 1 / mineral_aluminium 4 / mineral_silicon 17` after relaunch.
- Sector content is rolled per run (run 2: traders + patrol; run 3: pirate + patrol; POIs differ).

## Tooling appendix (godot-ai on an unfocused window)

1. The game window being unfocused **intermittently stalls the main loop** (`debug_status`
   `loop_live=false`, eval `EVAL_GAME_NOT_READY`, screenshots served from the old buffer, queued
   input applied late — one nav click was swallowed and an arming window expired).
2. `editor_screenshot(source="game")` returns the **previous run's** frame for the first capture
   after a relaunch, and generally lags one to two states; read `get_ui_elements` as ground truth.
3. An eval that throws parks the game in a debugger break (`game_status.status="break"`,
   `"Invalid call. Nonexistent function 'is_active' in base 'Line2D'"`, mine) which will not
   self-resume — `project_manage(op="stop")` and relaunch.
4. `input_action` sets action state but raises no `InputEvent`, so `_unhandled_input`-driven UI
   (`U` status, `C` cargo, ESC) needs `input_key`; `mine` armed fine from action state.
5. This playtest **wrote the live `user://` profile** (refine, sale, mining). The gate's no-write
   discipline does not cover manual play — restore a pristine save if the owner wants one.
