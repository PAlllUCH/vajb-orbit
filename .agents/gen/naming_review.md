# Naming plan audit — 2026-09-20

Scope: `docs/design/ASSET_NAMING_SPEC.md`, `staging/cut/_naming/assignments.tsv`,
`staging/cut/_naming/canonical.txt`, `staging/cut/_naming/live_names.txt`.
Line numbers refer to the true TSV line numbers (header = line 1) and to the
canonical/live files as read.

## A. Two siblings resolving to the same name

**None found.** All non-empty `new_name` values in the TSV are unique
(`panel_modules_a`, `panel_modules_b`, `panel_modules_c`, `panel_button_plates`,
plus the seven stamped `keep` names; no name is claimed by two different files).

## B. A new name colliding with a name in canonical.txt or live_names.txt

1. **P1** — `assignments.tsv:21` renames `raw/icon_module__20260918-114107.png` to
   `panel_modules_a`, but `canonical.txt:856` already lists `panel_modules_a`.
   Nuance: no file on disk holds that name and §6 shape 3 / §7 `icons-spec-8.2`
   sanction the rename, so the collision rule (§8.1, "reserved if canonical.txt
   lists it") and the rename intent are in conflict — the engine must decide
   which list is authoritative before dispatch.
2. **P2** — `assignments.tsv:22` → `panel_modules_b`, same situation
   (`canonical.txt:857`).
3. **P3** — `assignments.tsv:23` → `panel_modules_c`, same situation
   (`canonical.txt:858`).
   `panel_button_plates` (line 24) collides with neither list; its problem is
   P24 below.

## C. Names breaking the §1 grammar

Grammar §1 allows only lowercase a–z, digits, underscore; forbids timestamps and
version markers. `@2x`, `_16` etc. are derived suffixes, not part of a master
name (§5).

4. **P4** — `assignments.tsv:12`, keep of `raw/icon_module__20260918-114107.png`,
   sets `new_name = icon_module__20260918-114107`: contains a timestamp and the
   hyphen `20260918-114107`, both outside the §1 character set and explicitly
   forbidden ("no timestamps"). 
5. **P5** — `assignments.tsv:13`, `raw/icon_module__20260918-114156.png`, same
   stamped name kept.
6. **P6** — `assignments.tsv:14`, `raw/icon_module__20260918-114240.png`, same.
7. **P7** — `assignments.tsv:15`, `raw/ship_drone_swarm__20260917-213637.png`, same.
8. **P8** — `assignments.tsv:16`, `raw/ship_drone_swarm__20260918-133108.png`, same.
9. **P9** — `assignments.tsv:17`, `raw/ui_button_plate__20260917-185457.png`, same.
10. **P10** — `assignments.tsv:18`, `raw/ui_button_plate__20260918-133142.png`, same.
    (P4–P7 and P10 sit on paths that also carry a contradictory second row, P25–P34;
    a rename engine that honours the later row would erase these names anyway.)
11. **P11 (spec bug)** — §4's asteroid-band variants `_L1 _L2 _L3 _M1 … _S3` are
    uppercase, which the §1 character rule ("lowercase `a` to `z`") forbids. These
    names are already live and canonical (`env_asteroid_L1` …, `canonical.txt:813+`),
    so either §1 or §4 is wrong as written.
12. **P12 (spec bug)** — §5's `@2x` contains `@`, which is outside the §1 character
    set; the sanctioned derived names (`ui_bar_caps@2x`, `canonical.txt:1066`, etc.)
    formally break the grammar they are appended to.

## D. Variants outside the closed list in §4

13. **P13** — §10 decision 3 recommends extending the sector roster to
    `env_sector_8_bg` … `env_sector_11_bg`: `_8_bg` … `_11_bg` are outside the
    closed `_1_bg` … `_7_bg` list until §4 is amended.
14. **P14** — §10 decision 4 proposes keeping the displaced moon "as `_prev`":
    `_prev` is not in the closed variant vocabulary.
15. **P15** — §10 decision 6 proposes `ui_bar_caps_left` / `ui_bar_caps_right`:
    `left` / `right` are not in the closed variant vocabulary.
16. **P16** — §10 decision 1 proposes `icons/alt/` with `icon_alt_<subject>` names:
    `alt` acts as an unlisted variant/qualifier, and the `icons/alt/` container is
    not in §3's container table.

## E. A master carrying a derived suffix

**None found.** No `rename` or `keep` row ends in `_16`, `_48`, `_96`, `_192` or
`@2x`; no master name in the plan carries a derived suffix.

## F. A sanctioned name put on art the spec does not order

17. **P17** — `assignments.tsv:24` renames `raw/ui_button_plate__20260918-133142.png`
    to `panel_button_plates` with evidence `icons-spec-8.2`. §7 defines that
    evidence as covering **only** `panel_modules_a/b/c`; no spec orders a
    button-plate panel, and the note itself admits "the master name is proposed
    here" — an invented name, which §7 forbids. The evidence tag is also
    mislabelled (it should be `owner` or a spec amendment), so the rename engine
    would apply it as if sanctioned.

## G. A row whose `new_name` is set while its evidence is `owner`

**None found.** All 60+ `owner` rows (evidence column = `owner`, lines 69–243)
have an empty `new_name`; nothing is silently renamed under owner evidence.

## H. Additional problems found outside the requested classes

18. **P18** — `assignments.tsv:16` claims `stamp-absent` ("no file holds
    ship_drone_swarm"), but `canonical.txt:960` lists `ship_drone_swarm` (and
    `:961` the prefix `ship_drone_swarm_`). The stamp is therefore not spurious;
    under §6 shape 2 / §8.2 the sheet is a duplicate of named art and should be
    dropped, not kept. Its sibling at line 15 is in fact treated that way
    (drop-pending at line 64), so the same shape is handled two different ways.
19. **P19–P28** — **ten files carry two contradictory rows each**, so the plan
    resolves the same file to two different dispositions:

    | File | Row A | Row B |
    |---|---|---|
    | `cut/ui_button_plate_disabled__20260917-185457.png` | drop (line 7) | owner (line 224) |
    | `cut/ui_button_plate_hover__20260917-185457.png` | drop (line 8) | owner (line 222) |
    | `cut/ui_button_plate_normal__20260917-185457.png` | drop (line 9) | owner (line 221) |
    | `cut/ui_button_plate_pressed__20260917-185457.png` | drop (line 10) | owner (line 223) |
    | `raw/icon_module__20260918-114107.png` | keep (line 12) | rename → `panel_modules_a` (line 21) |
    | `raw/icon_module__20260918-114156.png` | keep (line 13) | rename → `panel_modules_b` (line 22) |
    | `raw/icon_module__20260918-114240.png` | keep (line 14) | rename → `panel_modules_c` (line 23) |
    | `raw/ship_drone_swarm__20260917-213637.png` | keep (line 15) | drop-pending (line 64) |
    | `raw/ui_button_plate__20260917-185457.png` | keep (line 17) | owner (line 220) |
    | `raw/ui_button_plate__20260918-133142.png` | keep (line 18) | rename → `panel_button_plates` (line 24) |

    The icon_module pairs are semi-benign (the keep note says "handled below", and
    keep-then-rename in file order is a no-op followed by the rename), but the
    four `ui_button_plate` state twins and the two `ui_button_plate` raws are
    drop-vs-owner and keep-vs-owner contradictions that block any mechanical run,
    and the drone-swarm keep vs drop-pending pair is a real disposition conflict.
    Each duplicate pair also doubles the blast-radius mapping (§9) if both rows
    are honoured.

## Count

| Category | Problems |
|---|---|
| A. Two siblings resolving to the same name | 0 |
| B. New name colliding with canonical.txt / live_names.txt | 3 (P1–P3) |
| C. Names breaking the §1 grammar | 9 (P4–P12) |
| D. Variant outside §4 | 4 (P13–P16) |
| E. Master carrying a derived suffix | 0 |
| F. Sanctioned name on art no spec orders | 1 (P17) |
| G. `new_name` set with owner evidence | 0 |
| H. Additional (false stamp-absent; contradictory row pairs) | 11 (P18–P28) |
| **Total** | **28** |
