extends Panel

signal settings_changed(settings: Dictionary)
signal close_requested

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
