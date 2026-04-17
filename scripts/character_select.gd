extends Control

const UI_BTN_NORMAL_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-010.png")
const UI_BTN_HOVER_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-011.png")
const UI_BTN_PRESSED_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-012.png")

const ARCHER_IDLE_RUN_SHEET := preload("res://assets/player/archer/idle_run.png")
const BASE_IDLE_RUN_SHEET := preload("res://assets/player/idle_run.png")
const WIZARD_IDLE_SHEET := preload("res://assets/player/wizard/idle.png")
const SORCERER_IDLE_SHEET := preload("res://assets/player/wizard/sorcerer_idle.png")
const HERO_KNIGHT_IDLE_SHEET := preload("res://assets/player/hero_knight/idle.png")
const HUNTRESS_IDLE_SHEET := preload("res://assets/player/huntress/Idle.png")

const BG_GRASS := Color(0.658824, 0.854902, 0.580392, 1.0)
const BG_GRASS_SHADE := Color(0.52, 0.72, 0.45, 1.0)
const BG_DIRT := Color(0.74, 0.64, 0.45, 1.0)
const PANEL_BG := Color(0.11, 0.09, 0.07, 0.94)
const PANEL_HIGHLIGHT := Color(0.78, 0.65, 0.35, 0.72)
const TEXT_GOLD := Color(1.0, 0.86, 0.52, 1.0)
const TEXT_BODY := Color(0.95, 0.92, 0.84, 1.0)
const TEXT_MUTED := Color(0.77, 0.73, 0.63, 0.92)

var _characters: Array[Dictionary] = []
var _selected_id: String = String(GameState.selected_character)
var _selected_index: int = 0

var _card_controls: Array[Control] = []
var _card_body_controls: Array[ColorRect] = []
var _card_strip_controls: Array[ColorRect] = []
var _card_name_labels: Array[Label] = []

var _preview_sprite_large_y: float = 228.0
var _preview_stage_scale: float = 1.0
var _picker_scroll: ScrollContainer
var _preview_sprite: AnimatedSprite2D
var _preview_name_label: Label
var _preview_title_label: Label
var _preview_role_label: Label
var _preview_edge_label: Label
var _detail_playstyle_label: Label
var _detail_abilities_box: VBoxContainer
var _confirm_btn: Button
var _black_overlay: ColorRect


func _ready() -> void: 
	_characters = _get_character_entries()
	_selected_index = _find_character_index(_selected_id)
	if _selected_index < 0:
		_selected_index = 0
		if not _characters.is_empty():
			_selected_id = String(_characters[0].get("id", GameState.selected_character))
	_build_ui()
	_refresh_selection(false)


func _vp() -> Vector2:
	return get_viewport_rect().size


func _build_ui() -> void:
	var vp: Vector2 = _vp()
	var base_size := Vector2(1280.0, 720.0)
	var scale_x: float = vp.x / base_size.x
	var scale_y: float = vp.y / base_size.y
	var ui_scale: float = min(scale_x, scale_y)
	ui_scale = max(ui_scale, 0.72)
	var offset_x: float = max((vp.x - (base_size.x * ui_scale)) * 0.5, 0.0)
	var offset_y: float = max((vp.y - (base_size.y * ui_scale)) * 0.5, 0.0)

	var picker_y_pos: float = vp.y - 250.0
	var confirm_btn_y: float = picker_y_pos - 68.0
	var panels_h: float = clamp(confirm_btn_y - 126.0 - 12.0, 240.0, 478.0)

	var sx := func(x: float) -> float:
		return offset_x + (x * ui_scale)

	var sy := func(y: float) -> float:
		return offset_y + (y * ui_scale)

	var sw := func(w: float) -> float:
		return w * ui_scale

	var sh := func(h: float) -> float:
		return h * ui_scale

	var sky := ColorRect.new()
	sky.position = Vector2.ZERO
	sky.size = vp
	sky.color = BG_GRASS
	add_child(sky)

	var grass_band := ColorRect.new()
	grass_band.position = Vector2(0.0, 0.0)
	grass_band.size = Vector2(vp.x, vp.y * 0.72)
	grass_band.color = BG_GRASS_SHADE
	add_child(grass_band)

	var path := ColorRect.new()
	path.position = Vector2(vp.x * 0.44, 0.0)
	path.size = Vector2(vp.x * 0.12, vp.y)
	path.color = BG_DIRT
	add_child(path)

	var vignette := ColorRect.new()
	vignette.position = Vector2.ZERO
	vignette.size = vp
	vignette.color = Color(0.0, 0.0, 0.0, 0.14)
	add_child(vignette)

	var header := Label.new()
	header.text = "Choose Your Champion"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.position = Vector2(0.0, 18.0)
	header.size = Vector2(vp.x, 54.0)
	header.add_theme_color_override("font_color", TEXT_GOLD)
	header.add_theme_color_override("font_shadow_color", Color(0.22, 0.14, 0.06, 0.75))
	header.add_theme_constant_override("shadow_offset_x", 2)
	header.add_theme_constant_override("shadow_offset_y", 3)
	header.add_theme_font_size_override("font_size", 36)
	add_child(header)

	var sub := Label.new()
	sub.text = "See the hero, review the role, then scroll through the roster."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0.0, 66.0)
	sub.size = Vector2(vp.x, 24.0)
	sub.add_theme_color_override("font_color", Color(0.30, 0.21, 0.12, 0.95))
	sub.add_theme_font_size_override("font_size", 15)
	add_child(sub)

	var divider := ColorRect.new()
	divider.position = Vector2((vp.x - 360.0) * 0.5, 98.0)
	divider.size = Vector2(360.0, 2.0)
	divider.color = Color(0.58, 0.45, 0.22, 0.42)
	add_child(divider)

	var back_btn := _make_button("← Back", 16)
	back_btn.position = Vector2(26.0, 22.0)
	back_btn.size = Vector2(118.0, 40.0)
	back_btn.pressed.connect(_on_back)
	add_child(back_btn)

	var preview_panel := _create_panel(388.0, panels_h)
	preview_panel.position = Vector2(42.0, 126.0)
	add_child(preview_panel)

	var preview_heading := Label.new()
	preview_heading.text = "Visual Preview"
	preview_heading.position = Vector2(24.0, 16.0)
	preview_heading.size = Vector2(220.0, 28.0)
	preview_heading.add_theme_color_override("font_color", TEXT_GOLD)
	preview_heading.add_theme_font_size_override("font_size", 18)
	preview_panel.add_child(preview_heading)

	var preview_hint := Label.new()
	preview_hint.text = "Selected class appearance"
	preview_hint.position = Vector2(24.0, 42.0)
	preview_hint.size = Vector2(220.0, 20.0)
	preview_hint.add_theme_color_override("font_color", TEXT_MUTED)
	preview_hint.add_theme_font_size_override("font_size", 12)
	preview_panel.add_child(preview_hint)

	var stage_top := 76.0
	var stage_h: float = clamp(panels_h - 200.0, 120.0, 250.0)
	var stage_bot: float = stage_top + stage_h

	var stage_clip := Control.new()
	stage_clip.position = Vector2(24.0, stage_top)
	stage_clip.size = Vector2(340.0, stage_h)
	stage_clip.clip_contents = true
	preview_panel.add_child(stage_clip)

	var preview_stage := ColorRect.new()
	preview_stage.position = Vector2.ZERO
	preview_stage.size = Vector2(340.0, stage_h)
	preview_stage.color = Color(0.18, 0.16, 0.12, 0.92)
	stage_clip.add_child(preview_stage)

	var preview_stage_bar := ColorRect.new()
	preview_stage_bar.position = Vector2.ZERO
	preview_stage_bar.size = Vector2(340.0, 4.0)
	preview_stage_bar.color = PANEL_HIGHLIGHT
	stage_clip.add_child(preview_stage_bar)

	var preview_floor := ColorRect.new()
	preview_floor.position = Vector2(30.0, stage_h * 0.824)
	preview_floor.size = Vector2(280.0, 10.0)
	preview_floor.color = Color(0.0, 0.0, 0.0, 0.24)
	stage_clip.add_child(preview_floor)

	_preview_sprite_large_y = stage_h * 0.35
	_preview_stage_scale = stage_h / 250.0
	_preview_sprite = AnimatedSprite2D.new()
	_preview_sprite.position = Vector2(170.0, _preview_sprite_large_y)
	_preview_sprite.z_index = 2
	stage_clip.add_child(_preview_sprite)

	_preview_name_label = Label.new()
	_preview_name_label.position = Vector2(24.0, stage_bot + 6.0)
	_preview_name_label.size = Vector2(340.0, 34.0)
	_preview_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_name_label.add_theme_color_override("font_color", TEXT_GOLD)
	_preview_name_label.add_theme_font_size_override("font_size", 26)
	preview_panel.add_child(_preview_name_label)

	_preview_title_label = Label.new()
	_preview_title_label.position = Vector2(24.0, stage_bot + 40.0)
	_preview_title_label.size = Vector2(340.0, 24.0)
	_preview_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_title_label.add_theme_color_override("font_color", TEXT_MUTED)
	_preview_title_label.add_theme_font_size_override("font_size", 15)
	preview_panel.add_child(_preview_title_label)

	_preview_role_label = Label.new()
	_preview_role_label.position = Vector2(24.0, stage_bot + 72.0)
	_preview_role_label.size = Vector2(340.0, 22.0)
	_preview_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_role_label.add_theme_color_override("font_color", TEXT_BODY)
	_preview_role_label.add_theme_font_size_override("font_size", 14)
	preview_panel.add_child(_preview_role_label)

	_preview_edge_label = Label.new()
	_preview_edge_label.position = Vector2(24.0, stage_bot + 96.0)
	_preview_edge_label.size = Vector2(340.0, 22.0)
	_preview_edge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_edge_label.add_theme_color_override("font_color", Color(0.98, 0.90, 0.70, 0.95))
	_preview_edge_label.add_theme_font_size_override("font_size", 13)
	preview_panel.add_child(_preview_edge_label)

	var info_panel_width: float = vp.x - 472.0
	var info_panel := _create_panel(info_panel_width, panels_h)
	info_panel.position = Vector2(460.0, 126.0)
	add_child(info_panel)

	var info_heading := Label.new()
	info_heading.text = "Class Information"
	info_heading.position = Vector2(24.0, 16.0)
	info_heading.size = Vector2(info_panel_width - 48.0, 28.0)
	info_heading.add_theme_color_override("font_color", TEXT_GOLD)
	info_heading.add_theme_font_size_override("font_size", 20)
	info_panel.add_child(info_heading)

	var info_sub := Label.new()
	info_sub.text = "Bonuses, role, and expected playstyle"
	info_sub.position = Vector2(24.0, 42.0)
	info_sub.size = Vector2(info_panel_width - 48.0, 20.0)
	info_sub.add_theme_color_override("font_color", TEXT_MUTED)
	info_sub.add_theme_font_size_override("font_size", 13)
	info_panel.add_child(info_sub)

	_detail_playstyle_label = Label.new()
	_detail_playstyle_label.position = Vector2(24.0, 78.0)
	_detail_playstyle_label.size = Vector2(info_panel_width - 48.0, 100.0)
	_detail_playstyle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_playstyle_label.add_theme_color_override("font_color", TEXT_BODY)
	_detail_playstyle_label.add_theme_font_size_override("font_size", 16)
	info_panel.add_child(_detail_playstyle_label)

	var perk_title := Label.new()
	perk_title.text = "Starting Bonuses"
	perk_title.position = Vector2(24.0, 196.0)
	perk_title.size = Vector2(info_panel_width - 48.0, 28.0)
	perk_title.add_theme_color_override("font_color", TEXT_GOLD)
	perk_title.add_theme_font_size_override("font_size", 18)
	info_panel.add_child(perk_title)

	var perk_divider := ColorRect.new()
	perk_divider.position = Vector2(24.0, 228.0)
	perk_divider.size = Vector2(info_panel_width - 48.0, 1.0)
	perk_divider.color = Color(0.72, 0.60, 0.34, 0.28)
	info_panel.add_child(perk_divider)

	_detail_abilities_box = VBoxContainer.new()
	_detail_abilities_box.position = Vector2(24.0, 246.0)
	_detail_abilities_box.size = Vector2(info_panel_width - 48.0, 160.0)
	_detail_abilities_box.add_theme_constant_override("separation", 10)
	info_panel.add_child(_detail_abilities_box)

	_confirm_btn = _make_button("Play", 22)
	_confirm_btn.position = Vector2(460.0, confirm_btn_y)
	_confirm_btn.size = Vector2(280.0, 56.0)
	_confirm_btn.pressed.connect(_on_confirm)
	add_child(_confirm_btn)

	var picker_panel := _create_panel(vp.x - 84.0, 224.0)
	picker_panel.position = Vector2(42.0, picker_y_pos)
	add_child(picker_panel)

	var picker_heading := Label.new()
	picker_heading.text = "Scroll Through Champions"
	picker_heading.position = Vector2(24.0, 14.0)
	picker_heading.size = Vector2(280.0, 26.0)
	picker_heading.add_theme_color_override("font_color", TEXT_GOLD)
	picker_heading.add_theme_font_size_override("font_size", 18)
	picker_panel.add_child(picker_heading)

	var picker_sub := Label.new()
	picker_sub.text = "Mouse wheel, scrollbar, or arrow keys"
	picker_sub.position = Vector2(24.0, 38.0)
	picker_sub.size = Vector2(280.0, 20.0)
	picker_sub.add_theme_color_override("font_color", TEXT_MUTED)
	picker_sub.add_theme_font_size_override("font_size", 12)
	picker_panel.add_child(picker_sub)

	var prev_btn := _make_button("◀", 18)
	prev_btn.position = Vector2(24.0, 88.0)
	prev_btn.size = Vector2(54.0, 104.0)
	prev_btn.pressed.connect(func() -> void: _shift_selection(-1))
	picker_panel.add_child(prev_btn)

	var next_btn := _make_button("▶", 18)
	next_btn.position = Vector2(picker_panel.size.x - 78.0, 88.0)
	next_btn.size = Vector2(54.0, 104.0)
	next_btn.pressed.connect(func() -> void: _shift_selection(1))
	picker_panel.add_child(next_btn)

	_picker_scroll = ScrollContainer.new()
	_picker_scroll.position = Vector2(94.0, 80.0)
	_picker_scroll.size = Vector2(picker_panel.size.x - 188.0, 124.0)
	_picker_scroll.clip_contents = true
	picker_panel.add_child(_picker_scroll)

	var picker_row := HBoxContainer.new()
	picker_row.add_theme_constant_override("separation", 14)
	_picker_scroll.add_child(picker_row)

	_card_controls.clear()
	_card_body_controls.clear()
	_card_strip_controls.clear()
	_card_name_labels.clear()

	for i in range(_characters.size()):
		var entry: Dictionary = _characters[i]
		var card: Control = _build_picker_card(entry, i)
		picker_row.add_child(card)

	_black_overlay = ColorRect.new()
	_black_overlay.position = Vector2.ZERO
	_black_overlay.size = vp
	_black_overlay.color = Color(0, 0, 0, 1)
	_black_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black_overlay)

	var tween: Tween = create_tween()
	tween.tween_property(_black_overlay, "color:a", 0.0, 0.55).set_ease(Tween.EASE_OUT)


func _create_panel(w: float, h: float) -> Control:
	var root := Control.new()
	root.size = Vector2(w, h)

	var shadow := ColorRect.new()
	shadow.position = Vector2(10.0, 10.0)
	shadow.size = Vector2(w - 8.0, h - 8.0)
	shadow.color = Color(0.0, 0.0, 0.0, 0.22)
	root.add_child(shadow)

	var body := ColorRect.new()
	body.position = Vector2.ZERO
	body.size = Vector2(w, h)
	body.color = PANEL_BG
	root.add_child(body)

	var top_bar := ColorRect.new()
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(w, 4.0)
	top_bar.color = PANEL_HIGHLIGHT
	root.add_child(top_bar)

	return root


func _build_picker_card(entry: Dictionary, index: int) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(196.0, 112.0)
	root.size = Vector2(196.0, 112.0)
	root.clip_contents = false

	var shadow := ColorRect.new()
	shadow.position = Vector2(6.0, 10.0)
	shadow.size = Vector2(184.0, 96.0)
	shadow.color = Color(0.0, 0.0, 0.0, 0.20)
	root.add_child(shadow)

	var body := ColorRect.new()
	body.position = Vector2.ZERO
	body.size = Vector2(188.0, 102.0)
	body.color = Color(0.15, 0.12, 0.09, 0.96)
	root.add_child(body)
	_card_body_controls.append(body)

	var strip := ColorRect.new()
	strip.position = Vector2.ZERO
	strip.size = Vector2(188.0, 4.0)
	strip.color = entry.get("icon_color", TEXT_GOLD)
	root.add_child(strip)
	_card_strip_controls.append(strip)

	var sprite := AnimatedSprite2D.new()
	sprite.position = Vector2(44.0, 72.0)
	sprite.z_index = 2
	root.add_child(sprite)
	_apply_preview_to_sprite(sprite, entry, false)

	var name_label := Label.new()
	name_label.position = Vector2(84.0, 18.0)
	name_label.size = Vector2(92.0, 24.0)
	name_label.text = String(entry.get("name", ""))
	name_label.add_theme_color_override("font_color", TEXT_GOLD)
	name_label.add_theme_font_size_override("font_size", 16)
	root.add_child(name_label)
	_card_name_labels.append(name_label)

	var title_label := Label.new()
	title_label.position = Vector2(84.0, 42.0)
	title_label.size = Vector2(96.0, 40.0)
	title_label.text = String(entry.get("title", ""))
	title_label.add_theme_color_override("font_color", TEXT_MUTED)
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(title_label)

	var hotkey_label := Label.new()
	hotkey_label.position = Vector2(162.0, 10.0)
	hotkey_label.size = Vector2(18.0, 18.0)
	hotkey_label.text = str(index + 1)
	hotkey_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hotkey_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82, 0.55))
	hotkey_label.add_theme_font_size_override("font_size", 10)
	root.add_child(hotkey_label)

	var button := Button.new()
	button.position = Vector2.ZERO
	button.size = Vector2(188.0, 102.0)
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	button.mouse_entered.connect(func() -> void: _select_index(index))
	button.pressed.connect(func() -> void: _select_index(index))
	root.add_child(button)

	_card_controls.append(root)
	return root


func _get_character_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for base_entry_variant in GameState.get_characters():
		var base_entry: Dictionary = base_entry_variant
		var entry: Dictionary = base_entry.duplicate(true)
		var char_id: String = String(entry.get("id", ""))
		match char_id:
			GameState.CHAR_ARCHER:
				entry["role"] = "Role: Balanced Wall Archer"
				entry["edge"] = "Best for a straightforward ranged run with no drawbacks"
				entry["preview"] = {
					"mode": "grid",
					"sheet": ARCHER_IDLE_RUN_SHEET,
					"columns": 8,
					"rows": 2,
					"row_index": 0,
					"column_start": 0,
					"column_end": 1,
					"fps": 4.0,
					"large_scale": 4.9,
					"small_scale": 1.75,
					"large_offset": Vector2(0.0, 24.0),
					"small_offset": Vector2(0.0, 4.0),
					"modulate": Color(1.0, 1.0, 1.0, 1.0),
				}
			GameState.CHAR_WARDEN:
				entry["role"] = "Role: Armored Fortress Champion"
				entry["edge"] = "Best for holding the wall and powering up castle defenses early"
				entry["preview"] = {
					"mode": "strip",
					"sheet": HERO_KNIGHT_IDLE_SHEET,
					"frame_count": 8,
					"fps": 6.0,
					"large_scale": 3.9,
					"small_scale": 1.8,
					"large_offset": Vector2(0.0, 10.0),
					"small_offset": Vector2(0.0, 2.0),
					"modulate": Color(1.0, 1.0, 1.0, 1.0),
				}
			GameState.CHAR_RANGER:
				entry["role"] = "Role: Fast Ranged Hunter"
				entry["edge"] = "Best for killing fast enemies before they ever touch the wall"
				entry["preview"] = {
					"mode": "strip",
					"sheet": HUNTRESS_IDLE_SHEET,
					"frame_count": 8,
					"fps": 6.0,
					"large_scale": 4.2,
					"small_scale": 1.85,
					"large_offset": Vector2(0.0, 12.0),
					"small_offset": Vector2(0.0, 2.0),
					"modulate": Color(0.96, 1.0, 0.92, 1.0),
				}
			GameState.CHAR_ALCHEMIST:
				entry["role"] = "Role: Battlefield Control"
				entry["edge"] = "Best for trap-heavy and catapult-heavy runs"
				entry["preview"] = {
					"mode": "grid",
					"sheet": BASE_IDLE_RUN_SHEET,
					"columns": 8,
					"rows": 2,
					"row_index": 0,
					"column_start": 0,
					"column_end": 1,
					"fps": 4.0,
					"large_scale": 4.9,
					"small_scale": 2.05,
					"large_offset": Vector2(0.0, 24.0),
					"small_offset": Vector2(0.0, 6.0),
					"modulate": Color(1.08, 0.90, 0.72, 1.0),
				}
			GameState.CHAR_MERCHANT:
				entry["role"] = "Role: Economy and Tempo"
				entry["edge"] = "Best for snowballing coins and faster upgrades"
				entry["preview"] = {
					"mode": "strip",
					"sheet": SORCERER_IDLE_SHEET,
					"frame_count": 10,
					"fps": 8.0,
					"large_scale": 1.48,
					"small_scale": 0.66,
					"large_offset": Vector2(0.0, 10.0),
					"small_offset": Vector2(0.0, 2.0),
					"modulate": Color(1.0, 1.0, 1.0, 1.0),
				}
			GameState.CHAR_WIZARD:
				entry["role"] = "Role: Piercing Arcane Burst"
				entry["edge"] = "Best for blasting through clustered enemies"
				entry["preview"] = {
					"mode": "strip",
					"sheet": WIZARD_IDLE_SHEET,
					"frame_count": 10,
					"fps": 6.0,
					"large_scale": 3.7,
					"small_scale": 1.65,
					"large_offset": Vector2(0.0, 22.0),
					"small_offset": Vector2(0.0, 8.0),
					"modulate": Color(1.0, 1.0, 1.0, 1.0),
				}
			_:
				entry["role"] = "Role: Balanced"
				entry["edge"] = "Best for a standard run"
				entry["preview"] = {
					"mode": "grid",
					"sheet": BASE_IDLE_RUN_SHEET,
					"columns": 8,
					"rows": 2,
					"row_index": 0,
					"column_start": 0,
					"column_end": 1,
					"fps": 4.0,
					"large_scale": 4.8,
					"small_scale": 2.0,
					"large_offset": Vector2(0.0, 24.0),
					"small_offset": Vector2(0.0, 6.0),
					"modulate": Color(1.0, 1.0, 1.0, 1.0),
				}
		entries.append(entry)
	return entries


func _find_character_index(id: String) -> int:
	for i in range(_characters.size()):
		if String(_characters[i].get("id", "")) == id:
			return i
	return -1


func _refresh_selection(animate_cards: bool = true) -> void:
	if _characters.is_empty():
		return

	var entry: Dictionary = _characters[_selected_index]
	_selected_id = String(entry.get("id", ""))
	GameState.selected_character = _selected_id

	_preview_name_label.text = String(entry.get("name", ""))
	_preview_title_label.text = String(entry.get("title", ""))
	_preview_role_label.text = String(entry.get("role", ""))
	_preview_edge_label.text = String(entry.get("edge", ""))
	_detail_playstyle_label.text = String(entry.get("playstyle", ""))
	_confirm_btn.text = "Play as %s" % String(entry.get("name", "Hero"))

	_apply_preview_to_sprite(_preview_sprite, entry, true)
	_refresh_ability_rows(entry)
	_refresh_cards(animate_cards)
	call_deferred("_scroll_selected_card_into_view")


func _refresh_ability_rows(entry: Dictionary) -> void:
	for child in _detail_abilities_box.get_children():
		child.queue_free()

	var abilities: Array = entry.get("abilities", [])
	var accent: Color = entry.get("icon_color", TEXT_GOLD)
	for ability_variant in abilities:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_detail_abilities_box.add_child(row)

		var bullet := ColorRect.new()
		bullet.custom_minimum_size = Vector2(12.0, 12.0)
		bullet.color = accent
		row.add_child(bullet)

		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = String(ability_variant)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", TEXT_BODY)
		label.add_theme_font_size_override("font_size", 15)
		row.add_child(label)


func _refresh_cards(animate_cards: bool) -> void:
	for i in range(_card_controls.size()):
		var card: Control = _card_controls[i]
		var body: ColorRect = _card_body_controls[i]
		var strip: ColorRect = _card_strip_controls[i]
		var name_label: Label = _card_name_labels[i]
		var entry: Dictionary = _characters[i]
		var is_selected: bool = i == _selected_index
		var accent: Color = entry.get("icon_color", TEXT_GOLD)

		body.color = Color(0.24, 0.18, 0.12, 0.98) if is_selected else Color(0.15, 0.12, 0.09, 0.96)
		strip.color = accent if is_selected else accent.darkened(0.22)
		strip.size.y = 6.0 if is_selected else 4.0
		name_label.add_theme_color_override("font_color", TEXT_GOLD if is_selected else Color(0.90, 0.84, 0.72, 0.95))

		if animate_cards:
			var tween: Tween = card.create_tween()
			tween.tween_property(card, "scale", Vector2.ONE * (1.04 if is_selected else 1.0), 0.16).set_ease(Tween.EASE_OUT)
		else:
			card.scale = Vector2.ONE * (1.04 if is_selected else 1.0)


func _apply_preview_to_sprite(sprite: AnimatedSprite2D, entry: Dictionary, large_preview: bool) -> void:
	var preview: Dictionary = entry.get("preview", {})
	sprite.sprite_frames = _build_preview_frames(preview)
	sprite.modulate = preview.get("modulate", Color.WHITE)
	var scale_value: float = float(preview.get("large_scale", 4.5)) if large_preview else float(preview.get("small_scale", 2.0))
	if large_preview:
		scale_value *= _preview_stage_scale
	sprite.scale = Vector2.ONE * scale_value
	var offset: Vector2 = preview.get("large_offset", Vector2.ZERO) if large_preview else preview.get("small_offset", Vector2.ZERO)
	if large_preview:
		sprite.position = Vector2(170.0, _preview_sprite_large_y) + offset * _preview_stage_scale
	else:
		sprite.position = Vector2(36.0, 54.0) + offset
	if sprite.sprite_frames != null:
		sprite.play("idle")


func _build_preview_frames(preview: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", float(preview.get("fps", 5.0)))

	var mode: String = String(preview.get("mode", "strip"))
	var sheet: Texture2D = preview.get("sheet", null)
	if sheet == null:
		return frames

	if mode == "grid":
		var columns: int = int(preview.get("columns", 1))
		var rows: int = int(preview.get("rows", 1))
		var row_index: int = int(preview.get("row_index", 0))
		var column_start: int = int(preview.get("column_start", 0))
		var column_end: int = int(preview.get("column_end", 0))
		var frame_width: int = int(sheet.get_width() / float(max(columns, 1)))
		var frame_height: int = int(sheet.get_height() / float(max(rows, 1)))
		for col in range(column_start, column_end + 1):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * frame_width, row_index * frame_height, frame_width, frame_height)
			frames.add_frame("idle", atlas)
	else:
		var frame_count: int = int(preview.get("frame_count", 1))
		var frame_width_strip: int = int(sheet.get_width() / float(max(frame_count, 1)))
		var frame_height_strip: int = sheet.get_height()
		for i in range(frame_count):
			var atlas_strip := AtlasTexture.new()
			atlas_strip.atlas = sheet
			atlas_strip.region = Rect2(i * frame_width_strip, 0, frame_width_strip, frame_height_strip)
			frames.add_frame("idle", atlas_strip)

	return frames


func _select_index(index: int) -> void:
	if _characters.is_empty():
		return
	_selected_index = clamp(index, 0, _characters.size() - 1)
	_refresh_selection(true)


func _shift_selection(direction: int) -> void:
	if _characters.is_empty():
		return
	var next_index: int = wrapi(_selected_index + direction, 0, _characters.size())
	_select_index(next_index)


func _scroll_selected_card_into_view() -> void:
	if _picker_scroll == null or _selected_index < 0 or _selected_index >= _card_controls.size():
		return

	var card: Control = _card_controls[_selected_index]
	var left: float = card.position.x
	var right: float = left + card.size.x
	var current_scroll: float = float(_picker_scroll.scroll_horizontal)
	var visible_width: float = _picker_scroll.size.x

	if left < current_scroll:
		_picker_scroll.scroll_horizontal = int(max(left - 12.0, 0.0))
	elif right > current_scroll + visible_width:
		_picker_scroll.scroll_horizontal = int(max(right - visible_width + 12.0, 0.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_shift_selection(-1)
		accept_event()
		return
	if event.is_action_pressed("ui_right"):
		_shift_selection(1)
		accept_event()
		return
	if event.is_action_pressed("ui_accept"):
		_on_confirm()
		accept_event()
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if not mouse_event.pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and _picker_scroll != null:
			_picker_scroll.scroll_horizontal = max(_picker_scroll.scroll_horizontal - 96, 0)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and _picker_scroll != null:
			_picker_scroll.scroll_horizontal += 96


func _on_confirm() -> void:
	GameState.selected_character = _selected_id
	_black_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween: Tween = create_tween()
	tween.tween_property(_black_overlay, "color:a", 1.0, 0.45)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/Level.tscn"))


func _on_back() -> void:
	_black_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween: Tween = create_tween()
	tween.tween_property(_black_overlay, "color:a", 1.0, 0.38)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))


func _make_button(label_text: String, font_size: int) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_stylebox_override("normal", _make_ui_style(UI_BTN_NORMAL_TEX, 10.0, Color(0.34, 0.27, 0.18, 1.0)))
	btn.add_theme_stylebox_override("hover", _make_ui_style(UI_BTN_HOVER_TEX, 10.0, Color(0.44, 0.35, 0.23, 1.0)))
	btn.add_theme_stylebox_override("pressed", _make_ui_style(UI_BTN_PRESSED_TEX, 10.0, Color(0.25, 0.20, 0.14, 1.0)))
	btn.add_theme_stylebox_override("focus", _make_ui_style(UI_BTN_HOVER_TEX, 10.0, Color(0.44, 0.35, 0.23, 1.0)))
	btn.add_theme_color_override("font_color", TEXT_BODY)
	btn.add_theme_color_override("font_hover_color", TEXT_GOLD)
	btn.add_theme_color_override("font_pressed_color", Color(0.84, 0.70, 0.36, 1.0))
	btn.add_theme_font_size_override("font_size", font_size)
	return btn


func _make_ui_style(texture: Texture2D, content_margin: float, tint: Color) -> StyleBoxTexture:
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
