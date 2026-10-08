# Dispatch done sections retired 2026-10-08 (owner clear-out)

Extracted verbatim from `.agents/gen/dispatch_coder.md` and
`.agents/gen/dispatch_designer.md` at the 2026-10-08 clear-out, which left both
queues holding only S24–S27 (coder items 30–33). Earlier done rows live in
`dispatch_coder_done_2026-10-07.md` / `dispatch_designer_done_2026-10-07.md`;
the wave recaps are in `MASTER_REPORT.md` §6.

## dispatch_coder.md — the closed S36 row

| # | Wave | Item | What | Status |
|---|---|---|---|---|
| 43 | S36 | Chrome re-skin | The family wired: `StyleBoxTexture` per class + BG-1..4, keep-list untouched, the chrome-census regression suite. Five-piece: `slices/S36-chrome-reskin/`. | **done 2026-10-07** — B1 → R1 (blocked: 1 HIGH/4 MED/4 LOW) → F1 cured the review (drawn-space margins + guard, A4 reverts, tooltip inset; F1c fixed B1's lrtb order, designer-ratified); census 13 rows; gate **1151/0 ×2**; wave-boundary commit landed; T-144–T-147 filed. |

## dispatch_coder.md — the Done section

Items 1–43 closed (gate 437 → 1151/0 through the waves). Detail:
`_archive/dispatch_coder_done_2026-10-07.md` and `MASTER_REPORT.md` §6.

## dispatch_designer.md — the closed queue note

(empty — no live design item. **Owner 2026-10-07:** a fresh design round
regenerates the planning; this queue refills from it. The chrome family's
design law D21 closed 2026-10-06; its implementation runs as coder item 43 /
S36.)

## dispatch_designer.md — the Done section

Items 1–20 closed (D2 icon unification through D22 screen integrity; the D8/D12
fix waves ditched or absorbed). Detail: `_archive/dispatch_designer_done_2026-10-07.md`
and `MASTER_REPORT.md` §6.

## dispatch_coder.md — the closed S24 row (world identity, closed 2026-10-08)

Extracted verbatim from the live queue at the S24 close-out; the slice folder
now lives in `_archive/slices/S24-world-identity/`.

| # | Wave | Item | What | Status |
|---|---|---|---|---|
| 30 | S24 | World identity | Named stations + per-faction menus/flavours, standing band effects, per-sector hostile bands, nebula clouds (L-band-split). Five-piece: `slices/S24-world-identity/`; pins R-S24-1..3 (14/13/11 P3 blocks, ticks W1–W3) + the new mechanism pins V1–V8 (12/14/13/11's 2026-10-08 blocks). | **next — brief re-cut 2026-10-08** against the shipped shell (S30–S37) and re-measured: baseline 1152/0, **two sequential builders** (B1 = the station entity/identity/prices A1–A2, B2 = bands/standing/auction/nebula A3–A5) then R1, then F1 only on HIGH/MED. Dispatch from `S24_prompts.md` |
