# dispatch_coder.md — the code-lane queue of record

Rebuilt 2026-09-22, reorganised 2026-09-24 (open items only — closed work lives
in the Done pointer below, `MASTER_REPORT.md` and `_state/WAVEBOARD.md` §Closed).
Execute **one item per order**, close out per the brief's close-out section.
Model for every worker: `deepseek/deepseek-flash` (DeepSeek API direct, owner
ruling 2026-09-24; supersedes the same-day go order; fallback
`opencode-go/deepseek-v4.1-flash`) on `--reasoning-effort high`. The owner pastes
only the handoff block at the bottom.

**File-collision law:** two waves never hold one file (nor the same `test_*`
prefix, nor one `staging/` driver). Across lanes only with provably disjoint
write sets (the S5∥D6 precedent); one live session per workspace (L82).
**Wave anatomy:** docs-first five-piece → `verify_wave.py snapshot` + commit →
Q0/K0 dispositions into CONTRACTS → builders → review → fixer only on
HIGH/MED → close-out (gate ×2 hermetic, `verify --baseline`, §9/§10 sequenced
with any parallel lane, WAVEBOARD, wave-boundary commit).

## Open queue

| # | Wave | Slice folder | Brief / prompts | Status |
|---|---|---|---|---|
| 23 | **Fragment re-splits** (owner ask 2026-09-25, verbatim: "right now they split correctly, but the once split asteroid doesnt split further. this need to change") | `slices/S16-fragment-resplit/` | `S16_BRIEF.md` / `S16_prompts.md` | **DONE 2026-09-25** — gate 859 → **866/0** (+7: `test_s16_resplits.gd`); 0 HIGH / 0 MED / 4 LOW L212–L215; no fixer. Shot debris re-splits via the runtime-only `_cleave_child` marker (`cleaves()` = `_bore_ore > 0.0 or _cleave_child`) — parentage, not ore, gates a fragment's cleave (02 §5.2 ter); originals keep ruling 17's yield-0 law; money untouched (a 0-bore fragment's owed is 0, `_pay_burst` returns). R1 landed CONTRACTS §5/§9/§10 v0.28. |
| 15 | **Flight-feel retune** (owner O4/O5) — **folded into item 18** | — | — | **TICKED 2026-09-24.** The owner answered "go ahead with all": T1 `COAST_TIME_MULT` 2.5 and T2 new `ANGULAR_DAMP_MULT` 0.5 are implemented by item 18's **S11-B4**; **T4 is superseded** by the one-vector decay; **T3 is HELD** (§22's row contradicts itself — notice with the owner). |
| 17 | **Jump gates to sector edges** (owner ask 2026-09-24: same gates, spawn placement only) | not opened | — | **QUEUED — next.** The `game/sector.gd` seam is **free** since D11's close-out (2026-09-25); editor-only change otherwise; five-piece at dispatch-prep. |
| 18 | **Station legibility, space gunnery, one-vector inertia** (owner ask 2026-09-24: hovered-item description panel, credits in the space scene, near-infinite kinetic/beam range, the two-stop inertia) — pin **CONTRACTS §23** | `slices/S11-legibility-gunnery-feel/` | `S11_BRIEF.md` / `S11_prompts.md` | **DONE 2026-09-24** — gate 775 → **807/0**, 0 HIGH / 0 MED / 6 LOW (L178–L183). Six builders (B1 inspector, B2 prose + HUD credits, B3 ranges, B4 one-vector inertia, B5 test rows, B6 describe + titles) + R1; the readability half is the design lane's **D12-A0** audit. |
| 20 | **Ore caps, mining batteries, dev tuning** (owner ticks 2026-09-25: `GUN_BURST_SHARE` 0.10, `FRAGMENT_CORE_SHARE` 0.25, multiple `w_mining` must work, an F1 slider overlay for these values, `DOCK_RING_RADIUS` 175) | `slices/S13-ore-caps-devmenu/` | `S13_BRIEF.md` / `S13_prompts.md` | **DONE 2026-09-25** — gate 812 → **834/0**; 0 HIGH / 3 MED (F1 fixed the credit-reset and the live-config test; the developer session mounted the overlay in `game/game.gd`) / 4 LOW L198–L201. Gun realisation ≤ 0.10, cascade 4.0× → 1.000×, mining 1/2/3×, ring 175, F1 slider overlay live. Rule B stayed deferred. The `18_engine_spec` §6/§13 rewording awaits the owner. |
| 21 | **Four asteroid sizes, debris splits** (owner ask 2026-09-25: `XL>L>M>S`, each shatters into a random mix of smaller sizes — XL → few L/M/S "so that it looks more like debris"; yields untouched, Rule B stays deferred) | `slices/S14-debris-splits/` | `S14_BRIEF.md` / `S14_prompts.md` | **DONE 2026-09-25** — gate 834 → **852/0** (S14's +9 rows); 2 HIGH closed by the §3 ratification (forced row moves), 1 MED fixed by the developer session (the latent `SIZE_LARGE` bound), 6 LOW L202–L207. XL → L 1-3 / M 2-4 / S 2-5 debris mixes, conservation held (bore 32 → 32 over 4 seeds), spawn mix measured 37.6/34.5/20.7/7.2 vs the proposed 40/32/20/8 (**owner tick**). |
| 22 | **Battery hardcap 5x4 + armory B1-B5** (owner ask 2026-09-25: "hardcap of 5 gun batteries with 4 guns each ... rework the armory to reflect that as the cockpit has B1 to B5") | `slices/S15-battery-cap/` | `S15_BRIEF.md` / `S15_prompts.md` | **DONE 2026-09-25** — gate **852/0**; 3 HIGH + 1 MED all cured by F1 (the `ui/hud` lamp fix with `test_d7_cockpit` rows restored byte-identical, the no-rackless-weapon tail fold, the full-width tail bay), 4 LOW L208–L211. Refusals silent, 7-group saves clamp to 5×4, 5 bays 4+1 aligned to the cockpit lamps, plate-fit ink defect gone (route = ink layout; `weapon_6/7` inert — the `project.godot` cleanup stays the owner's optional pass). |
| 19 | **Ore budget — the two K0 probes** (owner ruling 2026-09-25: shooting rocks stays possible but mining must always be more profitable; asteroids could be bigger, in clusters and fields) — docs already amended, these are the numbers | `slices/S12-ore-budget/` | `S12_BRIEF.md` / `S12_prompts.md` | **DONE 2026-09-25** — K0/K1 measured byte-identical ×2, R1 replayed both on a detached worktree with zero byte differences; 0 HIGH / 2 MED (both bucket-2 docs, cured at close-out) / 7 LOW L191–L197. Tables + §10 ticks handed to the owner; **no cap implemented** (the caps and scale rows are a later wave on the owner's ticks). Gate rows unmoved (812/0 = 807 + D11's `test_d11_station`). |

Beyond the queue: **slice 4's remainder** (quadrants/directional armour — 18
§4.5 + ruling 23; bosses/arena — 14 §5, blocked on P4 contracts + boss art).
Owner-locked homework: the `18_engine_spec.md` §6/§13/§15 cleaving rewording
is done (applied 2026-09-25 on the owner's delegation); the §13 turn/coast
column ticks and slice 2.5's two calls stay the owner's.

## Done

Items 1–16 and 18 closed: chrome, combat repair, weapon FX (→ `MASTER_REPORT.md`);
P2-A `8d189bf`, Rock cleave `0e419f7`, P2-B1 `1f794cc`, P2-B `3e79e61` (→
`session_2026-09-22_items_4_to_7_report.md`, gate 437); S2.6 (457), S3 (493),
S4 (524), S5 (578), S6 (674), S7 (753), S8 (770), S10 (775), S11 (807) — detail, reviews,
incidents and LOW rows in `MASTER_REPORT.md` §6 +
`session_2026-09-24_items_8_to_13_report.md`; evidence archived in each
slice's `_archive/` (S8's, S10's and S11's still in their slice folders).

## Handoff (live)

**Item 19 is DONE** (2026-09-25): the tables and the §10 ticks are with the
owner; the caps and scale rows become their own wave once the owner ticks —
**do not implement ticked numbers before that wave is briefed**.
**Item 20 (S13) is DONE 2026-09-25** — the owner's ticks are shipped; the
`18_engine_spec` §6/§13 rewording (R1's review carries the exact proposed
sentences) is the owner's edit.
**Items 21 (S14 debris splits) and 22 (S15 battery cap + armory) are DONE
2026-09-25** (gate 852/0; the S14 spawn mix is the owner's tick, the S15
plate-fit route was ink layout).
**Item 23 (S16 — fragment re-splits) is DONE 2026-09-25** (gate 859 →
**866/0**; 0 HIGH / 0 MED / 4 LOW L212–L215; brief
`slices/S16-fragment-resplit/S16_BRIEF.md`, recap `MASTER_REPORT.md` §6).
**Item 17** (jump gates to sector edges) is now next; it needs its own
five-piece at dispatch-prep.
Slice 4's remainder (quadrants and directional armour, bosses/arena) still
needs its own five-piece. Owner answers 2026-09-25: the spawn mix is **kept**
(the shipped 40/32/20/8 weights stand) and the `18_engine_spec` §6/§13/§15
rewording is **applied on delegation** — neither is pending any more.

Beyond the queue: **slice 4's remainder** (quadrants/directional armour — 18
§4.5 + ruling 23; bosses/arena — 14 §5, blocked on P4 contracts + boss art).
Owner-locked homework: the `18_engine_spec.md` §6/§13/§15 cleaving rewording
is done (applied 2026-09-25 on the owner's delegation); the §13 turn/coast
column ticks and slice 2.5's two calls stay the owner's.

## Design lane (not mine to dispatch)

**D12's readability audit (owner ruling 2026-09-25: the fix wave is DITCHED —
the ARMORY takes a later rework).** The findings recap lives in
`dispatch_designer.md` §"D12-A0 recap" (the slice folder was cleared with the
2026-09-25 purge); any future rework brief reads it from there. D8 item 9
(station composition pass) is ditched the same day.
