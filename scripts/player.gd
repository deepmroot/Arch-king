extends CharacterBody2D

signal shoot_requested(spawn_position: Vector2, target_position: Vector2)

const IDLE_RUN_SHEET := preload("res://assets/player/idle_run.png")
const ATTACK_SHEET := preload("res://assets/player/attack.png")
const DEATH_SHEET := preload("res://assets/player/death.png")

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

	if _is_shoot_just_pressed():
		shoot()

	if not is_attacking:
		_update_movement_animation(move_input)


func shoot() -> void:
	if fire_timer > 0.0 or is_dead:
		return

	fire_timer = fire_cooldown
	is_attacking = true
	animated_sprite.play("attack")
	shoot_requested.emit(shoot_point.global_position, get_global_mouse_position())


func die() -> void:
	if is_dead:
		return

	is_dead = true
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

	_add_grid_animation(frames, "idle", IDLE_RUN_SHEET, 8, 2, 0, 0, 1, 3.0, true)
	_add_grid_animation(frames, "run", IDLE_RUN_SHEET, 8, 2, 1, 0, 7, 10.0, true)
	_add_grid_animation(frames, "attack", ATTACK_SHEET, 8, 4, 0, 0, 7, 14.0, false)
	_add_grid_animation(frames, "death", DEATH_SHEET, 8, 3, 1, 0, 7, 9.0, false)

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
	var right_action := "move_right" if InputMap.has_action("move_right") else "ui_right"
	var left_action := "move_left" if InputMap.has_action("move_left") else "ui_left"
	var down_action := "move_down" if InputMap.has_action("move_down") else "ui_down"
	var up_action := "move_up" if InputMap.has_action("move_up") else "ui_up"
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
