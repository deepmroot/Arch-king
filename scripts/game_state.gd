extends Node

# Character IDs
const CHAR_ARCHER   := "archer"
const CHAR_WARDEN   := "warden"
const CHAR_RANGER   := "ranger"
const CHAR_ALCHEMIST := "alchemist"
const CHAR_MERCHANT := "sorcerer"
const CHAR_WIZARD   := "wizard"

var selected_character := CHAR_ARCHER


# ── Bonuses applied in level.gd _ready() ──────────────────────────────────────

func apply_to_level(level: Node) -> void:
	ranger_arrow_count = 0  # Reset pierce counter each new game
	match selected_character:

		CHAR_ARCHER:
			# Balanced starter kit: no extra bonuses, pure baseline archer gameplay
			pass

		CHAR_WARDEN:
			# Fortress-focused: more HP, cheaper wall/keep, extra turret range
			level.starting_hp      += 4
			level.max_castle_hp    += 4
			level.wall_upgrade_cost = max(1, level.wall_upgrade_cost - 2)
			level.keep_upgrade_cost = max(1, level.keep_upgrade_cost - 2)
			level.turret_range     += 30.0

		CHAR_RANGER:
			# Precision/aggression: free fire rate level, cheaper damage upgrades, starts with extra coin
			level.fire_rate_level       += 1
			level.damage_upgrade_cost    = max(1, level.damage_upgrade_cost - 2)
			level.starting_coins        += 2

		CHAR_ALCHEMIST:
			# Trap/AoE focus: extra coins, cheaper traps, catapult bonus radius baked via variable
			level.starting_coins       += 3
			level.spike_trap_cost       = max(1, level.spike_trap_cost - 2)
			level.fire_trap_cost        = max(1, level.fire_trap_cost - 2)
			level.slow_trap_cost        = max(1, level.slow_trap_cost - 2)
			# catapult AoE bonus — level.gd reads this in _update_catapult_attack
			level.catapult_aoe_bonus    = 24.0

		CHAR_MERCHANT:
			# Economy: more starting coins, all upgrades 1 cheaper, longer prep
			level.starting_coins        += 6
			level.repair_cost            = max(1, level.repair_cost - 1)
			level.wall_upgrade_cost      = max(1, level.wall_upgrade_cost - 1)
			level.keep_upgrade_cost      = max(1, level.keep_upgrade_cost - 1)
			level.fire_rate_upgrade_cost = max(1, level.fire_rate_upgrade_cost - 1)
			level.damage_upgrade_cost    = max(1, level.damage_upgrade_cost - 1)
			level.turret_build_cost      = max(1, level.turret_build_cost - 1)
			level.catapult_build_cost    = max(1, level.catapult_build_cost - 1)
			level.spike_trap_cost        = max(1, level.spike_trap_cost - 1)
			level.fire_trap_cost         = max(1, level.fire_trap_cost - 1)
			level.slow_trap_cost         = max(1, level.slow_trap_cost - 1)
			level.prep_phase_duration   += 5.0

		CHAR_WIZARD:
			# Arcane: bonus damage, piercing shots from the start, extra coins
			level.damage_upgrade_cost    = max(1, level.damage_upgrade_cost - 1)
			level.starting_coins        += 3
			level.fire_rate_level       += 1


# ── Per-kill coin bonus ────────────────────────────────────────────────────────

func bonus_coins_per_kill() -> int:
	if selected_character == CHAR_MERCHANT:
		return 1
	return 0


func is_melee_character() -> bool:
	return selected_character == CHAR_WARDEN or selected_character == CHAR_MERCHANT

func is_battlefield_character() -> bool:
	return selected_character == CHAR_WARDEN or selected_character == CHAR_MERCHANT


# ── Ranger pierce: every 5th arrow pierces one extra enemy ────────────────────

var ranger_arrow_count := 0

func ranger_should_pierce() -> bool:
	if selected_character == CHAR_WIZARD:
		return true
	if selected_character != CHAR_RANGER:
		return false
	ranger_arrow_count += 1
	if ranger_arrow_count >= 5:
		ranger_arrow_count = 0
		return true
	return false


# ── Display helpers ───────────────────────────────────────────────────────────

static func get_characters() -> Array[Dictionary]:
	return [
		{
			"id": CHAR_ARCHER,
			"name": "Archer",
			"title": "Castle Marksman",
			"icon_color": Color(0.48, 0.72, 0.96, 1),
			"abilities": [
				"Balanced ranged starter",
				"Reliable bow damage",
				"Good all-round first pick",
			],
			"playstyle": "Balanced — the baseline defender. Clean ranged combat, steady upgrades, and no special restrictions.",
		},
		{
			"id": CHAR_WARDEN,
			"name": "Hero Knight",
			"title": "Defender of the Realm",
			"icon_color": Color(0.35, 0.55, 0.85, 1),
			"abilities": [
				"+ 4 Starting Wall HP",
				"Wall & Keep upgrades cost 2 less",
				"Turret range +30",
			],
			"playstyle": "Defensive — a stalwart hero knight built to anchor the wall, strengthen the fortress, and survive the hardest waves.",
		},
		{
			"id": CHAR_RANGER,
			"name": "Huntress",
			"title": "Spear of the Wilds",
			"icon_color": Color(0.42, 0.78, 0.38, 1),
			"abilities": [
				"Starts with Fire Rate Lv.1",
				"Damage upgrades cost 2 less",
				"Every 5th shot pierces",
			],
			"playstyle": "Aggressive — a swift huntress who picks off threats early and keeps pressure on the horde with relentless ranged attacks.",
		},
		{
			"id": CHAR_ALCHEMIST,
			"name": "Alchemist",
			"title": "Master of Destruction",
			"icon_color": Color(0.85, 0.55, 0.20, 1),
			"abilities": [
				"All traps cost 2 less",
				"Catapult AoE radius +24",
				"+ 3 Starting Coins",
			],
			"playstyle": "Area Control — blanket the battlefield in fire, spikes, and explosions.",
		},
		{
			"id": CHAR_MERCHANT,
			"name": "Sorcerer",
			"title": "Dark Conjurer",
			"icon_color": Color(0.88, 0.78, 0.28, 1),
			"abilities": [
				"+ 6 Starting Coins  +1 per kill",
				"All upgrades cost 1 less",
				"Prep phase lasts 5s longer",
			],
			"playstyle": "Economy — out-resource the horde and max everything before the walls break.",
		},
		{
			"id": CHAR_WIZARD,
			"name": "Wizard",
			"title": "Arcane Destroyer",
			"icon_color": Color(0.55, 0.25, 0.80, 1),
			"abilities": [
				"All shots pierce enemies",
				"Starts with Fire Rate Lv.1",
				"Damage upgrades cost 1 less  +3 Coins",
			],
			"playstyle": "Arcane — blast through entire rows of enemies with piercing magical bolts.",
		},
	]
