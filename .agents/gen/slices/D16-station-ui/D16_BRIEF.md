# D16 — Station identity & contracts UI design (wave brief)

**Wave:** D16 (design lane, item 17 of `dispatch_designer.md`)
**Slice folder:** `.agents/gen/slices/D16-station-ui/`
**Owner go (2026-09-27):** pillars D + B ("world identity … contracts board")
need one design language before the coder waves (S24/S25/S26) build panels.
**Design only: no code, no game docs.** Runs after S23 and before S24.

## 1. The law to read, in order
1. `slices/D16-station-ui/SLICE.md` — scope, file sets.
2. `docs/design/UI_SPEC.md` §3.10 **Amendment 5** (A5.1–A5.3) — the composition
  law every panel obeys (verbatim below).
3. `docs/gameplay/14_station_services.md` §1–§4/§8 (read-only — the panel
  content pin) + its 2026-09-27 P3 block (R-S24-1's names, R-S25-1).
4. `docs/design/STATION_HUB.md` + `ASSET_CATALOG.md` (chrome inventory) by range.
5. The §5 spec extract.

## 2. The owner's request (verbatim)
> "right now the fundamentals are there, it needs a bit of playtesting and a lot
> of new content as right now there isnt much … i want to focus on content,
> bugfixes, playability and feel" (2026-09-27). Pillar D as ticked: "Per-station
> stock/services/identity … Makes sectors feel distinct"; the owner's standing
> UI ruling (2026-09-26): *"i want all to look this clean"*, *"we always should
> use anchors and relative positioning"*.

## 3. What is already measured (file:line)
| Fact | Site |
|---|---|
| the nine places' names + characters are proposed, awaiting tick W3 | `docs/gameplay/14_station_services.md` **2026-09-27 P3 block** |
| the service matrix is pinned per faction/outpost | 14 §1/§8 |
| the contracts content is pinned (types, rewards, escrow, gates) | 14 §2 (+R-S25-1) |
| insurance premiums + flows are pinned | 14 §3 |
| vault tiers/behaviour are pinned | 14 §4 |
| the panel row idiom (rows over plates) is proven | `ui/station/auction_panel.gd`, UI_SPEC §3.10 A5.3 |
| the armory's chrome law is settled (A5) | `docs/design/UI_SPEC.md` §3.10 Amendment 5 |
| no per-station visual identity exists today | `game/station_scene.gd:128` (visual layer, no identity) |

## 4. Pinned interface + rules
UI_SPEC §3.10 Amendment 5 (the law):
> "**A5.2 Composition law (the owner's rule, as mechanism).** (i) Layout is containers + anchors + `custom_minimum_size` + size flags — never coordinates; (ii) a surface's chrome is a theme stylebox or a sibling node, never a `_draw` pass over content; (iii) a code-drawn mark draws **within its own child rect**, anchored to it; (iv) chrome that carries a visual band also sets the `content_margin_*` that keeps content off it. A worker who needs coordinates for anything that must sit inside art is out of contract."
> "**A5.1 Chrome is chosen by the asset's own cut size — and inside a pane it is flat.** … the flat Tokens language — `StyleBoxFlat`, 1 px `metal_mid` border …"

Rules:
1. **Design only** (deliverables = spec blocks + mockups + tick sheets; S24/
  S25/S26 implement and cite this report).
2. **Shipped chrome only** (owner 2026-09-27): every proposed surface names the
  exact asset/idiom from `ASSET_CATALOG.md` or the theme Tokens; a new render is
  out of contract.
3. **Every new presentation value carries its reversal + tick id** (copy
  strings count: a label wording is a value).
4. **Content follows the pin**: the panels show 14 §1–§4/§8's content exactly —
  no invented service, price or reward line.

## 5. Spec extract (verbatim, cited)
`docs/gameplay/14_station_services.md` §1 (the matrix the CONTRACTS column sits in):
> "| Contracts board | ✔ | ✔ (best rates) | ✔ | … | Insurance | ✔ (cheapest) | ✔ | ✖ (the Choir does not believe in accidents) | … | Boss arena contract | ✖ | ✔ (expedition desk) | ✔ (rite of the Choir) |"

`14_station_services.md` §2 (escrow + cancel the panel must show):
> "the board pays *over* the exchange's buy price (that's the point) but locks the goods at accept-time (escrow: quantity reserved from the manifest, removable by cancelling for a 100 CR fee)."

`14_station_services.md` §3 (the insurance readout):
> "**One-death rule:** the payout covers one loss; the policy does not renew mid-flight."
> "(The starter Lancer is never fully losable: if you have no other hull, the Concord reissues a bare Fighter — mercy clause, once per profile.)"

`14_station_services.md` §4 (the vault rows):
> "**one vault per station, 20 units base, +20 per upgrade tier** (tiers 1–3: 500 / 1 200 / 2 400 CR one-off per station) … contents persist per-station … Vault contents do **not** count against cargo on launch."

`docs/design/UI_SPEC.md` §3.10 A5.1–A5.3 (quoted in §4 above — the full
amendment is the composition law).

## 6. Acceptance list (numbered)
- **A1 (CONTRACTS panel):** the board spec — row anatomy (type, objective,
  reward incl. the over-exchange note, faction), accept/cancel with the 100 CR
  fee visible at the decision point, the escrow readout (reserved quantities),
  the max-3 state, and Expedition greyed as "arenas arrive with S26" — all
  under A5.1/A5.2, with a mockup.
- **A2 (insurance + vaults panels):** the §3 premium row per class with the
  one-death and mercy-clause states legible; the §4 vault tier rows (500/1 200/
  2 400, Meridian's 40-unit +25 % note) and a contents view (deposit/withdraw)
  that says "not cargo" — mockups included.
- **A3 (station identity):** the treatment for the nine places (name plate +
  character line + any per-faction accent from existing chrome/Tokens only),
  mapped to R-S24-1's table, with one worked example per faction (Concord/
  Meridian/Choir) in mockup.
- **A4 (tick sheet):** R-S24-1's nine names presented ready-to-tick (tick W3)
  plus any presentation values introduced (labels, wordings) with reversals.
- **A5 (handoff):** the report names the owner rulings implemented (the A5
  chrome law, D13's approach B where it carries over, the 2026-09-26 "look
  this clean" / "anchors and relative positioning" rulings) and states each
  panel's handoff to S25/S26 as the design law their briefs cite.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| D16-A1 | designer | `docs/design/, staging/mockup/, .agents/gen/slices/D16-station-ui/` | `D16-A1_report.md` + mockups |
| D16-R1 | design reviewer | `docs/design/, .agents/gen/slices/D16-station-ui/D16-R1_review.md` | `D16-R1_review.md` |

## 8. Run order + tests
**A1 → R1.** No gate rows move (design only — a row moving is a defect).

## 9. Hard rules
- `docs/gameplay/*`, `docs/CONTRACTS.md`, `docs/archive/`, all code: untouchable.
  `docs/design/` writes are amendment blocks appended by heading only.
- No AI art (owner 2026-09-27); every surface names a shipped asset/idiom with
  its `ASSET_CATALOG.md` cite. Evidence cites on every row.

## 10. Staged / deferred
- Faction vendor screens (12 §5's exclusives retail) and the D14 armory
  questions stay with their slices; a per-station emblem family would need
  generation budget (out).

## 11. Owner tick list
A4's table is the tick sheet (W3's nine names + presentation values).

## 12. Close-out (the orchestrator)
1. Owner ticks the names; the developer lands them in 14's P3 block at S24's
   open (docs-first).
2. `python3 staging/verify_wave.py verify --baseline d16_start` (design-only
   diff surface), WAVEBOARD + `dispatch_designer.md` one-liners,
   `MASTER_REPORT.md` §6 recap, wave-boundary commit.
