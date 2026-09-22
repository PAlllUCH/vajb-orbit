# Session report — queue items 4 to 7 (2026-09-22)

One file that answers "what happened in this session" without reading seven wave-report
chains. **Scope:** the owner's order to execute `dispatch_coder.md` items 4, 5 and 6, then
item 7 ("lets start with p2-b"). **State in one line:** all four items are CLOSED and
committed; the universal gate reads **`passed=437 failed=0`, exit 0**; nothing is in flight;
the next brief is the module-affixes wave (doc 15), with the AUCTION behind it.

Companion files: `.agents/gen/WAVEBOARD.md` (current state + queue of record),
`.agents/gen/MASTER_REPORT.md` (the earlier wave history), `.agents/gen/LOW_BACKLOG.md`
(L61, L66–L92), and the per-wave report chains named below.

---

## 1. The four items, at a glance

| Item | Wave | Brief / prompts | Gate | Commit |
|---|---|---|---|---|
| 4 | P2-A ship slot frames | `.agents/gen/p2a_wave_task.md` | 311 → **372** | `8d189bf` |
| 5 | Rock cleave (asteroid destruction) | `.agents/gen/rock_cleave_wave_task.md` | 372 → **378** | `0e419f7` |
| 6 | P2-B1 weapon fit surface | `.agents/gen/p2b1_weapon_fit_wave_task.md` | 378 → 387 → **389** | `1f794cc` |
| 7 | P2-B proper fitting panel | `.agents/gen/p2b_proper_wave_task.md` | 389 → 402 → 420 → 431 → **437** | planning `7b82731`, wave `3e79e61` |

Every wave ran **D0 (docs) → builders → R1 (mandatory review) → F1 (fixer, only on HIGH/MED)**,
with a `verify_wave.py` snapshot before it and a wave-boundary commit after it.

---

## 2. Item 4 — P2-A ship slot frames

- **Builders:** nine per-class matrices (shipyard grids 4×3 → 5×6, columns 4×8 + 5, plates
  8/11/12/13/13/15/14/17/23); the engine set (1–3 cells by mass band, **summed** deltas with the
  1.40 ceiling — the Mule's three-engine set is ×1.40, not the product); profile fits at save
  v4 with v1–v3 loading clean; the nine-hull `StationCatalog.SHIPS` roster; the launch resolving
  the active hull's own fit and filing ammo per fitted weapon (measured: Vanguard `[laser]`
  300 rounds, Lancer `[laser, laser]` 600 — was five families / 1500); the shipyard
  GridContainer and the HUD cell display.
- **Reviewer:** no HIGH, **1 MED** (a shadowing const in `test_p2a_ship_roster.gd:10`) fixed by
  F1 (+2 tests), 6 LOW → `LOW_BACKLOG.md` L66–L71.
- **Owner ticks:** brief §8 — all six kept. Launch-fit **symptom 1 closed** at root cause.

## 3. Item 5 — Rock cleave

- **Builders:** fragments are a uniform **2–5** on both cleaving tiers in **uniform 360°**
  (the deterministic (2,3)/(2,2) split and the ±15° cone retired) at the shipped ×1.2 speed —
  measured Large {2:80, 3:69, 4:72, 5:79}, Medium {2:78, 3:69, 4:70, 5:83}, widest fragment
  pair 179.8°, 529/529 at ×1.2; a rock-scaled explosion `clamp(1.2 × diameter, 96, 224) u`
  plus a new four-take rock cue in `CUE_POOLS` and the shipped shockwave; a Small keeps its
  1–2 pickups; a yield-0 rock cracks bare but still plays the break read.
- **Reviewer:** no HIGH, **1 MED** (a stale `CONTRACTS.md` §5 cleaving sentence) fixed by A3
  (+ v1.4 changelog), 4 LOW → L72–L75.
- **Owner tick owed:** the `18_engine_spec.md` §6/§13/§15 dated amendment (the spec is
  owner-locked and its text still lags the shipped behaviour).

## 4. Item 6 — P2-B1 weapon fit surface

- **Builders:** `PlayerProfile.buy_module` (refusals reuse `purchase_failed`; one `BUY_MODULE`
  economy-log line); OUTFITTING's `MODULES` rows + `FITTED WEAPONS` strip; install/swap/remove
  through `ShipFit.fit_legal`; the refusals `11 / 8 PWR — OVER BY 3` (09 §2's over-by format)
  and `W SLOTS FULL — SWAP OR REMOVE FIRST`; the mandatory engine/reactor set untouchable.
- **Reviewer (measured itself):** gate 387 twice; the round trip and its persistence re-read
  out of the file (credits 20 000 → 14 600, a swap hands the laser back, reload identical);
  W2's probe byte-identical; 25 signatures 0 drift; 21 format-law byte checks 0 failures.
  **No HIGH, 2 MED, 8 LOW** (L76–L83, plus L84):
  - **MED-1** — an unaffordable module purchase named a fabricated `0 NEEDED`; cured by
    extending `ui/screens/station.gd`'s `_entry` chain with `ModuleCatalog` (`5 200 NEEDED`).
  - **MED-2** — `w_mining` had **no row**, so the 600 CR mining laser (09 §4 item 7) could not
    be obtained in play; the brief's §1 and §3 named two different sixes and D0 left the
    contradiction standing. Adjudicated to **seven rows** (09 §3.1's six plus `w_mining`) so
    the launch-fit gate's mining swap has a door; F1 landed it plus two guards (suite 7 → 9).
- **Owner ticks:** the seven-row set (one reversal constant), the two refusal wordings,
  INSTALL = first empty W cell, and L78's ACTION precedence. Launch-fit **symptom 2 closed**.

## 5. Item 7 — P2-B proper fitting panel

**Owner decisions taken this session** (scope confirmation before any code): affixes (doc 15)
deferred to the **next** wave; the six legacy `UPGRADES` rows **retire now** with their effects
migrated; the owner's four station requests **all ride along**.

- **D0 (docs):** `STATION_HUB.md` §5.3 rewritten as **FITTING** (rail swap, the retirement and
  its reversal), §5.4's `REFUEL`/`RECHARGE` rows, §5.2's hover line; 09 §4's per-slot fitting
  rules and §7's note; 10 §6's interim note; 15 §6's dated affix note; `CONTRACTS.md` **§13**
  plus the v0.5 changelog. It flagged two drifts rather than inventing: a stale constant in the
  dispatcher's own prompts and the brief's duplicated rule numbering.
- **W1 (profile + retirement):** `fit_module_at`, `clear_fit_slot`, `retire_legacy_upgrades`,
  `SAVE_VERSION` 5 with the load-path migration, the six-row `LEGACY_UPGRADE_MODULES` table, and
  the complete deletion of the legacy surface (`has_upgrade` / `installed_upgrades` /
  `install_upgrade`, the catalogue rows, the `upgrades` record). Measured: a v4 file with all
  six installed reads back as **six inventory modules** and a second migration call returns 0.
  +13 tests (gate 389 → 402).
- **W2 (the pane):** the FITTING pane — the UPGRADES rail slot, the active hull's slot grid
  built from `ShipFit.grid_cells` with the **shipyard's own plate recipe** (measured 16/16 same
  size and plate art), selectable cells, the OWNED MODULES rows, the power meter in its three
  forms, the three pinned refusals, the focus order, the empty state; the retired pane files
  deleted and the four `station.gd` parse errors from the retirement cured. +18 tests (402 → 420).
- **W3 (requests 1 and 4):** the shipyard hover line (`W1 · LASER MKII · OWNED ×3`) and LAUNCH's
  `REFUEL`/`RECHARGE` rows through `Repairs.refuel`/`recharge` (free and instant, no credits
  move). +11 tests (420 → 431).
- **R1 (review):** **no HIGH, 2 MED, 8 LOW** (L85–L92).
  - **MED-1** — the pane previewed the fit the launch would fly while the profile committed
    against the stored fit, so FITTING was dead on any hull with no stored fit (every hull
    bought in SHIPYARD arrives without one). Cured profile-side: a new `resolved_fit(ship_id)`
    (the stored fit when it holds any module, else `ShipFit.standard_fit`) is now the candidate
    for both transactions and the panes' display, so preview and commit read one shape.
  - **MED-2** — a refusal's footer line outlived the successful action that followed it.
- **F1 (fixer):** both MEDs cured, +6 tests → **437**.
- **F2 (orchestrator-authorised test-only pass):** cured a **pre-existing** fixture assumption
  R1 diagnosed in LOW-6 — three `test_engine2_dock.gd` / `test_engine2_fixes.gd` tests resolved
  the ammo slot from the catalogue order while the launched fit sizes it, which the owner's own
  cannon-first Vanguard exposed. The canonical gate (no sandbox, live profile) went 434/3 →
  **437/0**.
- **Owner ticks 1–5 landed** (the rail entry, the six-row retirement table, the pinned strings,
  the four requests, affixes next). One measured residual parked: a bare hull's delivered
  mandatory cell still offers `REMOVE` and refuses with the pinned wording (W2's disclosed
  reading).

---

## 6. Incidents and their root causes

1. **The apparent "provider stall" that wedged R1 twice (P2-B1)** was not the provider: one of
   R1's own probes ran an **unbounded `while` loop** (an inverted empty-cell search) at 100% CPU
   and produced a 1.65-million-line log. `crush run` prints only assistant text, so the log's
   silence looked like a hung stream. Cured by killing the runaway Godot process and bounding
   the loop; recorded as L82 with the lesson that every probe needs its own hard iteration
   bound, not just `--quit-after` on the runner.
2. **The shell's `kill` is an unsupported builtin** in this environment, so `kill -9 <pid>`
   silently failed; processes must be signalled through `python3 -c "os.kill(...)"`.
3. **`opencode-go/deepseek-v4.1-flash` is currently unusable for agent streams** — it fails
   deterministically with `[invalid_request_error] The reasoning_content in the thinking mode
   must be passed back to the API`. Two dispatches died on it in seconds. D0 ran on
   `opencode-go/deepseek-v4-flash`; everything after ran on `deepseek/deepseek-v4-flash` per the
   owner's instruction.
4. **A model's own probe was edited mid-review by the orchestrator** (to bound the loop in item
   1); R1 disclosed it in its report's caveat and rested its conclusions on files whose mtimes
   never moved. Worth knowing: three `crush` sessions and the editor were live in this
   workspace at once.
5. **The live profile is a test input.** The three engine2 failures in item 4 above only appear
   against the owner's real save; every worker ran a sandboxed `user://`. The gate is green on
   both today, but future workers must not read those three as a regression.

---

## 7. Open items

- **Owner ticks owed:** the `18_engine_spec.md` §6/§13/§15 cleaving amendment (spec is
  owner-locked); nothing else — the P2-A, P2-B1 and P2-B proper tick lists are resolved.
- **Backlog:** `LOW_BACKLOG.md` L61 (the tolerated `test_weapon_fx_f4` SCRIPT ERROR line),
  L66–L71 (P2-A), L72–L75 (rock cleave), L76–L84 (P2-B1), L85–L92 (P2-B proper). Notable:
  L80 (module instances hand back their base id — the affix wave's decision), L83 (the 48/40 px
  icon tension), L92 (the bare hull's mandatory-cell `REMOVE` residual).
- **Owner requests still queued, unbriefed:** the rock-cleave follow-up (fragments moving
  outward from the centre); the beam's hit FX spawning randomly across the struck surface; the
  beam terminating nearer the object's middle. The other four (shipyard hover, the owned-items
  inventory, the shipyard slot-grid layout, REFUEL) shipped in item 7.
- **Next in the queue:** the **module-affixes wave (doc 15)** — the instance shape
  `{base_id, rarity, prefixes[], suffixes[]}`, the roll sources and the 15 §7 naming/stat
  grammar — then the **AUCTION** (10 §2), into which OUTFITTING's module rows retire.
- The designer/graphics lane (`dispatch_designer.md` + `designer_generation_backlog.md`) is
  still deferred and has nothing in flight.

---

## 8. Commits this session

| Commit | Message |
|---|---|
| `90f6896` | Queue the ship-slot, rock-cleave and weapon-fit waves |
| `8d189bf` | Give every ship class its own slot count and layout (item 4) |
| `0e419f7` | Make asteroid death read as a break, not a silent split (item 5) |
| `1f794cc` | Open the weapon-fitting door on the station's OUTFITTING panel (item 6) |
| `7b82731` | Plan the fitting panel the station needs to install modules cell by cell |
| `3e79e61` | Replace the station's dead upgrade rows with a real fitting panel (item 7) |
