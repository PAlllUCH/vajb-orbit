# VOTE_SITE_SPEC — the release-voting website

**Status:** spec 2026-10-07, approved in session (owner "go" after the design
round). Owner of this document: the owner. It governs a **separate repository**,
not the game code; the game repo's only change is one `.gitignore` line plus
this file.

## 1. Purpose and scope

A public static site where the community votes on what the next Vajb Orbit
release ships. Votes are GitHub 👍 reactions on one issue per candidate in the
site's repo; the site renders the curated candidate list and live counts.

It is **not**: a backend, an account system, a tracking surface, a build
project, or any change to game code. No framework, no package manager, no CI.

## 2. Repos and placement

- New public repo **`PAlllUCH/vajb-orbit-site`** (name confirmable at creation;
  see §12 ticks). Scaffolded locally at `$VAJB_WORKSPACE/vajb-orbit-site/` so
  the workspace mirror covers it; it is its own git repo with its own GitHub
  remote. The game repo gains exactly one line in `.gitignore`:
  `vajb-orbit-site/`.
- GitHub Pages serves from the repo root on `main`. The owner enables Pages
  once in repo settings (Deploy from branch, `main`, root); every push then
  deploys automatically.
- Voting issues live in the **site repo**, so the game repo's tracker stays for
  development.

## 3. Architecture and file tree

Vanilla static files only:

```
index.html
assets/style.css
assets/site.js
data/candidates.json
.github/ISSUE_TEMPLATE/candidate.md
LICENSE
README.md
```

`data/candidates.json` is the single curation surface. `assets/site.js` renders
the page from it at load, fetches live counts, and degrades to the manifest's
cached numbers. No server-side anything.

## 4. Data model

```json
{
  "cycle": 1,
  "cycle_name": "Next content release",
  "cycle_note": "One line shown under the title.",
  "repo": "PAlllUCH/vajb-orbit-site",
  "updated": "2026-10-07",
  "candidates": [
    {
      "slug": "world-identity",
      "title": "World identity",
      "blurb": "One sentence, plain language.",
      "status": "planned",
      "issue": 1,
      "votes_cached": 0,
      "updated": "2026-10-07"
    }
  ]
}
```

Field law:

- `status` is one of `planned | in-progress | shipped`. `shipped` candidates
  leave the vote grid and render in a "Shipped" strip (the release history),
  newest first by their `updated` date. `in-progress` renders in the grid with
  its status chip; its vote link stays live and it keeps taking votes.
- `votes_cached` is the last measured 👍 count; it is refreshed by the curation
  pass (§7), never by hand-guessing.
- `slug` is unique, kebab-case, and anchors the panel's DOM id.
- `issue` is `null` until the candidate's GitHub issue exists (the panel then
  renders without a Vote link); once created it is a positive integer.
  *(Amendment 2026-10-07 during implementation: the original text required a
  positive integer unconditionally, which the seed manifest cannot satisfy
  before the first issue pass.)*
- The client validates the shape at load (required keys present, `status` in
  the set above, `issue` a positive integer or `null`, unique `slug`). A
  malformed manifest renders an explicit error state naming the problem —
  never a blank page.

## 5. Voting mechanics

- One GitHub issue per candidate, title `[Candidate] <title>`, labeled
  `vote-candidate`, body from the template (What ships / Why it matters /
  Source doc). The template ships at
  `.github/ISSUE_TEMPLATE/candidate.md`; the label is created once by hand.
- A vote is a 👍 (`+1`) reaction on the issue's opening post. One vote per
  GitHub account; GitHub carries the anti-abuse burden. Comments may stay open
  for discussion; the owner may lock an issue without affecting reactions.
- **Counting rule:** the client counts `reactions["+1"]` only — never
  `reactions.total_count`, which lumps in every reaction type (heart, laugh,
  downvote) and would inflate the standings.

## 6. Live counts

- Exactly **one** API call per page load:
  `GET https://api.github.com/repos/<repo>/issues?labels=vote-candidate&state=all&per_page=100`
  (unauthenticated; the core limit is 60 requests/hour per IP, and the issues
  list includes each issue's `reactions` object). The client matches issues to
  manifest entries by `issue` number and upgrades the cached counts.
- Until the fetch resolves, panels render with `votes_cached`. On any failure
  (throttle, offline, API change) the cached numbers stand and a quiet footer
  note says counts are cached. The page never blocks on the API and never
  shows fabricated zeros over non-zero reality.
- Sorting: panels render in manifest order first; after the first successful
  fetch they are sorted once by live count, descending. No further re-sorting
  while the page is open. The current leader's panel carries an accent edge.
- Vote counts on the page are a snapshot, not a live poll; the manifest's
  `updated` date is shown next to the cycle name.

## 7. Per-cycle curation workflow

1. Pick 8–12 candidates from the roadmap docs (the live queue and
   `docs/gameplay/`).
2. Create one issue per candidate from the template; note each issue number.
3. Update `data/candidates.json`: bump `cycle`, replace the list, set the
   previous cycle's outcome (`in-progress` if picked, `planned` rolls over),
   refresh `votes_cached` from the issues pages, commit.
4. Push. Pages deploys. Decision rule shown on the page: **top-voted candidate
   when the owner cuts the cycle is what ships next.**

## 8. Visual system

Palette — copied verbatim from `docs/design/STYLE_BIBLE.md` §2 (CSS custom
properties; no other hexes on the page):

| Token | Hex | Use on the site |
|---|---|---|
| Void Black | `#0A0E14` | page background |
| Deep Void Blue | `#111823` | section background wash |
| Panel Black | `#15181D` | panel background |
| Panel Steel | `#2A2E35` | panel borders, dividers, button bodies |
| Steel Highlight | `#565C63` | hover edges |
| Ash Text | `#8D939B` | body text |
| Bone Text | `#C9CDD2` | headings, key values |
| Burnt Ember | `#C8461B` | the one accent: leader edge, status emphasis |
| Ember Glow | `#E8703A` | accent hover/glow only |

Panel law follows the game's theme rules (IMPLEMENTATION_PLAN §3.2): corner
radius **0**, border width **1 px**, flat fills — no gradients on chrome. Typography:
**Oxanium** (headings), **Rajdhani** (body), **Saira Stencil One** (the cycle
stamp / flavour line) — the same three OFL faces the game adopted
(IMPLEMENTATION_PLAN §9.8 item 2), loaded from the Google Fonts CDN with a
system-stack fallback; no font files are bundled. **PROPOSED** (reversal:
owner tick): a faint CSS grain/vignette overlay on the background to carry
STYLE_BIBLE's film-grain principle without shipping a binary texture.

Layout: header (title lockup text-only, cycle name + note), the vote grid
(single column on mobile, two columns ≥ 720 px, three ≥ 1100 px), the Shipped
strip, a "How voting works" footer. Every interactive element has a visible
focus state; vote links carry an aria-label ("Vote for X on GitHub");
`prefers-reduced-motion` disables all transitions.

## 9. Seed candidate list (cycle 1)

Drawn from the live queue (WAVEBOARD §Queued) and the gameplay docs; all enter
as `status: planned` and the owner may prune or reword before the issues are
created. Source doc cited per row.

| Slug | Title | Source |
|---|---|---|
| `world-identity` | World identity (S24) | WAVEBOARD queue; `slices/S24-world-identity/` |
| `contracts-board` | Contracts board (S25) | WAVEBOARD queue |
| `bosses-arenas` | Bosses, arenas, insurance, vaults (S26) | WAVEBOARD queue |
| `catalog-shipyard` | Catalog breadth & shipyard (S27) | WAVEBOARD queue |
| `galactic-map` | Galactic map travel | `docs/gameplay/11_galactic_map.md` |
| `factions` | Factions and standing | `docs/gameplay/12_factions.md` |
| `heat-bounty` | Heat and bounty system | `docs/gameplay/13_heat_bounty.md` |
| `crafting` | Crafting from components | `docs/gameplay/07_crafting.md` |
| `refinery` | Refinery chain | `docs/gameplay/04_refinery.md` |
| `exchange` | Player exchange / market | `docs/gameplay/05_exchange.md` |

## 10. Verification

- Serve locally (`python3 -m http.server` in the repo) and check: manifest
  renders; live fetch against the real repo once issues exist upgrades counts;
  network blocked (devtools offline) falls back to cached counts with the
  footer note; malformed JSON (temporarily edit a key) shows the error state.
- Layout checked at 360, 720 and 1100 px widths; focus states tabbed through;
  reduced-motion honoured.
- Lighthouse not gated; the page is one HTML file, one CSS file, one JS file.

## 11. Explicitly out of scope

Accounts, backends, cookies, analytics, build tooling, server-side rendering,
per-option ranking (single votes only), vote buying prevention beyond GitHub's
own controls, localization.

## 12. Owner ticks

- [x] Confirm the repo name (`vajb-orbit-site`) — created 2026-10-07.
- [x] Create the repo and enable Pages (Deploy from branch, `main`, root) —
      live at https://pallluch.github.io/vajb-orbit-site/.
- [ ] Choose the site repo's LICENSE (the game repo carries none in-repo; the
      site needs an explicit one for a public page).
- [x] Confirm or prune the cycle-1 seed list (§9) — created as issues #1–#10.
- [ ] Confirm the PROPOSED grain overlay (§8).
