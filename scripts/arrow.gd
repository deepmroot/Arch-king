extends Area2D

const ARROW_TEX := preload("res://assets/projectiles/arrow.png")
const HUNTRESS_SPEAR_TEX := preload("res://assets/player/huntress/Spear.png")
const HUNTRESS_SPEAR_MOVE_TEX := preload("res://assets/player/huntress/Spear move.png")
const WIZARD_BEAM_SHEET := preload("res://assets/projectiles/wizard_beam_sheet.png")
const WIZARD_BEAM_FRAME_A := Vector2i(1, 3)
const WIZARD_BEAM_FRAME_B := Vector2i(2, 3)
const WIZARD_BEAM_BASE_SCALE := Vector2(1.85, 0.74)
const WIZARD_BEAM_GLOW_SCALE := Vector2(2.25, 1.02)
const WIZARD_SPEED_MULTIPLIER := 0.76
const HUNTRESS_SPEAR_SCALE := Vector2(1.3, 1.3)

@export var speed := 700.0
@export var damage := 1

var velocity := Vector2.ZERO
var previous_position := Vector2.ZERO
var pierce := false  # If true, passes through the first enemy hit
var is_wizard := false
var is_huntress := false
var _pierced := false

@onready var glow: Sprite2D = $Glow
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	previous_position = global_position
	if is_wizard:
		_apply_wizard_visuals()
	elif is_huntress:
		_apply_huntress_visuals()
	else:
		_apply_damage_visuals()
	area_entered.connect(_on_area_entered)


func set_direction(target_pos: Vector2) -> void:
	var dir := (target_pos - global_position).normalized()
	velocity = dir * speed * (WIZARD_SPEED_MULTIPLIER if is_wizard else 1.0)
	rotation = dir.angle() if is_wizard or is_huntress else dir.angle() + PI / 2


func set_damage(value: int) -> void:
	damage = value
	if is_wizard:
		_apply_wizard_visuals()
	elif is_huntress:
		_apply_huntress_visuals()
	else:
		_apply_damage_visuals()


func _process(delta: float) -> void:
	previous_position = global_position
	global_position += velocity * delta
	if is_wizard:
		var t := Time.get_ticks_msec() * 0.015
		var beam_frame := WIZARD_BEAM_FRAME_A if sin(t * 1.9) > 0.0 else WIZARD_BEAM_FRAME_B
		if glow != null:
			glow.frame_coords = WIZARD_BEAM_FRAME_A if beam_frame == WIZARD_BEAM_FRAME_B else WIZARD_BEAM_FRAME_B
			glow.modulate.a = 0.46 + sin(t) * 0.12
			glow.scale = WIZARD_BEAM_GLOW_SCALE + Vector2(sin(t * 1.2) * 0.08, sin(t * 1.6) * 0.04)
		if sprite != null:
			sprite.frame_coords = beam_frame
			sprite.scale = WIZARD_BEAM_BASE_SCALE + Vector2(sin(t * 1.5) * 0.05, sin(t * 1.8) * 0.025)
		_spawn_trail()
	elif is_huntress:
		var spear_frame: int = int(Time.get_ticks_msec() / 45) % 4
		if glow != null:
			glow.modulate.a = 0.22 + sin(Time.get_ticks_msec() * 0.02) * 0.05
		if sprite != null:
			sprite.frame = spear_frame
		if randi() % 2 == 0:
			_spawn_trail()
	else:
		if glow != null:
			glow.modulate.a = 0.22 + sin(Time.get_ticks_msec() * 0.02) * 0.06
		if sprite != null:
			sprite.scale = Vector2.ONE * (0.2 + sin(Time.get_ticks_msec() * 0.03) * 0.005)
		if randi() % 2 == 0:
			_spawn_trail()

	var viewport_rect := get_viewport_rect()
	if not viewport_rect.grow(100.0).has_point(global_position):
		queue_free()


func _apply_damage_visuals() -> void:
	if sprite != null:
		sprite.visible = true
		sprite.texture = ARROW_TEX
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.frame = 0
		sprite.rotation = 1.5708
	if glow == null:
		return
	glow.texture = ARROW_TEX
	glow.hframes = 1
	glow.vframes = 1
	glow.frame = 0
	glow.rotation = 1.5708
	glow.modulate = Color(1.0, min(0.78 + damage * 0.06, 1.0), 0.31, 0.3)
	glow.scale = Vector2(0.28, 0.34)
	if collision_shape != null and collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = Vector2(10, 28)


func _apply_huntress_visuals() -> void:
	if sprite != null:
		sprite.visible = true
		sprite.texture = HUNTRESS_SPEAR_MOVE_TEX
		sprite.hframes = 4
		sprite.vframes = 1
		sprite.frame = 0
		sprite.rotation = 0.0
		sprite.scale = HUNTRESS_SPEAR_SCALE
		sprite.modulate = Color(1, 1, 1, 1)
	if glow != null:
		glow.texture = HUNTRESS_SPEAR_TEX
		glow.hframes = 1
		glow.vframes = 1
		glow.frame = 0
		glow.rotation = 0.0
		glow.scale = HUNTRESS_SPEAR_SCALE * 1.08
		glow.modulate = Color(1.0, 0.96, 0.86, 0.24)
	if collision_shape != null and collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = Vector2(28, 10)


func _apply_wizard_visuals() -> void:
	if sprite != null:
		sprite.visible = true
		sprite.texture = WIZARD_BEAM_SHEET
		sprite.hframes = 3
		sprite.vframes = 4
		sprite.frame_coords = WIZARD_BEAM_FRAME_B
		sprite.scale = WIZARD_BEAM_BASE_SCALE
		sprite.rotation = 0.0
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.98)
	if glow == null:
		return
	glow.texture = WIZARD_BEAM_SHEET
	glow.hframes = 3
	glow.vframes = 4
	glow.frame_coords = WIZARD_BEAM_FRAME_A
	glow.rotation = 0.0
	glow.modulate = Color(0.70, 1.0, 0.55, 0.64)
	glow.scale = WIZARD_BEAM_GLOW_SCALE


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemies"):
		return

	if area.has_method("take_damage"):
		area.take_damage(damage)

	_spawn_impact_flash(global_position)

	if pierce and not _pierced:
		_pierced = true
		# Visual feedback: brief flash of gold tint, keep flying
		if glow != null:
			glow.modulate = Color(1.0, 0.86, 0.30, 0.7)
	else:
		queue_free()


func _spawn_trail() -> void:
	if is_wizard:
		var head_position: Vector2 = previous_position.lerp(global_position, 0.78)
		var mid_position: Vector2 = previous_position.lerp(global_position, 0.52)
		var tail_position: Vector2 = previous_position.lerp(global_position, 0.22)
		_spawn_wizard_trail_shard(head_position, rotation, Vector2(0.62, 0.24), WIZARD_BEAM_FRAME_A)
		_spawn_wizard_trail_shard(mid_position, rotation, Vector2(0.50, 0.20), WIZARD_BEAM_FRAME_B)
		_spawn_wizard_trail_shard(tail_position, rotation, Vector2(0.36, 0.15), WIZARD_BEAM_FRAME_A)
		return
	if is_huntress:
		var spear_trail := Line2D.new()
		spear_trail.z_index = -1
		spear_trail.width = 2.0
		spear_trail.default_color = Color(1.0, 0.96, 0.84, 0.24)
		spear_trail.global_position = Vector2.ZERO
		spear_trail.points = PackedVector2Array([previous_position, global_position])
		get_tree().current_scene.add_child(spear_trail)
		var spear_tween := spear_trail.create_tween()
		spear_tween.tween_property(spear_trail, "modulate", Color(1, 1, 1, 0), 0.08)
		spear_tween.tween_callback(spear_trail.queue_free)
		return

	var trail := Line2D.new()
	trail.z_index = -1
	trail.width = 2.0
	trail.default_color = Color(1.0, 0.9, 0.45, 0.35)
	trail.global_position = Vector2.ZERO
	trail.points = PackedVector2Array([previous_position, global_position])
	get_tree().current_scene.add_child(trail)
	var tween := trail.create_tween()
	tween.tween_property(trail, "modulate", Color(1, 1, 1, 0), 0.15)
	tween.tween_callback(trail.queue_free)


func _spawn_wizard_trail_shard(position: Vector2, angle: float, scale_value: Vector2, frame: Vector2i) -> void:
	var shard := Sprite2D.new()
	shard.texture = WIZARD_BEAM_SHEET
	shard.hframes = 3
	shard.vframes = 4
	shard.frame_coords = frame
	shard.global_position = position
	shard.rotation = angle
	shard.scale = scale_value
	shard.modulate = Color(0.62, 1.0, 0.52, 0.48)
	get_tree().current_scene.add_child(shard)
	var tween := shard.create_tween()
	tween.parallel().tween_property(shard, "scale", scale_value * Vector2(1.55, 0.9), 0.18)
	tween.parallel().tween_property(shard, "modulate", Color(1, 1, 1, 0), 0.18)
	tween.tween_callback(shard.queue_free)


func _spawn_impact_flash(position: Vector2) -> void:
	if is_wizard:
		var fx := Node2D.new()
		fx.global_position = position
		fx.modulate = Color(0.72, 1.0, 0.62, 0.96)
		get_tree().current_scene.add_child(fx)

		for i in range(3):
			var shard := Sprite2D.new()
			shard.texture = WIZARD_BEAM_SHEET
			shard.hframes = 3
			shard.vframes = 4
			shard.frame_coords = WIZARD_BEAM_FRAME_A if i % 2 == 0 else WIZARD_BEAM_FRAME_B
			shard.centered = true
			shard.rotation = randf_range(-0.35, 0.35) + float(i) * TAU / 3.0
			shard.scale = Vector2(0.55, 0.55) * (1.0 - float(i) * 0.12)
			shard.modulate = Color(0.58 + float(i) * 0.08, 1.0, 0.48 + float(i) * 0.08, 0.84)
			fx.add_child(shard)

		var tween_fx := fx.create_tween()
		tween_fx.parallel().tween_property(fx, "scale", Vector2(1.8, 1.8), 0.14)
		tween_fx.parallel().tween_property(fx, "modulate", Color(1, 1, 1, 0), 0.14)
		tween_fx.tween_callback(fx.queue_free)
		return
	if is_huntress:
		var spear_flash := Line2D.new()
		spear_flash.global_position = Vector2.ZERO
		spear_flash.z_index = 1
		spear_flash.width = 3.0
		spear_flash.default_color = Color(1.0, 0.96, 0.86, 0.8)
		var dir := velocity.normalized()
		spear_flash.points = PackedVector2Array([position - dir * 16.0, position + dir * 10.0])
		get_tree().current_scene.add_child(spear_flash)
		var spear_flash_tween := spear_flash.create_tween()
		spear_flash_tween.parallel().tween_property(spear_flash, "width", 1.0, 0.08)
		spear_flash_tween.parallel().tween_property(spear_flash, "modulate", Color(1, 1, 1, 0), 0.08)
		spear_flash_tween.tween_callback(spear_flash.queue_free)
		return

	var flash := Polygon2D.new()
	flash.global_position = position
	flash.color = Color(1.0, 0.92, 0.65, 0.75)
	flash.polygon = PackedVector2Array([
		Vector2(-6, 0), Vector2(-2, -2), Vector2(0, -7), Vector2(2, -2),
		Vector2(7, 0), Vector2(2, 2), Vector2(0, 7), Vector2(-2, 2)
	])
	get_tree().current_scene.add_child(flash)
	var tween := flash.create_tween()
	tween.parallel().tween_property(flash, "scale", Vector2(2.0, 2.0), 0.12)
	tween.parallel().tween_property(flash, "modulate", Color(1, 1, 1, 0), 0.12)
	tween.tween_callback(flash.queue_free)
