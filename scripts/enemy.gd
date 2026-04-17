extends Area2D

signal enemy_killed(reward: int)
signal reached_wall(damage: int)
signal wall_attacked(damage: int)
signal enemy_hit(damage_dealt: int, killed: bool, target_type: String, world_position: Vector2, elite: bool)

const CREATURE_GOBLIN     := preload("res://assets/enemies/creatures/goblin.png")
const CREATURE_SKELETON   := preload("res://assets/enemies/creatures/skeleton.png")
const CREATURE_MUSHROOM   := preload("res://assets/enemies/creatures/mushroom.png")
const CREATURE_FLYING_EYE := preload("res://assets/enemies/creatures/flying_eye.png")
const GOBLIN_KING_SHEET := preload("res://assets/enemies/goblin_king/goblin_king_sheet.png")
const GOBLIN_MECH_SHEET := preload("res://assets/enemies/goblin_mech/goblin_mech_sheet.png")
const MECHA_GOLEM_SHEET := preload("res://assets/enemies/mecha_golem/character_sheet.png")
const MECHA_GOLEM_LASER_SHEET := preload("res://assets/enemies/mecha_golem/laser_sheet.png")
const MECHA_GOLEM_PROJECTILE_GLOW := preload("res://assets/enemies/mecha_golem/arm_projectile_glowing.png")

# Goblin variant sheets: 350x320, 3 cols x 4 rows (row 0 = walk toward camera)
const GOBLIN_1 := preload("res://assets/enemies/goblins/$Goblin_1.png")
const GOBLIN_3 := preload("res://assets/enemies/goblins/$Goblin_3.png")
const GOBLIN_5 := preload("res://assets/enemies/goblins/$Goblin_5.png")


# Large Frost Goblins: 256x256 single frames (tank/boss stand-ins)
const LARGE_FROST_0 := preload("res://assets/enemies/frost_goblins/Large_Frost_Goblin_0.png")
const LARGE_FROST_4 := preload("res://assets/enemies/frost_goblins/Large_Frost_Goblin_4.png")

@export var speed := 85.0
@export var max_health := 1
@export var coin_reward := 1
@export var wall_y := 110.0
@export var castle_damage := 1
@export var armor := 0

var is_dead := false
var current_health := 1
var enemy_type := "grunt"
var is_elite := false
var attack_mode := "melee"
var attack_interval := 1.15
var attack_timer := 0.0
var attack_line_y := 0.0
var slow_multiplier := 1.0
var slow_time_remaining := 0.0
var shield_points := 0
var base_tint := Color(1, 1, 1, 1.0)
var burst_speed_multiplier := 1.0
var burst_duration := 0.0
var burst_cooldown := 0.0
var burst_time_remaining := 0.0
var burst_cooldown_remaining := 0.0
var target_position := Vector2.ZERO
var stop_distance := 12.0
var drift_target_x := 576.0
var drift_start_y := 0.0
var drift_end_y := 0.0
var mecha_charge_duration := 0.6
var mecha_warning_active := false
var mecha_warning_fx: Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shadow: Polygon2D = $Shadow

var health_bar_root: Node2D
var health_bar_bg: Polygon2D
var health_bar_fill: Polygon2D
var elite_marker: Polygon2D


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	_build_status_visuals()
	animated_sprite.animation_finished.connect(_on_animation_finished)
	# Build default animations (grunt) in case configure() is not called
	_build_animations()
	animated_sprite.play("walk")
	_update_health_bar()


func configure(definition: Dictionary) -> void:
	enemy_type = str(definition.get("enemy_type", enemy_type))
	speed = float(definition.get("speed", speed))
	max_health = int(definition.get("max_health", max_health))
	coin_reward = int(definition.get("coin_reward", coin_reward))
	castle_damage = int(definition.get("castle_damage", castle_damage))
	armor = int(definition.get("armor", armor))
	is_elite = bool(definition.get("elite", false))
	attack_mode = str(definition.get("attack_mode", "melee"))
	attack_interval = float(definition.get("attack_interval", attack_interval))
	attack_line_y = float(definition.get("attack_line_y", wall_y - 120.0))
	attack_timer = attack_interval
	mecha_charge_duration = float(definition.get("mecha_charge_duration", mecha_charge_duration))
	mecha_warning_active = false
	_clear_mecha_charge_warning()
	shield_points = int(definition.get("shield_points", 0))
	burst_speed_multiplier = float(definition.get("burst_speed_multiplier", 1.0))
	burst_duration = float(definition.get("burst_duration", 0.0))
	burst_cooldown = float(definition.get("burst_cooldown", 0.0))
	burst_time_remaining = burst_duration
	burst_cooldown_remaining = 0.0
	var visual_scale := float(definition.get("scale", 1.0))
	var tint: Color = definition.get("tint", Color(1, 1, 1, 1))
	base_tint = tint
	animated_sprite.modulate = base_tint
	shadow.scale = Vector2.ONE * visual_scale
	current_health = max_health
	if is_elite and elite_marker != null:
		elite_marker.visible = true
		elite_marker.scale = Vector2.ONE * clamp(visual_scale, 1.0, 1.6)
	# Build animations now that enemy_type is set, then apply scale
	_build_animations()
	animated_sprite.scale = animated_sprite.scale * visual_scale
	animated_sprite.play("walk")
	_update_health_bar()


func _process(delta: float) -> void:
	if is_dead:
		return

	if slow_time_remaining > 0.0:
		slow_time_remaining = max(slow_time_remaining - delta, 0.0)
		if slow_time_remaining <= 0.0:
			slow_multiplier = 1.0

	if burst_duration > 0.0 and burst_speed_multiplier > 1.0:
		if burst_time_remaining > 0.0:
			burst_time_remaining = max(burst_time_remaining - delta, 0.0)
		elif burst_cooldown_remaining > 0.0:
			burst_cooldown_remaining = max(burst_cooldown_remaining - delta, 0.0)
		else:
			burst_time_remaining = burst_duration
			burst_cooldown_remaining = burst_cooldown

	var movement_multiplier := slow_multiplier
	if burst_time_remaining > 0.0:
		movement_multiplier *= burst_speed_multiplier

	if attack_mode == "ranged" and global_position.y >= attack_line_y:
		global_position.y = attack_line_y
		attack_timer -= delta
		animated_sprite.speed_scale = 0.55 if enemy_type == "mecha_boss" and mecha_warning_active else 0.75
		if enemy_type == "mecha_boss":
			if not mecha_warning_active and attack_timer <= mecha_charge_duration:
				mecha_warning_active = true
				_spawn_mecha_charge_warning()
			if attack_timer <= 0.0:
				attack_timer = attack_interval
				mecha_warning_active = false
				_clear_mecha_charge_warning()
				_perform_ranged_attack()
		else:
			if attack_timer <= 0.0:
				attack_timer = attack_interval
				_perform_ranged_attack()
		return

	animated_sprite.speed_scale = 1.22 if burst_time_remaining > 0.0 else 1.0
	global_position.y += speed * movement_multiplier * delta

	if drift_end_y > drift_start_y and global_position.y >= drift_start_y:
		var t: float = clamp((global_position.y - drift_start_y) / (drift_end_y - drift_start_y), 0.0, 1.0)
		var eased: float = t * t * (3.0 - 2.0 * t)
		global_position.x = lerpf(global_position.x, drift_target_x, eased * delta * 3.5)

	if global_position.y >= wall_y:
		is_dead = true
		_clear_mecha_charge_warning()
		reached_wall.emit(castle_damage)
		queue_free()


func take_damage(amount: int = 1) -> void:
	if is_dead:
		return

	if shield_points > 0 and amount < 999:
		shield_points -= 1
		enemy_hit.emit(0, false, "shield_block", global_position + Vector2(0, -28), is_elite)
		_flash_shield_block()
		return

	var final_damage: int = max(1, amount - armor)
	current_health -= final_damage
	var was_killed := current_health <= 0
	enemy_hit.emit(final_damage, was_killed, enemy_type, global_position + Vector2(0, -28), is_elite)
	_flash_hit()
	global_position.y -= min(12.0, float(final_damage) * 3.0)
	_update_health_bar()
	if current_health > 0:
		return

	is_dead = true
	_clear_mecha_charge_warning()
	collision_shape.disabled = true
	enemy_killed.emit(coin_reward)
	animated_sprite.play("death")
	var tween: Tween = animated_sprite.create_tween()
	tween.parallel().tween_property(animated_sprite, "modulate", Color(animated_sprite.modulate.r, animated_sprite.modulate.g, animated_sprite.modulate.b, 0.0), 0.22)
	tween.parallel().tween_property(shadow, "modulate", Color(0, 0, 0, 0.0), 0.22)
	if health_bar_root != null:
		tween.parallel().tween_property(health_bar_root, "modulate", Color(1, 1, 1, 0.0), 0.18)


func apply_slow(multiplier: float, duration: float) -> void:
	if is_dead:
		return

	slow_multiplier = min(slow_multiplier, clamp(multiplier, 0.2, 1.0))
	slow_time_remaining = max(slow_time_remaining, duration)
	var tint_boost := Color(0.8, 0.92, 1.2, animated_sprite.modulate.a)
	animated_sprite.modulate = tint_boost
	var tween := animated_sprite.create_tween()
	tween.tween_property(animated_sprite, "modulate", base_tint, 0.18)


func _perform_ranged_attack() -> void:
	wall_attacked.emit(castle_damage)
	var base_color := animated_sprite.modulate
	animated_sprite.modulate = Color(min(base_color.r + 0.25, 1.4), min(base_color.g + 0.18, 1.35), min(base_color.b + 0.1, 1.2), base_color.a)
	if enemy_type == "mecha_boss":
		_spawn_mecha_laser_fx()
	var tween := animated_sprite.create_tween()
	tween.tween_property(animated_sprite, "modulate", base_color, 0.16)


func _spawn_mecha_charge_warning() -> void:
	_clear_mecha_charge_warning()
	mecha_warning_fx = Node2D.new()
	mecha_warning_fx.global_position = global_position + Vector2(0, -12)
	get_tree().current_scene.add_child(mecha_warning_fx)

	var orb := Sprite2D.new()
	orb.texture = MECHA_GOLEM_PROJECTILE_GLOW
	orb.hframes = 3
	orb.vframes = 2
	orb.frame = 3 + int(randi() % 3)
	orb.scale = Vector2.ONE * 0.42
	orb.modulate = Color(0.95, 0.5, 0.28, 0.9)
	mecha_warning_fx.add_child(orb)

	var warning_line := Line2D.new()
	warning_line.width = 3.0
	warning_line.default_color = Color(1.0, 0.42, 0.2, 0.32)
	warning_line.position = Vector2.ZERO
	warning_line.points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(0, wall_y - global_position.y + 4.0)
	])
	mecha_warning_fx.add_child(warning_line)

	var tween: Tween = mecha_warning_fx.create_tween()
	tween.set_loops(4)
	tween.parallel().tween_property(orb, "scale", Vector2.ONE * 0.62, 0.12)
	tween.parallel().tween_property(orb, "modulate", Color(1.0, 0.86, 0.45, 1.0), 0.12)
	tween.parallel().tween_property(warning_line, "default_color", Color(1.0, 0.72, 0.36, 0.58), 0.12)
	tween.tween_interval(0.04)
	tween.parallel().tween_property(orb, "scale", Vector2.ONE * 0.42, 0.12)
	tween.parallel().tween_property(orb, "modulate", Color(0.95, 0.5, 0.28, 0.9), 0.12)
	tween.parallel().tween_property(warning_line, "default_color", Color(1.0, 0.42, 0.2, 0.32), 0.12)


func _clear_mecha_charge_warning() -> void:
	if mecha_warning_fx != null and is_instance_valid(mecha_warning_fx):
		mecha_warning_fx.queue_free()
	mecha_warning_fx = null


func _spawn_mecha_laser_fx() -> void:
	var fx_root := Node2D.new()
	fx_root.global_position = global_position + Vector2(0, -12)
	get_tree().current_scene.add_child(fx_root)

	var orb := Sprite2D.new()
	orb.texture = MECHA_GOLEM_PROJECTILE_GLOW
	orb.hframes = 3
	orb.vframes = 2
	orb.frame = randi() % 6
	orb.scale = Vector2.ONE * 0.55
	orb.modulate = Color(0.85, 1.0, 1.15, 0.95)
	fx_root.add_child(orb)

	var beam_distance: float = max(wall_y - global_position.y, 140.0)
	var orb_tween: Tween = orb.create_tween()
	orb_tween.parallel().tween_property(orb, "position", Vector2(0, beam_distance * 0.82), 0.12)
	orb_tween.parallel().tween_property(orb, "scale", Vector2.ONE * 0.78, 0.12)

	var beam := Sprite2D.new()
	beam.texture = MECHA_GOLEM_LASER_SHEET
	beam.hframes = 1
	beam.vframes = 15
	beam.frame = 8 + int(randi() % 6)
	beam.centered = true
	beam.rotation = PI * 0.5
	beam.position = Vector2(0, beam_distance * 0.5)
	beam.scale = Vector2(max(beam_distance / 300.0, 1.0), 0.55)
	beam.modulate = Color(0.82, 1.0, 1.25, 0.95)
	fx_root.add_child(beam)

	var tween := fx_root.create_tween()
	tween.parallel().tween_property(fx_root, "modulate", Color(1, 1, 1, 0), 0.18)
	tween.parallel().tween_property(orb, "scale", Vector2.ONE * 0.95, 0.18)
	tween.parallel().tween_property(beam, "scale", Vector2(beam.scale.x * 1.08, beam.scale.y), 0.18)
	tween.tween_callback(fx_root.queue_free)


func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		_clear_mecha_charge_warning()
		queue_free()


func _flash_hit() -> void:
	var base_color := animated_sprite.modulate
	animated_sprite.modulate = Color(min(base_color.r + 0.5, 1.6), min(base_color.g + 0.25, 1.4), min(base_color.b + 0.25, 1.4), base_color.a)
	var tween: Tween = animated_sprite.create_tween()
	tween.tween_property(animated_sprite, "modulate", base_color, 0.12)


func _flash_shield_block() -> void:
	var base_color := animated_sprite.modulate
	animated_sprite.modulate = Color(0.75, 0.92, 1.2, base_color.a)
	var tween: Tween = animated_sprite.create_tween()
	tween.tween_property(animated_sprite, "modulate", base_color, 0.1)


func get_health_ratio() -> float:
	return clamp(float(current_health) / max(float(max_health), 1.0), 0.0, 1.0)


func is_boss_enemy() -> bool:
	return enemy_type == "boss" or enemy_type == "mecha_boss"


func get_display_name() -> String:
	match enemy_type:
		"boss":
			return "War Chief"
		"mecha_boss":
			return "Mecha-Stone Golem"
		"shield":
			return "Shield Bearer"
		"ranged":
			return "Raider"
		"runner":
			return "Runner"
		_:
			return enemy_type.capitalize()


func _build_status_visuals() -> void:
	health_bar_root = Node2D.new()
	health_bar_root.position = Vector2(-26, -42)
	add_child(health_bar_root)

	health_bar_bg = Polygon2D.new()
	health_bar_bg.color = Color(0.06, 0.06, 0.08, 0.82)
	health_bar_bg.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(52, 0), Vector2(52, 7), Vector2(0, 7)
	])
	health_bar_root.add_child(health_bar_bg)

	health_bar_fill = Polygon2D.new()
	health_bar_fill.color = Color(0.3, 0.92, 0.38, 0.95)
	health_bar_fill.position = Vector2(2, 1)
	health_bar_fill.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(48, 0), Vector2(48, 5), Vector2(0, 5)
	])
	health_bar_root.add_child(health_bar_fill)

	elite_marker = Polygon2D.new()
	elite_marker.visible = false
	elite_marker.position = Vector2(0, -48)
	elite_marker.color = Color(1.0, 0.82, 0.24, 0.95)
	elite_marker.polygon = PackedVector2Array([
		Vector2(0, -7), Vector2(3, -2), Vector2(8, -2), Vector2(4, 2),
		Vector2(5, 8), Vector2(0, 5), Vector2(-5, 8), Vector2(-4, 2),
		Vector2(-8, -2), Vector2(-3, -2)
	])
	add_child(elite_marker)


func _update_health_bar() -> void:
	if health_bar_root == null or health_bar_fill == null or health_bar_bg == null:
		return

	var should_show := max_health > 1 or is_elite or enemy_type == "boss" or enemy_type == "mecha_boss" or enemy_type == "ranged" or enemy_type == "shield"
	health_bar_root.visible = should_show and not is_dead
	if not should_show:
		return

	var ratio: float = clamp(float(current_health) / max(float(max_health), 1.0), 0.0, 1.0)
	health_bar_fill.scale.x = ratio
	if ratio > 0.65:
		health_bar_fill.color = Color(0.3, 0.92, 0.38, 0.95)
	elif ratio > 0.3:
		health_bar_fill.color = Color(0.95, 0.78, 0.2, 0.95)
	else:
		health_bar_fill.color = Color(1.0, 0.32, 0.25, 0.95)

	if elite_marker != null:
		elite_marker.visible = is_elite


func _build_animations() -> void:
	var frames := SpriteFrames.new()

	match enemy_type:
		"boss":
			_add_grid_animation(frames, "walk", GOBLIN_KING_SHEET, 14, 12, 0, 0, 3, 8.0, true)
			_add_grid_animation(frames, "death", GOBLIN_KING_SHEET, 14, 12, 7, 0, 7, 6.0, false)
			animated_sprite.scale = Vector2.ONE * 1.1
		"mecha_boss":
			_add_grid_animation(frames, "walk", MECHA_GOLEM_SHEET, 10, 10, 6, 0, 9, 8.0, true)
			_add_grid_animation(frames, "death", MECHA_GOLEM_SHEET, 10, 10, 7, 0, 9, 7.0, false)
			animated_sprite.scale = Vector2.ONE * 1.12
		"runner":
			# Goblin_3 (jester hat) — fast runner; visual_scale from level.gd will multiply on top
			_add_grid_animation(frames, "walk", GOBLIN_3, 3, 4, 0, 0, 2, 12.0, true)
			_add_grid_animation(frames, "death", GOBLIN_3, 3, 4, 3, 0, 2, 8.0, false)
			animated_sprite.scale = Vector2.ONE * 2.4
		"ranged":
			# CREATURE_MUSHROOM kept for ranged — distinctive silhouette, not a goblin
			_add_strip_animation(frames, "walk", CREATURE_MUSHROOM, 11, 8.0, true)
			_add_strip_animation(frames, "death", CREATURE_MUSHROOM, 11, 8.0, false)
			animated_sprite.scale = Vector2.ONE * 0.82
		"shield":
			# CREATURE_SKELETON for shield bearer — bony silhouette reads clearly
			_add_strip_animation(frames, "walk", CREATURE_SKELETON, 6, 8.0, true)
			_add_strip_animation(frames, "death", CREATURE_SKELETON, 6, 6.0, false)
			animated_sprite.scale = Vector2.ONE * 0.82
		"armored":
			# Goblin_5 (crowned/armored) — distinct from grunt
			_add_grid_animation(frames, "walk", GOBLIN_5, 3, 4, 0, 0, 2, 8.0, true)
			_add_grid_animation(frames, "death", GOBLIN_5, 3, 4, 3, 0, 2, 6.0, false)
			animated_sprite.scale = Vector2.ONE * 2.5
		"tank":
			# Large Frost Goblin — big icy brute; 256x256 single frame
			_add_still_frame(frames, "walk", LARGE_FROST_4, 3.0)
			_add_still_frame(frames, "death", LARGE_FROST_0, 1.0)
			animated_sprite.scale = Vector2.ONE * 0.38
		_:
			# grunt — plain Goblin_1 (green standard goblin)
			_add_grid_animation(frames, "walk", GOBLIN_1, 3, 4, 0, 0, 2, 10.0, true)
			_add_grid_animation(frames, "death", GOBLIN_1, 3, 4, 3, 0, 2, 8.0, false)
			animated_sprite.scale = Vector2.ONE * 2.3

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
	var frame_width := int(texture.get_width() / float(max(frame_count, 1)))
	var frame_height := texture.get_height()
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame(animation_name, atlas)


func _add_variant_animation(
	frames: SpriteFrames,
	animation_name: String,
	texture: Texture2D,
	columns: int,
	rows: int,
	row_index: int,
	fps: float,
	loop: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)

	var frame_width := int(texture.get_width() / float(columns))
	var frame_height := int(texture.get_height() / float(rows))

	for col in range(columns):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(col * frame_width, row_index * frame_height, frame_width, frame_height)
		frames.add_frame(animation_name, atlas)


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


func _add_still_frame(frames: SpriteFrames, animation_name: String, texture: Texture2D, fps: float) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, true)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, 0, texture.get_width(), texture.get_height())
	frames.add_frame(animation_name, atlas)
