# D23 — station panel design audit (brief)

**Slice:** `.agents/gen/slices/D23-panel-audit/` (design lane; a one-worker audit,
not a wave — no code changes, no docs changes).
**Worker:** `D23-R1`, a **visual / UI designer** audit pass on the station panels.
**Model:** `hyper/glm-5.3-flash` at `--reasoning-effort high` (the standing
audit/reviewer assignment; the owner named the model and the level).
**Owner request (verbatim):** "Spawn once again the GLM5-3 flash on high reviewer
and make sure that he takes a role of visual designer/ui designer and has to
review panels and give back results."

**Deliverable:** `.agents/gen/slices/D23-panel-audit/D23-R1_audit.md`.

## 1. Your role and what this is

You are a **visual designer / UI designer** doing an independent design audit of
the game's station screen. You are NOT re-running the S40 contrast measurement
(that is done and recorded) and you are NOT a code reviewer. You are judging the
**visual design and composition**: hierarchy, grouping, alignment, spacing and
rhythm, density, balance, focal order, colour role discipline, affordances and
affordance clarity, and cross-panel consistency — the things a player feels
before they read a word.

Be opinionated and specific. "The panel is fine" is not a finding; "the header
band and the value column share no left edge, so the eye zigzags" is.

## 2. The medium and the audience

- **Medium: canvas / game-engine UI, not the web.** This is Godot 4 Control UI
  (containers, anchors, theme styleboxes, nine-slices). Judge it with
  framework primitives in mind (rects, bands, plates, sprites, drawn marks) —
  never propose CSS, flexbox, box-shadow or web idioms.
- **Audience:** a player at a **1920×1080** station screen, mouse + keyboard,
  reading a dense trading/combat hub. Typical viewing distance: a desktop
  monitor. Colour and chrome exist to frame data, not to decorate.

## 3. The law to read, in order (by range where long)

1. `docs/design/STYLE_BIBLE.md` — palette, tone, the style law.
2. `docs/design/UI_SPEC.md` — the UI composition law. Read **§3.10 Amendment 5
   (A5.1–A5.3)** in full: the owner ruling of 2026-09-26 is **containers and
   relative positioning, never coordinates** — a panel's layout is containers +
   anchors + `custom_minimum_size` + size flags; a surface's chrome is a theme
   stylebox or a sibling node, **never a `_draw` pass over content**; chrome is
   picked by the asset's own cut size (a nine-slice band only where the content
   leaves room, otherwise the flat Tokens box with a 1 px `metal_mid` border).
   The ARMORY is the worked example. Also read **§16** (the S40 legibility pass)
   and §12–§15 (the shell-v2 idiom) by range.
3. `docs/design/MENU_FLOW.md` and `docs/design/STATION_HUB.md` §19–§21 — the
   screen inventory and the shell contract.
4. The panel sources (read the `.tscn` for structure and the `.gd` for anything
   it builds in code):
   - `vajb-orbit/ui/screens/station.tscn` / `station.gd` — the deck shell, the
     module rail, the deck backdrops.
   - `vajb-orbit/ui/station/armory_panel.tscn` / `.gd` + `armory_style.gd`
     (three modes: modules, battery, fit).
   - `vajb-orbit/ui/station/refinery_panel.*`, `exchange_panel.*`,
     `auction_panel.*`, `shipyard_panel.*`, `launch_panel.*`, `overview_panel.*`,
     `contracts_panel.*` (the SERVICES deck's board), `insurance_panel.*`,
     `vaults_panel.*`.
   - `vajb-orbit/ui/theme/vajb_theme.tres` and `vajb-orbit/tools/build_theme.gd`
     — the token set. **Every hex literal lives in `build_theme.gd`**; a panel
     that hard-codes a colour is a finding.
5. `.agents/gen/slices/S40-legibility/S40_REVIEW.md` — the recorded contrast
   measurement and its remaining 34 below-AA labels. Treat it as **already-known
   data**, not as your job: do not re-derive contrast numbers, and do not
   re-file its open tickets (T-174/T-175/T-176/T-177).

## 4. The substrate: rendered panels

Ten full-resolution renders of the live station screen are on disk:

```
/tmp/vajb_review/deck0_armory.png          /tmp/vajb_review/deck5_launch.png
/tmp/vajb_review/deck0_armory_battery.png  /tmp/vajb_review/deck6_overview.png
/tmp/vajb_review/deck0_armory_fit.png      /tmp/vajb_review/deck7_services.png
/tmp/vajb_review/deck1_refinery.png        /tmp/vajb_review/deck4_shipyard.png
/tmp/vajb_review/deck2_exchange.png        /tmp/vajb_review/deck3_auction.png
```

They are **1920×1080 PNGs at 1.4–2.3 MB**, which is far over the `view` tool's
**204800-byte** limit. Before viewing, downscale one at a time to a JPEG of about
1200 px wide and quality 80 (Pillow is installed), e.g.

```
python3 -c "from PIL import Image; im=Image.open('/tmp/vajb_review/deck6_overview.png'); im.thumbnail((1200,1200)); im.convert('RGB').save('/tmp/d23_overview.jpg', quality=80)"
```

**Images are expensive** — each one costs a slot and thousands of tokens and
stays in your context. View the decks you need, **one at a time**, and act from
what you have. Do not view a file twice. If a detail is unreadable, crop from a
render you already looked at rather than viewing the whole thing again.

**If you cannot see image content at all** (the model returns no visual
information for the image), say so **explicitly and early** in your report, then
do the audit from the sources and the recorded data instead: the panel `.tscn`
structure (container nesting, anchors, size flags, separations, margins,
`custom_minimum_size`), the `.gd` layout code, the theme tokens, and S40's
measured rects. A source-level audit is still a valid deliverable — but the
report must be honest about which mode it ran in.

## 5. Acceptance list (answer every item with a cite)

- **A1 — per-deck composition.** For each of the eight decks (and the armory's
  two extra modes) state: the focal point, whether the hierarchy reads in the
  right order, whether the grouping is legible, and the single biggest visual
  problem. Cite the panel file and the region.
- **A2 — the layout law.** Flag every place a panel positions by absolute
  coordinate, draws chrome over content in a `_draw` pass, or sets a visual
  element to a layout-filler size flag (the T-160 class: a visual box that
  stretched because it carried `size_flags_vertical = 3`). Cite `file:line`.
- **A3 — the token law.** Flag every colour, size or font literal that does not
  come from the theme tokens. Cite `file:line`.
- **A4 — consistency across panels.** The station is one screen with many
  decks: report where headers, captions, value rows, buttons, gutters, list
  rows, empty states and scroll affordances differ between decks without a
  reason. Cite both sides of each mismatch.
- **A5 — affordances.** Are interactive elements obviously interactive, and
  non-interactive ones obviously not? Are hover/selected/disabled/empty states
  visually distinct? Cite the region.
- **A6 — findings table.** Every finding with an ID `D23-R1/F##`, a tier
  (**HIGH** = the player cannot use the screen or reads it wrong; **MED** = the
  design actively works against the player; **LOW** = polish), the file:line,
  one evidence line, and a **concrete** proposed change phrased in framework
  primitives (which container, which token, which size flag) — not a mood board.
- **A7 — what already works.** Name the two or three strongest pieces of
  composition on the screen, with the reason. A design audit that only lists
  faults cannot tell the owner what to protect.

## 6. Hard rules

- **No code changes, no docs changes.** Your only write is
  `.agents/gen/slices/D23-panel-audit/D23-R1_audit.md`. Scratch files (the
  downscaled JPEGs) go to `/tmp/` — produce them with `python3` through bash,
  because the `write`/`edit` tools are scoped to your report path only.
- **Name nothing you did not verify.** Every file, node, token and line number
  in the audit comes from a file you read or a render you viewed. An invented
  node name is a finding against you.
- **Do not re-file S40's open tickets** (T-174/T-175/T-176/T-177) and do not
  re-derive contrast ratios; reference S40's numbers when they support a design
  point.
- **Never leave a command in the background.** Redirect any long command's
  output to a log you then read, bound every Godot run with `--quit-after`, and
  if a command has not returned in about five minutes, kill it and continue with
  what you have.
- The report is **at most 180 lines**, exception-based and short: the per-deck
  verdicts (A1), the findings table (A6), the strengths (A7), and a one-line
  statement of which mode you ran in (visual or source-level).
