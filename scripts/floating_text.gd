extends Node2D
class_name FloatingText

var text := ""
var color := Color.WHITE
var lifetime := 0.7
var velocity := Vector2(0, -54)
var age := 0.0
var font_size := 20


func configure(label_text: String, label_color: Color, size: int = 20, life: float = 0.7) -> void:
	text = label_text
	color = label_color
	font_size = size
	lifetime = life
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	position += velocity * delta
	velocity *= 0.94
	modulate.a = clamp(1.0 - age / max(lifetime, 0.001), 0.0, 1.0)
	scale = Vector2.ONE * (1.0 + min(age * 0.3, 0.12))
	queue_redraw()
	if age >= lifetime:
		queue_free()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	if font == null or text.is_empty():
		return

	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var origin := Vector2(-text_size.x * 0.5, 0)
	draw_string(font, origin + Vector2(2, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0, 0, 0, 0.7))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
