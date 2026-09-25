# D13 — Armory rework, the design wave (brief)

**Wave:** D13 (design lane, item 14 of `dispatch_designer.md`)
**Slice folder:** `.agents/gen/slices/D13-armory-rework/`
**Baseline:** gate **866/0 must not move** — this wave writes no code and no
docs. `python3 staging/verify_wave.py snapshot --name d13_start` before the
first dispatch.
**Owner ask (2026-09-25, verbatim):** "rework armory with vision skill and
reasoning on how it should like with brainstorming to used and mockups" — on
the 2026-09-25 ruling "armory will take a rework, ditch it for now" (the D12
fix wave and D8 item 9 were ditched for this).

## 1. The law to read, in order

1. `slices/D13-armory-rework/SLICE.md` — scope, ACs, your file-set row.
2. This brief §2 (today, measured), §3 (the audit input), §4 (the method —
   the owner mandates it), §5 (the yardstick).
3. `docs/design/STATION_HUB.md` §5.11 + its three amendments (D7 restyle
   :903, OUTFITTING→ARMORY :924, S15 hardcap :936, rework-open :945).
4. `docs/design/UI_SPEC.md` §3.9 (the instrument language) + §3.10 + its
   **Amendment 2** (the canvas pin: console 872×956, the 136-tall ammo well,
   Mockup A geometry).
5. `docs/design/STYLE_BIBLE.md` — palette, typography and the contrast/size
   floors, by section (§3 ember, §7.2 fog law for reference).
6. `docs/gameplay/09_ship_slots_modules.md` §11 (batteries v2) + §12 (the
   5×4 hardcap) — the data law. `docs/CONTRACTS.md` §17 — the panel seams.

## 2. Today, measured (the vision evidence — ground truth)

A live capture was taken 2026-09-25 by the orchestrator (the station scene
running at 1920×1080, the ARMORY mounted, a fresh profile with the standard
fit — W1 CANNON MKI in the inspector):

- `slices/D13-armory-rework/_evidence/armory_live_1920x1080.png` — the
  full-res framebuffer (1.38 MB; do not `view` it directly — the tool refuses
  images over 204800 bytes).
- `slices/D13-armory-rework/_evidence/armory_live_1100.jpg` — the viewable
  whole (85 KB). **View this first.**
- For detail, crop with PIL, never re-capture (this environment has no
  screen-capture stack — `mss` is absent and pip is blocked; do not try to
  install anything):
  `python3 -c "from PIL import Image; im=Image.open('<png>').convert('RGB'); im.crop((l,t,r,b)).save('/tmp/crop.jpg', quality=80)"`
  sized to stay under 204800 bytes. The pane's live rect is
  **(452, 214) + 1392×610** inside the station host (rail 360 wide left,
  inspector 130 tall below, footer 18) — measure the composition against
  these, they are reported, not invented.

What the pane is: the ARMORY is battery composition by drag-and-drop — five
rack bays `B1..B5` flowing **4+1** (the tail bay full-width, labels aligned
with the cockpit's five-lamp band), each bay 4 gun cells on drawn recesses
(`ui_armory_rack_plate` 194×182 at 2×, ink rows 49..132, ~34.5 px pitch, the
S15 ink-fit law), a SALVO ledge with `ui_seg_*` 3-cell seconds×100 digits; an
INVENTORY well and an AMMUNITION well of pack cards on
`ui_armory_row_plate` rows; the whole on the painted console
`ui_armory_console` (1744×1912 master). The shipped law: `09 §12` (5×4
hardcap, silent refusals), the §13/§16 transactions (refusals write nothing),
CONTRACTS §17.

## 3. The input — D12-A0 readability audit (2026-09-24, 1920×1080, station theme; kept verbatim because the audit report was purged with the slices)

**5 HIGH / 4 MED / 3 LOW**, every finding lane-tagged:

- **HIGH-1:** the pane's ink is 9-13 px, under every spec floor, with **12
  per-node size overrides** that escape `ui_scale`
  (`armory_panel.gd:72-75,1509-1787`; fix: the §6 scale, floor 13, sizes
  registered in `Router.FONT_SIZE_ITEMS`).
- **HIGH-2:** every `text_dim` caption sits on painted metal at **1.9-2.8:1**
  (floor 4.5:1; `ROLE_TEXT_DIM` on the console/rack/row plates).
- **HIGH-3:** the `OVER CAP` ember state tag is **1.8:1** on the row plate
  while the pack name is 12 px — the hierarchy is inverted.
- **HIGH-4:** at 1920×1080 the pane's whole AMMUNITION half sits **below the
  fold** (0 of 6 pack cards visible; 520 px / 37 % of the host empty) — the
  §3.10 Amendment 2 canvas is pinned, so the canvas itself is the owner's
  question (bucket 2/3).
- **HIGH-5:** a fitted barrel's name draws at `font_color` alpha 0 plus an
  11 px `✕` chip — the rack reads as unlabelled machined blocks.
- **MED-1:** the ammo rows draw outside their well (AmmoBox at local y -32;
  a 7th spacer row grows the group 64 px the block's arithmetic never sees).
- **MED-2:** one card mixes rounds and units (`300 ROUNDS PER PACK` beside
  `HELD 60 / 30`, no unit word).
- **MED-3:** the shell strip cannot carry an item description (one 13 px
  line, min 405 px for 65 chars; a description needs a 3-line ~57 px strip —
  or belongs in the pane).
- **MED-4:** `SALVO s` sits ~59 px from its drum digits and the state line
  that says `SALVO 0.6 s` is at alpha 0.
- **LOW-1:** the empty-rack drop cue is clipped 8 px at 9 px.
- **LOW-2:** the pane's key hints are honest; a recorded check — do not
  "fix" them.
- **LOW-3:** the pane footer and the shell's StatusLabel do the same caption
  job 950 px apart.
- **Plus LOW L208** (LOW_BACKLOG): the bay's `B<n>`/`(i)` head and empty-bay
  cue print above the plate's ink — `_position_head` puts the label at drawn
  y 8..56 while `ui_armory_rack_plate`'s bar starts at row 49.

S15's close already cured the plate-fit ink defect (route = ink layout).

## 4. The method (the owner mandates this exact process)

1. **Vision first.** View `armory_live_1100.jpg`; crop the pane, a bay, the
   ammo half and the shell strip from the PNG per §2. Judge the composition
   from the capture and the audit numbers together — never from memory of
   similar UIs.
2. **Brainstorming.** Read
   `~/.local/share/crush/skills/brainstorming/SKILL.md` by path and run its
   **architectural** path, adapted to a dispatched worker: there is no
   dialogue partner — the owner's tick list IS the approval gate, and the
   HARD GATE maps to *this wave produces design only, zero code*. Explore
   the context (§2/§3), then present **2-3 approaches with explicit
   trade-offs** (what each does to the fold, the ink, the hierarchy, the
   canvas pin), then recommend one with reasons.
3. **Reasoning on how it should look.** The report carries the design
   reasoning: what the pane is for (compose five batteries, read ammo and
   salvo state, fit/remove barrels), what today fails at (per finding), what
   the reworked hierarchy is, and why — every decision with its reason.
4. **Mockups.** Write `staging/mockup/armory_mockup_v2.py` (the
   `station_mockup.py`/`mockup_rest.py` precedent: PIL, geometry + palette
   as the source of truth, no paid calls, deterministic output) and render
   **one 1920×1080 mockup per approach** into `staging/mockup/out/`, plus
   one owner sheet (mockups + the tick list as text). Compose the pane at
   its live host rect unless the approach itself proposes a different host
   geometry (then PROPOSED, §5).

## 5. The yardstick (constraints — the review diffs against these)

- **Medium:** Godot 4.7 `Control` UI with painted plate art and code-drawn
  treatments — no CSS idiom, no web pattern that the engine cannot draw.
- **Data model fixed:** five batteries × 4 cells, the pack cards, salvo
  readouts, the §13/§16 transactions, CONTRACTS §17 seams. The design
  reorganizes *presentation*, never the seams; a dropped datum is HIGH.
- **Style:** palette and typography from STYLE_BIBLE only; text ink ≥ 13 px,
  `text_dim` contrast ≥ 4.5:1, colour never the sole carrier of state (the
  audit's own floors).
- **The canvas pin** (UI_SPEC §3.10 Amendment 2: console 872×956, the
  136-tall ammo well, the 1392×610 host) is **bucket 3**: you may propose
  changing it, marked PROPOSED with its reversal — never assume it moved.
- **Zero writes outside your file set:** no `vajb-orbit/`, no `docs/` — the
  proposal rides the report; the ticked values land in the docs at the next
  boundary. A number you cannot derive from the pinned inputs is written
  PROPOSED with its reversal, never invented.

## 6. Output contract

Report `slices/D13-armory-rework/D13-A0_report.md` (REPORT template, ≤120
lines): the "today" reading (grounded in the capture), the approach set with
trade-offs, the recommended design in sections (layout, hierarchy, states,
ink, palette use, host geometry), every PROPOSED value with its reversal, the
owner tick list (binary, answerable), and the mockup file paths.

## 7. Skills

`~/.local/share/crush/skills/brainstorming/SKILL.md` (mandated, §4.2). Godot
idiom, if needed to keep proposals engine-drawable:
`~/.local/share/crush/additional-skills/godot/godot-ui/SKILL.md` and
`godot-ui-theming` under the same root, read by path.

## 8. Run order and close-out (the orchestrator)

**A0 → R1 → (F1 only on HIGH/MED).** R1 re-derives: re-renders every mockup
byte-identically from the committed script, checks each audit finding is
addressed-or-deferred with a reason, checks the yardstick §5 (data model,
floors, no CSS idiom, PROPOSED-with-reversal discipline), and writes
`D13-R1_review.md` (REVIEW template, ≤150 lines; findings `D13-A0/F##`).
Close-out: gate once (**866/0 unmoved**),
`python3 staging/verify_wave.py verify --baseline d13_start --forbidden
vajb-orbit/ docs/ --expect-reports .agents/gen/slices/D13-armory-rework/D13-A0_report.md
.agents/gen/slices/D13-armory-rework/D13-R1_review.md`, WAVEBOARD +
`dispatch_designer.md` one-liners, MASTER_REPORT §6 recap, wave-boundary
commit — then the mockups and the tick list go to the owner. The
implementation wave is briefed only on the owner's ticks.
