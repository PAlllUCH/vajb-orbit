---
slice: D16
worker: D16-A1
model: "mimo-v2.6-pro (design session)"
status: actionable
gate: "n/a (design only — no gate row moves)"
---

# D16-A1 report — station identity & contracts UI design

## Result
The design law for S24/S25/S26 is landed: `STATION_HUB.md` §15 (the three service panels, the identity treatment, every presentation value) and `UI_SPEC.md` §7 (the A5.4 chrome extension, incl. the L263 SALVO drum row), plus four wireframe mockups. Every surface names its A5.4 row or proposes one and cites shipped chrome/Tokens; every wording carries a tick id + reversal. No gate row moves (design only — a row moving would be a defect).

## Acceptance list answers
- **A1** — CONTRACTS panel spec done: row anatomy (type icon+name / objective / reward / faction), `ACCEPT` + `CANCEL · 100 CR FEE` with the fee at both decision points, the escrow readout (`ESCROW — RESERVED FROM YOUR HOLD` + per-stack `… · RESERVED`), `ACTIVE CONTRACTS %d/3` + `MAX 3 ACTIVE`, Expedition greyed `STAGED` / `arenas arrive with S26` — `docs/design/STATION_HUB.md` §15.2, mockup `staging/mockup/d16_contracts_wireframe.md`, pin 14 §2:45-51.
- **A2** — insurance + vaults done: six premium rows verbatim (14 §3:60-67) with `UNINSURED` / `INSURED · COVERS ONE LOSS` / `PAID OUT · POLICY SPENT` and `MERCY AVAILABLE` / `MERCY USED` legible; tier rows 500 / 1 200 / 2 400 + Meridian's 40-unit +25 % note (14 §4:85-89); contents view carries the `NOT CARGO` chip + captions — `STATION_HUB.md` §15.3/§15.4, mockup `staging/mockup/d16_insurance_vaults_wireframe.md`.
- **A3** — identity treatment done: name plate (flat Tokens box + faction glyph 48 + `HeroTitle` name + character line) with per-faction accent = the faction's own glyph + metal-ramp border (Concord `metal_mid` / Meridian `metal_light` / Choir `metal_dark`, no new hue legal); all nine places mapped to R-S24-1's table; one worked plate per faction — `STATION_HUB.md` §15.5, mockup `staging/mockup/d16_identity_wireframe.md`.
- **A4** — the tick sheet below: W3's nine names ready-to-tick + every presentation value (U1–U18) with reversals; per-string detail at `STATION_HUB.md` §15.6.
- **A4b** — SALVO drum answers L263: four `ui_seg_*` cells 18×32 on the 20 pitch on the flat `ledge_bg` ledge, `0073`-style figures, `SALVO s` caption at its measured 78 px origin; own tick **U18**, reversal = L263's own; heavy-cadence icon **staged pending generation budget**; no code touched — `UI_SPEC.md` §7 A5.4-6, mockup `staging/mockup/d16_salvo_drum_wireframe.md`.
- **A5** — owner rulings + handoff below.

## The tick sheet (ready to tick; unticked ⇒ the PROPOSED value ships)

| Tick | Place | Name + character line (R-S24-1 verbatim) |
|---|---|---|
| W3 | S1 primary (Concord capital) | **Halcyon Anchorage** — forge-grey bastion, the full menu |
| W3 | S2 primary (Concord) | **Ironworks Depot** — mill-town market floor |
| W3 | S2 outpost | **Marchgate Post** — a dock and a vending wall |
| W3 | S3 primary (Meridian capital) | **Spanport Meridian** — the merchant's harbour, best contract rates |
| W3 | S4 primary (Meridian) | **Ashveil Exchange** — free-port chaos, component prices |
| W3 | S4 outpost | **Rimward Depot** — caravan stop |
| W3 | S5 primary (Choir) | **Cinder Gate** — incense and plasma scorch |
| W3 | S5 shrine (outpost) | **The First Ember** — the Choir's smallest rite |
| W3 | S6 primary (Choir capital) | **Emberlight** — cathedral dark, meanest turrets |

Reversal for any name: rename in the registry row (14's 2026-09-27 P3 block).

| Tick | Value(s) introduced (verbatim) | Reversal |
|---|---|---|
| U1 | `SERVICES` rail = entry 7 before LAUNCH + faction-glyph rail icon | LAUNCH keeps entry 7; `icon_map_node_station_48` |
| U2 | strip `CONTRACTS`/`INSURANCE`/`VAULTS`; grey reasons `the Choir does not believe in accidents` / `fly to a capital` | `BOARD`/`POLICY`/`STORAGE`; hide unavailable |
| U3 | `TYPE`/`OBJECTIVE`/`REWARD`/`FACTION`; `THE BOARD PAYS OVER THE EXCHANGE'S BUY PRICE — GOODS LOCK INTO ESCROW AT ACCEPT · CANCEL FEE 100 CR` | headers + note drop |
| U4 | `ACCEPT`; `CANCEL · 100 CR FEE`; `CANCEL THIS CONTRACT? — 100 CR FEE · THE RESERVED GOODS UNLOCK.` | `TAKE JOB`; fee in the confirm only |
| U5 | `ESCROW — RESERVED FROM YOUR HOLD`; `<qty>× <item> · RESERVED` | the `RESERVED` lines alone |
| U6 | `ACTIVE CONTRACTS %d/3`; `MAX 3 ACTIVE` | `%d ACTIVE CONTRACTS`; chip drops |
| U7 | `STAGED`; `arenas arrive with S26` | Expedition row hidden until S26 |
| U8 | `NO OPEN JOBS — NEW JOBS ROLL ON THE 20-MINUTE CLOCK`; `REDEMPTION MUST PRECEDE EMPLOYMENT` | silent empty board |
| U9 | `HULL CLASS`/`PREMIUM PER LAUNCH`; `YOUR CLASS`; `Champion standing multiplies the premium ×0.8` | pin's header casing; chips/notes drop |
| U10 | `UNINSURED`/`INSURED · COVERS ONE LOSS`/`PAID OUT · POLICY SPENT`; `THE PAYOUT COVERS ONE LOSS · THE POLICY DOES NOT RENEW MID-FLIGHT` | one `INSURED` chip |
| U11 | `MERCY AVAILABLE`/`MERCY USED`; `mercy clause: if you have no other hull, the Concord reissues a bare Fighter — once per profile` | no mercy readout |
| U12 | `UNINSURED LOSS: HULL AND ALL INSTALLED MODULES ARE GONE` | warning drops |
| U13 | `INSURE LAUNCHES`/`CANCEL POLICY`; `PREMIUM %d CR PER LAUNCH · CHARGED AT LAUNCH` | `INSURE`/`UNINSURE` |
| U14 | `TIER %d · +20 UNITS · %d CR`; totals `40/60/80` (**PROPOSED**); Meridian `625/1 500/3 000` (derived ×1.25) + the §4 Meridian line | totals `20/40/60`; base prices; note drops |
| U15 | `YOUR HOLD`; `VAULT CONTENTS`; `DEPOSIT`; `WITHDRAW`; `DEPOSITS AND WITHDRAWALS ARE FREE`; `NOT CARGO`; `VAULT CONTENTS DO NOT COUNT AGAINST CARGO ON LAUNCH`; `CONTENTS PERSIST PER-STATION — THE VAULT IS FURNITURE, NOT A POCKET` | one list; `STORE`/`TAKE`; captions drop |
| U16 | `THIS VAULT — %d / %d UNITS`; `tier 1 only — this is an outpost` | readout drops; tiers 2/3 hidden at outposts |
| U17 | name plate (flat Tokens box, faction glyph 48, name + character line); ramp borders `metal_mid`/`metal_light`/`metal_dark` | bare `StationMark` + `TitleBox`; `StationLocation` returns |
| U18 | SALVO drum four cells (`0073` figures, `SALVO s` caption) — `UI_SPEC.md` §7 A5.4-6 | `salvo_cells 3` + `SALVO_MAX 999` + pin rows back (L263) |

## Owner rulings implemented + handoff (A5)
Rulings: (1) the **A5 chrome law** (`UI_SPEC.md` §3.10 A5.1–A5.4: flat Tokens inside panes, `ui_panel_frame` only at pane scale, every surface on its A5.4 row); (2) the **2026-09-26 "look this clean" / "anchors and relative positioning"** rulings (rows are the AUCTION `Button` row verbatim; containers + anchors only, never coordinates); (3) **D13's approach B** where it carries over (landscape, nothing the decision needs hidden: board beside escrow, tiers above the hold/vault split; host-derived rects; 13 px ink floor; `slices/D13-armory-rework/D13-A0_report.md:12`); (4) shipped chrome only (owner 2026-09-27) — faction identity is glyph + ramp, never a new hue (UI_SPEC §1 one-accent rule).

Handoff (this report + `STATION_HUB.md` §15 + `UI_SPEC.md` §7 are the design law their briefs cite):
- **S24 (world identity):** the name plate, character line and faction accent for the nine places — `STATION_HUB.md` §15.5 + `d16_identity_wireframe.md`; ticks W3 (names) + U17.
- **S25 (contracts board):** the CONTRACTS panel whole — `STATION_HUB.md` §15.2 + `d16_contracts_wireframe.md` + `UI_SPEC.md` §7 A5.4-3/A5.4-4; ticks U3–U8; ships the greyed Expedition row (R-S25-1's seam) that **S26** flips live.
- **S26 (insurance, vaults):** both panels — `STATION_HUB.md` §15.3/§15.4 + `d16_insurance_vaults_wireframe.md` + A5.4-5; ticks U9–U16 (incl. the U14 unit reading).
- **Armory owner's eye (L263):** `UI_SPEC.md` §7 A5.4-6 + `d16_salvo_drum_wireframe.md`; tick U18 closes L263 at owner tick.

## Deviations from SLICE.md
- Mockups are wireframes (`.md`), not rendered plates — the wave is design-only (no render script is code). Reversal: a rendered pass at S24/S25's mockup stage on owner ask.
- 14 §4's "20 units base, +20 per upgrade tier" is ambiguous (totals 40/60/80 vs 20/40/60): proposed 40/60/80 with the reversal named, tick U14 decides (a pin number I cannot derive is never left to a coder).
- Outpost faction = the sector primary's faction (**PROPOSED** in §15.5's table; the pin states none); reversal: the registry names its own.
- The character line takes `StationLocation`'s slot, so the location string leaves the header (U17's reversal restores it).
- Service switching is a strip of three buttons (14 §1 pins panels under SERVICES but no mechanism) — presentation call, U2.
- Tick letter **U** taken fresh (W/J/E/K/T are S24/S25/S26/S27/armory).

## Evidence
- Law blocks: `docs/design/STATION_HUB.md` §15 (1318–1479), `docs/design/UI_SPEC.md` §7 (852–887); indexes refreshed by `python3 staging/docs_index.py docs/design/UI_SPEC.md docs/design/STATION_HUB.md` → "index written, 7 sections, 887 lines" / "15 sections, 1479 lines".
- Pins re-read verbatim: 14 §2:45-51, §3:57-80, §4:85-94, §8, P3 block :155-184 (R-S24-1 names, R-S25-1 seam).
- Chrome cites verified in `ASSET_CATALOG.md`: :293-297 contract icons, :332-334 insignia cuts, :391-393 service icons, :437 button plates, :444 panel frame (32 px band), :467 `ui_seg_*`; A5.1–A5.4 at `UI_SPEC.md:628/641/649/658`.
- L263 measured at `.agents/gen/_state/LOW_BACKLOG.md:836` (salvo_cells 4, SALVO_MAX 9999, caption 74→78, its own reversal).
- `git status --short`: only `docs/design/STATION_HUB.md`, `docs/design/UI_SPEC.md`, `staging/mockup/d16_*.md` and this slice folder — no code, no `docs/gameplay/`, no `CONTRACTS.md`.

## Files touched
- `docs/design/STATION_HUB.md` — §15 amendment (panels, identity, presentation values)
- `docs/design/UI_SPEC.md` — §7 amendment (A5.4 extension + A5.4-6 SALVO drum)
- `staging/mockup/d16_contracts_wireframe.md` — A1 mockup
- `staging/mockup/d16_insurance_vaults_wireframe.md` — A2 mockups + state variants
- `staging/mockup/d16_identity_wireframe.md` — A3: three faction plates + nine-place map
- `staging/mockup/d16_salvo_drum_wireframe.md` — A4b mockup
- `.agents/gen/slices/D16-station-ui/D16-A1_report.md` — this report

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| heavy-cadence ledge icon (≥10.00 s marker) staged pending generation budget | [DESIGN] | `UI_SPEC.md` §7 A5.4-6 |
| per-faction hue + per-station emblem family staged (Tokens amendment + budget) | [DESIGN] | `STATION_HUB.md` §15.5 |
| vault tier totals reading (40/60/80 vs 20/40/60) lands by tick U14 at S26's open | [DESIGN] | `STATION_HUB.md` §15.4 |

## Fixer note (2026-10-03, D16-F1 — cures for D16-R1's two MED findings)

Amendment-block edits only; F3/F4 (LOW) ride the next wave as `L267`/`L268` and stay untouched here.

- **F1 cured — U1 recomputed on the live rail** (`STATION_HUB.md` §15.1 rail row + §15.6 U1 row). The live rail is eight entries — `ui/screens/station.gd:67` (`enum Module`), labels `:80-87` ending LAUNCH eighth — not §3.1's seven-entry grid: SERVICES is entry **8**, LAUNCH becomes **9**, the post-change stack is 9×56 + 8×6 = **552 px** inside the 769 px rail content box (intent kept: SERVICES between REPAIRS and LAUNCH, inside the band). U1's reversal now names LAUNCH's real current entry — **LAUNCH keeps entry 8**, SERVICES appended below it — superseding this report's U1 tick row above ("entry 7", "LAUNCH keeps entry 7"); the older §2 grid table (`STATION_HUB.md:96`) stays the mockup-era record, outside this pass's edit surface.
- **F2 cured — A5.4-5's two new presentation values now carry their own tick ids + reversals** (`UI_SPEC.md` §7 A5.4-5; brief §4 rule 3). **U19** = the contents-list height `min (0, 200)`, reversal `min (0, 110)` (the shipped `CargoList` height, `STATION_HUB.md:358`); **U20** = the 24 px stack icon in `ItemList` rows, marked **PROPOSED** — the shipped `CargoList` is a plain-text list with no row icons (`STATION_HUB.md:358`, `:683`), so no cite carries it — reversal: plain-text `40× ingot_titanium` rows, no row icon. Both ride S26's contents view and are registered in `STATION_HUB.md` §15.6.

Corrected / added tick rows (owner ticks here; unticked ⇒ the PROPOSED value ships):

| Tick | Value | Reversal |
|---|---|---|
| U1 (corrected) | `SERVICES` rail = entry 8 before LAUNCH (LAUNCH becomes 9; stack 552 px) + faction-glyph rail icon | LAUNCH keeps entry 8, SERVICES appended below it; `icon_map_node_station_48` |
| U19 | contents lists `min (0, 200)` (`UI_SPEC.md` §7 A5.4-5) | `min (0, 110)` (the shipped `CargoList` height, `STATION_HUB.md:358`) |
| U20 | 24 px stack icon in `ItemList` rows (**PROPOSED**) | plain-text `40× ingot_titanium` rows, no row icon (`STATION_HUB.md:683`) |

Section indexes refreshed (`python3 staging/docs_index.py docs/design/UI_SPEC.md docs/design/STATION_HUB.md`): UI_SPEC already current (single-line edit); STATION_HUB rewritten — 15 sections, 1481 lines (§15.6's two rows). No code, no `docs/gameplay/`, no `CONTRACTS.md` touched.
