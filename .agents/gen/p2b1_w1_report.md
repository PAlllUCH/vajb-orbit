# P2-B1 — W1 report: the purchase seam (`PlayerProfile.buy_module`)

**Worker:** W1 (coder — the purchase seam). **Wave:** P2-B1 — the weapon fit surface.
**Brief (law):** `.agents/gen/p2b1_weapon_fit_wave_task.md` §3 (the pin) + §4 row W1 + §5 + §6.
**File set (`VAJB_WORKER_FILES`):** `vajb-orbit/autoload/player_profile.gd`,
`vajb-orbit/tests/`. Two shipped files touched, one probe created; **no** `assets/**`, no
theme, no `project.godot`, no `addons/**`, no `docs/**`.
**Status:** complete. The gate is green and grown (**378 → 380**, `failed=0`, exit 0);
`buy_module` is `CONTRACTS.md` §12's pin, byte for byte in name and signature; no existing
method, signal or assertion was reshaped, and no number was invented.

---

## 1. Files changed

| File | Change |
|---|---|
| `vajb-orbit/autoload/player_profile.gd` | +30 / −0 (additive only): `const ModuleData` + `const Log` preloads, `const EVENT_BUY_MODULE`, and `buy_module` at `:378`. Nothing else in the file moved — `git diff` is three additive hunks, zero deletions. |
| `vajb-orbit/tests/test_p1_profile.gd` | +119 / −1: two new tests (the sanctioned file of brief §5, which owns the profile) plus three helpers (`_watch_purchases`, `_on_purchase_failed`, `_log_lines`) and the `_failures` capture. **The one deleted line is a header sentence** replaced by two lines; no existing test's assertions changed. |
| `vajb-orbit/tests/probe_p2b1_buy_module.gd` | **new**, the re-runnable evidence probe (run with `--script`, no scene). |
| `.agents/gen/p2b1_w1_report.md`, `.agents/gen/p2b1_w1_probe.txt`, `.agents/gen/p2b1_w1_gate.txt` | this report and its raw captures. |

`git status --short` lists my two modified files and my one new probe and nothing else; the
four modified `docs/**` files in the tree are **D0's** (its report is
`.agents/gen/p2b1_d0_report.md`), untouched by this pass.

## 2. The seam as shipped (`autoload/player_profile.gd:368-385`)

```gdscript
## Buy one module into the inventory (CONTRACTS section 12, P2-B1). `cost` is the
## catalogue's own price, passed by the caller exactly as `buy_ammo`, `buy_ship`
## and `install_upgrade` take theirs (17 section 5 item 4 keeps the price in the
## catalogue and out of the UI, so the one caller that reads it passes it in).
## 17 section 5's transaction law, all-or-nothing: verify (an id the catalogue
## does not ship, or a negative cost, is `unknown_id`), charge
## (`insufficient_credits` when the balance is short), give (`add_module` once),
## emit (`&"credits"` when the charge moved credits, then `&"modules"` from the
## add) and log — exactly one `economy_log` line, and a refused purchase writes
## no credits, no inventory and no line.
func buy_module(module_id: StringName, cost: int) -> bool:
	if ModuleData.module(module_id).is_empty() or cost < 0:
		return _refuse(REASON_UNKNOWN, module_id)
	if not _charge(cost):
		return _refuse(REASON_INSUFFICIENT, module_id)
	add_module(module_id, 1)
	Log.append(EVENT_BUY_MODULE, module_id, 1, -cost, _credits)
	return true
```

The signature is §12's exactly: `func buy_module(module_id: StringName, cost: int) -> bool`.
Built only out of the seams P2-A shipped: `ModuleData.module()` (the unknown-id test),
`_refuse`/`_charge` (the pre-existing purchase pattern of `buy_ammo` / `buy_ship` /
`install_upgrade`), `add_module()` (the inventory half) and its own `_touch(KEY_MODULES)`
emitting `profile_changed(&"modules")`.

Two constants were added, both named after an existing pattern in the same file:

```gdscript
const ModuleData := preload("res://game/module_catalog.gd")
const Log := preload("res://game/economy_log.gd")
const EVENT_BUY_MODULE := "BUY_MODULE"
```

`EVENT_BUY_MODULE` is the "nearest shipped event id" §12 rule 1 allows: the shipped
vocabulary is `MINE`/`CACHE` (`pickup.gd:40-41`), `SELL`/`QUEUE`/`QUEUE_BUY`
(`exchange.gd:70-72`), `REPAIR`/`REFUEL`/`RECHARGE` (`repairs.gd:50-52`) and
`AMMO`/`DROP`/`KILL` (`game.gd:143-145`) — none of them says "a module was bought", so the
value is new and follows their shape (upper-case, one token).

## 3. The transaction, step by step (17 §5's law)

| Law step | Implementation |
|---|---|
| verify | `ModuleData.module(module_id).is_empty()` → `unknown_id`; `cost < 0` → `unknown_id` (the guard `buy_ship`/`install_upgrade` use against a negative price) |
| charge | `_charge(cost)` → refuses with `insufficient_credits` when `cost > _credits`; a zero cost is free and legal, and `cost == _credits` is allowed (the balance lands exactly at 0, never negative) |
| give | `add_module(module_id, 1)` — one call, so the count moves by exactly one |
| emit | `_charge` emits `profile_changed(&"credits")` when credits moved; `add_module` emits `profile_changed(&"modules")`. Both keys are P2-A's §11 keys. A free (`cost == 0`) buy therefore emits only `&"modules"` |
| log | `Log.append(EVENT_BUY_MODULE, module_id, 1, -cost, _credits)` — **one** line per purchase, balance read after the charge |

A refused purchase touches nothing: `_refuse` only emits `purchase_failed`, never a
`profile_changed` and never a log line (measured in §5 below).

## 4. The round-trip numbers (raw, from `probe_p2b1_buy_module.gd`)

Every figure below is `.agents/gen/p2b1_w1_probe.txt`, re-runnable with

```text
godot --headless --path vajb-orbit --script res://tests/probe_p2b1_buy_module.gd
```

```text
[probe] catalogue prices: w_cannon=1200 w_railgun=5200
[probe] start: credits=10000 w_cannon=0
[probe] buy_module(w_cannon, 1200) = true
[probe] after buy: credits=8800 w_cannon=1 signals=["credits", "modules"]
[probe] log lines=1 raw=2026-09-21T22:53:17, BUY_MODULE, w_cannon, 1, -1200, 8800
[probe] buy_module(w_cannon, 1200) again = true
[probe] after the second buy: credits=7600 w_cannon=2 log lines=2
[probe] after reload: credits=7600 w_cannon=2
[probe] -- refusals --
[probe] buy_module(w_do_not_exist, 100) = false failures=["unknown_id/w_do_not_exist"] w_do_not_exist=0 credits=7600 lines=2
[probe] buy_module(w_cannon, -1) = false failures=["unknown_id/w_cannon"] credits=7600
[probe] balance drained to 500; buy_module(w_railgun, 5200) = false failures=["insufficient_credits/w_railgun"] credits=500 railgun=0 lines=2 signals=[]
```

What each line proves:

| Claim (brief §3 / §12) | Measured |
|---|---|
| the price is 09 §3.1's, not the caller's invention | `w_cannon=1200`, `w_railgun=5200` read out of `ModuleCatalog` |
| credits move by exactly the price | 10 000 → 8 800 → 7 600 |
| the inventory count moves by exactly one | `w_cannon` 0 → 1 → 2 |
| the emit is `profile_changed(&"modules")` | `signals=["credits", "modules"]` — the charge's key then the inventory's key |
| exactly **one** economy-log line per purchase | 1 line after one buy, 2 after two, and the line reads `…, BUY_MODULE, w_cannon, 1, -1200, 8800` (event, id, qty 1, delta −cost, post-purchase balance) |
| the purchase persists | `reload()` returns credits 7 600 and `w_cannon` 2 (a save v4 record, P2-A's shape) |
| unknown id refuses as `unknown_id` | `w_do_not_exist` → `false`, `unknown_id/w_do_not_exist`, count 0, credits untouched, **no new log line** (still 2) |
| a negative cost is not a price | `w_cannon, -1` → `false`, `unknown_id/w_cannon` |
| insufficient refuses as `insufficient_credits` | balance drained to 500, `w_railgun` 5 200 → `false`, `insufficient_credits/w_railgun`, **balance still 500**, count 0, **no new log line**, **no `profile_changed`** (`signals=[]`) |

## 5. Tests added (brief §5: additions only, the gate grows)

Two tests in `tests/test_p1_profile.gd`, which brief §5 names as the profile's own suite.

| Test | Asserts |
|---|---|
| `test_buy_module_round_trips` | `ModuleCatalog`'s own `w_cannon` price is 1 200 (the number under test is the catalogue's); one buy spends exactly 1 200 (10 000 → 8 800), puts the count at 1, refuses nothing, and emits `[credits, modules]`; the log holds **exactly one** line with the six fields `EVENT_BUY_MODULE` / `w_cannon` / `1` / `-1200` / `8800`; a second buy stacks the count to 2 and makes the log 2 lines ("one line per purchase, never two"); `reload()` round-trips both credits and count |
| `test_buy_module_refuses_unknown_and_insufficient` | the unknown id refuses with `unknown_id` and writes no inventory, no credits, no signal and no log line; a negative cost refuses `unknown_id` on a real id; the railgun's catalogue price is 5 200 and against a 500 balance it refuses with `insufficient_credits`, leaves the balance at 500, gives nothing, emits nothing and logs nothing |

Supporting helpers added (append-only): `_watch_purchases` / `_on_purchase_failed` capture the
`purchase_failed` vocabulary as `{reason, id}`, and `_log_lines()` reads the scratch log. The
existing `_reset_log()` already pointed `EconomyLog.log_path` at `user://test_p1_log.txt`, so
`user://economy_log.txt` and `user://profile.cfg` are never touched by this suite.

## 6. The gate

Baseline (measured before this pass, matching D0's own run in its report §3 item 3):
`[SUMMARY] passed=378 failed=0`.

After this pass, raw capture `.agents/gen/p2b1_w1_gate.txt`:

```text
$ godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
...
[PASS] test_p1_profile.gd.test_buy_module_refuses_unknown_and_insufficient
[PASS] test_p1_profile.gd.test_buy_module_round_trips
[PASS] test_p1_profile.gd.test_equal_sets_are_silent
[PASS] test_p1_profile.gd.test_existing_api_emits_its_keys
[PASS] test_p1_profile.gd.test_fresh_defaults_without_a_file
[PASS] test_p1_profile.gd.test_getter_copies_cannot_mutate_state
[PASS] test_p1_profile.gd.test_signal_keys_for_emitting_setters
[PASS] test_p1_profile.gd.test_silent_setters_emit_nothing
[PASS] test_p1_profile.gd.test_spend_over_balance_refuses
[PASS] test_p1_profile.gd.test_v1_profile_migrates_to_defaults
[PASS] test_p1_profile.gd.test_v2_round_trip_for_every_key
[SUMMARY] passed=380 failed=0
```

exit 0, 380 `[PASS]` lines, 0 `[FAIL]`. The suite is 9 → 11 tests; no other suite moved.

## 7. Decisions and interpretations (nothing in §12 is contradicted)

1. **"Unknown" = absent from `ModuleCatalog`**, not "not a weapon": the catalogue is the
   authority on what the game ships (P2-A's §11 pin), and 09 §3's other slot types are
   purchasable at the auction in the same motion. The panel decides which rows it offers; the
   seam refuses any id it cannot price. This is also why the seam needs no hard-coded weapon
   list that could drift from 09 §3.1.
2. **`cost < 0` is `unknown_id`, not a fifth reason.** It copies `buy_ship` (`:218`) and
   `install_upgrade` (`:248`) exactly and adds no new reason to the refusal vocabulary.
3. **`EVENT_BUY_MODULE := "BUY_MODULE"`.** §12 rule 1 allows "`EVENT_BUY_MODULE` or the
   nearest shipped event id"; no shipped id means a purchase, so the new one is defined (§2).
4. **The price is a parameter, not a lookup inside the profile.** The signature is the pin's,
   and the profile never re-derives a catalogue price in the other four purchase seams either.
   Consequence worth stating for R1: the profile charges what it is told, exactly as
   `buy_ammo` does — a caller that passes a wrong number is a panel bug, not a profile one.
   Making the seam verify `cost == ModuleCatalog.module(id)[&"cost"]` would be a **new**
   refusal condition the pin does not authorise, so it was not added.
5. **Zero-cost purchase is legal** (`_charge(0)` is a no-op that returns `true`): the pin
   refuses only unknown and insufficient, and a free module is neither. Nothing in shipped
   data prices a module at 0 (09 §3's cheapest is 600 CR).

## 8. Findings for W2 / R1 (transcribed, not resolved — the brief is law)

1. **The refusal key the panel must render from.** `buy_module` fails with
   `purchase_failed(&"unknown_id" | &"insufficient_credits", module_id)` — the two reasons
   `STATION_HUB.md` §12.4 already maps. The panel's STATUS (`LOCKED` when unaffordable) and the
   footer wording are W2's; the seam emits `insufficient_credits` for exactly the case
   "affordable" describes (`cost > credits`).
2. **W2's panel must pass the catalogue's `cost`.** `ModuleCatalog.module(id)[&"cost"]` is the
   only price the seam is meant to receive (decision 4 above).
3. **`profile_changed` fires twice on a paid buy** (`&"credits"` then `&"modules"`), once on a
   free one (`&"modules"`). W2's `refresh_profile` reacting to `&"fits"` **and** `&"modules"`
   should also tolerate `&"credits"` arriving first, or it will rebuild the rows twice per
   purchase. P2-A W2's §11 pin deliberately left this to the consumer.
4. **D0's finding 1 (six rows versus seven ids) is not this seam's problem and was not
   settled here.** `buy_module` sells any id `ModuleCatalog` ships, so whichever six rows W2
   renders, every one of them is purchasable. Recording it so R1 does not read the seam's
   permissiveness as a ruling on the row set.
5. **Not touched, still stale (D0 finding 4):** `docs/design/STATION_HUB.md:49` ("4 hulls,
   `StationCatalog.SHIPS`") and `docs/gameplay/10_ship_acquisition.md:154` ("09 §4.6" where
   the swapping rule is §4.8). Both are one-line doc fixes outside my file set.

## 9. Commands run

| Command | Purpose | Result |
|---|---|---|
| `godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` | the wave's gate, before and after | 378 → **380**, `failed=0`, exit 0 (`/tmp/p2b1_w1_gate.txt` → `.agents/gen/p2b1_w1_gate.txt`) |
| `godot --headless --path vajb-orbit --script res://tests/probe_p2b1_buy_module.gd` | the round-trip and both refusals, raw | `.agents/gen/p2b1_w1_probe.txt` |
| `git diff --numstat` / `git diff --stat` | scope proof | `player_profile.gd` +30 / −0; `test_p1_profile.gd` +119 / −1 (the single deletion is a header sentence); the four `docs/**` changes are D0's |
| `lsp_diagnostics` on both edited files and the probe | static check | empty (no diagnostics) |
