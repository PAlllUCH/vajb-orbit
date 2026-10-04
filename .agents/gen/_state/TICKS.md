# TICKS — the one file (live only)

Every open owner decision and every open action in one screen. **Rows leave this
file when decided or done** (deleted at the wave close-out or the ruling — the
record lives in the cited file and `MASTER_REPORT.md` §6, this is the index
only). Refreshed at every wave close-out and after every owner ruling.

*Last refreshed: 2026-10-03 (D19 close, `f22a151`)*

## Waiting on the owner — tick one, or stay silent to take the default

| ID | The call | Where | Default if silent |
|---|---|---|---|
| N28-amend | Grid cells open the INSPECT modal through the **cluster** chip (a 48 px cell cannot seat a 96×32 chip); rows keep their own chip | `UI_SPEC.md` §11.1 (:1098) | stands as ruled |
| U14 | Vault capacity tiers: **40/60/80** or 20/40/60 | `STATION_HUB.md` §15 (:1407) | 40/60/80 |
| U17 | Character line **replaces** `StationLocation`? | `STATION_HUB.md` §15 (:1424) | replacement |
| outpost-faction | Outpost faction = **sector primary** | `STATION_HUB.md` §15 | sector primary |
| B2-1 | Main-menu hover plate pick (ember style) | `slices/D17-playtest-pass/D17_synthesis.md` | none — gated since D17 |
| T-98 | Exchange holdings header: `CR EACH` (shipped) or `CAP` | `LOW_BACKLOG.md` | CR EACH |
| T-100 | Deck-foot ZOOM± / EXPAND buttons: keep or drop | `LOW_BACKLOG.md` | keep (shipped) |
| T-102 | Grant a first-class `map_filters` save key, or keep the `_config` borrow | `LOW_BACKLOG.md` | designer grants the key at S30 |
| T-106 | ARMORY battery body (racks/ammo bands) keep or retire | `LOW_BACKLOG.md` | keep (shipped) |
| T-107 | OVERVIEW pane: accept the P22 scroll, or state per-block minima | `LOW_BACKLOG.md` | P22 scroll |
| T-108 | `REPAIR →` glyph: amend the wording or trust the P30 chevron | `LOW_BACKLOG.md` | chevron covers |
| T-109 | One-word fix: P18's `W3 names` → `U2 names` (say "go") | `LOW_BACKLOG.md` | fix applies on go |
| T-113 | Wire `ScriptErrorCapture` into the headless gate so script errors fail rows (bucket 2 — moves gate behaviour) | `LOW_BACKLOG.md` | leave the runner as-is |
| D19 tables | N31–N41 + P22–P31 (25 presentation rows) | `UI_SPEC.md` §12 / `STATION_HUB.md` §19.5 | implement at PROPOSED when S30 runs |

## Open actions — no decision needed, just waiting

| ID | Action | Who | Closes at |
|---|---|---|---|
| T-94–T-97, T-99, L267, L268 | Doc cite/wording fixes (one batch) | developer | next wave's docs-first step |
| T-101 + T-110 | Input-map rows: `map_toggle`, `station_inspect`, station prev/next module | orchestrator | S30 close-out |
| T-103 | Dead `RACK_INSTALL_CUE` const + stale comments | builder | S30 (ARMORY touch) |
| T-104 | Browser rows' second description surface | builder | S30 (census row 7: DELETE → TOOLTIP) |
| T-105 | L18/L122 clock rows: frozen-clock fixture or accept the weaker read | designer | S30's tests brief |
| T-111 | Plate seat 2 px overflow (272×56 in a 270 box) | builder | S30 (PROPOSED) |
| T-112 | Three-plate cluster seat arithmetic | designer | S30 brief |
