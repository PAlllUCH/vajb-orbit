# TICKS — the one file (live only)

Every open owner decision and every open action in one screen. **Rows leave this
file when decided or done** (deleted at the wave close-out or the ruling — the
record lives in the cited file and `MASTER_REPORT.md` §6, this is the index
only). Refreshed at every wave close-out and after every owner ruling.

*Last refreshed: 2026-10-05 (the owner's playtest round + the chrome-family
ruling — D21/S33/S34 five-pieces queued and live)*

## Waiting on the owner

| ID | The call | Where | Default if silent |
|---|---|---|---|
| T-131 | Chrome family: unique station backgrounds — PROPOSED 4 backdrops assigned across the 7 station panes | `docs/design/UI_SPEC.md` §15 + `UI_CHROME_ASSETS_SPEC.md` (lands in D21) | 4 as proposed |
| T-132 | Armory note-2 reading: "left with overwiev we have not" = the overview we have now stays left | `docs/design/STATION_HUB.md` §21 | the pinned reading (P38) |
| T-133 | Refinery value pack R1–R8 (time = ingot value/10 s clamped 10–60, fee at queue, 2→5 slots at 3,000 CR, caps 60/60, wall-clock jobs) | `docs/gameplay/04_refinery.md` §7 | as PROPOSED |
| T-117 | Drawer content box lands 1 px off the pin (x 69..341 vs 68..340) | `LOW_BACKLOG.md` | accept the 1 px |
| T-113 | Wire `ScriptErrorCapture` into the headless gate (bucket 2 — moves gate behaviour) | `LOW_BACKLOG.md` | leave the runner as-is |

Everything else already defaulted 2026-10-03 and is either shipped or riding
below.

## Open actions — no decision needed, just waiting

| ID | Action | Who | Closes at |
|---|---|---|---|
| T-114 | Dead `_row_hint` helpers — shipyard, auction, exchange remain (armory's died with S32) | builder | next pane touch |
| T-115 | ARMORY meter word: `CANDIDATE` vs `IF FITTED` (two pins disagree) | designer | next docs pass |
| T-116 | Auction foot band shape: §5.10 two-label vs §19.4 one-line (two pins disagree) | designer | next docs pass |

*Closed at this refresh: the T-94–T-97 / T-99 / L267 / L268 docs-cite batch —
re-measured against the S30-rewritten panels and fixed (symbol-stable cites);
T-99b closed with zero hits (no docked-hangar copy remains in `MENU_FLOW.md`).*
