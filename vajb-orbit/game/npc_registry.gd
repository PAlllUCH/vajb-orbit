class_name NpcRegistry
extends RefCounted
## The NPC archetype registry: ENGINE_SPEC section 5's archetypes (plus ruling 24's
## three alien families), each with the hull it flies, its faction, its loot band and
## the per-sector count shape of section 13 - "NPC counts per sector (13 section 4
## density shape): S1 0-1, S2 1-2, S3 2-3, S4 3-4, S5 3-5, S6 4-6, S7 6-8, patrols only
## in owned space, one convoy per inhabited sector".
##
## Data, not logic: no nodes, no scene tree, no profile. `spawns_for` resolves the
## shape into per-sector spawn rows for the sector population code (slice-2 W5).
##
## Contract: docs/gameplay/18_engine_spec.md sections 5 and 13; docs/gameplay/13
## sections 2-5 (heat, pirates, hunters, enforcement); docs/gameplay/11 sections 1
## and 3 (owners, population targets); docs/gameplay/06 sections 3 and 4 (the loot
## bands); docs/design/STYLE_BIBLE.md section 2.5 (the alien palettes, read-only here);
## docs/design/ASSET_NAMING_SPEC.md section 1 (the `ship_<hull>[_<qualifier>][_<angle>]`
## hull law); the slice-2 brief's pinned interface item 7.
##
## **Where the numbers live.** Section 13 is the only home of the per-sector band, of
## the aggro radii and of the leash; it is transcribed once, in `HOSTILE_BAND`,
## `PATROL_PRESENCE` and the three per-sector columns the rows carry. Doc 13 section 4
## and doc 11 section 3 both point back at "13 section 4" for the same counts (the W0
## pass recorded the circular pointer as D4), so nothing is re-stated from those.
##
## **The human/alien split of a sector's hostile band is stated by no doc.** Ruling 24
## requires the alien `swarmer` to be live in slice 2 and section 13 gives one total
## band per sector, so the band is filled in `HOSTILE_FILL` order - the first filler is
## the pirate, the second the swarmer - which needs no fraction and leaves the sector's
## total exactly the section 13 figure. A different mix is an edit to that one array,
## and it is raised in the W3 report for the owner's tick. Nothing here is inferred
## from a guess: the fill is a stated rule, the sums are asserted by the test suite.
##
## **Sprite paths are swap-ready.** A row names its *hull* (`sprite_base`, the
## `ship_<hull>` token of ASSET_NAMING_SPEC section 1) and optionally whose livery it
## wears (`livery_source`); the path is built by `sprite_path`, which asks for the
## liveried file first and falls back to the plain one. Replacing or adding art changes
## no code here, and a missing file never changes behaviour (the hull flies on the
## placeholder, exactly as section 16 item 3 requires for the alien sheets).

## The group every NPC hull joins (pinned interface item 5). The sector population
## code and the brain's ship-side contact scan both read it.
const GROUP: StringName = &"npc_ship"

const UNALIGNED: StringName = &"unaligned"
const FACTION_NONE: StringName = &"none"

## The section 5 "Faction" column's two derived values: a hull that belongs to whatever
## faction owns the space it was spawned in (patrols, hunters), and one that belongs to
## the station it is bolted to (turrets).
const FACTION_SPACE_OWNER: StringName = &"space_owner"
const FACTION_STATION: StringName = &"station"
const FACTION_ARENA: StringName = &"arena"

## The world's ship sprites are bow-right side views (the player's own hull scene draws
## `ship_vanguard_side.png` at rotation 0), so an NPC hull draws its `side` view too.
const SPRITE_DIR := "res://assets/ships/"
const SPRITE_VIEW := "side"

## Doc 13 section 3's heat tiers, the four bands a player's heat falls in. The `min`
## column is doc 13's own threshold (Clean 0-19, Suspect 20-49, Wanted 50-79, Outlaw
## 80-100); everything that compares tiers compares these numbers, so no caller
## restates 20 or 80.
const HEAT_TIERS: Array[Dictionary] = [
	{&"id": &"clean", &"min": 0},
	{&"id": &"suspect", &"min": 20},
	{&"id": &"wanted", &"min": 50},
	{&"id": &"outlaw", &"min": 80},
]
const HEAT_CLEAN: StringName = &"clean"
const HEAT_SUSPECT: StringName = &"suspect"
const HEAT_WANTED: StringName = &"wanted"
const HEAT_OUTLAW: StringName = &"outlaw"

## Section 13's seven hostile bands, S1 to S7, in sector-registry order. This is the
## single home of 0-1 ... 6-8; the pirate and swarmer rows derive their own columns
## from it (`_hostile_column`), so the two can never drift from the total.
const HOSTILE_BAND: Array[Vector2i] = [
	Vector2i(0, 1),
	Vector2i(1, 2),
	Vector2i(2, 3),
	Vector2i(3, 4),
	Vector2i(3, 5),
	Vector2i(4, 6),
	Vector2i(6, 8),
]

## Who fills the band, in fill order (see the file doc). Slot 0 is present whenever the
## band's count is at least 1, slot 1 whenever it is at least 2, and so on.
const HOSTILE_FILL: Array[StringName] = [&"pirate", &"swarmer"]

## Doc 13 section 3's bounty-hunter row id, the one archetype a heat tier spawns
## (`game.gd:HUNTER_ARCHETYPE` spells the same id for the kill's loot). `hunter_spawn`,
## `hunter_hull_for` and `hunter_wing_size` are this row's helpers.
const ARCHETYPE_HUNTER: StringName = &"hunter"
## Doc 13 section 7's hull map fallback: the hull a wing flies when the player's hull is in
## no band of the row's `KEY_MEMBERS` (a hull the roster does not know).
const HUNTER_HULL_DEFAULT: StringName = &"ship_fighter"

## Doc 11 section 3's "Patrols: Concord/Meridian/Choir space only" states presence in
## owned space and no count, and section 13 repeats only the qualifier. This is the
## **proposed default** (one patrol per owned sector) that keeps owned space patrolled;
## it is not in section 13 and is raised in the W3 report rather than presented as spec.
const PATROL_PRESENCE: Vector2i = Vector2i(1, 1)

## Doc 13 section 5's convoy ("1 hauler + 1-2 fighter escorts", section 5's own trader
## row) - the one convoy doc 11 section 3 gives every inhabited sector. Both halves are
## doc numbers; the group's hauler is the row's own hull and the escorts are fighters.
const CONVOY_HAULER: StringName = &"ship_freighter"
const CONVOY_ESCORT: StringName = &"ship_fighter"
const CONVOY_ESCORTS: Vector2i = Vector2i(1, 2)

## Section 5's "On death" column, in the two currencies doc 13 section 2/4 names: heat
## with the local faction and standing. A kill's witness surcharge (+5) and the
## standing gain belong to the enforcement code (doc 13 sections 2 and 5), not to a row.
const NO_HEAT := 0
const NO_STANDING := 0

## Row keys, named once so no caller spells a string. The row is the pinned
## "archetype -> hull/tier/faction" record plus the section 5 behaviour columns.
const KEY_ID: StringName = &"id"
const KEY_FACTION: StringName = &"faction"
const KEY_HULL_ID: StringName = &"hull_id"
const KEY_SPRITE_BASE: StringName = &"sprite_base"
const KEY_LIVERY_SOURCE: StringName = &"livery_source"
const KEY_TIER: StringName = &"tier"
const KEY_LOOT_KIND: StringName = &"loot_kind"
const KEY_AGGRO_RADIUS: StringName = &"aggro_radius"
const KEY_SCAN_RADIUS: StringName = &"scan_radius"
const KEY_FLEE_HULL: StringName = &"flee_hull"
const KEY_FLEE_TIER: StringName = &"flee_tier"
const KEY_SCAN_TIER: StringName = &"scan_tier"
const KEY_ATTACK_TIER: StringName = &"attack_tier"
const KEY_HOSTILITY: StringName = &"hostility"
const KEY_STATIC: StringName = &"static"
const KEY_BLIP_KIND: StringName = &"blip_kind"
const KEY_HEAT_ON_KILL: StringName = &"heat_on_kill"
const KEY_STANDING_ON_KILL: StringName = &"standing_on_kill"
const KEY_SPAWN: StringName = &"spawn"
const KEY_SEAM: StringName = &"seam"
const KEY_DENSITY: StringName = &"density"
const KEY_GROUP_KIND: StringName = &"group_kind"
const KEY_ROLE: StringName = &"role"
const KEY_MEMBERS: StringName = &"members"
## The player hulls one `KEY_MEMBERS` entry answers for, in the hunter row (doc 13 section
## 7's hull map: "the hull map lives in `KEY_MEMBERS`"). A member without the key answers
## for every hull - the trader row's convoy members carry none and need none.
const KEY_PLAYER_HULLS: StringName = &"player_hulls"

## The resolved spawn row's own keys (`spawns_for`): the row's seed plus the sector's
## answer - the archetype id, the rolled band's bounds, the faction the hull flies for in
## this space and the sprite path it draws.
const KEY_ARCHETYPE: StringName = &"archetype"
const KEY_MIN: StringName = &"min"
const KEY_MAX: StringName = &"max"
const KEY_FACTION_ID: StringName = &"faction_id"
const KEY_SPRITE_PATH: StringName = &"sprite_path"
const ROLE_HULL: StringName = &"hull"

## Section 5's "Behaviour" column, as the brain reads it. A row's hostility is the rule
## that turns a contact into a target; `everything` is the pirate row's "engages
## anything in radius" and ruling 24's "hostile to everything", `faction_rules` is the
## patrol's "ignores Clean players; scans Suspect+; attacks Outlaws and defends faction
## ships", `on_attack` is the turret's "aggro on attack" and `none` never initiates.
const HOSTILITY_EVERYTHING: StringName = &"everything"
const HOSTILITY_FACTION_RULES: StringName = &"faction_rules"
const HOSTILITY_ON_ATTACK: StringName = &"on_attack"
const HOSTILITY_NONE: StringName = &"none"

## Where a row can be spawned. `sector` is the sector population (section 8's on-entry
## set); `station` is bolted to a station and spawns with it, not with the sector; `seam`
## is a row that exists so the interface is fixed but ships nothing - section 5's
## hunters and boss ("slice-4 seams - code the seam, ship nothing") and ruling 24's
## `sibelon` (slice 3) and `apex` (slice 4).
const SPAWN_SECTOR: StringName = &"sector"
const SPAWN_STATION: StringName = &"station"
const SPAWN_SEAM: StringName = &"seam"

const SEAM_NONE: StringName = &""
const SEAM_SLICE_3: StringName = &"slice_3"
const SEAM_SLICE_4: StringName = &"slice_4"

## Section 8's minimap blip classes: hostile (pirates, hunters, swarmers) and neutral
## (a trader's convoy). `self`/`friendly` are other owners' blips.
const BLIP_HOSTILE: StringName = &"hostile"
const BLIP_NEUTRAL: StringName = &"neutral"

## The convoy group's rows carry this so the spawner knows which rows are one convoy
## (one route, one anchor) rather than independent hulls.
const GROUP_CONVOY: StringName = &"convoy"
const GROUP_NONE: StringName = &""

## The archetype rows, filled once by `_ensure` (SectorRegistry's own pattern). Every
## public accessor goes through `_ensure`, so a reader cannot see the array empty
## whatever order the class table was built in.
static var NPCS: Array[Dictionary] = []

const SectorRegistryScript := preload("res://game/sector_registry.gd")


static func _static_init() -> void:
	_ensure()


## Idempotent: builds NPCS from the constants above plus the sector registry's owners
## and convoy column, which is where "owned space" and "inhabited sector" are owned.
static func _ensure() -> void:
	if not NPCS.is_empty():
		return
	var patrol_column := _patrol_column()
	var convoy_column := _convoy_column()
	NPCS = [
		{
			KEY_ID: &"pirate",
			KEY_FACTION: FACTION_NONE,
			KEY_HULL_ID: &"ship_fighter",
			KEY_SPRITE_BASE: &"ship_fighter",
			KEY_LIVERY_SOURCE: &"",
			KEY_TIER: 1,
			KEY_LOOT_KIND: &"fighter",
			KEY_AGGRO_RADIUS: 900.0,
			KEY_SCAN_RADIUS: 0.0,
			KEY_FLEE_HULL: 0.30,
			KEY_FLEE_TIER: &"",
			KEY_SCAN_TIER: &"",
			KEY_ATTACK_TIER: &"",
			KEY_HOSTILITY: HOSTILITY_EVERYTHING,
			KEY_STATIC: false,
			KEY_BLIP_KIND: BLIP_HOSTILE,
			KEY_HEAT_ON_KILL: -3,
			KEY_STANDING_ON_KILL: 1,
			KEY_SPAWN: SPAWN_SECTOR,
			KEY_SEAM: SEAM_NONE,
			KEY_DENSITY: _hostile_column(0),
			KEY_GROUP_KIND: GROUP_NONE,
			KEY_MEMBERS: [],
		},
		{
			KEY_ID: &"swarmer",
			KEY_FACTION: FACTION_NONE,
			## Ruling 24's alien hulls carry no 08 class row, so the swarmer flies the
			## section 13 Fighter column - the same band its loot table reuses (06
			## section 3.1 through `LootTables`' `swarmer` kind). Raised in the report.
			KEY_HULL_ID: &"ship_fighter",
			KEY_SPRITE_BASE: &"ship_swarmer",
			KEY_LIVERY_SOURCE: &"",
			KEY_TIER: 1,
			KEY_LOOT_KIND: &"swarmer",
			KEY_AGGRO_RADIUS: 900.0,
			KEY_SCAN_RADIUS: 0.0,
			KEY_FLEE_HULL: 0.30,
			KEY_FLEE_TIER: &"",
			KEY_SCAN_TIER: &"",
			KEY_ATTACK_TIER: &"",
			KEY_HOSTILITY: HOSTILITY_EVERYTHING,
			KEY_STATIC: false,
			KEY_BLIP_KIND: BLIP_HOSTILE,
			KEY_HEAT_ON_KILL: NO_HEAT,
			KEY_STANDING_ON_KILL: NO_STANDING,
			KEY_SPAWN: SPAWN_SECTOR,
			KEY_SEAM: SEAM_NONE,
			KEY_DENSITY: _hostile_column(1),
			KEY_GROUP_KIND: GROUP_NONE,
			KEY_MEMBERS: [],
		},
		{
			KEY_ID: &"patrol",
			KEY_FACTION: FACTION_SPACE_OWNER,
			KEY_HULL_ID: &"ship_patrol",
			KEY_SPRITE_BASE: &"ship_patrol",
			KEY_LIVERY_SOURCE: FACTION_SPACE_OWNER,
			KEY_TIER: 1,
			## Section 5's "On death" column: "no loot".
			KEY_LOOT_KIND: &"",
			KEY_AGGRO_RADIUS: 1000.0,
			KEY_SCAN_RADIUS: 1000.0,
			## Section 5 gives patrols no flee; they are the law, not a source of loot.
			KEY_FLEE_HULL: 0.0,
			KEY_FLEE_TIER: &"",
			KEY_SCAN_TIER: HEAT_SUSPECT,
			KEY_ATTACK_TIER: HEAT_OUTLAW,
			KEY_HOSTILITY: HOSTILITY_FACTION_RULES,
			KEY_STATIC: false,
			KEY_BLIP_KIND: BLIP_HOSTILE,
			KEY_HEAT_ON_KILL: 25,
			KEY_STANDING_ON_KILL: NO_STANDING,
			KEY_SPAWN: SPAWN_SECTOR,
			KEY_SEAM: SEAM_NONE,
			KEY_DENSITY: patrol_column,
			KEY_GROUP_KIND: GROUP_NONE,
			KEY_MEMBERS: [],
		},
		{
			KEY_ID: &"trader",
			KEY_FACTION: FACTION_NONE,
			KEY_HULL_ID: CONVOY_HAULER,
			KEY_SPRITE_BASE: CONVOY_HAULER,
			KEY_LIVERY_SOURCE: &"",
			KEY_TIER: 1,
			KEY_LOOT_KIND: &"freighter",
			## Section 5: the convoy "flies fixed route; flees from Suspect+" - it never
			## closes, so it has no aggro radius of its own.
			KEY_AGGRO_RADIUS: 0.0,
			KEY_SCAN_RADIUS: 0.0,
			KEY_FLEE_HULL: 0.0,
			KEY_FLEE_TIER: HEAT_SUSPECT,
			KEY_SCAN_TIER: &"",
			KEY_ATTACK_TIER: &"",
			KEY_HOSTILITY: HOSTILITY_NONE,
			KEY_STATIC: false,
			KEY_BLIP_KIND: BLIP_NEUTRAL,
			KEY_HEAT_ON_KILL: 15,
			KEY_STANDING_ON_KILL: NO_STANDING,
			KEY_SPAWN: SPAWN_SECTOR,
			KEY_SEAM: SEAM_NONE,
			KEY_DENSITY: convoy_column,
			KEY_GROUP_KIND: GROUP_CONVOY,
			KEY_MEMBERS: [
				{KEY_HULL_ID: CONVOY_HAULER, KEY_MIN: 1, KEY_MAX: 1, KEY_ROLE: &"hauler"},
				{
					KEY_HULL_ID: CONVOY_ESCORT,
					KEY_MIN: CONVOY_ESCORTS.x,
					KEY_MAX: CONVOY_ESCORTS.y,
					KEY_ROLE: &"escort",
				},
			],
		},
		{
			KEY_ID: &"turret",
			KEY_FACTION: FACTION_STATION,
			## 08 section 5's `ship_turret_platform` is an enemy-only hull with no class
			## row, so the turret's vitals have no snapshot to resolve; its
			## "static, high damage" behaviour ships and the class row is a doc gap the
			## W3 report raises.
			KEY_HULL_ID: &"ship_turret_platform",
			KEY_SPRITE_BASE: &"ship_turret_platform",
			KEY_LIVERY_SOURCE: FACTION_SPACE_OWNER,
			## No loot and no band: the turret rolls no 06 table (section 5's "On death"
			## column is the +25 heat only).
			KEY_TIER: 0,
			KEY_LOOT_KIND: &"",
			KEY_AGGRO_RADIUS: 750.0,
			## Section 5 says the turret holds aggro "until scan range clears"; section 13
			## states no turret scan radius, so the brain's release radius falls back to
			## the aggro radius rather than inventing one (reported).
			KEY_SCAN_RADIUS: 0.0,
			KEY_FLEE_HULL: 0.0,
			KEY_FLEE_TIER: &"",
			KEY_SCAN_TIER: &"",
			KEY_ATTACK_TIER: &"",
			KEY_HOSTILITY: HOSTILITY_ON_ATTACK,
			KEY_STATIC: true,
			KEY_BLIP_KIND: BLIP_HOSTILE,
			KEY_HEAT_ON_KILL: 25,
			KEY_STANDING_ON_KILL: NO_STANDING,
			KEY_SPAWN: SPAWN_STATION,
			KEY_SEAM: SEAM_NONE,
			KEY_DENSITY: _zero_column(),
			KEY_GROUP_KIND: GROUP_NONE,
			KEY_MEMBERS: [],
		},
		{
			KEY_ID: &"hunter",
			KEY_FACTION: FACTION_SPACE_OWNER,
			KEY_HULL_ID: &"ship_fighter",
			KEY_SPRITE_BASE: &"ship_fighter",
			KEY_LIVERY_SOURCE: FACTION_SPACE_OWNER,
			KEY_TIER: 1,
			## Doc 13 section 3: "Hunters drop loot like pirates of their band".
			KEY_LOOT_KIND: &"fighter",
			## Doc 13 section 7 (wave S6, CONTRACTS section 19): the row flips off its
			## slice-4 seam and carries the aggro/scan radius the pirate fighter band
			## flies at. **Proposed**: the radius is the pirate row's own 900.0
			## (`game/npc_registry.gd`, the pirate row); reversal 1200.0.
			KEY_AGGRO_RADIUS: 900.0,
			KEY_SCAN_RADIUS: 900.0,
			KEY_FLEE_HULL: 0.0,
			KEY_FLEE_TIER: &"",
			KEY_SCAN_TIER: &"",
			KEY_ATTACK_TIER: &"",
			KEY_HOSTILITY: HOSTILITY_EVERYTHING,
			KEY_STATIC: false,
			KEY_BLIP_KIND: BLIP_HOSTILE,
			KEY_HEAT_ON_KILL: NO_HEAT,
			KEY_STANDING_ON_KILL: NO_STANDING,
			## `SPAWN_SECTOR` so the row is a real sector archetype (13 section 3 spawns the
			## wing into the player's sector, not a station or a seam), and a **zero**
			## density so `spawns_for` never rolls it with the ordinary population: the wing
			## is the heat tier's business (`game.gd:_spawn_hunter_wave`), not the band's.
			KEY_SPAWN: SPAWN_SECTOR,
			KEY_SEAM: SEAM_NONE,
			KEY_DENSITY: _zero_column(),
			KEY_GROUP_KIND: GROUP_NONE,
			## Doc 13 section 3 / section 5: "2-3 hunter hulls, fighter band", and doc 13
			## section 7's **hull map** - one member per player class band, each naming the
			## hull the wing flies and the player hulls it answers for. `hunter_hull_for` is
			## the only reader; a member with no `KEY_PLAYER_HULLS` answers for every hull.
			KEY_MEMBERS: [
				{
					KEY_HULL_ID: &"ship_fighter",
					KEY_MIN: 2,
					KEY_MAX: 3,
					KEY_ROLE: &"wing",
					KEY_PLAYER_HULLS: [
						&"ship_fighter", &"ship_interceptor", &"ship_patrol", &"ship_miner",
						&"ship_vanguard", &"ship_trader", &"ship_corvette",
					],
				},
				{
					KEY_HULL_ID: &"ship_gunship",
					KEY_MIN: 2,
					KEY_MAX: 3,
					KEY_ROLE: &"wing",
					KEY_PLAYER_HULLS: [
						&"ship_gunship", &"ship_destroyer", &"ship_freighter",
					],
				},
			],
		},
		{
			KEY_ID: &"boss",
			KEY_FACTION: FACTION_ARENA,
			KEY_HULL_ID: &"ship_boss_maw",
			KEY_SPRITE_BASE: &"ship_boss_maw",
			KEY_LIVERY_SOURCE: &"",
			KEY_TIER: 0,
			## 06 carries the Maw table, but section 5's boss death "pays through 14
			## section 5", which is slice 4's contract; the row rolls no 06 table.
			KEY_LOOT_KIND: &"",
			KEY_AGGRO_RADIUS: 0.0,
			KEY_SCAN_RADIUS: 0.0,
			KEY_FLEE_HULL: 0.0,
			KEY_FLEE_TIER: &"",
			KEY_SCAN_TIER: &"",
			KEY_ATTACK_TIER: &"",
			KEY_HOSTILITY: HOSTILITY_EVERYTHING,
			KEY_STATIC: false,
			KEY_BLIP_KIND: BLIP_HOSTILE,
			KEY_HEAT_ON_KILL: NO_HEAT,
			KEY_STANDING_ON_KILL: NO_STANDING,
			KEY_SPAWN: SPAWN_SEAM,
			KEY_SEAM: SEAM_SLICE_4,
			KEY_DENSITY: _zero_column(),
			KEY_GROUP_KIND: GROUP_NONE,
			KEY_MEMBERS: [],
		},
		{
			KEY_ID: &"sibelon",
			KEY_FACTION: FACTION_NONE,
			## Ruling 24: "the `sibelon` (anomaly entity, slice 3)". Its hull is not an
			## 08 class either, so slice 3 resolves its own snapshot.
			KEY_HULL_ID: &"ship_sibelon",
			KEY_SPRITE_BASE: &"ship_sibelon",
			KEY_LIVERY_SOURCE: &"",
			KEY_TIER: 0,
			KEY_LOOT_KIND: &"",
			KEY_AGGRO_RADIUS: 0.0,
			KEY_SCAN_RADIUS: 0.0,
			KEY_FLEE_HULL: 0.0,
			KEY_FLEE_TIER: &"",
			KEY_SCAN_TIER: &"",
			KEY_ATTACK_TIER: &"",
			KEY_HOSTILITY: HOSTILITY_EVERYTHING,
			KEY_STATIC: false,
			KEY_BLIP_KIND: BLIP_HOSTILE,
			KEY_HEAT_ON_KILL: NO_HEAT,
			KEY_STANDING_ON_KILL: NO_STANDING,
			KEY_SPAWN: SPAWN_SEAM,
			KEY_SEAM: SEAM_SLICE_3,
			KEY_DENSITY: _zero_column(),
			KEY_GROUP_KIND: GROUP_NONE,
			KEY_MEMBERS: [],
		},
		{
			KEY_ID: &"apex",
			KEY_FACTION: FACTION_NONE,
			## Ruling 24: "the `apex` leviathan boss (slice 4)".
			KEY_HULL_ID: &"ship_apex",
			KEY_SPRITE_BASE: &"ship_apex",
			KEY_LIVERY_SOURCE: &"",
			KEY_TIER: 0,
			KEY_LOOT_KIND: &"",
			KEY_AGGRO_RADIUS: 0.0,
			KEY_SCAN_RADIUS: 0.0,
			KEY_FLEE_HULL: 0.0,
			KEY_FLEE_TIER: &"",
			KEY_SCAN_TIER: &"",
			KEY_ATTACK_TIER: &"",
			KEY_HOSTILITY: HOSTILITY_EVERYTHING,
			KEY_STATIC: false,
			KEY_BLIP_KIND: BLIP_HOSTILE,
			KEY_HEAT_ON_KILL: NO_HEAT,
			KEY_STANDING_ON_KILL: NO_STANDING,
			KEY_SPAWN: SPAWN_SEAM,
			KEY_SEAM: SEAM_SLICE_4,
			KEY_DENSITY: _zero_column(),
			KEY_GROUP_KIND: GROUP_NONE,
			KEY_MEMBERS: [],
		},
	]


## One filler's column: filler `i` is present whenever the band's count reaches it, and
## the *last* filler takes whatever is left of the band, so the columns always sum back
## to `HOSTILE_BAND` exactly - the test suite and the probe both assert that. With
## `HOSTILE_FILL` as shipped (pirate, swarmer) every sector splits into one guarding
## pirate and the rest of the band as aliens.
static func _hostile_column(slot: int) -> Array[Vector2i]:
	var last := slot == HOSTILE_FILL.size() - 1
	var column: Array[Vector2i] = []
	for band: Vector2i in HOSTILE_BAND:
		if last:
			column.append(Vector2i(maxi(band.x - slot, 0), maxi(band.y - slot, 0)))
		else:
			column.append(
				Vector2i(clampi(band.x - slot, 0, 1), clampi(band.y - slot, 0, 1))
			)
	return column


## Patrols only in owned space (doc 11 section 3, section 5): a sector owned by
## `unaligned` is nobody's, so the presence default is zeroed there.
static func _patrol_column() -> Array[Vector2i]:
	var column: Array[Vector2i] = []
	for row: Dictionary in SectorRegistryScript.SECTORS:
		var owned := StringName(row.get(&"owner", UNALIGNED)) != UNALIGNED
		column.append(PATROL_PRESENCE if owned else Vector2i.ZERO)
	return column


## One convoy per inhabited sector (doc 11 section 3, section 13). "Inhabited" is the
## sector registry's own convoy column, so the two cannot disagree.
static func _convoy_column() -> Array[Vector2i]:
	var column: Array[Vector2i] = []
	for row: Dictionary in SectorRegistryScript.SECTORS:
		var densities: Dictionary = row.get(&"densities", {})
		var inhabited := int(densities.get(&"convoys", 0)) > 0
		column.append(Vector2i(1, 1) if inhabited else Vector2i.ZERO)
	return column


static func _zero_column() -> Array[Vector2i]:
	var column: Array[Vector2i] = []
	for _band: Vector2i in HOSTILE_BAND:
		column.append(Vector2i.ZERO)
	return column


## One archetype row by id, or an empty dictionary for an unknown id.
static func archetype(id: StringName) -> Dictionary:
	_ensure()
	for row: Dictionary in NPCS:
		if StringName(row[KEY_ID]) == id:
			return row
	return {}


static func has(id: StringName) -> bool:
	return not archetype(id).is_empty()


static func ids() -> Array[StringName]:
	_ensure()
	var out: Array[StringName] = []
	for row: Dictionary in NPCS:
		out.append(StringName(row[KEY_ID]))
	return out


## The archetypes a row asks the brain to be hostile to, in one place. `contact` is the
## hull-side contact record: `archetype`, `is_player` and the contact's own `hostility`.
## `heat_tier` is the player's tier in this space (doc 13 section 3) and `attacked` is
## whether this hull has been hit since its last aggro ended.
##
## The rules are section 5's behaviour column, nothing else: `everything` engages any
## contact that is not its own kind (a swarm that fired on itself would not be a swarm),
## `faction_rules` defends against anything whose nature is to attack and attacks the
## player only at the Outlaw tier, `on_attack` waits to be hit, and `none` never starts.
static func is_hostile(
	row: Dictionary, contact: Dictionary, heat_tier: StringName, attacked: bool
) -> bool:
	var hostility := StringName(row.get(KEY_HOSTILITY, HOSTILITY_NONE))
	var contact_kind := StringName(contact.get(&"archetype", &""))
	var is_player := bool(contact.get(&"is_player", false))
	match hostility:
		HOSTILITY_EVERYTHING:
			return contact_kind != StringName(row.get(KEY_ID, &""))
		HOSTILITY_FACTION_RULES:
			if is_player:
				return tier_at_least(heat_tier, StringName(row.get(KEY_ATTACK_TIER, &"")))
			return StringName(contact.get(&"hostility", HOSTILITY_NONE)) \
				== HOSTILITY_EVERYTHING
		HOSTILITY_ON_ATTACK:
			return attacked and is_player
		_:
			return false


## Doc 13 section 3's tier for a heat value: the highest tier whose threshold it reaches.
static func heat_tier(heat: int) -> StringName:
	var tier := HEAT_CLEAN
	for row: Dictionary in HEAT_TIERS:
		if heat >= int(row[&"min"]):
			tier = StringName(row[&"id"])
	return tier


## A tier's threshold (doc 13 section 3's own numbers), the comparison basis so no
## caller restates 20, 50 or 80. An unknown tier reads as Clean.
static func heat_min(tier: StringName) -> int:
	for row: Dictionary in HEAT_TIERS:
		if StringName(row[&"id"]) == tier:
			return int(row[&"min"])
	return 0


static func tier_at_least(tier: StringName, floor: StringName) -> bool:
	if floor == &"":
		return false
	return heat_min(tier) >= heat_min(floor)


## A row's per-sector count band, in sector-registry order (S1 first). An unknown row or
## sector reads as (0, 0) rather than guessing.
static func density(id: StringName, sector_id: StringName) -> Vector2i:
	var index := sector_index(sector_id)
	if index < 0:
		return Vector2i.ZERO
	var column: Variant = archetype(id).get(KEY_DENSITY, [])
	if column is Array and index < (column as Array).size():
		return (column as Array)[index] as Vector2i
	return Vector2i.ZERO


## Doc 11 section 3's population targets this registry answers to, as a dictionary, so
## the sector code reads one shape: the seven-row hostile band plus every row's column.
static func density_table(sector_id: StringName) -> Dictionary:
	_ensure()
	var out := {}
	for row: Dictionary in NPCS:
		var id := StringName(row[KEY_ID])
		var band := density(id, sector_id)
		if band != Vector2i.ZERO:
			out[id] = band
	return out


## The resolved spawn rows for one sector: every `SPAWN_SECTOR` archetype whose band is
## not empty, with the band, the resolved faction id and the sprite path filled in, one
## entry per hull (a convoy's hauler and its escorts are two entries sharing `group_kind`).
##
## The sector code rolls a count in `[min, max]` per entry and spawns that many hulls
## (section 8's on-entry set and the 20-minute clock, which stay the sector's business).
static func spawns_for(sector_id: StringName) -> Array[Dictionary]:
	_ensure()
	var out: Array[Dictionary] = []
	var owner := space_owner(sector_id)
	for row: Dictionary in NPCS:
		if StringName(row[KEY_SPAWN]) != SPAWN_SECTOR:
			continue
		var band := density(StringName(row[KEY_ID]), sector_id)
		if band == Vector2i.ZERO:
			continue
		out.append_array(_expand(row, band, owner))
	return out


## One row's spawn entries for a sector band. A row with members expands to one entry per
## member (each carrying the member's own doc-sourced count); a plain row is one entry
## carrying the band.
static func _expand(row: Dictionary, band: Vector2i, owner: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var members: Array = []
	var raw: Variant = row.get(KEY_MEMBERS, [])
	if raw is Array and not (raw as Array).is_empty():
		members.assign(raw)
	if members.is_empty():
		out.append(_spawn_row(row, StringName(row[KEY_HULL_ID]), band, owner, ROLE_HULL))
		return out
	for member: Dictionary in members:
		var counts := Vector2i(int(member.get(KEY_MIN, 0)), int(member.get(KEY_MAX, 0)))
		out.append(
			_spawn_row(
				row,
				StringName(member.get(KEY_HULL_ID, row[KEY_HULL_ID])),
				counts,
				owner,
				StringName(member.get(KEY_ROLE, ROLE_HULL))
			)
		)
	return out


static func _spawn_row(
	row: Dictionary, hull_id: StringName, band: Vector2i, owner: StringName, role: StringName
) -> Dictionary:
	var out := row.duplicate(true)
	out[KEY_HULL_ID] = hull_id
	out[KEY_ARCHETYPE] = StringName(row[KEY_ID])
	out[KEY_MIN] = band.x
	out[KEY_MAX] = band.y
	out[KEY_ROLE] = role
	out[KEY_FACTION_ID] = resolve_faction(row, owner)
	out[KEY_SPRITE_PATH] = sprite_path_for_hull(row, hull_id, owner)
	return out


## The faction a row belongs to in one sector: its own owner where the row names one, the
## space's owner for a faction hull, and `unaligned` for nobody's.
static func resolve_faction(row: Dictionary, owner: StringName) -> StringName:
	var faction := StringName(row.get(KEY_FACTION, FACTION_NONE))
	if faction == FACTION_SPACE_OWNER or faction == FACTION_STATION:
		return owner if owner != &"" else UNALIGNED
	return faction


## The livery qualifier a row wears in one sector: its own id for a faction hull, empty
## otherwise. `sprite_path` is the only reader.
static func livery(row: Dictionary, owner: StringName) -> StringName:
	if StringName(row.get(KEY_LIVERY_SOURCE, &"")) == FACTION_SPACE_OWNER:
		return owner
	return &""


## Which hull art a spawn draws (ASSET_NAMING_SPEC section 1's `<hull>` token): the row's
## own `sprite_base` when the row flies the hull it was handed - ruling 24's alien rows
## name a hull of their own - and the hull id itself otherwise, so a convoy escort
## (`trader` row, fighter hull) draws a fighter in the convoy's livery rather than the
## hauler's box. `NpcShip` and the spawn rows read this one rule.
static func sprite_base_for(row: Dictionary, hull_id: StringName) -> StringName:
	var row_hull := StringName(row.get(KEY_HULL_ID, &""))
	if row_hull == hull_id:
		return StringName(row.get(KEY_SPRITE_BASE, hull_id))
	return hull_id


## The swap-ready sprite path for one (row, hull, space) spawn: the rule above plus
## `sprite_path`.
static func sprite_path_for_hull(row: Dictionary, hull_id: StringName, owner: StringName) -> String:
	var sprite_row := {KEY_SPRITE_BASE: sprite_base_for(row, hull_id)}
	sprite_row[KEY_LIVERY_SOURCE] = row.get(KEY_LIVERY_SOURCE, &"")
	return sprite_path(sprite_row, owner)


## The shipped sprite path for a row in one sector: the liveried file when one exists,
## then the plain hull view, then the bare hull name - ASSET_NAMING_SPEC section 1's
## `ship_<hull>[_<qualifier>][_<angle>].png` for a hull and the single-file shape the
## non-hull platform art uses (`ship_turret_platform.png` has no angle). Nothing here
## creates or edits art; a file that is absent is simply not the one asked for, and
## `NpcShip` draws its placeholder.
static func sprite_path(row: Dictionary, owner: StringName = &"") -> String:
	var base := String(row.get(KEY_SPRITE_BASE, &""))
	if base.is_empty():
		return ""
	var qualifier := livery(row, owner)
	var candidates: Array[String] = []
	if not qualifier.is_empty():
		candidates.append("%s%s_%s_%s.png" % [SPRITE_DIR, base, qualifier, SPRITE_VIEW])
	candidates.append("%s%s_%s.png" % [SPRITE_DIR, base, SPRITE_VIEW])
	candidates.append("%s%s.png" % [SPRITE_DIR, base])
	for candidate: String in candidates:
		if ResourceLoader.exists(candidate):
			return candidate
	## Nothing on disk: hand back the plain view so a caller can report the exact miss.
	return "%s%s_%s.png" % [SPRITE_DIR, base, SPRITE_VIEW]


## A sector's owner, read off the sector registry (the single owner of the seven
## sectors' ownership). Empty for an unknown sector.
static func space_owner(sector_id: StringName) -> StringName:
	var row := SectorRegistryScript.sector(sector_id)
	if row.is_empty():
		return &""
	return StringName(row.get(&"owner", UNALIGNED))


static func sector_index(sector_id: StringName) -> int:
	var ids := SectorRegistryScript.sector_ids()
	return ids.find(sector_id)


## --- Doc 13 section 3's hunters (wave S6) ------------------------------------------


## The hunter row's `KEY_MEMBERS` entries, typed. A row that carries none answers `[]`,
## which makes `hunter_wing_size` 0 and `hunter_spawn` empty rather than guessing a wing.
static func hunter_members() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var raw: Variant = archetype(ARCHETYPE_HUNTER).get(KEY_MEMBERS, [])
	if raw is Array:
		for entry: Variant in (raw as Array):
			if entry is Dictionary:
				out.append(entry)
	return out


## Doc 13 section 7's wing size (`randi_range(2, 3)`), read off the hunter row's own
## `KEY_MEMBERS` so the number has one home: the first member's band, which every band
## member shares. `(0, 0)` for a row without members.
static func hunter_wing_size() -> Vector2i:
	for member: Dictionary in hunter_members():
		return Vector2i(int(member.get(KEY_MIN, 0)), int(member.get(KEY_MAX, 0)))
	return Vector2i.ZERO


## Doc 13 section 7's hull map: the hunter hull one player class draws ("one band below the
## player's active hull"). A player hull in no band falls back to `HUNTER_HULL_DEFAULT`,
## which is also the first band's own hull, so an unknown hull still draws a wing.
static func hunter_hull_for(player_hull_id: StringName) -> StringName:
	for member: Dictionary in hunter_members():
		var band: Variant = member.get(KEY_PLAYER_HULLS, [])
		if band is Array and (band as Array).has(player_hull_id):
			return StringName(member.get(KEY_HULL_ID, HUNTER_HULL_DEFAULT))
	return HUNTER_HULL_DEFAULT


## One hunter wing's spawn row for `sector_id`'s space and a player flying
## `player_hull_id`: the archetype's own row with the hull doc 13 section 7's map gives
## that player class, the wing's own 2-3 band and the space's owner as the faction, in the
## same shape `spawns_for` hands the sector population - so the caller rolls
## `[KEY_MIN, KEY_MAX]` and spawns that many. The row's density stays zero, so a wing
## exists only where a heat tier asks for one (13 section 3's per-faction rule: Concord
## hunts Concord's outlaws, and nobody hunts in nobody's space).
static func hunter_spawn(sector_id: StringName, player_hull_id: StringName) -> Dictionary:
	_ensure()
	var row := archetype(ARCHETYPE_HUNTER)
	if row.is_empty():
		return {}
	var owner := space_owner(sector_id)
	return _spawn_row(
		row, hunter_hull_for(player_hull_id), hunter_wing_size(), owner, ROLE_HULL
	)
