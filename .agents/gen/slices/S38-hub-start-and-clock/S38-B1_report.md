---
slice: S38
worker: S38-B1
model: hyper/deepseek-v4.1-flash (--reasoning-effort xhigh)
status: actionable
gate: "1226/0 → 1229/7 ×2 identical (the 7 are pre-H1 test premises outside this worker's file set; see A6/Follow-ups)"
---

# S38-B1 report

## Result
A1–A5 landed and measured. The probe's cold start moves from **0 rows** and the scene's
placeholder pair to **6 rows** and `["Halcyon Anchorage", "forge-grey bastion, the full
menu"]`; the U22 readout moves on its own (`09:49` → `09:48`, 1.2 s apart) and the boundary
re-roll lands the next band's board in place. The new suite `test_s38_start_and_clock.gd`
(**10 rows, all green**) is the wave's gate growth. A6 records the gate ×2 and **7 red rows
that are all pre-H1 test premises in files outside `VAJB_WORKER_FILES`** (the hook refused
the edits) — 2 of them the brief's §8 pre-authorised, 5 not listed in §8 at all.

## Acceptance list answers
- **A1 — done.** `StationRegistry.starting_station()` = `primary_for(SectorRegistry.DEFAULT_SECTOR_ID)`
  (station_registry.gd:281-284); both seams answer it for an empty filed id
  (station_registry.gd:288-296, :305-312); `game.gd` reads the constant from the registry
  (game.gd:112-114, :828, :975) and files the sector's own id when it has no primary row
  (game.gd:1460-1472). Probe: `start filed_id= row_empty=false board=6 empty_text=`,
  `start docked_id=s1_primary`, `start plate=["Halcyon Anchorage", "forge-grey bastion, the full menu"]`.
- **A2 — done.** U22's readout is one `StationCaption` at the right end of the U3 strip
  (contracts_panel.gd:216-226), reading `BAND_SECONDS − now % BAND_SECONDS`
  (contracts_panel.gd:540-545). Probe: `remaining=589 arithmetic=589 band_seconds=1200`,
  `timer_wait=1.0 one_shot=false running=true`, `second=NEW JOBS IN 09:48 moved=true`.
- **A3 — done.** `_tick` re-rolls once when the band changes (contracts_panel.gd:526-538).
  Probe (clock pinned to the band edge): `before_band=1492942 after_band=1492943
  expected_band=1492943`, `readout=NEW JOBS IN 20:00`, `rows_are_next_band=true
  rows_changed=true`; suite row asserts the same panel object and scene (no scene change).
- **A4 — done.** S7 files `sector_7` and resolves to no place; a null profile and an
  unparseable id unchanged (suite rows `test_a4_s7_and_the_two_unchanged_paths`,
  `test_a4_the_dock_files_the_sectors_own_id_with_no_primary`).
- **A5 — done.** T-156: one dimmed inner box per staged row, `modulate == text_dim`, the type
  icon under it (contracts_panel.gd:302-307, :676-684). T-157: an accepted row leaves the
  board and a second accept of the same id is refused (contracts_panel.gd:454-480).
- **A6 — RECORDED, NOT GREEN.** Gate ×2 on fresh scratch stores, both
  `[SUMMARY] passed=1229 failed=7`; the 7 rows are enumerated in Follow-ups with their
  reason and exact re-cut. Nothing else moved.

## Deviations from SLICE.md
- `ui/station/contracts_panel.tscn` untouched: the U22 readout is built in `_build_headers()`
  beside the four U3 labels it shares the strip with (a scene child would sort before the
  code-built headers). Reversal: a scene node plus an insert-at-0 in `_build_headers`.
- The tick timer runs always (`autostart = true`), not gated on `visibility_changed` like the
  refinery's: the readout is a clock, so a hidden deck must not miss the boundary (H3's "no
  player action"). Reversal: the refinery's start/stop pair.
- `column_headers()` skips the readout (contracts_panel.gd:786-792) so U3's four headers stay four.
- T-157's filter lives in the panel (`_without_active`), not in `ContractRegistry.board`: the
  pinned signature and every S25 number stay byte-identical (rule 1), and `board()` is the
  station's offer, not the session's.

## Moved values (with reversal and tick)
| Value | Where | Tick | Reversal |
|---|---|---|---|
| `ROLL_FORMAT := "NEW JOBS IN %s"` | contracts_panel.gd:99 | U22 | the U8 caption alone, no countdown |
| `TICK_SECONDS := 1.0` | contracts_panel.gd:98 | U22 | the U8 caption alone |
| `DEFAULT_SECTOR_ID := &"sector_1"` | sector_registry.gd:40-45 | H1 | the constant returns to `game.gd` and the cold start falls back to nothing |
| `game.gd SECTOR_ID_DEFAULT` retired (was :113) | game.gd:112-114 | H1 | restore the constant and read it at :828/:975 |
| an empty filed id means "no run has filed a place" | station_registry.gd:288-296; game.gd:1464-1472 | H1 | an empty id means "no station" again; the scene's placeholder copy returns |

## Evidence
- `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200` ×2 → `[SUMMARY] passed=1229 failed=7` both times (pre-change baseline 1226/0).
- `... res://tests/probe_s38_start_board.tscn --quit-after 1200` → the `[S38P]` lines quoted in A1–A3, plus the probe's own negative controls `board_of_empty_row=0` and `band next_roll_differs=true`.
- The probe's first run also caught the timer bug: `running=false moved=false` before `autostart`, `running=true moved=true` after.

## Files touched
- `game/sector_registry.gd` — `DEFAULT_SECTOR_ID` plus the header note.
- `game/station_registry.gd` — `starting_station()`, the empty-id answers in both seams, header note.
- `game/game.gd` — reads `Registry.DEFAULT_SECTOR_ID`; `_file_docked_station` files the sector's own id; `SECTOR_ID_DEFAULT` retired.
- `ui/station/contracts_panel.gd` — U22 (readout, 1 Hz tick, band re-roll), T-156 (whole-row dim), T-157 (`_without_active`), `column_headers()` skips the readout.
- `tests/test_s38_start_and_clock.gd` — NEW, 10 rows (A1–A6).
- `tests/probe_s38_start_board.gd` — cold board, countdown ×2, boundary re-roll (`tests/probe_s38_start_board.gd.uid` is Godot's own generated artifact).
- `.agents/gen/slices/S38-hub-start-and-clock/S38-B1_report.md` — this file.
- Read, no change needed: `game/contract_registry.gd`, `ui/station/contracts_panel.tscn`, `ui/screens/station.gd`, `ui/station/overview_panel.gd`.

## Follow-ups
**Bucket 2** — every red row is a test premise that used an *empty filed id* as a proxy for
"not at a station"; H1 makes that mean "at Halcyon Anchorage". All 7 live in files outside
this worker's declared set, so the hook denied the edits: they need the file set extended
(or F1, whose set already carries `vajb-orbit/tests/`, lands them).

| Row | Why | Exact re-cut |
|---|---|---|
| `tests/test_s17_gate_edges.gd:281-282` | `REGISTRY_MD5` freezes `game/sector_registry.gd`, which H1 must edit | `REGISTRY_MD5 = "71e7d4f488b510d70e09f6f65540b840"` |
| `tests/test_s24_world.gd:306` (§8-listed) | H1: an empty id answers the starting place | assert `docked_station(profile)["id"] == "s1_primary"` and `docked_station_id(profile) == &"s1_primary"` |
| `tests/test_s24_world.gd:505-506` (not in §8) | the "no station" leg now resolves `s1_primary`, so the Champion standing prices the repair | file `&"sector_7"` instead of `&""` |
| `tests/test_s25_contracts.gd:1176-1179` (§8-listed) | H1: an empty id offers the starting board | assert `board_rows().size() == 6` and `empty_state_text() == ""` |
| `tests/test_s29_station_panels.gd:195` (not in §8) | the cold start is Concord, so `e_hyperdrive`'s engines family reads `apply_price(12 000) = 10 200` | expect `"10 200 CR"` |
| `tests/test_s29_station_panels.gd:265-268` (not in §8) | the same discount on the shortfall copy | expect `"REFUSED · NOT ENOUGH CREDITS · 10 200 NEEDED"` |
| `tests/test_s3_auction.gd:445` (not in §8) | `listing_rows` prices through `_station_price` → `apply_price` with the starting row, so a Concord-family plain row reads 0.85 × list | compare against `StationRegistry.apply_price(list, StationRegistry.docked_station(profile), 0, base)` |

T-156 and T-157 are closed in code by this wave. No other LOW item was raised.

---

## Orchestrator addendum (developer session, 2026-10-08)

**Bucket 2 — the tests-that-moves list, landed by the orchestrator.** B1's
follow-up table was correct and complete: its gate read `1229/7`, the seven red
rows were exactly the seven it listed, and every one is a premise that used an
*empty filed id* as a proxy for "not at a station" — which H1 redefines. The
file sets are the collision-avoidance mechanism, so they were **not** widened;
the developer session re-cut all seven rows by hand, the same intervention S28
disclosed (`test_s23_content.gd` / `probe_s23_r1.gd`'s `fee_for` call sites).

Gate after the re-cut: **`passed=1236 failed=0`** (1226 baseline + B1's 10 new
rows). The brief's §8 table has been extended with the four rows it had missed
and now carries the intervention, its reason and its reversal.

| Row | Re-cut | Why this preserves the row's intent |
|---|---|---|
| `tests/test_s17_gate_edges.gd:56` | `REGISTRY_MD5` → `71e7d4f488b510d70e09f6f65540b840` | the hash still locks both S17-forbidden files; the comment records it as the third re-pin (S23, S24 precedent) |
| `tests/test_s24_world.gd:301-312` | the seam test asserts `s1_primary` from both seams, doc comment restated | this row *is* the seam's own test, so the starting place is the law's own answer, not a workaround |
| `tests/test_s24_world.gd:512` | `&""` → `&"sector_7"` | `sector_7` carries no station row, so the leg still proves the section 6 number (692) |
| `tests/test_s25_contracts.gd:1171-1176` | `&""` → `&"sector_7"` | keeps U8's second empty state (`EMPTY_NO_JOBS`) proven verbatim, rather than asserting the starting board |
| `tests/test_s29_station_panels.gd:35/60/72/84` | `setup()` files `&"sector_7"`; `_docked_station` saved and restored | restores the factor 1.0 fixture the suite always had, so both list prices (12 000) stand |
| `tests/test_s3_auction.gd:428-431` | the profile files `&"sector_7"` | keeps the test's stated premise that the hot slot is the *only* discount |

Nothing was fixed at the wave's own sites: B1's A1–A5 code is untouched by this
addendum, and the re-cuts are confined to the seven rows above.

