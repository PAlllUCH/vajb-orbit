# D17 — orchestrator synthesis of the two in-game playtest reviews (2026-10-03)

Sources: `D17-P1_report.md` (hyper/glm-5.3-flash) and `D17-P2_report.md`
(xiaomi/mimo-v2.6-pro), same prompt, run back-to-back on the live editor.
Both played the real game through godot-ai; neither touched code. The shared
profile carries P1's purchases (a Courier at the auction, Mine Stock) — P2's
figures are post-P1. Nothing here is filed to LOW_BACKLOG yet: these await
your tick, per the playtest gate's "ride the wave that owns the file" rule.

## 1. The headline — flight navigation (both reviewers, independently)

- **P1 HIGH:** after ~20 s of flight there is no way home — no station marker,
  no off-map indicator, target-next finds nothing, and the ship was lost at
  19.3k px from the station (read via debugger). Asteroid fields sat outside
  navigable range, so mining and dock-back were unreachable for the whole
  later route.
- **P2 MED (HIGH if you reproduce by hand):** dock-back never completed from
  inputs — ESC arms a dock hint at the crosshair but no dock followed a 10 s
  hands-off window; thrust + interact (F) did not reach the zone either.
- **Read:** two reviewers, same cluster. Either the dock/return loop has a
  real defect, or the flight scale makes recovery practically impossible —
  both readings say the *player-facing* result is "lost in space with no
  recovery affordance". This is the one I would fix before playtest build 2.
  Note P2's map does have a legend and P1 confirmed the minimap works — the
  gap is a station/off-map *direction* affordance plus a dock hint that
  actually completes.

## 2. Cross-confirmed defects (both reviewers hit them)

- **The shared inspector band goes stale on module switch** — P1 saw ship
  stats persist into REFINERY; P2 saw REFINERY say "NO STACK SELECTED" while
  the inspector still advertised Laser Cells. One root cause: the band never
  clears/re-anchors on module change.
- **REPAIRS copy:** "NOT REPORTED" on intact systems (P2: sounds like missing
  data; P1: the MISSING/FEE rows read unfinished). Suggested: NOMINAL, drop
  the fee row from the body.
- **SHIPYARD self-comparison** shows two identical columns (both LOW; P2 adds
  the shield mismatch: SHIPYARD says 450, LAUNCH briefing says 400 — one
  stats source is wrong).
- **Main-menu hover plate** is the static ember border you vetoed in B2-1 —
  reconfirmed live by both; still waiting on your pick.
- **FITTING** affordance confusion (P1 MED: SELECT A CELL with no visible
  target, inconsistent FIT/SWAP/REMOVE; P2 MED: no confirmation or refusal —
  a wrong-cell pick left the old module advertised). Same fix family: one
  select→fit affordance with explicit confirm/refuse.

## 3. Single-reviewer findings worth trusting (with cites)

- **CONTROLS tab needs a pass** — P1: Q is bound to STRAFE LEFT + PITCH +
  TARGET NEXT and E doubles as STRAFE RIGHT + PITCH; P2: TURN LEFT/RIGHT ship
  unbound on a fresh profile. Conflicts + unbound defaults, one screen.
- **P2's measured layout rows** (get_ui_elements rects, the strongest evidence
  in either report): action-button sizes range 64×16 → 360×88 across the
  station; the ARMORY pane header lacks the module icon and starts at x=472
  vs the others' 504; REPAIRS/LAUNCH leave the inspector band empty; the
  armory ammo row hard-offsets children inside a plain Button (an A5.2
  violation) with Title/Meta overlapping 2 px and Held overflowing 1.5 px;
  the 64×16 BUY target silently becomes a row select on a missed click;
  credits box reflows on every balance change; module content sits on
  fractional pixels at 105 % UI scale.
- **P2's copy rows:** raw token `NO_DAMAGE_REPORT` rendered under the LAUNCH
  button; dev-speak strings in player panels ("IT NEVER SELLS IN V1",
  "SHIP VIEWER ONLY"); "1 ENGINES" / "1 WEAPONS" plural grammar; CARGO row
  reads 40/25 over limit with no warning.
- **P2 release hygiene:** DevTuningMenu ships inside the flight scene tree.
- **P1's rows the layout pass should absorb:** DROP HERE ghosts on 13 empty
  armory cells; EXCHANGE holdings table with no column headers; REPAIRS ~780 px
  dead band; auction post-BUY inspector blank; SHIPYARD hull rows' unlabeled
  stat pairs.
- **P1's tuning row:** initial turn response ~0.02 rad/s — likely the S22.6/
  S22.7 mass-derived angular force doing its job on the starting hull, but it
  needs your eye against the coast figures before playtest 2.

## 4. Disputed / injection artifacts (do not fix blind)

- **Keyboard parity:** P1 claimed TAB RAIL / ENTER CONFIRM cannot exist (only
  one focusable BaseButton found statically). P2 *demonstrated* Tab moving
  focus with the footer tracking it, Enter/Space activating, Esc restoring —
  and resolved the old "Enter did not register" note as a press-only
  injection artifact. Trust P2; treat P1's row as disproven.
- **LAUNCH double-press:** P1 could not complete it through any injected path
  and had to emit the signal directly; P2 completed arm + confirm with
  press+release pairs. P1's window-width suggestion (5 s) is still a
  reasonable ask, but the "cannot confirm" part is an artifact.
- **No visible projectile / dead gauges** (P1, P2) — both could be dry ammo
  after the purchases or frame misses at 640; hand-verify before filing.

## 5. What passed (both reviewers' positive controls)

Economy is exact end-to-end (P2 measured GROSS/FEE/YOU GET and credit/hold
propagation); the station chrome is coherent across all seven modules
(PaneHeader pattern, gutters, insets, footer hints); the quit dialog defaults
to CANCEL; the game log stayed clean the whole route; the flight HUD/minimap
legend and region name are present and coherent.

## 6. Harness notes carried forward

Injected clicks/keys need full press+release pairs; a malformed `game_eval`
expression parks the game in a debugger break and forces a relaunch (both
reviewers hit it); screenshots of a backgrounded window can report
`stale_frame` — focus and retry.

## 7. Suggested disposition (for your tick)

1. Fix before playtest build 2: the navigation cluster (§1), the stale
   inspector band, the CONTROLS conflicts/unbound rows, `NO_DAMAGE_REPORT`,
   the shield 450-vs-400 mismatch, and P2's armory row rebuild (A5.2).
2. Ride with the wave that owns the file: the P2 layout/copy rows (armory,
   exchange, repairs, shipyard, fitting, launch), dev-hygiene rows.
3. Your eye: hover-plate pick (B2-1), turn-response feel, LAUNCH window.
