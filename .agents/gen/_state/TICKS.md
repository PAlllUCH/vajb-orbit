# TICKS — the one file (live only)

Every open owner decision and every open action in one screen. **Rows leave this
file when decided or done** (deleted at the wave close-out or the ruling — the
record lives in the cited file and `MASTER_REPORT.md` §6, this is the index
only). Refreshed at every wave close-out and after every owner ruling.

*Last refreshed: 2026-10-04 (D20 close — the owner's playtest compiled; T-118–T-126 filed)*

## Waiting on the owner

| ID | The call | Where | Default if silent |
|---|---|---|---|
| T-117 | Drawer content box lands 1 px off the pin (x 69..341 vs 68..340) | `LOW_BACKLOG.md` | accept the 1 px |
| T-113 | Wire `ScriptErrorCapture` into the headless gate (bucket 2 — moves gate behaviour) | `LOW_BACKLOG.md` | leave the runner as-is |
| T-124 | Inspect "twice as long": linger 0.5 s after unhover + steady across intra-row hover churn (A) vs appear delay 0.25 → 0.5 s (B) | `D20_synthesis.md` §5 | A |
| T-125 | Armory split shape: two full-screen modes (FIT CELLS / BATTERY CONFIG) vs two panes on one screen | `D20_synthesis.md` §5 | two full-screen modes |
| T-126 | Battery module scope: rack regroup (`set_battery_groups`) + SALVO/cycle readout vs also loadout presets | `D20_synthesis.md` §5 | regroup + readout only |

Everything else already defaulted 2026-10-03 and is either shipped or riding
below.

## Open actions — no decision needed, just waiting

| ID | Action | Who | Closes at |
|---|---|---|---|
| T-101 + T-110 | Input-map rows: `map_toggle`, `station_inspect`, station prev/next | orchestrator | **blocked** — the editor was in play mode at close-out (`EDITOR_PLAYING`); lands the next time the game is stopped |
| T-114 | Dead `_row_hint` helpers in four panes | builder | next pane touch |
| T-115 | ARMORY meter word: `CANDIDATE` vs `IF FITTED` (two pins disagree) | designer | next docs pass |
| T-116 | Auction foot band shape: §5.10 two-label vs §19.4 one-line (two pins disagree) | designer | next docs pass |
| D20 fixes F1–F5 | Exchange parity, armory overflow, inspect popup (quick) + armory 2-module rework (own wave) + the LOW pack T-118–T-123 | orchestrator | on the owner's go (T-124–T-126 default if silent) |

*Closed at this refresh: the T-94–T-97 / T-99 / L267 / L268 docs-cite batch —
re-measured against the S30-rewritten panels and fixed (symbol-stable cites);
T-99b closed with zero hits (no docked-hangar copy remains in `MENU_FLOW.md`).*
