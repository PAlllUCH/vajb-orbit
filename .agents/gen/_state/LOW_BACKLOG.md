# LOW backlog — findings that ride with the next wave

This file is `.agents/gen/_state/LOW_BACKLOG.md` under the folder law
(`AGENTS.md` §Slice / folder law) — the single list of open items; reports and
reviews are history.

Tiering per the WAVEBOARD: **HIGH blocks the wave**, **MED gets one fixer pass**,
**LOW lands here and rides with the next wave**.

**2026-10-07 (owner prune):** the workspace keeps only S36, S24, S25, S26,
S27. Every earlier row — the L1–L268 engine/UI/asset records with their
section intros — moved verbatim to
`_archive/low_backlog_open_rows_retired_2026-10-07.md`; the 41 explicitly
CLOSED rows are in `_archive/low_backlog_closed_rows_2026-10-07.md`; closed
slice folders live in `_archive/slices/`. Repro paths in retired rows are
historical; the finding text is self-contained. **The next free ticket is
T-148.**

Legend: **[DOC]** = a docs pass, **[SPEC]** = needs the owner's spec lock,
**[CODE]** = a code change when someone owns the file, **[HARNESS]** = agent
tooling, **[TOOL]** = a shipped repo tool/script.

**Tickets:** new items take the next global `T-###` (next free **T-152**) and
follow `_templates/TICKET.md` — one row here is the index; skip a detail file
when the row says it all.

**Closure protocol:** when an item closes, record it in its Disposition as
`CLOSED in <slice/wave>` with the evidence pointer — never delete the row. A
carried-over item (e.g. `L26` = `L11`) closes in **both** rows. A brief
referenced by an open row survives until the row closes.

| # | Item | Kind | Where | Disposition |
|---|------|------|-------|-------------|
| T-136 | **LOW (D22-P1/F04): seven empty layout containers report zero-size visible rects** (OVERVIEW `PaneActions`, HUD `PromptBlock`/`CreditsSpacer`, EXCHANGE `BoardRows/Slack`, SHIPYARD `StatsSpacer`/`ShipList/Slack`, `settings_rebind_row` `Spacer`) — empty spacers, polish only. | [UI] | `ui/**/*.tscn` | Hide the spacers at the S36 re-skin touch. Reversal: leave (they render nothing). |
| T-137 | **LOW (D22-P1/F05): `menu_button`'s Glow underlay extends 6 px past its plate** (measured −6,−6,362×82) — the pinned halo look (`glow_underlay.gd`). | [UI] | `ui/components/menu_button.tscn` | Keep (informational) or inset the halo 6 px at S36. Reversal: inset. |
| T-141 | **LOW (D21-G2-R1/L1): the uniform-band metric needs calibration** — the shipped-art controls fail byte-identity too (5.25–9.10 p95 vs the builder's ≤ 8 line), so the C11/C12 "grain-level marginal" reads are metric noise, not cut defects. | [HARNESS] | the band QC metric | Calibrate the p95 band metric against the shipped controls at S36's census suite. Reversal: drop the metric, keep visual QC. |
| T-138 | **SERVICES deck placeholder:** the deck ships a `MODULE OFFLINE` placeholder until the contracts/insurance/vaults strip (D22-P1/F03). | [UI] | `ui/screens/station.gd` (SERVICES deck) | Rider on S25 (the contracts wave); the fresh design round re-derives it. Reversal: keep the placeholder. |
| T-144 | **LOW (S36-F1/F2): the four REFINERY queue bars (114–176 px wide) sit under C2's 272 floor** — reverted to native `StationButton` at the F1 pass; `S36-F1_report.md` A4 table. | [UI] | `ui/station/refinery_panel.gd:156-165` | New-plate candidate; re-derive at the fresh design round. Reversal: wear C2 with the guard clamping (illegal stretch — do not). |
| T-145 | **LOW (S36-F1/F3): the ARMORY rack bay rows measure 876×116 — outside every class band** (C4 caps at 84 tall; C5 is the fixed 260×192 card); §15.1's 260×192 measurement is stale for these rows. Reverted to the flat Tokens plate. | [UI] | `ui/station/armory_panel.gd:783-796`, `UI_SPEC.md` §15.1 | Wide-strip class (or re-measure) at the fresh design round. Reversal: none — the flat plate stands. |
| T-146 | **LOW (S36-F1/F5): the SHIPYARD cluster inspect chip measures 452×32 — over C3's 160 ceiling** — reverted to native `Button`. | [UI] | `ui/station/shipyard_panel.gd:798` | New-plate candidate; re-derive at the fresh design round. Reversal: wear C3 with the guard clamping (illegal stretch — do not). |
| T-147 | **LOW (S36-F1): the 32 px inline chips' C3 bevel sums to the chip height** (t+b = 32; the guard clamps, b 20→16) — the C3 cut's margins leave no centre band at the shipped chip size. | [UI] | `ui/theme/chrome_family.gd` guard, `UI_SPEC.md` §15.3 C3 | **CLOSED in S37** — the replacement C3 cut's margins are 9/11 (t+b = 20 < 32), so the clamp never fires; `S37-B2_report.md`. Reversal: none — the clamp is the cure. |
| T-148 | **MED (S37-B2/F1): the C4 row content spans 92–97 % of its slot** — content +10 % (the owner's pad) exceeds the slot itself on 87 rows (AUCTION 1756 slot / need 1878; ARMORY browser 864/897; EXCHANGE 784/793; REFINERY 686/701). The chrome is now correct; the row content needs right-sizing. | [UI] | `auction/overview/exchange/refinery/shipyard/armory_panel.gd` row builders | Right-size the row content (or inset it) so content +10 % fits the slot; S37-F1 found per-node `font_size` overrides redden HIGH-1, so inset the content instead. Reversal: none — the overlap stands. |
| T-149 | **LOW (S37-B2/F2): the C12 `ui_panel_frame` shell frames' content exceeds the frame band** — ModuleHost 1872×860 (band 1808×796, need 1945×871), the drawer plate, the SHIPYARD preview frame. Pre-existing (the frame's theme margins inset the content). | [UI] | `ui/theme/vajb_theme.tres` (`ui_panel_frame` boxes) | Re-measure the frame margins or contain the shell content; re-derive at the fresh design round. Reversal: none. |
| T-150 | **LOW (S37-B2/F3): the C7 tooltip text rides over its side caps** (band 327×148, need 396×80; cm l/r = 0) — N47 pins the label at 360, so it cannot shrink to seat inside the caps. | [UI] | `ui/components/tooltip.gd:38`, `chrome_family.gd` C7 | Seat the text inside the caps without moving N47's 360 label (a wider cap band or a scaled inset). Reversal: none. |
| T-151 | **LOW (S37-B2/F4): the REFINERY `UpgradeButton` measures 187 px — under C2's 272 floor** (content +10 % 196.9 > slot 187), so it wears the legacy plate. | [UI] | `ui/station/refinery_panel.gd` (UpgradeButton) | New-plate candidate or widen the button; re-derive at the fresh design round. Reversal: none. |
