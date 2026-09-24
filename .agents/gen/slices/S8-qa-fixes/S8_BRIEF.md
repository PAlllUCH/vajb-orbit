# S8_BRIEF — QA playtest fixes (the independent review's 2 HIGH / 6 MED + bundle)

Wave `S8`, slice `S8-qa-fixes`. Read in this order before working:
1. `AGENTS.md` (rules; the escalation ladder; the folder law)
2. `docs/CONTRACTS.md` **§21** (this wave's pin), then §17/§15/§16 (the base
   pins these findings regress against), §9 (the gate)
3. `.agents/gen/slices/S7-affix-application/S7_QA_playtest_review_2026-09-24.md`
   **end to end** — the independent playtest is this wave's input
4. `docs/gameplay/05_exchange.md` **§9**, `04_refinery.md` §5,
   `docs/design/STATION_HUB.md` §12.3 (what may NOT move)
5. this brief end to end

## Owner request, verbatim

The queue row (dispatch_coder.md item 14): "**S8 QA playtest fixes** — the
independent reviewer's findings: launch-ammo seeding, status/fitting cell
mismatch, resolved-figure maxima, rock-ram physics errors, exchange
display-name path, honored confirm quote, copy/naming bundle, warning
ledger." Owner, 2026-09-24: "Reviewer finished. Read
S7_QA_playtest_review_2026-09-24.md and then cleanup .agents/gen/ and prepare
for next sessions."

**The owner's same-day follow-up (six verbatim findings, CONTRACTS §21's
O1–O6 table):** "drag and dropping in FITTING doesnt do anything" /
"cant set weapon groups" / "Hitting enemy ships punches them way too hard" /
"The torque in flying is way too big (you slow down too fast)" / "The A/D
strifing should be a bit stronger or we need to think about how the inertia
works once again" / "make space station bigger with more details (not a single
sprite, more static and moving elements, but the main sprite should be much
bigger as well)". **This wave builds O1/O2/O3 through Q0's dispositions; O4/O5
are coder item 15 (owner-gated flight feel); O6 is designer item 13.** Q0
measures all three of its own before a builder runs.

**Attribution note (measured by the developer session):** the QA ran on
`bdfaace` + K3's uncommitted work, which equals `1a1f57a`; the ship commit
`48779d5` added no game/UI code — so every finding was observed on
HEAD-equivalent code and stands unless Q0 proves otherwise. Q0's dispositions
append to §21 (orchestrator-applied) **before Q1 runs**; a finding Q0 proves
fixed or mis-attributed closes in the disposition table, not in code.

## What is already measured (file:line — QA's own numbers, spot-checked by the developer session)

- **H1:** briefing `AMMUNITION 1 941 ROUNDS ACROSS 6 WEAPONS`
  (`ui/station/launch_panel.gd`) vs flight `Cannon MkI 0/300`, no projectile
  node under `/Game/Sector`, cluster `AMMO 0000`. Suspect area:
  `game.gd:_seed_ammo` (`:1721-1731`) / `_seed_ammo_from_store` (`:1737`),
  `_launch_weapons` (`:502`), S5-J2's ammo-as-cargo packs. **Q0 names the
  break; no mechanism is assumed.**
- **H2:** status pane shows `W1 · B1 · Cannon` + `W2 · B1 · Cannon` (same rack,
  duplicated family) and `W3 · Light Plate` while FITTING lists Cannon / Railgun
  / Mining Laser once each. Suspect area: `game.gd:_hull_slot_cells`
  (`:1508-1532`, filters `type == &"weapons"`), `ship_status_screen.gd:
  set_hull_slots` (`:346`, **L148 keys by layout index alone**), the v7
  `batteries` record (S5 J3).
- **M4:** `repairs_panel.gd:177-179` reads `hull_max/shield_max` from the
  station hull row (base 1000/600) while currents come from the resolved-seeded
  report (1250/800) → `1250/1000`, `800/600`. The status footer resolves hull
  but shows base shield. `ShipFit.resolve` (`ship_fit.gd:573`) is the one
  denominator.
- **M1:** `player_ship.gd:940 → asteroid.gd:262/248/309 → asteroid_field.gd:
  271/365/255 → asteroid.gd:232/347` where `body_set_shape_disabled` /
  `body_set_shape_as_one_way_collision` refuse inside the flush — 16–24 errors
  per ram, fragments do spawn.
- **M2:** `exchange_panel.gd:107 CONFIRM_FORMAT`, name resolved `:277` with
  `String(mineral_id)` fallback; hold rows render names correctly.
- **M3:** preview `YOU GET 8` → commit `+5` (5986 → 5991); market flipped
  IRON 67/1.0x → 57/0.9x inside ~30 s. `exchange.gd:exchange_price (:145)`,
  `sell (:276)`.
- **Copy:** `module_catalog.gd:263` name is `Cannon MkI` (catalogue law);
  Fitting/Armory respell `Mk1`; `hud.gd:168 RANGE_OUT` area carries the `m`
  format (Q0 names the exact line); `refinery_panel.gd:63-84` carries the
  `CONVERSIONS` formats; `REFINERY ALL` (`refinery_panel.tscn:199`) is
  **docs-pinned** (04 §5, STATION_HUB §12.3) and stands.
- **O1/O2 (owner):** FITTING has **no** drag code at all — measured: zero
  `_get_drag_data`/`_can_drop_data`/`_drop_data` in `fitting_panel.gd`; the
  capability lives only in the ARMORY's racks (`armory_panel.gd:3-14,149-157`,
  drop zones `B1..B7` → `weapon_1..7`), committed through
  `PlayerProfile.set_battery_groups` (`:1252`, ceiling `GROUPS_MAX` 7). Q0
  reproduces the ARMORY drag headlessly and reports whether it commits; the
  FITTING-side UX call (port / point at ARMORY / unify) is bucket 3 — the
  owner's, never guessed.
- **O3 (owner):** `player_ship.gd:922 _on_hull_body_entered` →
  `impact.gd:44 collision_damage(mass_a, mass_b, relative_velocity)`. Q0
  measures one representative player→NPC ram (inputs + delivered damage vs the
  NPC's pool); the orchestrator proposes the reduction factor in §21's
  disposition table (reversal 1.0); no number ships unmeasured or unticked.
- **O4/O5/O6:** see §21's table — item 15 (flight feel, owner-gated) and
  designer item 13 (station scene); nothing in this wave touches flight
  numbers, the station scene, or `18_engine_spec.md`.
- **Warnings:** `weapons.gd` five shadowing rows (L163, functions at
  `:1885,1901,2014,2043,2066`), `module_catalog.gd:636/643/651`
  `INTEGER_DIVISION`, `projectile.gd:1485/1489/1759` shadows. QA's
  `tools/d7r1_probe.gd:397` parse error **did not reproduce** (developer
  session: `--check-only` clean) and the four stray files are archived out of
  `res://` — no action.

## The pinned interface (CONTRACTS §21 is the source of truth; nothing here may drift)

```gdscript
# game/exchange.gd — ONE optional parameter; every existing caller unchanged:
static func sell(profile, item_id, count, ..., quoted_total: int = -1) -> int
#   -1 (default) = today's live-price path, byte-identical; >= 0 commits at the
#   preview's gross/fee/paid (05 §9). The panel captures the quote at preview.

# ui/hud/ship_status_screen.gd / ui/station/repairs_panel.gd — the denominator
# rule (acceptance, not a new seam): max = ShipFit.resolve's figure; no pane
# may print current > max.

# game/asteroid.gd + game/asteroid_field.gd — acceptance: the fragment's shape
# state changes are deferred out of the flush (set_deferred); zero refusals.

# Copy law (§21): catalogue `name` may be cased, never respelled; ranges in `u`;
# display names in every sale copy; 1 CONVERSION singular (proposed).
```

Rules that fix every ambiguity:

- **Restore, don't redesign.** H1/H2/M4 are regressions/defects against
  already-pinned behaviour (P2-A's launch fit, L148's warning, 09 §5) — the fix
  returns to the pin; no new number, no new constant without a §21 disposition.
- **One owner per file:** Q1 owns the accounting family (`game.gd`, profile,
  status, repairs, hud, `weapons.gd`); Q2 owns the physics + exchange + copy
  family. Shared files are ordered Q1 → Q2; never two holders.
- **Never touch `ui/hud/cockpit_*`, the theme, `.tscn` files, or any designer
  taste surface** — the composition/close-X/arming items are the designer
  lane's queue rows 9–12. (The `REFINERY ALL` button text is `.tscn` AND
  docs-pinned: it stands.)
- **Every probe/gate on a scratch store** (`XDG_DATA_HOME`; T-93 class); the
  QA's own appendix item 5 reminds us the live `user://` is the owner's.
- **Pinned literal defence:** `NEXT RESTOCK <m:ss>` (§15/STATION_HUB),
  `REFINERY ALL` (04 §5), `CONFIRM_FORMAT`'s shape (05 §5) — the shape stays;
  only the name/number resolution inside it changes (M2/M3).
- Bucket ladder: mechanism = worker; pin/number/docs = orchestrator/developer;
  taste = owner tick.

## Worker table and run order

| ID | Role | Deliverable |
|---|---|---|
| S8-Q0 | reproduce + attribute | run QA's exact scenarios on HEAD (real launch on their fit shape; status-vs-fitting diff; the two maxima; a ram; a confirm+re-roll) **plus O1/O2/O3** (ARMORY-drag commit via the three handlers; group assignment surface; one measured player→NPC ram); name each root cause and the exact file:line; grep copy-pinning test rows; findings → §21 disposition table (orchestrator-applied, incl. O3's proposed factor) |
| S8-Q1 | the accounting family + O3 | H1 seed path, H2 payload, M4 denominators, the ram reduction **if §21's disposition ships it**, the hud range copy + `tests/test_s8_launch_ammo.gd` |
| S8-Q2 | physics + exchange + bundle + O1/O2 | M1 defer, M2/M3 (05 §9), **the ARMORY-drag/groups work exactly as §21's disposition says (fix a break, or nothing if the UX call routes to the owner)**, spelling/unit/singular copy, warning ledgers + `tests/test_s8_qa_fixes.gd` |
| S8-R1 | mandatory review | re-measure every AC (W8 method), tier findings, LOW rows L168+, §9/§10 |
| S8-F1 | fixer (HIGH/MED only) | named fixes + the gate |

**Run order: Q0 → (orchestrator applies Q0's dispositions to §21, one commit)
→ Q1 → Q2 → R1 → (F1 only on HIGH/MED).**

## Tests that move

Expected: **none.** Q0 greps `Mk1`, `860 m`, `CONVERSIONS`, `MINERAL_`,
`CONFIRM_FORMAT`, the confirm/status literals across `tests/`; any row that
must move is dispositioned in Q0's report and ratified in §21 before Q1 (the
S6 `test_engine2_wiring` precedent). `test_p1_refinery.gd:192` (hide-behaviour)
**must not move** — it pins an owner-ticked design.

## Hard rules

- Write sets exactly as `SLICE.md`; `.agents/` reports always allowed; no bash
  file edits (the hook cannot see them).
- No `docs/` writes beyond Q0's disposition pass (orchestrator-applied) and R1's
  §9/§10 notes; no `project.godot`; no `18_engine_spec.md`.
- The designer lane's live wave is **item 13 (D11, station scene)** — its sets
  (`assets/env/**`, `staging/**`, `asset-library/**`, `game/sector.gd`,
  `game/station_scene.gd`, `tests/test_d11_*`) are disjoint from every S8 set;
  `ui/**` stays designer-only either way. Attribute D11's gate rows, never fix
  them (and your close-out's §9/§10 rows sequence after D11's if it is still
  open — next free row read at close-out, rebase never revert). One live
  session per workspace (L82).
- If a pinned number seems wrong: report it, leave it (bucket 2). Taste → owner
  tick (bucket 3).

## Staged / deferred (§21's own list)

Refinery hide-behaviour (owner tick), `REFINE ALL` preference (owner tick +
two docs), M5 close-X / M6 arming countdown / station dead zones / HUD
top-left + minimap / player-hull visibility / mining-beam visibility / auction
thumbnails → **designer queue items 9–12**; **O6 (the station scene: bigger
hero sprite + static/moving detail elements) → designer item 13**;
**O4/O5 (torque/slow-down, strafe/inertia) → coder item 15**, owner-gated on
the flight-numbers session (owner-locked 18 §13 + ruling 23 + the open §13
column ticks); the QA live-profile disclosure →
owner note (restore wanted?).

## Owner ticks owed after this wave

1. **The honored quote** as built (05 §9; reversal: `INDICATIVE` label).
2. **Catalogue spelling law** (`Cannon MkI` ships; reversal: rename the
   catalogue row to `Mk1` instead — one line, then all panels follow).
3. **`1 CONVERSION` singular** as proposed (reversal: keep plural).
4. **Refinery hides sub-convertible stacks** — keep (test-pinned, by design) or
   show exhausted rows (QA read the vanish as data loss).
5. **`REFINE ALL`** — QA's verb preference vs 04 §5 + STATION_HUB §12.3's
   pinned `REFINERY ALL` (reversal: amend both docs + one `.tscn` string).
6. **O3's ram reduction factor** — proposed in §21's table after Q0's
   measurement (reversal: factor 1.0 = shipped).
7. **O1/O2's UX call** — port the drag to FITTING / point the owner at ARMORY /
   unify the two fitting surfaces (Q0's two readings arrive with a
   recommendation; nothing is guessed).
8. **Q0's dispositions** (post-dispatch, orchestrator-applied to §21) and any
   number a fix touches.
9. **The QA disclosure:** its playtest wrote the live `user://` profile —
   restore a pristine save if wanted (none newer than the S3 incident's
   `profile.restored.cfg` is known).

## Close-out (the orchestrator runs these, in order)

1. Gate **twice** on scratch stores:
   `source ~/.profile && XDG_DATA_HOME=$(mktemp -d) godot --headless --path
   vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` → identical
   counts, expect `753 + the two suites`, 0 failed; live `profile.cfg` /
   `economy_log.txt` md5s unchanged.
2. Verify:

   ```bash
   python3 staging/verify_wave.py verify --baseline s8_start \
     --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md \
       docs/gameplay/04_refinery.md \
     --tests \
     --expect-reports .agents/gen/slices/S8-qa-fixes/S8-Q0_report.md \
       .agents/gen/slices/S8-qa-fixes/S8-R1_review.md
   ```

   (`docs/CONTRACTS.md` and `docs/gameplay/05_exchange.md` are deliberately
   NOT forbidden — §21's disposition pass and R1's §9/§10 write them; D7's
   brief made that mistake, L168-candidate noted.)
3. R1 updates §9 (measured figure) + §10 (**v0.20** — v0.19 is taken by §22;
   if a parallel lane landed a row first, take the next free one), LOW rows at
   the **next free ids read from `LOW_BACKLOG.md`** (L167's lesson; ~L168 /
   T-94). CONTRACTS §9/§10 sequence with D11's close-out: rebase, never revert.
4. WAVEBOARD: S8 row closed with numbers, owner ticks recorded.
5. Wave-boundary commit (untracked strays excluded, L10/L105).
