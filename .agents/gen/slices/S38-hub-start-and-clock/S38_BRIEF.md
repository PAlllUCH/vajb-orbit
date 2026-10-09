# S38 — The board's clock and the hub's cold start (wave brief)

**Wave:** S38 (code lane, the owner's 2026-10-08 playtest finding)
**Slice folder:** `.agents/gen/slices/S38-hub-start-and-clock/`
**Baseline:** the gate after S25's close — **1226/0** (record it in the report);
`python3 staging/verify_wave.py snapshot --name s38_start` before the first dispatch.
**Runs before S26** (both touch `game/` and `ui/screens/station.gd`; one live
session, one file holder).

## 1. The law to read, in order
1. `slices/S38-hub-start-and-clock/SLICE.md` — scope, file sets, the ID note.
2. `docs/gameplay/14_station_services.md` **2026-10-08 S38 block** (the law:
   H1–H3, each with its reversal) — then §2 and §9 as context.
3. `docs/design/STATION_HUB.md` §15.2 (the CONTRACTS panel law, U3–U8, and
   **U22** the countdown row), §15.6 (U21/U22 in the presentation table), §15.5
   (the name plate), §15.1 (the SERVICES strip).
4. `docs/CONTRACTS.md` §24 (S24's docked-station seam, which H1 extends) and
   §26 (S25's registry, reward law and the three exits) — **by range only**
   (`rg -n '^## §'`, then `view --offset … --limit …`).
5. `docs/CODE_MAP.md` — by range.
6. The §5 spec extract below.

## 2. The owner's request (verbatim)
> "one thing. there is 20 minute refresh timer for contrats but i cannot see in
> real time how much time is left for refresh and there should be contracts on
> the start"

## 3. What is already measured (file:line, 2026-10-08)
Everything below is read off the shipped tree by the orchestrator's probe
(`vajb-orbit/tests/probe_s38_start_board.tscn`, run on a fresh sandboxed
profile); the probe ships in B1's file set and its lines are the evidence.

| Fact | Site / reading |
|---|---|
| the menu's PLAY routes straight to the hub, so no game run ever files the place | `ui/screens/main_menu.gd:223` (`ROUTE_STATION` if the route exists) |
| the only writer of the docked place | `game/game.gd:1458 _file_docked_station()`, called at `:1440` in the docking route |
| a fresh profile clears the place | `autoload/player_profile.gd:2158` (in `reset_to_defaults`) |
| the seam's current answers | `game/station_registry.gd:283 docked_station_id()`, `:293 docked_station()`, `:306 primary_for()` |
| the board an empty row answers | `game/contract_registry.gd:204 board()` → `rows = []` for an empty row |
| **cold start, measured** | `filed_id=` (empty) · `row_empty=true` · `board_of_empty_row=0` · panel `board=0` · `empty_text=NO OPEN JOBS — NEW JOBS ROLL ON THE 20-MINUTE CLOCK` · `board_empty_visible=true` |
| the plate at cold start | `["ORBITAL DRYDOCK KEPLER-9", "DOCKING RING 04 · HELIOS DRIFT · HULL TRAFFIC LOW"]` — the **scene's** mockup-era copy (`ui/screens/station.tscn:129`, `:135`), because `ui/screens/station.gd:998 _apply_identity()` writes the labels only for a non-empty row |
| the same root cause reaches every other reader | `ui/station/overview_panel.gd:552` (`station.is_empty() or offers(...)` → every service row reads available) · `:580` (the vault record reads 0) · S24's price law needs the row |
| **with the place filed + a refresh, measured** | `board=6` · first row `haul · 4 500 CR · 40× ingot_aluminium to Marchgate Post` |
| the roll's arithmetic | `autoload/world_clock.gd:18 BAND_SECONDS := 1200`; `elapsed = now % 1200`; probe read `remaining=667`; the next band's board differs (`next_roll_differs=true`) |
| the panel has no clock at all | `ui/station/contracts_panel.gd` — no `_process`, no `Timer`, no time readout; the board re-derives only in `_refresh()` (`:422`, mount + profile writes) |
| the tick idiom to copy | `ui/station/refinery_panel.gd:57 TICK_SECONDS`, `:250 _make_tick_timer()`, `:272 _tick()`, `:1191 _mmss()` |
| the starting sector's one home today | `game/game.gd:113 SECTOR_ID_DEFAULT := &"sector_1"` (read at `:826`, `:973`) |
| S7's deliberate empty filing | `game/game.gd:1454-1463`'s own comment: a sector with no station files an empty id and the readers fall back |

## 4. Pinned interface (verbatim) + rules

```gdscript
# game/sector_registry.gd — the starting sector gets one home; game.gd reads it
const DEFAULT_SECTOR_ID: StringName = &"sector_1"   ## was game.gd:113 SECTOR_ID_DEFAULT

# game/station_registry.gd — the cold-start place (H1)
static func starting_station() -> Dictionary
    ## primary_for(SectorRegistry.DEFAULT_SECTOR_ID); {} if that sector has no primary
static func docked_station(profile: Node) -> Dictionary
    ## unchanged for every other input; an EMPTY filed id now answers starting_station()
static func docked_station_id(profile: Node) -> StringName
    ## unchanged for every other input; an EMPTY filed id answers the starting row's id

# game/game.gd:_file_docked_station — the sentinel's meaning becomes exact
## a sector with no primary row files its OWN sector id (S7 files &"sector_7"),
## so an empty id means "no run has filed a place" and nothing else.

# ui/station/contracts_panel.gd — the countdown (H2/H3)
const TICK_SECONDS := 1.0                       ## the refinery panel's idiom
const ROLL_FORMAT := "NEW JOBS IN %s"           ## mm:ss via the _mmss shape (refinery_panel.gd:1191)
func _roll_remaining() -> int
    ## WorldClock.BAND_SECONDS - WorldClock.now() % WorldClock.BAND_SECONDS
```

Rules:
1. **No contract number moves.** The reward law, the gates, the escrow, the
   escort loop and every 14 §2 shape are S25's (`CONTRACTS.md` §26) and stay
   byte-identical. This wave adds exactly two presentation values (`NEW JOBS IN
   %s`, `TICK_SECONDS`) and one sector constant.
2. **H1 applies to an empty id only.** A null profile, an unparseable id and a
   station-less sector keep their current answers (`{}`, and the shell's
   placeholder copy stays as the last resort). Do not "fix" those paths.
3. **The countdown reads the clock, never a stored value.** It must move on its
   own (1 Hz) and it must re-roll the board at zero with no scene change and no
   player action — a readout that can disagree with the rows behind it is the
   defect this wave exists to cure.
4. **S7 must not change.** `game.gd` files the sector's own id there, so
   `docked_station` still answers `{}` and the readers fall back exactly as they
   do today. Prove it.
5. **The riders are T-156 and T-157** (the wave owns `contracts_panel.gd`): the
   staged Expedition row dims **whole** (icon included, `text_dim`), and an
   accepted row **leaves the board** so one job cannot be taken twice in a band.
6. **Layer Cake** (signals up, calls down); containers and anchors only, never
   coordinates (UI_SPEC §3.10 A5.1–A5.3); chrome from the shipped family.
7. Docs are read-only for every worker; `docs/CONTRACTS.md` is R1's alone.

## 5. Spec extract (verbatim, cited)

`docs/gameplay/14_station_services.md`, **2026-10-08 S38 block** (the law):

> **H1 — the hub's cold start.** … **An empty filed id means "no run has filed a
> place" and nothing else.** A sector with no station files its **own sector id** …
> **The starting place is the starting sector's primary.** `SectorRegistry` gains
> `DEFAULT_SECTOR_ID := &"sector_1"` … `StationRegistry` gains
> `starting_station() -> Dictionary` = `primary_for(SectorRegistry.DEFAULT_SECTOR_ID)`,
> and **both** `docked_station` and `docked_station_id` answer it when the
> profile's id is empty, so every reader … agrees, with no write from a screen.

> **H2 — the countdown.** … The U3 header strip's right end carries
> **`NEW JOBS IN mm:ss`** (the countdown at `WorldClock.BAND_SECONDS − now %
> WorldClock.BAND_SECONDS`, two-digit minutes so the maximum reads `20:00`),
> ticking at **1 Hz** …

> **H3 — the re-roll at zero.** When the countdown reaches 0 the panel re-rolls
> its own board (one `_refresh()` …) with no scene change and no player action.

`docs/design/STATION_HUB.md` §15.2, the new **U22** row:

> | Roll countdown | right end of the header strip, one `StationCaption` readout:
> `NEW JOBS IN mm:ss` at `WorldClock.BAND_SECONDS − now % WorldClock.BAND_SECONDS`
> (two-digit minutes; the maximum reads `20:00`), ticking at **1 Hz** … At `0` the
> board re-rolls and the readout restarts at `20:00` … Reversal: the U8 caption
> alone, no countdown. **U22** |

`docs/design/STATION_HUB.md` §15.6's **U22** row: the string `NEW JOBS IN mm:ss`
(e.g. `NEW JOBS IN 11:07`).

`docs/gameplay/14_station_services.md` §2 (unchanged, the board's own law):

> "Data-driven job list; new jobs roll on the 20-minute station clock."

`docs/CONTRACTS.md` §24 (the seam H1 extends — read by range):

> `static func contracts_visible(standing: int) -> bool` · the docked-station
> profile seam, filed by `game.gd`

## 6. Acceptance list (numbered; the report answers each with a cite)
- **A1 (cold start):** the hub entered with no filed place offers the full board —
  the probe's cold-start reading moves from **0** rows to **6**, and the plate
  reads the row's own name + character line, not the scene's placeholder copy.
- **A2 (the countdown):** the header strip carries `NEW JOBS IN mm:ss` reading
  `BAND_SECONDS − now % BAND_SECONDS`, and it **moves on its own** (a 1 Hz tick
  the probe observes changing between two reads one second apart).
- **A3 (the re-roll):** at zero the board re-rolls in place — the next band's
  rows appear and the readout restarts at `20:00`, with no scene change and no
  player action (the probe drives the boundary directly, not by waiting 20
  minutes).
- **A4 (S7 unchanged):** a sector with no primary still resolves to no place
  (`docked_station` `{}`, the plate's fallback intact), and a null profile and an
  unparseable id are unchanged.
- **A5 (the riders):** T-156 — the staged Expedition row dims whole, icon
  included; T-157 — an accepted row leaves the board, so the same id cannot be
  accepted twice in one band.
- **A6 (the gate):** ×2 hermetic on fresh scratch stores; every moved row
  enumerated (see §8) with its reason; the probe's lines recorded.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S38-B1 | coder (builder) | `game/sector_registry.gd, game/game.gd, game/station_registry.gd, game/contract_registry.gd, ui/station/contracts_panel.gd, ui/station/contracts_panel.tscn, ui/screens/station.gd, ui/station/overview_panel.gd, tests/test_s38_start_and_clock.gd, tests/probe_s38_start_board.gd, tests/probe_s38_start_board.tscn` (+ its report) | A1–A6: the cold-start place, the countdown, the re-roll, the two riders, the suite |
| S38-R1 | reviewer | `vajb-orbit/tests/, docs/CONTRACTS.md` (+ its review) | the re-measured grade, CONTRACTS §9/§10 (and a §27 if it pins the wave's interface), the findings |
| S38-F1 | fixer (only on HIGH/MED) | B1's set + `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S38-hub-start-and-clock/` | the HIGH/MED fixes only |

## 8. Run order + the tests that move
**B1 → R1 → F1 only on HIGH/MED.** Expected gate growth: **+
`test_s38_start_and_clock.gd` rows (one per AC)** only.

| Suite | Row | Why | Verdict |
|---|---|---|---|
| `test_s24_world.gd:306` | `test_a_place_resolves_from_the_profile_seam`, first assertion (`"nothing filed, no place"`) | H1: an empty id now answers the starting place | **moved** — asserts `s1_primary` from both seams (and its doc comment restated) |
| `test_s25_contracts.gd:1171-1179` | `test_a7_the_two_empty_states`, second half (empty id → `EMPTY_NO_JOBS`) | H1: an empty id now offers the starting board | **moved** — files `&"sector_7"`, a place that genuinely offers nothing, so U8's second state stays proven |
| `test_s25_contracts.gd:1204-1207` | `test_a8_the_launch_line_names_the_docked_sector`, last leg | H1: the empty-id line now names the starting sector | **outcome unchanged** (still no `HELIOS`) but its wording is stale — restate |
| `test_s24_world.gd:307, :322-323` | the null-profile and unparseable-id legs | H1 covers the **empty** id only | unchanged |
| `test_s25_contracts.gd` A7 rows | the staged-row dim (T-156) and the accepted-row filter (T-157) | the panel's own behaviour changes | unchanged — the riders' own rows are in `test_s38_start_and_clock.gd` |

**Added at dispatch (bucket 2, orchestrator, 2026-10-08).** B1's first gate read
`1229/7`: the table above listed three rows, but H1 reaches **four more**, all of
them premises that used an *empty filed id* as a proxy for "not at a station".
B1 reported them and left them (its file set did not hold those suites, and the
worker-files hook refused the edits); the developer session re-cut all seven by
hand and the gate then read `1236/0`. The four this table had missed:

| Suite | Row | Why | Verdict |
|---|---|---|---|
| `test_s17_gate_edges.gd:56` | `REGISTRY_MD5`, the frozen hash of `game/sector_registry.gd` | H1 moves the starting-sector constant into that file, which the hash freezes | **moved** — re-pinned to `71e7d4f488b510d70e09f6f65540b840` (the third re-pin; S23's and S24's are its precedents) |
| `test_s24_world.gd:505` | `test_the_band_multiplier_moves_the_repair_fee`, last leg | the "no station" leg filed `&""`, which H1 now reads as the cold start (Concord at Champion → 623, not the Neutral 692) | **moved** — files `&"sector_7"`, so the leg still proves the section 6 number |
| `test_s29_station_panels.gd:195, :265` | `test_the_hyperdrive_row_is_visible_at_tier_3`, `test_the_buy_flow_checks_credits_first` | the suite mounted with no place filed, so H1 priced `e_hyperdrive` through the starting row's Concord engines discount (`12 000` → `10 200`) | **moved** — `setup()` files `&"sector_7"` (with `_docked_station` saved and restored in `suite_setup`/`suite_teardown`), restoring the factor 1.0 fixture the rows always meant; both numbers stand |
| `test_s3_auction.gd:445` | `test_the_hot_slot_arithmetic` | the shelf's plain rows price through `_station_price`, so the cold start's station discount became a second discount and the test's stated premise ("the one discount") broke | **moved** — the profile files `&"sector_7"`, so the hot slot stays the only discount |

Every one of the seven is a **premise re-cut**, not a number moved: the four
`&""` → `&"sector_7"` sites restore the exact "not at a station" fixture the
rows were written against (`sector_7` carries no station row, so `docked_station`
answers `{}` and the price factor is 1.0), and the one row that genuinely
changed is S24's own seam test, where the starting place is the law.

Any other count moving is a bucket-2 pause: report it, leave it, stop.

## 9. Hard rules
- Docs read-only (14's S38 block and STATION_HUB's U22 are the pin as landed).
  `--forbidden` at verify: `vajb-orbit/project.godot`, `vajb-orbit/addons/`.
  (Note: `verify_wave.py --forbidden` matches **exact relative paths**, so a bare
  `docs/` covers nothing — the docs discipline is the workers' own.)
- No art, no new chrome: `icon_contract_*` ships; the countdown is a
  `StationCaption` on the shipped strip.
- Bounded runs, scratch `XDG_DATA_HOME`, no shell edits, Layer Cake. The clock's
  constants come from `WorldClock` — never re-derived, never hardcoded.
- A number you believe is wrong is reported with its bucket and left in place —
  the brief is law.
- Worker reports ≤120 lines (REPORT template), the review ≤150 (REVIEW).

## 10. Staged / deferred
- **T-155** (the gate-log salvo jitter) stays where it is; **T-153** rides S27.
- Expedition going live, INSURANCE/VAULTS and the boss payouts are **S26's**.
- The plate's scene placeholder strings (`station.tscn:129/:135`) are **kept** as
  the reversal path for H1 — they become unreachable in normal play, which is
  the point; deleting them is a separate call.

## 11. Owner tick list (unticked ⇒ the PROPOSED value ships)
| Tick | Row | PROPOSED | Reverse by |
|---|---|---|---|
| H1 | the cold-start place | the starting sector's primary (`sector_1`), resolved read-only by the registry | every reader falls back to nothing; the scene's placeholder copy returns |
| H2 | the countdown | `NEW JOBS IN mm:ss` at the U3 strip's right end, 1 Hz | the U8 caption alone, no countdown |
| H3 | the re-roll | the board re-rolls in place at zero | the board changes only on the next mount |

## 12. Close-out (the orchestrator)
1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s38_start --forbidden
   vajb-orbit/project.godot vajb-orbit/addons/ --tests --expect-reports
   .agents/gen/slices/S38-hub-start-and-clock/S38-B1_report.md
   .agents/gen/slices/S38-hub-start-and-clock/S38-R1_review.md`
3. `python3 staging/build_code_map.py` — the map must describe the shipped tree
   (deterministic; a no-change re-run diffs nothing).
4. CONTRACTS §9's measured block + §10's changelog row (R1's), and §27 if the
   wave's interface is pinned; the CONTRACTS index regenerated.
5. WAVEBOARD + `dispatch_coder.md` one-liners; `LOW_BACKLOG.md` (T-156/T-157
   close, or a new id at the next free read at write time); `MASTER_REPORT.md` §6
   recap; wave-boundary commit.
6. Then item 32 (S26) resumes — it flips the `staged` Expedition row live and
   fills the SERVICES strip's INSURANCE/VAULTS placeholders.
