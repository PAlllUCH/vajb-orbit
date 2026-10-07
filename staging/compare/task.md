# Design task — the BOUNTY BOARD (station-hub module, screen design spec)

You are a senior game UI designer. Produce a complete, coder-ready screen design
spec for a NEW station-hub module in the game Vajb Orbit. This spec is your
deliverable; write it as one self-contained markdown file. It is a design spec
only: no code, no scene files. The implementing coder has NOT read any other
document, so everything they need must be in your spec.

## 1. Game context (facts you must respect)

- Vajb Orbit is a 2D top-down space shooter with an RPG/economy layer
  (Dark Orbit-like), built in Godot 4.7.2. Every screen is 2D Control UI.
- Base render target 1920x1080, stretch canvas_items, aspect expand.
- The station hub screen is a **persistent module rail plus a single module
  host**: a 360 px wide rail (PanelContainer) with numbered station entries
  plus LOG OUT below a spacer, and one framed console host panel where the
  active module draws its content. There are no tabs and no nested pages.
- Existing modules (rail entries 1-7): OUTFITTING, REFINERY, EXCHANGE,
  SHIPYARD, FITTING, REPAIRS, LAUNCH. LOG OUT sits in the session group below
  the spacer. Module cycling: mouse, PageUp/PageDown from anywhere in the
  host, gamepad shoulder buttons, Tab/Shift+Tab focus walk.
- Label style: ALL CAPS. Copy is English, terse, terminal-flavoured
  (e.g. `ARMED · PRESS LAUNCH AGAIN WITHIN 3 s TO UNDOCK`).
- Escape (ui_cancel) never leaves the station by itself; it closes overlays,
  disarms armed controls, then moves focus back toward the rail.

## 2. The systems your screen serves (numbers are law — do not change them)

The game has a per-faction HEAT system (doc: docs/gameplay/13_heat_bounty.md,
you may read it for nuance; the numbers below are the contract):

- Heat is 0-100 per faction. Crimes: kill trader +15, kill patrol +25, kill
  station turret +25, surviving witness +5 extra. Decay -1 per minute of play.
- Heat tiers: Clean 0-19, Suspect 20-49, Wanted 50-79, Outlaw 80-100.
  Wanted spawns bounty hunter wings on sector entry; Outlaw is denied docking
  and gate use (so an Outlaw can NEVER see your screen — they cannot dock).
- Killing a pirate in faction X's space: +1 standing with X, -3 heat with X.
- Paying the bounty at a station: fine = heat x 25 CR (40 heat = 1 000 CR),
  zeroes heat instantly. A `PAY BOUNTY (n CR)` row already exists in the
  LAUNCH module for the docked station's faction.
- Three named factions exist: Concord, Meridian, the Choir. Pirates are
  factionless enemies that do not respect borders. Standing and heat are two
  separate dials on the same relationship.
- Economy scale: a typical play session nets about 1 200 CR. Contract payouts
  must fit this economy; if you price anything, derive it from these numbers
  and say how.

## 3. The task

Design the **BOUNTY BOARD**: a new module in the station hub where the player
takes on combat contracts — consistent with the systems above (pirate-hunting
contracts, per-faction politics, heat interplay). You decide the exact
contract model (pricing, duration, tracking, completion credit) and you must
state every number you choose, with one line of reasoning each. You also
decide how an eighth rail entry integrates with the existing rail (the rail
was measured for seven 56 px entries in a 769 px content box — address the
fit), or argue for a different integration if you can justify it.

Your spec must cover, at minimum:

1. Screen composition: regions, container plan, measured boxes at 1920x1080,
   and how the module fills the host panel. State explicit px numbers.
2. Information design: what one contract row/list entry shows, what the detail
   view shows, and the full data contract (field names + types) a coder wires.
3. The contract lifecycle: browse, filter/sort (your call), accept (with
   confirm if needed), track active contracts, complete, fail/expire, abandon
   (if allowed). Include the player's own heat/standing context if relevant.
4. ALL UI states: empty list, no active contracts, active contract(s),
   confirm overlay, cannot-afford or locked state, filtering to zero results,
   and any danger-state presentation of the player's own heat (ember accent
   usage is semantic, not decorative).
5. Input: full keyboard focus order, gamepad mapping, mouse behaviour,
   Escape behaviour within the module.
6. Motion: entry/exit, hover/selection, row appear, any pulse — durations and
   easings, keeping in mind the hub's motion table (you may read
   docs/design/STATION_HUB.md section 9 for the house style).
7. Audio hooks: one line per state change that should make sound.
8. Acceptance criteria: 5-10 concrete, testable statements a coder or reviewer
   can verify.
9. A "numbers the coder needs" table: every size, spacing, duration, colour
   name and copy string, as an explicit list. Text strings in ALL CAPS.

## 4. Hard visual law (violate any of these and the spec fails)

The palette is fixed at 16 colours — pick from these, never invent tones:

| Hex | Name | Use |
|-----|------|-----|
| #3A3F46 | Gunmetal Mid | primary hull/metal |
| #2B2F35 | Gunmetal Dark | hull shadow |
| #232629 | Iron Black | deepest shadow |
| #565C63 | Steel Highlight | rim-lit edges |
| #6E5B4A | Rusted Ochre | rust patches |
| #8A6A50 | Dry Rust | rust streaks |
| #4A423B | Grimy Umber | grime washes |
| #0A0E14 | Void Black | deep space base |
| #111823 | Deep Void Blue | starfield wash |
| #1A2230 | Void Haze | mid-depth background |
| #C8461B | Burnt Ember | THE danger accent: warnings, hostile markers, critical values |
| #E8703A | Ember Glow | emissive rim of the accent |
| #15181D | Panel Black | UI panel backgrounds, HUD trays |
| #2A2E35 | Panel Steel | panel borders, button bodies, dividers |
| #8D939B | Ash Text | body text, inactive labels |
| #C9CDD2 | Bone Text | headings, key values, focused labels |

- Panel backgrounds Panel Black with 1 px Panel Steel borders, subtle inner
  shadow, slightly bevelled corners, never glossy or rounded-friendly.
- Body text Ash Text, headings/key values Bone Text.
- Burnt Ember is the ONLY colour permitted in UI, and only for warnings,
  hostile indicators and critical values — never decoration. Hover/selection
  brightens borders to Ash Text, not to the accent. (Menu-level buttons may
  carry a 6 px Ember Glow bloom on hover — sanctioned; in-screen hover stays
  border-brighten only.)
- Style name: grimdark painted sci-fi. Tired, scarred, maintained by
  necessity. No chrome shine, no neon optimism, no second accent colour.

## 5. Reference reading (optional, identical for any author)

You MAY read for house style and precision: docs/design/STYLE_BIBLE.md,
docs/design/STATION_HUB.md, docs/design/UI_SPEC.md,
docs/gameplay/13_heat_bounty.md. Nothing you read may contradict the numbers
in this brief; if you spot a conflict, follow this brief and flag it in a
short "conflicts" note.

## 6. Quality bar

- Complete but information-dense. No filler, no restating this brief, no
  history or preamble. Every claim actionable. Every number stated once,
  clearly.
- Consistency beats flash: a coder must be able to implement your spec
  without asking you anything.
- Write the deliverable file now, then stop.
