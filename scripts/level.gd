extends Node2D

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const ARROW_SCENE := preload("res://scenes/Arrow.tscn")
const KNIGHT_GUARD_SCENE := preload("res://scenes/KnightGuard.tscn")
const FLOATING_TEXT_SCRIPT := preload("res://scripts/floating_text.gd")
const OPTIONS_PANEL_SCENE := preload("res://scenes/OptionsPanel.tscn")

# --- Audio assets ---
const SFX_ARROW_LAUNCH := preload("res://assets/audio/sfx/arrow_launch.ogg")
const SFX_ARROW_WHISTLE := preload("res://assets/audio/sfx/arrow_whistle.mp3")
const SFX_BEAR_TRAP := preload("res://assets/audio/sfx/bear_trap_clamp.ogg")
const SFX_GOBLIN_DEATH := preload("res://assets/audio/sfx/goblin_death.ogg")
const SFX_CANNON_FIRE := preload("res://assets/audio/sfx/cannon_fire.ogg")
const SFX_TURRET_CRANK := preload("res://assets/audio/sfx/turret_crank.ogg")

# --- UI assets ---
const UI_TUTORIAL_PANEL_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-transparent-border-010.png")
const UI_TUTORIAL_BTN_NORMAL_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-010.png")
const UI_TUTORIAL_BTN_HOVER_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-011.png")
const UI_TUTORIAL_BTN_PRESSED_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-012.png")

# --- Defense art assets ---
const TURRET_FACE_TEX := preload("res://assets/defenses/turret/turret_face.png")
const TURRET_BULLET_TEX := preload("res://assets/defenses/turret/turret_bullet.png")
const BEAR_TRAP_TEX := preload("res://assets/defenses/traps/bear_trap.png")
const FIRE_TRAP_TEX := preload("res://assets/defenses/traps/fire_trap.png")
const ARTILLERY_TEX := preload("res://assets/defenses/artillery/artillery.png")

# --- Wall art assets ---
const WALL_LEVEL1_TEX := preload("res://assets/environment/walls/wall_level1.png")
const WALL_LEVEL2_TEX := preload("res://assets/environment/walls/wall_level2.png")
const WALL_LEVEL3_TEX := preload("res://assets/environment/walls/wall_level3.png")
const WALL_BATTLEMENT_TEX := preload("res://assets/environment/walls/wall_battlement.png")

const PHASE_PREP := "prep"
const PHASE_BATTLE := "battle"

const TRAP_SPIKE := "spike"
const TRAP_FIRE := "fire"
const TRAP_SLOW := "slow"

const TARGET_CLOSEST := "closest"
const TARGET_STRONGEST := "strongest"
const TARGET_FASTEST := "fastest"
const TARGET_GROUPED := "grouped"

const BOSS_REWARD_REINFORCE := "reinforce"
const BOSS_REWARD_SHARPEN := "sharpen"
const BOSS_REWARD_VOLLEY := "volley"

const SHOP_TAB_FORTRESS := "fortress"
const SHOP_TAB_DEFENSES := "defenses"
const SHOP_TAB_TACTICS := "tactics"
const SHOP_TAB_TRAPS := "traps"

const BASE_VIEWPORT_WIDTH := 1152.0
const BASE_VIEWPORT_HEIGHT := 900.0
const BASE_CENTER_X := BASE_VIEWPORT_WIDTH * 0.5
const BASE_PATH_WIDTH := 300.0
const BASE_RIGHT_TOWER_WIDTH := 170.0
const SETTINGS_PATH := "user://settings.cfg"
const TURRET_IDLE_ROTATION := -PI * 0.5

@export var starting_hp := 12
@export var max_castle_hp := 16
@export var starting_coins := 8
@export var tutorial_enabled := true
@export var wall_y := 90.0
@export var wall_margin_from_bottom := 90.0
@export var repair_cost := 4
@export var spike_trap_cost := 5
@export var fire_trap_cost := 7
@export var slow_trap_cost := 8
@export var fire_rate_upgrade_cost := 7
@export var damage_upgrade_cost := 9
@export var wall_upgrade_cost := 11
@export var keep_upgrade_cost := 16
@export var turret_build_cost := 14
@export var catapult_build_cost := 30
@export var enemy_lane_half_width := 120.0
@export var player_wall_offset := -24.0
@export var lower_lane_y := 720.0
@export var lower_area_top_y := 560.0
@export var lower_area_bottom_y := 800.0
@export var ladder_transition_duration := 0.55
@export var prep_phase_duration := 15.0

var coins := 0
var castle_hp := 0
var score := 0
var wave_index := 0
var current_phase := PHASE_PREP
var is_game_over := false
var player_in_shop_zone := false
var player_near_ladder_top := false
var player_near_ladder_bottom := false
var player_is_on_lower_lane := true
var is_ladder_transitioning := false
var battle_started := false
var enemies_to_spawn := 0
var enemies_alive := 0
var prep_time_remaining := 0.0
var fire_rate_level := 0
var damage_level := 0
var wall_level := 1
var keep_level := 1
var turret_level := 0
var turret_fire_timer := 0.0
var turret_range := 240.0
var turret_positions: Array[Vector2] = []  # Computed in _ready relative to wall_y
var turret_visuals: Array[Sprite2D] = []
var turret_range_indicators: Array[Line2D] = []
var turret_preview_hovered := false
var turret_target_mode := TARGET_CLOSEST
var catapult_level := 0
var catapult_fire_timer := 0.0
var catapult_range := 320.0
var catapult_aoe_bonus := 0.0  # Set by GameState.apply_to_level for Alchemist
var catapult_position := Vector2.ZERO  # Computed in _ready relative to wall_y
var catapult_visual: Sprite2D
var catapult_target_mode := TARGET_GROUPED
var trap_inventory: Dictionary = {
	TRAP_SPIKE: 0,
	TRAP_FIRE: 0,
	TRAP_SLOW: 0,
}
var battlefield_trap_points: Array[Vector2] = []  # Computed in _ready relative to wall_y
var placed_traps: Array[String] = ["", "", "", "", "", "", "", ""]
var trap_trigger_radius := 42.0
var enemy_spawn_queue: Array = []
var status_message := ""
var status_message_time := 0.0
var boss_reward_pending := false
var trap_coverage_indicators: Array[Polygon2D] = []
var current_shop_tab := SHOP_TAB_FORTRESS
var master_volume := 1.0
var music_volume := 0.6
var sfx_volume := 1.0
var display_mode := "fullscreen"
var resolution_scale := 1.0
var options_panel
var music_player: AudioStreamPlayer
var sfx_players: Dictionary = {}
var wall_body_sprites: Array[Sprite2D] = []
var wall_pillar_sprites: Array[Sprite2D] = []
var trap_sprites: Array[Sprite2D] = []
var guard_home_positions: Array[Vector2] = []
var knight_guards: Array[Node2D] = []
var guards_container: Node2D
var tutorial_panel: Panel
var tutorial_title_label: Label
var tutorial_body_label: RichTextLabel
var tutorial_button: Button
var tutorial_skip_button: Button
var prompt_chip: Panel
var message_chip: Panel
var tutorial_pages: Array[Dictionary] = []
var tutorial_page_index := -1
var shown_enemy_tutorials: Dictionary = {}

@onready var player = $Player
@onready var ui_root: CanvasLayer = $UI
@onready var enemies_container = $Enemies
@onready var projectiles_container = $Projectiles
@onready var enemy_spawner: Timer = $EnemySpawner
@onready var background_fill: Polygon2D = $Background/BackgroundFill
@onready var background_forest: TextureRect = $Background/ForestBackground
@onready var background_path: TextureRect = $Background/Path
@onready var support_area: Polygon2D = $SupportArea
@onready var back_yard_boundary: Polygon2D = $BackYardBoundary
@onready var wall_front_shadow: Polygon2D = $WallFrontShadow
@onready var shop_zone: Area2D = $ShopZone
@onready var castle_wall_band: Polygon2D = $CastleWallBand
@onready var wall_highlight: Polygon2D = $WallHighlight
@onready var wall_mid_shadow: Polygon2D = $WallMidShadow
@onready var gate_arch: Sprite2D = $GateArch
@onready var ladder: Node2D = $Ladder
@onready var wall_battlements: Node2D = $WallBattlements
@onready var towers: Node2D = $Towers
@onready var right_tower: Polygon2D = $Towers/RightTower
@onready var right_tower_cap: Polygon2D = $Towers/RightTowerCap
@onready var right_tower_highlight: Polygon2D = $Towers/RightTowerHighlight
@onready var right_tower_window: Polygon2D = $Towers/RightTowerWindow
@onready var right_tower_window_glow: Polygon2D = $Towers/RightTowerWindowGlow
@onready var lane_marker: Marker2D = $LayoutMarkers/EnemyLaneCenter
@onready var shop_marker: Marker2D = $LayoutMarkers/ShopMarker
@onready var wall_camera_focus: Marker2D = $LayoutMarkers/WallCameraFocus
@onready var back_area_camera_focus: Marker2D = $LayoutMarkers/BackAreaCameraFocus
@onready var ladder_top_zone: Area2D = $LadderZones/LadderTopZone
@onready var ladder_bottom_zone: Area2D = $LadderZones/LadderBottomZone
@onready var game_camera: Camera2D = $GameCamera
@onready var hud_root: Control = $UI/HUD
@onready var hud_panel: Panel = $UI/HUD/HUDPanel
@onready var hud_stats_title: Label = $UI/HUD/StatsTitle
@onready var hud_combat_title: Label = $UI/HUD/CombatTitle
@onready var hp_label: Label = $UI/HUD/HPLabel
@onready var hp_bar_fill: ColorRect = $UI/HUD/HPBarBG/HPBarFill
@onready var coins_label: Label = $UI/HUD/CoinsLabel
@onready var score_label: Label = $UI/HUD/ScoreLabel
@onready var wave_label: Label = $UI/HUD/WaveLabel
@onready var phase_label: Label = $UI/HUD/PhaseLabel
@onready var trap_label: Label = $UI/HUD/TrapLabel
@onready var prompt_label: Label = $UI/PromptLabel
@onready var message_label: Label = $UI/MessageLabel
@onready var boss_bar_panel: Panel = $UI/BossBarPanel
@onready var boss_name_label: Label = $UI/BossBarPanel/BossNameLabel
@onready var boss_bar_fill: ColorRect = $UI/BossBarPanel/BossBarBG/BossBarFill
@onready var wave_banner: Label = $UI/WaveBanner
@onready var boss_reward_panel: Panel = $UI/BossRewardPanel
@onready var boss_reward_title: Label = $UI/BossRewardPanel/VBoxContainer/TitleLabel
@onready var boss_reward_button_1: Button = $UI/BossRewardPanel/VBoxContainer/RewardButton1
@onready var boss_reward_button_2: Button = $UI/BossRewardPanel/VBoxContainer/RewardButton2
@onready var boss_reward_button_3: Button = $UI/BossRewardPanel/VBoxContainer/RewardButton3
@onready var shop_dimmer: ColorRect = $UI/ShopDimmer
@onready var shop_panel: Panel = $UI/ShopPanel
@onready var shop_message_label: Label = $UI/ShopPanel/VBoxContainer/MessageLabel
@onready var fortress_tab_button: Button = $UI/ShopPanel/VBoxContainer/CategoryTabs/FortressTabButton
@onready var defenses_tab_button: Button = $UI/ShopPanel/VBoxContainer/CategoryTabs/DefensesTabButton
@onready var tactics_tab_button: Button = $UI/ShopPanel/VBoxContainer/CategoryTabs/TacticsTabButton
@onready var traps_tab_button: Button = $UI/ShopPanel/VBoxContainer/CategoryTabs/TrapsTabButton
@onready var structure_header: Label = $UI/ShopPanel/VBoxContainer/StructureHeader
@onready var upgrade_header: Label = $UI/ShopPanel/VBoxContainer/UpgradeHeader
@onready var trap_header: Label = $UI/ShopPanel/VBoxContainer/TrapHeader
@onready var shop_info_title_label: Label = $UI/ShopPanel/VBoxContainer/InfoPanel/InfoVBox/InfoTitleLabel
@onready var shop_info_body_label: Label = $UI/ShopPanel/VBoxContainer/InfoPanel/InfoVBox/InfoBodyLabel
@onready var repair_button: Button = $UI/ShopPanel/VBoxContainer/RepairButton
@onready var fire_rate_button: Button = $UI/ShopPanel/VBoxContainer/FireRateButton
@onready var damage_button: Button = $UI/ShopPanel/VBoxContainer/DamageButton
@onready var wall_upgrade_button: Button = $UI/ShopPanel/VBoxContainer/WallUpgradeButton
@onready var keep_upgrade_button: Button = $UI/ShopPanel/VBoxContainer/KeepUpgradeButton
@onready var turret_button: Button = $UI/ShopPanel/VBoxContainer/TurretButton
@onready var turret_mode_button: Button = $UI/ShopPanel/VBoxContainer/TurretModeButton
@onready var catapult_button: Button = $UI/ShopPanel/VBoxContainer/CatapultButton
@onready var catapult_mode_button: Button = $UI/ShopPanel/VBoxContainer/CatapultModeButton
@onready var trap_button: Button = $UI/ShopPanel/VBoxContainer/TrapButton
@onready var fire_trap_button: Button = $UI/ShopPanel/VBoxContainer/FireTrapButton
@onready var slow_trap_button: Button = $UI/ShopPanel/VBoxContainer/SlowTrapButton
@onready var close_button: Button = $UI/ShopPanel/VBoxContainer/CloseButton
@onready var main_menu_panel: Panel = $UI/MainMenuPanel
@onready var main_menu_vbox: VBoxContainer = $UI/MainMenuPanel/VBox
@onready var start_button: Button = $UI/MainMenuPanel/VBox/StartButton
@onready var pause_panel: Panel = $UI/PausePanel
@onready var pause_vbox: VBoxContainer = $UI/PausePanel/VBox
@onready var resume_button: Button = $UI/PausePanel/VBox/ResumeButton
@onready var game_over_panel: Panel = $UI/GameOverPanel
@onready var restart_button: Button = $UI/GameOverPanel/VBox/RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_setup_input_actions()
	_setup_audio()
	_build_options_ui()
	_build_tutorial_ui()
	_build_notice_chips()
	_load_settings()

	# Apply character bonuses before reading derived values
	GameState.apply_to_level(self)

	castle_hp = starting_hp
	coins = starting_coins
	wall_y = 470.0

	# Compute defense positions relative to wall_y
	_refresh_defense_mount_positions()
	# Trap points spread across the battlefield above the wall
	var trap_y_base := wall_y - 68.0
	battlefield_trap_points = [
		Vector2(162, trap_y_base - 6.0),
		Vector2(238, trap_y_base),
		Vector2(372, trap_y_base + 12.0),
		Vector2(510, trap_y_base - 4.0),
		Vector2(646, trap_y_base + 10.0),
		Vector2(784, trap_y_base - 2.0),
		Vector2(920, trap_y_base + 8.0),
		Vector2(998, trap_y_base - 4.0),
	]

	get_viewport().size_changed.connect(_update_responsive_layout)
	_update_responsive_layout()
	guards_container = Node2D.new()
	guards_container.name = "Guards"
	add_child(guards_container)
	player.global_position = Vector2(ladder_bottom_zone.global_position.x, lower_lane_y)
	player.shoot_requested.connect(_on_player_shoot_requested)
	player.melee_impact.connect(_on_player_melee_impact)
	_apply_player_upgrades()

	enemy_spawner.timeout.connect(_on_enemy_spawner_timeout)
	shop_zone.body_entered.connect(_on_shop_zone_body_entered)
	shop_zone.body_exited.connect(_on_shop_zone_body_exited)
	ladder_top_zone.body_entered.connect(_on_ladder_top_zone_body_entered)
	ladder_top_zone.body_exited.connect(_on_ladder_top_zone_body_exited)
	ladder_bottom_zone.body_entered.connect(_on_ladder_bottom_zone_body_entered)
	ladder_bottom_zone.body_exited.connect(_on_ladder_bottom_zone_body_exited)
	fortress_tab_button.pressed.connect(func(): _set_shop_tab(SHOP_TAB_FORTRESS))
	defenses_tab_button.pressed.connect(func(): _set_shop_tab(SHOP_TAB_DEFENSES))
	tactics_tab_button.pressed.connect(func(): _set_shop_tab(SHOP_TAB_TACTICS))
	traps_tab_button.pressed.connect(func(): _set_shop_tab(SHOP_TAB_TRAPS))
	repair_button.pressed.connect(_on_repair_button_pressed)
	repair_button.mouse_entered.connect(func(): _show_repair_info())
	fire_rate_button.mouse_entered.connect(func(): _show_fire_rate_info())
	damage_button.mouse_entered.connect(func(): _show_damage_info())
	wall_upgrade_button.mouse_entered.connect(func(): _show_wall_upgrade_info())
	keep_upgrade_button.mouse_entered.connect(func(): _show_keep_upgrade_info())
	turret_button.mouse_entered.connect(func(): _show_turret_info())
	turret_button.mouse_entered.connect(func(): _set_turret_preview_hovered(true))
	turret_button.mouse_exited.connect(func(): _set_turret_preview_hovered(false))
	turret_mode_button.mouse_entered.connect(func(): _show_turret_tactics_info())
	turret_mode_button.mouse_entered.connect(func(): _set_turret_preview_hovered(true))
	turret_mode_button.mouse_exited.connect(func(): _set_turret_preview_hovered(false))
	catapult_button.mouse_entered.connect(func(): _show_catapult_info())
	catapult_mode_button.mouse_entered.connect(func(): _show_catapult_tactics_info())
	trap_button.mouse_entered.connect(func(): _show_spike_trap_info())
	fire_trap_button.mouse_entered.connect(func(): _show_fire_trap_info())
	slow_trap_button.mouse_entered.connect(func(): _show_slow_trap_info())
	fire_rate_button.pressed.connect(_on_fire_rate_button_pressed)
	damage_button.pressed.connect(_on_damage_button_pressed)
	wall_upgrade_button.pressed.connect(_on_wall_upgrade_button_pressed)
	keep_upgrade_button.pressed.connect(_on_keep_upgrade_button_pressed)
	turret_button.pressed.connect(_on_turret_button_pressed)
	turret_mode_button.pressed.connect(_on_turret_mode_button_pressed)
	catapult_button.pressed.connect(_on_catapult_button_pressed)
	catapult_mode_button.pressed.connect(_on_catapult_mode_button_pressed)
	trap_button.pressed.connect(_on_trap_button_pressed)
	fire_trap_button.pressed.connect(_on_fire_trap_button_pressed)
	slow_trap_button.pressed.connect(_on_slow_trap_button_pressed)
	close_button.pressed.connect(_close_shop)
	start_button.pressed.connect(_start_game)
	restart_button.pressed.connect(_restart_game)
	resume_button.pressed.connect(_toggle_pause)

	# Add "Main Menu" button to pause panel
	var pause_menu_btn := Button.new()
	pause_menu_btn.text = "Main Menu"
	pause_menu_btn.focus_mode = Control.FOCUS_ALL
	pause_menu_btn.pressed.connect(_go_to_main_menu)
	pause_vbox.add_child(pause_menu_btn)

	# Add "Main Menu" button to game over panel
	var gameover_menu_btn := Button.new()
	gameover_menu_btn.text = "Main Menu"
	gameover_menu_btn.focus_mode = Control.FOCUS_ALL
	gameover_menu_btn.pressed.connect(_go_to_main_menu)
	$UI/GameOverPanel/VBox.add_child(gameover_menu_btn)

	boss_reward_button_1.pressed.connect(func(): _claim_boss_reward(BOSS_REWARD_REINFORCE))
	boss_reward_button_2.pressed.connect(func(): _claim_boss_reward(BOSS_REWARD_SHARPEN))
	boss_reward_button_3.pressed.connect(func(): _claim_boss_reward(BOSS_REWARD_VOLLEY))

	_apply_kenney_ui_theme()

	hud_root.visible = true
	boss_bar_panel.visible = false
	boss_reward_panel.visible = false
	shop_dimmer.visible = false
	shop_panel.visible = false
	game_over_panel.visible = false
	pause_panel.visible = false
	# Skip the built-in menu if launched from MainMenu scene
	main_menu_panel.visible = false
	if options_panel != null:
		options_panel.visible = false
	message_label.visible = false
	prompt_label.text = ""
	_refresh_shop_buttons()
	_refresh_trap_visuals()
	_build_trap_coverage_indicators()
	_build_turret_visual()
	_build_catapult_visual()
	_build_wall_sprites()
	_build_trap_sprites()
	# Hide old polygon battlements — wall sprites now handle the visual
	wall_battlements.visible = false
	_update_castle_visuals()
	_start_prep_phase()
	# Game starts immediately — MainMenu scene handles the pre-game flow
	get_tree().paused = false
	battle_started = false
	_set_status_message("Prepare your defenses.", 1.5)
	_show_intro_tutorial()


func _refresh_defense_mount_positions() -> void:
	var center_x := get_viewport_rect().size.x * 0.5
	turret_positions = [
		Vector2(center_x - 76.0, wall_y - 38.0),
		Vector2(center_x + 76.0, wall_y - 38.0),
	]
	catapult_position = Vector2(center_x + 88.0, wall_y - 44.0)


func _refresh_guard_home_positions() -> void:
	var center_x := get_viewport_rect().size.x * 0.5
	var guard_y := wall_y - 28.0 - float(max(wall_level - 1, 0)) * 6.0
	guard_home_positions = [
		Vector2(center_x - 52.0, guard_y),
		Vector2(center_x + 52.0, guard_y),
		Vector2(center_x - 104.0, guard_y + 4.0),
		Vector2(center_x + 104.0, guard_y + 4.0),
		Vector2(center_x - 156.0, guard_y + 10.0),
		Vector2(center_x + 156.0, guard_y + 10.0),
	]


func _get_knight_guard_target_count() -> int:
	return min(2 + max(wall_level - 1, 0), guard_home_positions.size())


func _get_active_knight_guard_count() -> int:
	var count := 0
	for guard in knight_guards:
		if is_instance_valid(guard):
			count += 1
	return count


func _sync_knight_guards(reset_stats: bool = true) -> void:
	if guards_container == null:
		return

	_refresh_guard_home_positions()

	var valid_guards: Array[Node2D] = []
	for guard in knight_guards:
		if is_instance_valid(guard):
			valid_guards.append(guard)
	knight_guards = valid_guards

	var target_count := _get_knight_guard_target_count()
	while knight_guards.size() < target_count:
		var guard: Node2D = KNIGHT_GUARD_SCENE.instantiate()
		guards_container.add_child(guard)
		knight_guards.append(guard)
	while knight_guards.size() > target_count:
		var extra_guard: Node2D = knight_guards.pop_back() as Node2D
		if is_instance_valid(extra_guard):
			extra_guard.queue_free()

	for i in range(knight_guards.size()):
		var guard: Node2D = knight_guards[i] as Node2D
		if not is_instance_valid(guard):
			continue
		var home_position := guard_home_positions[i] if i < guard_home_positions.size() else Vector2(get_viewport_rect().size.x * 0.5, wall_y - 28.0)
		if guard.has_method("set_home_position"):
			guard.call("set_home_position", home_position)
		if guard.has_method("set_battle_active"):
			guard.call("set_battle_active", current_phase == PHASE_BATTLE and not is_game_over)
		if reset_stats and guard.has_method("configure"):
			guard.call("configure", {
				"guard_index": i,
				"home_position": home_position,
				"battle_active": current_phase == PHASE_BATTLE and not is_game_over,
				"speed": 138.0 + float(min(wall_level - 1, 4)) * 5.0,
				"attack_damage": 2 + int((wall_level - 1) / 2) + int((wave_index - 1) / 6),
				"max_health": 5 + wall_level + max(keep_level - 1, 0),
				"attack_cooldown": max(0.62, 0.92 - float(wall_level - 1) * 0.03),
				"attack_range": 28.0,
				"slash_radius": 44.0 + float(min(wall_level - 1, 3)) * 3.0,
				"leash_range": 250.0 + float(min(wall_level - 1, 5)) * 26.0,
				"contact_damage_interval": max(0.75, 1.15 - float(min(wave_index, 8)) * 0.03),
				"visual_scale": 1.45,
			})


func _apply_player_upper_lane_bounds(viewport_size: Vector2) -> void:
	if GameState.is_battlefield_character() and current_phase == PHASE_BATTLE:
		player.set_free_move_bounds(120.0, viewport_size.x - 120.0, 110.0, player.wall_y + 10.0)
	else:
		player.set_lane(player.wall_y, 170.0, viewport_size.x - 170.0)


func _update_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var center_x := viewport_size.x * 0.5
	var right_edge := viewport_size.x
	var right_tower_left := right_edge - BASE_RIGHT_TOWER_WIDTH

	_refresh_defense_mount_positions()
	_refresh_guard_home_positions()
	if guards_container != null:
		_sync_knight_guards(false)

	# Derived Y positions relative to wall_y (470)
	var wall_bottom := wall_y + 70.0          # 540 — bottom of wall band
	var wall_shadow_bottom := wall_bottom + 26.0  # 566

	# --- Background ---
	background_fill.polygon = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(right_edge, 0.0),
		Vector2(right_edge, wall_bottom), Vector2(0.0, wall_bottom)
	])
	background_forest.offset_right = right_edge
	background_forest.offset_bottom = wall_bottom
	background_path.offset_left = center_x - BASE_PATH_WIDTH * 0.5
	background_path.offset_right = center_x + BASE_PATH_WIDTH * 0.5
	background_path.offset_bottom = wall_bottom

	# --- Terrain polygons (all relative to wall_y) ---
	castle_wall_band.polygon = PackedVector2Array([
		Vector2(0.0, wall_y), Vector2(right_edge, wall_y),
		Vector2(right_edge, wall_bottom), Vector2(0.0, wall_bottom)
	])
	wall_highlight.polygon = PackedVector2Array([
		Vector2(0.0, wall_y), Vector2(right_edge, wall_y),
		Vector2(right_edge, wall_y + 20.0), Vector2(0.0, wall_y + 20.0)
	])
	wall_mid_shadow.polygon = PackedVector2Array([
		Vector2(0.0, wall_y + 30.0), Vector2(right_edge, wall_y + 30.0),
		Vector2(right_edge, wall_y + 50.0), Vector2(0.0, wall_y + 50.0)
	])
	support_area.polygon = PackedVector2Array([
		Vector2(0.0, wall_bottom), Vector2(right_edge, wall_bottom),
		Vector2(right_edge, BASE_VIEWPORT_HEIGHT), Vector2(0.0, BASE_VIEWPORT_HEIGHT)
	])
	wall_front_shadow.polygon = PackedVector2Array([
		Vector2(0.0, wall_bottom), Vector2(right_edge, wall_bottom),
		Vector2(right_edge, wall_shadow_bottom), Vector2(0.0, wall_shadow_bottom)
	])
	back_yard_boundary.polygon = PackedVector2Array([
		Vector2(0.0, 840.0), Vector2(right_edge, 840.0),
		Vector2(right_edge, BASE_VIEWPORT_HEIGHT), Vector2(0.0, BASE_VIEWPORT_HEIGHT)
	])

	# --- Center-aligned elements ---
	lane_marker.position.x = center_x
	wall_camera_focus.position.x = center_x
	back_area_camera_focus.position.x = center_x
	gate_arch.position.x = center_x
	ladder.position.x = center_x
	ladder_top_zone.position.x = center_x
	ladder_bottom_zone.position.x = center_x

	# --- Right tower ---
	right_tower.polygon = PackedVector2Array([
		Vector2(right_tower_left, 180.0), Vector2(right_edge, 180.0),
		Vector2(right_edge, BASE_VIEWPORT_HEIGHT), Vector2(right_tower_left, BASE_VIEWPORT_HEIGHT)
	])
	right_tower_cap.polygon = PackedVector2Array([
		Vector2(right_tower_left, 160.0), Vector2(right_edge, 160.0),
		Vector2(right_edge, 210.0), Vector2(right_tower_left, 210.0)
	])
	right_tower_highlight.polygon = PackedVector2Array([
		Vector2(right_tower_left + 18.0, 190.0), Vector2(right_tower_left + 62.0, 190.0),
		Vector2(right_tower_left + 62.0, BASE_VIEWPORT_HEIGHT), Vector2(right_tower_left + 18.0, BASE_VIEWPORT_HEIGHT)
	])
	right_tower_window.polygon = PackedVector2Array([
		Vector2(right_tower_left + 86.0, 620.0), Vector2(right_tower_left + 126.0, 620.0),
		Vector2(right_tower_left + 126.0, 698.0), Vector2(right_tower_left + 86.0, 698.0)
	])
	right_tower_window_glow.polygon = PackedVector2Array([
		Vector2(right_tower_left + 92.0, 632.0), Vector2(right_tower_left + 120.0, 632.0),
		Vector2(right_tower_left + 120.0, 686.0), Vector2(right_tower_left + 92.0, 686.0)
	])

	# --- Player ---
	player.wall_y = wall_y + player_wall_offset
	player.left_bound = 170.0
	player.right_bound = viewport_size.x - 170.0
	if player_is_on_lower_lane:
		player.set_free_move_bounds(80.0, viewport_size.x - 80.0, lower_area_top_y, lower_area_bottom_y)
	else:
		_apply_player_upper_lane_bounds(viewport_size)
	player.global_position.x = clamp(player.global_position.x, player.left_bound, player.right_bound)

	# --- Camera & shop ---
	shop_zone.global_position = shop_marker.global_position
	game_camera.limit_right = int(right_edge)
	game_camera.limit_bottom = int(BASE_VIEWPORT_HEIGHT)
	if not is_ladder_transitioning:
		game_camera.global_position = back_area_camera_focus.global_position if player_is_on_lower_lane else wall_camera_focus.global_position

	# --- Wall sprites (only rebuild if already initialized) ---
	if not wall_body_sprites.is_empty() or not wall_pillar_sprites.is_empty():
		_build_wall_sprites()

	if not turret_visuals.is_empty():
		_update_turret_visual()
	if catapult_visual != null and is_instance_valid(catapult_visual):
		_update_catapult_visual()

	# --- UI panels ---
	_set_centered_control_rect(prompt_label, 820.0, min(652.0, viewport_size.x - 80.0), 36.0)
	_set_centered_control_rect(message_label, 120.0, min(600.0, viewport_size.x - 80.0), 34.0)
	_sync_label_chip(prompt_label, prompt_chip, 14.0, 8.0)
	_sync_label_chip(message_label, message_chip, 14.0, 8.0)
	_set_centered_control_rect(boss_bar_panel, 10.0, min(600.0, viewport_size.x - 120.0), 40.0)
	_set_centered_control_rect(wave_banner, 52.0, min(520.0, viewport_size.x - 120.0), 66.0)
	_set_centered_control_rect(boss_reward_panel, 160.0, min(520.0, viewport_size.x - 60.0), 240.0)
	_set_centered_control_rect(shop_panel, 52.0, min(620.0, viewport_size.x - 40.0), min(680.0, viewport_size.y - 80.0))
	_set_centered_control_rect(main_menu_panel, 170.0, min(360.0, viewport_size.x - 80.0), 230.0)
	_set_centered_control_rect(pause_panel, 170.0, min(360.0, viewport_size.x - 80.0), 250.0)
	_set_centered_control_rect(game_over_panel, 190.0, min(360.0, viewport_size.x - 80.0), 230.0)
	if options_panel != null:
		_set_centered_control_rect(options_panel, 130.0, min(460.0, viewport_size.x - 80.0), min(420.0, viewport_size.y - 120.0))
	if tutorial_panel != null:
		_set_centered_control_rect(tutorial_panel, 120.0, min(620.0, viewport_size.x - 60.0), min(360.0, viewport_size.y - 120.0))

	_apply_ui_layout_polish(viewport_size)


func _set_centered_control_rect(control: Control, y: float, width: float, height: float) -> void:
	control.position = Vector2(get_viewport_rect().size.x * 0.5 - width * 0.5, y)
	control.size = Vector2(width, height)


func _build_notice_chips() -> void:
	prompt_chip = Panel.new()
	prompt_chip.visible = false
	prompt_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_chip.z_index = 19
	ui_root.add_child(prompt_chip)

	message_chip = Panel.new()
	message_chip.visible = false
	message_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_chip.z_index = 19
	ui_root.add_child(message_chip)

	prompt_label.z_index = 20
	message_label.z_index = 20


func _sync_label_chip(label: Control, chip: Panel, pad_x: float = 14.0, pad_y: float = 8.0) -> void:
	if chip == null:
		return
	chip.position = label.position - Vector2(pad_x, pad_y)
	chip.size = label.size + Vector2(pad_x * 2.0, pad_y * 2.0)


func _apply_ui_layout_polish(viewport_size: Vector2) -> void:
	# Make fixed-offset shop children follow panel size to avoid clipping.
	var shop_shadow: Control = $UI/ShopPanel/ShopShadow
	var shop_backdrop: Control = $UI/ShopPanel/ShopBackdrop
	var shop_inner_shade: Control = $UI/ShopPanel/ShopInnerShade
	var shop_top_accent: Control = $UI/ShopPanel/ShopTopAccent
	var shop_divider_1: Control = $UI/ShopPanel/ShopDivider1
	var shop_divider_2: Control = $UI/ShopPanel/ShopDivider2
	var shop_vbox: VBoxContainer = $UI/ShopPanel/VBoxContainer
	var shop_info_panel: Panel = $UI/ShopPanel/VBoxContainer/InfoPanel

	shop_shadow.offset_right = shop_panel.size.x - 4.0
	shop_shadow.offset_bottom = shop_panel.size.y - 4.0
	shop_backdrop.offset_right = shop_panel.size.x - 8.0
	shop_backdrop.offset_bottom = shop_panel.size.y - 8.0
	shop_inner_shade.offset_right = shop_panel.size.x - 18.0
	shop_inner_shade.offset_bottom = shop_panel.size.y - 18.0
	shop_top_accent.offset_right = shop_panel.size.x - 18.0
	shop_divider_1.offset_right = shop_panel.size.x - 28.0
	shop_divider_2.offset_right = shop_panel.size.x - 28.0
	shop_vbox.offset_right = shop_panel.size.x - 28.0
	shop_vbox.offset_bottom = shop_panel.size.y - 20.0

	# Responsive text sizing for small widths.
	var compact_ui := viewport_size.x < 1120.0
	var shop_font := 15 if compact_ui else 16
	var small_shop_font := 13 if compact_ui else 14
	for b in [
		wall_upgrade_button, keep_upgrade_button, turret_button, catapult_button,
		repair_button, fire_rate_button, damage_button, trap_button, fire_trap_button, slow_trap_button, close_button
	]:
		b.add_theme_font_size_override("font_size", shop_font)
		b.custom_minimum_size.y = 42
	for b in [fortress_tab_button, defenses_tab_button, tactics_tab_button, traps_tab_button, turret_mode_button, catapult_mode_button]:
		b.add_theme_font_size_override("font_size", small_shop_font)

	if compact_ui:
		shop_info_panel.custom_minimum_size.y = 102
		shop_info_body_label.add_theme_font_size_override("font_size", 14)
	else:
		shop_info_panel.custom_minimum_size.y = 92
		shop_info_body_label.add_theme_font_size_override("font_size", 15)

	# HUD and combat text scale for smaller displays.
	var hud_compact := viewport_size.x < 1080.0
	hud_root.scale = Vector2(0.94, 0.94) if hud_compact else Vector2.ONE
	hud_root.position = Vector2(12.0, 8.0) if hud_compact else Vector2(16.0, 10.0)

	for label in [hp_label, coins_label, score_label, wave_label, phase_label, trap_label]:
		label.add_theme_font_size_override("font_size", 14 if hud_compact else 15)
	hud_stats_title.add_theme_font_size_override("font_size", 17 if hud_compact else 18)
	hud_combat_title.add_theme_font_size_override("font_size", 17 if hud_compact else 18)
	prompt_label.add_theme_font_size_override("font_size", 18 if hud_compact else 20)
	message_label.add_theme_font_size_override("font_size", 16 if hud_compact else 18)
	wave_banner.add_theme_font_size_override("font_size", 27 if hud_compact else 30)

	# Keep vertical spacing readable when many controls are present.
	shop_vbox.add_theme_constant_override("separation", 7 if compact_ui else 8)


func _process(delta: float) -> void:
	_update_music(delta)
	if get_tree().paused or is_game_over:
		return

	if status_message_time > 0.0:
		status_message_time = max(status_message_time - delta, 0.0)
		message_label.visible = status_message_time > 0.0
		if status_message_time <= 0.0:
			message_label.text = ""
	else:
		message_label.visible = false
	if message_chip != null:
		message_chip.visible = message_label.visible

	if current_phase == PHASE_PREP and battle_started:
		prep_time_remaining = max(prep_time_remaining - delta, 0.0)
		if prep_time_remaining <= 0.0 and not is_ladder_transitioning:
			if player_is_on_lower_lane:
				_set_status_message("Prep over - climbing to the wall.", 1.2)
				_toggle_ladder_lane()
			elif current_phase == PHASE_PREP:
				_begin_next_wave()

	if turret_level > 0:
		turret_fire_timer = max(turret_fire_timer - delta, 0.0)
	if catapult_level > 0:
		catapult_fire_timer = max(catapult_fire_timer - delta, 0.0)

	if current_phase == PHASE_BATTLE:
		_update_trap_triggers()
		_update_turret_attack()
		_update_catapult_attack()

	_update_hud()
	_update_prompt()
	if prompt_chip != null:
		prompt_chip.visible = prompt_label.visible
	_update_trap_coverage_indicators()
	_update_boss_ui()


func _start_game() -> void:
	main_menu_panel.visible = false
	if options_panel != null:
		options_panel.visible = false
	get_tree().paused = false
	battle_started = false
	_start_prep_phase()
	_set_status_message("Prepare your defenses.", 1.5)


func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _toggle_pause() -> void:
	if is_game_over or main_menu_panel.visible:
		return

	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	pause_panel.visible = is_paused
	if not is_paused and options_panel != null:
		options_panel.visible = false


func _setup_input_actions() -> void:
	_ensure_action("move_left", [_make_key_event(KEY_A), _make_key_event(KEY_LEFT), _make_joy_button_event(JOY_BUTTON_DPAD_LEFT)])
	_ensure_action("move_right", [_make_key_event(KEY_D), _make_key_event(KEY_RIGHT), _make_joy_button_event(JOY_BUTTON_DPAD_RIGHT)])
	_ensure_action("move_up", [_make_key_event(KEY_W), _make_key_event(KEY_UP), _make_joy_button_event(JOY_BUTTON_DPAD_UP)])
	_ensure_action("move_down", [_make_key_event(KEY_S), _make_key_event(KEY_DOWN), _make_joy_button_event(JOY_BUTTON_DPAD_DOWN)])
	_ensure_action("shoot", [_make_key_event(KEY_SPACE), _make_mouse_event(MOUSE_BUTTON_LEFT), _make_joy_button_event(JOY_BUTTON_X)])
	_ensure_action("interact", [_make_key_event(KEY_E), _make_joy_button_event(JOY_BUTTON_A)])
	_ensure_action("pause", [_make_key_event(KEY_ESCAPE), _make_joy_button_event(JOY_BUTTON_START)])
	_ensure_action("toggle_fullscreen", [_make_key_event(KEY_F11)])
	_ensure_action("ui_accept", [_make_key_event(KEY_ENTER), _make_joy_button_event(JOY_BUTTON_A)])
	_ensure_action("ui_cancel", [_make_key_event(KEY_ESCAPE), _make_joy_button_event(JOY_BUTTON_B), _make_joy_button_event(JOY_BUTTON_START)])
	_ensure_action("ui_left", [_make_key_event(KEY_LEFT), _make_joy_button_event(JOY_BUTTON_DPAD_LEFT)])
	_ensure_action("ui_right", [_make_key_event(KEY_RIGHT), _make_joy_button_event(JOY_BUTTON_DPAD_RIGHT)])
	_ensure_action("ui_up", [_make_key_event(KEY_UP), _make_joy_button_event(JOY_BUTTON_DPAD_UP)])
	_ensure_action("ui_down", [_make_key_event(KEY_DOWN), _make_joy_button_event(JOY_BUTTON_DPAD_DOWN)])


func _ensure_action(action_name: String, events: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for event in events:
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


func _make_key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	return event


func _make_mouse_event(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event


func _make_joy_button_event(button_index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	return event


func _start_prep_phase() -> void:
	current_phase = PHASE_PREP
	prep_time_remaining = prep_phase_duration
	enemy_spawn_queue.clear()
	enemies_to_spawn = 0
	enemy_spawner.stop()
	_sync_knight_guards(true)
	if not player_is_on_lower_lane:
		_apply_player_upper_lane_bounds(get_viewport_rect().size)
	_refresh_shop_buttons()
	_update_turret_visual()
	_update_hud()


func _begin_next_wave() -> void:
	if current_phase == PHASE_BATTLE:
		return

	turret_preview_hovered = false
	current_phase = PHASE_BATTLE
	wave_index += 1
	enemy_spawn_queue = _build_wave_queue(wave_index)
	enemies_to_spawn = enemy_spawn_queue.size()
	_sync_knight_guards(true)
	_refresh_shop_buttons()
	_update_turret_visual()
	var wave_banner_text: String = "Wave %d Start" % wave_index
	if wave_index % 5 == 0:
		wave_banner_text = "MECHA-STONE GOLEM" if _get_boss_enemy_type(wave_index) == "mecha_boss" else "Boss Wave %d" % wave_index
	_show_wave_banner(wave_banner_text)
	_play_sound("wave_start")
	_set_status_message(_get_wave_hint(wave_index), 2.2)
	_set_next_spawn_time()
	if not player_is_on_lower_lane:
		_apply_player_upper_lane_bounds(get_viewport_rect().size)
	_update_hud()


func _build_wave_queue(target_wave: int) -> Array:
	match target_wave:
		1:
			return ["grunt", "grunt", "grunt", "grunt"]
		2:
			return ["grunt", "grunt", "grunt", "runner", "grunt"]
		3:
			return ["grunt", "grunt", "runner", "grunt", "ranged", "grunt"]
		4:
			return ["grunt", "grunt", "runner", "ranged", "shield", "grunt", "grunt"]
		5:
			return ["grunt", "grunt", "runner", "ranged", "shield", _get_boss_enemy_type(target_wave)]
		6:
			return ["grunt", "runner", "ranged", "shield", "tank", "grunt", "grunt", "grunt"]
		7:
			return ["grunt", "runner", "ranged", "shield", "tank", "armored", "grunt", "grunt", "grunt"]

	var queue: Array = []
	var total := 4 + int(target_wave * 1.5)
	for i in range(total):
		queue.append("grunt")

	_replace_random_enemy_types(queue, "runner", 1 + int(target_wave / 4))
	_replace_random_enemy_types(queue, "ranged", 1 + int((target_wave - 1) / 4))
	_replace_random_enemy_types(queue, "shield", int((target_wave - 2) / 4))
	_replace_random_enemy_types(queue, "tank", int((target_wave - 3) / 5))
	_replace_random_enemy_types(queue, "armored", int((target_wave - 4) / 5))

	if target_wave >= 8:
		var elite_count: int = min(1 + int((target_wave - 8) / 3), max(queue.size() - 2, 1))
		for i in range(elite_count):
			var index := randi() % queue.size()
			var queued_enemy_type: String = str(queue[index])
			if queued_enemy_type != "boss" and queued_enemy_type != "mecha_boss":
				queue[index] = "elite_" + queued_enemy_type

	if target_wave % 5 == 0:
		queue.append(_get_boss_enemy_type(target_wave))
		queue.append("grunt")

	queue.shuffle()
	return queue


func _replace_random_enemy_types(queue: Array, enemy_type: String, count: int) -> void:
	for i in range(max(count, 0)):
		if queue.is_empty():
			return
		queue[randi() % queue.size()] = enemy_type


func _get_boss_enemy_type(target_wave: int) -> String:
	var boss_phase_index: int = int(target_wave / 5)
	return "mecha_boss" if boss_phase_index % 2 == 0 else "boss"


func _get_wave_hint(target_wave: int) -> String:
	match target_wave:
		1:
			return "Wave 1: basic goblins only. Learn the ladder and bow."
		2:
			return "Wave 2: runners are fast, but they go down quickly."
		3:
			return "Wave 3: raiders stop early and shoot the wall. Focus them first."
		4:
			return "Wave 4: shield bearers can block a few hits before taking damage."
		5:
			return "Boss wave: the war chief is coming with a small escort."
		6:
			return "Wave 6: tanks are slow but sturdy. Keep firing."
		7:
			return "Wave 7: armored goblins reduce damage from weak hits."
	if target_wave % 10 == 0:
		return "Boss wave: the Mecha-Stone Golem is charging its laser barrage."
	if target_wave % 5 == 0:
		return "Boss wave! Strengthen the wall before the next assault."
	return "Mixed wave incoming. Use the shop between waves to stay ahead."


func _set_next_spawn_time() -> void:
	if current_phase != PHASE_BATTLE or enemies_to_spawn <= 0:
		return

	if wave_index <= 1:
		enemy_spawner.wait_time = 1.55
	elif wave_index == 2:
		enemy_spawner.wait_time = 1.4
	elif wave_index == 3:
		enemy_spawner.wait_time = 1.28
	elif wave_index == 4:
		enemy_spawner.wait_time = 1.18
	else:
		enemy_spawner.wait_time = max(0.5, 1.15 - wave_index * 0.035)
	enemy_spawner.start()


func _on_enemy_spawner_timeout() -> void:
	if is_game_over or current_phase != PHASE_BATTLE or enemies_to_spawn <= 0:
		return

	_spawn_enemy()
	enemies_to_spawn -= 1
	if enemies_to_spawn > 0:
		_set_next_spawn_time()


func _spawn_enemy() -> void:
	var enemy: Node = ENEMY_SCENE.instantiate()
	var viewport_size: Vector2 = get_viewport_rect().size
	var enemy_type: String = "grunt"
	var is_elite: bool = false
	if enemy_spawn_queue.size() > 0:
		enemy_type = str(enemy_spawn_queue.pop_back())
	if enemy_type.begins_with("elite_"):
		is_elite = true
		enemy_type = enemy_type.substr(6)

	var spawn_x: float = randf_range(110.0, viewport_size.x - 110.0)
	var spawn_y: float = randf_range(-140.0, -30.0)
	var wall_target_x: float = randf_range(190.0, viewport_size.x - 190.0)
	var wall_target: Vector2 = Vector2(wall_target_x, wall_y - 18.0)

	enemy.global_position = Vector2(spawn_x, spawn_y)
	enemy.wall_y = wall_y - 16.0
	enemy.enemy_killed.connect(_on_enemy_killed)
	enemy.reached_wall.connect(_on_enemy_reached_wall)
	if enemy.has_signal("wall_attacked"):
		enemy.wall_attacked.connect(_on_enemy_wall_attacked)
	if enemy.has_signal("enemy_hit"):
		enemy.enemy_hit.connect(_on_enemy_hit)
	enemies_alive += 1
	enemies_container.add_child(enemy)
	if enemy.has_method("configure"):
		var definition: Dictionary = _get_enemy_definition(enemy_type)
		definition["target_position"] = wall_target
		definition["stop_distance"] = 16.0
		if enemy_type == "ranged":
			definition["stop_distance"] = 22.0
		if enemy_type == "boss":
			definition["stop_distance"] = 28.0
		if enemy_type == "mecha_boss":
			definition["stop_distance"] = 34.0
		if is_elite:
			definition = _make_elite_enemy(definition)
		enemy.configure(definition)
		_show_enemy_tutorial(enemy_type)


func _get_enemy_definition(enemy_type: String) -> Dictionary:
	var base_speed := 72.0 + float(max(wave_index - 1, 0)) * 4.5
	var base_hp := 1 + int((wave_index - 1) / 4)
	var base_reward := 1 + int((wave_index - 1) / 2)

	match enemy_type:
		"runner":
			return {
				"enemy_type": "runner",
				"speed": base_speed + 26.0,
				"max_health": max(1, base_hp),
				"coin_reward": base_reward,
				"castle_damage": 1,
				"armor": 0,
				"scale": 0.88,
				"tint": Color(0.82, 1.0, 0.86, 1.0),
				"burst_speed_multiplier": 1.45,
				"burst_duration": 0.32,
				"burst_cooldown": 1.1
			}
		"ranged":
			return {
				"enemy_type": "ranged",
				"speed": max(50.0, base_speed - 12.0),
				"max_health": base_hp,
				"coin_reward": base_reward + 1,
				"castle_damage": 1,
				"armor": 0,
				"scale": 0.96,
				"tint": Color(0.96, 0.92, 0.7, 1.0),
				"attack_mode": "ranged",
				"attack_interval": max(1.15, 2.0 - wave_index * 0.02),
				"attack_line_y": wall_y - 108.0
			}
		"tank":
			return {
				"enemy_type": "tank",
				"speed": max(46.0, base_speed - 18.0),
				"max_health": base_hp + 2,
				"coin_reward": base_reward + 2,
				"castle_damage": 2,
				"armor": 0,
				"scale": 1.24,
				"tint": Color(1.0, 0.86, 0.8, 1.0)
			}
		"shield":
			return {
				"enemy_type": "shield",
				"speed": max(54.0, base_speed - 10.0),
				"max_health": base_hp + 1,
				"coin_reward": base_reward + 1,
				"castle_damage": 1,
				"armor": 0,
				"shield_points": 1 + int(wave_index / 7),
				"scale": 1.12,
				"tint": Color(0.85, 0.92, 1.0, 1.0)
			}
		"armored":
			return {
				"enemy_type": "armored",
				"speed": max(54.0, base_speed - 8.0),
				"max_health": base_hp + 1,
				"coin_reward": base_reward + 1,
				"castle_damage": 1,
				"armor": 1,
				"scale": 1.06,
				"tint": Color(0.8, 0.9, 1.0, 1.0)
			}
		"boss":
			return {
				"enemy_type": "boss",
				"speed": max(40.0, base_speed - 24.0),
				"max_health": 7 + int(round(wave_index * 1.6)),
				"coin_reward": 12 + wave_index,
				"castle_damage": 2,
				"armor": int(wave_index / 15),
				"scale": 1.66,
				"tint": Color(1.0, 0.72, 0.72, 1.0),
				"elite": true,
				"attack_mode": "ranged",
				"attack_interval": max(1.05, 1.45 - wave_index * 0.015),
				"attack_line_y": wall_y - 150.0
			}
		"mecha_boss":
			return {
				"enemy_type": "mecha_boss",
				"speed": max(34.0, base_speed - 28.0),
				"max_health": 10 + int(round(wave_index * 1.85)),
				"coin_reward": 14 + wave_index,
				"castle_damage": 3,
				"armor": 1 + int(wave_index / 12),
				"scale": 1.75,
				"tint": Color(0.84, 0.95, 1.08, 1.0),
				"elite": true,
				"attack_mode": "ranged",
				"attack_interval": max(1.2, 1.7 - wave_index * 0.012),
				"attack_line_y": wall_y - 168.0
			}
		_:
			return {
				"enemy_type": "grunt",
				"speed": base_speed,
				"max_health": base_hp,
				"coin_reward": base_reward,
				"castle_damage": 1,
				"armor": 0,
				"scale": 1.0,
				"tint": Color(1, 1, 1, 1)
			}


func _make_elite_enemy(definition: Dictionary) -> Dictionary:
	var elite_definition: Dictionary = definition.duplicate(true)
	elite_definition["elite"] = true
	elite_definition["max_health"] = int(elite_definition.get("max_health", 1)) + 1
	elite_definition["coin_reward"] = int(elite_definition.get("coin_reward", 1)) + 2
	elite_definition["castle_damage"] = int(elite_definition.get("castle_damage", 1)) + 1
	elite_definition["scale"] = float(elite_definition.get("scale", 1.0)) * 1.06
	var tint: Color = elite_definition.get("tint", Color.WHITE)
	elite_definition["tint"] = Color(min(tint.r + 0.08, 1.0), min(tint.g + 0.08, 1.0), min(tint.b + 0.08, 1.0), tint.a)
	return elite_definition


func _show_enemy_tutorial(enemy_type: String) -> void:
	if not tutorial_enabled or shown_enemy_tutorials.has(enemy_type):
		return

	var message := ""
	match enemy_type:
		"runner":
			message = "Runner goblins are quick but fragile. Pick them off fast."
		"ranged":
			message = "Ranged goblins stop before the wall and shoot. Focus them first."
		"shield":
			message = "Shield bearers block a few hits. Keep shooting to break through."
		"tank":
			message = "Tanks are slow and bulky. Use steady damage and traps."
		"armored":
			message = "Armored goblins shrug off weak hits. Upgrades help against them."
		"boss":
			message = "Boss incoming. Keep the wall healthy and stay on target."
		"mecha_boss":
			message = "The Mecha-Stone Golem is here. Watch for heavy laser hits on the wall."
		_:
			return

	shown_enemy_tutorials[enemy_type] = true
	_set_status_message(message, 2.8)


func _on_player_shoot_requested(spawn_position: Vector2, target_position: Vector2) -> void:
	if is_game_over or get_tree().paused:
		return

	var on_battlefield: bool = current_phase == PHASE_BATTLE and GameState.is_battlefield_character() and not player_is_on_lower_lane
	if current_phase != PHASE_BATTLE or player_is_on_lower_lane:
		if not on_battlefield:
			return

	_play_sound("shoot")
	var arrow = ARROW_SCENE.instantiate()
	arrow.global_position = spawn_position
	if GameState.selected_character == GameState.CHAR_WIZARD or GameState.selected_character == GameState.CHAR_MERCHANT:
		arrow.is_wizard = true
	elif GameState.selected_character == GameState.CHAR_RANGER:
		arrow.is_huntress = true
	if arrow.has_method("set_damage"):
		arrow.set_damage(_get_player_arrow_damage())
	if GameState.ranger_should_pierce():
		arrow.pierce = true
	projectiles_container.add_child(arrow)

	if arrow.has_method("set_direction"):
		arrow.set_direction(target_position)


func _on_player_melee_impact(pos: Vector2, radius: float) -> void:
	var ring := Node2D.new()
	ring.position = pos
	ring.z_index = 10
	add_child(ring)

	var line := Line2D.new()
	line.width = 6.0
	line.default_color = Color(1.0, 0.65, 0.1, 1.0)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	var points: PackedVector2Array = []
	var steps := 32
	for i in range(steps + 1):
		var angle := (float(i) / float(steps)) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	line.points = points
	ring.add_child(line)

	var fill := Line2D.new()
	fill.width = radius * 2.0
	fill.default_color = Color(1.0, 0.65, 0.1, 0.18)
	fill.joint_mode = Line2D.LINE_JOINT_ROUND
	fill.points = points
	ring.add_child(fill)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.5, 1.5), 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(line, "default_color:a", 0.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(fill, "default_color:a", 0.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(ring.queue_free)


func _on_enemy_killed(reward: int) -> void:
	coins += reward + GameState.bonus_coins_per_kill()
	score += 10 * max(wave_index, 1)
	enemies_alive = max(enemies_alive - 1, 0)
	_play_sound("enemy_die")
	_check_wave_clear()
	_update_hud()
	_refresh_shop_buttons()


func _on_enemy_hit(damage_dealt: int, killed: bool, target_type: String, world_position: Vector2, elite: bool) -> void:
	if target_type == "shield_block":
		_spawn_floating_text(world_position, "BLOCK", Color(0.72, 0.9, 1.0, 1.0), 18, 0.45)
		_play_sound("deny")
		return

	var hit_color := Color(1.0, 0.92, 0.45, 1.0)
	if target_type == "armored":
		hit_color = Color(0.72, 0.88, 1.0, 1.0)
	elif target_type == "boss":
		hit_color = Color(1.0, 0.52, 0.52, 1.0)
	elif target_type == "mecha_boss":
		hit_color = Color(0.55, 0.9, 1.0, 1.0)
	elif elite:
		hit_color = Color(1.0, 0.8, 0.25, 1.0)
	_spawn_floating_text(world_position, str(damage_dealt), hit_color, 24 if elite or target_type == "boss" or target_type == "mecha_boss" else 20)
	if killed:
		_spawn_floating_text(world_position + Vector2(0, -18), "KO!", Color(1.0, 0.96, 0.7, 1.0), 18, 0.55)
		return
	_play_sound("enemy_hit", {"damage": damage_dealt, "target_type": target_type})


func _on_enemy_wall_attacked(damage: int) -> void:
	if is_game_over:
		return

	castle_hp = max(castle_hp - damage, 0)
	_flash_wall_hit()
	_play_sound("wall_hit")
	_set_status_message("Ranged attack hit the wall for %d!" % damage, 1.0)
	_spawn_floating_text(Vector2(lane_marker.global_position.x, wall_y - 46.0), "-%d" % damage, Color(1.0, 0.5, 0.45, 1.0), 22)
	_update_hud()
	if castle_hp <= 0:
		_trigger_game_over()


func _on_enemy_reached_wall(damage: int) -> void:
	if is_game_over:
		return

	enemies_alive = max(enemies_alive - 1, 0)
	castle_hp = max(castle_hp - damage, 0)
	_flash_wall_hit()
	_play_sound("wall_hit")
	_set_status_message("The wall took %d damage!" % damage, 1.0)
	_spawn_floating_text(Vector2(lane_marker.global_position.x, wall_y - 46.0), "-%d" % damage, Color(1.0, 0.45, 0.4, 1.0), 22)
	_check_wave_clear()
	_update_hud()

	if castle_hp <= 0:
		_trigger_game_over()


func _check_wave_clear() -> void:
	if current_phase != PHASE_BATTLE:
		return

	if enemies_to_spawn <= 0 and enemies_alive <= 0:
		score += 50 * wave_index
		var clear_bonus_coins := 2 + int((wave_index - 1) / 2)
		coins += clear_bonus_coins
		_show_wave_banner("Wave %d Cleared" % wave_index)
		_play_sound("wave_clear")
		_set_status_message("Wave clear bonus: +%d coins. Prep time to repair and upgrade." % clear_bonus_coins, 1.8)
		boss_reward_pending = wave_index % 5 == 0
		_start_prep_phase()
		if boss_reward_pending:
			_open_boss_reward_panel()


func _trigger_game_over() -> void:
	is_game_over = true
	enemy_spawner.stop()
	shop_panel.visible = false
	_hide_tutorial()
	get_tree().paused = true

	if player.has_method("die"):
		player.die()

	game_over_panel.visible = true


func _on_shop_zone_body_entered(body: Node2D) -> void:
	if is_game_over:
		return

	if body == player:
		player_in_shop_zone = true


func _on_shop_zone_body_exited(body: Node2D) -> void:
	if body != player:
		return

	player_in_shop_zone = false
	if shop_panel.visible:
		_close_shop()


func _on_ladder_top_zone_body_entered(body: Node2D) -> void:
	if body == player:
		player_near_ladder_top = true


func _on_ladder_top_zone_body_exited(body: Node2D) -> void:
	if body == player:
		player_near_ladder_top = false


func _on_ladder_bottom_zone_body_entered(body: Node2D) -> void:
	if body == player:
		player_near_ladder_bottom = true


func _on_ladder_bottom_zone_body_exited(body: Node2D) -> void:
	if body == player:
		player_near_ladder_bottom = false


func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action("toggle_fullscreen") and event.is_action_pressed("toggle_fullscreen"):
		display_mode = "windowed" if display_mode == "fullscreen" else "fullscreen"
		_apply_settings()
		_save_settings()
		get_viewport().set_input_as_handled()
		return

	if options_panel != null and options_panel.visible and InputMap.has_action("pause") and event.is_action_pressed("pause"):
		_close_options()
		get_viewport().set_input_as_handled()
		return

	if main_menu_panel.visible:
		return

	if boss_reward_panel.visible:
		if InputMap.has_action("pause") and event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
		return

	if tutorial_panel != null and tutorial_panel.visible:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			_advance_tutorial()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_cancel"):
			_skip_tutorial()
			get_viewport().set_input_as_handled()
			return

	if InputMap.has_action("pause") and event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return

	if is_game_over:
		return

	if _should_climb_up(event):
		_toggle_ladder_lane()
		get_viewport().set_input_as_handled()
		return

	if _should_climb_down(event):
		_toggle_ladder_lane()
		get_viewport().set_input_as_handled()
		return

	if InputMap.has_action("interact") and event.is_action_pressed("interact"):
		if player_in_shop_zone and not shop_panel.visible and current_phase == PHASE_PREP:
			_open_shop()
			get_viewport().set_input_as_handled()
			return


func _open_shop() -> void:
	shop_dimmer.visible = true
	shop_panel.visible = true
	hud_root.modulate = Color(1, 1, 1, 0.3)
	prompt_label.visible = false
	message_label.visible = false
	_hide_tutorial()
	current_shop_tab = SHOP_TAB_FORTRESS
	_refresh_shop_buttons()
	_update_turret_visual()
	_update_shop_tab_visibility()
	_update_shop_tab_info()
	shop_message_label.text = ""
	_play_sound("shop_open")
	get_tree().paused = true


func _should_climb_up(event: InputEvent) -> bool:
	if is_ladder_transitioning:
		return false

	return event.is_action_pressed("move_up") and player_is_on_lower_lane and (player_near_ladder_bottom or _is_player_near_ladder_bottom())


func _should_climb_down(event: InputEvent) -> bool:
	if is_ladder_transitioning:
		return false

	if current_phase != PHASE_PREP:
		return false

	return event.is_action_pressed("move_down") and not player_is_on_lower_lane and (player_near_ladder_top or _is_player_near_ladder_top())


func _toggle_ladder_lane() -> void:
	if is_ladder_transitioning:
		return

	is_ladder_transitioning = true
	player.set_movement_locked(true)

	var viewport_size: Vector2 = get_viewport_rect().size
	var going_up: bool = player_is_on_lower_lane
	var ladder_x: float = ladder_top_zone.global_position.x
	var target_y: float = player.wall_y if going_up else lower_lane_y
	var target_camera: Vector2 = wall_camera_focus.global_position if going_up else back_area_camera_focus.global_position

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(player, "global_position:x", ladder_x, 0.18)
	tween.parallel().tween_property(game_camera, "global_position", target_camera, ladder_transition_duration)
	tween.tween_property(player, "global_position:y", target_y, 0.37)
	await tween.finished

	if going_up:
		player_is_on_lower_lane = false
		_apply_player_upper_lane_bounds(viewport_size)
		player.global_position.x = ladder_top_zone.global_position.x
		game_camera.global_position = wall_camera_focus.global_position
		if not battle_started:
			battle_started = true
			_begin_next_wave()
		elif current_phase == PHASE_PREP and prep_time_remaining <= 0.0:
			_begin_next_wave()
	elif current_phase == PHASE_PREP:
		player_is_on_lower_lane = true
		player.set_free_move_bounds(80.0, viewport_size.x - 80.0, lower_area_top_y, lower_area_bottom_y)
		player.global_position = Vector2(ladder_bottom_zone.global_position.x, lower_lane_y)
		game_camera.global_position = back_area_camera_focus.global_position

	player.set_movement_locked(false)
	is_ladder_transitioning = false


func _is_player_near_ladder_bottom() -> bool:
	var dx: float = abs(player.global_position.x - ladder_bottom_zone.global_position.x)
	var dy: float = abs(player.global_position.y - ladder_bottom_zone.global_position.y)
	return dx <= 52.0 and dy <= 90.0


func _is_player_near_ladder_top() -> bool:
	var dx: float = abs(player.global_position.x - ladder_top_zone.global_position.x)
	var dy: float = abs(player.global_position.y - ladder_top_zone.global_position.y)
	return dx <= 52.0 and dy <= 72.0


func _close_shop() -> void:
	shop_dimmer.visible = false
	shop_panel.visible = false
	hud_root.modulate = Color(1, 1, 1, 1)
	prompt_label.visible = true
	turret_preview_hovered = false
	_update_turret_visual()
	_play_sound("shop_close")

	if not is_game_over:
		get_tree().paused = false


func _set_shop_tab(tab_name: String) -> void:
	current_shop_tab = tab_name
	_update_shop_tab_visibility()
	_update_shop_tab_info()
	_update_turret_visual()
	_play_sound("shop_open")


func _on_repair_button_pressed() -> void:
	_try_purchase(repair_cost, Callable(self, "_buy_repair"), "Wall repaired +2 HP.")


func _on_fire_rate_button_pressed() -> void:
	_try_purchase(_get_fire_rate_upgrade_cost(), Callable(self, "_buy_fire_rate_upgrade"), "Fire rate improved.")


func _on_damage_button_pressed() -> void:
	_try_purchase(_get_damage_upgrade_cost(), Callable(self, "_buy_damage_upgrade"), "Arrow damage increased.")


func _on_wall_upgrade_button_pressed() -> void:
	_try_purchase(_get_wall_upgrade_cost(), Callable(self, "_buy_wall_upgrade"), "Wall reinforced and strengthened.")


func _on_keep_upgrade_button_pressed() -> void:
	_try_purchase(_get_keep_upgrade_cost(), Callable(self, "_buy_keep_upgrade"), "Keep expanded. New fortress systems unlocked.")


func _on_turret_button_pressed() -> void:
	_try_purchase(_get_turret_cost(), Callable(self, "_buy_or_upgrade_turret"), "Arrow turret improved.")


func _on_catapult_button_pressed() -> void:
	_try_purchase(_get_catapult_cost(), Callable(self, "_buy_or_upgrade_catapult"), "Catapult reinforced.")


func _on_turret_mode_button_pressed() -> void:
	turret_target_mode = _get_next_target_mode(turret_target_mode)
	shop_message_label.text = "Turret target mode: %s" % _get_target_mode_display_name(turret_target_mode)
	_refresh_shop_buttons()


func _on_catapult_mode_button_pressed() -> void:
	catapult_target_mode = _get_next_target_mode(catapult_target_mode)
	shop_message_label.text = "Catapult target mode: %s" % _get_target_mode_display_name(catapult_target_mode)
	_refresh_shop_buttons()


func _on_trap_button_pressed() -> void:
	_try_purchase_trap(TRAP_SPIKE)


func _on_fire_trap_button_pressed() -> void:
	_try_purchase_trap(TRAP_FIRE)


func _on_slow_trap_button_pressed() -> void:
	_try_purchase_trap(TRAP_SLOW)


func _try_purchase(cost: int, action: Callable, success_message: String) -> void:
	if current_phase != PHASE_PREP:
		shop_message_label.text = "You can only shop during prep time."
		_play_sound("deny")
		return

	if coins < cost:
		shop_message_label.text = "Not enough coins."
		_play_sound("deny")
		return

	coins -= cost
	action.call()
	_play_sound("buy")
	shop_message_label.text = success_message
	_refresh_shop_buttons()
	_update_hud()


func _try_purchase_trap(trap_type: String) -> void:
	if current_phase != PHASE_PREP:
		shop_message_label.text = "You can only deploy traps during prep time."
		_play_sound("deny")
		return

	var free_index: int = _get_random_free_trap_point_index()
	if free_index == -1:
		shop_message_label.text = "All battlefield trap points are occupied."
		_play_sound("deny")
		return

	var cost: int = _get_trap_cost(trap_type)
	if coins < cost:
		shop_message_label.text = "Not enough coins."
		_play_sound("deny")
		return

	coins -= cost
	_deploy_trap_at_index(free_index, trap_type)
	_play_sound("buy")
	shop_message_label.text = "%s trap auto-deployed to the wall approach." % _get_trap_display_name(trap_type)
	_refresh_shop_buttons()
	_update_hud()


func _buy_repair() -> void:
	castle_hp = min(castle_hp + 2, max_castle_hp)


func _buy_fire_rate_upgrade() -> void:
	fire_rate_level += 1
	_apply_player_upgrades()


func _buy_damage_upgrade() -> void:
	damage_level += 1


func _buy_wall_upgrade() -> void:
	wall_level += 1
	max_castle_hp += 4
	castle_hp = min(castle_hp + 4, max_castle_hp)
	_update_castle_visuals()
	_sync_knight_guards(true)


func _buy_keep_upgrade() -> void:
	keep_level += 1
	max_castle_hp += 2
	castle_hp = min(castle_hp + 2, max_castle_hp)
	_update_castle_visuals()
	_sync_knight_guards(true)


func _buy_or_upgrade_turret() -> void:
	if keep_level < 1:
		return
	turret_level += 1
	turret_range = 280.0 + float(turret_level - 1) * 28.0
	_update_turret_visual()
	_update_castle_visuals()


func _buy_or_upgrade_catapult() -> void:
	if keep_level < 3:
		return
	catapult_level += 1
	catapult_range = 320.0 + float(catapult_level - 1) * 24.0
	_update_catapult_visual()
	_update_castle_visuals()


func _buy_spike_trap() -> void:
	trap_inventory[TRAP_SPIKE] += 1
	_refresh_trap_visuals()


func _buy_fire_trap() -> void:
	trap_inventory[TRAP_FIRE] += 1
	_refresh_trap_visuals()


func _buy_slow_trap() -> void:
	trap_inventory[TRAP_SLOW] += 1
	_refresh_trap_visuals()


func _get_random_free_trap_point_index() -> int:
	var free_indices: Array[int] = []
	for i in range(_get_active_trap_point_count()):
		if str(placed_traps[i]) == "":
			free_indices.append(i)
	if free_indices.is_empty():
		return -1
	return free_indices[randi() % free_indices.size()]


func _get_active_trap_point_count() -> int:
	return min(battlefield_trap_points.size(), 4 + max(wall_level - 1, 0) + max(keep_level - 1, 0))


func _deploy_trap_at_index(trap_index: int, trap_type: String) -> void:
	if trap_index < 0 or trap_index >= placed_traps.size():
		return
	placed_traps[trap_index] = trap_type
	trap_inventory[trap_type] += 1
	_refresh_trap_visuals()
	_set_status_message("%s trap deployed to a battlefield approach point." % _get_trap_display_name(trap_type), 1.2)


func _apply_player_upgrades() -> void:
	player.fire_cooldown = max(0.08, 0.25 - fire_rate_level * 0.03)
	player.melee_damage = 2 + damage_level


func _get_player_arrow_damage() -> int:
	return 1 + damage_level


func _get_fire_rate_upgrade_cost() -> int:
	return fire_rate_upgrade_cost + fire_rate_level * 3


func _get_damage_upgrade_cost() -> int:
	return damage_upgrade_cost + damage_level * 4


func _get_wall_upgrade_cost() -> int:
	return wall_upgrade_cost + (wall_level - 1) * 7


func _get_keep_upgrade_cost() -> int:
	return keep_upgrade_cost + (keep_level - 1) * 10


func _get_turret_cost() -> int:
	return turret_build_cost + max(turret_level - 1, 0) * 12


func _get_catapult_cost() -> int:
	return catapult_build_cost + max(catapult_level - 1, 0) * 16


func _get_trap_cost(trap_type: String) -> int:
	match trap_type:
		TRAP_FIRE:
			return fire_trap_cost + int(trap_inventory[TRAP_FIRE]) * 2
		TRAP_SLOW:
			return slow_trap_cost + int(trap_inventory[TRAP_SLOW]) * 2
		_:
			return spike_trap_cost + int(trap_inventory[TRAP_SPIKE]) * 2


func _update_trap_triggers() -> void:
	for i in range(_get_active_trap_point_count()):
		var trap_type := str(placed_traps[i])
		if trap_type == "":
			continue

		var trap_point: Vector2 = _get_trap_trigger_point(i)
		for enemy in enemies_container.get_children():
			if not is_instance_valid(enemy):
				continue
			if not enemy.has_method("take_damage"):
				continue
			if enemy.global_position.distance_to(trap_point) <= trap_trigger_radius:
				_trigger_trap(i, trap_type, trap_point)
				return


func _trigger_trap(slot_index: int, trap_type: String, slot_center: Vector2) -> void:
	match trap_type:
		TRAP_FIRE:
			_spawn_trap_trigger_flash(slot_center, Color(1.0, 0.45, 0.2, 0.85), 2.8)
			_play_sound("trap_fire")
			for enemy in enemies_container.get_children():
				if not is_instance_valid(enemy):
					continue
				if enemy.has_method("take_damage") and enemy.global_position.distance_to(slot_center) <= trap_trigger_radius * 1.85:
					enemy.take_damage(2 + damage_level)
			_set_status_message("Fire trap detonated!", 1.0)
		TRAP_SLOW:
			_spawn_trap_trigger_flash(slot_center, Color(0.58, 0.82, 1.0, 0.9), 3.0)
			_play_sound("trap_slow")
			for enemy in enemies_container.get_children():
				if not is_instance_valid(enemy):
					continue
				if enemy.global_position.distance_to(slot_center) > trap_trigger_radius * 2.25:
					continue
				if enemy.has_method("apply_slow"):
					enemy.apply_slow(0.38, 3.0)
				if enemy.has_method("take_damage"):
					enemy.take_damage(1)
			_set_status_message("Slow trap snared the wave!", 1.0)
		_:
			_spawn_trap_trigger_flash(slot_center, Color(1.0, 0.85, 0.35, 0.8), 2.2)
			_play_sound("trap_spike")
			var nearest_enemy: Node2D = null
			var nearest_distance := 99999.0
			for enemy in enemies_container.get_children():
				if not is_instance_valid(enemy):
					continue
				if not enemy.has_method("take_damage"):
					continue
				var distance: float = enemy.global_position.distance_to(slot_center)
				if distance < nearest_distance:
					nearest_enemy = enemy
					nearest_distance = distance
			if nearest_enemy != null:
				nearest_enemy.take_damage(999)
			_set_status_message("Spike trap triggered!", 1.0)

	placed_traps[slot_index] = ""
	trap_inventory[trap_type] = max(int(trap_inventory[trap_type]) - 1, 0)
	_refresh_trap_visuals()


func _get_trap_display_name(trap_type: String) -> String:
	match trap_type:
		TRAP_FIRE:
			return "Fire"
		TRAP_SLOW:
			return "Slow"
		_:
			return "Spike"


func _get_trap_trigger_point(slot_index: int) -> Vector2:
	if slot_index < 0 or slot_index >= battlefield_trap_points.size():
		return Vector2(lane_marker.global_position.x, wall_y - 70.0)
	return battlefield_trap_points[slot_index]


func _build_trap_coverage_indicators() -> void:
	for indicator in trap_coverage_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	trap_coverage_indicators.clear()

	for i in range(battlefield_trap_points.size()):
		var indicator: Polygon2D = Polygon2D.new()
		indicator.z_index = 4
		indicator.visible = false
		indicator.color = Color(1.0, 1.0, 1.0, 0.22)
		indicator.polygon = _get_trap_icon_polygon(TRAP_SPIKE)
		add_child(indicator)
		trap_coverage_indicators.append(indicator)


func _update_trap_coverage_indicators() -> void:
	if trap_coverage_indicators.is_empty():
		return

	var active_count: int = _get_active_trap_point_count()
	for i in range(trap_coverage_indicators.size()):
		var indicator := trap_coverage_indicators[i]
		if not is_instance_valid(indicator):
			continue

		var trap_type: String = str(placed_traps[i]) if i < placed_traps.size() else ""
		var trap_point: Vector2 = _get_trap_trigger_point(i)
		var slot_unlocked: bool = i < active_count
		var show_indicator: bool = current_phase == PHASE_PREP and trap_type != ""

		indicator.visible = slot_unlocked and (show_indicator or current_phase == PHASE_BATTLE and trap_type != "")
		indicator.modulate = Color(1, 1, 1, 1) if slot_unlocked else Color(1, 1, 1, 0.0)
		if not indicator.visible:
			continue

		indicator.global_position = trap_point
		indicator.rotation = 0.0
		indicator.scale = Vector2.ONE * (1.0 if current_phase == PHASE_BATTLE else 1.08)
		indicator.polygon = _get_trap_icon_polygon(trap_type)

		match trap_type:
			TRAP_FIRE:
				indicator.color = Color(1.0, 0.45, 0.2, 0.9 if current_phase == PHASE_BATTLE else 0.3)
			TRAP_SLOW:
				indicator.color = Color(0.58, 0.82, 1.0, 0.92 if current_phase == PHASE_BATTLE else 0.32)
			_:
				indicator.color = Color(1.0, 0.85, 0.35, 0.88 if current_phase == PHASE_BATTLE else 0.3)


func _refresh_trap_visuals() -> void:
	for indicator in trap_coverage_indicators:
		if not is_instance_valid(indicator):
			continue
		indicator.visible = false

	# Update trap sprites to match placed_traps
	for i in range(min(trap_sprites.size(), placed_traps.size())):
		var trap_spr := trap_sprites[i]
		if not is_instance_valid(trap_spr):
			continue
		var trap_type: String = str(placed_traps[i])
		if trap_type == "":
			trap_spr.visible = false
		else:
			trap_spr.visible = true
			match trap_type:
				TRAP_SPIKE:
					trap_spr.texture = BEAR_TRAP_TEX
					trap_spr.hframes = 3
					trap_spr.vframes = 1
					trap_spr.frame = 0
					trap_spr.modulate = Color(1, 1, 1, 1)
				TRAP_FIRE:
					trap_spr.texture = FIRE_TRAP_TEX
					trap_spr.hframes = 7
					trap_spr.vframes = 1
					trap_spr.frame = 3
					trap_spr.modulate = Color(1, 1, 1, 1)
				_:
					trap_spr.texture = BEAR_TRAP_TEX
					trap_spr.hframes = 3
					trap_spr.vframes = 1
					trap_spr.frame = 0
					trap_spr.modulate = Color(0.6, 0.8, 1.2, 1.0)


func _build_turret_visual() -> void:
	for visual in turret_visuals:
		if is_instance_valid(visual):
			visual.queue_free()
	for indicator in turret_range_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	turret_visuals.clear()
	turret_range_indicators.clear()

	for turret_position in turret_positions:
		var turret_sprite := Sprite2D.new()
		turret_sprite.texture = TURRET_FACE_TEX
		turret_sprite.z_index = 8
		turret_sprite.visible = false
		turret_sprite.position = turret_position
		turret_sprite.hframes = 1
		turret_sprite.vframes = 8
		turret_sprite.frame = 0
		turret_sprite.rotation = TURRET_IDLE_ROTATION
		turret_sprite.scale = Vector2(2.0, 2.0)
		add_child(turret_sprite)
		turret_visuals.append(turret_sprite)

		var indicator: Line2D = Line2D.new()
		indicator.z_index = 6
		indicator.visible = false
		indicator.width = 2.0
		indicator.default_color = Color(1.0, 0.86, 0.45, 0.18)
		indicator.closed = true
		indicator.position = turret_position
		add_child(indicator)
		turret_range_indicators.append(indicator)
	_update_turret_visual()


func _build_catapult_visual() -> void:
	if catapult_visual != null and is_instance_valid(catapult_visual):
		catapult_visual.queue_free()

	catapult_visual = Sprite2D.new()
	catapult_visual.texture = ARTILLERY_TEX
	catapult_visual.z_index = 8
	catapult_visual.visible = false
	catapult_visual.position = catapult_position
	catapult_visual.hframes = 3
	catapult_visual.vframes = 1
	catapult_visual.frame = 0
	# Artillery source is 362x257 (3 frames of ~120x257). Scale to ~50px tall
	catapult_visual.scale = Vector2(0.2, 0.2)
	add_child(catapult_visual)
	_update_catapult_visual()


func _build_wall_sprites() -> void:
	# Clear previous wall sprites
	for spr in wall_body_sprites:
		if is_instance_valid(spr):
			spr.queue_free()
	for spr in wall_pillar_sprites:
		if is_instance_valid(spr):
			spr.queue_free()
	wall_body_sprites.clear()
	wall_pillar_sprites.clear()

	_layout_wall_sprites()


func _layout_wall_sprites() -> void:
	# Wall is built from alternating body (inbetween_wall 338x256) and pillar (wall1 128x206) segments.
	# Target height: 90px. Anchored so bottom aligns with wall_y + 35 (center of wall band).
	var viewport_w := get_viewport_rect().size.x
	var wall_center_y := wall_y + 35.0  # visual center of the wall band

	var body_h := 256.0
	var body_w := 338.0
	var body_scale := 90.0 / body_h  # ~0.35
	var scaled_body_w := body_w * body_scale  # ~118px

	var pillar_h := 206.0
	var pillar_w := 128.0
	var pillar_scale := 100.0 / pillar_h  # ~0.485, pillars slightly taller than body
	var scaled_pillar_w := pillar_w * pillar_scale  # ~62px

	# Build the pattern: pillar, body, pillar, body, ... pillar
	# Calculate how many body segments we need to span the viewport
	var segment_w := scaled_body_w + scaled_pillar_w  # ~180px per body+pillar pair
	var num_bodies := int(ceil(viewport_w / segment_w)) + 1
	var total_w := float(num_bodies) * scaled_body_w + float(num_bodies + 1) * scaled_pillar_w
	var start_x := (viewport_w - total_w) * 0.5 + scaled_pillar_w * 0.5  # center the wall

	var cursor_x := start_x

	# Place pillars and bodies alternating
	for i in range(num_bodies + 1):
		# Place a pillar — texture depends on current wall_level
		var pillar := Sprite2D.new()
		var _ptex: Texture2D
		match wall_level:
			2: _ptex = WALL_LEVEL2_TEX
			3: _ptex = WALL_LEVEL3_TEX
			_: _ptex = WALL_LEVEL1_TEX
		pillar.texture = _ptex
		pillar.z_index = 6
		pillar.scale = Vector2(pillar_scale, pillar_scale)
		pillar.position = Vector2(cursor_x, wall_center_y)
		add_child(pillar)
		wall_pillar_sprites.append(pillar)
		cursor_x += scaled_pillar_w * 0.5

		if i < num_bodies:
			# Place a body segment
			cursor_x += scaled_body_w * 0.5
			var body := Sprite2D.new()
			body.texture = WALL_BATTLEMENT_TEX
			body.z_index = 5
			body.scale = Vector2(body_scale, body_scale)
			body.position = Vector2(cursor_x, wall_center_y)
			add_child(body)
			wall_body_sprites.append(body)
			cursor_x += scaled_body_w * 0.5 + scaled_pillar_w * 0.5


func _build_trap_sprites() -> void:
	# Clear old trap sprites
	for spr in trap_sprites:
		if is_instance_valid(spr):
			spr.queue_free()
	trap_sprites.clear()

	for i in range(battlefield_trap_points.size()):
		var trap_spr := Sprite2D.new()
		trap_spr.z_index = 7
		trap_spr.visible = false
		trap_spr.position = battlefield_trap_points[i]
		trap_spr.scale = Vector2(1.5, 1.5)
		add_child(trap_spr)
		trap_sprites.append(trap_spr)


func _update_castle_visuals() -> void:
	var wall_body_lighten: float = min(float(wall_level - 1) * 0.04, 0.16)
	castle_wall_band.color = Color(0.388235 + wall_body_lighten, 0.352941 + wall_body_lighten * 0.9, 0.294118 + wall_body_lighten * 0.75, 1)
	wall_highlight.color = Color(0.584314 + wall_body_lighten * 0.7, 0.529412 + wall_body_lighten * 0.6, 0.423529 + wall_body_lighten * 0.55, 0.45)
	wall_mid_shadow.color = Color(0, 0, 0, max(0.08, 0.12 - float(wall_level - 1) * 0.01))

	var keep_boost: float = min(float(keep_level - 1) * 0.05, 0.2)
	towers.scale = Vector2.ONE * (1.0 + float(keep_level - 1) * 0.03)
	towers.position.y = -float(keep_level - 1) * 6.0
	gate_arch.scale = Vector2.ONE * (2.0 + float(keep_level - 1) * 0.08)
	gate_arch.modulate = Color(1.0 + keep_boost * 0.2, 1.0 + keep_boost * 0.12, 1.0 + keep_boost * 0.08, 1.0)

	for tower_child in towers.get_children():
		var poly := tower_child as Polygon2D
		if poly == null:
			continue
		var color_name := String(poly.name)
		if color_name.contains("Glow"):
			poly.color = Color(0.980392, 0.572549 + keep_boost * 0.3, 0.192157 + keep_boost * 0.08, 0.28 + keep_boost * 0.25)
		elif color_name.contains("Highlight"):
			poly.color = Color(0.658824 + keep_boost * 0.18, 0.596078 + keep_boost * 0.16, 0.490196 + keep_boost * 0.14, 0.26)
		elif color_name.contains("Cap"):
			poly.color = Color(0.713726 + keep_boost * 0.12, 0.658824 + keep_boost * 0.1, 0.552941 + keep_boost * 0.08, 1)
		elif color_name.contains("Window"):
			poly.color = Color(0.180392, 0.14902, 0.117647, 1)
		else:
			poly.color = Color(0.294118 + keep_boost * 0.12, 0.262745 + keep_boost * 0.1, 0.219608 + keep_boost * 0.08, 1)

	_update_turret_visual()
	_update_catapult_visual()

	# Update pillar textures based on wall_level
	var pillar_tex: Texture2D
	match wall_level:
		1:
			pillar_tex = WALL_LEVEL1_TEX
		2:
			pillar_tex = WALL_LEVEL2_TEX
		_:
			pillar_tex = WALL_LEVEL3_TEX
	for pillar in wall_pillar_sprites:
		if is_instance_valid(pillar):
			pillar.texture = pillar_tex



func _build_circle_points(radius: float, segments: int = 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _set_turret_preview_hovered(is_hovered: bool) -> void:
	turret_preview_hovered = is_hovered
	_update_turret_visual()


func _spawn_turret_tracer(origin: Vector2, target: Vector2) -> void:
	var bullet := Sprite2D.new()
	bullet.texture = TURRET_BULLET_TEX
	bullet.z_index = 18
	bullet.position = origin
	bullet.scale = Vector2(2.0, 2.0)
	bullet.rotation = (target - origin).angle()
	add_child(bullet)
	var tween: Tween = bullet.create_tween()
	tween.tween_property(bullet, "position", target, 0.08)
	tween.parallel().tween_property(bullet, "modulate", Color(1, 1, 1, 0.3), 0.08)
	tween.tween_callback(bullet.queue_free)


func _spawn_turret_muzzle_flash(origin: Vector2) -> void:
	var flash: Polygon2D = Polygon2D.new()
	flash.z_index = 19
	flash.position = origin
	flash.color = Color(1.0, 0.92, 0.65, 0.95)
	flash.polygon = PackedVector2Array([
		Vector2(-6, 0), Vector2(-2, -2), Vector2(0, -8), Vector2(2, -2),
		Vector2(8, 0), Vector2(2, 2), Vector2(0, 8), Vector2(-2, 2)
	])
	add_child(flash)
	var tween: Tween = flash.create_tween()
	tween.parallel().tween_property(flash, "scale", Vector2(2.0, 2.0), 0.1)
	tween.parallel().tween_property(flash, "modulate", Color(1, 1, 1, 0), 0.1)
	tween.tween_callback(flash.queue_free)


func _spawn_turret_impact_sparks(position: Vector2) -> void:
	var sparks: Polygon2D = Polygon2D.new()
	sparks.z_index = 19
	sparks.position = position
	sparks.color = Color(1.0, 0.82, 0.38, 0.95)
	sparks.polygon = PackedVector2Array([
		Vector2(-10, 0), Vector2(-3, -3), Vector2(0, -11), Vector2(3, -3),
		Vector2(10, 0), Vector2(3, 3), Vector2(0, 11), Vector2(-3, 3)
	])
	add_child(sparks)
	var tween: Tween = sparks.create_tween()
	tween.parallel().tween_property(sparks, "scale", Vector2(1.8, 1.8), 0.12)
	tween.parallel().tween_property(sparks, "modulate", Color(1, 1, 1, 0), 0.12)
	tween.tween_callback(sparks.queue_free)


func _get_active_turret_count() -> int:
	if turret_level <= 0:
		return 0
	if keep_level >= 2 and turret_level >= 2:
		return min(2, turret_positions.size())
	return 1


func _update_turret_visual() -> void:
	if turret_visuals.is_empty():
		return

	var active_count := _get_active_turret_count()
	var show_range_preview: bool = current_phase == PHASE_PREP and shop_panel.visible and turret_preview_hovered
	for i in range(turret_visuals.size()):
		var turret_visual := turret_visuals[i]
		if not is_instance_valid(turret_visual):
			continue
		turret_visual.visible = i < active_count
		if i >= active_count:
			if i < turret_range_indicators.size() and is_instance_valid(turret_range_indicators[i]):
				turret_range_indicators[i].visible = false
			continue
		var mount_position: Vector2 = turret_positions[i] + Vector2(0, -float(max(wall_level - 1, 0)) * 4.0)
		turret_visual.position = mount_position
		turret_visual.rotation = lerp_angle(turret_visual.rotation, TURRET_IDLE_ROTATION, 0.18)
		turret_visual.scale = Vector2.ONE * (2.0 + float(turret_level - 1) * 0.2)
		if i < turret_range_indicators.size() and is_instance_valid(turret_range_indicators[i]):
			var indicator: Line2D = turret_range_indicators[i]
			indicator.position = mount_position
			indicator.visible = show_range_preview
			indicator.points = _build_circle_points(turret_range, 40)
			indicator.default_color = Color(1.0, 0.86, 0.45, 0.18 + min(float(turret_level) * 0.03, 0.08))


func _update_catapult_visual() -> void:
	if catapult_visual == null or not is_instance_valid(catapult_visual):
		return

	catapult_visual.visible = catapult_level > 0
	if catapult_level <= 0:
		return

	catapult_visual.position = catapult_position + Vector2(0, -float(max(wall_level - 1, 0)) * 4.0)
	catapult_visual.scale = Vector2.ONE * (0.2 + float(catapult_level - 1) * 0.03)


func _get_target_mode_display_name(mode: String) -> String:
	match mode:
		TARGET_STRONGEST:
			return "Strongest"
		TARGET_FASTEST:
			return "Fastest"
		TARGET_GROUPED:
			return "Grouped"
		_:
			return "Closest"


func _get_next_target_mode(mode: String) -> String:
	match mode:
		TARGET_CLOSEST:
			return TARGET_STRONGEST
		TARGET_STRONGEST:
			return TARGET_FASTEST
		TARGET_FASTEST:
			return TARGET_GROUPED
		_:
			return TARGET_CLOSEST


func _select_enemy_target(origin: Vector2, target_range: float, mode: String) -> Node2D:
	var best_enemy: Node2D = null
	var best_score: float = -INF
	for enemy in enemies_container.get_children():
		if not is_instance_valid(enemy):
			continue
		var enemy_node := enemy as Node2D
		if enemy_node == null:
			continue
		var distance: float = enemy_node.global_position.distance_to(origin)
		if distance > target_range:
			continue

		var health_value: float = float(enemy_node.get("current_health"))
		var speed_value: float = float(enemy_node.get("speed"))
		var grouped_value: float = 0.0
		if mode == TARGET_GROUPED:
			for other in enemies_container.get_children():
				if not is_instance_valid(other) or other == enemy_node:
					continue
				var other_node := other as Node2D
				if other_node != null and other_node.global_position.distance_to(enemy_node.global_position) <= 76.0:
					grouped_value += 1.0

		var score: float = 0.0
		match mode:
			TARGET_STRONGEST:
				score = health_value * 10.0 - distance * 0.02
			TARGET_FASTEST:
				score = speed_value * 8.0 - distance * 0.02
			TARGET_GROUPED:
				score = grouped_value * 20.0 + health_value - distance * 0.01
			_:
				score = -distance

		if score > best_score:
			best_score = score
			best_enemy = enemy_node
	return best_enemy


func _update_turret_attack() -> void:
	if turret_level <= 0 or current_phase != PHASE_BATTLE or turret_fire_timer > 0.0:
		return

	var fired: bool = false
	var active_count: int = _get_active_turret_count()
	for i in range(active_count):
		var mount_position: Vector2 = turret_positions[i] + Vector2(0, -float(max(wall_level - 1, 0)) * 4.0)
		var target := _select_enemy_target(mount_position, turret_range, turret_target_mode)
		if target == null:
			continue

		var arrow = ARROW_SCENE.instantiate()
		arrow.global_position = mount_position + Vector2(0, -10)
		if arrow.has_method("set_damage"):
			arrow.set_damage(2 + turret_level)
		projectiles_container.add_child(arrow)
		if arrow.has_method("set_direction"):
			arrow.set_direction(target.global_position)
		_spawn_turret_tracer(mount_position + Vector2(0, -10), target.global_position)
		_spawn_turret_muzzle_flash(mount_position + Vector2(0, -10))
		_spawn_turret_impact_sparks(target.global_position)
		fired = true
		_play_sound("turret_shoot")
		if i < turret_visuals.size() and is_instance_valid(turret_visuals[i]):
			var turret_visual := turret_visuals[i]
			var aim_angle: float = (target.global_position - mount_position).angle()
			turret_visual.rotation = aim_angle
			turret_visual.scale = Vector2.ONE * (2.4 + float(turret_level - 1) * 0.2)
			turret_visual.modulate = Color(1.3, 1.15, 0.8, 1.0)
			var tween: Tween = turret_visual.create_tween()
			tween.parallel().tween_property(turret_visual, "scale", Vector2.ONE * (2.0 + float(turret_level - 1) * 0.2), 0.12)
			tween.parallel().tween_property(turret_visual, "modulate", Color(1, 1, 1, 1), 0.16)
			tween.parallel().tween_property(turret_visual, "rotation", TURRET_IDLE_ROTATION, 0.18)

	if fired:
		turret_fire_timer = max(0.2, 0.75 - float(turret_level - 1) * 0.07)


func _update_catapult_attack() -> void:
	if catapult_level <= 0 or current_phase != PHASE_BATTLE or catapult_fire_timer > 0.0:
		return

	var target := _select_enemy_target(catapult_position, catapult_range, catapult_target_mode)
	if target == null:
		return
	if target.global_position.distance_to(catapult_position) > catapult_range:
		return

	var impact_point := target.global_position
	_spawn_trap_trigger_flash(impact_point, Color(1.0, 0.58, 0.26, 0.9), 3.4)
	_play_sound("catapult_shoot")
	for enemy in enemies_container.get_children():
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("take_damage"):
			continue
		if enemy.global_position.distance_to(impact_point) <= 78.0 + float(catapult_level) * 6.0 + catapult_aoe_bonus:
			enemy.take_damage(2 + catapult_level)

	catapult_fire_timer = max(1.3, 2.6 - float(catapult_level - 1) * 0.16)
	if catapult_visual != null and is_instance_valid(catapult_visual):
		catapult_visual.frame = 2  # firing frame
		catapult_visual.scale = Vector2.ONE * (0.24 + float(catapult_level - 1) * 0.03)
		var tween: Tween = catapult_visual.create_tween()
		tween.tween_property(catapult_visual, "scale", Vector2.ONE * (0.2 + float(catapult_level - 1) * 0.03), 0.16)
		tween.tween_callback(func(): catapult_visual.frame = 0)


func _get_trap_icon_polygon(trap_type: String) -> PackedVector2Array:
	match trap_type:
		TRAP_FIRE:
			return PackedVector2Array([
				Vector2(0, -12), Vector2(6, -4), Vector2(3, 2),
				Vector2(10, 8), Vector2(2, 12), Vector2(-2, 8),
				Vector2(-8, 12), Vector2(-5, 3), Vector2(-10, -2), Vector2(-3, -4)
			])
		TRAP_SLOW:
			return PackedVector2Array([
				Vector2(0, -12), Vector2(3, -3), Vector2(12, 0),
				Vector2(3, 3), Vector2(0, 12), Vector2(-3, 3),
				Vector2(-12, 0), Vector2(-3, -3)
			])
		_:
			return PackedVector2Array([
				Vector2(-10, 10), Vector2(-5, 0), Vector2(0, 10),
				Vector2(5, 0), Vector2(10, 10), Vector2(6, 10),
				Vector2(6, 12), Vector2(-6, 12), Vector2(-6, 10)
			])


func _spawn_floating_text(world_position: Vector2, text: String, color: Color, size: int = 20, life: float = 0.7) -> void:
	var floating_text := FLOATING_TEXT_SCRIPT.new()
	floating_text.position = world_position
	floating_text.z_index = 30
	floating_text.configure(text, color, size, life)
	add_child(floating_text)


func _flash_wall_hit() -> void:
	castle_wall_band.color = Color(0.72, 0.34, 0.3, 1)
	wall_highlight.color = Color(1.0, 0.6, 0.55, 0.55)
	wall_mid_shadow.color = Color(0.2, 0.0, 0.0, 0.22)
	gate_arch.modulate = Color(1.2, 0.8, 0.8, 1)
	towers.modulate = Color(1.08, 0.8, 0.8, 1)
	var original_camera: Vector2 = game_camera.global_position
	game_camera.global_position += Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0))
	var tween: Tween = castle_wall_band.create_tween()
	tween.parallel().tween_property(castle_wall_band, "color", Color(0.388235, 0.352941, 0.294118, 1), 0.24)
	tween.parallel().tween_property(wall_highlight, "color", Color(0.584314, 0.529412, 0.423529, 0.45), 0.24)
	tween.parallel().tween_property(wall_mid_shadow, "color", Color(0, 0, 0, 0.12), 0.24)
	tween.parallel().tween_property(gate_arch, "modulate", Color(1, 1, 1, 1), 0.24)
	tween.parallel().tween_property(towers, "modulate", Color(1, 1, 1, 1), 0.24)
	tween.parallel().tween_property(game_camera, "global_position", original_camera, 0.22)


func _show_wave_banner(message: String) -> void:
	wave_banner.text = message
	wave_banner.visible = true
	wave_banner.modulate = Color(1, 1, 1, 0)
	var tween: Tween = wave_banner.create_tween()
	tween.tween_property(wave_banner, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.tween_interval(0.9)
	tween.tween_property(wave_banner, "modulate", Color(1, 1, 1, 0), 0.35)
	tween.tween_callback(func():
		if is_instance_valid(wave_banner):
			wave_banner.visible = false
	)


func _spawn_trap_trigger_flash(position: Vector2, flash_color: Color = Color(1.0, 0.85, 0.35, 0.8), target_scale: float = 2.2) -> void:
	var flash: Polygon2D = Polygon2D.new()
	flash.z_index = 20
	flash.position = position
	flash.color = flash_color
	flash.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(-5, -5), Vector2(0, -14), Vector2(5, -5),
		Vector2(14, 0), Vector2(5, 5), Vector2(0, 14), Vector2(-5, 5)
	])
	add_child(flash)
	var tween: Tween = flash.create_tween()
	tween.parallel().tween_property(flash, "scale", Vector2(target_scale, target_scale), 0.18)
	tween.parallel().tween_property(flash, "modulate", Color(1, 1, 1, 0), 0.18)
	tween.tween_callback(flash.queue_free)


func _setup_audio() -> void:
	var sfx_map: Dictionary = {
		"shoot": SFX_ARROW_LAUNCH,
		"enemy_die": SFX_GOBLIN_DEATH,
		"trap_spike": SFX_BEAR_TRAP,
		"turret_shoot": SFX_TURRET_CRANK,
		"catapult_shoot": SFX_CANNON_FIRE,
		"trap_fire": SFX_CANNON_FIRE,
	}
	for event_name in sfx_map:
		var player_node := AudioStreamPlayer.new()
		player_node.stream = sfx_map[event_name]
		player_node.bus = "Master"
		player_node.volume_db = linear_to_db(sfx_volume)
		add_child(player_node)
		sfx_players[event_name] = player_node


func _make_kenney_panel_style(texture: Texture2D, tint: Color = Color(1, 1, 1, 1), content_margin: float = 12.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 12
	style.texture_margin_top = 12
	style.texture_margin_right = 12
	style.texture_margin_bottom = 12
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	style.modulate_color = tint
	return style


func _style_button_kenney(button: Button) -> void:
	if button == null:
		return

	var normal := _make_kenney_panel_style(UI_TUTORIAL_BTN_NORMAL_TEX, Color(0.34, 0.27, 0.18, 1.0), 10.0)
	var hover := _make_kenney_panel_style(UI_TUTORIAL_BTN_HOVER_TEX, Color(0.44, 0.35, 0.23, 1.0), 10.0)
	var pressed := _make_kenney_panel_style(UI_TUTORIAL_BTN_PRESSED_TEX, Color(0.25, 0.2, 0.14, 1.0), 10.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(0.98, 0.95, 0.86, 1))
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.75, 1))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.75, 1))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.62, 1))


func _apply_kenney_button_theme_to_tree(root: Node) -> void:
	for child in root.get_children():
		if child is Button:
			var button := child as Button
			if button != tutorial_button and button != tutorial_skip_button:
				_style_button_kenney(button)
		_apply_kenney_button_theme_to_tree(child)


func _apply_kenney_ui_theme() -> void:
	var solid_panel_style := _make_kenney_panel_style(UI_TUTORIAL_BTN_NORMAL_TEX, Color(0.14, 0.11, 0.08, 0.96), 14.0)
	var transparent_panel_style := _make_kenney_panel_style(UI_TUTORIAL_PANEL_TEX, Color(0.82, 0.7, 0.44, 1.0), 14.0)

	for panel in [shop_panel, boss_reward_panel, pause_panel, game_over_panel, main_menu_panel, boss_bar_panel, hud_panel]:
		if panel != null:
			panel.add_theme_stylebox_override("panel", solid_panel_style)
	if options_panel != null:
		options_panel.add_theme_stylebox_override("panel", solid_panel_style)
	if tutorial_panel != null:
		tutorial_panel.add_theme_stylebox_override("panel", transparent_panel_style)
	if prompt_chip != null:
		prompt_chip.add_theme_stylebox_override("panel", _make_kenney_panel_style(UI_TUTORIAL_PANEL_TEX, Color(0.18, 0.14, 0.1, 0.92), 10.0))
	if message_chip != null:
		message_chip.add_theme_stylebox_override("panel", _make_kenney_panel_style(UI_TUTORIAL_PANEL_TEX, Color(0.2, 0.15, 0.1, 0.95), 10.0))

	if $UI != null:
		_apply_kenney_button_theme_to_tree($UI)

	_apply_hud_text_theme()


func _apply_hud_text_theme() -> void:
	for title_label in [hud_stats_title, hud_combat_title]:
		title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52, 1))
		title_label.add_theme_font_size_override("font_size", 18)

	for stat_label in [hp_label, coins_label, score_label, wave_label, phase_label, trap_label]:
		stat_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
		stat_label.add_theme_font_size_override("font_size", 15)

	prompt_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	prompt_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.66, 1))
	message_label.add_theme_font_size_override("font_size", 18)
	boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62, 1))
	boss_name_label.add_theme_font_size_override("font_size", 16)
	wave_banner.add_theme_color_override("font_color", Color(1.0, 0.9, 0.68, 1))
	wave_banner.add_theme_color_override("font_shadow_color", Color(0.2, 0.12, 0.05, 0.55))
	wave_banner.add_theme_constant_override("shadow_offset_x", 2)
	wave_banner.add_theme_constant_override("shadow_offset_y", 2)


func _build_tutorial_ui() -> void:
	tutorial_panel = Panel.new()
	tutorial_panel.visible = false
	tutorial_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	tutorial_panel.modulate = Color(1, 1, 1, 0.98)

	var panel_style := _make_kenney_panel_style(UI_TUTORIAL_PANEL_TEX, Color(0.82, 0.7, 0.44, 1.0), 14.0)
	tutorial_panel.add_theme_stylebox_override("panel", panel_style)
	$UI.add_child(tutorial_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 18.0
	vbox.offset_top = 16.0
	vbox.offset_right = -18.0
	vbox.offset_bottom = -16.0
	vbox.add_theme_constant_override("separation", 8)
	tutorial_panel.add_child(vbox)

	tutorial_title_label = Label.new()
	tutorial_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_title_label.add_theme_font_size_override("font_size", 24)
	tutorial_title_label.add_theme_color_override("font_color", Color(1, 0.88, 0.58, 1))
	tutorial_title_label.custom_minimum_size = Vector2(0, 34)
	vbox.add_child(tutorial_title_label)

	tutorial_body_label = RichTextLabel.new()
	tutorial_body_label.bbcode_enabled = false
	tutorial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body_label.scroll_active = true
	tutorial_body_label.fit_content = false
	tutorial_body_label.selection_enabled = false
	tutorial_body_label.add_theme_font_size_override("normal_font_size", 16)
	tutorial_body_label.add_theme_color_override("default_color", Color(0.96, 0.94, 0.88, 1))
	tutorial_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tutorial_body_label.custom_minimum_size = Vector2(0, 180)
	vbox.add_child(tutorial_body_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(button_row)

	tutorial_skip_button = Button.new()
	tutorial_skip_button.custom_minimum_size = Vector2(150, 44)
	tutorial_skip_button.text = "Skip Tutorial"
	tutorial_skip_button.focus_mode = Control.FOCUS_ALL
	tutorial_skip_button.pressed.connect(_skip_tutorial)
	button_row.add_child(tutorial_skip_button)

	tutorial_button = Button.new()
	tutorial_button.custom_minimum_size = Vector2(190, 44)
	tutorial_button.text = "Got it"
	tutorial_button.focus_mode = Control.FOCUS_ALL
	tutorial_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_button.pressed.connect(_on_tutorial_button_pressed)
	button_row.add_child(tutorial_button)

	_style_button_kenney(tutorial_button)
	_style_button_kenney(tutorial_skip_button)


func _on_tutorial_button_pressed() -> void:
	_advance_tutorial()


func _skip_tutorial() -> void:
	_hide_tutorial()


func _show_tutorial(title: String, body: String, button_text: String = "Got it") -> void:
	if tutorial_panel == null:
		return
	tutorial_pages.clear()
	tutorial_page_index = -1
	tutorial_title_label.text = title
	tutorial_body_label.text = body
	tutorial_body_label.scroll_to_line(0)
	tutorial_button.text = button_text
	if tutorial_skip_button != null:
		tutorial_skip_button.visible = false
	tutorial_panel.visible = true
	tutorial_button.grab_focus()


func _show_tutorial_page(page_index: int) -> void:
	if tutorial_panel == null:
		return
	if page_index < 0 or page_index >= tutorial_pages.size():
		_hide_tutorial()
		return
	tutorial_page_index = page_index
	var page: Dictionary = tutorial_pages[page_index]
	tutorial_title_label.text = str(page.get("title", "How to Play"))
	tutorial_body_label.text = str(page.get("body", ""))
	tutorial_body_label.scroll_to_line(0)
	tutorial_button.text = "Start Defending" if page_index == tutorial_pages.size() - 1 else "Next"
	if tutorial_skip_button != null:
		tutorial_skip_button.visible = page_index < tutorial_pages.size() - 1
	tutorial_panel.visible = true
	tutorial_button.grab_focus()


func _advance_tutorial() -> void:
	if tutorial_pages.is_empty():
		_hide_tutorial()
		return
	var next_index := tutorial_page_index + 1
	if next_index >= tutorial_pages.size():
		_hide_tutorial()
		return
	_show_tutorial_page(next_index)


func _hide_tutorial() -> void:
	tutorial_pages.clear()
	tutorial_page_index = -1
	if tutorial_panel != null:
		tutorial_panel.visible = false


func _show_intro_tutorial() -> void:
	if not tutorial_enabled:
		return
	tutorial_pages = [
		{
			"title": "Movement",
			"body": "Move with [WASD] or Arrow Keys.\n\nPress [Enter] for next tip, or use [Skip Tutorial].\n\nIn prep phase, explore the yard and collect your bearings before climbing."
		},
		{
			"title": "Shop (Prep Only)",
			"body": "Walk to the shop area and press [E] to open the shop.\n\nSpend coins on wall repairs, upgrades, traps, and defenses before each wave."
		},
		{
			"title": "Ladder",
			"body": "At the ladder bottom, press [W] to climb to the wall.\n\nDuring prep only, press [S] at the top to climb back down."
		},
		{
			"title": "Combat",
			"body": "On the wall: aim with mouse and shoot with Click or [Space].\n\nPrioritize ranged enemies and runners. Keep your wall healthy."
		}
	]
	_show_tutorial_page(0)


func _build_options_ui() -> void:
	var main_menu_options_button := Button.new()
	main_menu_options_button.text = "Options"
	main_menu_options_button.focus_mode = Control.FOCUS_ALL
	main_menu_options_button.pressed.connect(_toggle_options)
	main_menu_vbox.add_child(main_menu_options_button)

	var pause_options_button := Button.new()
	pause_options_button.text = "Options"
	pause_options_button.focus_mode = Control.FOCUS_ALL
	pause_options_button.pressed.connect(_toggle_options)
	pause_vbox.add_child(pause_options_button)

	options_panel = OPTIONS_PANEL_SCENE.instantiate()
	options_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(options_panel)
	options_panel.close_requested.connect(_close_options)
	options_panel.settings_changed.connect(_on_options_settings_changed)


func _toggle_options() -> void:
	if options_panel == null:
		return
	var should_show: bool = not options_panel.visible
	options_panel.visible = should_show
	if should_show:
		options_panel.apply_settings(_get_settings_dictionary())
		options_panel.focus_default()


func _close_options() -> void:
	if options_panel == null:
		return
	options_panel.visible = false


func _get_settings_dictionary() -> Dictionary:
	return {
		"display_mode": display_mode,
		"resolution_scale": resolution_scale,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
	}


func _load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err == OK:
		master_volume = float(config.get_value("audio", "master_volume", 1.0))
		music_volume = float(config.get_value("audio", "music_volume", 0.6))
		sfx_volume = float(config.get_value("audio", "sfx_volume", 1.0))
		display_mode = str(config.get_value("video", "display_mode", "fullscreen"))
		resolution_scale = float(config.get_value("video", "resolution_scale", 1.0))
	else:
		display_mode = "fullscreen"
		resolution_scale = 1.0

	_apply_settings()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("video", "display_mode", display_mode)
	config.set_value("video", "resolution_scale", resolution_scale)
	config.save(SETTINGS_PATH)


func _apply_settings() -> void:
	master_volume = clamp(master_volume, 0.0, 1.0)
	music_volume = clamp(music_volume, 0.0, 1.0)
	sfx_volume = clamp(sfx_volume, 0.0, 1.0)
	resolution_scale = clamp(resolution_scale, 0.75, 1.5)

	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	match display_mode:
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		"windowed":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(int(BASE_VIEWPORT_WIDTH), int(BASE_VIEWPORT_HEIGHT)))
		_:
			display_mode = "fullscreen"
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	get_window().content_scale_factor = resolution_scale
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(max(master_volume, 0.0001)))

	# Update music volume
	if music_player != null:
		music_player.volume_db = linear_to_db(max(music_volume, 0.0001))

	# Update SFX volumes
	for key in sfx_players:
		var sfx_node: AudioStreamPlayer = sfx_players[key]
		if sfx_node != null:
			sfx_node.volume_db = linear_to_db(max(sfx_volume, 0.0001))

	if options_panel != null:
		options_panel.apply_settings(_get_settings_dictionary())


func _on_options_settings_changed(settings: Dictionary) -> void:
	display_mode = str(settings.get("display_mode", display_mode))
	resolution_scale = float(settings.get("resolution_scale", resolution_scale))
	master_volume = float(settings.get("master_volume", master_volume))
	music_volume = float(settings.get("music_volume", music_volume))
	sfx_volume = float(settings.get("sfx_volume", sfx_volume))
	_apply_settings()
	_save_settings()


func _play_sound(event_name: String, _data: Dictionary = {}) -> void:
	# Map aliases to loaded SFX players
	var key := event_name
	match event_name:
		"enemy_hit", "wall_hit":
			key = "shoot"  # reuse arrow impact sound for hits
		"trap_slow":
			key = "trap_spike"  # reuse bear trap sound
		"buy", "shop_open", "shop_close":
			key = "shoot"  # short click-like reuse
		"deny":
			key = "trap_spike"
		"wave_start", "wave_clear":
			key = "shoot"

	if sfx_players.has(key):
		var player_node: AudioStreamPlayer = sfx_players[key]
		player_node.volume_db = linear_to_db(max(sfx_volume, 0.0001))
		player_node.pitch_scale = randf_range(0.9, 1.1)
		player_node.play()


func _update_music(_delta: float) -> void:
	if music_player == null:
		return
	music_player.volume_db = linear_to_db(max(music_volume * master_volume, 0.0001))


func _update_shop_tab_visibility() -> void:
	_apply_shop_tab_style(fortress_tab_button, current_shop_tab == SHOP_TAB_FORTRESS)
	_apply_shop_tab_style(defenses_tab_button, current_shop_tab == SHOP_TAB_DEFENSES)
	_apply_shop_tab_style(tactics_tab_button, current_shop_tab == SHOP_TAB_TACTICS)
	_apply_shop_tab_style(traps_tab_button, current_shop_tab == SHOP_TAB_TRAPS)

	var show_fortress: bool = current_shop_tab == SHOP_TAB_FORTRESS
	var show_defenses: bool = current_shop_tab == SHOP_TAB_DEFENSES
	var show_tactics: bool = current_shop_tab == SHOP_TAB_TACTICS
	var show_traps: bool = current_shop_tab == SHOP_TAB_TRAPS

	structure_header.visible = show_fortress
	wall_upgrade_button.visible = show_fortress
	keep_upgrade_button.visible = show_fortress
	repair_button.visible = show_fortress

	upgrade_header.visible = show_defenses
	turret_button.visible = show_defenses
	catapult_button.visible = show_defenses
	fire_rate_button.visible = show_defenses
	damage_button.visible = show_defenses

	turret_mode_button.visible = show_tactics
	catapult_mode_button.visible = show_tactics

	trap_header.visible = show_traps
	trap_button.visible = show_traps
	fire_trap_button.visible = show_traps
	slow_trap_button.visible = show_traps


func _apply_shop_tab_style(tab_button: Button, active: bool) -> void:
	if tab_button == null:
		return

	tab_button.modulate = Color(1, 1, 1, 1)
	if active:
		tab_button.self_modulate = Color(1.0, 0.93, 0.74, 1.0)
		tab_button.scale = Vector2(1.02, 1.02)
	else:
		tab_button.self_modulate = Color(0.72, 0.7, 0.66, 1.0)
		tab_button.scale = Vector2.ONE


func _set_shop_info(title: String, body: String) -> void:
	shop_info_title_label.text = title
	shop_info_body_label.text = body


func _show_repair_info() -> void:
	_set_shop_info("Repair Wall", "Current wall HP: %d/%d\nRepairs +2 HP instantly during prep." % [castle_hp, max_castle_hp])


func _show_fire_rate_info() -> void:
	_set_shop_info("Fire Rate Lv.%d → Lv.%d" % [fire_rate_level, fire_rate_level + 1], "Current cooldown: %.2fs\nNext cooldown: %.2fs" % [player.fire_cooldown, max(0.08, 0.25 - (fire_rate_level + 1) * 0.03)])


func _show_damage_info() -> void:
	_set_shop_info("Arrow Damage Lv.%d → Lv.%d" % [damage_level, damage_level + 1], "Current damage: %d\nNext damage: %d" % [_get_player_arrow_damage(), _get_player_arrow_damage() + 1])


func _show_wall_upgrade_info() -> void:
	var next_guard_count: int = min(2 + max(wall_level, 0), guard_home_positions.size())
	var next_trap_points: int = min(battlefield_trap_points.size(), 4 + max(wall_level, 0) + max(keep_level - 1, 0))
	_set_shop_info("Wall Level %d → %d" % [wall_level, wall_level + 1], "Adds +4 max HP\nRaises knight defenders to %d\nExpands active trap coverage to %d points." % [next_guard_count, next_trap_points])


func _show_keep_upgrade_info() -> void:
	var unlock_text := ""
	if keep_level == 1:
		unlock_text = "Unlocks Arrow Turret"
	elif keep_level == 2:
		unlock_text = "Unlocks Catapult"
	else:
		unlock_text = "Improves fortress scale and coverage"
	_set_shop_info("Keep Level %d → %d" % [keep_level, keep_level + 1], "+1 max HP\n%s" % [unlock_text])


func _show_turret_info() -> void:
	var mounts_next := 1
	if keep_level >= 2 and turret_level + 1 >= 2:
		mounts_next = 2
	_set_shop_info("Arrow Turret Lv.%d → %d" % [max(turret_level, 0), max(turret_level + 1, 1)], "Current mounts: %d\nNext mounts: %d\nFast auto-defense with long range and stronger shots." % [_get_active_turret_count(), mounts_next])


func _show_turret_tactics_info() -> void:
	_set_shop_info("Turret Targeting", "Current mode: %s\nCycles: Closest, Strongest, Fastest, Grouped." % _get_target_mode_display_name(turret_target_mode))


func _show_catapult_info() -> void:
	_set_shop_info("Catapult Lv.%d → %d" % [max(catapult_level, 0), max(catapult_level + 1, 1)], "Current blast damage: %d\nNext blast damage: %d\nHeavy splash defense for clustered enemies." % [2 + catapult_level, 3 + catapult_level])


func _show_catapult_tactics_info() -> void:
	_set_shop_info("Catapult Targeting", "Current mode: %s\nGrouped works best against large pushes." % _get_target_mode_display_name(catapult_target_mode))


func _show_spike_trap_info() -> void:
	_set_shop_info("Spike Trap", "Armed now: %d\nInstantly deletes one target at a random open defense point." % int(trap_inventory[TRAP_SPIKE]))


func _show_fire_trap_info() -> void:
	_set_shop_info("Fire Trap", "Armed now: %d\nExplodes in an area and scales with your arrow damage upgrades." % int(trap_inventory[TRAP_FIRE]))


func _show_slow_trap_info() -> void:
	_set_shop_info("Slow Trap", "Armed now: %d\nSlows and chips enemies so your fortress can finish them off." % int(trap_inventory[TRAP_SLOW]))


func _update_shop_tab_info() -> void:
	match current_shop_tab:
		SHOP_TAB_DEFENSES:
			_set_shop_info("Defenses", "Turrets and catapults support you automatically. Build them up as the keep grows.")
		SHOP_TAB_TACTICS:
			_set_shop_info("Tactics", "Tune how automated defenses pick targets to handle runners, tanks, and clustered waves.")
		SHOP_TAB_TRAPS:
			_set_shop_info("Traps", "Active trap points: %d/%d\nBought traps auto-deploy to a random open battlefield point." % [_get_active_trap_point_count(), battlefield_trap_points.size()])
		_:
			_set_shop_info("Fortress Upgrades", "Wall Lv.%d | Keep Lv.%d | Knights %d\nGrow the castle, unlock defenses, and send more defenders out through the gate." % [wall_level, keep_level, _get_active_knight_guard_count()])


func _refresh_shop_buttons() -> void:
	repair_button.text = "⚒ Repair Wall (%d) | %d/%d HP" % [repair_cost, castle_hp, max_castle_hp]
	fire_rate_button.text = "➤ Fire Rate Lv.%d (%d)" % [fire_rate_level + 1, _get_fire_rate_upgrade_cost()]
	damage_button.text = "✦ Arrow Damage Lv.%d (%d)" % [damage_level + 1, _get_damage_upgrade_cost()]
	wall_upgrade_button.text = "Wall Level %d (%d)" % [wall_level + 1, _get_wall_upgrade_cost()]
	keep_upgrade_button.text = "Keep Level %d (%d)" % [keep_level + 1, _get_keep_upgrade_cost()]
	turret_button.text = "Arrow Turret Lv.%d | Mounts %d (%d)" % [max(turret_level, 1), _get_active_turret_count(), _get_turret_cost()]
	turret_mode_button.text = "Turret Target: %s" % _get_target_mode_display_name(turret_target_mode)
	catapult_button.text = "Catapult Lv.%d %s" % [max(catapult_level, 1), "(%d)" % _get_catapult_cost() if keep_level >= 3 else "(Unlock at Keep 3)"]
	catapult_mode_button.text = "Catapult Target: %s" % _get_target_mode_display_name(catapult_target_mode)
	trap_button.text = "▲ Buy Spike Trap (%d) | Armed: %d" % [_get_trap_cost(TRAP_SPIKE), int(trap_inventory[TRAP_SPIKE])]
	fire_trap_button.text = "✹ Buy Fire Trap (%d) | Armed: %d" % [_get_trap_cost(TRAP_FIRE), int(trap_inventory[TRAP_FIRE])]
	slow_trap_button.text = "❄ Buy Slow Trap (%d) | Armed: %d" % [_get_trap_cost(TRAP_SLOW), int(trap_inventory[TRAP_SLOW])]

	var can_shop := current_phase == PHASE_PREP
	var has_free_trap_point: bool = _get_random_free_trap_point_index() != -1
	repair_button.disabled = can_shop == false or castle_hp >= max_castle_hp
	fire_rate_button.disabled = can_shop == false
	damage_button.disabled = can_shop == false
	wall_upgrade_button.disabled = can_shop == false
	keep_upgrade_button.disabled = can_shop == false
	turret_button.disabled = can_shop == false
	turret_mode_button.disabled = can_shop == false or turret_level <= 0
	catapult_button.disabled = can_shop == false or keep_level < 3
	catapult_mode_button.disabled = can_shop == false or catapult_level <= 0
	trap_button.disabled = can_shop == false or not has_free_trap_point
	fire_trap_button.disabled = can_shop == false or not has_free_trap_point
	slow_trap_button.disabled = can_shop == false or not has_free_trap_point
	_update_shop_tab_visibility()


func _update_prompt() -> void:
	if shop_panel.visible or boss_reward_panel.visible:
		prompt_label.text = ""
		return

	var prompt := ""
	if current_phase == PHASE_PREP and player_is_on_lower_lane:
		if player_in_shop_zone:
			prompt = "Press E to open shop and spend coins"
		elif player_near_ladder_bottom or _is_player_near_ladder_bottom():
			prompt = "Press W to climb to the wall when ready"
		elif tutorial_enabled and not battle_started:
			prompt = "Move with WASD or arrows. Explore the yard before starting."
		elif _has_armed_traps():
			prompt = "Armed trap markers show active battlefield coverage"
	elif current_phase == PHASE_PREP and not player_is_on_lower_lane:
		if player_near_ladder_top or _is_player_near_ladder_top():
			prompt = "Press S to return to the yard"
	elif current_phase == PHASE_BATTLE and player_is_on_lower_lane:
		prompt = "Battle active - climb back to the wall"
	elif current_phase == PHASE_BATTLE and tutorial_enabled and wave_index == 1:
		prompt = "Aim with the mouse and click or press Space to shoot"

	prompt_label.text = prompt


func _has_armed_traps() -> bool:
	for trap_type in placed_traps:
		if str(trap_type) != "":
			return true
	return false


func _set_status_message(message: String, duration: float = 1.2) -> void:
	status_message = message
	status_message_time = duration
	message_label.text = message
	message_label.visible = true


func _get_active_boss() -> Node:
	for enemy in enemies_container.get_children():
		if not is_instance_valid(enemy):
			continue
		if enemy.has_method("is_boss_enemy") and enemy.is_boss_enemy():
			return enemy
	return null


func _update_boss_ui() -> void:
	var boss: Node = _get_active_boss()
	if boss == null:
		boss_bar_panel.visible = false
		return

	boss_bar_panel.visible = true
	if boss.has_method("get_display_name"):
		boss_name_label.text = str(boss.get_display_name())
	else:
		boss_name_label.text = "Boss"

	var ratio: float = 1.0
	if boss.has_method("get_health_ratio"):
		ratio = float(boss.get_health_ratio())
	boss_bar_fill.scale.x = clamp(ratio, 0.0, 1.0)
	boss_bar_fill.color = Color(1.0, 0.32 + ratio * 0.35, 0.26 + ratio * 0.12, 1.0)


func _open_boss_reward_panel() -> void:
	boss_reward_pending = true
	boss_reward_panel.visible = true
	boss_reward_title.text = "Boss defeated! Choose one blessing:"
	boss_reward_button_1.text = "Reinforce Wall\n+1 Max HP, heal 2"
	boss_reward_button_2.text = "Sharpen Arrows\n+1 Damage this run"
	boss_reward_button_3.text = "Rapid Volley\n+1 Fire Rate level"
	get_tree().paused = true


func _claim_boss_reward(reward_type: String) -> void:
	match reward_type:
		BOSS_REWARD_REINFORCE:
			max_castle_hp += 1
			castle_hp = min(castle_hp + 2, max_castle_hp)
			_set_status_message("Wall reinforced after the boss fight.", 1.5)
		BOSS_REWARD_SHARPEN:
			damage_level += 1
			_set_status_message("Arrow damage permanently improved for this run.", 1.5)
		_:
			fire_rate_level += 1
			_apply_player_upgrades()
			_set_status_message("Your archers can fire faster now.", 1.5)

	boss_reward_pending = false
	boss_reward_panel.visible = false
	if not is_game_over:
		get_tree().paused = false
	_refresh_shop_buttons()
	_update_hud()


func _update_hud() -> void:
	hp_label.text = "Wall L%d  HP:%d/%d" % [wall_level, castle_hp, max_castle_hp]
	coins_label.text = "Coins: %d" % coins
	score_label.text = "Keep L%d  Score:%d" % [keep_level, score]
	if wave_index > 0:
		wave_label.text = "Wave: %d" % wave_index
	else:
		wave_label.text = "Wave: -"
	trap_label.text = "S:%d F:%d L:%d T:%d K:%d" % [int(trap_inventory[TRAP_SPIKE]), int(trap_inventory[TRAP_FIRE]), int(trap_inventory[TRAP_SLOW]), _get_active_turret_count(), _get_active_knight_guard_count()]

	var hp_ratio: float = clamp(float(castle_hp) / max(float(max_castle_hp), 1.0), 0.0, 1.0)
	hp_bar_fill.scale.x = hp_ratio
	if hp_ratio > 0.6:
		hp_bar_fill.color = Color(0.32, 0.86, 0.38, 1.0)
	elif hp_ratio > 0.3:
		hp_bar_fill.color = Color(0.95, 0.74, 0.22, 1.0)
	else:
		hp_bar_fill.color = Color(0.92, 0.28, 0.22, 1.0)

	if current_phase == PHASE_PREP:
		phase_label.text = "Prep: %.0fs" % ceil(prep_time_remaining)
	else:
		phase_label.text = "Battle: %d left" % (enemies_to_spawn + enemies_alive)
