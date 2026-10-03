# Changelog

Player-facing history of Vajb Orbit. Versions are the numbers shown on the
main menu; each entry summarizes what changed for a player, drawn from the
wave history in `.agents/gen/MASTER_REPORT.md` §6.

## 0.3 — the content & feel push (2026-09-27 → 2026-10-03, playtest-2 cycle)

- **Flight feel:** every landed hit reads — hit flashes, kick, damage numbers
  and de-flammed audio; the feel sheet's twenty-five rows landed across the
  wave.
- **Asteroids are real objects:** rocks take location-by-location punishment,
  shed splinter children when broken, leave a core layer on partial cleaves,
  and splash damage is billed by the last hit.
- **Inertia and mass:** hulls coast with class-derived thrust and turn forces,
  fuel is billed by thrust, and asteroids carry real weight — they drift,
  collide and shove each other.
- **Weapons cadence split:** the spam tier (laser/plasma/cannon) fires as
  before; the heavy tier fires one shot and cools — railgun 15 s, rocket 12 s,
  mine 10 s — with the cooldown as the barrel's cadence, the HUD counting the
  selected rack down and the armory SALVO drum reading 10–15 s figures.
- **Dead content lives:** the exclusive module families fire under the cadence
  law, the three dead module effects work, the sibelon joins the corvette
  spawn column, interceptor and turret hull rows spawn, per-hull V3 ladder
  sprites and loot rows land, and the dev menu gains a credits toggle.
- **Auction house:** every restock draws ten extra tier-I listings, and a
  listing's hover inspector now carries the item's full stat block after its
  description.
- **Station UI design law (design only — implementation follows in the next
  waves):** the contracts board, insurance and vaults panel specs, and the
  nine docking places' identity treatment are pinned for the world-identity
  and contracts waves.
- **Stability:** the first playtest's defect pile cleared before the push.

## 0.2 — first playable (2026-09-20 → 2026-09-26)

- **Engine:** the hull flies on real physics with the reactor chain powering
  it; shields and then directional armour (four hull pools, rear-arc
  vulnerability, breach malfunctions until repaired).
- **Combat:** weapons, NPC ships and death work end to end; sectors spawn
  their traffic and point-of-interest loot.
- **World:** sectors connected by gates, asteroid fields to mine, the
  20-minute station clock driving exchange bands and respawns.
- **Economy:** the exchange, the refinery's conversion loop, the auction
  house and the credits wallet.
- **The station:** a dockable hub with ARMORY, REFINERY, EXCHANGE, AUCTION,
  SHIPYARD, FITTING and REPAIRS modules; the armory reworked onto the flat
  per-surface chrome law.
- **Cockpit and HUD:** the instruments and cockpit rework, and the icon set
  unified onto SVG masters.
