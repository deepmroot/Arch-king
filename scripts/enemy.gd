extends Area2D

signal enemy_killed(reward: int)
signal reached_wall(damage: int)

const GOBLIN_SHEET := preload("res://assets/enemies/goblin.png")

@export var speed := 85.0
@export var max_health := 1
@export var coin_reward := 1
@export var wall_y := 110.0
@export var castle_damage := 1

var is_dead := false
var current_health := 1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shadow: Polygon2D = $Shadow


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	_build_animations()
	animated_sprite.play("walk")
	animated_sprite.animation_finished.connect(_on_animation_finished)


func _process(delta: float) -> void:
	if is_dead:
		return

	global_position.y += speed * delta

	if global_position.y >= wall_y:
		is_dead = true
		reached_wall.emit(castle_damage)
		queue_free()


func take_damage(amount: int = 1) -> void:
	if is_dead:
		return

	current_health -= amount
	_flash_hit()
	if current_health > 0:
		return

	is_dead = true
	collision_shape.disabled = true
	enemy_killed.emit(coin_reward)
	animated_sprite.play("death")
	var tween: Tween = create_tween()
	tween.parallel().tween_property(animated_sprite, "modulate", Color(1, 1, 1, 0.0), 0.22)
	tween.parallel().tween_property(shadow, "modulate", Color(0, 0, 0, 0.0), 0.22)


func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		queue_free()


func _flash_hit() -> void:
	animated_sprite.modulate = Color(1.6, 1.2, 1.2, 1)
	var tween: Tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.12)


func _build_animations() -> void:
	var frames := SpriteFrames.new()

	_add_grid_animation(frames, "walk", GOBLIN_SHEET, 9, 5, 0, 0, 7, 10.0, true)
	_add_grid_animation(frames, "death", GOBLIN_SHEET, 9, 5, 4, 4, 8, 8.0, false)

	animated_sprite.sprite_frames = frames


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
