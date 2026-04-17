extends Node2D

const IDLE_SHEET := preload("res://assets/guards/knight/knight_idle.png")
const WALK_SHEET := preload("res://assets/guards/knight/knight_walk.png")
const ATTACK_SHEET := preload("res://assets/guards/knight/knight_attack.png")
const DEATH_SHEET := preload("res://assets/guards/knight/knight_death.png")

@export var speed := 142.0
@export var attack_damage := 2
@export var max_health := 6
@export var attack_cooldown := 0.95
@export var attack_range := 28.0
@export var slash_radius := 44.0
@export var leash_range := 300.0
@export var contact_damage_interval := 1.15
@export var visual_scale := 1.45
@export var stationary := false

var current_health := 6
var guard_index := 0
var battle_active := false
var is_attacking := false
var is_dead := false
var facing_direction := 1.0
var attack_timer := 0.0
var contact_damage_timer := 0.0
var home_position := Vector2.ZERO
var target_enemy: Area2D

@onready var shadow: Polygon2D = $Shadow
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("guards")
	current_health = max_health
	home_position = global_position
	_build_animations()
	animated_sprite.scale = Vector2.ONE * visual_scale
	animated_sprite.play("idle")
	animated_sprite.animation_finished.connect(_on_animation_finished)


func configure(definition: Dictionary) -> void:
	guard_index = int(definition.get("guard_index", guard_index))
	speed = float(definition.get("speed", speed))
	attack_damage = int(definition.get("attack_damage", attack_damage))
	max_health = int(definition.get("max_health", max_health))
	attack_cooldown = float(definition.get("attack_cooldown", attack_cooldown))
	attack_range = float(definition.get("attack_range", attack_range))
	slash_radius = float(definition.get("slash_radius", slash_radius))
	leash_range = float(definition.get("leash_range", leash_range))
	contact_damage_interval = float(definition.get("contact_damage_interval", contact_damage_interval))
	visual_scale = float(definition.get("visual_scale", visual_scale))
	stationary = bool(definition.get("stationary", stationary))
	home_position = definition.get("home_position", home_position)
	battle_active = bool(definition.get("battle_active", battle_active))
	current_health = max_health
	is_dead = false
	is_attacking = false
	attack_timer = 0.0
	contact_damage_timer = 0.0
	target_enemy = null
	visible = true
	modulate = Color(1, 1, 1, 1)
	shadow.modulate = Color(0, 0, 0, 0.22)
	animated_sprite.scale = Vector2.ONE * visual_scale
	animated_sprite.play("idle")
	global_position = home_position


func set_home_position(value: Vector2) -> void:
	home_position = value
	if is_dead:
		return
	if not battle_active and not is_attacking:
		global_position = home_position


func set_battle_active(active: bool) -> void:
	battle_active = active
	if not active:
		target_enemy = null


func _process(delta: float) -> void:
	if is_dead:
		return

	attack_timer = max(attack_timer - delta, 0.0)
	_update_contact_damage(delta)

	if is_attacking:
		return

	if not battle_active:
		target_enemy = null
		_move_toward_point(home_position, delta)
		return

	target_enemy = _find_target()
	if target_enemy == null:
		_move_toward_point(home_position, delta)
		return

	var target_position := target_enemy.global_position
	var to_target := target_position - global_position
	if abs(to_target.x) > 2.0:
		_update_facing(to_target.x)

	if to_target.length() > attack_range:
		_move_toward_point(target_position, delta)
		return

	if attack_timer <= 0.0:
		_start_attack()
	else:
		_play_idle()


func _find_target() -> Area2D:
	var best_enemy: Area2D
	var best_distance := INF
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Area2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		var distance_from_home := home_position.distance_to(enemy.global_position)
		if distance_from_home > leash_range:
			continue
		var distance_to_guard := global_position.distance_to(enemy.global_position)
		if distance_to_guard < best_distance:
			best_distance = distance_to_guard
			best_enemy = enemy
	return best_enemy


func _move_toward_point(target_position: Vector2, delta: float) -> void:
	if stationary:
		global_position = home_position
		_play_idle()
		return

	var to_target := target_position - global_position
	if to_target.length() <= 4.0:
		global_position = global_position.lerp(target_position, 0.35)
		_play_idle()
		return

	if abs(to_target.x) > 2.0:
		_update_facing(to_target.x)
	global_position += to_target.normalized() * speed * delta
	global_position.y = clamp(global_position.y, -200.0, home_position.y + 6.0)
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")


func _start_attack() -> void:
	is_attacking = true
	attack_timer = attack_cooldown
	animated_sprite.play("attack")
	var tween := create_tween()
	tween.tween_interval(0.18)
	tween.tween_callback(Callable(self, "_apply_slash_damage"))


func _apply_slash_damage() -> void:
	if is_dead:
		return

	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Area2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > slash_radius:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage)


func _update_contact_damage(delta: float) -> void:
	if not battle_active or is_dead:
		return

	var nearby_enemies := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Area2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= attack_range + 8.0:
			nearby_enemies += 1

	if nearby_enemies <= 0:
		contact_damage_timer = 0.0
		return

	contact_damage_timer -= delta
	if contact_damage_timer > 0.0:
		return

	_take_damage(max(1, int(ceil(float(nearby_enemies) * 0.5))))
	contact_damage_timer = contact_damage_interval


func _take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= max(1, amount)
	if current_health > 0:
		_flash_hit()
		return

	_die()


func _die() -> void:
	is_dead = true
	battle_active = false
	is_attacking = false
	target_enemy = null
	animated_sprite.play("death")
	var tween := create_tween()
	tween.parallel().tween_property(shadow, "modulate", Color(0, 0, 0, 0.0), 0.35)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0.85), 0.35)


func _flash_hit() -> void:
	var base_color := animated_sprite.modulate
	animated_sprite.modulate = Color(1.25, 0.82, 0.82, base_color.a)
	var tween := animated_sprite.create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.12)


func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		queue_free()
		return

	if animated_sprite.animation == "attack":
		is_attacking = false
		_play_idle()


func _play_idle() -> void:
	if is_dead:
		return
	if animated_sprite.animation != "idle":
		animated_sprite.play("idle")


func _update_facing(direction: float) -> void:
	if direction > 0.01:
		facing_direction = 1.0
	elif direction < -0.01:
		facing_direction = -1.0
	animated_sprite.flip_h = facing_direction < 0.0


func _build_animations() -> void:
	var frames := SpriteFrames.new()
	_add_strip_animation(frames, "idle", IDLE_SHEET, 4, 6.0, true)
	_add_strip_animation(frames, "walk", WALK_SHEET, 8, 11.0, true)
	_add_strip_animation(frames, "attack", ATTACK_SHEET, 10, 14.0, false)
	_add_strip_animation(frames, "death", DEATH_SHEET, 9, 10.0, false)
	animated_sprite.sprite_frames = frames


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
