extends Panel

signal settings_changed(settings: Dictionary)
signal close_requested

const UI_PANEL_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-transparent-border-010.png")
const UI_BTN_NORMAL_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-010.png")
const UI_BTN_HOVER_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-011.png")
const UI_BTN_PRESSED_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-012.png")

@onready var display_mode_option: OptionButton = $Margin/VBox/DisplayModeOption
@onready var resolution_scale_option: OptionButton = $Margin/VBox/ResolutionScaleOption
@onready var master_volume_slider: HSlider = $Margin/VBox/MasterVolumeSlider
@onready var music_volume_slider: HSlider = $Margin/VBox/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = $Margin/VBox/SfxVolumeSlider
@onready var close_button: Button = $Margin/VBox/ButtonRow/CloseButton

var _is_updating: bool = false
var _resolution_scales: Array[float] = [0.75, 1.0, 1.25, 1.5]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	display_mode_option.clear()
	display_mode_option.add_item("Fullscreen")
	display_mode_option.add_item("Borderless")
	display_mode_option.add_item("Windowed")

	resolution_scale_option.clear()
	for scale in _resolution_scales:
		resolution_scale_option.add_item("%d%%" % int(scale * 100.0))

	display_mode_option.item_selected.connect(_emit_settings_changed)
	resolution_scale_option.item_selected.connect(_emit_settings_changed)
	master_volume_slider.value_changed.connect(func(_value: float): _emit_settings_changed())
	music_volume_slider.value_changed.connect(func(_value: float): _emit_settings_changed())
	sfx_volume_slider.value_changed.connect(func(_value: float): _emit_settings_changed())
	close_button.pressed.connect(func(): close_requested.emit())

	_apply_visual_theme()


func _make_ui_style(texture: Texture2D, tint: Color, content_margin: float = 10.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 12
	style.texture_margin_top = 12
	style.texture_margin_right = 12
	style.texture_margin_bottom = 12
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	style.modulate_color = tint
	return style


func _style_button_like(control: BaseButton) -> void:
	control.add_theme_stylebox_override("normal", _make_ui_style(UI_BTN_NORMAL_TEX, Color(0.34, 0.27, 0.18, 1.0), 10.0))
	control.add_theme_stylebox_override("hover", _make_ui_style(UI_BTN_HOVER_TEX, Color(0.44, 0.35, 0.23, 1.0), 10.0))
	control.add_theme_stylebox_override("pressed", _make_ui_style(UI_BTN_PRESSED_TEX, Color(0.25, 0.2, 0.14, 1.0), 10.0))
	control.add_theme_stylebox_override("focus", _make_ui_style(UI_BTN_HOVER_TEX, Color(0.44, 0.35, 0.23, 1.0), 10.0))
	control.add_theme_color_override("font_color", Color(0.98, 0.95, 0.86, 1))
	control.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.75, 1))
	control.add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.75, 1))
	control.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.62, 1))


func _apply_visual_theme() -> void:
	add_theme_stylebox_override("panel", _make_ui_style(UI_PANEL_TEX, Color(0.82, 0.7, 0.44, 1.0), 14.0))

	for control in [display_mode_option, resolution_scale_option, close_button]:
		_style_button_like(control)
		control.custom_minimum_size.y = 42

	for slider in [master_volume_slider, music_volume_slider, sfx_volume_slider]:
		slider.custom_minimum_size.y = 30
		slider.modulate = Color(0.9, 0.82, 0.62, 1)

	var title_label: Label = $Margin/VBox/TitleLabel
	var hint_label: Label = $Margin/VBox/HintLabel
	title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.58, 1))
	hint_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8, 1))

	for label_path in [
		"Margin/VBox/DisplayModeLabel",
		"Margin/VBox/ResolutionScaleLabel",
		"Margin/VBox/MasterVolumeLabel",
		"Margin/VBox/MusicVolumeLabel",
		"Margin/VBox/SfxVolumeLabel"
	]:
		var label: Label = get_node(label_path)
		label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))


func apply_settings(settings: Dictionary) -> void:
	_is_updating = true

	var display_mode: String = str(settings.get("display_mode", "fullscreen"))
	match display_mode:
		"borderless":
			display_mode_option.select(1)
		"windowed":
			display_mode_option.select(2)
		_:
			display_mode_option.select(0)

	var resolution_scale: float = float(settings.get("resolution_scale", 1.0))
	var best_index: int = 0
	var best_distance: float = INF
	for i in range(_resolution_scales.size()):
		var distance: float = abs(_resolution_scales[i] - resolution_scale)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	resolution_scale_option.select(best_index)

	master_volume_slider.value = float(settings.get("master_volume", 1.0))
	music_volume_slider.value = float(settings.get("music_volume", 0.6))
	sfx_volume_slider.value = float(settings.get("sfx_volume", 1.0))

	_is_updating = false


func focus_default() -> void:
	display_mode_option.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()


func _emit_settings_changed(_value = null) -> void:
	if _is_updating:
		return

	var selected_scale: float = _resolution_scales[resolution_scale_option.selected]
	var selected_mode: String = "fullscreen"
	match display_mode_option.selected:
		1:
			selected_mode = "borderless"
		2:
			selected_mode = "windowed"

	settings_changed.emit({
		"display_mode": selected_mode,
		"resolution_scale": selected_scale,
		"master_volume": master_volume_slider.value,
		"music_volume": music_volume_slider.value,
		"sfx_volume": sfx_volume_slider.value,
	})
