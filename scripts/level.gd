extends Node2D

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const ARROW_SCENE := preload("res://scenes/Arrow.tscn")

@export var starting_hp := 10
@export var wall_y := 90.0
@export var wall_margin_from_bottom := 90.0
@export var shop_cost := 5
@export var enemy_lane_half_width := 120.0
@export var player_wall_offset := -24.0
@export var lower_lane_y := 720.0
@export var lower_area_top_y := 560.0
@export var lower_area_bottom_y := 800.0
@export var ladder_transition_duration := 0.55

var coins := 0
var castle_hp := 0
var is_game_over := false
var player_in_shop_zone := false
var player_near_ladder_top := false
var player_near_ladder_bottom := false
var player_is_on_lower_lane := false
var is_ladder_transitioning := false

@onready var player = $Player
@onready var enemies_container = $Enemies
@onready var projectiles_container = $Projectiles
@onready var enemy_spawner: Timer = $EnemySpawner
@onready var shop_zone: Area2D = $ShopZone
@onready var castle_wall_band: Polygon2D = $CastleWallBand
@onready var lane_marker: Marker2D = $LayoutMarkers/EnemyLaneCenter
@onready var shop_marker: Marker2D = $LayoutMarkers/ShopMarker
@onready var wall_camera_focus: Marker2D = $LayoutMarkers/WallCameraFocus
@onready var back_area_camera_focus: Marker2D = $LayoutMarkers/BackAreaCameraFocus
@onready var ladder_top_zone: Area2D = $LadderZones/LadderTopZone
@onready var ladder_bottom_zone: Area2D = $LadderZones/LadderBottomZone
@onready var game_camera: Camera2D = $GameCamera
@onready var hp_label: Label = $UI/HUD/HPLabel
@onready var coins_label: Label = $UI/HUD/CoinsLabel
@onready var shop_panel: Panel = $UI/ShopPanel
@onready var shop_message_label: Label = $UI/ShopPanel/VBoxContainer/MessageLabel
@onready var buy_button: Button = $UI/ShopPanel/VBoxContainer/BuyButton
@onready var close_button: Button = $UI/ShopPanel/VBoxContainer/CloseButton
@onready var main_menu_panel: Panel = $UI/MainMenuPanel
@onready var start_button: Button = $UI/MainMenuPanel/VBox/StartButton
@onready var pause_panel: Panel = $UI/PausePanel
@onready var resume_button: Button = $UI/PausePanel/VBox/ResumeButton
@onready var game_over_panel: Panel = $UI/GameOverPanel
@onready var restart_button: Button = $UI/GameOverPanel/VBox/RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_setup_input_actions()

	castle_hp = starting_hp
	_update_hud()

	var viewport_size := get_viewport_rect().size
	wall_y = 470.0 # Match the top of the CastleWallBand

	player.wall_y = wall_y + player_wall_offset
	player.left_bound = 170.0 # Don't walk into the left tower
	player.right_bound = viewport_size.x - 170.0 # Don't walk into the right tower
	player.set_lane(player.wall_y, 170.0, viewport_size.x - 170.0)
	player.shoot_requested.connect(_on_player_shoot_requested)

	shop_zone.global_position = shop_marker.global_position
	game_camera.global_position = wall_camera_focus.global_position
	var wall_top := wall_y
	var wall_bottom := wall_y + 70.0
	castle_wall_band.polygon = PackedVector2Array([
		Vector2(0.0, wall_top),
		Vector2(viewport_size.x, wall_top),
		Vector2(viewport_size.x, wall_bottom),
		Vector2(0.0, wall_bottom)
	])

	enemy_spawner.timeout.connect(_on_enemy_spawner_timeout)
	shop_zone.body_entered.connect(_on_shop_zone_body_entered)
	shop_zone.body_exited.connect(_on_shop_zone_body_exited)
	ladder_top_zone.body_entered.connect(_on_ladder_top_zone_body_entered)
	ladder_top_zone.body_exited.connect(_on_ladder_top_zone_body_exited)
	ladder_bottom_zone.body_entered.connect(_on_ladder_bottom_zone_body_entered)
	ladder_bottom_zone.body_exited.connect(_on_ladder_bottom_zone_body_exited)
	buy_button.pressed.connect(_on_buy_button_pressed)
	close_button.pressed.connect(_close_shop)
	start_button.pressed.connect(_start_game)
	restart_button.pressed.connect(_restart_game)
	resume_button.pressed.connect(_toggle_pause)

	shop_panel.visible = false
	game_over_panel.visible = false
	pause_panel.visible = false
	main_menu_panel.visible = true
	get_tree().paused = true


func _start_game() -> void:
	main_menu_panel.visible = false
	get_tree().paused = false
	_set_next_spawn_time()


func _restart_game() -> void:
	get_tree().reload_current_scene()


func _toggle_pause() -> void:
	if is_game_over or main_menu_panel.visible:
		return

	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	pause_panel.visible = is_paused


func _setup_input_actions() -> void:
	_ensure_action("move_left", [_make_key_event(KEY_A), _make_key_event(KEY_LEFT)])
	_ensure_action("move_right", [_make_key_event(KEY_D), _make_key_event(KEY_RIGHT)])
	_ensure_action("move_up", [_make_key_event(KEY_W), _make_key_event(KEY_UP)])
	_ensure_action("move_down", [_make_key_event(KEY_S), _make_key_event(KEY_DOWN)])
	_ensure_action("shoot", [_make_key_event(KEY_SPACE), _make_mouse_event(MOUSE_BUTTON_LEFT)])
	_ensure_action("interact", [_make_key_event(KEY_E)])
	_ensure_action("pause", [_make_key_event(KEY_ESCAPE)])


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


func _set_next_spawn_time() -> void:
	enemy_spawner.wait_time = randf_range(1.0, 2.0)
	enemy_spawner.start()


func _on_enemy_spawner_timeout() -> void:
	if is_game_over:
		return

	_spawn_enemy()
	_set_next_spawn_time()


func _spawn_enemy() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	var lane_center_x := lane_marker.global_position.x
	enemy.global_position = Vector2(
		randf_range(lane_center_x - enemy_lane_half_width, lane_center_x + enemy_lane_half_width),
		-24.0
	)
	enemy.wall_y = wall_y - 16.0
	enemy.enemy_killed.connect(_on_enemy_killed)
	enemy.reached_wall.connect(_on_enemy_reached_wall)
	enemies_container.add_child(enemy)


func _on_player_shoot_requested(spawn_position: Vector2, target_position: Vector2) -> void:
	if is_game_over or get_tree().paused:
		return

	var arrow = ARROW_SCENE.instantiate()
	arrow.global_position = spawn_position
	projectiles_container.add_child(arrow)
	
	if arrow.has_method("set_direction"):
		arrow.set_direction(target_position)


func _on_enemy_killed(reward: int) -> void:
	coins += reward
	_update_hud()


func _on_enemy_reached_wall(damage: int) -> void:
	if is_game_over:
		return

	castle_hp = max(castle_hp - damage, 0)
	_update_hud()

	if castle_hp <= 0:
		_trigger_game_over()


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
	if main_menu_panel.visible:
		return

	if InputMap.has_action("pause") and event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return

	if is_game_over:
		return

	if InputMap.has_action("interact") and event.is_action_pressed("interact"):
		if _can_use_ladder():
			_toggle_ladder_lane()
			get_viewport().set_input_as_handled()
			return

		if player_in_shop_zone and not shop_panel.visible:
			_open_shop()
			get_viewport().set_input_as_handled()


func _open_shop() -> void:
	shop_panel.visible = true
	shop_message_label.text = "Spend %d coins to repair the wall (+1 HP)." % shop_cost
	get_tree().paused = true


func _can_use_ladder() -> bool:
	if is_ladder_transitioning:
		return false

	return (player_near_ladder_top and not player_is_on_lower_lane) or (player_near_ladder_bottom and player_is_on_lower_lane)


func _toggle_ladder_lane() -> void:
	if is_ladder_transitioning:
		return

	is_ladder_transitioning = true
	player.set_movement_locked(true)

	var viewport_size := get_viewport_rect().size
	var ladder_x := ladder_top_zone.global_position.x
	var target_y := lower_lane_y if not player_is_on_lower_lane else player.wall_y
	var target_camera := back_area_camera_focus.global_position if not player_is_on_lower_lane else wall_camera_focus.global_position

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(player, "global_position:x", ladder_x, 0.18)
	tween.parallel().tween_property(game_camera, "global_position", target_camera, ladder_transition_duration)
	tween.tween_property(player, "global_position:y", target_y, 0.37)
	await tween.finished

	if player_is_on_lower_lane:
		player_is_on_lower_lane = false
		player.set_lane(player.wall_y, 170.0, viewport_size.x - 170.0)
		player.global_position.x = ladder_top_zone.global_position.x
	else:
		player_is_on_lower_lane = true
		player.set_free_move_bounds(80.0, viewport_size.x - 80.0, lower_area_top_y, lower_area_bottom_y)
		player.global_position = Vector2(ladder_bottom_zone.global_position.x, lower_lane_y)

	player.set_movement_locked(false)
	is_ladder_transitioning = false


func _close_shop() -> void:
	shop_panel.visible = false

	if not is_game_over:
		get_tree().paused = false


func _on_buy_button_pressed() -> void:
	if coins >= shop_cost:
		coins -= shop_cost
		castle_hp += 1
		shop_message_label.text = "Purchase complete. Wall HP +1."
	else:
		shop_message_label.text = "Not enough coins."

	_update_hud()


func _update_hud() -> void:
	hp_label.text = "HP: %d" % castle_hp
	coins_label.text = "Coins: %d" % coins
