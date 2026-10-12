# TICKS — the one file (live only)

Every open owner decision and every open action in one screen. **Rows leave this
file when decided or done** (deleted at the wave close-out or the ruling — the
record lives in the cited file and `MASTER_REPORT.md` §6, this is the index
only). Refreshed at every wave close-out and after every owner ruling.

*Last refreshed: 2026-10-12 (phase-prep close — the developer session, housekeeping
not a wave: gate **1330/0 ×2 hermetic**, **T-183 closed** via `staging/gate.py` (the
SCRIPT ERROR guard), the 2026-10-08 clear-out landed in git, and **playtest build 2
delivered** at `builds/vajb-orbit-0.4-2026-10-12-d77aba6-{linux,windows}/` — v0.4,
Linux smoke-tested, Windows verified structurally; `19_testing_notes.md`'s 2026-10-12
amendment is the build-2 eye list. P3's remaining work is the owner's alone; the next
code work follows a fresh P4 planning round. Every open decision below is unchanged
and still waiting.)*
*Previously 2026-10-11 (S41 the composition pass closed — the design audit D23
implemented. Gate **1300 → 1330/0** ×2 hermetic on fresh scratch stores; five
builders (B1–B4 parallel, B5 the completion pass), R1 (glm-5.3-flash, code **and**
visual) returned **passed-with-followups** — all 16 findings plus **T-177** fixed
at their named sites and **visible on the ten fresh renders**. **T-177 closed**
(the theme generator preserves the `.tres` uids; a regeneration is a byte no-op).
**T-180/T-181/T-182 + T-183 filed**; next free **T-184**. Every new token is
**PROPOSED** (below). One owner call rides the wave: the OVERVIEW tradeoff.)*
*Previously 2026-10-10 (S27 catalog breadth & the shipyard closed — P3's last
code item. Gate **1275 → 1300/0** ×2 hermetic on fresh scratch stores; CONTRACTS
**§20 S27 block** + §9 + §10 **v0.56/v0.57**; B1+B2 built, R1 left **no HIGH**,
2 MED (both cured by F1), 1 LOW → **T-178**; **T-153 closed** (the tier-4 reserved
slot). Ticks **K1** (15 `<base>_mk2` variants, +15 %/step), **K2** (the seven
R-S27-2 rows, incl. `PYRE_RING_RADIUS` 240.0) and **K3** (every suffix perk live at
its flight seam) shipped at their PROPOSED values and were not separately ruled —
they now live in `CONTRACTS.md` §20 and `15`/`09`'s P3 blocks. A post-fix
verification review (**S27-R2**, glm-5.3-flash) returned **clean** — no HIGH, no
MED — and filed **T-179** (the Pyre ring can chain-detonate through its own kills;
an owner ruling on interaction density). Next free ticket **T-180**. The queue is
now **P3's exit** (playtest build 2); the playtest pass #1
row below stays open — the owner's own eye is still the phase's exit criterion)*
*Previously 2026-10-10 (S40 legibility — the owner's visibility review of the
station decks. Gate **1267 → 1275/0** ×2 hermetic; UI_SPEC **§16**; the measured
below-AA share across the eight decks **241/607 (39.7 %) → 34/610 (5.6 %)**;
**T-171/T-172/T-173 filed and closed in S40**, **T-174/T-175/T-176 filed open**
(the launch briefing column, the four header-caption surfaces, the staged row's
1.61:1), **T-177 filed** (the theme generator drops the `.tres` uids); next free
**T-178**. The queue is now **S27**, then the rest of P3. The playtest pass #1 row
below stays open — the owner's own eye is still the phase's exit criterion)*
*Previously 2026-10-10 (S39 flight feel, hostile fire and cargo — the owner's
second playtest. Gate **1258 → 1267/0** ×2 hermetic; CONTRACTS **§29** + §10
**v0.55**; **T-164–T-170 filed and closed in S39**. Every new number is
**PROPOSED** with its reversal in §29 and awaits the owner's fold-in to the
owner-locked `18_engine_spec.md`)*
*Previously 2026-10-10 (S26 endgame closed — gate 1237 → **1258/0**, CONTRACTS
**§28** + §10 **v0.54**, 1 HIGH + 4 MED cured by the fixer, **T-161/T-162/T-163**
filed, next free **T-164**. **Ticks E1/E2 shipped at their PROPOSED values and
were not separately ruled** — E1 (the three boss hull rows, 08's P3 block) and E2
(the Maw's roam rows) now live in `CONTRACTS.md` §28 and `14`'s §5 block. The
queue is now **S27 alone**. The playtest pass #1 row below stays open — the
owner's own eye is still the phase's exit criterion)*
*Previously 2026-10-09 (the owner's playtest — its first finding, "there are no
contracts available", is fixed: the service host never gave the CONTRACTS pane
the deck's height, so the board's scroll collapsed to 2 px and drew no rows. Gate
1236 → 1237/0, CONTRACTS §10 v0.52, **T-160** filed and closed. This was one eye,
not the pass)*
*Previously 2026-10-08 (S38 board clock + hub cold start closed — gate
1236/0, CONTRACTS §27 + §10 v0.50/v0.51, T-156/T-157 closed, 1 MED cured by the
fixer, 2 LOW → T-158/T-159. **Ticks H1/H2/H3 shipped at their PROPOSED values
and were not separately ruled** — H1 (the cold-start place), H2 (the countdown)
and H3 (the re-roll) now live in `docs/gameplay/14_station_services.md`'s
2026-10-08 S38 block and `CONTRACTS.md` §27. The queue runs S26 → S27; S26's
E1/E2 land with its wave. Earlier retired rows are in
`_archive/ticks_rows_retired_2026-10-07.md`; a fresh design round regenerates the
plan)*

## Waiting on the owner

- **The caption tone (S40, brief §10 T1).** `text_caption` `#acb2ba` /
  `text_caption_void` `#969da5` are **PROPOSED** in `docs/design/UI_SPEC.md` §16.1
  A1 and shipped: the shared `SectionHeader` / `StationCaption` / `FlavourText`
  variations moved off `text_dim` onto them (measured 6.15–6.77:1 where
  `text_dim` read 2.85–2.96:1). Ratify or re-cut the tone. Reversal: `text_dim`
  on the three variations.
- **Four pinned-idiom legibility sites (S40, brief §10 T2).** Recorded in
  `.agents/gen/slices/S40-legibility/S40_REVIEW.md` "After": the AUCTION family-tab
  ink (9 labels, 3.47:1, the theme's `font_unselected_color`), the SHIPYARD
  comparison rows (18, 4.08:1 = §1's documented ≈4.0:1 floor), the SHIPYARD
  `NOMINAL` reads (3, P13 pins `text_dim`), the SERVICES board note + roll
  countdown (2, `contracts_panel.gd:677,681`). Each cure is one line; each
  supersedes a pinned idiom, so it is the owner's call. **T-174/T-175/T-176**
  carry the surface-level ones.
- **The shipyard's build band post-S28 (S27, T-178).** Change 02's 2026-10-08 ore
  values moved under 10 §3.1's untouched material rows, so the nine hull builds
  now re-derive at **47.7–59.1 %** of auction list (materials 15.2–19.3 %), under
  the doc's own "materials ≈ 20–30 % … a build totals ≈ 55–70 %" band. Play-safe
  (building still saves), but the doc band is false on the live ladder. 10 §4
  names the lever (labour %, never the frozen list prices, never the ore table);
  needs an owner-ticked amendment. Reversal: none (drift, not a code defect).
- **The Pyre ring's own-kill cascade (S27, T-179).** A ring kill is itself a
  below-quarter kill, so in a dense spawn one Pyre kill can chain-detonate rings
  from each new victim's position (it terminates — dead hulls do not refire and
  each victim is excluded from its own ring — but N kills can pay N × 50 across
  the group). 15 §4's literal text already says a below-quarter kill detonates
  its ring, so this is a ruling on **interaction density**, not a code defect:
  ratify the cascade or gate the ring on the killing blow's source (player shots
  only). Code stays as shipped until ruled.
- **The OVERVIEW tradeoff (S41, B2/F01).** The HIGH fix moved the services block
  (CONTRACTS · INSURANCE · VAULTS) **out of the scroll** so all three deep-link
  rows are visible unscrolled — the deck's navigation promise (P26) now holds. The
  cost: the hull block (hull/shield readouts and the pane's only REPAIR chip) moved
  **below the fold** inside `%BlockScroll`, so it needs a scroll. Both P22 and P26
  are satisfied; which one the owner would rather lead with is a taste call.
  Reversal: the services rows return to `%BlockStack` (`overview_panel.gd`).
- **S41's new chrome tokens (all PROPOSED; the owner ratifies shared-chrome
  tones).** F7 gave every disabled plate a 1 px `metal_mid` edge
  (`DISABLED_EDGE`, `build_theme.gd:133`); F9 moved the scrollbar grabber to
  `text_meta` and gave the track a `metal_dark` edge with a new
  `SCROLL_GRABBER_MIN_HEIGHT` 48 px floor (`:137`); F16 pinned
  `HEADER_BAND_BOTTOM` 163 px (`ui/components/tooltip.gd:25`); F10 pinned
  `PREVIEW_FRACTION` 0.60 (`shipyard_panel.gd:104`) and F15 set the four shipyard
  mode plates to the chip row's 32 px / 18 px ink. **No colour value changed** —
  every token is an existing one reused, so no contrast re-measurement is owed.
  Reversals are in `S41-B1_report.md` and `S41-B4_report.md`.

## Open actions — no decision needed, just waiting

- **Playtest pass (build 2) — the owner's own eye over the delivered build:** the
  2026-10-12 eye list in `docs/gameplay/19_testing_notes.md` (B2-1/B2-2, everything
  P3 shipped after 0.3, the S41 composition, the menu keyboard row), plus the
  ALREADY-KNOWN table in the build's README (the tester template). The build is
  `builds/vajb-orbit-0.4-2026-10-12-d77aba6-{linux,windows}/` (v0.4, gate 1330/0 ×2
  hermetic, Linux smoke-tested). This pass is P3's exit criterion.
