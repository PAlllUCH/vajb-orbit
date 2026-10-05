# TICKS — the one file (live only)

Every open owner decision and every open action in one screen. **Rows leave this
file when decided or done** (deleted at the wave close-out or the ruling — the
record lives in the cited file and `MASTER_REPORT.md` §6, this is the index
only). Refreshed at every wave close-out and after every owner ruling.

*Last refreshed: 2026-10-05 (S34 close — the refinery queue ships (gate
1132/0); T-133 decided by default)*

## Waiting on the owner

| ID | The call | Where | Default if silent |
|---|---|---|---|
| T-131 | Chrome family: unique station backgrounds — PROPOSED 4 backdrops (1765×753) assigned ARMORY / REFINERY / EXCHANGE+AUCTION / SHIPYARD+LAUNCH+OVERVIEW | `docs/design/UI_CHROME_ASSETS_SPEC.md` §13.3 | 4 as proposed |
| T-134 | Exchange unit-number selector is display-only since `SELL UNITS` owns the sale — fold it away, keep it as a readout, or give it a job? | `ui/station/exchange_panel.gd` | keep as a readout |
| T-135 | Chrome C9 drawer-entry target: spec 360×56 vs measured 272×56 (`station.gd:129`) | `UI_SPEC.md` §15 | adopt the measured 272 |
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

*Closed at this refresh: **T-133** (the R1–R8 pack implemented at its
PROPOSED values) at the S34 close. Earlier: **T-130/T-132** at the S33 close.*
