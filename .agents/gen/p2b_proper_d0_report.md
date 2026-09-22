# P2-B proper — D0 documentation report (2026-09-22)

**Role:** D0 (docs only). **Files changed:** `docs/design/STATION_HUB.md`,
`docs/gameplay/09_ship_slots_modules.md`, `docs/gameplay/10_ship_acquisition.md`,
`docs/gameplay/15_module_affixes.md`, `docs/CONTRACTS.md`. **Nothing else touched:**
no code, no assets, no theme, no `project.godot`, no `addons/`. No number is this pass's:
every figure below is the brief's (`.agents/gen/p2b_proper_wave_task.md`), 09's own tables or
12's, and the report names the source per pinned item.

**Two drifts recorded, not invented (see §6).** (1) The dispatcher's prompt and W1's prompt
name a `FIT_MANDATORY_KEYS` constant. No such constant exists in the brief or in the tree;
the brief's own rule 1 pins the law: the mandatory-key list is **not** re-declared and
`FitData.MANDATORY_SLOT_KEYS` (`game/ship_fit.gd:117`) is the one source. §13 carries rule 1
verbatim and no `FIT_MANDATORY_KEYS` is landed anywhere. (2) The brief's §3 rule list numbers
two rules "2."; §13 numbers the six rules 1–6 in reading order with **no text change**, and
the changelog records it.

---

## 1. docs/design/STATION_HUB.md

Header amendment block (the retirement and its reversal recorded, plus the two dead
references disposed of) — **lines 11–23**.

| Pinned item | Line(s) | Source |
|---|---|---|
| Rail table: `FITTING \| rail entry 5`, payload names the SLOT LAYOUT grid + OWNED MODULES rows, `ShipFit.grid_cells` / `PlayerProfile.modules` | 62 | brief §3.2 "Rail" bullet |
| §1 intent: "fitting (FITTING)" replaces "refits (UPGRADES)" | 41 | retirement consistency |
| §2 prose: "(OUTFITTING, FITTING)" | 75 | retirement consistency |
| §3.1 "Panes" node list: `Fitting` replaces `Upgrades` | ~120 (the `Panes` row) | retirement consistency; §3.1's `Upgrades*` node rows and the `UPGRADES` column set are **explicitly left** as the retired mockup's measurement record and flagged in the header (line 21) |
| §5.2 hover/selection line (owner request 1), `<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`, reading the selected hull's `fit_for`; reversal | 478–484 | brief §3.2 "Hover / selection info" bullet |
| §5.3 heading `### 5.3 FITTING (fit, swap and remove modules per cell)` | 486 | brief §3.2 |
| §5.3 transcription note | 488–490 | brief §3 |
| Rail swap: `Module.UPGRADES` becomes `Module.FITTING`, label `FITTING`, entry keeps the retired entry's rail position, icon path and tint; the retired `upgrades_panel.gd`/`.tscn` deleted; nothing else in the rail moves | 492–494 | brief §3.2 "Rail" bullet, verbatim |
| SLOT LAYOUT grid: the shipyard's own recipe (`ShipFit.grid_cells`, `SlotButtonWeapon` 48 px plates, gaps as empty `Control`s, the type's slot glyph, caption `SLOT LAYOUT · <n> CELLS · <m> ENGINES`), selectable cells, one at a time, `FOCUS_ALL`, the theme's focus ring, identity = `slot_key` + `index` (09 §4.5) | 498–504 | brief §3.2 "Anatomy" → "SLOT LAYOUT", verbatim |
| OWNED MODULES rows: aggregated by id, `ShipFit.FIT_SLOT_KEYS` then catalogue order, 48 px icon / name / `SLOT <TYPE> · DRAW <n>` / `OWNED ×<n>` / ACTION | 505–508 | brief §3.2 "Anatomy" → "OWNED MODULES", verbatim |
| ACTION per state: `FIT` / `SWAP` / `SELECT A CELL` (disabled) | 509–513 | brief §3.2 "ACTION per state", verbatim |
| Power meter: idle `PWR <Σ draws> / <out + power module>`; candidate `PWR <Σ> / <out> · CANDIDATE <Σ'> / <out>`; over budget, danger colour, `— OVER BY <n>`; numbers = `fit_legal`'s `power` | 514–517 | brief §3.2 "The power meter", verbatim |
| Hover / selection line; shipyard's plates gain the same line on hover | 519–522 | brief §3.2 "Hover / selection info", verbatim |
| The three pinned refusals: `13 / 11 PWR — OVER BY 2`, `MANDATORY CELL — SWAP ONLY, NEVER EMPTY`, `REFUSED · FIT ILLEGAL`; footer never blank | 523–526 | brief §3.2 "Refusals", verbatim |
| Focus order: SLOT LAYOUT cells (row-major) → OWNED MODULES rows → pane footer → rail (§10) | 528–530 | brief §3.2 "Focus order", verbatim |
| Empty states: `NO MODULES OWNED · BUY THEM IN OUTFITTING`; full hull shows meter + grid, no refusal | 531–533 | brief §3.2 "Empty states", verbatim |
| The per-cell transactions (request-only, `fit_module_at` / `clear_fit_slot`, `fit_legal` preview, mandatory never emptied) | 535–540 | brief §3.1's pin + §3's rules 3–5 |
| The retirement and its reversal: six legacy rows retire, one successor module per row (`LEGACY_UPGRADE_MODULES`), v4 file with all six → six inventory modules, no upgrade records; `has_upgrade` / `installed_upgrades` / `install_upgrade` / `upgrades` gone; reversal = restore label, entry, pane files + mapping constant + catalogue rows | 542–548 | brief §3.2 "Rail", §7 owner ticks 1 and 2 |
| §5.4 table rows `REFUEL` (calls `Repairs.refuel(profile, active_ship)`, `fuel_max` or refusal reason) and `RECHARGE` (as REFUEL, for `energy_max`) | 562–563 | brief §3.3, verbatim |
| §5.4 amendment: the two actions, free and instant, no price column, no credits move (14 §1's rate, `FREE_FEE` 0), refusal states rendered never hidden, button stays pressable; reversal | 578–587 | brief §3.3, verbatim |
| §7.1 art map: `icon_equip_generator_48.png` is the FITTING rail entry's icon, the retired entry's own icon path and tint, reused (no new art) | 762 | brief §3.2 "Rail" bullet; owner tick 1 |
| §7.1 art map: the five `icon_equip_*` roots annotated as retired row icons (no live pane draws them) | 767 | retirement consistency |
| §8 theme table: `SlotButtonWeapon` covers the shipyard's display and FITTING's selectable grid | 805 | retirement consistency |
| §10: Tab order rails `(OUTFITTING, SHIPYARD, FITTING, LAUNCH, LOG OUT)`; new FITTING-pane focus-order row | 848–849 | brief §3.2 "Focus order" + §10 contract |
| §11 audio: `FITTING entered` keeps the retired UPGRADES module's cue | 873 | retirement consistency |
| §12.1 files table: `fitting_panel.tscn` replaces `upgrades_panel.tscn` | 900 | brief §3.2 |
| §12.4: `&"fits"` and `&"modules"` rebuild FITTING (replaces `&"upgrades"` / UPGRADES); `owns_ship` / `module_count` replace `has_upgrade` | 940–942, 948 | brief §3.1 pin; retirement consistency |
| §12.5: the upgrade copies (`every upgrade (...)` and `the installed upgrades [upgrade_engine, upgrade_extra]`) removed with the retired surface | 961–966 | retirement consistency |

Section 5.1 is **not** changed (its P2-B1 amendment stands); §3.1's measured node/column
tables and §13's verification table are left as the retired mockup's record, flagged in the
header amendment (line 21).

## 2. docs/gameplay/09_ship_slots_modules.md

| Pinned item | Line(s) | Source |
|---|---|---|
| §4 item 8's interim note gains the pointer: the surface that then fits, swaps and removes those modules per cell is **FITTING** (`STATION_HUB.md` §5.3; items 9 to 13 below) | 278–280 | owner task, §4.8 pointer |
| §4 item 9: the composed install `fit_module_at` — guards (hull, `FIT_SLOT_KEYS`, index bounds, `module_count == 0`, `fit_legal` on the candidate `fit_for` + one cell), success order (displacement → take → `set_fit_slot` → one `EVENT_FIT_MODULE` log line → both keys), no half-writes | 281–294 | brief §3.1 `fit_module_at` pin, verbatim |
| §4 item 10: the composed remove `clear_fit_slot` — same guards plus a `FitData.MANDATORY_SLOT_KEYS` key always refused; `add_module`, `&""`, one log line (module id, qty 1, delta 0), both keys; `clear_fit` stays the whole-fit reset | 296–303 | brief §3.1 `clear_fit_slot` pin + rule 3, verbatim |
| §4 item 11: legality previewed once (pane colours the meter and gates the ACTION) and re-checked on commit, both through `ShipFit.fit_legal`; nothing auto-removes | 305–308 | brief §3 rules 5 and 6 (numbered 5, 6 in §13) |
| §4 item 12: the pane never mutates directly; may only call the two composed APIs, `fit_for`, `module_count`, `modules`, `ShipFit.*`, `Repairs.*` | 310–313 | brief §3 rule 4 |
| §4 item 13: the six legacy rows, `upgrade()`, `upgrade_ids()`, `has_upgrade`, `installed_upgrades`, `install_upgrade` and the `upgrades` record removed; the v5 migration (idempotent, called when version < 5); the fitting surface is **FITTING** | 314–324 | brief §3.1 `retire_legacy_upgrades` pin + rule 1 (migration) |
| §7 note: the fitting surface is **FITTING**; a mandatory cell may be replaced but never left empty (`clear_fit_slot` refuses `MANDATORY_SLOT_KEYS`) | 388–393 | brief §3.1 + owner task, §7 note |

## 3. docs/gameplay/10_ship_acquisition.md

| Pinned item | Line(s) | Source |
|---|---|---|
| §6's interim note gains: the install surface beside OUTFITTING's shop is **FITTING** (`STATION_HUB.md` §5.3), requesting the composed transactions `PlayerProfile.fit_module_at` / `PlayerProfile.clear_fit_slot` (CONTRACTS §13), never mutating the profile directly; OUTFITTING buys, FITTING installs/swaps/removes | 169–174 | owner task, §6 interim note |

## 4. docs/gameplay/15_module_affixes.md

| Pinned item | Line(s) | Source |
|---|---|---|
| §6 note (dated): affixes are the **next** wave; this one's fitting surface aggregates the inventory **by module id** (`OWNED ×<n>`, STATION_HUB.md §5.3) and stores base ids — no `{base_id, rarity, prefixes[], suffixes[]}` instances created, no roll at purchase or drop; reversal none owed, the instance shape is 15's own | 117–124 | brief §7 owner tick 5, verbatim |

## 5. docs/CONTRACTS.md

| Pinned item | Line(s) | Source |
|---|---|---|
| §13 heading | 1087 | brief §3 |
| `## autoload/player_profile.gd — additive beyond §12's pin.` code block: `SAVE_VERSION := 5` (was 4; v4 still reads, `MIN_READABLE_VERSION` 1), `LEGACY_UPGRADE_MODULES` (the six-row retirement table, 09's own), `EVENT_FIT_MODULE := "FIT_MODULE"`, `fit_module_at`, `clear_fit_slot`, `retire_legacy_upgrades` | 1091–1123 | brief §3.1, verbatim (byte-for-byte, including comments) |
| Rule 1: the mandatory-key list is **not** re-declared; `FitData.MANDATORY_SLOT_KEYS` (`game/ship_fit.gd:117`, `[&"engines", &"power"]`) is the one source, exactly as `FitData.FIT_SLOT_KEYS` at `player_profile.gd:456` | 1127–1129 | brief §3 rules, verbatim |
| Rule 2: the migration is a one-way door; `has_upgrade` / `installed_upgrades` / `install_upgrade` / the `upgrades` key removed; v1–v3 still load; the fixture | 1130–1135 | brief §3 rules, verbatim |
| Rule 3: `fit_module_at` never half-writes; displacement before take | 1136–1137 | brief §3 rules, verbatim |
| Rule 4: `clear_fit` stays; `clear_fit_slot` is the per-cell remove | 1138–1139 | brief §3 rules, verbatim |
| Rule 5: the pane never mutates directly; the allowed call set | 1140–1142 | brief §3 rules, verbatim |
| Rule 6: legality previewed, not enforced twice | 1143–1145 | brief §3 rules, verbatim |
| Numbering note: the brief duplicates "2."; §13 numbers 1–6 in reading order, no text change | 1147–1148 | editorial record of the transcription |
| Consumer rules (the `STATION_HUB.md` §5.3 amendment): Rail / Anatomy (SLOT LAYOUT + OWNED MODULES) / ACTION per state / power meter / hover / refusals / focus order / empty states | 1150–1186 | brief §3.2, verbatim |
| LAUNCH's service rows (the `STATION_HUB.md` §5.4 amendment): `REFUEL` / `RECHARGE`, free and instant, no price column, no credits move (14 §1's rate, `FREE_FEE` 0); refusal states rendered never hidden | 1188–1194 | brief §3.3, verbatim |
| §10 changelog line **v0.5** recording the wave, the two drifts, and that §9's figure is R1's to move (pre-wave gate stands at the recorded 389, no post-wave count claimed) | 1501–1530 | brief §8 close-out; §9 |

## 6. Drift notes (for W1, W2, R1)

1. **`FIT_MANDATORY_KEYS` does not exist and must not be created.** The dispatcher's and
   W1's prompts name it; the brief's rule 1, landed verbatim in §13 (line 1127), says the
   mandatory-key list is **not** re-declared and `FitData.MANDATORY_SLOT_KEYS`
   (`game/ship_fit.gd:117`) is the one source. If W1 finds the prompt contradictory, the
   law is the brief: implement no new constant and read the list from `FitData`.
2. **Rule numbering.** The brief's list numbers two rules "2."; §13 lands six rules (1–6) in
   reading order, text unchanged. Reading-order mapping: migration → 2, never half-writes → 3,
   `clear_fit` stays → 4, pane never mutates → 5, legality previewed → 6.
3. **§9's gate figure is not moved by D0.** The brief's D0 row says it "moves when R1
   measures it"; the v0.5 entry records the pre-wave gate at the P2-B1 close-out's 389 and
   no post-wave count.
4. **Consistency edits (documented, not design):** every retired-surface reference in
   STATION_HUB sections 1, 2, 3.1 (node list only), 5, 8, 10, 11, 12 was renamed or
   annotated so no live pane is named UPGRADES; §3.1's measured `Upgrades*` node rows /
   `UPGRADES` column set and §13's mockup verification table remain as the mockup's
   measurement record, flagged in the header amendment. No number changed anywhere in the
   process.