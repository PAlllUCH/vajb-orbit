---
slice: D21-chrome-family
worker: D21-G2
role: coder (asset lane)
status: ready
tier: paid — hyper/glm-5.3-flash @ max (owner's image-lane + reviewer assignments, 2026-10-05)
---

# D21-G2 — cut, key, center and land the chrome family

## 0. The owner's request (verbatim)

Keep/swap criterion (2026-10-05): "keep the chromes from main menu, terminal
side panel, CANCEL, SELL buttons, all the ones that are native not stretched
look good. rest is up to you or worker you spawn, suggest then we will work
with it." — and on the four S36 calls, verbatim: **"1. swap, 2. POWER 3.
accept 4. ok waiting."** The record with reversals is `UI_SPEC.md` §15.5; the
keep/swap map is `slices/D21-chrome-family/S36_proposal.md`.

## Context (read in this order)

1. `slices/D21-chrome-family/D21-G1_report.md` — the 16-run inventory (run
   dirs, pixels, alpha shares) + its two deviations that change the cut math:
   C3/C10 returned 21:9 (so they take the crop-to-master route too) and
   C2/C8/C11/C12 returned opaque (so they need the local background-strip key).
2. `slices/D21-chrome-family/S36_proposal.md` — the swap map + the decided calls.
3. The spec extracts below — they are the law; the big specs are read only
   where an extract names its source.
4. `asset-library/README.md` §"Keying is done" — key routes + the two known
   failure modes.
5. `docs/design/ASSET_NAMING_SPEC.md` §1 + §4 — stem grammar, closed state
   suffixes.

## Spec extract (the pinned law, verbatim)

**`docs/design/UI_CHROME_ASSETS_SPEC.md` §13.1 — the crop-to-master rule:**

> **The crop-to-master route (PROPOSED, one uniform rule for the six unmatched
> classes C1/C2/C4/C5/C6/C9 — reversal: pad to the master aspect instead of
> cropping, a substrate hairline on every edge).** Those six prompts draw the
> plate **at its own class aspect, centred with plain substrate margin on every
> side, about four fifths of the frame width** — never filling the source
> frame. The local step then (1) keys the substrate (§1's route) when the
> return is opaque, (2) measures the ink box, (3) crops to the **smallest
> centred rectangle at the class's master aspect that contains the ink box in
> full** — a rectangle that would exceed the returned frame is a fail, never a
> clip — and (4) resizes to the master pixels with one uniform scale factor
> (UI_SPEC §15.2 A1/A6). The direct classes skip step 3: their frame already
> sits at the master aspect.

Master pixels per class (from §13.1's class blocks): C1 1134×280, C2 720×112,
C3 192×64, C4 1120×152, C5 520×384, C6 2720×1032, C7 720×480, C8 112×112,
C9 720×112, C10 84×28, C11 400×400, C12 192×192, BG-1..4 (C13) 2048×874.

**`§13.2` — states:**

> One run per class carries the **normal** state only. Hover, pressed and
> disabled derive by `modulate` and stylebox tint (UI_SPEC §15.2 A7; A5.5/N24 —
> never size, position or an in-flow `visible`). Where modulate fails QC — the
> pressed inset read of a button is the expected case — **at most one paid
> variant** ships for that class, named with the closed `_pressed` / `_hover` /
> `_disabled` suffixes (`ASSET_NAMING_SPEC.md` §4). State-bearing classes: C1,
> C2, C3, C4, C8, C9 — the ceiling below counts one variant each.

**`§13.4` — the stems:**

> C1 `ui_tile_slab`, C2 `ui_action_bar`, C3 `ui_inline_chip`, C4 `ui_row_strip`,
> C5 `ui_rack_bay_card`, C6 `ui_armory_console` (existing name, art replaces in
> place), C7 `ui_tooltip_frame`, C8 replaces the slot faces in place under the
> existing names `ui_slot_weapon` / `ui_slot_cargo` / `ui_slot_inventory`, C9
> `ui_drawer_entry`, C10 `ui_bar_caps` (in place), C11 `ui_minimap_bezel` (in
> place), C12 `ui_panel_frame` (in place; the 192 master keeps the one name),
> C13 the §13.3 stems (`ui_backdrop_armory_deck`, `ui_backdrop_refinery_deck`,
> `ui_backdrop_market_deck`, `ui_backdrop_dock_deck`).

**`§13.5` — QC:**

> **Aspect verify (before any cutting …)** Every returned render is measured
> with Pillow … **before it enters the cut step** … and the declared
> crop-to-master must land the class block's stated master aspect exactly (the
> crop rectangle is computed at that aspect, never assumed; the containment
> check below is what proves no plate was clipped).
> Ink-box containment **≥ 95 %** on every cut (the §12 law); UI_SPEC §15's
> nine-slice margins are re-measured from each cut's own rivet/bevel band and
> reported (N51); §2's uniform-band check runs on C7/C11/C12 (each edge band
> identical along its run — a render that fails re-renders once, then the class
> falls back to its shipped art and the route is reported). … Backdrops verify
> opaque with no alpha.

**`docs/design/UI_SPEC.md` §15.2 — the aspect law (A1/A2/A6/A7):**

> 1. **A1 — every plate is drawn at its class's true aspect, and that aspect is
>    respected always.** …
> 2. **A2 — caps, corners and rivets never stretch.** All ornament lives inside
>    the nine-slice corner squares …
> 6. **A6 — whole-face plates (C6 and the `keep` anchors) are drawn at their
>    surface's exact aspect and are never stretched or sliced** …
> 7. **A7 — states derive by `modulate` and stylebox tint** …

**`§15.3` — the margins law (your margins report must measure these):**

- C1 — margins 16 all sides; stretch only the flat interior, both axes within
  ±10 % of 567×140 (h 510–624, v 126–154).
- C2 — margins 20 at the short-side caps, 12 top/bottom; horizontal flat band
  272→450 wide, vertical 56→88 tall.
- C3 — margins 8; horizontal flat band 80→160 wide.
- C4 — margins 12/8 (RowInner); horizontal flat band 320→1765 wide; vertical
  64→84 tall; the band is flat end to end (A3).
- C5 — margins 10; no stretch (fixed 260×192 rect at use).
- C6 — no margins, no stretch (A6, `contain`).
- C7 — margins 12; horizontal 280→360 (360 cap is N47), vertical 120→400.
- C8 — a cut sprite at 1:1; no nine-slice; uniform scale is legal, any
  non-uniform use is barred.
- C9 — margins 16/8 (RailInner); horizontal 272→360 (target 272 per T-135);
  vertical none (56 fixed).
- C10 — a cut sprite; no margins, no stretch.
- C11 — margins 16 (measured); no stretch (fixed 200×200 at use).
- C12 — margins 32 at the 96 cut (64 at the 192 master); edge bands tile over
  any rect; corners never move or scale (A5).
- C13 — opaque cover-fit at 1765:753; no stretch.
  **Pinned, all classes: caps, corners and rivets never stretch (A2).**

**`§15.5` — the owner's four calls (decided 2026-10-05):** drawer entries swap
onto C9 (drawer surface stays native); `POWER` stays; the 393 px TradeBox is
accepted; state variants stay un-purchased until cut-stage QC demands them,
then ≤ 1 per failing class, ≤ 6 runs / ≤ $0.30.

## Task

Turn the 16 generated renders in `asset-library/raw/chrome-family/20261005-*/`
into the landed, keyed, centered, master-sized chrome family under
`vajb-orbit/assets/ui/`, class by class per the law above: key → ink box →
crop-to-master (§13.1's uniform rule) → one uniform resize to master pixels →
center → margins measured from each cut's own rivet/bevel band → land at the
§13.4 stems → one cut contact sheet for the owner's eye. You land art only —
every wiring decision (StyleBoxTexture, BG backdrop nodes, keep-list
enforcement) belongs to the later S36 wave.

## Acceptance list

1. The 16 inputs are located from `D21-G1_report.md`'s table and mapped
   class → render file in the report.
2. Keying per class: the eight transparent-sufficient renders take a substrate
   trim; C2/C8/C11/C12 take the local background-strip fallback key;
   BG-1..4 are never keyed and stay opaque with no alpha.
3. Crop-to-master runs on the crop-route classes (C1/C2/C4/C5/C6/C9 **plus
   C3/C10** per G1's deviation): smallest centred rectangle at the master
   aspect containing the ink box in full; a rectangle that would exceed the
   returned frame is a FAIL in the report, never a clip. C7/C8/C11/C12 skip
   the crop (their frame is the master; C8's 40/48/56 cuts derive at use from
   its 112 master). BG-1..4 take the 1765:753 crop + 2 px trim.
4. Every landed PNG is exactly its §13.1 master pixels, resized with ONE
   uniform scale factor (no per-axis skew).
5. The center check runs `--apply` on every sprite cut (BG-1..4 exempt — they
   are full-bleed covers).
6. Ink-box containment ≥ 95 % is computed and reported per cut.
7. The §15.3 margins are measured from each cut's own rivet/bevel band and
   reported measured-vs-declared per class (±1 px is a pass).
8. The §13.5 uniform-band check passes on C7/C11/C12 (each edge band identical
   along its run); a failing class falls back to its shipped art and the route
   is reported — never hand-retouched.
9. Landing: `vajb-orbit/assets/ui/` at the §13.4 stems; every stem that
   collides with a shipped file (`ui_armory_console`, `ui_slot_weapon`,
   `ui_slot_cargo`, `ui_slot_inventory`, `ui_bar_caps`, `ui_minimap_bezel`,
   `ui_panel_frame`) first moves the shipped original into
   `asset-library/_prekey_backup/chrome_family_2026-10-05/` (the reversal
   store) and records the swap pair. New PNGs copy a neighbouring landed
   `assets/ui/` texture's `.import` stanza (the editor reimport runs at
   close-out).
10. State-variant spend respects §15.5 ruling 4: zero variants unless
    cut-stage QC proves modulate cannot carry a state of C1/C2/C3/C4/C8/C9;
    then ≤ 1 per failing class with the closed `_pressed`/`_hover`/`_disabled`
    suffix, ≤ 6 runs and ≤ $0.30 total, each with class, cause and cost.
11. One contact sheet at
    `asset-library/_review/chrome_family_cuts_2026-10-05.png` — every landed
    cut labelled class + stem + pixels + measured margins.
12. `D21-G2_report.md` answers this list item by item with cites.

## Hard constraints

- File set: `asset-library/,vajb-orbit/assets/ui/,.agents/gen/slices/D21-chrome-family/`
  (the dispatch sets `VAJB_WORKER_FILES` to exactly this; trailing slashes are
  load-bearing).
- Do not touch: `docs/`, `docs/archive/` (sealed), `addons/`, `vajb-orbit/`
  outside `assets/ui/`, `staging/compare/` (the owner's scratch), other
  workers' files.
- Never hand-edit a PNG — keying, cropping, resizing and centering happen
  through scripts (the batch-driver law). A scripted key failure is a finding
  with a one-line reversal (`recraft/remove-background` is a rescue tool only).
- Every run bounded; never leave a command in the background.
- Paid calls only inside ruling 4's ceiling (≤ 6 runs, ≤ $0.30) — and zero if
  QC demands none. Generator for any such run:
  `gpt-image-2-5-flare-text-to-image` via `$KIE_GENERATE` (`--dry-run` first,
  `--yes` past the guard).

## Tests that move

None — asset lane. No code, no gate rows. The gate runs unchanged at close-out
(×2 fresh scratch) purely as a sanity check.

## Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| D21-G2 | builder (cut/key/land driver) | `asset-library/,vajb-orbit/assets/ui/,.agents/gen/slices/D21-chrome-family/` | the landed family + swap/backup record + `D21-G2_report.md` |
| D21-G2-R1 | reviewer (mandatory) | `asset-library/,.agents/gen/slices/D21-chrome-family/` | `D21-G2-R1_review.md` (verdict + fix list) |
| D21-G2-F1 | fixer (only if R1 leaves HIGH/MED) | same as D21-G2 | `D21-G2-F1_report.md` |

## Run order

`git tag g2_start` + `verify_wave.py snapshot --name g2_start` + the briefs
commit → D21-G2 → D21-G2-R1 → F1 only on HIGH/MED → close-out → the owner's
eyeball on the cut contact sheet gates S36's dispatch.

## Staged / deferred

- State variants: deferred (ruling 4) — bought only where cut-stage QC proves
  modulate cannot carry a state.
- All wiring is S36's (StyleBoxTexture per class, BG-1..4 backdrop nodes,
  keep-list enforcement, the chrome-census regression suite).
- Digit QC does not run (no `ui_seg_*` re-cut, §13.5).

## Owner tick list (the rulings this run implements)

- 2026-10-05 keep/swap map (`S36_proposal.md`): only stretched surfaces swap.
- 2026-10-05 call 1: drawer entries swap onto C9 (272×56, T-135's decided
  target) — you land the plate; the wiring is S36's.
- 2026-10-05 call 4: variants wait for QC (this run's spending law).
- T-131 decided: 4 backdrops as proposed (BG-1..4 land).
- T-135 decided: the measured 272×56 is C9's target.

## Close-out (the orchestrator — `D21-G2_prompts.md` carries the commands)

Reimport the landed PNGs (godot-ai `filesystem_manage reimport`) →
`staging/phase_d/build_catalog.py` (regenerate `ASSET_CATALOG.md`) → gate ×2
fresh scratch + `verify_wave.py verify --baseline g2_start` →
`staging/build_code_map.py` → TICKS / WAVEBOARD / `MASTER_REPORT.md` §6 →
wave-boundary commit → hand the owner the cut contact sheet.

## Reversal

Per cut: re-crop, re-key, or fall back to that class's shipped art. Whole
pass: the family retires, the keep-list grows to "keep everything shipped",
and the renders stay in `asset-library/raw/` (`S36_proposal.md`'s standing
reversal). Every swapped shipped file is recoverable from
`asset-library/_prekey_backup/chrome_family_2026-10-05/`.
