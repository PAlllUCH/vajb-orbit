# BOUNTY BOARD — station-hub module · screen design spec

**Deliverable:** a coder-ready design spec for one new station-hub module: the BOUNTY BOARD, where the player signs pirate-hunting contracts. No code, no scenes — everything a coder needs is on this page.
**Surface:** the station hub's module rail (one new entry) + one new pane inside the framed module host. Base render target 1920x1080, stretch `canvas_items`, aspect `expand`. All UI is 2D `Control`.

---

## 1. System facts the screen renders (law — never changed by this spec)

| Fact | Number |
|---|---|
| Heat per faction | 0–100, persisted; decay −1 per minute of **play** (flight time only) |
| Heat tiers | CLEAN 0–19 · SUSPECT 20–49 · WANTED 50–79 · OUTLAW 80–100 |
| Kill a trader / patrol / station turret | +15 / +25 / +25 heat (victim faction) · surviving witness +5 extra |
| Kill a pirate in faction X's space | **+1 standing, −3 heat with X** |
| Pay the bounty | fine = heat × 25 CR (40 heat = 1 000 CR); zeroes heat instantly; a `PAY BOUNTY (n CR)` row already exists in the LAUNCH module for the docked station's faction |
| Factions | CONCORD, MERIDIAN, CHOIR (three named); pirates are factionless enemies of everyone |
| Docking law | an Outlaw never reaches the station, so **no Outlaw can ever see this screen** (no Outlaw-specific state is needed beyond one tier word) |
| Economy anchor | a typical session nets ≈ **1 200 CR** — every price below is derived from this |
| Standing bands | standing is a second dial on the same relationship; the exile band is standing ≤ −51 |

Standing and heat are independent dials: a pilot can be Clean with Meridian and Wanted with Concord at once. The board renders both dials and lets politics happen.

---

## 2. The contract model (every chosen number, each with one line of reasoning)

### 2.1 Two contract kinds, fixed terms

| Term | PATROL | SECTOR SWEEP |
|---|---|---|
| Kill target | **6 pirates** anywhere in the issuer's space | **10 pirates** in one named sector of the issuer's space |
| Window | **30 flight minutes** | **45 flight minutes** |
| Reward | **400 CR** | **750 CR** |
| Standing on claim | +2 with issuer | +2 with issuer |
| Standing on void (fail or abandon) | −2 with issuer | −2 with issuer |

Reasoning, one line each:

- **6 kills** — at S2–S4 pirate densities (1–4 per sector) that is 2–4 sector visits, ~15–20 min of hunting, a fraction of a session.
- **30 flight min** — at −1 heat/min the window's own decay walks a mid-Suspect (30 heat) down to CLEAN during one dedicated run; the window comfortably contains the kills plus travel.
- **400 CR** — one third of the 1 200 CR session net for a third of a session's focus; ≈67 CR per kill on top of the loot, +1 standing and −3 heat each kill already pays.
- **10 kills** — one sector's respawn cycle worked repeatedly; double a patrol's count in one place.
- **45 flight min** — 1.5× the patrol window, and another 45 heat of natural decay for the same alignment.
- **750 CR** — 75 CR per kill: a 25 % per-kill concentration premium over patrol, paying for camping one sector whose tier band may roll high (S5+ densities 3–5).
- **+2 standing on claim** — two kills' worth of the per-kill +1; the kills stay the ladder, the claim is the handshake.
- **−2 standing on void** — the exact mirror of the claim bonus: a broken promise costs precisely what a kept one paid; expiry and abandonment are the same penalty, so waiting out a timer is never a dodge.
- **No sign fee or deposit** — the honest loop must be enterable at 0 CR; the board pays, it never charges. The only price on the screen is a fine the player might owe (see §6).

### 2.2 The shelf and its rotation

- The board posts **6 offers: one PATROL + one SECTOR SWEEP per faction** (3 × 2). Reasoning: one page — 6 rows at 76 px + 5 × 6 gaps = 486 px, inside the 497 px offers box (§4.3), so the default view never scrolls; every faction is always represented.
- The shelf **persists with the save** and redraws on the station clock's **1200 s band** (the AUCTION's restock cadence — one clock, one cadence). The sweep sector per faction is drawn from the issuer's inhabited sectors at redraw.
- The `NEXT POSTING <m:ss>` tag is **a reading computed at pane entry** (`1200 − (WorldClock.now() % 1200)`); no Timer node, no ticking — the shelf changes on the next entry, the same rule the AUCTION's rotation line obeys.
- **Signing removes the offer from the shelf** (it is now yours; a failed posting is gone until the next redraw). With one row gone the shelf holds 5 — this is also what makes the filter-zero state (§6) reachable.

### 2.3 Lifecycle state machine

```
SHELF OFFER ──sign──▶ ACTIVE ──last target kill──▶ FULFILLED ──claim──▶ cleared (paid)
                        │
                        └──window expires──▶ VOID (−2 standing) ──▶ cleared
                        └──abandon (2-press)──▶ VOID (−2 standing) ──▶ cleared
```

- **One active contract at a time** (`ACTIVE_LIMIT = 1`). Reasoning: one timer, one state blob, one HUD tracker line — split timers punish exactly the undock→hunt→return loop the board exists to serve.
- **Window counts flight minutes only**, accrued on the game scene's play-minute accumulator (heat decay's own clock — the same seam). Docked time burns nothing, so a mid-contract refit is free.
- **Progress counts pirate kills in scope, from signing**: PATROL counts any pirate killed while the per-kill faction effects fire in the issuer's space; SECTOR SWEEP counts only in the posted sector (which is in the issuer's space, so every contract kill is also a +1 standing / −3 heat kill — contract work IS the redemption loop; the detail note says so).
- **FULFILLED is terminal until claimed** — no expiry after the target is met; the player earned it and the walk back to a station is not a timer. Claim is possible at **any** station's board (the postings are galactic; the issuer pays).
- **CLAIM** pays `reward_cr`, adds +2 issuer standing, clears the active contract, and writes one economy-log line per the project's transaction law.
- **VOID** (expiry or abandon) applies −2 issuer standing, clears the active contract, writes its log line.

### 2.4 Sign locks (the board refuses its own fugitives)

`can_sign` returns the first failure:

| Priority | Rule | Reason |
|---|---|---|
| 1 | heat with issuer **≥ 50** (WANTED+) → refuse | a faction posts bounties; it does not staff its own hunt. SUSPECT (20–49) stays signable because pirate-hunting is the sanctioned heat cure (−3/kill) — locking Suspect would block the redemption path the system designs |
| 2 | standing with issuer **≤ −51** → refuse | the exile band — the same line that refuses docking; the faction posts for pilots it serves |
| 3 | an active contract exists → refuse | one at a time (§2.3) |

The lock is presentation plus transaction: the pane greys and explains, and `sign()` re-checks and can still refuse (the profile decides, never the pane).

---

## 3. Rail integration — the eighth entry and the fit

**Integration: a normal eighth rail entry, inserted after REPAIRS, before LAUNCH.** No alternative construct (no sub-menu, no merge into another module) is proposed: the rail-plus-one-host model has no other lawful shape, and the fit costs nothing:

- The rail content box measures **769 px tall** (y 208..977 inside the 360 px rail).
- Fixed rail furniture: two caption lines ≈ 18 px each, five 10 px separations, and the 56 px LOG OUT plate ≈ 132 px.
- Seven entries measured 7×56 + 6×6 = **428 px** → spacer 209 px.
- Eight entries measure 8×56 + 7×6 = **490 px** → fixed furniture + module stack = 622 px → **spacer 147 px**.
- The rail's own law — "the spacer absorbs the remainder" — holds; **no measurement changes, no rework, nothing moves but LAUNCH one slot down.**

**Position 7 (REPAIRS → BOUNTY BOARD → LAUNCH) reasoning:** LAUNCH stays the last module, adjacent to the spacer and session group, because the exit must keep reading at the bottom; and contract-taking completes the pre-flight chain the rail already tells (outfit → fit → repair → **sign** → launch).

**Wiring (the pane is loaded, never hand-placed):**

| Array (in `station.gd`) | Insert at index 6 (0-based, before LAUNCH) |
|---|---|
| `Module` enum | `BOUNTY` |
| `MODULE_LABELS` | `"BOUNTY BOARD"` |
| `MODULE_FILES` | `"bounty"` (→ `vajb-orbit/ui/station/bounty_panel.tscn`) |
| `MODULE_ICONS` | `"res://assets/icons/contract/icon_contract_hunt.svg"` |
| `MODULE_TINTED` | `true` (tint `Tokens/text_primary`, the SHIPYARD rail icon's precedent) |
| `MODULE_BEDS` | the default room loop (the board is an office console; no new ambience) |

Rail entry anatomy is untouched: 56 px `StationButton` plate, 40 px icon, `StationPanelTitle` label, `ui_accept` switches modules, shoulder buttons cycle, PageUp/PageDown cycle, Tab order follows the arrays. The label `BOUNTY BOARD` at 20 px fits the 337 px entry cell alongside the 40 px icon with >150 px to spare.

---

## 4. Screen composition — measured boxes at 1920x1080

The pane draws inside the module host's measured content box **x 453..1842, y 216..969 → 1390 × 753 px** (host frame + 20 px inner margin + the panel chrome's 33 px content inset; do not re-derive, use the box). Every number below lives inside it.

### 4.1 Region plan (pane root `Bounty`, VBoxContainer, separation 12, fill)

| # | Region | Construct | Height | Content |
|---|---|---|---|---|
| 1 | `PaneHeader` | HBox, sep 12 | 40 | 40 px pane icon · title `BOUNTY BOARD` (20 px Bone) over caption subtitle (13 px Ash) · right-pinned tag `NEXT POSTING <m:ss>` (13 px Ash) |
| 2 | `ActiveStrip` | PanelContainer, flat stylebox (§4.6) | 72 | the player's one live contract, or the no-contract line |
| 3 | `FilterRow` | HBox, sep 6 | 48 | `FACTION` caption + 4 chips, `TYPE` caption + 3 chips (§4.7) |
| 4 | `BoardBody` | HBox, sep 16, vertical expand | **525** | left: offers list 620 px · right: detail column (754 px measured) |
| 5 | `PaneFooter` | Label, 13 px Ash | 20 | economy teaching line, or the ember danger line (§6) |

Height check: 40 + 72 + 48 + 20 + 4×12 = 228 fixed → body = 753 − 228 = **525**. Offers list needs caption 20 + sep 8 + 6×76 + 5×6 = 486 ≤ 525 ✓ (11 px slack; the detail column's spacer absorbs the rest).

### 4.2 Node tree (container plan — names as the coder should build them)

```
Bounty (VBoxContainer, sep 12, fill)
├─ PaneHeader (HBox, sep 12)
│  ├─ PaneIcon (TextureRect 40x40, icon_contract_hunt, tint text_primary)
│  ├─ TitleBox (VBox, sep 2, h-expand)
│  │  ├─ PaneTitle (StationPanelTitle) "BOUNTY BOARD"
│  │  └─ PaneSubtitle (StationCaption) "GALACTIC POSTINGS · CLAIM AT ANY STATION"
│  └─ PanelTag (StationCaption, v-center, right-pinned) "NEXT POSTING 14:07"
├─ ActiveStrip (PanelContainer, ActivePanelFlat) → ActiveMargin (12/8) → ActiveRow (HBox, sep 12)
│  ├─ ActiveTitleBox (VBox, sep 2, h-expand): ActiveTitle (StationValue) + ActiveMeta (StationCaption)
│  ├─ ProgressCol (VBox, min 130): ProgressValue (StationValue) + ProgressCaption (StationCaption)
│  ├─ TimeCol (VBox, min 110): TimeValue (StationValue) + TimeCaption (StationCaption)
│  ├─ ClaimButton (Button, StationButton, min 110x56)
│  └─ AbandonButton (Button, StationButton, min 130x56)
├─ FilterRow (HBox, sep 6)
│  ├─ FactionCaption (StationCaption, v-center) "FACTION"
│  ├─ FactionChips (HBox, sep 6): 4 Buttons, toggle_mode, base Button theme, min 96x48
│  ├─ TypeCaption (StationCaption, v-center) "TYPE"
│  └─ TypeChips (HBox, sep 6): 3 Buttons, same construct
├─ BoardBody (HBox, sep 16, v-expand)
│  ├─ OffersBox (VBox, sep 8, min width 620)
│  │  ├─ OffersCaption (SectionHeader) "OPEN CONTRACTS"
│  │  └─ OfferScroll (ScrollContainer, v-expand, horizontal_scroll_mode 0)
│  │     └─ OfferRows (VBox, sep 6, h-expand)   6 x offer row (§4.4)
│  └─ DetailBox (VBox, sep 10, h-expand)        754 px measured
│     ├─ DetailCaption (SectionHeader) "CONTRACT DETAIL"
│     ├─ DetailRows (VBox, sep 6)               9 caption/value lines (§4.5)
│     ├─ DetailNote (StationCaption, autowrap)
│     ├─ DetailSpacer (Control, v-expand)
│     └─ DetailAction (VBox, sep 12)
│        ├─ SignButton (Button, StationButton, min 0x88, fill width)
│        └─ ConfirmStrip (StationValue, autowrap)
└─ PaneFooter (StationCaption)
```

### 4.3 One stylebox is new

`ActivePanelFlat` (the strip's, and only the strip's, background): `StyleBoxFlat` — fill **Panel Black #15181D**, border **1 px Panel Steel #2A2E35** all sides, corner radius 2, content margins 12 horizontal / 8 vertical, subtle inner shadow if the engine's shadow is available (zero cost), never glossy. This is the brief's own panel law rendered flat, because the theme's `PanelRaised` texture insets 33 px per side and cannot fit a 72 px strip. Everything else on the pane uses existing theme items only.

### 4.4 Offer row anatomy (list width 620)

Row = `Button`, base `Button` theme, `toggle_mode`, `FOCUS_ALL`, min (0, 76), pointing-hand cursor → `RowInner` MarginContainer 12/8 → HBox sep 12. **No icon column** (no faction art exists; the SHIPYARD list is the no-icon precedent) and **no column header strip** (a selection list, like SHIPYARD; the row self-carries its meaning):

| Column | Width | Content |
|---|---|---|
| title block | expands (≈332 measured) | line 1: contract kind, `StationValue` 18, Bone — `PATROL` / `SECTOR SWEEP`; line 2: `StationCaption` 13, Ash — `CONCORD SPACE · 6 PIRATES · 30 MIN` / `MERIDIAN · <SECTOR NAME> · 10 PIRATES · 45 MIN` |
| REWARD | 130 | `StationValue` 18, Bone — `400 CR` |
| STATUS | 110 | `StationValue` 18 — `OPEN` in Ash Text, or `LOCKED` in Burnt Ember (§6) |

Selection = the button's pressed stylebox (`void_panel_raised` band — a second, non-colour channel, so "selected" survives colour-blind reading) plus the shared 1 px `accent_danger_bright` focus ring on focus. Selecting a row fills the detail column; it commits nothing.

### 4.5 Detail column (754 px measured, right of the list)

- `DetailCaption` `CONTRACT DETAIL` (SectionHeader 16, Ash).
- **9 caption/value lines**, the LAUNCH-brief row style — caption left (13 px Ash, expands), value right-aligned in a **220 px** column (18 px Bone): `ISSUER` → `CONCORD` · `AREA` → `CONCORD SPACE` / `<SECTOR NAME>` · `TARGET` → `6 PIRATES` · `WINDOW` → `30 FLIGHT MIN` · `REWARD` → `400 CR ON CLAIM` · `CLAIM BONUS` → `+2 STANDING CONCORD` · `VOID PENALTY` → `−2 STANDING CONCORD` · `YOUR STANDING` → `+12` (ember when ≤ −51: `−54 · EXILE`) · `YOUR HEAT` → `8 · CLEAN` (ember when ≥ 50: `58 · WANTED`).
- `DetailNote` (13 px, autowrap): the state line, one of — open: `KILLS COUNT FROM SIGNING · EACH KILL ALSO PAYS +1 STANDING · −3 HEAT` (Ash); locked: the ember lock line (§6); one-at-a-time: `ONE CONTRACT AT A TIME · SETTLE YOUR ACTIVE CONTRACT FIRST` (Ash).
- `DetailAction`: `SignButton` `SIGN CONTRACT` — `StationButton`, min (0, 88), fills the column — over `ConfirmStrip` (`StationValue`, autowrap).

### 4.6 The ACTIVE strip (region 2) — states

| State | Title (18 px) | Meta (13 px) | Progress | Time | Buttons |
|---|---|---|---|---|---|
| none | `NO ACTIVE CONTRACT` (Ash) | `SIGN A CONTRACT BELOW · THE BOARD PAYS ON RETURN` (Ash) | — | — | hidden |
| ACTIVE | `ACTIVE · PATROL · CONCORD SPACE` (Bone) | `6 PIRATES · 30 FLIGHT MIN · 400 CR ON CLAIM` | `4/6` (Bone) + caption `PIRATES DOWN` | `12:40` (Bone) + caption `TIME LEFT` | CLAIM disabled · ABANDON enabled |
| FULFILLED | `FULFILLED · PATROL · CONCORD SPACE` (Bone) | unchanged | `6/6` (Bone) | `DONE` | CLAIM enabled · ABANDON hidden |
| ABANDON armed | unchanged | `ARMED · PRESS ABANDON AGAIN WITHIN 3 s TO VOID` (**ember**) | unchanged | unchanged | both dimmed by the arm pulse |

Both strip buttons are `StationButton`, min height 56, inside the 72 px strip (8+56+8). The countdown is a **reading at entry** (docked time does not accrue — the number is frozen while docked); `DONE`/`ACTIVE` status changes are only ever observed on entry, because kills happen in space.

### 4.7 Filter row

Two radio groups of toggle chips (base `Button` theme, 14 px, toggle_mode, min 96×48, sep 6; pressed = the `void_panel_raised` band, the same non-colour selected channel as rows):
- `FACTION`: `ALL` (default) · `CONCORD` · `MERIDIAN` · `CHOIR`
- `TYPE`: `ALL` (default) · `PATROL` · `SWEEP`

Groups combine by AND. Pressing a chip un-presses its siblings (radio behaviour); `ALL` clears the group. **No sort control** — with six rows on one page, shelf order (rotation order) is the only honest order; a sort would be chrome with nothing to sort. Filters exist to aim, not to arrange.

---

## 5. Data contract (what the coder wires)

### 5.1 One shelf offer (Dictionary)

| Field | Type | Meaning |
|---|---|---|
| `id` | StringName | unique posting id, stable for the shelf's life |
| `kind` | StringName | `&"patrol"` \| `&"sector_sweep"` |
| `issuer` | StringName | `&"concord"` \| `&"meridian"` \| `&"choir"` (the faction registry's ids) |
| `scope` | StringName | `&"faction"` (patrol) \| `&"sector"` (sweep) |
| `sector_id` | StringName | the posted sector's registry id, `&""` when scope is faction |
| `sector_name` | String | display name of the posted sector, resolved at shelf redraw |
| `target_kills` | int | 6 (patrol) \| 10 (sweep) |
| `window_min` | int | 30 (patrol) \| 45 (sweep) |
| `reward_cr` | int | 400 (patrol) \| 750 (sweep) |
| `posted_band` | int | station-clock band index the shelf was drawn for |

### 5.2 Profile additions (persisted, saved with the profile)

| Key | Type | Meaning |
|---|---|---|
| `contracts_shelf` | Array[Dictionary] | the live offers (≤6; signing removes one) |
| `contracts_band` | int | band the shelf was drawn for |
| `active_contract` | Dictionary | `{}` when none; else: `offer` (the signed offer, verbatim), `status` (`&"active"` \| `&"fulfilled"`), `kills` (int), `signed_at_play_min` (float, the game scene's play-minute accumulator at signing) |

Expiry check is `now_play_min − signed_at_play_min ≥ offer.window_min` while `status == &"active"`; the kill event is `on_pirate_kill(sector_id)` evaluated against `scope`/`sector_id`/`issuer`.

### 5.3 Service API (`game/bounty_board.gd`, the panel computes nothing itself)

| Call | Returns | Meaning |
|---|---|---|
| `refresh_if_stale(profile, band)` | void | redraws the 6-offer shelf when the band moved; persists |
| `shelf(profile)` | Array[Dictionary] | the live offers |
| `can_sign(profile, offer)` | Dictionary `{ok: bool, reason: StringName}` | reasons in §2.4 priority: `&"issuer_hunts_you"` \| `&"issuer_exiled_you"` \| `&"one_at_a_time"` |
| `sign(profile, offer)` | bool | re-checks locks, removes the offer from the shelf, writes `active_contract`, one log line |
| `on_pirate_kill(profile, sector_id)` | void | progress; flips to `&"fulfilled"` at target |
| `on_play_minute(profile, play_min)` | void | expiry → void, −2 standing, one log line |
| `claim(profile)` | bool | pays `reward_cr`, +2 issuer standing, clears, one log line |
| `abandon(profile)` | void | −2 issuer standing, clears, one log line |
| `fine(profile, faction_id)` | int | heat × 25, display only (the same math LAUNCH's PAY BOUNTY uses) |
| `heat_word(heat)` | StringName | `CLEAN` \| `SUSPECT` \| `WANTED` \| `OUTLAW` |

Signals: the pane rebuilds on `profile_changed(&"contracts")` (new key; join the existing credits/ammo/ships/fits/modules/cargo map) and refreshes prices/affordability on `&"credits"` and `&"standing"`. The pane also needs the docked station's faction (for the lock line's PAY AT wording) — passed by the shell at mount, the same source LAUNCH's PAY BOUNTY row reads.

### 5.4 In-space seam (the one thing this module owns outside the pane)

One HUD tracker line, owned by the cockpit/HUD surface, fed by `active_contract`: `CONTRACT · <kind> · 4/6 PIRATES · 12:40` (13–18 px per the HUD's own spec; ember only if the contract window runs under 5 flight minutes — the HUD's danger rule, not this pane's). This spec pins only the data and copy; the HUD surface owns placement.

---

## 6. ALL UI states

| # | State | Trigger | Presentation |
|---|---|---|---|
| 1 | Shelf empty | all 6 offers taken (or a future multi-slot model) | offers box shows one non-interactive caption row `BOARD REFRESHES AT THE NEXT POSTING` (Ash); detail shows `NO CONTRACT SELECTED` with value cells reading `—`; SIGN disabled |
| 2 | No active contract | `active_contract == {}` | strip state "none" (§4.6): two Ash lines, no buttons |
| 3 | Active contract | status `active` | strip shows progress `4/6`, frozen countdown, CLAIM disabled, ABANDON enabled |
| 4 | Fulfilled | target reached in space | strip `FULFILLED`, `6/6`, `DONE`, CLAIM enabled + idle pulse (§8), ABANDON hidden |
| 5 | Confirm (sign) | first press on enabled SIGN | **the two-press arm is the confirm — there is no modal overlay in this module** (the hub's own idiom: LAUNCH arms, refusals never open dialogs). Button font flips to Ember Glow + 2× pulse; strip reads `ARMED · PRESS SIGN AGAIN WITHIN 3 s TO SIGN`; second press within 3.0 s signs, else one-shot Timer disarms and restores. *Owner fallback if a modal is preferred:* the project's confirm dialog drops in at this press, CONFIRM default-focused — nothing else in the spec changes |
| 6 | Confirm (abandon) | first press on ABANDON | same arm idiom; meta swaps to the ember ARMED copy; second press voids |
| 7 | Locked — hunted | lock rule 1 (heat ≥ 50) | row STATUS `LOCKED` in Burnt Ember; SIGN disabled (focus skips it); detail note `LOCKED · CONCORD HUNTS YOU · 58 HEAT · PAY 1 450 CR AT LAUNCH` in ember when the issuer is the docked faction, else `LOCKED · CONCORD HUNTS YOU · PAY AT A CONCORD STATION` (LAUNCH's row pays the docked faction only — the wording must not promise the wrong counter) |
| 8 | Locked — exiled | lock rule 2 (standing ≤ −51) | row `LOCKED`; note `LOCKED · CONCORD EXILED YOU · STANDING TOO LOW` in ember; `YOUR STANDING` value `−54 · EXILE` in ember |
| 9 | Locked — one at a time | lock rule 3 | SIGN disabled; note `ONE CONTRACT AT A TIME · SETTLE YOUR ACTIVE CONTRACT FIRST` in Ash (a rule, not a danger — no ember) |
| 10 | Cannot-afford | n/a by design | **nothing on this board charges credits**; the only cost shown is the fine inside the lock line, and paying it is LAUNCH's transaction with its own existing refusal path. The board greys nothing on credits |
| 11 | Filter to zero | AND of filters matches nothing (e.g. the taken row under its own filter) | one caption row `NO CONTRACTS MATCH · PRESS ALL TO RESET`; detail falls to `NO CONTRACT SELECTED` |
| 12 | Refusal (press raced state) | `sign()` returns false after a lock changed | shell status strip line in ember (`REFUSED · …` set, §11), 4-step pulse on SIGN and the row's STATUS cell; **never a dialog**; focus and selection do not move |
| 13 | Expired since last visit | expiry processed in space | contract already void; on pane entry the shell status strip reads `CONTRACT FAILED · WINDOW EXPIRED · CONCORD STANDING −2` in ember; strip is back to state 2 |
| 14 | Success | sign / claim / void | strip lines: `SIGNED · PATROL · 6 PIRATES · 30 FLIGHT MIN` · `CONTRACT PAID · 400 CR · CONCORD STANDING +2` · `CONTRACT VOIDED · CONCORD STANDING −2` (Ash for the last — chosen, not danger); CLAIM additionally runs the credits count-up |
| 15 | Danger — player's own heat | any faction at heat ≥ 50 on entry | three semantic ember sites only: the locked rows/notes (7–8), the detail `YOUR HEAT` value at ≥ 50, and the **pane footer flips** from the Ash teaching line `PIRATE KILLS PAY +1 STANDING · −3 HEAT · BOUNTIES PAY IN CREDITS` to the ember `<FACTION> HUNTS YOU · PAY <n> CR AT LAUNCH` (highest heat wins; tie → docked faction) — the board's one ambient danger line. Outlaw-tier is unreachable by law (never docks) but the tier word renders if it ever appears |

**Ember law for this pane (semantic, never decorative):** Burnt Ember #C8461B = locked status, lock notes, armed strips and their font-colour override (Ember Glow #E8703A), refusal pulse, expiry notice, danger footer, heat ≥ 50 / standing ≤ −51 values. Everything else — hover, selection, pressed chips, rewards, progress — stays gunmetal/Ash/Bone. In-screen hover brightens borders to Ash, never ember; no bloom anywhere in the pane (bloom is menu-level only). CLAIM's idle pulse is an affordance cue in the status-beacon family, not an ember (modulate only, no colour change).

---

## 7. Input

**Focus order (Tab / Shift+Tab, tree order; ui_up/ui_down walk the same tree):** rail entries 1→8 then LOG OUT (shell-owned) → pane: CLAIM and ABANDON (only while visible **and** enabled; disabled buttons are skipped) → the 7 filter chips (faction group left-to-right, then type group) → offer rows top-to-bottom → SIGN (only while enabled) → wrap to the rail. Pane entry auto-selects the first visible offer row (SHIPYARD's precedent); after any list rebuild the selection falls to the first visible row, or the empty state if none.

| Input | Context | Effect |
|---|---|---|
| `ui_accept` | offer row | select → fill detail (commits nothing; the detail is the terms, signing is a separate control) |
| `ui_accept` | chip | toggle the filter (radio within its group) |
| `ui_accept` | SIGN | first press arms; second press within 3.0 s signs |
| `ui_accept` | CLAIM | pay out (single press — a gain, nothing to arm) |
| `ui_accept` | ABANDON | first press arms; second press within 3.0 s voids |
| `ui_accept` | rail entry | switch module (shell) |
| PageUp / PageDown, shoulder buttons | anywhere | cycle modules, wrapping (shell) |
| `ui_cancel` | armed control | disarm: restore font colour, strip/meta text, kill the Timer; focus stays |
| `ui_cancel` | otherwise | move focus to the BOUNTY BOARD rail entry (the hub's ladder then owns the second press — leave-confirm — outside this module) |
| Mouse | rows | hover = theme hover plate + pointing hand (no icon-fade beat — these rows carry no icon); click = select; wheel scrolls the offers list |
| Mouse | buttons/chips | standard press; armed controls disarm on mouse leave? — **no**: the 3.0 s Timer owns the disarm, pointer travel does not cancel an arm (matches LAUNCH) |

Gamepad: d-pad/stick = the focus walk (focused controls scroll into view); A = `ui_accept` per row above; B = `ui_cancel` ladder; shoulders = module cycling. Nothing in this pane needs analog input.

---

## 8. Motion (Tween only, never `_process`; every tween is `create_tween()` from the pane node, held in a local array, killed in `_exit_tree` while valid — house law, restated because it is binding)

| Beat | Target | Property | From → To | Time | Curve |
|---|---|---|---|---|---|
| Module enter / leave | the pane | shell-owned beats | outgoing 1→0 then `hide()`; incoming 0→1, then focus the pane's first focusable control in tree order | 0.12 / 0.18 | QUAD EASE_IN / CUBIC EASE_OUT |
| Row appear (pane entry, shelf redraw, filter change) | each row | `modulate:a` | 0 → 1, staggered 0.04 s per row from the first (6 rows → 0.32 s total) | 0.12 | CUBIC EASE_OUT |
| Strip content swap (sign / claim / void) | ActiveStrip | `modulate:a` | 0 → 1 after the children swap | 0.12 | CUBIC EASE_OUT |
| Row hover | row plate | theme hover stylebox | instant | — | — |
| Row select / focus | row | pressed stylebox + shared 1 px `accent_danger_bright` focus ring | instant | — | — |
| Chip toggle | chip | pressed stylebox | instant | — | — |
| SIGN / ABANDON arm | button | font override to Ember Glow + `modulate:a` 1.0→0.70→1.0 twice (0.16 per step) | — | 0.16 ×4 | SINE |
| Arm expiry | armed button + strip | colour/text restore at the 3.0 s one-shot Timer | — | 3.0 | — |
| Refusal | SIGN + row STATUS cell | `modulate:a` 1.0→0.35→1.0→0.35→1.0 | — | 0.12 / 0.16 / 0.12 / 0.16 | SINE |
| CLAIM idle while FULFILLED | CLAIM | `modulate:a` 1.0→0.80→1.0, looping; stops on claim or strip rebuild | — | 2.4 + 2.4 | SINE (the status-beacon ambient family) |
| Payout | credits readout | count-up old → new | — | 0.35 | CUBIC EASE_OUT |

No screen shake, no parallax, no glow: the pane's whole motion vocabulary is the hub's own table plus the two stated additions (row stagger, CLAIM idle).

---

## 9. Audio hooks (one line per sounding state change)

| Moment | Cue | Resolves to |
|---|---|---|
| BOUNTY BOARD entered (module switch) | shell `play_sfx(&"sfx_station_breaker_on_01")`; bed = the station room loop | `res://assets/audio/sfx/sfx_station_breaker_on_01.ogg` · `amb_station_room_01.ogg` |
| Row hover / focus move | `play_ui(AudioManager.UiCue.HOVER)` | `ui_hover.ogg` |
| Row select, chip toggle, CLAIM / ABANDON press | `play_ui(AudioManager.UiCue.CLICK)` | `ui_click.ogg` |
| SIGN / ABANDON armed | `play_sfx(&"sfx_station_breaker_on_01")` — the hub's arm cue | the breaker file above |
| Signed (second press) | today `play_sfx(&"sfx_station_hum_loop_01")`; should be `ui_confirm_01` | see the gap below |
| Claim paid | same success cue as signed + the credits count-up beat | as above |
| Void (abandon confirmed) and expiry notice | should be `ui_denied_01` | see the gap below |
| Any refusal (§6.12) | should be `ui_denied_01` | see the gap below |
| Offers list scrolled | should be `ui_scroll_01` | see the gap below |

**Reachability gap (binding, from the hub's audio table):** `UiCue` carries only `CLICK` and `HOVER`, and `play_sfx` searches only `assets/audio/sfx/` — `ui_confirm_01.ogg`, `ui_denied_01.ogg` and `ui_scroll_01.ogg` live in `assets/audio/ui/` and are unreachable today. Wire the calls above to the cue **names** so they light up when the three `UiCue` members (or a `play_ui_cue`) land; until then signed/claim falls back to the hum one-shot exactly like purchase success does, and refusal/void/expiry/scroll are silent. FULFILLED's idle pulse is silent by design.

---

## 10. Acceptance criteria

1. At 1920x1080 the pane fits the host content box x 453..1842, y 216..969 with no clipping: header 40 + strip 72 + filters 48 + body 525 (6 rows × 76 + 5×6 = 486 visible **without** the scrollbar) + footer 20.
2. The rail shows `BOUNTY BOARD` as module 7 between REPAIRS and LAUNCH; eight 56 px entries + session furniture fit the 769 px rail content box (490 + 132 = 622 ≤ 769) with the spacer still ≥ 100 px.
3. With heat 58 for Concord, every Concord row reads `LOCKED` in #C8461B, SIGN is disabled and skipped by Tab, and the detail note shows the exact fine `1 450 CR` (58 × 25) with the AT LAUNCH wording only when docked at a Concord station.
4. Arming SIGN (first press) swaps the strip to the ARMED copy in Ember Glow and pulses twice; a second press within 3.0 s signs, the row leaves the shelf, the strip shows `0/6`, and `profile_changed(&"contracts")` fires once; letting the Timer expire disarms with no state change.
5. The 6th in-scope pirate kill flips the profile to `fulfilled`; the next pane entry shows `6/6`, `DONE`, CLAIM enabled with the idle pulse; CLAIM pays `reward_cr`, +2 issuer standing, one economy-log line, and animates the credits readout 0.35 s.
6. Expiry uses flight minutes only: 10 docked minutes change nothing; crossing `window_min` in space voids the contract (−2 standing) and the next pane entry writes the ember `CONTRACT FAILED · WINDOW EXPIRED · …` line into the shell status strip.
7. ABANDON needs a second press within 3.0 s; Escape disarms it without voiding, then a second Escape moves focus to the BOUNTY BOARD rail entry.
8. Filters combine by AND; the zero state renders `NO CONTRACTS MATCH · PRESS ALL TO RESET`, and pressing either `ALL` chip restores rows.
9. No keyboard-only player is trapped: every commit (sign, claim, abandon) is reachable by Tab + `ui_accept` alone, and no state requires the mouse.
10. Colour audit: every ember pixel maps to §6's semantic table (locked, armed, refusal, expiry, danger footer, heat ≥ 50 / standing ≤ −51); hover and selection never use ember; no colour outside the 16 appears.

---

## 11. Numbers the coder needs

**Sizes / spacing (px).** safe margin 24 · rail 360 wide, entry 56 tall, rail separations 6 (entries) / 10 (rail box) · host content box 1390 × 753 at x 453..1842 / y 216..969 · pane VBox separation 12 · pane header 40 (icon 40×40) · active strip 72 tall (margins 12/8, buttons 56) · filter row 48 tall, chips 96×48, separation 6 · board body separation 16 · offers column min 620 · detail column 754 measured (h-expand) · row 76 tall / gap 6 · RowInner 12/8 · row columns: title expands, REWARD 130, STATUS 110 · detail value column 220 right-aligned · SIGN 88 tall, full detail width · strip buttons 110 (CLAIM) / 130 (ABANDON) × 56 · strip stylebox: fill #15181D, border 1 px #2A2E35, corner radius 2, margins 12/8 · focus ring 1 px `accent_danger_bright` (theme-shared).

**Contract numbers.** PATROL 6 kills / 30 flight min / 400 CR · SECTOR SWEEP 10 kills / 45 flight min / 750 CR · claim +2 standing · void −2 standing · shelf 6 (one patrol + one sweep × 3 factions) · rotation band 1200 s · ACTIVE_LIMIT 1 · lock heat ≥ 50 · lock standing ≤ −51 · fine heat × 25 · kill effects +1 standing / −3 heat (system law) · ARM_SECONDS 3.0 · fulfilment idle pulse 2.4 + 2.4 s.

**Type (theme variations only — no per-node font sizes, no overrides).** `StationPanelTitle` 20 Bone: pane title · `StationButton` 22 Bone: rail entry label, SIGN, CLAIM, ABANDON · `StationValue` 18 Bone (colour per state): row titles, REWARD, STATUS, strip title/progress/time, detail values, ConfirmStrip · `SectionHeader` 16 Ash: `OPEN CONTRACTS`, `CONTRACT DETAIL` · `StationCaption` 13 Ash: subtitle, tag, meta, captions, notes, footer · `Button` 14 Bone: filter chips.

**Colours (the only ones this pane touches; the rest of the 16 are unused — nothing outside the 16 may appear).**

| Hex | Name | Theme token | Used for |
|---|---|---|---|
| #15181D | Panel Black | panel fills (stylebox; `void_panel_raised` for pressed bands) | strip background, row/chip pressed bands |
| #2A2E35 | Panel Steel | borders | the strip's 1 px border |
| #8D939B | Ash Text | `Tokens/text_dim` | body, captions, `OPEN`, dimmed values |
| #C9CDD2 | Bone Text | `Tokens/text_primary` | headings, key values, focused labels |
| #C8461B | Burnt Ember | `Tokens/accent_danger` | every semantic site in §6's ember law |
| #E8703A | Ember Glow | `Tokens/accent_danger_bright` | armed font override, focus ring |

**Copy strings (ALL CAPS, verbatim).**

| Key | String |
|---|---|
| rail label / pane title | `BOUNTY BOARD` |
| pane subtitle | `GALACTIC POSTINGS · CLAIM AT ANY STATION` |
| rotation tag | `NEXT POSTING <m:ss>` |
| list / detail captions | `OPEN CONTRACTS` · `CONTRACT DETAIL` |
| filter captions + chips | `FACTION` `ALL` `CONCORD` `MERIDIAN` `CHOIR` · `TYPE` `ALL` `PATROL` `SWEEP` |
| row titles | `PATROL` · `SECTOR SWEEP` |
| row meta (examples) | `CONCORD SPACE · 6 PIRATES · 30 MIN` · `MERIDIAN · <SECTOR NAME> · 10 PIRATES · 45 MIN` |
| row status | `OPEN` · `LOCKED` |
| strip none | `NO ACTIVE CONTRACT` · `SIGN A CONTRACT BELOW · THE BOARD PAYS ON RETURN` |
| strip active | `ACTIVE · PATROL · CONCORD SPACE` · meta `6 PIRATES · 30 FLIGHT MIN · 400 CR ON CLAIM` · `PIRATES DOWN` · `TIME LEFT` |
| strip fulfilled | `FULFILLED · PATROL · CONCORD SPACE` · `DONE` |
| strip armed | `ARMED · PRESS ABANDON AGAIN WITHIN 3 s TO VOID` |
| buttons | `SIGN CONTRACT` · `CLAIM` · `ABANDON` |
| sign strip | `ONE CONTRACT IN THE AIR AT A TIME` · `ARMED · PRESS SIGN AGAIN WITHIN 3 s TO SIGN` |
| detail labels | `ISSUER` `AREA` `TARGET` `WINDOW` `REWARD` `CLAIM BONUS` `VOID PENALTY` `YOUR STANDING` `YOUR HEAT` |
| detail note (open) | `KILLS COUNT FROM SIGNING · EACH KILL ALSO PAYS +1 STANDING · −3 HEAT` |
| lock lines | `LOCKED · <FACTION> HUNTS YOU · <heat> HEAT · PAY <n> CR AT LAUNCH` · `LOCKED · <FACTION> HUNTS YOU · PAY AT A <FACTION> STATION` · `LOCKED · <FACTION> EXILED YOU · STANDING TOO LOW` · `ONE CONTRACT AT A TIME · SETTLE YOUR ACTIVE CONTRACT FIRST` |
| empty states | `NO CONTRACTS MATCH · PRESS ALL TO RESET` · `BOARD REFRESHES AT THE NEXT POSTING` · `NO CONTRACT SELECTED` |
| refusals | `REFUSED · <FACTION> HUNTS YOU · PAY <n> CR` · `REFUSED · <FACTION> EXILED YOU` · `REFUSED · ONE CONTRACT AT A TIME` |
| success lines | `SIGNED · PATROL · 6 PIRATES · 30 FLIGHT MIN` · `CONTRACT PAID · 400 CR · CONCORD STANDING +2` · `CONTRACT VOIDED · CONCORD STANDING −2` |
| expiry notice | `CONTRACT FAILED · WINDOW EXPIRED · <FACTION> STANDING −2` |
| footer | `PIRATE KILLS PAY +1 STANDING · −3 HEAT · BOUNTIES PAY IN CREDITS` → danger: `<FACTION> HUNTS YOU · PAY <n> CR AT LAUNCH` |
| tier words | `CLEAN` `SUSPECT` `WANTED` `OUTLAW` · exile word `EXILE` |
| HUD seam line | `CONTRACT · <KIND> · <k>/<n> PIRATES · <mm:ss>` |

---

## 12. Conflicts (this brief wins; flagged, not followed)

1. **Live rail vs the brief's list.** The shipped `station.gd` already carries 8 modules — the first is labelled ARMORY (renamed from OUTFITTING) and AUCTION sits at index 3 — while this brief names 7 entries without AUCTION. Per the brief, this spec's arithmetic assumes 7 + BOUNTY BOARD = 8; against the live 9-entry tree the same math gives 9×56 + 8×6 = 552 and a spacer of ~85 px — still no rail rework, and the module still slots before LAUNCH.
2. **Burnt Ember hex drift.** UI_SPEC §5.1 uses `#c8471f` for tooltip danger text; the palette (and this brief) says `#C8461B`. The brief's hex is law for this screen; the tooltip doc's digit is a typo to fix in that doc, not here.
3. **Outlaw docking.** The enforcement pin (13 §7) routes dock refusal through standing ≤ −51 and gate refusal through the heat tier, while this brief states heat-Outlaw is denied docking outright. Both readings agree on what matters here — an Outlaw never reaches the hub, so the pane needs no Outlaw state beyond the tier word — so the spec takes no side.
