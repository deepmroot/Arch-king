extends Node2D

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const ARROW_SCENE := preload("res://scenes/Arrow.tscn")
const FLOATING_TEXT_SCRIPT := preload("res://scripts/floating_text.gd")
const OPTIONS_PANEL_SCENE := preload("res://scenes/OptionsPanel.tscn")

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

@export var starting_hp := 10
@export var max_castle_hp := 15
@export var wall_y := 90.0
@export var wall_margin_from_bottom := 90.0
@export var repair_cost := 5
@export var spike_trap_cost := 6
@export var fire_trap_cost := 8
@export var slow_trap_cost := 9
@export var fire_rate_upgrade_cost := 8
@export var damage_upgrade_cost := 10
@export var wall_upgrade_cost := 12
@export var keep_upgrade_cost := 18
@export var turret_build_cost := 16
@export var catapult_build_cost := 34
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
var turret_positions: Array[Vector2] = [Vector2(500, 432), Vector2(652, 432)]
var turret_visuals: Array[Polygon2D] = []
var turret_range_indicators: Array[Line2D] = []
var turret_preview_hovered := false
var turret_target_mode := TARGET_CLOSEST
var catapult_level := 0
var catapult_fire_timer := 0.0
var catapult_range := 320.0
var catapult_position := Vector2(664, 426)
var catapult_visual: Polygon2D
var catapult_target_mode := TARGET_GROUPED
var trap_inventory: Dictionary = {
	TRAP_SPIKE: 0,
	TRAP_FIRE: 0,
	TRAP_SLOW: 0,
}
var battlefield_trap_points: Array[Vector2] = [
	Vector2(162, 402),
	Vector2(238, 396),
	Vector2(372, 384),
	Vector2(510, 398),
	Vector2(646, 386),
	Vector2(784, 400),
	Vector2(920, 388),
	Vector2(998, 398),
]
var placed_traps: Array[String] = ["", "", "", "", "", "", "", ""]
var trap_trigger_radius := 42.0
var enemy_spawn_queue: Array = []
var status_message := ""
var status_message_time := 0.0
var audio_players: Array[AudioStreamPlayer] = []
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
var music_step_time := 0.0
var music_step_index := 0
var music_melody := [261.63, 329.63, 392.0, 329.63, 293.66, 349.23, 440.0, 349.23]
var music_bass := [130.81, 0.0, 146.83, 0.0, 164.81, 0.0, 146.83, 0.0]

@onready var player = $Player
@onready var enemies_container = $Enemies
@onready var projectiles_container = $Projectiles
@onready var enemy_spawner: Timer = $EnemySpawner
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
	_setup_music()
	_build_options_ui()
	_load_settings()

	castle_hp = starting_hp
	wall_y = 470.0

	get_viewport().size_changed.connect(_update_responsive_layout)
	_update_responsive_layout()
	player.global_position = Vector2(ladder_bottom_zone.global_position.x, lower_lane_y)
	player.shoot_requested.connect(_on_player_shoot_requested)
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
	boss_reward_button_1.pressed.connect(func(): _claim_boss_reward(BOSS_REWARD_REINFORCE))
	boss_reward_button_2.pressed.connect(func(): _claim_boss_reward(BOSS_REWARD_SHARPEN))
	boss_reward_button_3.pressed.connect(func(): _claim_boss_reward(BOSS_REWARD_VOLLEY))

	boss_bar_panel.visible = false
	boss_reward_panel.visible = false
	shop_dimmer.visible = false
	shop_panel.visible = false
	game_over_panel.visible = false
	pause_panel.visible = false
	main_menu_panel.visible = true
	if options_panel != null:
		options_panel.visible = false
	message_label.visible = false
	prompt_label.text = ""
	_refresh_shop_buttons()
	_refresh_trap_visuals()
	_build_trap_coverage_indicators()
	_build_turret_visual()
	_build_catapult_visual()
	_update_castle_visuals()
	_start_prep_phase()
	get_tree().paused = true


func _update_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var center_x := viewport_size.x * 0.5
	var right_edge := viewport_size.x
	var right_tower_left := right_edge - BASE_RIGHT_TOWER_WIDTH

	background_forest.offset_right = right_edge
	background_forest.offset_bottom = 648.0
	background_path.offset_left = center_x - BASE_PATH_WIDTH * 0.5
	background_path.offset_right = center_x + BASE_PATH_WIDTH * 0.5
	background_path.offset_bottom = 648.0

	support_area.polygon = PackedVector2Array([
		Vector2(0.0, 540.0),
		Vector2(right_edge, 540.0),
		Vector2(right_edge, BASE_VIEWPORT_HEIGHT),
		Vector2(0.0, BASE_VIEWPORT_HEIGHT)
	])
	back_yard_boundary.polygon = PackedVector2Array([
		Vector2(0.0, 840.0),
		Vector2(right_edge, 840.0),
		Vector2(right_edge, BASE_VIEWPORT_HEIGHT),
		Vector2(0.0, BASE_VIEWPORT_HEIGHT)
	])
	wall_front_shadow.polygon = PackedVector2Array([
		Vector2(0.0, 540.0),
		Vector2(right_edge, 540.0),
		Vector2(right_edge, 566.0),
		Vector2(0.0, 566.0)
	])
	castle_wall_band.polygon = PackedVector2Array([
		Vector2(0.0, wall_y),
		Vector2(right_edge, wall_y),
		Vector2(right_edge, wall_y + 70.0),
		Vector2(0.0, wall_y + 70.0)
	])
	wall_highlight.polygon = PackedVector2Array([
		Vector2(0.0, 470.0),
		Vector2(right_edge, 470.0),
		Vector2(right_edge, 490.0),
		Vector2(0.0, 490.0)
	])
	wall_mid_shadow.polygon = PackedVector2Array([
		Vector2(0.0, 500.0),
		Vector2(right_edge, 500.0),
		Vector2(right_edge, 520.0),
		Vector2(0.0, 520.0)
	])

	lane_marker.position.x = center_x
	wall_camera_focus.position.x = center_x
	back_area_camera_focus.position.x = center_x
	gate_arch.position.x = center_x
	ladder.position.x = center_x
	ladder_top_zone.position.x = center_x
	ladder_bottom_zone.position.x = center_x
	wall_battlements.scale.x = right_edge / BASE_VIEWPORT_WIDTH

	right_tower.polygon = PackedVector2Array([
		Vector2(right_tower_left, 180.0),
		Vector2(right_edge, 180.0),
		Vector2(right_edge, BASE_VIEWPORT_HEIGHT),
		Vector2(right_tower_left, BASE_VIEWPORT_HEIGHT)
	])
	right_tower_cap.polygon = PackedVector2Array([
		Vector2(right_tower_left, 160.0),
		Vector2(right_edge, 160.0),
		Vector2(right_edge, 210.0),
		Vector2(right_tower_left, 210.0)
	])
	right_tower_highlight.polygon = PackedVector2Array([
		Vector2(right_tower_left + 18.0, 190.0),
		Vector2(right_tower_left + 62.0, 190.0),
		Vector2(right_tower_left + 62.0, BASE_VIEWPORT_HEIGHT),
		Vector2(right_tower_left + 18.0, BASE_VIEWPORT_HEIGHT)
	])
	right_tower_window.polygon = PackedVector2Array([
		Vector2(right_tower_left + 86.0, 620.0),
		Vector2(right_tower_left + 126.0, 620.0),
		Vector2(right_tower_left + 126.0, 698.0),
		Vector2(right_tower_left + 86.0, 698.0)
	])
	right_tower_window_glow.polygon = PackedVector2Array([
		Vector2(right_tower_left + 92.0, 632.0),
		Vector2(right_tower_left + 120.0, 632.0),
		Vector2(right_tower_left + 120.0, 686.0),
		Vector2(right_tower_left + 92.0, 686.0)
	])

	player.wall_y = wall_y + player_wall_offset
	player.left_bound = 170.0
	player.right_bound = viewport_size.x - 170.0
	if player_is_on_lower_lane:
		player.set_free_move_bounds(80.0, viewport_size.x - 80.0, lower_area_top_y, lower_area_bottom_y)
	else:
		player.set_lane(player.wall_y, 170.0, viewport_size.x - 170.0)
	player.global_position.x = clamp(player.global_position.x, player.left_bound, player.right_bound)

	shop_zone.global_position = shop_marker.global_position
	game_camera.limit_right = int(right_edge)
	game_camera.limit_bottom = int(BASE_VIEWPORT_HEIGHT)
	if not is_ladder_transitioning:
		game_camera.global_position = back_area_camera_focus.global_position if player_is_on_lower_lane else wall_camera_focus.global_position

	_set_centered_control_rect(prompt_label, 820.0, min(652.0, viewport_size.x - 80.0), 36.0)
	_set_centered_control_rect(message_label, 120.0, min(600.0, viewport_size.x - 80.0), 34.0)
	_set_centered_control_rect(boss_bar_panel, 10.0, min(600.0, viewport_size.x - 120.0), 40.0)
	_set_centered_control_rect(wave_banner, 52.0, min(520.0, viewport_size.x - 120.0), 66.0)
	_set_centered_control_rect(boss_reward_panel, 170.0, 420.0, 220.0)
	_set_centered_control_rect(shop_panel, 62.0, 516.0, 586.0)
	_set_centered_control_rect(main_menu_panel, 180.0, 320.0, 210.0)
	_set_centered_control_rect(pause_panel, 180.0, 320.0, 210.0)
	_set_centered_control_rect(game_over_panel, 200.0, 300.0, 150.0)
	if options_panel != null:
		_set_centered_control_rect(options_panel, 150.0, 380.0, 260.0)


func _set_centered_control_rect(control: Control, y: float, width: float, height: float) -> void:
	control.position = Vector2(get_viewport_rect().size.x * 0.5 - width * 0.5, y)
	control.size = Vector2(width, height)


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
	get_tree().reload_current_scene()


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
	_refresh_shop_buttons()
	_update_turret_visual()
	_show_wave_banner("Boss Wave %d" % wave_index if wave_index % 5 == 0 else "Wave %d Start" % wave_index)
	_play_sound("wave_start")
	_set_status_message(_get_wave_hint(wave_index), 1.6)
	_set_next_spawn_time()
	_update_hud()


func _build_wave_queue(target_wave: int) -> Array:
	var queue: Array = []
	var total := 5 + target_wave * 2
	for i in range(total):
		queue.append("grunt")

	if target_wave >= 2:
		for i in range(1 + int(target_wave / 3)):
			queue[randi() % queue.size()] = "runner"

	if target_wave >= 3:
		for i in range(1 + int(target_wave / 4)):
			queue[randi() % queue.size()] = "ranged"

	if target_wave >= 4:
		for i in range(1 + int(target_wave / 4)):
			queue[randi() % queue.size()] = "tank"

	if target_wave >= 4:
		for i in range(1 + int(target_wave / 5)):
			queue[randi() % queue.size()] = "shield"

	if target_wave >= 6:
		for i in range(1 + int(target_wave / 5)):
			queue[randi() % queue.size()] = "armored"

	if target_wave >= 3:
		var elite_count := 1 + int(target_wave / 6)
		for i in range(min(elite_count, queue.size())):
			var index := randi() % queue.size()
			if queue[index] != "boss":
				queue[index] = "elite_" + str(queue[index])

	if target_wave % 5 == 0:
		queue.append("boss")
		queue.append("ranged")
		queue.append("runner")

	queue.shuffle()
	return queue


func _get_wave_hint(target_wave: int) -> String:
	if target_wave % 5 == 0:
		return "Boss wave! A war chief is leading the assault."
	if target_wave >= 6:
		return "Mixed wave incoming: runners, ranged, shield, tank, and armored enemies."
	if target_wave >= 4:
		return "Shield bearers are joining the assault."
	if target_wave >= 3:
		return "Ranged raiders spotted behind the front line."
	if target_wave >= 2:
		return "Runner goblins incoming. Keep a slow trap ready."
	return "First wave. Hold the wall."


func _set_next_spawn_time() -> void:
	if current_phase != PHASE_BATTLE or enemies_to_spawn <= 0:
		return

	enemy_spawner.wait_time = max(0.32, 1.12 - wave_index * 0.05)
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
		if is_elite:
			definition = _make_elite_enemy(definition)
		enemy.configure(definition)


func _get_enemy_definition(enemy_type: String) -> Dictionary:
	var base_speed := 84.0 + float(max(wave_index - 1, 0)) * 6.0
	var base_hp := 1 + int((wave_index - 1) / 3)
	var base_reward := 1 + int((wave_index - 1) / 2)

	match enemy_type:
		"runner":
			return {
				"enemy_type": "runner",
				"speed": base_speed + 34.0,
				"max_health": max(1, base_hp),
				"coin_reward": base_reward,
				"castle_damage": 1,
				"armor": 0,
				"scale": 0.88,
				"tint": Color(0.82, 1.0, 0.86, 1.0),
				"burst_speed_multiplier": 1.7,
				"burst_duration": 0.42,
				"burst_cooldown": 0.85
			}
		"ranged":
			return {
				"enemy_type": "ranged",
				"speed": max(58.0, base_speed - 8.0),
				"max_health": base_hp + 1,
				"coin_reward": base_reward + 1,
				"castle_damage": 1,
				"armor": 0,
				"scale": 1.0,
				"tint": Color(0.96, 0.92, 0.7, 1.0),
				"attack_mode": "ranged",
				"attack_interval": max(0.75, 1.45 - wave_index * 0.03),
				"attack_line_y": wall_y - 130.0
			}
		"tank":
			return {
				"enemy_type": "tank",
				"speed": max(55.0, base_speed - 20.0),
				"max_health": base_hp + 3,
				"coin_reward": base_reward + 2,
				"castle_damage": 2,
				"armor": 0,
				"scale": 1.3,
				"tint": Color(1.0, 0.86, 0.8, 1.0)
			}
		"shield":
			return {
				"enemy_type": "shield",
				"speed": max(60.0, base_speed - 10.0),
				"max_health": base_hp + 2,
				"coin_reward": base_reward + 2,
				"castle_damage": 2,
				"armor": 0,
				"shield_points": 2 + int(wave_index / 6),
				"scale": 1.15,
				"tint": Color(0.85, 0.92, 1.0, 1.0)
			}
		"armored":
			return {
				"enemy_type": "armored",
				"speed": max(62.0, base_speed - 6.0),
				"max_health": base_hp + 1,
				"coin_reward": base_reward + 1,
				"castle_damage": 1,
				"armor": 1,
				"scale": 1.08,
				"tint": Color(0.8, 0.9, 1.0, 1.0)
			}
		"boss":
			return {
				"enemy_type": "boss",
				"speed": max(52.0, base_speed - 18.0),
				"max_health": 10 + wave_index * 2,
				"coin_reward": 10 + wave_index,
				"castle_damage": 3,
				"armor": 1 + int(wave_index / 10),
				"scale": 1.8,
				"tint": Color(1.0, 0.72, 0.72, 1.0),
				"elite": true,
				"attack_mode": "ranged",
				"attack_interval": max(0.6, 1.15 - wave_index * 0.02),
				"attack_line_y": wall_y - 170.0
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
	elite_definition["max_health"] = int(elite_definition.get("max_health", 1)) + 2
	elite_definition["coin_reward"] = int(elite_definition.get("coin_reward", 1)) + 2
	elite_definition["castle_damage"] = int(elite_definition.get("castle_damage", 1)) + 1
	elite_definition["scale"] = float(elite_definition.get("scale", 1.0)) * 1.08
	var tint: Color = elite_definition.get("tint", Color.WHITE)
	elite_definition["tint"] = Color(min(tint.r + 0.08, 1.0), min(tint.g + 0.08, 1.0), min(tint.b + 0.08, 1.0), tint.a)
	return elite_definition


func _on_player_shoot_requested(spawn_position: Vector2, target_position: Vector2) -> void:
	if is_game_over or get_tree().paused:
		return

	if current_phase != PHASE_BATTLE or player_is_on_lower_lane:
		return

	_play_sound("shoot")
	var arrow = ARROW_SCENE.instantiate()
	arrow.global_position = spawn_position
	if arrow.has_method("set_damage"):
		arrow.set_damage(_get_player_arrow_damage())
	projectiles_container.add_child(arrow)

	if arrow.has_method("set_direction"):
		arrow.set_direction(target_position)


func _on_enemy_killed(reward: int) -> void:
	coins += reward
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
	elif elite:
		hit_color = Color(1.0, 0.8, 0.25, 1.0)
	_spawn_floating_text(world_position, str(damage_dealt), hit_color, 24 if elite or target_type == "boss" else 20)
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
		_show_wave_banner("Wave %d Cleared" % wave_index)
		_play_sound("wave_clear")
		_set_status_message("Prep time. Repair, upgrade, and place traps.", 1.6)
		boss_reward_pending = wave_index % 5 == 0
		_start_prep_phase()
		if boss_reward_pending:
			_open_boss_reward_panel()


func _trigger_game_over() -> void:
	is_game_over = true
	enemy_spawner.stop()
	shop_panel.visible = false
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
		player.set_lane(player.wall_y, 170.0, viewport_size.x - 170.0)
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
	_try_purchase(repair_cost, Callable(self, "_buy_repair"), "Wall repaired +1 HP.")


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
	castle_hp = min(castle_hp + 1, max_castle_hp)


func _buy_fire_rate_upgrade() -> void:
	fire_rate_level += 1
	_apply_player_upgrades()


func _buy_damage_upgrade() -> void:
	damage_level += 1


func _buy_wall_upgrade() -> void:
	wall_level += 1
	max_castle_hp += 3
	castle_hp = min(castle_hp + 3, max_castle_hp)
	_update_castle_visuals()


func _buy_keep_upgrade() -> void:
	keep_level += 1
	max_castle_hp += 1
	castle_hp = min(castle_hp + 1, max_castle_hp)
	_update_castle_visuals()


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


func _get_player_arrow_damage() -> int:
	return 1 + damage_level


func _get_fire_rate_upgrade_cost() -> int:
	return fire_rate_upgrade_cost + fire_rate_level * 4


func _get_damage_upgrade_cost() -> int:
	return damage_upgrade_cost + damage_level * 5


func _get_wall_upgrade_cost() -> int:
	return wall_upgrade_cost + (wall_level - 1) * 8


func _get_keep_upgrade_cost() -> int:
	return keep_upgrade_cost + (keep_level - 1) * 12


func _get_turret_cost() -> int:
	return turret_build_cost + max(turret_level - 1, 0) * 14


func _get_catapult_cost() -> int:
	return catapult_build_cost + max(catapult_level - 1, 0) * 18


func _get_trap_cost(trap_type: String) -> int:
	match trap_type:
		TRAP_FIRE:
			return fire_trap_cost + int(trap_inventory[TRAP_FIRE]) * 3
		TRAP_SLOW:
			return slow_trap_cost + int(trap_inventory[TRAP_SLOW]) * 3
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
		var turret_visual: Polygon2D = Polygon2D.new()
		turret_visual.z_index = 8
		turret_visual.visible = false
		turret_visual.position = turret_position
		turret_visual.color = Color(0.82, 0.74, 0.58, 0.96)
		turret_visual.polygon = PackedVector2Array([
			Vector2(-16, 12), Vector2(16, 12), Vector2(12, -4),
			Vector2(6, -4), Vector2(6, -16), Vector2(-6, -16),
			Vector2(-6, -4), Vector2(-12, -4)
		])
		add_child(turret_visual)
		turret_visuals.append(turret_visual)

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

	catapult_visual = Polygon2D.new()
	catapult_visual.z_index = 8
	catapult_visual.visible = false
	catapult_visual.position = catapult_position
	catapult_visual.color = Color(0.72, 0.56, 0.34, 0.96)
	catapult_visual.polygon = PackedVector2Array([
		Vector2(-18, 12), Vector2(18, 12), Vector2(12, 2), Vector2(4, 2),
		Vector2(20, -10), Vector2(24, -22), Vector2(18, -24), Vector2(12, -12),
		Vector2(-8, 0), Vector2(-18, 2)
	])
	add_child(catapult_visual)
	_update_catapult_visual()


func _update_castle_visuals() -> void:
	var wall_body_lighten: float = min(float(wall_level - 1) * 0.04, 0.16)
	castle_wall_band.color = Color(0.388235 + wall_body_lighten, 0.352941 + wall_body_lighten * 0.9, 0.294118 + wall_body_lighten * 0.75, 1)
	wall_highlight.color = Color(0.584314 + wall_body_lighten * 0.7, 0.529412 + wall_body_lighten * 0.6, 0.423529 + wall_body_lighten * 0.55, 0.45)
	wall_mid_shadow.color = Color(0, 0, 0, max(0.08, 0.12 - float(wall_level - 1) * 0.01))

	var battlement_count: int = min(14, 7 + wall_level * 2)
	var battlement_index: int = 0
	for child in wall_battlements.get_children():
		var battlement := child as Polygon2D
		if battlement == null:
			continue
		battlement.visible = battlement_index < battlement_count
		battlement.position.y = -float(min(wall_level - 1, 3)) * 6.0
		battlement.color = Color(0.690196 + wall_body_lighten * 0.5, 0.631373 + wall_body_lighten * 0.45, 0.505882 + wall_body_lighten * 0.35, 1)
		battlement_index += 1

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
	var tracer: Line2D = Line2D.new()
	tracer.z_index = 18
	tracer.width = 3.0
	tracer.default_color = Color(1.0, 0.9, 0.55, 0.9)
	tracer.points = PackedVector2Array([origin, target])
	add_child(tracer)
	var tween: Tween = tracer.create_tween()
	tween.parallel().tween_property(tracer, "modulate", Color(1, 1, 1, 0), 0.12)
	tween.parallel().tween_property(tracer, "width", 1.0, 0.12)
	tween.tween_callback(tracer.queue_free)


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
		turret_visual.rotation = lerp_angle(turret_visual.rotation, 0.0, 0.18)
		turret_visual.scale = Vector2.ONE * (1.2 + float(turret_level - 1) * 0.12)
		turret_visual.color = Color(0.9 + min(float(turret_level) * 0.03, 0.1), 0.82 + min(float(keep_level - 1) * 0.03, 0.1), 0.5, 1.0)
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
	catapult_visual.scale = Vector2.ONE * (1.0 + float(catapult_level - 1) * 0.1)
	catapult_visual.color = Color(0.72 + min(float(catapult_level) * 0.03, 0.12), 0.56 + min(float(keep_level - 1) * 0.02, 0.06), 0.34, 0.98)


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
			var aim_angle: float = (target.global_position - mount_position).angle() + PI * 0.5
			turret_visual.rotation = aim_angle
			turret_visual.scale = Vector2.ONE * (1.35 + float(turret_level - 1) * 0.14)
			turret_visual.modulate = Color(1.3, 1.15, 0.8, 1.0)
			var tween: Tween = turret_visual.create_tween()
			tween.parallel().tween_property(turret_visual, "scale", Vector2.ONE * (1.2 + float(turret_level - 1) * 0.12), 0.12)
			tween.parallel().tween_property(turret_visual, "modulate", Color(1, 1, 1, 1), 0.16)
			tween.parallel().tween_property(turret_visual, "rotation", 0.0, 0.18)

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
	_play_sound("trap_fire")
	for enemy in enemies_container.get_children():
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("take_damage"):
			continue
		if enemy.global_position.distance_to(impact_point) <= 78.0 + float(catapult_level) * 6.0:
			enemy.take_damage(2 + catapult_level)

	catapult_fire_timer = max(1.3, 2.6 - float(catapult_level - 1) * 0.16)
	if catapult_visual != null and is_instance_valid(catapult_visual):
		catapult_visual.scale = Vector2.ONE * (1.12 + float(catapult_level - 1) * 0.1)
		var tween: Tween = catapult_visual.create_tween()
		tween.tween_property(catapult_visual, "scale", Vector2.ONE * (1.0 + float(catapult_level - 1) * 0.1), 0.16)


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
	for i in range(6):
		var player_node := AudioStreamPlayer.new()
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = 44100.0
		generator.buffer_length = 0.2
		player_node.stream = generator
		player_node.bus = "Master"
		add_child(player_node)
		audio_players.append(player_node)


func _setup_music() -> void:
	music_player = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.4
	music_player.stream = generator
	music_player.bus = "Master"
	add_child(music_player)


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


func _play_sound(event_name: String, data: Dictionary = {}) -> void:
	if audio_players.is_empty():
		return

	match event_name:
		"shoot":
			_play_tone(0, 760.0 + damage_level * 40.0, 0.045, 0.16, "triangle", 1.0)
			_play_tone(1, 980.0, 0.03, 0.08, "sine", 0.25)
		"turret_shoot":
			_play_tone(0, 610.0 + turret_level * 30.0, 0.05, 0.14, "square", 0.4)
			_play_tone(1, 820.0, 0.035, 0.06, "triangle", 0.15)
		"enemy_hit":
			var hit_pitch: float = 320.0
			var target_type := str(data.get("target_type", "grunt"))
			if target_type == "armored":
				hit_pitch = 240.0
			elif target_type == "runner":
				hit_pitch = 390.0
			_play_tone(2, hit_pitch, 0.035, 0.1, "square", 0.15)
		"enemy_die":
			_play_tone(2, 180.0, 0.08, 0.15, "saw", -0.45)
		"wall_hit":
			_play_tone(3, 110.0, 0.16, 0.22, "noise", -0.4)
			_play_tone(4, 84.0, 0.18, 0.12, "sine", -0.35)
		"trap_spike":
			_play_tone(3, 520.0, 0.05, 0.16, "square", 0.2)
			_play_tone(4, 280.0, 0.08, 0.11, "noise", -0.1)
		"trap_fire":
			_play_tone(3, 420.0, 0.12, 0.18, "noise", 0.25)
			_play_tone(4, 620.0, 0.08, 0.1, "sine", 0.15)
		"trap_slow":
			_play_tone(3, 360.0, 0.12, 0.16, "triangle", -0.05)
			_play_tone(4, 520.0, 0.14, 0.08, "sine", -0.1)
		"buy":
			_play_tone(5, 540.0, 0.05, 0.09, "sine", 0.1)
			_play_tone(5, 720.0, 0.06, 0.08, "sine", 0.1)
		"deny":
			_play_tone(5, 220.0, 0.06, 0.09, "square", -0.2)
		"shop_open":
			_play_tone(5, 440.0, 0.05, 0.07, "sine", 0.0)
		"shop_close":
			_play_tone(5, 340.0, 0.05, 0.05, "sine", 0.0)
		"wave_start":
			_play_tone(0, 330.0, 0.08, 0.12, "saw", 0.0)
			_play_tone(1, 494.0, 0.09, 0.11, "saw", 0.0)
		"wave_clear":
			_play_tone(0, 520.0, 0.08, 0.1, "sine", 0.0)
			_play_tone(1, 659.0, 0.1, 0.09, "sine", 0.0)


func _update_music(delta: float) -> void:
	if music_player == null:
		return

	music_step_time -= delta
	if music_step_time > 0.0:
		return

	music_step_time = 0.42
	var melody_freq: float = music_melody[music_step_index % music_melody.size()]
	var bass_freq: float = music_bass[music_step_index % music_bass.size()]
	if music_volume > 0.0:
		_play_generated_tone(music_player, melody_freq, 0.34, 0.05, "sine", 0.0, music_volume)
		if bass_freq > 0.0:
			_play_generated_tone(music_player, bass_freq, 0.36, 0.035, "triangle", 0.0, music_volume)
	music_step_index += 1


func _play_tone(player_index: int, frequency: float, duration: float, volume: float, waveform: String = "sine", pitch_slide: float = 0.0) -> void:
	if player_index < 0 or player_index >= audio_players.size():
		return
	_play_generated_tone(audio_players[player_index], frequency, duration, volume, waveform, pitch_slide, sfx_volume)


func _play_generated_tone(player_node: AudioStreamPlayer, frequency: float, duration: float, volume: float, waveform: String, pitch_slide: float, gain: float) -> void:
	if player_node == null or frequency <= 0.0 or gain <= 0.0:
		return
	if not player_node.playing:
		player_node.play()

	var playback := player_node.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		player_node.play()
		playback = player_node.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var mix_rate: float = 44100.0
	var frame_count: int = int(duration * mix_rate)
	var phase: float = 0.0
	for i in range(frame_count):
		var t: float = float(i) / max(float(frame_count), 1.0)
		var current_freq: float = max(40.0, frequency * (1.0 + pitch_slide * t))
		phase += TAU * current_freq / mix_rate
		var sample := _sample_waveform(waveform, phase)
		var envelope := 1.0 - t
		playback.push_frame(Vector2.ONE * sample * volume * gain * envelope)
	player_node.play()


func _sample_waveform(waveform: String, phase: float) -> float:
	match waveform:
		"square":
			return 1.0 if sin(phase) >= 0.0 else -1.0
		"triangle":
			return asin(sin(phase)) * (2.0 / PI)
		"saw":
			return fmod(phase / PI, 2.0) - 1.0
		"noise":
			return randf_range(-1.0, 1.0)
		_:
			return sin(phase)


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
	_set_shop_info("Repair Wall", "Current wall HP: %d/%d\nRepairs +1 HP instantly during prep." % [castle_hp, max_castle_hp])


func _show_fire_rate_info() -> void:
	_set_shop_info("Fire Rate Lv.%d → Lv.%d" % [fire_rate_level, fire_rate_level + 1], "Current cooldown: %.2fs\nNext cooldown: %.2fs" % [player.fire_cooldown, max(0.08, 0.25 - (fire_rate_level + 1) * 0.03)])


func _show_damage_info() -> void:
	_set_shop_info("Arrow Damage Lv.%d → Lv.%d" % [damage_level, damage_level + 1], "Current damage: %d\nNext damage: %d" % [_get_player_arrow_damage(), _get_player_arrow_damage() + 1])


func _show_wall_upgrade_info() -> void:
	_set_shop_info("Wall Level %d → %d" % [wall_level, wall_level + 1], "Adds +3 max HP\nExpands active trap coverage to %d points." % [min(battlefield_trap_points.size(), 4 + max(wall_level, 0) + max(keep_level - 1, 0))])


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
			_set_shop_info("Fortress Upgrades", "Wall Lv.%d | Keep Lv.%d\nGrow the castle, unlock defenses, and expand battlefield control." % [wall_level, keep_level])


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
			prompt = "Press E to open shop"
		elif _has_armed_traps():
			prompt = "Armed trap markers show active battlefield coverage"
		elif player_near_ladder_bottom or _is_player_near_ladder_bottom():
			prompt = "Press W to climb to the wall"
	elif current_phase == PHASE_PREP and not player_is_on_lower_lane:
		if player_near_ladder_top or _is_player_near_ladder_top():
			prompt = "Press S to return to the yard"
	elif current_phase == PHASE_BATTLE and player_is_on_lower_lane:
		prompt = "Battle active - climbing to the wall"

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
	hp_label.text = "Wall L%d  HP: %d/%d" % [wall_level, castle_hp, max_castle_hp]
	coins_label.text = "Coins: %d" % coins
	score_label.text = "Keep L%d  Score: %d" % [keep_level, score]
	if wave_index > 0:
		wave_label.text = "Wave: %d" % wave_index
	else:
		wave_label.text = "Wave: -"
	trap_label.text = "Armed S:%d F:%d L:%d  T:%d C:%d" % [int(trap_inventory[TRAP_SPIKE]), int(trap_inventory[TRAP_FIRE]), int(trap_inventory[TRAP_SLOW]), _get_active_turret_count(), catapult_level]

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
