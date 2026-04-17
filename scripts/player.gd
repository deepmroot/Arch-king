extends CharacterBody2D

signal shoot_requested(spawn_position: Vector2, target_position: Vector2)
signal melee_impact(position: Vector2, radius: float)

const ARCHER_IDLE_RUN := preload("res://assets/player/archer/idle_run.png")
const ARCHER_ATTACK    := preload("res://assets/player/archer/attack.png")
const ARCHER_DEATH     := preload("res://assets/player/archer/death.png")

const HUNTRESS_IDLE    := preload("res://assets/player/huntress/Idle.png")
const HUNTRESS_RUN     := preload("res://assets/player/huntress/Run.png")
const HUNTRESS_ATTACK  := preload("res://assets/player/huntress/Attack1.png")
const HUNTRESS_DEATH   := preload("res://assets/player/huntress/Death.png")

const HERO_KNIGHT_IDLE   := preload("res://assets/player/hero_knight/idle.png")
const HERO_KNIGHT_RUN    := preload("res://assets/player/hero_knight/run.png")
const HERO_KNIGHT_ATTACK := preload("res://assets/player/hero_knight/attack.png")
const HERO_KNIGHT_DEATH  := preload("res://assets/player/hero_knight/death.png")

const WIZARD_IDLE      := preload("res://assets/player/wizard/idle.png")
const WIZARD_ATTACK    := preload("res://assets/player/wizard/attack.png")
const WIZARD_DEATH     := preload("res://assets/player/wizard/death.png")
const WIZARD_FLY       := preload("res://assets/player/wizard/fly_forward.png")

const SORCERER_IDLE    := preload("res://assets/player/wizard/sorcerer_idle.png")
const SORCERER_ATTACK  := preload("res://assets/player/wizard/sorcerer_attack.png")
const SORCERER_DEATH   := preload("res://assets/player/wizard/death.png")

const WITCH_IDLE       := preload("res://assets/player/witch/idle_sheet.png")
const WITCH_ATTACK     := preload("res://assets/player/witch/attack_sheet.png")

const NINJA_IDLE       := preload("res://assets/player/ninja/idle.png")
const NINJA_WALK       := preload("res://assets/player/ninja/walk.png")
const NINJA_ATTACK     := preload("res://assets/player/ninja/attack.png")
const NINJA_DEATH      := preload("res://assets/player/ninja/death.png")

@export var speed := 350.0
@export var wall_y := 90.0
@export var left_bound := 24.0
@export var right_bound := 1128.0
@export var fire_cooldown := 0.25

var fire_timer := 0.0
var is_attacking := false
var is_dead := false
var facing_direction := 1.0
var current_lane_y := 0.0
var movement_locked := false
var free_move_mode := false
var lower_bound_y := 0.0
var upper_bound_y := 0.0
var queued_shot_pending := false
var melee_damage := 2
var melee_attack_radius := 60.0
var melee_attack_offset := 34.0

@onready var shoot_point: Marker2D = $ShootPoint
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_ensure_local_input_actions()
	current_lane_y = wall_y
	global_position.y = current_lane_y
	_build_animations()
	animated_sprite.play("idle")
	animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if fire_timer > 0.0:
		fire_timer -= delta

	if movement_locked:
		velocity = Vector2.ZERO
		if not is_attacking and animated_sprite.animation != "idle":
			animated_sprite.play("idle")
		return

	var move_input := _get_move_input()
	if abs(move_input.x) > 0.01:
		_update_facing(move_input.x)

	if free_move_mode:
		velocity = move_input * speed
	else:
		velocity = Vector2(move_input.x * speed, 0.0)

	move_and_slide()

	global_position.x = clamp(global_position.x, left_bound, right_bound)
	if free_move_mode:
		global_position.y = clamp(global_position.y, upper_bound_y, lower_bound_y)
	else:
		global_position.y = current_lane_y

	if GameState.is_melee_character():
		if fire_timer <= 0.0 and not is_attacking:
			_try_auto_melee()
	elif _is_shoot_just_pressed():
		shoot()

	if not is_attacking:
		_update_movement_animation(move_input)


func shoot() -> void:
	if fire_timer > 0.0 or is_dead:
		return

	fire_timer = fire_cooldown
	is_attacking = true
	animated_sprite.play("attack")
	var target_position: Vector2 = get_global_mouse_position()
	if GameState.selected_character == GameState.CHAR_RANGER:
		queued_shot_pending = true
		_emit_delayed_shot(target_position, 0.22)
		return
	shoot_requested.emit(shoot_point.global_position, target_position)


func die() -> void:
	if is_dead:
		return

	is_dead = true
	queued_shot_pending = false
	velocity = Vector2.ZERO
	collision_shape.disabled = true
	is_attacking = false
	animated_sprite.play("death")


func set_lane(target_y: float, target_left_bound: float, target_right_bound: float) -> void:
	free_move_mode = false
	current_lane_y = target_y
	left_bound = target_left_bound
	right_bound = target_right_bound
	global_position.x = clamp(global_position.x, left_bound, right_bound)
	global_position.y = current_lane_y


func set_free_move_bounds(target_left_bound: float, target_right_bound: float, target_upper_bound_y: float, target_lower_bound_y: float) -> void:
	free_move_mode = true
	left_bound = target_left_bound
	right_bound = target_right_bound
	upper_bound_y = target_upper_bound_y
	lower_bound_y = target_lower_bound_y
	global_position.x = clamp(global_position.x, left_bound, right_bound)
	global_position.y = clamp(global_position.y, upper_bound_y, lower_bound_y)


func set_movement_locked(locked: bool) -> void:
	movement_locked = locked
	if locked:
		velocity = Vector2.ZERO


func _emit_delayed_shot(target_position: Vector2, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_dead or queued_shot_pending == false:
		return
	queued_shot_pending = false
	shoot_requested.emit(shoot_point.global_position, target_position)


func _emit_delayed_melee_hit(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_dead or queued_shot_pending == false:
		return
	queued_shot_pending = false
	_perform_melee_attack()


func _try_auto_melee() -> void:
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Area2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= melee_attack_radius:
			fire_timer = fire_cooldown
			is_attacking = true
			animated_sprite.play("attack")
			queued_shot_pending = true
			_emit_delayed_melee_hit(0.16)
			return


func _perform_melee_attack() -> void:
	var hit_any := false
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Area2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > melee_attack_radius:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(melee_damage)
			hit_any = true
	if hit_any:
		melee_impact.emit(global_position, melee_attack_radius)


func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
		var move_input := _get_move_input()
		_update_facing(move_input.x)
		_update_movement_animation(move_input)


func _update_movement_animation(move_input: Vector2) -> void:
	if move_input.length() > 0.01:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")


func _update_facing(direction: float) -> void:
	if direction > 0.01:
		facing_direction = 1.0
	elif direction < -0.01:
		facing_direction = -1.0

	# Sprite sheet faces RIGHT by default. Flip when facing LEFT.
	animated_sprite.flip_h = facing_direction < 0.0


func _build_animations() -> void:
	var frames := SpriteFrames.new()

	if GameState.selected_character == GameState.CHAR_ALCHEMIST:
		# Ninja: idle 8f strip, walk 10f strip, attack 20f strip, death 14f strip
		_add_strip_animation(frames, "idle",   NINJA_IDLE,    8,  6.0, true)
		_add_strip_animation(frames, "run",    NINJA_WALK,   10, 12.0, true)
		_add_strip_animation(frames, "attack", NINJA_ATTACK, 20, 18.0, false)
		_add_strip_animation(frames, "death",  NINJA_DEATH,  14,  8.0, false)
		animated_sprite.scale = Vector2(1.4, 1.4)
		fire_cooldown = 0.22
		melee_attack_radius = 55.0
	elif GameState.selected_character == GameState.CHAR_WIZARD:
		_add_grid_animation(frames, "idle",   WIZARD_IDLE,   10, 1, 0, 0, 9,  6.0, true)
		_add_grid_animation(frames, "run",    WIZARD_FLY,     6, 1, 0, 0, 5,  8.0, true)
		_add_grid_animation(frames, "attack", WIZARD_ATTACK,  8, 1, 0, 0, 7, 14.0, false)
		_add_grid_animation(frames, "death",  WIZARD_DEATH,  10, 1, 0, 0, 9,  8.0, false)
	elif GameState.selected_character == GameState.CHAR_RANGER:
		_add_strip_animation(frames, "idle", HUNTRESS_IDLE, 8, 6.0, true)
		_add_strip_animation(frames, "run", HUNTRESS_RUN, 8, 10.0, true)
		_add_strip_animation(frames, "attack", HUNTRESS_ATTACK, 5, 12.0, false)
		_add_strip_animation(frames, "death", HUNTRESS_DEATH, 8, 8.0, false)
	elif GameState.selected_character == GameState.CHAR_WARDEN:
		_add_strip_animation(frames, "idle", HERO_KNIGHT_IDLE, 8, 6.0, true)
		_add_strip_animation(frames, "run", HERO_KNIGHT_RUN, 10, 10.0, true)
		_add_strip_animation(frames, "attack", HERO_KNIGHT_ATTACK, 6, 12.0, false)
		_add_strip_animation(frames, "death", HERO_KNIGHT_DEATH, 10, 8.0, false)
	elif GameState.selected_character == GameState.CHAR_MERCHANT:
		# idle: first 3 frames (standing with staff)
		_add_grid_animation(frames, "idle",   SORCERER_IDLE, 10, 1, 0, 0, 2,  4.0, true)
		_add_grid_animation(frames, "run",    SORCERER_IDLE, 10, 1, 0, 0, 2,  6.0, true)
		# attack: frames 3-9 (staff charges and releases shockwave)
		_add_grid_animation(frames, "attack", SORCERER_IDLE, 10, 1, 0, 3, 9, 12.0, false)
		_add_strip_animation(frames, "death",  SORCERER_DEATH, 10,  8.0, false)
		animated_sprite.scale = Vector2(0.52, 0.52)
		fire_cooldown = 1.2
		melee_attack_radius = 110.0
	else:
		_add_grid_animation(frames, "idle",   ARCHER_IDLE_RUN, 8, 2, 0, 0, 1,  3.0, true)
		_add_grid_animation(frames, "run",    ARCHER_IDLE_RUN, 8, 2, 1, 0, 7, 10.0, true)
		_add_grid_animation(frames, "attack", ARCHER_ATTACK,   8, 4, 0, 0, 7, 14.0, false)
		_add_grid_animation(frames, "death",  ARCHER_DEATH,    8, 3, 1, 0, 7,  9.0, false)

	animated_sprite.sprite_frames = frames


func _ensure_local_input_actions() -> void:
	_ensure_key_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_key_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_key_action("move_up", [KEY_W, KEY_UP])
	_ensure_key_action("move_down", [KEY_S, KEY_DOWN])
	_ensure_key_action("shoot", [KEY_SPACE])
	_ensure_mouse_action("shoot", MOUSE_BUTTON_LEFT)


func _ensure_key_action(action_name: String, keys: Array[Key]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for keycode in keys:
		var key_event := InputEventKey.new()
		key_event.keycode = keycode
		key_event.physical_keycode = keycode
		if not InputMap.action_has_event(action_name, key_event):
			InputMap.action_add_event(action_name, key_event)


func _ensure_mouse_action(action_name: String, button: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var mouse_event := InputEventMouseButton.new()
	mouse_event.button_index = button
	if not InputMap.action_has_event(action_name, mouse_event):
		InputMap.action_add_event(action_name, mouse_event)


func _get_move_input() -> Vector2:
	var right_action: String = "move_right" if InputMap.has_action("move_right") else "ui_right"
	var left_action: String = "move_left" if InputMap.has_action("move_left") else "ui_left"
	var down_action: String = "move_down" if InputMap.has_action("move_down") else "ui_down"
	var up_action: String = "move_up" if InputMap.has_action("move_up") else "ui_up"
	return Input.get_vector(left_action, right_action, up_action, down_action)


func _is_shoot_just_pressed() -> bool:
	if InputMap.has_action("shoot"):
		return Input.is_action_just_pressed("shoot")

	return Input.is_action_just_pressed("ui_accept")


func _add_grid_animation(
	frames: SpriteFrames,
	animation_name: String,
	texture: Texture2D,
	columns: int,
	rows: int,
	row_index: int,
	column_start: int,
	column_end: int,
	fps: float,
	loop: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)

	var frame_width := int(texture.get_width() / float(columns))
	var frame_height := int(texture.get_height() / float(rows))

	for col in range(column_start, column_end + 1):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(col * frame_width, row_index * frame_height, frame_width, frame_height)
		frames.add_frame(animation_name, atlas)


func _add_strip_animation(
	frames: SpriteFrames,
	animation_name: String,
	texture: Texture2D,
	frame_count: int,
	fps: float,
	loop: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)

	var frame_width := int(texture.get_width() / float(frame_count))
	var frame_height := texture.get_height()

	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame(animation_name, atlas)
