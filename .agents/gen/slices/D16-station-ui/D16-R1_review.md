---
slice: D16
reviewer: D16-R1
verdict: passed-with-followups
gate: "n/a (design only — no gate row moves; none moved)"
---

# D16-R1 review

## Acceptance list
Graded against the brief's §5 extract and UI_SPEC §3.10 A5.1–A5.3, never against A1's report.

- **A1** — **pass** — §15.2 + `d16_contracts_wireframe.md`: row anatomy, fee at both decision points, escrow readout, max-3 chip, Expedition `STAGED`. Every content line traces to 14 §2 (:28–51) verbatim — no invented service, price or reward; the one derived line (`NO ESCROW` on hunts/escorts, wireframe #6) is a sound inference of the escrow rule and carries U5 + a reversal.
- **A2** — **pass** — §15.3/§15.4 + `d16_insurance_vaults_wireframe.md`: six premiums verbatim (14 §3:60–67, checked figure by figure), one-death + mercy legible (U10/U11), tiers 500/1 200/2 400 + Meridian's 625/1 500/3 000 marked **derived**, `NOT CARGO` chip (U15/U16). U14's ambiguous totals (40/60/80 vs 20/40/60) written **PROPOSED** with reversal + tick — the lawful route.
- **A3** — **pass** — §15.5 + `d16_identity_wireframe.md`: all nine places mapped to R-S24-1 verbatim, one worked plate per faction (Concord/Meridian/Choir), accent = faction glyph + metal-ramp border only; no new hue (UI_SPEC §1's one-accent rule verified, `accent_nav` needle-only).
- **A4** — **pass** — tick sheet: nine W3 names ready-to-tick + U1–U18; every row carries a value, a reversal and a tick id.
- **A4b** — **pass** — UI_SPEC §7 A5.4-6 answers L263 with a value (four-cell drum), L263's own reversal, tick U18, and proposes no render (heavy-cadence icon STAGED, "never generate it"); L263's facts (74→78 caption, SALVO_MAX 9999) re-verified in code.
- **A5** — **pass** — all four named rulings are implemented by the text: A5.1–A5.4 rows cited on every surface; AUCTION `Button` row + containers/anchors throughout; D13 approach B verified (`D13-A0_report.md:12` says "approach B"); shipped chrome only — every `ASSET_CATALOG.md` cite spot-checked (:293-297, :332-334, :391, :437, :444, :467 all true).

## Judgements the dispatch asked for
- **Mockup form (markdown wireframes in `staging/mockup/`)** — **lawful.** Brief §4 pins "spec blocks + mockups + tick sheets" with no format; the wave is design-only (a render script would be code), AI art is owner-barred (2026-09-27) and no generation budget exists; `staging/mockup/` sits inside A1's `VAJB_WORKER_FILES`. Wireframes carry their own "sizes schematic" disclaimer; ruled numbers live in the law blocks.
- **UI_SPEC §7 as amendment site** — **lawful.** Appended as a new dated heading at EOF; the diff touches only the generated section index plus the appended block; §3.10's A5.4 table is untouched and A5.4-6 declares its amendment of the `Salvo ledge` row rather than editing it in place. STATION_HUB §15 identical (heading-only append at 1314+).
- **File surface** — clean: `git status --short` shows only `STATION_HUB.md`, `UI_SPEC.md`, the four `d16_*` mockups and the slice folder. Untracked `staging/compare/` (BOUNTY BOARD task + glm/mimo outputs) is outside every D16 file set and predates this review — orchestrator model-comparison leftovers, not counted against A1; hand back to the orchestrator.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| D16-A1/F1 | MED | `STATION_HUB.md` §15.1 rail row (:1358) | U1 is built on §3.1's stale seven-entry grid: the live rail is `station.gd:79-85` — ARMORY/REFINERY/EXCHANGE/AUCTION/SHIPYARD/FITTING/REPAIRS/LAUNCH, **8** entries, LAUNCH is 8 today — so SERVICES is entry 8 (not 7), LAUNCH becomes 9 (not 8), the post-change stack is 9×56+8×6 = **552 px** (not 490), and U1's reversal "LAUNCH keeps entry 7" names an entry LAUNCH does not hold. The intent (SERVICES between REPAIRS and LAUNCH, still inside 769) survives; the numbers ship wrong into the law S25 cites. | designer (amendment block) |
| D16-A1/F2 | MED | `UI_SPEC.md` §7 A5.4-5 (:872) | New presentation values with no tick id or reversal — brief §4 rule 3: `min (0, 200)` list height and a 24 px stack icon in ItemList rows; the row cites §3.1's `CargoList` idiom, but the shipped CargoList is a plain-text list with no row icons (`STATION_HUB.md`:358, :683), so both the height and the icon are new. | designer (amendment block) |
| D16-A1/F3 | LOW | `UI_SPEC.md` §7 A5.4-6; report §Evidence | Cite drift on the code the row measures: `salvo_cells` is at `armory_style.gd:97` (not :95), and the caption's "measured origin 78" is the derived `maxf(block, salvo_caption_left=74)` (`armory_style.gd:284-286`, :101) — recording 78 flat invites a coder to pin it, which would break L263's 74-reversal at `salvo_cells 3`. | → ticketed as `L267`, not fixed here |
| D16-A1/F4 | LOW | `STATION_HUB.md` §15.2 board row (:1372) | "icons 24 at their own cut" is unsatisfiable: the shipped chrome is 96 px SVG masters (`icon_contract_*`, ASSET_CATALOG.md:293-297) and 16/48/96/192 insignia cuts (:332-334) — no 24 cut exists, so every 24 px use is a scale of a master, not "its own cut" (A5.1's cut-size law reads the rule, not the raster). | → ticketed as `L268`, not fixed here |

Tiering per WAVEBOARD: 0 HIGH (no invented content, no render proposal, no coordinates-only layout — A5.2's four clauses are restated as mechanism in both law blocks and no deliverable layout uses coordinates), 2 MED (one fixer pass), 2 LOW (L267/L268 in `LOW_BACKLOG.md`).

## Verified fixes
None yet — no fixer dispatched; F1/F2 go to the designer session as amendment blocks (docs-design writes are never the reviewer's).

## Gate
Design-only wave: no gate run, no row moved (negative control: `git status --short` + `git diff --stat` — 2 modified files, both permitted docs; `14_station_services.md`, `CONTRACTS.md`, code: untouched).
