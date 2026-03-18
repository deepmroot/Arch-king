extends Node2D

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const ARROW_SCENE := preload("res://scenes/Arrow.tscn")

const PHASE_PREP := "prep"
const PHASE_BATTLE := "battle"

@export var starting_hp := 10
@export var wall_y := 90.0
@export var wall_margin_from_bottom := 90.0
@export var repair_cost := 5
@export var trap_cost := 6
@export var fire_rate_upgrade_cost := 8
@export var damage_upgrade_cost := 10
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
var traps_owned := 0
var placed_traps := [false, false, false]
var trap_trigger_radius := 42.0

@onready var player = $Player
@onready var enemies_container = $Enemies
@onready var projectiles_container = $Projectiles
@onready var enemy_spawner: Timer = $EnemySpawner
@onready var shop_zone: Area2D = $ShopZone
@onready var castle_wall_band: Polygon2D = $CastleWallBand
@onready var wall_highlight: Polygon2D = $WallHighlight
@onready var wall_mid_shadow: Polygon2D = $WallMidShadow
@onready var gate_arch: Sprite2D = $GateArch
@onready var towers: Node2D = $Towers
@onready var lane_marker: Marker2D = $LayoutMarkers/EnemyLaneCenter
@onready var shop_marker: Marker2D = $LayoutMarkers/ShopMarker
@onready var wall_camera_focus: Marker2D = $LayoutMarkers/WallCameraFocus
@onready var back_area_camera_focus: Marker2D = $LayoutMarkers/BackAreaCameraFocus
@onready var ladder_top_zone: Area2D = $LadderZones/LadderTopZone
@onready var ladder_bottom_zone: Area2D = $LadderZones/LadderBottomZone
@onready var game_camera: Camera2D = $GameCamera
@onready var trap_slot_1: Polygon2D = $TrapSlots/TrapSlot1
@onready var trap_slot_2: Polygon2D = $TrapSlots/TrapSlot2
@onready var trap_slot_3: Polygon2D = $TrapSlots/TrapSlot3
@onready var hp_label: Label = $UI/HUD/HPLabel
@onready var coins_label: Label = $UI/HUD/CoinsLabel
@onready var score_label: Label = $UI/HUD/ScoreLabel
@onready var wave_label: Label = $UI/HUD/WaveLabel
@onready var phase_label: Label = $UI/HUD/PhaseLabel
@onready var wave_banner: Label = $UI/WaveBanner
@onready var shop_panel: Panel = $UI/ShopPanel
@onready var shop_message_label: Label = $UI/ShopPanel/VBoxContainer/MessageLabel
@onready var repair_button: Button = $UI/ShopPanel/VBoxContainer/RepairButton
@onready var fire_rate_button: Button = $UI/ShopPanel/VBoxContainer/FireRateButton
@onready var damage_button: Button = $UI/ShopPanel/VBoxContainer/DamageButton
@onready var trap_button: Button = $UI/ShopPanel/VBoxContainer/TrapButton
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
	var viewport_size := get_viewport_rect().size
	wall_y = 470.0

	player.wall_y = wall_y + player_wall_offset
	player.left_bound = 170.0
	player.right_bound = viewport_size.x - 170.0
	player.set_free_move_bounds(80.0, viewport_size.x - 80.0, lower_area_top_y, lower_area_bottom_y)
	player.global_position = Vector2(ladder_bottom_zone.global_position.x, lower_lane_y)
	player.shoot_requested.connect(_on_player_shoot_requested)
	_apply_player_upgrades()

	shop_zone.global_position = shop_marker.global_position
	game_camera.global_position = back_area_camera_focus.global_position
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
	repair_button.pressed.connect(_on_repair_button_pressed)
	fire_rate_button.pressed.connect(_on_fire_rate_button_pressed)
	damage_button.pressed.connect(_on_damage_button_pressed)
	trap_button.pressed.connect(_on_trap_button_pressed)
	close_button.pressed.connect(_close_shop)
	start_button.pressed.connect(_start_game)
	restart_button.pressed.connect(_restart_game)
	resume_button.pressed.connect(_toggle_pause)

	shop_panel.visible = false
	game_over_panel.visible = false
	pause_panel.visible = false
	main_menu_panel.visible = true
	_refresh_shop_buttons()
	_refresh_trap_visuals()
	_start_prep_phase()
	get_tree().paused = true


func _process(delta: float) -> void:
	if get_tree().paused or is_game_over:
		return

	if current_phase == PHASE_PREP and battle_started:
		prep_time_remaining = max(prep_time_remaining - delta, 0.0)
		if prep_time_remaining <= 0.0 and not player_is_on_lower_lane and not is_ladder_transitioning:
			_begin_next_wave()

	if current_phase == PHASE_BATTLE:
		_update_trap_triggers()

	_update_hud()


func _start_game() -> void:
	main_menu_panel.visible = false
	get_tree().paused = false
	battle_started = false
	_start_prep_phase()


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


func _start_prep_phase() -> void:
	current_phase = PHASE_PREP
	prep_time_remaining = prep_phase_duration
	enemies_to_spawn = 0
	enemy_spawner.stop()
	_refresh_shop_buttons()
	_update_hud()


func _begin_next_wave() -> void:
	current_phase = PHASE_BATTLE
	wave_index += 1
	enemies_to_spawn = 5 + wave_index * 2
	_refresh_shop_buttons()
	_show_wave_banner("Wave %d Start" % wave_index)
	_set_next_spawn_time()
	_update_hud()


func _set_next_spawn_time() -> void:
	if current_phase != PHASE_BATTLE or enemies_to_spawn <= 0:
		return

	enemy_spawner.wait_time = max(0.35, 1.2 - wave_index * 0.08)
	enemy_spawner.start()


func _on_enemy_spawner_timeout() -> void:
	if is_game_over or current_phase != PHASE_BATTLE or enemies_to_spawn <= 0:
		return

	_spawn_enemy()
	enemies_to_spawn -= 1
	if enemies_to_spawn > 0:
		_set_next_spawn_time()


func _spawn_enemy() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	var lane_center_x: float = lane_marker.global_position.x
	enemy.global_position = Vector2(
		randf_range(lane_center_x - enemy_lane_half_width, lane_center_x + enemy_lane_half_width),
		-24.0
	)
	enemy.wall_y = wall_y - 16.0
	enemy.speed = 85.0 + float(max(wave_index - 1, 0)) * 8.0
	enemy.max_health = 1 + int((wave_index - 1) / 3)
	enemy.coin_reward = 1 + int((wave_index - 1) / 2)
	enemy.enemy_killed.connect(_on_enemy_killed)
	enemy.reached_wall.connect(_on_enemy_reached_wall)
	enemies_alive += 1
	enemies_container.add_child(enemy)


func _on_player_shoot_requested(spawn_position: Vector2, target_position: Vector2) -> void:
	if is_game_over or get_tree().paused:
		return

	if current_phase != PHASE_BATTLE or player_is_on_lower_lane:
		return

	var arrow = ARROW_SCENE.instantiate()
	arrow.global_position = spawn_position
	if arrow.has_method("set_damage"):
		arrow.set_damage(_get_player_arrow_damage())
	projectiles_container.add_child(arrow)

	if arrow.has_method("set_direction"):
		arrow.set_direction(target_position)


func _on_enemy_killed(reward: int) -> void:
	coins += reward
	score += 10 * wave_index
	enemies_alive = max(enemies_alive - 1, 0)
	_check_wave_clear()
	_update_hud()
	_refresh_shop_buttons()


func _on_enemy_reached_wall(damage: int) -> void:
	if is_game_over:
		return

	enemies_alive = max(enemies_alive - 1, 0)
	if _consume_placed_trap():
		score += 15
		_check_wave_clear()
		_update_hud()
		return

	castle_hp = max(castle_hp - damage, 0)
	_flash_wall_hit()
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
		_start_prep_phase()


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

		if current_phase == PHASE_PREP and player_is_on_lower_lane and _try_place_trap_near_player():
			get_viewport().set_input_as_handled()


func _open_shop() -> void:
	shop_panel.visible = true
	_refresh_shop_buttons()
	shop_message_label.text = "Spend coins during prep. Press E near trap slots to place bought trap charges."
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

	var viewport_size := get_viewport_rect().size
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
	shop_panel.visible = false

	if not is_game_over:
		get_tree().paused = false


func _on_repair_button_pressed() -> void:
	_try_purchase(repair_cost, Callable(self, "_buy_repair"), "Wall repaired +1 HP.")


func _on_fire_rate_button_pressed() -> void:
	_try_purchase(_get_fire_rate_upgrade_cost(), Callable(self, "_buy_fire_rate_upgrade"), "Fire rate improved.")


func _on_damage_button_pressed() -> void:
	_try_purchase(_get_damage_upgrade_cost(), Callable(self, "_buy_damage_upgrade"), "Arrow damage increased.")


func _on_trap_button_pressed() -> void:
	_try_purchase(_get_trap_cost(), Callable(self, "_buy_trap"), "Bought one trap charge for future trap placement.")


func _try_purchase(cost: int, action: Callable, success_message: String) -> void:
	if current_phase != PHASE_PREP:
		shop_message_label.text = "You can only shop during prep time."
		return

	if coins < cost:
		shop_message_label.text = "Not enough coins."
		return

	coins -= cost
	action.call()
	shop_message_label.text = success_message
	_refresh_shop_buttons()
	_update_hud()


func _buy_repair() -> void:
	castle_hp += 1


func _buy_fire_rate_upgrade() -> void:
	fire_rate_level += 1
	_apply_player_upgrades()


func _buy_damage_upgrade() -> void:
	damage_level += 1


func _buy_trap() -> void:
	traps_owned += 1
	_refresh_trap_visuals()


func _apply_player_upgrades() -> void:
	player.fire_cooldown = max(0.08, 0.25 - fire_rate_level * 0.03)


func _get_player_arrow_damage() -> int:
	return 1 + damage_level


func _get_fire_rate_upgrade_cost() -> int:
	return fire_rate_upgrade_cost + fire_rate_level * 4


func _get_damage_upgrade_cost() -> int:
	return damage_upgrade_cost + damage_level * 5


func _get_trap_cost() -> int:
	return trap_cost + traps_owned * 2


func _get_trap_slots() -> Array[Polygon2D]:
	return [trap_slot_1, trap_slot_2, trap_slot_3]


func _try_place_trap_near_player() -> bool:
	if traps_owned <= 0:
		phase_label.text = "Need trap charges from the shop"
		return false

	var slots: Array[Polygon2D] = _get_trap_slots()
	var best_index := -1
	var best_distance: float = 999999.0
	for i in range(slots.size()):
		if placed_traps[i]:
			continue
		var distance: float = player.global_position.distance_to(_get_trap_slot_center(slots[i]))
		if distance < 120.0 and distance < best_distance:
			best_distance = distance
			best_index = i

	if best_index == -1:
		phase_label.text = "Stand near an empty trap slot"
		return false

	placed_traps[best_index] = true
	traps_owned -= 1
	_refresh_trap_visuals()
	_refresh_shop_buttons()
	phase_label.text = "Trap placed"
	return true


func _consume_placed_trap() -> bool:
	for i in range(placed_traps.size()):
		if placed_traps[i]:
			placed_traps[i] = false
			_refresh_trap_visuals()
			return true
	return false


func _update_trap_triggers() -> void:
	var slots: Array[Polygon2D] = _get_trap_slots()
	for i in range(slots.size()):
		if not placed_traps[i]:
			continue

		var slot_center: Vector2 = _get_trap_slot_center(slots[i])
		for enemy in enemies_container.get_children():
			if not is_instance_valid(enemy):
				continue
			if not (enemy is Area2D):
				continue
			if enemy.has_method("take_damage") and enemy.global_position.distance_to(slot_center) <= trap_trigger_radius:
				_spawn_trap_trigger_flash(slot_center)
				enemy.take_damage(999)
				placed_traps[i] = false
				_refresh_trap_visuals()
				phase_label.text = "Trap triggered!"
				return


func _get_trap_slot_center(slot: Polygon2D) -> Vector2:
	var total := Vector2.ZERO
	for point in slot.polygon:
		total += point
	return slot.to_global(total / max(float(slot.polygon.size()), 1.0))


func _refresh_trap_visuals() -> void:
	var slots: Array[Polygon2D] = _get_trap_slots()
	for i in range(slots.size()):
		slots[i].color = Color(0.45, 0.45, 0.45, 0.65)
		var trap_visual := slots[i].get_node("TrapVisual") as CanvasItem
		trap_visual.visible = placed_traps[i]
		if placed_traps[i]:
			slots[i].color = Color(0.65, 0.55, 0.34, 0.85)


func _flash_wall_hit() -> void:
	castle_wall_band.color = Color(0.72, 0.34, 0.3, 1)
	wall_highlight.color = Color(1.0, 0.6, 0.55, 0.55)
	wall_mid_shadow.color = Color(0.2, 0.0, 0.0, 0.22)
	gate_arch.modulate = Color(1.2, 0.8, 0.8, 1)
	towers.modulate = Color(1.08, 0.8, 0.8, 1)
	var original_camera: Vector2 = game_camera.global_position
	game_camera.global_position += Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0))
	var tween: Tween = create_tween()
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
	var tween: Tween = create_tween()
	tween.tween_property(wave_banner, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.tween_interval(0.9)
	tween.tween_property(wave_banner, "modulate", Color(1, 1, 1, 0), 0.35)
	tween.tween_callback(func(): wave_banner.visible = false)


func _spawn_trap_trigger_flash(position: Vector2) -> void:
	var flash: Polygon2D = Polygon2D.new()
	flash.z_index = 20
	flash.position = position
	flash.color = Color(1.0, 0.85, 0.35, 0.8)
	flash.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(-5, -5), Vector2(0, -14), Vector2(5, -5),
		Vector2(14, 0), Vector2(5, 5), Vector2(0, 14), Vector2(-5, 5)
	])
	add_child(flash)
	var tween: Tween = create_tween()
	tween.parallel().tween_property(flash, "scale", Vector2(2.2, 2.2), 0.18)
	tween.parallel().tween_property(flash, "modulate", Color(1, 1, 1, 0), 0.18)
	tween.tween_callback(flash.queue_free)


func _refresh_shop_buttons() -> void:
	repair_button.text = "Repair Wall (%d)" % repair_cost
	fire_rate_button.text = "Fire Rate Lv.%d (%d)" % [fire_rate_level + 1, _get_fire_rate_upgrade_cost()]
	damage_button.text = "Arrow Damage Lv.%d (%d)" % [damage_level + 1, _get_damage_upgrade_cost()]
	trap_button.text = "Buy Trap Charge (%d) | Held: %d" % [_get_trap_cost(), traps_owned]

	repair_button.disabled = current_phase != PHASE_PREP
	fire_rate_button.disabled = current_phase != PHASE_PREP
	damage_button.disabled = current_phase != PHASE_PREP
	trap_button.disabled = current_phase != PHASE_PREP


func _update_hud() -> void:
	hp_label.text = "HP: %d" % castle_hp
	coins_label.text = "Coins: %d" % coins
	score_label.text = "Score: %d" % score
	wave_label.text = "Wave: %d" % max(wave_index, 1)

	if current_phase == PHASE_PREP:
		phase_label.text = "Prep: %.0fs" % ceil(prep_time_remaining)
	else:
		phase_label.text = "Battle: %d left" % (enemies_to_spawn + enemies_alive)
