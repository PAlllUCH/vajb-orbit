# P1 report — Economy core (docs/gameplay 01–05)

**Date:** 2026-09-18. **Worker model:** `opencode-go/deepseek-v4.1-flash` (paid,
$0.15/$0.60) for waves A–D; `deepseek/deepseek-v4-flash` (direct API) for the
recovery, review and fix waves, per the owner's mid-session instruction.
**Status:** code-complete, all gates green, live-verified; waiting only on
owner sign-off of the doc amendments listed at the end.

## 1. What shipped

| Deliverable | File | Doc |
|---|---|---|
| Mineral catalogue + generation data | `vajb-orbit/game/mineral_catalog.gd` | 02 (+11 §1.1) |
| Component catalogue | `vajb-orbit/game/component_catalog.gd` | 03 |
| Exchange (pricing, market, sales) | `vajb-orbit/game/exchange.gd` | 05 |
| Refinery | `vajb-orbit/game/refinery.gd` | 04 |
| Repairs + dock damage report | `vajb-orbit/game/repairs.gd`, `game/game.gd` (edit) | 01 §6 |
| Economy transaction log | `vajb-orbit/game/economy_log.gd` | 01 §7 |
| The one 20-minute clock | `vajb-orbit/autoload/world_clock.gd` (autoload, MCP-registered) | 17 §4 |
| Save v2 migration (all 17 §3 keys + `vitals`) | `vajb-orbit/autoload/player_profile.gd` | 17 §3 |
| REFINERY / EXCHANGE / REPAIRS panels + 7-entry rail | `ui/station/{refinery,exchange,repairs}_panel.{gd,tscn}`, `ui/screens/station.gd` (edit) | STATION_HUB §5.7–5.9 |
| Tests + headless runner | `vajb-orbit/tests/` (7 suites, 53 tests, runner) | 17 §6 |

Docs amended (documented amendments, owner sign-off requested):
`docs/design/STATION_HUB.md` (header, §2 rail table, §5.7–§5.9, §5.7 empty-state
footer, §12.1), `docs/design/IMPLEMENTATION_PLAN.md` §9.7 (rail, panel loading,
save v2, catalogue-owned tints, Phase F glyph wiring),
`docs/gameplay/17_coder_handoff.md` §3 (`vitals` key, owner-approved in-session).

## 2. Test results (17 §6 checklist)

- Headless: `res://tests/headless_runner.tscn` → `[SUMMARY] passed=53 failed=0`,
  exit 0, no `SCRIPT ERROR`. Re-run independently by the orchestrator and by the
  re-reviewer after the fix wave.
- Editor: godot-ai `test_run` → 7 suites, 53 passed, 0 failed.
- Checklist coverage: 05 §3 table (Iron/Titanium/Gold/Krillum at 1.0/0.6/1.6) and
  both 05 §5 worked examples reproduce exactly; 04 "3 Iron ore + 15 CR → 1 Iron
  ingot" exact; save→reload round-trip for every 17 §3 key; v1 profile migrates
  with new keys at defaults and the file stays v1 until a real change; repairs
  §6 example (500 CR at 200/1000 + 300/600); band math 0/1/2/3 bands; log format.
- Boots: `station.tscn` and `game.tscn` headless exit 0 (only the known,
  pre-existing `amb_station_room_01.ogg` leak pair on the station).

## 3. Live verification (editor, `project_run`)

Menu → PLAY → station at 1920×1080; all seven rail entries render; the three new
panels exercised end to end with real input:

- REFINERY: 8 gold ore → REFINE 2: credits 200 379 → 200 349 (−30), 2 ingots,
  leftover 2 ore below threshold, empty state + `BRING RAW ORE FROM THE BELT`.
- EXCHANGE: sold 12 iron ore → +279 (the quote's paid), stack removed, iron demand
  cooled 1.2x → 1.2 (display), board re-priced; queue path verified in tests.
- REPAIRS: fee 500 (the 01 §6 example), REPAIR → credits −500, pools 1000/600,
  `ALL SYSTEMS NOMINAL`.
- `user://economy_log.txt` (kept as evidence) holds exactly the three live lines:
  `SELL, mineral_iron, 12, +279`, `REPAIR, ship_vanguard, 0, -500`,
  `REFINE, mineral_gold, 6, -30`, each with timestamp and post-event balance.

## 4. Spec conflicts found (reported, not silently resolved)

| # | Conflict | Resolution taken |
|---|---|---|
| 1 | 04 §5 says `remove_cargo(mineral_id, 4n)` and pays before taking; 04 §2 and 17 §6 fix 3 ore → 1 ingot | Implemented **3n**, order verify → take → pay (17 §5 law); 04 §5 flagged to the designer |
| 2 | 05 §2's raw-ore aside "18 × 0.98 = 17" contradicts the round() formula and the 05 §3 table (63.7 → 64) | Implementation follows the formula/table; aside flagged |
| 3 | 05 §8 names `exchange_price(id, is_ingot, is_component)` and `last_band_time`; shipped `exchange_price(item_id, demand)` and `last_band` | Shipped shapes are the documented ones; 05 §8 flagged for amendment |
| 4 | 05 §2 "20 minutes of real playtime" vs a clock that risks accruing while closed | Clock is system Unix time (bands since last stamp), documented in `world_clock.gd`; flagged |
| 5 | 02 §2 tier headings vs 11 §1.1 sector mixes | 11 §1.1 (self-declared supersession) used; headings flagged |
| 6 | 02 §2 spells ids `mineral_krilium` while prose says "Krillum" | Doc ids used as written |
| 7 | 03 §4.1 gives no hexes for grade I/II | ICONS_SPEC §8.6 sanctioned hexes reused; noted |
| 8 | 01 §6 repairs had no state source (17 §3 has no hull key) | Owner chose option A in-session: documented `vitals` key added |

## 5. Decisions and known items

- Post-re-review polish (after `p1r2_report.md`): the dedicated-glyph render was
  corrected to the white `tint/` stencil + `Tokens/text_primary` (raw dark masters
  were invisible on the dark rows — caught in the live screenshot), which also
  closes p1r2 N1 (missing-glyph fallback now checks stencil existence first) and
  N2 (the derived stencils are reachable again); the board meta now reads
  `INGOT · <baseline> CR BASE`, closing N4 (demand no longer printed twice, kind
  caption restored). N3 (no permanent unit test for the panel icon branch) is
  accepted: panels are covered by the live pass and the headless boot; N5 is the
  item below.
- `commission_for(0) = 0` and every payout `maxi(0, gross - fee)` — found by the
  module probe (an empty-stock queue sale would otherwise have debited 10 CR).
- Component overflow over quota queues and pays out at the next band (05 §4 read
  literally); `SELL ALL RAW` includes components, ingots sell stack by stack.
- Phase F mineral/ingot glyphs were moved into the project mid-session; the
  catalogue now points at them (ICONS_SPEC §8.1 "retire the 02 §6 fallback") and
  the panels render the dedicated family through the white `tint/` stencil with
  `Tokens/text_primary` (the first fix wave drew the raw dark masters — caught in
  the live screenshot, corrected, re-verified live).
- Pre-existing, not fixed (out of P1 scope, listed in p1r): rail LOG OUT skips the
  STATION_HUB §2/§5.5 confirm overlay; `_mockup_station.*` deletion pending the
  S-verification close-out.
- Known low-risk edge (p1r2 N5): a re-entrant listener that advances the market
  clock mid-sale can still displace a component restock delta; the sale re-reads
  the market after the emits, the scenario needs a listener calling
  `evaluate_market` with advanced time during a transaction, and the regression
  suite covers the mineral re-entrancy path.
- Dev `user://profile.cfg` reset (backup `.agents/gen/profile_backup_20260918.cfg`)
  so the next boot starts at the documented 10 000 CR defaults.

## 6. Evidence chain

Briefs/reports: `.agents/gen/p1{a,b,c,d,e,f,h,i,j,k,l,l2,fix,r,r2}_*.md`; kept
runner logs (`.agents/gen/p1h_run8.txt`, `p1l_run.txt`); live screenshots were
returned inline to the session (not saved); `economy_log.txt` in user data.

## 7. Owner decisions requested

1. Sign off the STATION_HUB.md P1 amendments (§2 rail, §5.7–5.9 panels, corrected
   exchange columns, empty-state footer) — the panels were built under the
   in-session "reuse confirmed, proceed, document" answer.
2. Confirm the Phase F glyph wiring (data edit) and the `deepseek` provider
   switch stays the default for later phases.
3. P2 (ships: 08/09/10) is next once this is accepted.
