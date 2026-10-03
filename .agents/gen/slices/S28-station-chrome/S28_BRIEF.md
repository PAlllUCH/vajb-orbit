# S28 — Station chrome quick-fix wave (wave brief)

**Wave:** S28 (coder lane, item 34 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S28-station-chrome/`
**Owner go (2026-10-03):** "rest of the station chrome from report needs to be
fixed as well" plus the mechanical halves of his items 1–2 (the inspector
cure, the button unification on surviving panels). Runs beside D18 (disjoint
files) and before S29 (which rewrites the merged panels on D18's law).

## 1. The law to read, in order
1. `slices/S28-station-chrome/SLICE.md` — scope, file sets.
2. `docs/design/UI_SPEC.md` **§8** (P1–P3: the two button tokens, the action
   cluster placement, the one focus language) — the chrome you implement.
3. `docs/design/STATION_HUB.md` **§16 P6** (the inspector lifecycle; S28 ships
   the mechanical clear only).
4. `docs/design/UI_SPEC.md` §3.10 **A5.1–A5.4** (composition law).
5. `.agents/gen/slices/D17-playtest-pass/D17-P1_report.md`,
   `D17-P2_report.md`, `D17_synthesis.md` — the defect list (§6 cites them).
6. The §5 extract.

## 2. The owner's request (verbatim, `D16_UserInput.md`)
> "Station: 1. fix bottom inspector band going stale 2. unification of
> buttons. the same sizes, the same sprites/chromes best if even kept in the
> same lauouy between planes … rest of the station chrome from report needs
> to be fixed as well"

## 3. What is already measured (file:line)
| Fact | Site |
|---|---|
| the button tokens + focus law to implement | `docs/design/UI_SPEC.md` §8 (P1–P3) |
| the inspector nodes and the signal system | `ui/screens/station.tscn:214`, `station.gd:150-151`, `tests/test_s11_inspector.gd:140-233` |
| the stale-band defect (both reviewers) | `D17-P1_report.md:27`, `D17-P2_report.md:30` |
| the six shipped button sizes (the reversal) | `D17-P2_report.md:17` |
| CONTROLS: Q triple-bound, E double, TURN unbound | `D17-P1_report.md:21`, `D17-P2_report.md:14` |
| the `NO_DAMAGE_REPORT` strip + its test pins | `D17-P2_report.md:54`, `tests/test_p2b_services.gd:667`, `tests/test_p1_repairs.gd:128,139` |
| shield 450 (shipyard) vs 400 (launch briefing) | `D17-P2_report.md:55` |
| SELL ALL RAW enabled at zero raw | `D17-P2_report.md:33` |
| stepper defaults to whole stack | `D17-P2_report.md:34` |
| holdings table without headers | `D17-P1_report.md:39` |
| `MINE BACK` possible typo | `D17-P1_report.md:40` |
| dev-speak strings in player panels | `D17-P2_report.md:22` |
| DevTuningMenu preloaded into flight | `game/game.gd:39`, pinned by `tests/test_s13_devmenu.gd` |
| credits box reflow | `D17-P2_report.md:21` |
| fractional origins at 105 % scale | `D17-P2_report.md:20` |
| auction shelf tag vs 5 hulls | `D17-P2_report.md:37` |
| quit-dialog hangar copy on the top menu | `D17-P2_report.md:9` |
| splash progress line legibility | `D17-P1_report.md:11` |
| plural grammar rows | `D17-P2_report.md:46` |

## 4. Pinned interface + rules
UI_SPEC §8's token table (verbatim in §5) is the chrome law. Rules:
1. **A5 law**: containers + anchors, never coordinates; chrome by the
   per-surface table; no new art, no new hue.
2. **Scope guard**: touch only the panels S29 does not rewrite (refinery,
   exchange, auction, the LAUNCH panel, the shell, settings, menus). The
   armory/fitting/shipyard/repairs **bodies** are S29's — the only allowed
   touch there is none.
3. **Docs are law, not yours**: a number you cannot derive gets reported in
   the report, never invented, never edited into docs.
4. Every moved test row is disclosed in the report (the L264 lesson).

## 5. Spec extract (verbatim, cited)
`UI_SPEC.md` §8:
> "| **P1** | `ActionPrimary` | **360×56** | `Pressables` plate | the commit
> action: SELL, LAUNCH, REPAIR, REFINE, ACCEPT, BUY (panel-level) |
> | **P1** | `ActionSecondary` | **360×56** | same plate, flat + disabled
> states only | CANCEL, REMOVE, REFUEL, RECHARGE, DEPOSIT, WITHDRAW, SET
> ACTIVE | | **P1** | `ActionInline` | **96×32** | flat chip-button (theme
> `Button`, no asset) | row-corner actions inside data rows (ammo BUY/SELL) |"
> "**P3 — one focus language everywhere.** The focused state of every
> interactive control — station, settings, menus — is §6's existing theme
> row: the 1 px `accent_danger_bright` focus ring …"

`STATION_HUB.md` §16:
> "**P6** | … The shell clears/re-anchors the band on every module switch and
> on unhover-with-no-selection; every pane publishes through the existing
> inspector signal; the band never carries another module's content. …
> S28 ships the mechanical clear (the defect cure)"

## 6. Acceptance list (numbered; every row cites its law + defect)
- **A1** inspector cure: the band clears on module switch (P6's S28 half).
- **A2** CONTROLS: one binding per action per key (Q/E deconflicted);
  TURN LEFT/RIGHT gain defaults or fold behind an advanced row — the
  builder picks one route and discloses it.
- **A3** the LAUNCH confirm strip binds to arm/confirm copy, never the raw
  `NO_DAMAGE_REPORT` token; the reason token keeps its API.
- **A4** shield reads one source: shipyard comparison and launch briefing
  agree (whichever figure is the ship's own stat wins; disclose which).
- **A5** plural grammar: `1 ENGINE` / `1 WEAPON` (a count-aware helper).
- **A6** dev-speak strings become player copy or move out of player panels.
- **A7** DevTuningMenu is gated (debug builds only — `OS.is_debug_build()`),
  release builds never instantiate it.
- **A8** credits box: fixed-width value (min size or tabular alignment), no
  reflow on balance change.
- **A9** integer origins: row/content origins floor after the 105 % scale.
- **A10** `SELL ALL RAW` disables at zero raw stacks.
- **A11** the exchange stepper defaults to 1 and the primary button carries
  the quantity.
- **A12** the holdings table gains HELD / CAP / VALUE headers.
- **A13** the auction shelf tag reads the live count ("5 OF 20 ON SHELF ·
  RESTOCK 20:00"-form).
- **A14** quit dialog: state-neutral copy on the top-level menu.
- **A15** splash progress line one step brighter (13 px `StationCaption`
  family).
- **A16** P1–P3 on the surviving panels: every action button on the two
  360×56 tokens / 96×32 inline, clusters at the P2 placement, focus ring
  unified (settings' ember box retired).

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S28-B1 | coder | `vajb-orbit/ui/, vajb-orbit/game/, vajb-orbit/tests/, .agents/gen/slices/S28-station-chrome/` | `S28-B1_report.md` + the fixes + gate |
| S28-R1 | reviewer | same set + review file | `S28-R1_review.md` |
| S28-F1 | fixer (only if HIGH/MED) | same as B1 | cure note |

Models (owner, 2026-10-03): B1/F1 = `hyper/qwen3.8-flash` @ high; R1 =
`hyper/glm-5.3-flash` @ high.

## 8. Run order + tests
**B1 → R1 → F1 (if HIGH/MED).** Gate law: zero failures, run twice on fresh
scratch; the count moves only by rows this wave adds or re-derives.
**Tests expected to move** (disclose every row):
`tests/test_p1_repairs.gd:128,139` and `tests/test_p2b_services.gd:667`
(the `REASON_NO_DAMAGE_REPORT` strip rows), `tests/test_s5_ammo_cargo.gd`
(the SELL ALL RAW precondition), `tests/test_s11_inspector.gd` (grows the
module-switch clear rows), `tests/test_s3_auction.gd` (the shelf tag + footer
copy), `tests/test_s13_devmenu.gd` (the dev-menu gate), plus any suite
pinning a string this wave rewrites (settings/bindings rows in
`test_s21_stability.gd`).

## 9. Hard rules
- No docs edits; no new art; no coordinate layouts; report ≤120 lines with a
  per-acceptance answer and a cite.

## 10. Staged / deferred
- The B2-1 hover-plate pick (owner); everything in the merged panels
  (armory/fitting/shipyard/repairs bodies, S29); the map deck (S29);
  L260's clock flake (harness owner).

## 11. Owner tick list
None new — P1–P3 and P6's S28 half implement at their PROPOSED value
(unticked rows ship PROPOSED, the S19 precedent).

## 12. Close-out (the orchestrator)
Gate ×2 recorded, `python3 staging/verify_wave.py verify --baseline
s28_start`, WAVEBOARD + `dispatch_coder.md` one-liners, `MASTER_REPORT.md`
§6 recap, wave-boundary commit.
