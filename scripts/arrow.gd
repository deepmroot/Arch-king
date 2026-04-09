extends Area2D

@export var speed := 700.0
@export var damage := 1

var velocity := Vector2.ZERO
var previous_position := Vector2.ZERO

@onready var glow: Sprite2D = $Glow
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	previous_position = global_position
	_apply_damage_visuals()
	area_entered.connect(_on_area_entered)


func set_direction(target_pos: Vector2) -> void:
	var dir := (target_pos - global_position).normalized()
	velocity = dir * speed
	rotation = dir.angle() + PI / 2


func set_damage(value: int) -> void:
	damage = value
	_apply_damage_visuals()


func _process(delta: float) -> void:
	previous_position = global_position
	global_position += velocity * delta
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
	if glow == null:
		return
	glow.modulate = Color(1.0, min(0.78 + damage * 0.06, 1.0), 0.31, 0.3)


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemies"):
		return

	if area.has_method("take_damage"):
		area.take_damage(damage)

	_spawn_impact_flash(global_position)
	queue_free()


func _spawn_trail() -> void:
	var trail := Line2D.new()
	trail.z_index = -1
	trail.width = 2.0
	trail.default_color = Color(1.0, 0.9, 0.45, 0.35)
	trail.global_position = Vector2.ZERO
	trail.points = PackedVector2Array([
		previous_position,
		global_position
	])
	get_tree().current_scene.add_child(trail)
	var tween := trail.create_tween()
	tween.tween_property(trail, "modulate", Color(1, 1, 1, 0), 0.12)
	tween.tween_callback(trail.queue_free)


func _spawn_impact_flash(position: Vector2) -> void:
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
