extends Area2D

@export var speed := 700.0
@export var damage := 1

var velocity := Vector2.ZERO

@onready var glow: Sprite2D = $Glow


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func set_direction(target_pos: Vector2) -> void:
	var dir = (target_pos - global_position).normalized()
	velocity = dir * speed
	rotation = dir.angle() + PI/2 # Adjust rotation if sprite is vertical (pointing up)


func set_damage(value: int) -> void:
	damage = value


func _process(delta: float) -> void:
	global_position += velocity * delta
	glow.modulate.a = 0.22 + sin(Time.get_ticks_msec() * 0.02) * 0.06

	# Check if outside screen bounds
	var viewport_rect = get_viewport_rect()
	if not viewport_rect.grow(100.0).has_point(global_position):
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemies"):
		return

	if area.has_method("take_damage"):
		area.take_damage(damage)

	queue_free()
