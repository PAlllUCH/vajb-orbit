---
slice: S26
reviewer: S26-R1
verdict: blocked          # HIGH F1 remains; MED F2-F5 go to one fixer pass (S26-F1)
gate: "1237/0 (s26_start) -> 1258/0 x2 hermetic"
---

# S26-R1 review

Graded against the brief's §5 extract only (14 §3/§4/§5 + the 2026-10-08 S28 block,
06 §3.4, 08's 2026-09-27 P3 block, STATION_HUB §15.3/§15.4), never against B1's
report. Every number below re-measured by my own probe (`tests/probe_s26_r1.gd`,
scratch store, own seeds) or re-read off the shipped code.

## Acceptance list

- A1 — pass — `npc_registry.gd:236-247` places The Boneyard (S3, Meridian) and The
  Pyre (S6, Choir); `game.gd:_build_arena_zone` builds 8 pylons + 8 barricades on the
  r 1200 ring from the shipped renders as a sector child; an idle entry spawns nothing
  (probe R10/a1; `test_a1_*` green).
- A2 — pass — the Expedition row is live at s3/s6 and the greyed seam elsewhere
  (probe R10; the re-cut `test_s25_contracts.gd` rows green); accept opens the 60 s
  window (`contract_registry.gd:696-706`), the 20-minute clock refuses a second run
  (probe R5: +1199 s refused, +1200 s ready), the run closes at dock or respawn win or
  lose, and the payout requires the player's last hit (probe R6 both outcomes; the
  latch is consumed only by the player's `hit_landed` — `projectile.gd:987-988` runs
  `take_damage` → `_die()` → `died.emit` before `_report_landed`, so the player's own
  fatal delivery credits and a drone's never reaches `game.gd:_on_player_hit`).
- A3 — pass with F4 — the rows fly R-S26-1 exactly (gunship 3 500/1 625 ×2.5 5 W,
  frigate 4 500/2 000 ×2.5 4 W, Maw 12 000/6 000 7 W at half freighter speed; probe
  R8) and pay M10's 6 000/12 000 + the magic/rare floor (probe R6/R10); the Maw rolls
  06 §3.4 at EV 1 581.68 (±5 % of 1 584.75) with the exact 1 025 floor over 20 000 of
  my own seeds (probe R7) — but only at cache scale 1.0; the shipped kill path scales
  (F4).
- A4 — pass — the static `_wreck_drops` ledger outlives the scene and re-materialises
  the pre-death pickup after the respawn rebuild (`game.gd:3567-3583`); the death
  routes `DESTINATION_STATION` (probe R11 both halves).
- A5 — drift (F1, F2, F3) — the premium is M14's 1.5 %-of-list with the exact
  135–1 080 band (probe R1: 135/270/240/360/810/1 080), charged at launch only
  (`game.gd:497-499`, a crossing is not a launch), one loss, Choir sells none
  (`test_a5_choir_sells_none`), the payout flow credits hull+fit and replaces into the
  tier's cheapest — but Champion's ×0.8 never reaches the charge (F1 HIGH), and the
  replacement branch grants an unowned hull on an uninsured loss (F2) and wipes a
  surviving replacement's fit (F3). Mercy once per profile, second total loss leaves
  the account shipless (probe R3).
- A6 — pass — 20 base (+20/tier 500/1 200/2 400), Meridian 40 at 625/1 500/3 000,
  free deposit/withdraw (over-capacity refused whole), per-station persistence,
  outside `cargo_items()`, `u_vault` +20 at every vault including Meridian's
  (probe R9; 40 + 20 tier + 20 u_vault = 80 measured).
- A7 — pass with F5 — both panels mount real in the SERVICES deck beside S25's
  contracts strip (`station.gd:1149-1173`, `SERVICES_STRIP` at `:115-117`), shell-v2
  containers throughout, U9-U13 and U14-U16 surfaces present except two pinned
  captions never rendered (F5); every pane still expands and the strip holds three
  (`test_a7_*` green).
- A8 — pass — every moved value tabled in B1's A8 with reversal + tick (M10 ×2, M14,
  E1 ×3, E2), the payouts cite M10 and the premium cites M14; the §8 gate prediction
  held exactly (below).

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | HIGH | `autoload/player_profile.gd:3364-3384` (insurance_charge/premium) | M14's premium never applies Champion's ×0.8: `StationRegistry.insurance_multiplier` (`station_registry.gd:444`, S24's seam) has zero production callers, the INSURANCE panel renders U9's ×0.8 note (`insurance_panel.gd:34`) while the charge moves the full base. Probe R2: Champion standing (≥71), base 1 080, charged 1 080, expected 864. A5's ×0.8 clause is unanswered. | S26-F1 |
| F2 | MED | `autoload/player_profile.gd:3435-3444` (insurance_payout replacement branch) | An uninsured loss with a surviving fleet grants a base hull the account never owned: probe R4 — fleet {freighter(active), fighter}, uninsured → the freighter is erased then re-appended bare and the account is forced into it. 14 §3: "hull and all installed modules are gone". Also incoherent with the mercy clause: a respawn hull granted on every death would make "if you have no other hull" dead letter. | S26-F1 |
| F3 | MED | `autoload/player_profile.gd:3445-3448` (`_fits.erase` in the same branch) | The replacement erases the fit of a hull that survived the loss: probe R4 case 2 — fleet {gunship(active), fitted freighter}, the gunship dies insured → the surviving freighter's own fit record is wiped. The "bare hull" erase belongs to a newly granted hull only. | S26-F1 |
| F4 | MED | `game/game.gd:2700-2701` (the kill path's cache scale) | The Maw's in-game kill does not roll 06 §3.4 flat: the kill path passes `cache_scale(sector_tier)`, S7 is tier 4 → ×2.0 — probe R7's scaled run reads EV 2 582.75 / floor 1 825 over the pin's 1 584.75/1 025. The suite's 20k row rolls scale 1.0, so the lab passes while the game pays differently. Fix inside the pin: pass scale 1.0 for the maw band; a doc-side fix is an owner tick (bucket 3). | S26-F1 |
| F5 | MED | `ui/station/vaults_panel.gd:33,44` (declared, never rendered) | §15.4's pinned captions are missing: U15's `VAULT CONTENTS DO NOT COUNT AGAINST CARGO ON LAUNCH` and U16's `tier 1 only — this is an outpost` have zero usages, and the outpost grey disables only the RENT action, not the whole row (`button_disabled` per U16). | S26-F1 |
| F6 | LOW | `docs/design/STATION_HUB.md` §15.3 premium rows | The deck law still pins the §3 flats (200–700) verbatim while the shipped panel prices M14 (135–1 080) — the only coherent reading, but the two docs now disagree. → ticketed **T-161** | — |
| F7 | LOW | `autoload/player_profile.gd:3345-3357` (the premium's row keying) | D5's keying prices each §3 row off its cheapest hull (Corvette 240, not its own 405; Gunship 360, not 540). Inside M14's band and the only way to keep the six-row table shape, declared with reversal — but the plain "per class" reading differs; the owner should confirm or re-cut. → ticketed as part of **T-161**'s re-cut note | — |

Deviations graded, no finding: D1 (the three s25 seam rows) is §8's own re-cut,
landed by the orchestrator before this review and green; D2/D3 (bosses spawned by
`game.gd`, synthesised rows) are bucket-1 routes that keep `test_engine2_npc`'s
nine-row pin; D4 matches rule 5's "cannot complete a boss contract"; D5 → F7; D6's
shipless second loss is A5's own wording (probe R3); D7/D8 → T-162; D9's PROPOSED
values carry their reversals in B1's A8.

## Verified fixes

S26-F1 (2026-10-10) — F1-F5 fixed; re-measured on the fixer's own probe run
(`/tmp/s26f1_probe`, `passed=81 failed=0`, was `80/1`):
- F1 — `insurance_charge` multiplies by `insurance_standing_multiplier()`
  (S24's seam off the docked faction); probe R2 reads `charged 864 = 1080 × 0.8`.
- F2 — the replacement branch is gated on `insured`; probe R4 case 1 reads no
  re-grant and the account on the surviving hull.
- F3 — the bare-hull erase moved inside the newly-granted branch; probe R4 case
  2 keeps the surviving freighter's fit.
- F4 — `LootTables.cache_scale_for` pins the maw band flat; probe R7's scaled
  EVIDENCE line now equals the flat run (`scale 1.0`, EV 1581.68 / floor 1025).
- F5 — both pinned captions render and the outpost greys the whole tier row
  (suite `test_a7_the_panels_mount_in_the_services_deck`).
Gate unchanged at `1258/0` twice (fixer's stores), row sets identical.

## Gate

- Baseline `s26_start`: `1237/0` (B1's snapshot; re-derived: 1258 − 20 new s26 rows
  − 1 re-cut s25 row = 1237).
- This review, fresh stores `/tmp/s26r1_c` and `/tmp/s26r1_d`:
  `[SUMMARY] passed=1258 failed=0` twice, row sets byte-identical; the only whole-log
  diff is T-155's known `[s5-racks]` salvo jitter.
- Moved rows against §8's list: `test_s26_endgame.gd` +20 (new, A1-A8) and
  `test_s25_contracts.gd` +1 net (a1 re-pointed, a3 → `s1_primary`, a7 renamed with
  the seam-grey row added) — exactly the two §8 names; no other test file is in the
  diff (`git diff --stat`), so no unlisted row moved and no pinned value moved.
- Negative control: my first pair read `1258/0` then `1257/1` — the 1 was
  `test_wiring_map.gd.test_script_preloads_resolve` on my own probe's stale
  `preload("res://ui/screens/game.tscn")` literal, written between the two runs.
  Harness-only, fixed (the probe now `load()`s a `const` path); recorded as §9's
  sixth harness limit (CONTRACTS v0.53). Not a wave defect.
- `staging/verify_wave.py verify --baseline s26_start --forbidden
  vajb-orbit/project.godot docs/ vajb-orbit/addons/ --tests`: problems none (the
  modified/added set is the wave's own files plus my probe and this review);
  re-run at close-out will diff `docs/CONTRACTS.md`, which is R1's own deliverable.
- My probe: `XDG_DATA_HOME=/tmp/s26r1_probe godot --headless --path "$VAJB_PROJ"
  res://tests/probe_s26_r1.tscn --quit-after 2400` → `passed=80 failed=1` — the 1 is
  F1's R2 row; every other check green, and R7's EVIDENCE line carries F4's numbers.

## Close-out notes for the orchestrator

- Dispatch S26-F1 on F1-F5 (B1's set + `vajb-orbit/tests/` + this review's
  `Verified fixes` re-measure: R2 must read charged = roundi(base × 0.8) at
  Champion; R4's two EVIDENCE rows must flip to their lawful negatives; R7's scaled
  EVIDENCE line must equal the flat run; the two captions must render).
- §28 (the S26 wave section in CONTRACTS) is the close-out's to write — only §9/§10
  were this review's to touch (v0.53).
- LOW backlog: T-161/T-162/T-163 filed; the next free ticket is T-164.
