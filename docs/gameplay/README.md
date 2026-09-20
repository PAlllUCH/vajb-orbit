# Vajb Orbit — Gameplay Systems

Design documents for the RPG layer of Vajb Orbit (economy, resources, trading,
crafting). Each document is an engine file: a coder reads one document top to
bottom and implements exactly what it says. No document here contains code.

## How to read these documents

- **Authoritative data wins.** Where a document states a number (price,
  quantity, rate), that number is the specification. Coders do not invent
  values; designers amend the documents instead.
- **Order of implementation** follows the numbering below, with the phase
  plan in `17_coder_handoff.md`. Later documents depend on earlier ones.
- **Existing contracts are law.** These documents extend, never contradict,
  the frozen contracts in `docs/design/STATION_SPEC.md` (PlayerProfile cargo
  manifest, StationCatalog price scale) and `docs/design/STATION_HUB.md`
  (station as the single spend screen). Any conflict is resolved in favour of
  the older spec, and this folder must be amended.
- **Review stamp (2026-09-18):** full cross-document reconciliation pass
  done — session ledger (01 §5) now matches the final 02 price table, the
  refinery runs 3:1 at a +20 % bonus (02/04), insurance is a flat per-class
  premium (14 §3), and shipyard recipes are ore-denominated (10 §3).
- **Resolution stamp (2026-09-18):** icon production standard is the
  16/48/96/192 quartet from retained masters (`ICONS_SPEC.md` §9) so the UI
  holds from 720p to 4K at ×2.5 physical; the art fix pass is briefed in
  `16_art_design_brief.md` §P0.5 (re-cuts, `data_core_16` redraw, frame
  regeneration, fringe cleanup) and coder consumption rules live in
  `17_coder_handoff.md` §2.1.

## Reading order

| # | Document | Scope | Status |
|---|----------|-------|--------|
| 01 | `01_economy_core.md` | Credits, sources, sinks, balance targets, persistence | Ready to code |
| 02 | `02_minerals.md` | The 20-mineral catalogue: tiers, values, rarity, asteroid generation | Ready to code |
| 03 | `03_components.md` | The component catalogue: tiers, sources, drop rules | Ready to code |
| 04 | `04_refinery.md` | Ore refining at the station, yield formulas, refinement choice | Ready to code |
| 05 | `05_exchange.md` | Minerals exchange: dynamic pricing, buy/sell spread, UI contract | Ready to code |
| 06 | `06_loot_drops.md` | Enemy loot tables, wreck drops, drop-rate data | Ready to code |
| 07 | `07_crafting.md` | Component-based crafting (later phase; design now, do not code yet) | Design only — not for coding |
| 08 | `08_ship_classes.md` | Ship classes from the asset roster, progression ladder | Ready to code |
| 09 | `09_ship_slots_modules.md` | Eclipse-style slot grids, module catalogue, power budget, fits | Ready to code |
| 10 | `10_ship_acquisition.md` | Auction house (credits) vs shipyard build (materials + credits) | Ready to code |
| 11 | `11_galactic_map.md` | 7 sectors, jump gates, corridors, anomalies, derelicts | Ready to code |
| 12 | `12_factions.md` | 3 factions, per-faction economies, standing | Ready to code |
| 13 | `13_heat_bounty.md` | Crime heat, bounty hunters, pirates, redemption | Ready to code |
| 14 | `14_station_services.md` | Contracts, insurance, storage rental, boss arenas, escorts | Ready to code |
| 15 | `15_module_affixes.md` | ARPG rarity: common/magic/rare affixes, faction exclusives | Ready to code |
| 16 | `16_art_design_brief.md` | Every asset deliverable the gameplay docs imply, prioritised | Ready to work |
| 17 | `17_coder_handoff.md` | Build order, file map, persistence, test checklist | Ready to code |

## One-paragraph summary of the loop

The player mines asteroids for raw ore (02), refines ore into ingots at the
station refinery (04), sells ingots on the minerals exchange for credits (05),
and fights enemies for components and salvage (03, 06). Credits and materials
buy ships and modules: hulls come from the auction house (credits) or the
shipyard (materials + credits labour), and every hull is an Eclipse-style
slot grid — engine and reactor mandatory, weapons, shields, armour,
computers, boosters and utility are the player's build (08, 09, 10). Space
itself is a 7-sector map owned by three factions (11, 12): jump gates or
hand-flown corridors between sectors, anomalies and derelicts to scan,
boss arenas under contract, and a heat system that sends bounty hunters
after anyone who shoots the wrong hull (13, 14). Modules drop with ARPG
affixes — common, magic, rare — and proton missiles only exist where the
Ember Choir sells them (15). Components bank toward the future crafting
system (07). Credits are the only currency; every number in every document
is denominated in them.
