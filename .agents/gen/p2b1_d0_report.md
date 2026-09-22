# P2-B1 — D0 report: the docs pin (weapon fit surface)

**Worker:** D0 (documentation only). **Wave:** P2-B1 — the weapon fit surface.
**Brief (law):** `.agents/gen/p2b1_weapon_fit_wave_task.md`.
**File set (`VAJB_WORKER_FILES`):** `docs/` — four documented files touched, nothing else:
no code, no `assets/**`, no theme, no `project.godot`, no `addons/**`.
**Status:** complete. The pin exists before W1 starts, so W1/W2/R1 can all read it.

**Deviation note (one).** The `edit` tool refuses absolute paths on this host (P2-A's D0 hit the
same hook): `edit /home/kamil-paluszkiewicz/VajbOrbit/docs/design/STATION_HUB.md` was blocked with
"outside this worker's declared file set. Allowed: docs/". Every write was then issued with the
workspace-relative path (`docs/...`) and succeeded. `.agents/gen/**` is explicitly allowed by the
hook (`.crush/hooks/enforce_worker_files.py:41`), so this report needed no heredoc workaround.

## 1. Files changed

| File | Section(s) changed | Lines (after) | Change |
|---|---|---|---|
| `docs/design/STATION_HUB.md` | §5.1 (re-headed + amendment block), §2 rail table (46), §7.1 art map (686) | 363–398, 46, 686 | the MODULES section and the FITTED WEAPONS strip **verbatim** from the brief §3, the brief's two refusal wordings, the ammo rows re-labelled, §7.1's module-icon row, and the §2 payload line made true |
| `docs/CONTRACTS.md` | new **§12** (1029–1082) + **§10 Changelog** (1334–1365) | 1029–1082, 1334 | §12 pinned: `buy_module` + the six consumer rules **verbatim**, plus six rules the pin fixes; one v0.3 changelog entry |
| `docs/gameplay/10_ship_acquisition.md` | §6 (160–169) | 160–169 | the dated interim note: OUTFITTING sells the six weapon modules until the AUCTION module of §2 exists |
| `docs/gameplay/09_ship_slots_modules.md` | §4 item 8 (269–275) | 269–275 | the same dated interim pointer, on the rule it belongs to |

Diff size: **4 files, +141 / −5**, `docs/**` only (`git diff --stat`), plus this report.

## 2. STATION_HUB.md §5.1 — where each pinned item lives

"Brief line" is the line in `.agents/gen/p2b1_weapon_fit_wave_task.md`; "Doc line" is the line in
`docs/design/STATION_HUB.md` after the landing.

| Pinned item (brief §3, consumer rules) | Brief line | Doc line |
|---|---|---|
| `### 5.1 OUTFITTING (buy ammunition and weapon modules)` (re-headed — the heading this file owns) | — | 363 |
| lead-in: three groups in render order (strip, module rows, ammo packs) | — | 365 |
| amendment header: "**Amendment 2026-09-22 (P2-B1 — the weapon fit surface: the MODULES section and the FITTED WEAPONS strip).** Transcribed from `.agents/gen/p2b1_weapon_fit_wave_task.md` §3; every number in it is 09 §3.1's and none is this pass's." | — | 367–368 |
| bullet 1 — `MODULES` caption + the six weapon rows in 09 §3.1's order with their frozen costs, `W SLOT · DRAW n` meta, effect text, PRICE, STATUS, ACTION | 77–81 | **371–375** |
| bullet 2 — STATUS state machine (`FITTED (Wk)` / `OWNED ×n` / `FOR SALE` / `LOCKED`) | 82–83 | **376–377** |
| bullet 3 — ACTION state machine (`BUY` → `INSTALL` first empty W cell → SWAP → `REMOVE`, displaced module to inventory) | 84–86 | **378–380** |
| bullet 4 — the **FITTED WEAPONS** strip (`W1 LASER MKII` / `W2 — EMPTY`, REMOVE on fitted lines, reads `ShipFit.grid_cells` + `PlayerProfile.fit_for`, never mutates — §12.4) | 87–90 | **381–384** |
| bullet 5 — refusals in the panel's own footer strip (`status_requested`), never a dialog | 91–92 | **385–386** |
| bullet 6 — focus order (strip, then module rows, then ammo rows; Tab order, §10) | 93–94 | **387–388** |
| the brief's two refusal wordings (owner tick 2): `13 / 11 PWR — OVER BY 2` (09 §2's over-by format) and `W SLOTS FULL — SWAP OR REMOVE FIRST` | tick 2 (brief 128–129) | **390–393** |
| reversal path (house style) | — | 395–396 |
| `**The ammo rows.**` re-label covering the unchanged 40 px / 5-row ammo construct | — | 398 |
| §7.1 art map: the module-icon paths for the MODULES rows | — | **686** |
| §2 rail table: `6 weapon modules + 5 ammo packs, ModuleCatalog / StationCatalog.AMMO_PACKS (amendment, section 5.1)` | — | **46** |

The two refusal wordings are **not** in the brief's §3; they are owner tick 2 (brief 128–129,
"cosmetic, D0's"). Because the owner's instruction names them as part of what §5.1 must carry, they
land in the amendment block as a D0-authored paragraph quoting the brief's two strings
byte-exactly, `docs/design/STATION_HUB.md:390–393`:

```text
Refusal wordings (owner tick 2 of the wave brief, its own two lines; 09 §2's over-by format is the
first): the power overload renders `13 / 11 PWR — OVER BY 2` (Σ draws / output — over by) and a swap
with no empty W cell renders `W SLOTS FULL — SWAP OR REMOVE FIRST`; both land in the footer strip
(`status_requested`), never a dialog.
```

Both wordings are the brief's bytes inside that paragraph; the sentence around them is D0's framing.

## 3. Verbatim proof (re-runnable; no dependence on my reading)

```text
$ python3 - <<'PY'
brief = open('.agents/gen/p2b1_weapon_fit_wave_task.md', encoding='utf-8').read().split('\n')
doc = open('docs/design/STATION_HUB.md', encoding='utf-8').read().split('\n')
body = brief[76:94]                      # brief lines 77..94, the six consumer bullets
i = doc.index('- The pane gains a `MODULES` caption and six weapon rows above the ammo packs,')
print('brief 77..94 == STATION_HUB[%d:%d] ->' % (i+1, i+len(body)), doc[i:i+len(body)] == body)
PY
brief 77..94 == STATION_HUB[371:388] -> True
```

```text
$ python3 - <<'PY'
brief = open('.agents/gen/p2b1_weapon_fit_wave_task.md', encoding='utf-8').read().split('\n')
ct = open('docs/CONTRACTS.md', encoding='utf-8').read().split('\n')
h = ct.index('## §12 P2-B1 weapon fit (2026-09-22)')
seg = ct[h:h + 90]
pin = seg[seg.index('```gdscript'):][:6]
body = seg[seg.index(brief[76]):][:18]
print('pin  == brief 67..72 == CONTRACTS 1034..1039 ->', pin == brief[66:72])
print('body == brief 77..94 == CONTRACTS 1044..1061 ->', body == brief[76:94])
PY
pin  == brief 67..72 == CONTRACTS 1034..1039 -> True
body == brief 77..94 == CONTRACTS 1044..1061 -> True
```

Both blocks are the brief's **own bytes** in both files, so the fences, the em dashes, the `Σ`,
the `·`, the `×`, the `→` and the `—` are the brief's, not retyped. The only text that is **not**
the brief's is listed in §5 below, so R1 can diff it deliberately.

## 4. CONTRACTS.md §12 — the pin's line index

| Item | Doc line |
|---|---|
| `## §12 P2-B1 weapon fit (2026-09-22)` (heading) | 1029 |
| intro: "Pinned before the wave's code workers start, so they agree. Additive only: every §2/§3/§7/§8/§11 pin above stays valid." | 1031–1032 |
| `autoload/player_profile.gd` fence (opens 1034 / closes 1039) | 1034–1039 |
| `## autoload/player_profile.gd — additive beyond P2-A's §11 pin.` | 1035 |
| `func buy_module(module_id: StringName, cost: int) -> bool` | 1036 |
| `# 17 §5: refuse when unknown/insufficient (purchase_failed), else spend(cost),` | 1037 |
| `# add_module(module_id, 1), profile_changed(&"modules"), one EconomyLog line` | 1038 |
| consumer-rules heading ("the same six bullets are the surface's contract there; every number in them is 09 §3.1's") | 1041–1042 |
| the six consumer bullets, verbatim | 1044–1061 |
| `Rules the pin fixes, so no worker has to choose:` | 1063 |
| rule 1 — refusals reuse `purchase_failed`'s `&"unknown_id"` / `&"insufficient_credits"`, log line `EVENT_BUY_MODULE` or the nearest shipped event id, 17 §5's law | 1065–1068 |
| rule 2 — the panel only requests (`set_fit_slot` / `clear_fit` / `buy_module`) | 1070–1072 |
| rule 3 — every install and swap passes `ShipFit.fit_legal`, nothing auto-removes | 1073–1074 |
| rule 4 — the mandatory set (engines, reactor) is untouchable from this surface | 1075–1076 |
| rule 5 — the two refusal wordings live in `STATION_HUB.md` §5.1 | 1077–1079 |
| rule 6 — no flight-side change; a swapped weapon mounts on the next launch (09 §4.8) | 1080–1082 |
| `## §10 Changelog` | 1084 |
| `- **v0.3 (2026-09-22, P2-B1 weapon-fit wave — D0, the wave's only CONTRACTS writer)** — …` (32 lines) | 1334–1365 |

## 5. What is D0-authored (not the brief's bytes), and why

Everything below is framing, an index, or a restatement of an existing pin — **not a number**.

| Site | Text | Why |
|---|---|---|
| STATION_HUB 363 | the re-headed `### 5.1 OUTFITTING (buy ammunition and weapon modules)` | the pane stops being ammunition-only; the amendment is the reason. No cross-reference outside this file quotes the heading (grepped). |
| STATION_HUB 365 | the one-line lead-in naming the three groups in render order | the ammo text follows the amendment, so the read order has to be stated; the order is the brief's own (strip above rows, rows above the ammo packs) |
| STATION_HUB 367–368 | the amendment header + "Transcribed from … §3" | house style: dated amendment blocks (cf. §5.2's P2-A block) |
| STATION_HUB 390–393 | the refusal-wordings paragraph | owner tick 2 is D0's (brief 128–129); the two strings are the brief's bytes, and the `(Σ draws / output — over by)` gloss is 09 §2's own reading of its `13 / 11` pair |
| STATION_HUB 395–396 | the reversal path | house style: every amendment carries one, with no number in it |
| STATION_HUB 398 | `**The ammo rows.**` | the unchanged ammo construct needed a label once the amendment opened the section |
| STATION_HUB 686 | the §7.1 art-map row | the D0 row asks for the module icon paths; the rule text is CONTRACTS §11's icon rule (P2-A's pin) with `res://` prefixed, and the 48 px is the brief's `48 px module icon` |
| STATION_HUB 46 | `6 weapon modules + 5 ammo packs, ModuleCatalog / StationCatalog.AMMO_PACKS (amendment, section 5.1)` | the rail table's payload column is the pane's contents; this wave makes it wrong. Both numbers are the brief's (`six weapon rows`) and the section's own (`five rows`). The one line I touched outside the sections the D0 row names — flagged here so R1 can revert it deliberately. |
| CONTRACTS 1031–1032, 1041–1042, 1063–1082 | §12's intro, the consumer-rules heading and the six rules | the intro mirrors §11's; the rules are restatements of 09 §4.1/§4.8, §7, 17 §5's transaction law, STATION_HUB §12.4 and the brief's own §1/§3/§7 sentences, each carrying its citation. They fix ambiguity, which is what a pin is for. |
| CONTRACTS 1334–1365 | the v0.3 changelog entry | the D0 row asks for it |

**Duplication is deliberate and is the brief's own shape:** the six consumer bullets are the brief's
bytes in **both** §12 and §5.1, because the brief's §3 parenthetical says the consumer rules *are*
the STATION_HUB §5.1 amendment and §12 is the pin (P2-A's §11 landed its panel contracts the same
way). Both copies say so in their intro lines, so a future editor cannot "fix" one side in silence.

## 6. The dated interim notes (10 §6 and 09 §4.8)

| File | Line | Text |
|---|---|---|
| `docs/gameplay/10_ship_acquisition.md` | **160–169** (inside §6 `Module inventory`, which opens at 149) | "**Interim note 2026-09-22 (P2-B1 — the weapon fit surface).** Until the AUCTION module of §2 exists, **OUTFITTING sells the six weapon modules** into this inventory (`ModuleCatalog` and `buy_module`, CONTRACTS §12; the rows, states, refusal wordings and focus order are `STATION_HUB.md` §5.1's amendment). This is §5's precedent for the legacy upgrade rows — a documented interim surface, never a second economy. When AUCTION ships, those rows retire into it and OUTFITTING returns to ammunition. Reversal: none owed while §2 is unbuilt; if AUCTION is dropped, the OUTFITTING rows become the permanent home and this note becomes the rule." |
| `docs/gameplay/09_ship_slots_modules.md` | **269–275** (§4 item 8) | the same pointer appended to the swapping rule: "…**Interim note 2026-09-22 (P2-B1, the weapon fit surface):** until the AUCTION module (10 §2) exists, the surface that buys the weapon modules into the inventory is **OUTFITTING** (`STATION_HUB.md` §5.1's amendment; the same note is in 10 §6), and those rows retire into AUCTION when it ships." |

Both cite each other and §5.1, so the three copies cannot drift apart unnoticed. Neither note
carries a cost: the costs are 09 §3.1's and live once, in §5.1/§12's transcription.

## 7. Findings for the wave (transcribed, never resolved — the brief is law)

1. **HIGH-input for W2/R1: "six weapon rows" versus seven listed ids.**
   The brief's §3 bullet 1 says `six weapon rows` and then lists **seven** ids — `w_laser` 900,
   `w_cannon` 1 200, `w_rocket` 2 400, `w_mine` 1 800, `w_plasma` 4 800, `w_railgun` 5 200,
   `w_mining` 600 (brief 77–80). 09 §3.1's table has **six rows** (`w_laser` … `w_railgun`) and
   `w_mining` is 09 §4 item 7's weapon module (Tier I, draw 1, 600). The brief's §1 names a
   *different* six for the shop — `w_cannon`, `w_mining`, `w_rocket`, `w_mine`, `w_plasma`,
   `w_railgun`, i.e. no `w_laser` row (brief 25–27). Two readings follow:
   (a) rows = 09 §3.1's six table rows, no `w_mining` row; (b) rows = the brief §1 six, no
   `w_laser` row. **Neither is resolved anywhere in the docs**: §5.1 and §12 carry the brief's own
   bytes, discrepancy included, and the two interim notes deliberately do not enumerate the six.
   W2's row set is the first thing R1 should measure; if the brief is to be corrected, that is the
   owner's edit, not a worker's.
2. **A size tension R1 should not read as a D0 error:** the brief's bullet 1 says `48 px module
   icon`, while §3.1's row grid gives OUTFITTING a **40 px** icon column (line 140, "icon | 40 |
   40"). Both numbers are transcribed where they live; nobody reconciles them in the docs.
3. **Measured gate baseline (my own run, not a quote):** `passed=378 failed=0`, exit 0 — see §8.
   R1's post-wave count should be read against it.
4. **Not mine, not fixed (pre-existing staleness, recorded so it is not lost):**
   `docs/design/STATION_HUB.md:49` still reads "4 hulls, `StationCatalog.SHIPS`" — stale since
   P2-A made the roster nine (`STATION_SPEC.md` §4.2's amendment; P2-A's D0 did not sweep §2).
   Also `docs/gameplay/10_ship_acquisition.md:154` cites "09 §4.6" for install/remove, where the
   swapping/inventory rule is 09 §4.8. Both are one-line fixes for whoever owns a whole-file pass;
   this wave's D0 row names neither file's section, so I left them and say so here.

## 8. Commands run (all raw output in this report or re-runnable)

| Command | Purpose | Result |
|---|---|---|
| `godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` | the wave's pre-dispatch gate baseline | exit 0, `[SUMMARY] passed=378 failed=0` (`/tmp/p2b1_gate_d0.log`) |
| `python3` verbatim checks (§3) | prove both transcriptions are the brief's bytes | `True` for both |
| `rg -n "5\.1\|buy ammunition\|OUTFITTING" docs/` | find every reference the re-headed §5.1 could break | no file outside `docs/design/STATION_HUB.md` quotes §5.1's heading or §2's payload row |
| `ls vajb-orbit/assets/icons/{module,weapon}/*_48.png` | confirm every icon path §7.1 names exists on disk (read-only) | 27 `icon_module_*_48.png` (matching 09 §8's "all 27 module icons ship") + `icon_weapon_{laser,cannon,rocket,mine,plasma}_48.png` |
| `git diff --stat` | scope proof | 4 files, all under `docs/`, +141 / −5 |
