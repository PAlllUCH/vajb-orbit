# BOUNTY BOARD — station-hub module screen design spec

A station-hub module where the docked faction posts pirate-hunt contracts and the
player settles the bounty on their own head. Two jobs on one screen: work out
(postings, accept, track, claim) and bounty in (heat ledger, fine payment). It is
the eighth module of the station rail and draws only into the existing module host.

---

## 1. Screen composition

### 1.1 Rail integration and the fit

**Placement.** A new rail entry `BOUNTY BOARD` inserted **between REPAIRS and
LAUNCH**, so LAUNCH keeps its bottom-of-list position beside the session group
(both are exits) and "take work, then undock" is two presses. Shipped order:

`OUTFITTING · REFINERY · EXCHANGE · SHIPYARD · FITTING · REPAIRS · BOUNTY BOARD · LAUNCH`

Rail label `BOUNTY BOARD` (single line, `autowrap` off). Rail icon
`res://assets/icons/service/icon_service_bounty.svg` drawn 40x40 (Godot 4 imports
the SVG natively; fallback if the pipeline objects:
`res://assets/icons/tint/icon_alt_crosshair_targeting_plaque_48.png`, tinted
`text_primary`). Entry anatomy is the house rail entry (Button `StationButton`,
`toggle_mode`, min `(0, 56)`, `RowInner` 16/8, icon 40 + label `StationPanelTitle`).

**The fit, measured.** The rail content box is 270 x 769 (x 69..339, y 208..977).
`RailBox` is a `VBoxContainer` (separation 10) with fixed children `RailCaption`
(18), `ModuleButtons`, `RailSpacer` (absorbs slack), `SessionCaption` (18),
`SessionButtons` (1 x 56 for LOG OUT), so the fixed chrome is
18 + 18 + 56 + 4 x 10 = 132 px.

| Entries | Entry stack | Total (stack + chrome) | RailSpacer left |
|---|---|---|---|
| 7 (today's brief count) | 7 x 56 + 6 x 6 = 428 | 560 | 209 (reproduces the measured session caption ink y 899..907 and LOG OUT plate y 924..974) |
| **8 (this spec)** | 8 x 56 + 7 x 6 = 490 | 622 | **147** |
| 9 (if AUCTION counts, see §11) | 9 x 56 + 8 x 6 = 552 | 684 | 85 |
| 10 | 614 | 746 | 23 |
| 11 (first failure) | 676 | 808 | -39, breaks |

So the eighth entry fits with **147 px of spacer slack**: no compression, no new
measurement, entry height 56 and rail width 360 unchanged. The first count that
fails is 11 entries; the documented future mitigation is 48 px entries
(11 x 48 + 10 x 6 + 132 = 720 <= 769). At `ui_scale` 1.4 the label room inside an
entry is 186 px (270 - 32 inner margins - 40 icon - 12 separation);
`BOUNTY BOARD` at `StationPanelTitle` 20 px measures about 120 px of ink, about
168 px at 1.4, both inside the room. 4:3 grows `Body`, so the spacer grows too.

### 1.2 The pane fills the host

`vajb-orbit/ui/station/bounty_panel.tscn`, mounted behind `Module.BOUNTY` through
the house `MODULE_FILES` mechanism (no `station.tscn` edit). The pane is one
`VBoxContainer` (separation 12) filling the host content box **x 453..1842,
y 216..969 (1390 x 753)** at 1920x1080. Everything is container-placed; the only
full-rect child is the confirm overlay (§1.4). Note the house stylebox gotcha:
`PanelRaised` insets its child 33 px per side before any inner margin, which is
already accounted for in the measured boxes above.

### 1.3 Measured boxes at 1920x1080

Pane stack, top to bottom (VBoxContainer, separation 12):

| Region | Node | Container | size_flags | Min size | Measured box |
|---|---|---|---|---|---|
| Pane header | `PaneHeader`, `HBoxContainer`, separation 12 | child of pane | v 0 | `(0, 48)` | y 216..264 |
| Pane icon | `PaneIcon`, `TextureRect` | child of `PaneHeader` | v 4 | `(40, 40)` | `icon_service_bounty.svg` 40x40 |
| Title block | `TitleBox` (`PaneTitle` `BOUNTY BOARD` + `PaneSubtitle`), `VBoxContainer`, separation 2, h3 v4 | child of `PaneHeader` | h 3 | text | title ink starts y 216+ |
| Restock tag | `PanelTag`, `Label` (`StationCaption`), v 4 | child of `PaneHeader` | v 4 | text | `NEXT RESTOCK <m:ss>`, right-aligned in the band |
| Faction ledger | `LedgerStrip`, `HBoxContainer`, separation 12 | child of pane | v 0 | `(0, 32)` | y 276..308, full width x 453..1842 |
| One ledger cell | `LedgerCell`, `HBoxContainer`, separation 10 | x3, each `size_flags_horizontal 3` | fill | none | ≈453 wide each; glyph 24 + name + heat value + standing |
| Body | `Body`, `HBoxContainer`, separation 16 | child of pane | v 3 | none | y 320..824 (504 tall) |
| Board column | `BoardList`, `VBoxContainer`, separation 8 | child of `Body` | h 0 | `(760, 0)` | x 453..1212 |
| Board header | `BoardHeader`, `HBoxContainer`, separation 6 | child of `BoardList` | v 0 | `(0, 32)` | y 320..352 |
| Filter chips | 4 x `Button` (base `Button`, `toggle_mode`), min `(0, 28)` | inside `BoardHeader` | h 0 | widths 64 / 56 / 56 / 56 | `ALL`, `T1`, `T2`, `T3`; strip separation 6 |
| Order note | `OrderNote`, `Label` (`StationCaption`) | inside `BoardHeader`, after `h3` spacer | v 4 | text | `ORDER · HEAVY FIRST` |
| Posting list | `BoardScroll`, `ScrollContainer`, `horizontal_scroll_mode 0`, `follow_focus true` | child of `BoardList` | v 3 | none | y 360..824 (464 tall) |
| Posting rows | `BoardRows`, `VBoxContainer`, separation 6 | child of `BoardScroll` | h 3 | none | 5 rows = 5 x 76 + 4 x 6 = 404, fits without scrolling |
| Detail column | `DetailColumn`, `VBoxContainer`, separation 8 | child of `Body` | h 3 | `(614, 0)` | x 1229..1842 |
| Detail caption | `DetailCaption`, `Label` (`SectionHeader`) | child of `DetailColumn` | v 0 | text | `CONTRACT DETAIL`, y 320..338 |
| Detail rows | `DetailRows`, `VBoxContainer`, separation 6 | child of `DetailColumn` | v 0 | 8 lines x 22 | y 346..564 |
| Detail spacer | `DetailSpacer`, `Control`, v 3 | child of `DetailColumn` | v 3 | none | absorbs 12 px at 16:9, all slack at 4:3 |
| Primary action | `DetailAction`, `Button` (`StationButton`) | child of `DetailColumn` | v 0 | `(0, 56)` | x 1229..1842 |
| Secondary action | `DetailAbandon`, `Button` (`StationButton`) | child of `DetailColumn` | v 0 | `(0, 56)` | 8 px below |
| Bounty caption | `BountyCaption`, `Label` (`SectionHeader`) | child of `DetailColumn` | v 0 | text | `YOUR BOUNTY · <FACTION>` |
| Bounty line | `BountyLine`, `Label` (`StationValue`) | child of `DetailColumn` | v 0 | text | `FINE 1 000 CR · HEAT 42 · SUSPECT` |
| Pay action | `PayButton`, `Button` (`StationButton`) | child of `DetailColumn` | v 0 | `(0, 48)` | `PAY BOUNTY (1 000 CR)` |
| Active caption | `ActiveCaption`, `Label` (`SectionHeader`) | child of pane | v 0 | text | `ACTIVE CONTRACTS · <k> / 3`, y 836..854 |
| Active cards | `ActiveCards`, `HBoxContainer`, separation 16 | child of pane | v 0 | `(0, 76)` | y 866..942 |
| One active card | `Button` (base `Button`, `toggle_mode`), each `size_flags_horizontal 3` | child of `ActiveCards` | h 3 | `(0, 76)` | ≈452 wide; measured x 453..905, 922..1374, 1391..1842 |
| Pane footer | `PaneFooter`, `Label` (`StationCaption`) | child of pane | v 0 | text | y 954..969, ink y 957..965 (matches the house footer) |

Row anatomy is the house `_make_row` (Button, base `Button` theme, `toggle_mode`,
`FOCUS_ALL`, min `(0, 76)`, pointing-hand cursor; `RowInner` 12/8; HBox separation
12): posting row = icon 40 (`icon_contract_hunt.svg`) + `TitleBox` (h3,
`StationValue` title + `StationCaption` meta) + value column 110 (`PAYOUT`
value + caption `CREDITS`) + value column 160 (`STATUS` value + gate caption).
Title block room = 390 px. Active card = same anatomy minus one column: icon 40 +
`TitleBox` (h3) + value column 130 (expiry/`READY`). Card title room = 234 px.

Detail row anatomy: `HBoxContainer` (separation 12), caption `Label`
(`StationCaption`, fixed 180 px) + value `Label` (`StationValue`, h3, 422 px).
All eight lines always render; absent values read `—`. No rebuild: rows are
rewritten by text/visibility/disabled only.

### 1.4 Confirm overlay (module-owned, host-scoped)

`BountyConfirm` is a full-rect child of the pane (x 453..1842, y 216..969),
`mouse_filter STOP`, hidden by default: a `ColorRect` dimmer (`Tokens/void_base`
alpha 0.72) over the pane content box, a `CenterContainer`, and a
`PanelContainer` (`PanelRaised`, min `(520, 0)`) with `MarginContainer` 20 and a
`VBoxContainer` (separation 16): title (`StationPanelTitle`), body
(`StationCaption`, autowrap), and an `HBoxContainer` (separation 10, alignment 2)
holding `CANCEL` (focused on open) and the confirm button, both `StationButton`
min `(190, 52)`. Measured panel box at 1920x1080: **x 887..1407, y 471..714**
(520 x 244; the 244 = 33 x 2 stylebox inset + 20 x 2 inner margin + 24 title +
16 + 30 body (2 lines) + 16 + 52 buttons). Keeping the overlay inside the host
means `station.tscn` and `station.gd` need no edit beyond the module enum.

### 1.5 Responsive and scaling rules

- 16:9 of any size: every number above holds; the stretch scales once.
- 21:9: all extra width goes to `ModuleHost`; `BoardList` keeps 760 and
  `DetailColumn` absorbs the slack (h3). Vertical numbers unchanged.
- 4:3: all extra height goes to `Body`; `DetailSpacer` and `BoardScroll` absorb
  it. The header band, ledger strip, active strip and footer keep their heights.
- Never scaled by layout: 360 rail, 56 entry, 76 row, 32 ledger strip, 76 card,
  48/40 px icons, all font sizes (theme items only, no per-node sizes). At
  `ui_scale` 1.4 all eight theme font items scale together; the confirm body
  autowraps by design and everything else was sized to survive 1.4 (§1.1).

---

## 2. The contract model (every number, with its reasoning)

One posting family, pirate-hunt warrants in the **issuing faction's space** (the
docked station's faction posts its own work; cross-faction work would turn the
board into a travel agent, and the politics stay where they belong: which station
you dock at). Three tiers:

| Tier | Label | Kills | Payout | Window (play) | Gate at accept | Per-kill rate |
|---|---|---|---|---|---|---|
| T1 | `SCRUB SWEEP` | 3 pirates | 100 CR | 20 min (1 200 play-s) | none | 33 CR |
| T2 | `HUNT CLAIM` | 6 pirates | 250 CR | 40 min (2 400 play-s) | standing >= -20 with issuer | 42 CR |
| T3 | `PURGE WARRANT` | 10 pirates | 500 CR | 60 min (3 600 play-s) | standing >= 0 and heat 0-19 (Clean) with issuer | 50 CR |

Economy derivation, anchored to the contract numbers (session net 1 200 CR; fine
= heat x 25 CR; per-kill law +1 standing / -3 heat):

- **Danger unit = 25 CR** (the fine rate per heat point). The game already
  prices risk at 25 CR, so contract pay is quoted against it.
- **T1 = 100 CR (about 8 % of a session)**: an errand that tops up a haul run,
  33 CR per kill, about 1.3 x the danger unit.
- **T2 = 250 CR (about 21 %)**: the bread-and-butter warrant; the per-kill rate
  rises to 42 CR because six kills hold you in hostile space longer.
- **T3 = 500 CR (about 42 %)**: the evening's anchor, deliberately under half a
  session so the board tops up honest income instead of replacing it, and always
  below the 1 000 CR worst-case fine (40 heat), so crime stays more expensive
  than work.
- Mixed evening check: T2 + 2 x T1 = 450 CR = 37 % of a session on top of kill
  loot. A pure contract evening tops out at T3 + T2 = 750 CR = 62 % of a session.
- **Completion credit = payout + 2 standing with the issuer** (claim step, §4).
  2 standing = two kills' worth of the per-kill law, a nudge, never a standing
  farm. Heat moves only through the existing law (-3 per pirate kill, -1 per
  minute of play, or the fine); the board only *projects* it (§3).
- **Windows 20/40/60 min** = 20 min per tier. 20 min is one station band, the
  game's existing time unit. The window is **play time**: it rides the game
  scene's play-seconds accumulator (the same one heat decay uses) and does not
  run while docked, so a player staring at the board can never expire.
- **Active slots = 3.** The active strip holds three cards; a fourth would need a
  second strip row and dilute the triage the slot limit creates.
- **Board draw = 5 postings per band (2 x T1, 2 x T2, 1 x T3).** Five rows fit
  the 464 px list without scrolling at 1080p (§1.3); the scarce tier is the hook.
  The board redraws when the station band turns over (`WorldClock` 1 200 s
  bands), keyed to `board.issued_band`, evaluated on pane entry, no Timer. The
  `NEXT RESTOCK <m:ss>` tag is a reading computed at pane entry (it does not
  tick). Accepted contracts are snapshots and survive a restock; un-taken
  postings from the old band are replaced.
- **Kill crediting (FIFO):** a pirate kill in the issuer's space increments
  **exactly one** active posting, the earliest-accepted one whose scope matches.
  One kill never pays twice; no player management is needed. Kills outside the
  issuer's space or non-pirate kills count nothing.
- **Fail costs nothing but the flight.** No payout, no standing change, no
  penalty. The fighter loop must never punish twice in an economy where a 40
  heat fine already costs a session.
- T1's gate is "can dock at all" (dock refusal sits at standing <= -51), so a
  docked player always qualifies; T2/T3 gates are the faction's growing trust;
  T3's Clean gate is the faction declining to hand patrol work to a pilot its
  patrols are scanning (a Wanted player still runs T1/T2, whose kills clear heat
  at -3 each, which is the redemption path through this screen).

Outlaw note: an Outlaw of the docked faction cannot be on this screen at all
(dock refusal), so the worst in-person state is Wanted with the docked faction.
Outlaw with *another* faction is visible and presented as danger (§5).

---

## 3. Information design and data contract

### 3.1 One posting row shows

`[icon 40] T1 · SCRUB SWEEP` (StationValue 18) over `3 PIRATES · CONCORD SPACE · 20 MIN`
(StationCaption 13) | `100` / `CREDITS` (col 110) | `OPEN` / `OFFERED` (col 160).

- Row title = tier tag + label: `T1 · SCRUB SWEEP`, `T2 · HUNT CLAIM`,
  `T3 · PURGE WARRANT`.
- Row meta = `<count> PIRATES · <FACTION> SPACE · <window> MIN`.
- PAYOUT column = integer value + caption `CREDITS`.
- STATUS column = `OPEN` or `LOCKED`; its caption carries the gate:
  `OFFERED`, `CLEAN ONLY`, or `STANDING -20 NEEDED`.

### 3.2 One active card shows

`[icon 40] T2 · HUNT CLAIM` over `PROGRESS 4 / 10 · MERIDIAN` | `EXPIRES 12:41` /
`PLAY LEFT`. States: `READY` / `CLAIM AT THE BOARD` when progress is complete;
`EXPIRES <m:ss>` in Burnt Ember when under 2 min of window remains; the issuer is
appended to the caption whenever it is not the docked faction.

### 3.3 The detail view shows (8 fixed lines)

| # | Caption | Value |
|---|---|---|
| 1 | `ISSUER` | `CONCORD · DOCKED` (the `· DOCKED` suffix only for the docked faction) |
| 2 | `SCOPE` | `CONCORD SPACE · ANY SECTOR` |
| 3 | `TARGET` | `PIRATES · 10` |
| 4 | `WINDOW` | `60 MIN PLAY`; for an active contract `12:41 PLAY LEFT` |
| 5 | `PAYOUT` | `500 CR` |
| 6 | `PROGRESS` | `—` when offered, `4 / 10`, `10 / 10 · READY` |
| 7 | `ON COMPLETION` | `+2 STANDING · -30 HEAT (KILL LAW)`; the heat figure = min(heat, 3 x count), a projection only |
| 8 | `REQUIREMENT` | `NONE`, `STANDING -20 · MET`, `CLEAN ONLY · MET`, or unmet: `STANDING -20 NEEDED` / `CLEAN ONLY · YOUR HEAT 34` (line in Burnt Ember) |

### 3.4 Player context (the ledger)

`LedgerStrip` shows all three factions every visit: 24 px insignia
(`icons/tint/icon_insignia_<faction>_48.png`; `text_dim` normally,
`text_primary` for the docked faction) + name (`StationCaption`) +
`HEAT <n> · <TIER>` (`StationValue`) + `STANDING <±n>` (`StationCaption`).
Tiers read `CLEAN` 0-19, `SUSPECT` 20-49, `WANTED` 50-79, `OUTLAW` 80-100.
`YOUR BOUNTY · <FACTION>` block (detail column) shows `FINE <n> CR · HEAT <h> ·
<TIER>` or `NO BOUNTY DUE`, with `fine = heat x 25 CR` (the law, computed not
invented) and the `PAY BOUNTY (n CR)` action.

### 3.5 Data contract (what the coder wires)

`ContractPosting` (board row, persisted with the save):

| Field | Type | Example | Notes |
|---|---|---|---|
| `posting_id` | `StringName` | `&"concord_b07"` | stable within a band draw |
| `faction_id` | `StringName` | `&"concord"` | issuer = the docked faction |
| `tier` | `int` | 1..3 | drives label, icons, gates |
| `label` | `String` | `HUNT CLAIM` | from the tier table (§2), never a literal in code |
| `target_kind` | `StringName` | `&"pirate"` | only kind today |
| `count` | `int` | 3 / 6 / 10 | kills required |
| `payout_cr` | `int` | 100 / 250 / 500 | |
| `window_seconds` | `int` | 1200 / 2400 / 3600 | play seconds |
| `gate_standing` | `int` | -50 / -20 / 0 | accept requires standing >= this |
| `gate_heat_max` | `int` | 100 / 100 / 19 | accept requires heat <= this |
| `issued_band` | `int` | 412 | station band of the draw |

`ActiveContract` (persisted): `posting_id`, the posting snapshot (all fields
above copied at accept), `accepted_at_play : float`, `expires_at_play : float`
(= accepted_at_play + window_seconds), `progress : int`, `state : StringName`
(`&"active"`, `&"ready"`).

Board state (persisted): `band : int`, `postings : Array`, `last_outcome :
Dictionary` (empty or `{kind: &"claimed"|&"failed"|&"abandoned", posting_id,
payout_cr, standing_gained}`).

Service interface (panels request, the profile mutates, house law):

- Reads: `contract_board() -> Array`, `contracts_active() -> Array`,
  `contract_last_outcome() -> Dictionary`, `heat(faction_id) -> int`,
  `standing(faction_id) -> int`, `can_afford(cr) -> bool` (presentation only).
- Writes: `accept_contract(posting_id) -> bool`, `abandon_contract(posting_id)
  -> bool`, `claim_contract(posting_id) -> bool`, `pay_bounty(faction_id) -> bool`
  (the existing function LAUNCH already calls).
- Game-side hook: `on_pirate_killed(faction_id)` on the existing pirate-kill
  event (the +1 standing / -3 heat law fires unchanged) applies the FIFO rule
  (§2) and flips `active` to `ready` at `count`.
- Signals: `profile_changed(key)` with `&"credits"`, `&"heat"`, `&"standing"`,
  `&"contracts"`; claim writes one `CONTRACT` economy-log line, pay_bounty its
  one `BOUNTY` line.
- Refusal reasons (`StringName`): `&"slots_full"`, `&"gate_heat"`,
  `&"gate_standing"`, `&"already_active"`, `&"not_ready"`, `&"not_active"`,
  `&"no_bounty"`, `&"insufficient_credits"`, `&"unknown_id"`.

Wiring: add `Module.BOUNTY` before `Module.LAUNCH`, label `BOUNTY BOARD` in
`station.gd`'s `MODULE_LABELS`, and `bounty_panel.tscn` to `MODULE_FILES`. The
pane implements the house panel contract (`status_requested`, `refresh_profile`,
`focus_primary`) and owns its own footer strip (the shell cannot price a
contract, the same reason AUCTION owns its footer). In-space progress display is
a separate surface; this screen only requires that `progress` and
`expires_at_play` persist so the board renders them on return.

---

## 4. Contract lifecycle

States: `offered` -> `accepted` -> `ready` -> `claimed` (terminal), plus
`failed` and `abandoned` (terminal).

| Step | Trigger | Rule |
|---|---|---|
| Browse | pane entry | board draws the current band's 5 postings; selection lands on the first posting row (or the `ALL` chip if the board is empty); nothing is written |
| Filter | chip press | `ALL` / `T1` / `T2` / `T3` narrows the visible rows; sort is fixed, no sort control: heavy tier first, then payout descending, then posting id (`ORDER · HEAVY FIRST`) |
| Select | row or card press | writes nothing (SHIPYARD rework precedent: selecting previews, committing is a button) |
| Accept | `DetailAction` press on an offered posting | T1/T2 accept directly; **T3 opens the confirm overlay first** (a 60 min commitment). Checks: slots < 3, gate standing, gate heat, not already active. Success: posting moves from board to an active card, footer `ACCEPTED · T2 · HUNT CLAIM` |
| Track | active cards + detail lines 4/6 | `PROGRESS 4 / 10`, `12:41 PLAY LEFT`; the window runs only in flight; a kill in scope increments the FIFO posting |
| Ready | progress reaches count | state `ready`; the card reads `READY` / `CLAIM AT THE BOARD`; ready contracts **never expire** (the house holds the escrow) |
| Complete | `CLAIM (500 CR)` press | allowed at any board regardless of issuer; credits payout (+2 standing with issuer, one `CONTRACT` log line); footer `CLAIMED · T3 · PURGE WARRANT · +500 CR · +2 STANDING`; selection returns to the first posting row |
| Fail / expire | `expires_at_play` passes while `active` | in flight, silently; the card is removed, `last_outcome` records it; next pane entry shows `FAILED · T2 · HUNT CLAIM · WINDOW CLOSED` in the footer |
| Abandon | `ABANDON` press (active contract selected) | always behind the confirm overlay; no payout, no penalty; refused while `ready` (`REFUSED · CLAIM THE PAYOUT FIRST`); footer `ABANDONED · T1 · SCRUB SWEEP` |
| Pay bounty | `PayButton` press | always behind the confirm overlay (it spends credits); `pay_bounty(docked_faction)` zeroes heat instantly at `fine = heat x 25 CR`; the LAUNCH module's `PAY BOUNTY (n CR)` row does not move |

Player context at every step: the ledger (all three factions) is always visible;
gates read the player's heat/standing with the issuer at accept time only (a
later heat change never revokes an accepted contract); `ON COMPLETION` projects
the kill-law heat relief (`min(heat, 3 x count)`) and the +2 standing.

---

## 5. UI states (complete list)

| State | Presentation |
|---|---|
| Board with postings | 5 rows, one selected (pressed band `void_panel_raised`, the colour-blind selection channel; focus ring = 1 px `accent_danger_bright`) |
| Empty board | one disabled row `BOARD CLEAR · NEXT RESTOCK <m:ss>`; detail lines all `—`; `DetailAction` refuses with `REFUSED · NO POSTING SELECTED` |
| Filtered to zero | one disabled row `NO POSTINGS MATCH · FILTER T2`; the chip stays pressed |
| No active contracts | the strip shows one full-width disabled card `NO ACTIVE CONTRACTS · TAKE A POSTING` (geometry fixed) |
| Active contract(s) | cards as §3.2; `ACTIVE CONTRACTS · 2 / 3` caption |
| Locked posting | STATUS `LOCKED` + gate caption; requirement line 8 in Burnt Ember; the press is refused (§ refusal law) |
| Cannot afford (pay bounty) | fine value and button sum in Burnt Ember (the house refused-price rule); press runs the 4-step pulse and writes `REFUSED · NOT ENOUGH CREDITS · 1 000 NEEDED` |
| Confirm overlay | three instances: T3 accept, abandon, pay bounty (§1.4); CANCEL focused first |
| Danger state (own heat) | any faction at heat >= 50 renders its `HEAT` value and tier word in Burnt Ember (Wanted: hunters; Outlaw: denial); Suspect stays plain. This and the five sites below are the module's entire ember budget |
| Expiry warning | active card `EXPIRES <m:ss>` in Burnt Ember under 2 min, with the slow 2.4 s pulse (§7) |
| Refusals | footer strip text in Burnt Ember, success text in `text_primary` |

**Ember budget (semantic only, never decoration):** (1) heat >= 50 values in the
ledger, (2) unaffordable fine, (3) unmet requirement line, (4) expiry under
2 min, (5) refusal text in the footer (house §5.6), (6) the 1 px focus ring
(`accent_danger_bright`, sanctioned state colouring). Hover everywhere
brightens borders to Ash Text only; the menu's 6 px Ember Glow hover bloom is
**not** used in this module, not even on the confirm buttons.

**Refusal law (uniform):** every action button and posting row stays pressable;
a refused press writes its wording into `PaneFooter`, runs the 4-step pulse on
the pressed control, mutates nothing, and keeps focus and selection. Greying is
presentation only. The only disabled controls: `ABANDON` when the selection is
not an active contract (`text_dim` disabled), and the placeholder rows/cards of
the empty and zero-filter states.

---

## 6. Input

**Keyboard focus order (tree order, containers guarantee it):** rail entries
(`BOUNTY BOARD` at position 7, then LAUNCH, then LOG OUT) -> filter chips
(`ALL`, `T1`, `T2`, `T3`) -> posting rows top-down -> active cards left-to-right
-> `DetailAction` -> `DetailAbandon` -> `PayButton` -> wraps to rail entry 1.
`ui_up`/`ui_down` walk the current column and cross columns at the ends (default
neighbour walk); `BoardScroll` follows focus.

**Commit keys:** `ui_accept` on a chip filters, on a row or card selects (writes
nothing), on `DetailAction`/`DetailAbandon`/`PayButton` commits the labelled
action (T3 accept, abandon and pay open the confirm overlay first; in the
overlay `ui_accept` presses the focused button).

**Escape (`ui_cancel`), this module has no armed state (its commits use confirm
overlays, not arm windows), so two steps:** (1) confirm overlay open -> close it
and return focus to the button that opened it; (2) otherwise -> move focus to the
current rail entry. On the rail, a further `ui_cancel` opens the station's
LEAVE THE STATION confirm. Escape never leaves the station by itself.

**Module cycling (unchanged house law):** mouse on rail entries, `PageUp` /
`PageDown` from anywhere in the host (wrapping), `JOY_BUTTON_LEFT_SHOULDER` /
`RIGHT_SHOULDER`, `Tab`/`Shift+Tab` focus walk.

**Gamepad:** D-pad = the `ui_*` walk above; `ui_accept` (A) = select/commit;
`ui_cancel` (B) = the two-step escape; shoulders = module cycling.

**Mouse:** hover raises the row/card icon `modulate:a` 0.72 -> 1.0 and shows the
pointing-hand cursor (hover does not select); click = the control's `pressed`
(select on rows/cards, commit on buttons, filter on chips); wheel scrolls the
posting list only when it overflows; no drag anywhere.

---

## 7. Motion

`Tween` only, never `_process`; tweens created from the screen node, held in a
local array, killed in `_exit_tree()`.

| Beat | Target | Property | From -> To | Time | Transition / ease |
|---|---|---|---|---|---|
| Module switch in | pane | `modulate:a` | 0 -> 1 | 0.18 | `TRANS_CUBIC` / `EASE_OUT` (house) |
| Module switch out | pane | `modulate:a` | 1 -> 0 | 0.12 | `TRANS_QUAD` / `EASE_IN`, then `hide()` (house) |
| Row appear (pane entry, restock, filter change) | each posting row | `modulate:a` | 0 -> 1 | 0.15 each, stagger 0.03 top-down | `TRANS_CUBIC` / `EASE_OUT` |
| Row hover / out | row or card icon | `modulate:a` | 0.72 <-> 1.0 | 0.09 | linear (house) |
| Accept commit | accepted row | `modulate:a` | 1 -> 0 | 0.12 | `TRANS_QUAD` / `EASE_IN`, then moved to the card strip |
| Card appear / disappear | active card | `modulate:a` | 0 -> 1 / 1 -> 0 | 0.15 / 0.12 | `TRANS_CUBIC` / `EASE_OUT` / `TRANS_QUAD` / `EASE_IN` |
| Claim commit | `CreditsValue` (header housing) | counting old -> new | 0.35 | `TRANS_CUBIC` / `EASE_OUT` (house) |
| Refusal | pressed control + `CreditsPanel` (credit refusals) | `modulate:a` | 1.0 -> 0.35 -> 1.0 -> 0.35 -> 1.0 | 0.12 / 0.16 / 0.12 / 0.16 | `TRANS_SINE` (house 4-step) |
| Confirm open | dimmer / panel | `color:a` 0 -> 0.72 / `modulate:a` 0 -> 1 | 0.20 / 0.12 | `TRANS_QUAD` `EASE_OUT` / `TRANS_CUBIC` `EASE_OUT` |
| Confirm close | panel / dimmer | `modulate:a` 1 -> 0 / `color:a` 0.72 -> 0 | 0.10 / 0.15 | `TRANS_QUAD` / `EASE_IN`, then `hide()` |
| Expiry warning (< 2 min, the only loop) | card expiry label | `modulate:a` | 1.0 -> 0.55 -> 1.0 | 2.4 + 2.4 | `TRANS_SINE`, looping, killed on hide/exit |

No scaling, no glow, no other pulses. Detail values rewrite instantly (numbers
must be readable at once).

---

## 8. Audio hooks (one line per state change)

| Moment | Call / file |
|---|---|
| Module switched to the board | `play_sfx(&"sfx_station_breaker_on_01")` (house switch cue) |
| Focus move between chips, rows, cards | `play_ui(AudioManager.UiCue.HOVER)` |
| Any button or chip press | `play_ui(AudioManager.UiCue.CLICK)` |
| Posting rows appear (restock) | `ui_scroll_01` (see reachability note) |
| Accept succeeds | `ui_confirm_01` |
| Accept refused (slots/gate/already) | `ui_denied_01` |
| Confirm overlay opens or closes | `play_ui(AudioManager.UiCue.CLICK)` |
| Abandon confirmed | `play_ui(AudioManager.UiCue.CLICK)` (the commit; the removal is silent) |
| Claim succeeds | `ui_confirm_01` (credits counting is visual only) |
| Claim refused (not ready) | `ui_denied_01` |
| Pay bounty succeeds | `play_ui(AudioManager.UiCue.CLICK)` then `ui_confirm_01` |
| Pay bounty refused (credits / nothing due) | `ui_denied_01` |
| Contract fails in flight | no station sound; the outcome line is the record (an in-space cue belongs to the HUD surface) |

Reachability note (house gap, STATION_HUB §11/§14 item 7): `ui_confirm_01`,
`ui_denied_01` and `ui_scroll_01` exist on disk but `UiCue` carries only
`CLICK`/`HOVER`, so until the enum grows (or a `play_ui_cue(StringName)` lands)
those five moments are silent; the calls are named so the wiring is one pass when
the gap closes.

---

## 9. Acceptance criteria

1. The rail reads `OUTFITTING · REFINERY · EXCHANGE · SHIPYARD · FITTING ·
   REPAIRS · BOUNTY BOARD · LAUNCH`; the entry stack measures 490 px inside the
   769 px rail content box with 147 px of `RailSpacer` left, and LOG OUT is
   unchanged below the spacer.
2. The pane fills the host content box exactly (x 453..1842, y 216..969) and the
   stack measures 48 / 32 / 504 / 18 / 76 / 15 with 12 px separations, as §1.3.
3. The ledger shows all three factions' HEAT, TIER and STANDING; any faction at
   heat >= 50 renders exactly its heat value and tier word in `#C8461B`, and no
   other element on the strip is ember.
4. Pressing a posting row or active card writes nothing (verified: no profile
   call); only `DetailAction`, `DetailAbandon` and `PayButton` mutate, each
   behind its confirm rule (T3 accept, abandon, pay = overlay; T1/T2 accept and
   claim = direct).
5. A T3 accept opens the confirm overlay (520 x 244 panel at x 887..1407,
   y 471..714, CANCEL focused); `ui_cancel` closes it and returns focus to
   `DetailAction`; the pane does not leave the station on Escape.
6. Accepting moves the posting to an active card (max 3); a fourth attempt
   renders `REFUSED · CONTRACT SLOTS FULL · 3 / 3` in the footer in ember and
   mutates nothing; a T3 attempt while heat 34 renders `REFUSED · LOCKED ·
   CLEAN ONLY`.
7. A pirate kill in the issuer's space increments exactly one active posting
   (FIFO); at `count / count` the card reads `READY`; `CLAIM` credits 500 CR with
   the 0.35 s counting animation, writes +2 standing, and the footer reads
   `CLAIMED · T3 · PURGE WARRANT · +500 CR · +2 STANDING`.
8. A window that closes under count removes the card and records `FAILED · T2 ·
   HUNT CLAIM · WINDOW CLOSED`, shown on the next pane entry; play-seconds do
   not accrue while docked, so a contract cannot expire on this screen.
9. `PAY BOUNTY (n CR)` shows `n = heat x 25` for the docked faction (40 heat ->
   `1 000 CR`); a press with insufficient credits renders `REFUSED · NOT ENOUGH
   CREDITS · 1 000 NEEDED`, pulses 4 steps and zeroes nothing; a successful pay
   zeroes heat instantly and the ledger re-renders.
10. Every colour is one of the 16 palette hexes pushed through theme tokens; the
    ember sites are exactly the six of §5; hover brightens borders to Ash Text
    only; with filter `T3` and no T3 posted the list shows the single disabled
    `NO POSTINGS MATCH · FILTER T3` row, never a blank region.

---

## 10. Numbers the coder needs

**Sizes and spacing (px):** rail width 360; rail entry 56 (gap 6, stack 490, 8
entries); rail captions 18 each; `RailBox` separation 10; pane VBox separation
12; pane header 48; ledger strip 32; body 504 (y 320..824); body HBox
separation 16; board column 760 (x 453..1212); detail column 614
(x 1229..1842); board header 32; chips 64/56/56/56 wide x 28 (gap 6); board
scroll 464 (y 360..824); posting row 76 (gap 6, pitch 82); row inner margin 12/8;
row icon 40; row value columns 110 and 160; row title room 390; detail caption
column 180 (value 422); detail line 22 (gap 6, 8 lines = 218); detail VBox
separation 8; action buttons 56; pay button 48; active caption 18; active cards
76 tall, three equal (~452-453 wide, gap 16); card icon 40; card value column
130; card title room 234; pane footer 15 (ink y 957..965); confirm dimmer = pane
content box; confirm panel 520 x 244 (x 887..1407, y 471..714), inner margin 20
plus the 33 px `PanelRaised` inset; confirm buttons min 190 x 52; ledger glyph 24.

**Durations (s):** module switch in 0.18 / out 0.12; row appear 0.15 with 0.03
stagger; hover 0.09; accept row fade-out 0.12; card appear 0.15 / disappear
0.12; credits counting 0.35; refusal pulse 0.12 / 0.16 / 0.12 / 0.16; confirm
open 0.20 (dim) + 0.12 (panel); confirm close 0.10 (panel) + 0.15 (dim); expiry
pulse 2.4 + 2.4 loop. Easings: `TRANS_CUBIC/EASE_OUT` (in, appear, count),
`TRANS_QUAD/EASE_IN` (out, close), `TRANS_SINE` (pulse), linear (hover).

**Economy and time:** T1 3 kills / 100 CR / 1 200 play-s; T2 6 / 250 / 2 400;
T3 10 / 500 / 3 600; per-kill rates 33/42/50 CR; danger unit 25 CR; completion
+2 standing; kill law unchanged (+1 standing, -3 heat per pirate kill); fine =
heat x 25 CR; active slots 3; board draw 5 per 1 200 s band (2/2/1); expiry
warning threshold 120 s; T2 gate standing -20; T3 gate standing 0 and heat <= 19.

**Colours (palette name = law; token = what the code pushes):**

| Use | Palette (hex) | Theme token |
|---|---|---|
| Headings, key values | Bone Text `#C9CDD2` | `text_primary` |
| Body, captions, inactive | Ash Text `#8D939B` | `text_dim` |
| Warnings, critical values, refusals | Burnt Ember `#C8461B` | `accent_danger` |
| Focus ring | Ember Glow `#E8703A` | `accent_danger_bright` |
| Panel borders, dividers, button bodies | Panel Steel `#2A2E35` | `metal_mid` |
| Panel backgrounds | Panel Black `#15181D` | `PanelRaised` / `void_panel` |
| Selected row band | Void Haze family | `void_panel_raised` |
| Confirm dimmer | Void Black `#0A0E14` | `void_base` at 0.72 |

Theme items used: `PanelRaised`, `StationButton`, `StationPanelTitle` (20),
`StationValue` (18), `SectionHeader` (16), `StationCaption` (13), `Button` (14),
plus `ScrollContainer`/`VScrollBar` and the `Tokens/*` colours, all pushed via
`get_theme_color(token, &"Tokens")`. No per-node font sizes.

**Copy strings (ALL CAPS; `<n>` integer with a space thousands separator,
`<m:ss>` clock, `±n` signed standing):**

- Static: `BOUNTY BOARD` (rail + title); `<FACTION> POSTINGS · PILOT CONTRACTS`
  (subtitle); `NEXT RESTOCK <m:ss>`; `HEAT <n> · <TIER>`; `STANDING <±n>`;
  `POSTINGS · <n> OFFERED`; `ALL`; `T1`; `T2`; `T3`; `ORDER · HEAVY FIRST`;
  `CONTRACT DETAIL`; `ISSUER`; `SCOPE`; `TARGET`; `WINDOW`; `PAYOUT`; `PROGRESS`;
  `ON COMPLETION`; `REQUIREMENT`; `CONCORD · DOCKED`; `<FACTION> SPACE · ANY
  SECTOR`; `PIRATES · <n>`; `<n> MIN PLAY`; `<n> CR`; `+2 STANDING · -<3n> HEAT
  (KILL LAW)`; `NONE`; `STANDING -20 · MET`; `CLEAN ONLY · MET`;
  `ACTIVE CONTRACTS · <k> / 3`; `YOUR BOUNTY · <FACTION>`;
  `FINE <n> CR · HEAT <h> · <TIER>`; `NO BOUNTY DUE`.
- Tier labels and rows: `SCRUB SWEEP`; `HUNT CLAIM`; `PURGE WARRANT`;
  `T<1-3> · <LABEL>`; `<n> PIRATES · <FACTION> SPACE · <n> MIN`; `CREDITS`;
  `OPEN`; `LOCKED`; `OFFERED`; `CLEAN ONLY`; `STANDING -20 NEEDED`.
- Cards: `PROGRESS <p> / <n> · <FACTION>` (issuer suffix only when not docked);
  `EXPIRES <m:ss>`; `PLAY LEFT`; `READY`; `CLAIM AT THE BOARD`;
  `NO ACTIVE CONTRACTS · TAKE A POSTING`.
- Buttons: `ACCEPT`; `ACCEPTED`; `CLAIM (<n> CR)`; `ABANDON`;
  `PAY BOUNTY (<n> CR)` (label `PAY BOUNTY` when nothing is due); `CANCEL`.
- Placeholders: `BOARD CLEAR · NEXT RESTOCK <m:ss>`;
  `NO POSTINGS MATCH · FILTER <Tn>`.
- Footer statuses (success in `text_primary`, refusals in `accent_danger`):
  `ACCEPTED · <Tn> · <LABEL>`; `CLAIMED · <Tn> · <LABEL> · +<n> CR · +2 STANDING`;
  `FAILED · <Tn> · <LABEL> · WINDOW CLOSED`; `ABANDONED · <Tn> · <LABEL>`;
  `REFUSED · NOT ENOUGH CREDITS · <n> NEEDED`; `REFUSED · NO BOUNTY DUE`;
  `REFUSED · CONTRACT SLOTS FULL · 3 / 3`; `REFUSED · LOCKED · CLEAN ONLY`;
  `REFUSED · LOCKED · STANDING -20 NEEDED`; `REFUSED · ALREADY ACCEPTED`;
  `REFUSED · CLAIM THE PAYOUT FIRST`; `REFUSED · NO POSTING SELECTED`.
- Default footer (no outcome, no status):
  `POSTINGS ROTATE PER BAND · WINDOWS RUN IN FLIGHT TIME`.
- Confirm overlays: `ACCEPT PURGE WARRANT?` / `<n> PIRATES IN <FACTION> SPACE ·
  <n> MIN PLAY WINDOW · PAYOUT <n> CR` / `CANCEL` + `ACCEPT`;
  `ABANDON CONTRACT?` / `PROGRESS <p> / <n> IS LOST · NO PAYOUT` / `CANCEL` +
  `ABANDON`; `PAY BOUNTY?` / `<n> CR CLEARS <h> HEAT WITH <FACTION> · HEAT GOES
  TO 0` / `CANCEL` + `PAY <n> CR`.

---

## 11. Conflicts with the reference docs

1. **Rail count.** The brief describes seven existing entries; STATION_HUB §10's
   shipped order also carries AUCTION (2026-09-22), i.e. eight entries today.
   This spec follows the brief (the eighth entry is BOUNTY BOARD) and §1.1 proves
   the fit for both counts (8 -> 147 px slack, 9 -> 85 px slack). If AUCTION
   ships, BOUNTY BOARD is the ninth entry at the same position (still before
   LAUNCH) and nothing else moves.
2. **Token hex drift.** UI_SPEC §1's theme tokens differ slightly from the 16
   colour hexes the brief makes law (e.g. `accent_danger` `#C8471F` vs Burnt
   Ember `#C8461B`, `text_dim` `#6B7484` vs Ash Text `#8D939B`). The brief's
   palette is law here; the coder pushes the tokens named in §10 and the theme
   owner reconciles the hexes.
3. **PAY BOUNTY surfaces.** 13 §7 places the `PAY BOUNTY (n CR)` row in LAUNCH.
   This module adds a second surface calling the same `pay_bounty(faction_id)`;
   the LAUNCH row and its tests do not move.
4. **Cockpit restyle.** UI_SPEC §3.9's analog instrument language binds
   cockpit-family surfaces (the ARMORY battery window got it by owner request).
   This module keeps the station's standard `PanelRaised` pane chrome, which is
   what the brief's panel law describes.
