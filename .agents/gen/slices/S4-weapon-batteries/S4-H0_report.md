---
slice: S4
worker: S4-H0
model: deepseek/deepseek-v4-flash
status: informational
gate: n/a (report-only; no code or doc file written outside this report)
---

# S4-H0 report — docs drift check against the tree

## Result

**Measure-first item, answered:** one trigger does **not** discharge multiple barrels
today, and there is nowhere for a volley to live. `WeaponComponent.tick` fires exactly
one weapon — `var id := selected_weapon()` (`game/weapons.gd:520`), dispatched to
`_fire_beam` (`:555`) or `_fire_projectile` (`:601`) — and `selected_weapon()` is
`_fitted[_group - 1]` (`:385-388`). Worse for this wave: **the grouping data is already
destroyed at the seam** — `set_fitted` drops any id already present (`:365-371`, the
`_fitted.has(id)` guard at `:369`), so a `[w_laser, w_laser, w_laser]` fit reaches the
component as **one** group. No `volley`/`salvo`/`strum`/`battery` symbol exists anywhere
in the tree (grep over `*.gd`/`*.tscn`, `addons/` excluded). So §16's `fitted() -> Array
# unchanged, per barrel` is self-contradictory as written: "unchanged" is today's
de-duplicated list, "per barrel" requires duplicates kept (F1 below).

**Read against the tree:** 09 §10/§4, STATION_HUB §5.10 + §5.1, CONTRACTS §16/§13/§8.2,
plus the four files the wave touches and every caller of the two seams it moves.
**15 findings**: 4 HIGH, 5 MED, 6 LOW/informational. Nothing was fixed, no number invented.

## Findings

Tiers are the escalation ladder's: HIGH = the pin cannot be implemented as written or two
pinned texts contradict each other; MED = an unpinned decision a worker cannot make from
the docs; LOW = a stale line, an imprecise pointer, or a note.

### HIGH

**F1 — The volley does not exist, and duplicate barrels are collapsed before they can group.**
`game/weapons.gd:501-527` (`tick`) reads one id (`:520`) and fires one family; nothing loops
`_fitted`. `set_fitted` (`:365-371`) skips any id already kept (`:369 if id == &"" or
_fitted.has(id): continue`), so `ShipFit.fitted_ids`' duplicates (`game/ship_fit.gd:481-489`
appends per cell, duplicates kept) never survive into the component. §16's comment
(`docs/CONTRACTS.md:1489`) is therefore self-contradictory. Consequence for H2: the volley is
**new work** (keep duplicates; loop the battery in `tick`), not the strum-and-read reduction
`S4_BRIEF.md:28-32` holds open.
*Reversal:* none needed — the ruling is the owner's; this is the measurement the brief asked for.

**F2 — `battery(base_id) -> Array  # this battery's W indices` cannot be answered from what the component is handed.**
`set_fitted` is called with `_fit_ids` (`game/player_ship.gd:1205-1206`), which is
`ShipFit.fitted_ids(_launch_fit)` (`game/game.gd:465`) — a **flat id list with no cell
indices**, from which `WeaponComponent` keeps only firing families (`weapon_id`, `:369`,
`:1531-1536`). At the same time `PlayerState.weapons` — what the HUD and the ammo arrays read —
is one entry per fitted W cell **including** the family-less ones (`game/game.gd:395-405`'s own
comment: "a fitted cell whose module has no firing family (`w_mining`…) is a slot with no pack
rather than a dropped cell"), and it is built by the same `weapon_id` bridge (`:403`). So the
two index spaces diverge on the first hole or the first `w_mining`: for `[w_mining, w_laser]`
the component holds `[laser]` (one element) while the fit's W cells are 0 and 1, and the cell
index 1 is unrecoverable. §16 pins a return of "W indices" but no index-carrying seam.
*Bucket:* (2) — a `set_fitted`/`battery` shape change would edit a pin; escalate, do not choose.

**F3 — "the ammo slot each barrel already owns" is not true; ammo is per family, one pack shared by every barrel.**
`WeaponScript.ammo_slot` (`game/weapons.gd:1519-1526`) resolves the **family's** index in
`PlayerState.WEAPONS` (`game/player_state.gd:35`), so every `laser` barrel reads the same slot
regardless of its cell. The tree says so in words twice: `game/player_state.gd:84-89` ("Ammo
stays per family: the packs are keyed by family id, so a fit carrying two lasers draws both of
its slots from the `laser` pack") and `game/game.gd:1247-1249` ("a hull that mounts two lasers
seeds both from the one `laser` pack"). A 3-barrel volley therefore charges **one** pack three
times per trigger (`_consume_ammo`, `:1211-1217`, reads `_state.ammo[slot] - 1` each call). The
brief's parenthetical (`S4_BRIEF.md:52`) must be read as "one round per barrel, from the family
pack" or H2 will look for per-barrel slots that do not exist.
*Knock-on (recorded, not owned here):* a 3-round-per-trigger delta triples the blast radius of
the known MED at `docs/CONTRACTS.md:781-791` (`_file_ammo_report` is not idempotent within one
launch). `game/game.gd` is in **no** S4 worker's file set.

**F4 — STATION_HUB §5.1 and §5.10 contradict each other on the strip, and §5.1 is unowned.**
§5.1 is the strip's owner and still pins "one line per W cell of the active hull —
`W1 LASER MKII` / `W2 — EMPTY` — each fitted line carrying REMOVE" (`docs/design/STATION_HUB.md:408-411`),
and its S3 amendment explicitly declares the strip untouched (`:386-387`). §5.10 pins "one row
per battery" (`:800-805`). A S4 worker may only touch `docs/CONTRACTS.md` (H3/H4) — no worker
owns STATION_HUB — so the losing half must be amended by the designer session or the wave closes
with two contradictory strip laws. Second half of the same finding: **§5.1's EMPTY lines have no
home in a grouped strip** (a battery by definition holds instances), yet
`tests/test_p2b1_outfitting_panel.gd:603-604`, `:606-607` and `:633-634` assert them, and the
brief's escape hatch — "the expander keeps the single-cell assertions alive"
(`S4_BRIEF.md:60-61`) — cannot cover an *empty* cell. The brief's pointer "(§5.10 (the strip
rows)" is also imprecise: the strip's anatomy is §5.1's; §5.10 only restates the battery row.
*Bucket:* (2) — doc text.

### MED

**F5 — `fit_battery(ship_id, base_id, indices)` cannot be a thin loop of `fit_module_at(cell, base_id)`.**
`fit_module_at` refuses when `module_count(module_id) == 0` (`autoload/player_profile.gd:855`),
and `module_count(base_id)` does **not** aggregate a base's instances — the tree states it:
`ui/station/fitting_panel.gd:657-658` ("`module_count(base_id)` cannot answer this for an
instance-keyed bag"). With the bag holding three lasers as three `mod_%04d` records
(`add_instance`, `:462-470`), every base-id call refuses. The batch has to resolve each cell's
entry from `instances_of(base_id)` (`:487-500`, bag keys at `count` 1, creation order), a pairing
rule §16 does not name. Same gap for `FIT ALL`'s "min(owned, free) … in layout order"
(`S4_BRIEF.md:53-54`): which owned instance lands in which cell is unpinned.

**F6 — The rollback restore is pinned for the fit but a batch moves the bag too.**
Each successful `fit_module_at` banks the displaced entry and takes the incoming one
(`player_profile.gd:865-870`); each `clear_fit_slot` banks the cell's entry (`:911-915`).
§16's "a failed cell rolls the batch back to its starting fit" (`docs/CONTRACTS.md:1484-1485`)
names the fit array only, so a literal implementation leaves the bag drifted — a restored cell
whose instance is still at `count` 0 (the L80 class `docs/CONTRACTS.md:1405-1406` cures). The
restore path exists and is public (`set_fits` `:710`, `set_modules` `:341`, `set_fit` `:766`),
so the pin only needs to say "snapshot the fit **and** the bag". §16 does not.

**F7 — The new row copy's building blocks live in a file no S4 worker owns.**
`OWNED ×%d` is `ui/station/fitting_panel.gd:111`; the three pinned refusals are
`:147-149` (`REFUSAL_OVERLOAD`, `REFUSAL_MANDATORY`, `REFUSAL_FIT_ILLEGAL`); the selection line
is `:116`. §5.10 `:804-805` and the brief's rules say the batch's failure "names the §13
refusal" but never where the wording's single home is. §13's precedent is explicit for the other
shared list (`docs/CONTRACTS.md:1251-1253`, "The mandatory-key list is not re-declared"); no twin
rule exists here, so H1 must either duplicate three constants (drift) or preload the FITTING pane
from OUTFITTING (an unsanctioned coupling). `VAJB_WORKER_FILES` for H1 excludes that file
(`SLICE.md:40`).

**F8 — `MANDATORY CELL — SWAP ONLY, NEVER EMPTY` is unreachable for a W battery.**
`FitData.MANDATORY_SLOT_KEYS` is `[&"engines", &"power"]` (`game/ship_fit.gd:117`) and a battery
is W-only, so `clear_battery` can never trigger it; the brief's rule (`S4_BRIEF.md:56`) and
§5.10 `:805` list it among the batch's refusals. A test asserting it would need a non-W battery
(none exists) or a hand-written fixture. Report, do not invent a trigger.

**F9 — The dedup F1 removes is pinned by a test the brief's tests-that-move list omits.**
`tests/test_engine2_wiring.gd:246-255` asserts `fitted() == launched`, where `launched` is itself
de-duplicated (`:250-253`) and the comment at `:249` says "duplicates included". It stays green
only because the fixture flies the default Vanguard's one-laser fit
(`player_profile.gd:148`, 09 §9 `:432`); a Lancer — `[w_laser, w_laser]` per 09 §9 `:431` —
turns it red the moment `fitted()` keeps duplicates. The brief names only
`test_p2b1_outfitting_panel.gd` and `test_engine2_weapons.gd` (`S4_BRIEF.md:80-84`).

### LOW / informational

**F10 — The brief's "what is already measured" claim about the strip is half wrong.**
`S4_BRIEF.md:33-34` says "fitted cells hold `instance_id`s and the strip's rows aggregate by
`base_id` with `OWNED ×<n>`". The first half is right (`player_profile.gd:784-786`,
`:831-836`; the strip resolves each cell through `base_module_id`, `outfitting_panel.gd:641`,
`:755-758`). The second is not: the strip is one line per W cell with a single REMOVE plate and
no aggregation (`outfitting_panel.gd:590-616`, `:628-649`), and `OWNED_FORMAT` exists only in
`fitting_panel.gd:111`.

**F11 — The brief's `module_action` citation is stale.** `S4_BRIEF.md:23-24` cites "L78's
`module_action` at `:873-882`" of `outfitting_panel.gd`; the file is **813** lines and has no
`module_action` (the S3 retirement took the MODULES rows, `:13-20`). The LOW row carries the same
stale path (`_state/LOW_BACKLOG.md:201`). L78's precedence question is only reachable now through
the expander's single-cell actions, not through a row.

**F12 — Two stale figures in the living contracts (H3 owns CONTRACTS.md; the board is close-out's).**
`docs/CONTRACTS.md:1210` still pins `const SAVE_VERSION := 5` while §15 `:1409` pins 6 and the
tree has 6 (`player_profile.gd:54`). `.agents/gen/_state/WAVEBOARD.md:79` still reads "§9's gate
figure is the measured **437**" while §9 `:800` reads 493 and STATION_HUB `:750` records the S3
tick at 493/0.

**F13 — `game/projectile.gd` is in H2's set with nothing pinned to change.** `configure`
(`game/projectile.gd:485-517`) has no delay/strum key, and the strum is a weapon-side release
offset, so the change plausibly lands entirely in `weapons.gd`. Also a doc nit for H3: §16's code
block (`docs/CONTRACTS.md:1488-1491`) carries no `BATTERY_STRUM_MS`; the value is pinned in §16's
prose `:1495-1496` and 09 §10 `:462-463`, and its home (WeaponComponent) comes from the brief
`:46` only.

**F14 — Two volley behaviours the pin leaves open (energy families).** A laser's "release" is a
per-frame `try_spend_energy` (`weapons.gd:555-560`), so "one trigger discharges the whole
battery: one round per barrel" (`docs/CONTRACTS.md:1494-1496`) has no partial/abort rule: a pool
that pays for two of three barrels is undefined, and the strum wording (a *release* offset) is
written for travelling families. Reported, no number invented.

**F15 — Notes a worker should not re-litigate.**
(a) No name collision: no `battery`/`BATTERY` symbol exists in the tree, so §16's names are free.
(b) The strip's **fixed node set** is a documented invariant — `_build_strip` pre-builds
`_max_weapon_cells()` lines and shows/hides by index (`outfitting_panel.gd:591-596`, `:635-640`)
*because* the profile emits `profile_changed` from inside its own handler (`:147-148`); battery
rows still fit it (≤ max W cells) if H1 keeps the constant node set and rewrites text/controls.
The brief does not mention the constraint. (c) A battery row may hold a non-firing module
(`w_mining`, 09 §3.1/§4 item 7), whose base id `set_fitted` drops (`weapons.gd:369`,
`:1531-1536`), so `battery(&"w_mining")` is unanswerable in the family-keyed reading — the
grouping law is base-id, the fire seam is family-keyed, and §16 reconciles the two nowhere.
(d) The focus order *within* a battery row (FIT ALL / REMOVE ALL / SWAP ALL / expander) is
unpinned; §5.10 `:813-814` pins an order for AUCTION only, §5.1 `:414-415` for OUTFITTING's
two groups.

## Verified consistent (so H3 does not re-open them)

- **No fit-shape change, one instance per W cell:** confirmed — `set_fit` stores what it is
  handed at the hull's shape (`player_profile.gd:757-775`) and §13's transactions keep their
  signatures while accepting instance ids (`docs/CONTRACTS.md:1395-1396`).
- **`WEAPON_SLOT` is not mandatory**, so a battery's cells are always removable
  (`ship_fit.gd:117`, `player_profile.gd:901`).
- **`clear_fit_slot` refuses an empty cell** (`player_profile.gd:903-905`), which is harmless for
  a battery whose cells are all non-empty by definition.
- **`WEAPON_SLOT`'s cell addressing** (`0 .. slot_capacity-1`, `_fit_cell_exists`
  `player_profile.gd:1361-1369`) is what §16's `indices` can mean.

## Deviations from SLICE.md

None — no file inside the declared set was edited, and no measurement was re-derived from a
printed figure (every number above is read off the tree at the cited line).

## Evidence

- `grep -rni "volley\|salvo\|strum" vajb-orbit --include=*.gd --include=*.tscn` → no functional
  hit (only the word "instrument" in probe headers); `grep -rn "battery\|BATTERY" …` → none.
- `grep -n "func \|^const " vajb-orbit/game/weapons.gd` → `tick` at `:501`, `selected_weapon` at
  `:385`, `set_fitted` at `:365`, `ammo_slot` at `:1519`.
- `grep -rn "set_fitted\|selected_weapon\|selected_group" vajb-orbit` → the callers named in F2
  (`player_ship.gd:1205-1206`, `game.gd:799-800`, `:1353-1359`, `tests/test_engine2_wiring.gd:243-255`).
- `wc -l vajb-orbit/ui/station/outfitting_panel.gd` → 813 (F11).
- `grep -c "^func test_" vajb-orbit/tests/test_engine2_weapons.gd` → 29 (the brief's own figure).
- `grep -n "OWNED_FORMAT\|REFUSAL_" vajb-orbit/ui/station/fitting_panel.gd` → `:111`, `:147-149` (F7).

## Files touched

None (report-only pass; this report is the only artifact).

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| F2/F4 — a pin-shaped change (the index-carrying seam; the losing half of §5.1 vs §5.10) belongs to the developer/designer session before H2 starts, or the wave ships a worker-chosen index space | escalation (bucket 2) | `docs/CONTRACTS.md §16`, `docs/design/STATION_HUB.md §5.1/§5.10` |
| F3/F6/F7/F8 — the ammo parenthetical, the bag half of the rollback, the refusal-wording home, and the unreachable mandatory refusal are all answerable inside the pinned reading if the brief is amended before dispatch | brief amendment | `S4_BRIEF.md:52`, `:53-59`; `SLICE.md` worker sets |
| F12 — `SAVE_VERSION` in §13 and the WAVEBOARD gate figure | doc fix | `docs/CONTRACTS.md:1210`; `_state/WAVEBOARD.md:79` (H3 / close-out) |

*(Not ticketed: this pass writes no code and H3's brief already owns the CONTRACTS/backlog rows.)*
