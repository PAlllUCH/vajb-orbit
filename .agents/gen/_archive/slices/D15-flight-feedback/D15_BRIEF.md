# D15 — Flight feel & feedback design (wave brief)

**Wave:** D15 (design lane, item 16 of `dispatch_designer.md`)
**Slice folder:** `.agents/gen/slices/D15-flight-feedback/`
**Owner go (2026-09-27):** "i want to focus on content, bugfixes, playability
and feel" — this slice resolves the feel rulings S22 needs before it can code
anything. **Design only: no code, no game docs.** Runs after S21 (one live
session) and before S22.

## 1. The law to read, in order
1. `slices/D15-flight-feedback/SLICE.md` — scope, file sets.
2. `slices/S22-feel-and-juice/S22_BRIEF.md` §11 (the T-feel rows to resolve) —
   by range.
3. `docs/gameplay/18_engine_spec.md` §3/§4.5 (owner-locked — read, never edit).
4. `.agents/gen/_state/LOW_BACKLOG.md` — L25/L39/L51/L55/L57/L59/L64/L70/L103/
  L182 rows (the evidence).
5. `docs/design/UI_SPEC.md` §3.10 Amendment 5 (A5.1–A5.3) — the composition law.

## 2. The owner's request (verbatim)
> "i want to focus on content, bugfixes, playability and feel" (2026-09-27).
> The ticked pillar for this slice: "Feel — flight model … juice/feedback …
> readability" from the plan the owner approved; the standing rule is the
> designer-lane output format (docs + mockups + owner tick list).

## 3. What is already measured (file:line)
| Row | Measured | Site |
|---|---|---|
| L25 | a seeker orbits locks inside 409 u (no fuse radius); `HIT_RADIUS` 4.0 and `SHOT_MASS` 1.0 unpinned | `game/projectile.gd:68,74` |
| L39 | the ×0.50 coast retune halved every NPC's brake (undisclosed) | `game/ship_fit.gd:151`, `npc_ship.gd:695-709` |
| L103 | NPC skid settles ~2× slower (no midline drag) | `player_ship.gd:_lateral_damp` vs `npc_ship.gd` |
| L182 | lateral release = ramp, not the pinned damp shape (t_10 1.150 s vs 2.383 s) | `player_ship.gd:873-884`; CONTRACTS §23.5 |
| L51 | muzzle flash mouth = shot spawn (reads over the hull middle) | `weapons.gd:285,1445` |
| L55 | low-hull arcs unwired; "intermittent" has no interval anywhere | `projectile.gd` plume seam |
| L57 | bolt 16.4:1 and slug 9.4:1 vs FX_SPEC §1.1's 4:1 / 6:1 | `assets/fx/fx_laser_bolt.png`, `projectile.gd:SHEETS` |
| L59/L64 | trail 12 FPS/48 u, mine 22 u, plume emitter set, chip 40 u — none stated by a spec | `projectile.gd:SHEETS/FEEDBACK/PLUME_*` |
| L70 | a `w_mining` slot's label falls back to a gun name | `ui/hud/hud.gd:1488` |
| L241 | the quadrant rows print the even split (no production feed) | `ship_status_screen.gd:843`; feed site `hud.gd:835-840` |
| L48/L49/L54 | mine cue missing; `sfx_weapon_laser_04` 1.244 s outlier; anti-flam unimplemented | `AUDIO_SPEC` §8/§4.1; `audio_manager.gd:352` |

## 4. Pinned interface + rules
The composition law (UI_SPEC §3.10 A5.2) binds every visual call:
> "**A5.2 Composition law (the owner's rule, as mechanism).** (i) Layout is containers + anchors + `custom_minimum_size` + size flags — never coordinates; (ii) a surface's chrome is a theme stylebox or a sibling node, never a `_draw` pass over content; (iii) a code-drawn mark draws **within its own child rect**, anchored to it; (iv) chrome that carries a visual band also sets the `content_margin_*` that keeps content off it."

Rules:
1. **This slice rules, it does not build.** Deliverables are amendment blocks +
  mockups + the tick sheet; the coder lane implements (S22).
2. **Every proposed number carries its reversal** and its owner-tick id; a
  value nobody can derive from a doc is PROPOSED, never left open.
3. **Feedback stays cosmetic** (18 §3.4: "zero gameplay numbers live here") —
  a feel row that moves a flight number says so and names its §13/CONTRACTS
  consequence (bucket-3 escalation if it supersedes an owner ruling).
4. **No new art**: composition and dispositions use shipped assets only (L57's
  disposition must therefore be "wiring-side aspect fix" or "accepted
  deviation" — a re-cut is out of budget this round).

## 5. Spec extract (verbatim, cited)
`18_engine_spec.md` §3.1/§3.2 (quoted in `S22_BRIEF.md` §5 — the inertia law
your rows tune around) and §3.4:
> "All of it is *feedback*, not physics: zero gameplay numbers live here."

`18_engine_spec.md` §4.5:
> "**Breach malfunctions:** when a quadrant's armor reaches 0: **RCS drift** (random rotational torque every 2 s) from a stern breach, **engine flicker** (15 % chance to ignore a thrust input) from a prow breach; port/starboard breaches clip the turn rate on that side until repaired."

`docs/design/FX_SPEC.md` §1.1 (via L57):
> "light (thin, 4:1)" / "medium (6:1 elongation)"

`docs/design/AUDIO_SPEC.md` §4.1 (via L54):
> the 30 ms minimum between triggers of one cue, the per-pool voice caps (weapons 4 / impacts 6 / mining 1 / UI 2) and "skip the last used variant"

## 6. Acceptance list (numbered)
- **A1 (the tick sheet):** every row of `S22_BRIEF.md` §11 (T-feel-1..7) plus
  S19's T1–T7, CONTRACTS §22's T3, and L39/L103/L182/L57 resolved into a table:
  row → PROPOSED value → reversal → tick id → the §text it implements. The
  owner ticks this table; unticked rows implement at the PROPOSED value.
- **A2 (spec amendments):** dated amendment blocks drafted for
  `docs/design/FX_SPEC.md` (chip-spark master correction, arc interval row,
  L59/L64's rates/sizes pinned, L57 disposition) and `docs/design/AUDIO_SPEC.md`
  (§8's `mine_drop` row — the cue is CC0 via `assetmcp` per AGENTS.md — plus
  §4.1's wiring note and L49's trim disposition), each row carrying its
  reversal + tick id.
- **A3 (feedback composition):** the quadrant feed + hit-marker language
  specified under A5.2 (where the feed lands on the status screen, the marker's
  visual verb, the ram spark's placement) with a mockup or a labelled sketch in
  `staging/mockup/`; named owner rulings implemented (ruling 18, ruling 23, the
  A5 chrome law).
- **A4 (handoff):** the report is the designer-lane five-piece's piece 2/3 for
  S22: it names each owner ruling it implements, the bucket-3 escalations (if
  any) are called out for the owner, and nothing outside `docs/design/` +
  `staging/mockup/` changed.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| D15-A1 | designer | `docs/design/, staging/mockup/, .agents/gen/slices/D15-flight-feedback/` | `D15-A1_report.md` + the two amendment drafts + mockups |
| D15-R1 | design reviewer | `docs/design/, .agents/gen/slices/D15-flight-feedback/D15-R1_review.md` | `D15-R1_review.md` |

## 8. Run order + tests
**A1 → R1.** No gate rows move (design only — a row moving is a defect).

## 9. Hard rules
- `docs/gameplay/*`, `docs/CONTRACTS.md`, `docs/archive/` and all code are
  untouchable; `docs/design/` writes are amendment blocks appended by heading,
  never edits to existing §text.
- No AI art generation (owner 2026-09-27). Cite every row's evidence
  (`file:line` or `doc §`); nothing unsourced ships.

## 10. Staged / deferred
- The bolt/slug re-cut (needs generation budget); the anti-flam *assets* pass;
  §13 speed-table columns (owner-locked).

## 11. Owner tick list
A1's table **is** the tick list (T-feel-1..7, M4–M7 cross-refs, S19 T1–T7, T3,
L57). The report presents it ready-to-tick.

## 12. Close-out (the orchestrator)
1. Owner ticks the sheet; the developer lands the ticked rows in the owning
   docs/CONTRACTS at S22's open (docs-first).
2. `python3 staging/verify_wave.py verify --baseline d15_start` (design-only
   diff surface), WAVEBOARD + `dispatch_designer.md` one-liners,
   `MASTER_REPORT.md` §6 recap, wave-boundary commit.
