# Vajb Orbit — findings, 2026-09-25 (playthrough + ore balance)

**One file.** This consolidates the live playthrough review and the ore/cargo
balance analysis into a single owner-facing document. It supersedes
`session_2026-09-25_playthrough_review.md`, whose content is absorbed below.

Authorities this file defers to (do not let it drift from them):

| Question | Authority |
|---|---|
| What is live / queued / in flight | `.agents/gen/_state/WAVEBOARD.md` |
| The ruled numbers | `docs/gameplay/01_economy_core.md` §5.6, `docs/gameplay/02_minerals.md` §5.1 |
| The queue and the worker roster | `.agents/gen/dispatch_coder.md` |
| The measurement wave this file ends with | `.agents/gen/slices/S12-ore-budget/S12_BRIEF.md` |

---

## 1. How to reproduce the playthrough

- Launch the editor detached (or the godot-ai session is dead), then
  `session_manage(op="list")` must show one session;
  run the game with `project_run(mode="main")`.
- Frames: `editor_screenshot(source="game")` at **640-1080**; 1152 and above
  fail the MCP transport intermittently. Read *state*, not pixels, from
  `get_scene_tree` / `get_ui_elements` / `get_node_info`.
- **Do not trust a string read off a screenshot.** At 960/1080 I misread
  "Laser MkII" as "Loser MKII", "Cannon MkI" as "Common MkI" and a blank
  seven-segment digit as "1"; three findings were discarded once
  `get_ui_elements` returned the real text. Confirm every quoted string.
- **Focus caveat.** The game window cannot be focused on this host (no
  `xdotool`/`wmctrl`), so the loop ran at ~5 fps (85 frames / 17.1 s) and game
  time advanced ~0.7 s per real second. Timing and feel are out of scope for
  anything measured this way; `input_action` and `get_*` still work,
  `input_sequence` times out.
- The session produced **zero GDScript errors**; the only editor errors were my
  own bad `game_eval` paths. The sector re-rolls per launch (different fields
  and POIs run to run) — expected, not a regression.

## 2. Playthrough findings

| # | Tier | Finding | Evidence |
|---|---|---|---|
| F1 | MED | **ARMORY rack plate does not fit its bay.** `ui_armory_rack_plate.png` is 194x182 but its ink is only rows 49..132 (180x84); every code-drawn mark is laid out against the full 194x182 (`armory_style.gd:65-76`: slots at drawn y 38..82 on a 44 px pitch, ledge 96, SALVO drums 40x72 at y 104..176). So the plate floats mid-bay, the drop cue prints over its top edge, and the drums hang off its bottom. The art's slots are also on a ~34.5 px pitch (dark-run centres x≈45/79/114/148), so fitted-cell blocks (`armory_panel.gd:381-397`) miss the art's recesses. Approved look: `staging/mockup/out/armory_mockup.png`, bay 1. | pixel measurement + live frame |
| F2 | MED | **ARMORY leaves a 520 px dead column.** Live UI tree: host 1432x650, Armory 1392x610, `ConsolePlate` **872x956** inside a 534 px viewport — 37 % of the pane empty to the right, and AMMUNITION below the fold. Every other pane fills its width. | live rects; **overlaps D12-A0's "37 % of its host empty"** — count it once, in the design lane |
| F3 | LOW | **The empty-bay drop cue is clipped mid-word** ("DROP A WEAPON FROM THE INVENTORY HER"), by design: `hint.clip_text = true` (`armory_panel.gd:1558-1566`). | live frame |
| F4 | LOW | **Pre-launch and in-flight pool figures disagree**: LAUNCH reads `HULL LIMIT 1000 / SHIELD LIMIT 600` (class values) while the flown hull reads HULL 1250 / SHLD 800 (fit effects, `ship_fit.gd:1246-1257`). Both defensible; nothing distinguishes class limit from fitted pool. | digits decoded from live `texture` paths (`ui_seg_1`+`ui_seg_2` = 12xx; `ui_seg_blank`+`ui_seg_8` = 8xx); 315 rounds matches the launch panel |
| F5 | LOW | `SLOT LAYOUT · 11 CELLS · 1 ENGINES` — ungrammatical (`fitting_panel.gd`), and the same eleven things are "SLOTS" in SHIPYARD and "CELLS" in FITTING. | live `text` |
| F6 | INFO | **Projectiles stay live across 30 000 u.** With fire held, `/Game` grew 6 → **78** children, 69 of them projectile `Area2D`s (`visible`, `monitoring`, `monitorable`), one measured moving (1074,864) → (23 019,11832). Not a leak — they fizzle at `max_range`; the range is pinned by `CONTRACTS §23.4` (S11-B3), so this is a design note for sustained fights, not a defect. | live scene tree + `get_node_info` |
| F7 | MED | **The HUD's credits block reads as misassembled.** `CreditsIcon` is a **192x192** TextureRect in a 258x192 header, `CreditsTitle` centred at y 85, and `CreditsValue` on its own row at y 194 left-aligned to the 12 px screen margin — the number lands ~200 px from its own label, under the hexagon. The station shell draws the same panel with a 28 px icon. | live UI rects + frame |
| F8 | INFO | **The spawn frame is mostly empty black**: station ~19 % of screen width, player ship ~30 px, no NPC or rock in view (4 NPCs and several fields exist elsewhere in the sector). Cheapest visual win available. | frame |

Verified working (not findings): boot splash → menu → station → undock → sector
`Halcyon Reach`; all eight station panes switch and carry live data; the D11
station scene renders its full element table (`station_scene.gd:66-120`);
thrust moved the ship (0,420) → (-149.4,237.0) and eased rotation; firing spawns
projectiles. Unverified: combat landing (no target in front), mining, boost,
countermeasures, warp, docking return, audio, and any timing claim.

## 3. The ore/cargo balance — the real problem

Your report was right, and **cargo capacity is not the culprit** (25/40/55/60/120
across the hull ladder is coherent). The faucet feeding it is broken, from three
pinned rules that are individually correct:

1. **Cleaving re-rolls a full yield per fragment** — `AsteroidField._cleave`
   gives every fragment `_rolled_yield(tier)`, a fresh 02 §5 roll
   (`asteroid_field.gd:224-229`, `:365-373`; pinned by `CONTRACTS.md:350-353`).
   A T1 Large (6 units) therefore becomes 1 + 3.5 + 12.25 ≈ **16.75 rocks ≈ 100
   ore units**. `FIELD_ROCKS_MAX` 12 caps only the *initial* spawn; fragments are
   uncapped. The ×0.7 diminishing window (`02 §8`) only shaves it to ~70.
2. **A Small's crack pays a flat 1-2 pickups however it died** and whatever it
   still held (`asteroid.gd:107-112`, `asteroid_field.gd:400-420`), and
   `cleaves()` keys off `_bore_ore` — the roll *at setup*, not the ore left
   (`asteroid.gd:237`, `:293-294`). So guns, which by pin "never extract ore"
   (`18_engine_spec.md:51`, `:278`), still get paid.
3. **Chip rate vs mine cycle.** `GUN_CHIP_RATE` 0.10 (`weapons.gd:216`;
   `CONTRACTS.md:374`) on a 45 dps cannon is **13.5 ore-units/s of depletion
   with 3 cannons** against `MINE_CYCLE` 1.2 s = **0.83 units/s** for the laser
   (`mining_laser.gd:34`), so the cascade fires ~16× more often and the laser
   (220 u range) is never the better tool.

**Contradicted by the shipped behaviour:** `18_engine_spec.md:30` ("laser
primary, guns secondary"), `:51` ("never extract ore — the mining laser keeps
the extraction monopoly"), `02_minerals.md:190` ("asteroid combat out of
scope"), `01 §5.1` (one full hold ≈ a session's yield) and `§5.3` (≈110 CR/min
net). Those two docs had already contradicted each other before this review,
which is how the imbalance slipped through.

**Not verified as a live stopwatch.** My session ran at ~5 fps, so the rates
above are arithmetic from the pinned constants and the code paths; your
"almost instantly" is the empirical half. §5 is the wave that measures it.

## 4. What the docs now say

Ruled in on your instruction, both **proposed** numbers with reversals and owner
ticks, and nothing implemented:

- **`01_economy_core.md` §5.6 — the rock income invariant** (your words,
  verbatim): mining realises 100 % of a rock, shooting at most
  `GUN_BURST_SHARE`; more firepower buys *time, never income*; a field is a
  budget, not a faucet; session income is set by mining.
- **`02_minerals.md` §5.1 — Rule A (no method mints ore)** with a real choice
  for the fragments (`FRAGMENT_CORE_SHARE` 0.0 = debris, 0.25 = the crack hands
  the pieces a quarter), and **Rule B (scale)** — the answer to "bigger rocks,
  more yield, bigger clusters, maybe fields": size spread S 1 / M 2 / L 4 on the
  tier base, 2-4 veins of 3-9 rocks per field, a field budget of ≈200 units on
  average, with the guard rail that a hold stays 3-8 rocks and no rock exceeds
  ~⅓ of the hold that carries it.
- §5's "≈7 asteroids" line is marked superseded; §9's "asteroid combat out of
  scope" is amended to in-scope-but-capped.
- **Measured open question**, written down rather than papered over: T4 ore pays
  300-600 CR/unit, so even a *Small* there is 900-1 800 CR. `TIER_BASE_YIELD`
  (6/5/4/3) and 02 §2's ore values predate size mattering and must be re-derived
  together, or the deep fields pay a session's income per rock.

**Cannot be changed by any agent** (so they are ticks, not work): the owner-locked
`18_engine_spec.md` §6/§13/§17, and `CONTRACTS.md` §5's fragment-yield and
gun-work sentences (lines 350, 374) — review waves own that file.

## 5. What is queued: S12, the two probes

`.agents/gen/slices/S12-ore-budget/` (item 19 in `dispatch_coder.md`), read-only,
touching `vajb-orbit/tests/probe_s12_*.gd` only, moving no gate row (807/0):

- `S12-K0` — the field's ore budget: Σ spawn yield, Σ delivered units, the
  out/in factor per path (laser, 3 cannons, max-cell rack) and per tier.
- `S12-K1` — the rate: delivered units/s and units/rock per path, the
  mining:gunning ratio, and one single-rock row.
- `S12-R1` — byte-identical replay, independent re-read of every constant, the
  mirror diff against the real call sites, and the arithmetic recomputed.

Its §10 tick list is the decision list, and the handoff paragraph is in §7 below.

## 6. Open decisions for the owner

1. `GUN_BURST_SHARE` — the share of a rock's own yield a gun-cracked rock may
   realise (proposed 0.10).
2. `FRAGMENT_CORE_SHARE` — 0.0 (fragments are debris) or 0.25 (a quarter rides
   to the pieces).
3. Rule B's four scale rows, or the cheaper gating-the-deep-tiers variant.
4. The ⅓-of-hold rule, and the T4 tier-curve re-derivation.
5. The playthrough fixes: F1/F2/F3 are the ARMORY and belong to the design lane
   (D12-A0's territory); F7 is a `hud.gd`/`hud.tscn` layout pass; F4/F5 are copy.
6. Still open from before this review: S8's O1/O2/O3 gates, L168, L169, the
   `18_engine_spec` §6/§13/§15 amendment, the §13 turn column, slice 2.5's two calls.

## 7. How to proceed

**Keep one orchestrator session — the model you talk to — and let it dispatch
the workers.** That is the project's own law, not a preference: the queue file
is the plan (`dispatch_coder.md`), one item per order, `snapshot` + commit
before the first dispatch, builders → **mandatory review** → a fixer only if the
review leaves HIGH or MED, then close-out. Your input per item is one paragraph
(the template at the end of this section); everything else is in the files.

- **One session per wave phase** (builder session, then reviewer session) —
  a long-lived session re-sends its whole history every turn, so three short
  sessions cost less than one long one.
- **One live session per workspace** (L82), and two waves never hold the same
  file. S12 is disjoint from D11, so it can run beside it.
- **Workers are pinned by the lane, not by your session**: code →
  `deepseek/deepseek-flash` (verified resolvable today; fallback
  `opencode-go/deepseek-v4.1-flash`), design → `opencode-go/mimo-v2.6-*` or
  `opencode-go/glm-5.3*`. Changing the session model changes none of that.

**Model advice.** Your session today runs `deepseek/deepseek-v4-flash`. For the
orchestrator role it has been adequate — the hard work is decomposition, reading
dense specs by range, and holding the queue honest. **MiMo 2.6 Pro
(`opencode-go/mimo-v2.6-pro`, verified present) will work**, with three caveats
worth knowing before you spend on it: it sits on the roster as the *designer's*
large-scope model ($0.435/$0.87 per 1M, effort `low`/`medium`/`high`, default
`medium`), so it is design-first — do not route code work to it, because the
lane pins DeepSeek V4.1 Flash for that; it is **go-only** (zen carries only
`mimo-v2.6-*-free`, which the roster puts out of scope); and it is ~3x the
session's input price, paid on *every* turn of a long-lived session. If you want
a stronger planner, MiMo Pro is a defensible step up; if the planning feels
fine, the money is better spent on reviews. I cannot benchmark its tool-use
quality from here — that is the one thing this environment cannot tell you.

**Next action, concretely:** dispatch item 19 (paste block in
`S12_prompts.md`; the same paragraph is copied below), then tick §6's 1-4 from
the number tables it produces — do not tick them from this document's
arithmetic.

```text
Read .agents/gen/dispatch_coder.md and execute queue item 19 only — S12 ore budget, the two K0 probes. Brief: .agents/gen/slices/S12-ore-budget/S12_BRIEF.md. Prompts: .agents/gen/slices/S12-ore-budget/S12_prompts.md. Docs are already amended (01 §5.6 + 02 §5.1); run the pre-dispatch snapshot + commit line from the prompts file before the first dispatch, then K0 ∥ K1 → R1, and a fixer only if the review leaves HIGH or MED (probe files only). Stop before item 17. Close out per the brief's §11 (gate twice on fresh scratch stores at 807/0, verify_wave.py verify --baseline s12_start with the forbidden list, MASTER_REPORT §6 + the dispatch/WAVEBOARD lines, wave-boundary commit), then report back: the measured gate count, each probe's number tables, the reviewer's findings by tier, and the owner ticks from §10 — do not implement the ticked numbers.
```

## 8. Limits of this document

- No timing, feel, audio or balance claim is measured here; §5 is the wave that
  measures the balance half properly.
- The playthrough covered one session on one host; the sector re-rolls, so a
  sighting may not recur.
- Two of my initial readings were wrong (see §1) — treat any number here that
  lacks a `file:line` or a printed line as unverified.
