# A/B comparison — GLM-5.3 (max) vs MiMo V2.6 Pro (high)

Same brief (`staging/compare/task.md`): design the BOUNTY BOARD station-hub
module. GLM ran at its true `max` effort; MiMo does not accept `max` — it ran
at `high`, its ceiling. Both wrote self-contained specs; neither output was
revised after the fact.

| File | Lines | Words |
|---|---|---|
| `out_glm.md` (GLM-5.3) | 414 | 6 601 |
| `out_mimo.md` (MiMo Pro) | 583 | 6 310 |

## 1. Where they independently converged (the house rules held)

- **Rail fit.** Both placed BOUNTY BOARD between REPAIRS and LAUNCH and
  computed the same arithmetic: 8 entries = 490 px stack, 147 px spacer.
- **The AUCTION catch.** Both noticed the live hub already ships 8 modules
  (AUCTION at index 3), recomputed the 9-entry case to the same numbers
  (9×56+8×6 = 552 px, ~85 px spacer) and kept the placement valid either way.
- **Host box.** Both mounted the pane into the measured content box
  x 453..1842, y 216..969 (1390×753) and their region stacks both sum to
  exactly 753 px.
- **Hex drift.** Both flagged the same UI_SPEC `#C8471F` vs `#C8461B` typo and
  declared the brief's 16-colour palette law.
- **Audio gap.** Both independently discovered `ui_confirm_01`/`ui_denied_01`/
  `ui_scroll_01` are unreachable (UiCue carries only CLICK/HOVER) and wrote the
  calls as names so wiring is one pass when the gap closes.
- **Kill law untouched.** Both kept +1 standing / −3 heat per pirate kill as
  the only heat mover on the contract path and anchored payouts to the
  1 200 CR session net (neither invented a number outside the fine math).
- **Ember discipline.** Both defined an explicit semantic ember budget
  (GLM 6 sites in a table, MiMo 6 sites numbered) and kept hover/selection
  non-ember.

## 2. Where they diverge

### Contract model

| | GLM | MiMo |
|---|---|---|
| Kinds | 2: PATROL (6 kills/30 min/400 CR), SECTOR SWEEP (10/45/750) | 3 tiers: T1 3/20/100, T2 6/40/250, T3 10/60/500 |
| Stakes | symmetric: +2 standing on claim, −2 on void; expiry and abandon identical | +2 on claim; fail/abandon cost nothing but the flight |
| Concurrency | 1 active contract | 3 active slots, FIFO kill crediting |
| Offers | 6 (one per kind × 3 factions), signing removes from shelf | 5 per band (2/2/1), snapshots survive restock |
| Access gates | refuse at heat ≥ 50 with issuer (Wanted hunts itself), standing ≤ −51 | per-tier gates: T2 standing ≥ −20, T3 standing ≥ 0 **and** Clean |

GLM's symmetric ±2 makes voiding a real choice and its one-active rule keeps
the loop tight. MiMo's tier gates create progression and its pricing anchor is
sharper: it derives a **danger unit = 25 CR/heat point** (the fine rate) and
prices kills at 33/42/50 CR against it, proving T3+T2 (750 CR, 62 % of a
session) stays under the 1 000 CR worst-case fine. Both reasonings are sound;
they are different philosophies — GLM designs a loop, MiMo designs a ladder.

### Screen composition

| | GLM | MiMo |
|---|---|---|
| Regions | header 40, active strip 72, filter row 48, body 525, footer 20 | header 48, faction ledger 32, body 504, active cards 76, footer 15 |
| Active contracts | one strip at top (progress/time/buttons) | three cards at bottom + `ACTIVE CONTRACTS k/3` |
| Player context | your standing/heat shown per-issuer in the detail column; footer flips to an ember danger line | always-visible 3-faction ledger strip (heat + tier + standing) + YOUR BOUNTY block |
| Confirm idiom | no modal: two-press arm (LAUNCH's idiom), with an owner-fallback note if a modal is preferred | module-owned confirm overlay, measured 520×244 at x 887..1407, y 471..714, CANCEL focused |

MiMo's persistent ledger is the richer information design — heat politics for
all three factions at a glance. GLM's arm-idiom choice is the more consistent
match to the hub's LAUNCH precedent and avoids a second dialog idiom; but it
also duplicates nothing, while MiMo's PAY BOUNTY on the board creates a second
surface for an action LAUNCH already owns (MiMo flags this itself, conflict
§11.3, and keeps the LAUNCH row lawfully intact).

### Depth signals (beyond the rubric)

- MiMo: `ui_scale` 1.4 label-room check (168 px of ink vs 186 px of room),
  tabulated the rail failure point (11 entries breaks; mitigation 48 px
  entries), 21:9/4:3 responsive rules, icon fallback path, ON COMPLETION heat
  projection `min(heat, 3×count)`, fixed `ORDER · HEAVY FIRST` with a no-sort
  rationale, refusal StringName set, panel-owned footer justification.
- GLM: lock priority table (`can_sign` returns the first failure, three
  StringName reasons), 15-state table including a press-raced refusal state,
  in-space HUD seam line spec (data + copy, placement owned by the HUD),
  shelf-persistence state machine, caught the ARMORY rename and the outlaw
  docking two-axis nuance (dock refusal reads standing, gate refusal reads
  heat tier).

## 3. Scorecard

| Dimension | GLM-5.3 | MiMo Pro |
|---|---|---|
| Rubric coverage (9 required sections) | all 9 | all 9 + responsive rules |
| Palette / style law | compliant | compliant |
| Economy derivation | good (flat per-kill ~67/75 CR) | sharper (danger-unit anchor, mixed-evening check) |
| Coder-readiness | high (service API, data contract, states) | high (reads/writes split, refusal reasons, measured overlay) |
| Integration accuracy | AUCTION, ARMORY, hex drift, outlaw nuance | AUCTION, hex drift, PAY BOUNTY surface, cockpit scope |
| Information design | solid, one-contract focus | richer (ledger, tier gates, gate captions) |
| Robustness checks | 15 states incl. race | ui_scale 1.4, failure point, responsive, FIFO |
| Surface discipline | no duplicate surfaces | one flagged second surface |

**Verdict.** Both are implementable without follow-up questions; this would be
a coin flip for a one-off feature. On a full read, **MiMo Pro edges ahead**:
denser coverage per word (583 lines vs 414 for near-identical word counts), the
stronger pricing derivation, the always-visible ledger, and four robustness
checks GLM never attempted (ui_scale 1.4, failure point table, responsive
bands, FIFO across slots) — at `high`, not `max`. GLM's edge is loop elegance
(symmetric standing stakes, one-active tightness), the race-state coverage, and
stricter surface discipline (no duplicated PAY BOUNTY). If the roster's
standing rule is MiMo Pro for design, this test supports it; GLM-5.3 at max is
the pick when a single elegant loop matters more than screen breadth.
