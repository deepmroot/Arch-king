extends Control

# Assets
const DIRT_TEX := preload("res://assets/environment/fantasy_tileset/picks/dirt_tile.png")
const GATE_TEX := preload("res://assets/environment/fantasy_tileset/The Fan-tasy Tileset (Free)/Art/Buildings/CityWall_Gate_1.png")
const TREE_TEX := preload("res://assets/environment/fantasy_tileset/The Fan-tasy Tileset (Free)/Art/Trees and Bushes/Tree_Emerald_1.png")
const TREE2_TEX := preload("res://assets/environment/fantasy_tileset/The Fan-tasy Tileset (Free)/Art/Trees and Bushes/Tree_Emerald_3.png")
const BUSH_TEX := preload("res://assets/environment/fantasy_tileset/The Fan-tasy Tileset (Free)/Art/Trees and Bushes/Bush_Emerald_4.png")
const BANNER_TEX := preload("res://assets/environment/fantasy_tileset/The Fan-tasy Tileset (Free)/Art/Props/Banner_Stick_1_Purple.png")
const WALL_TEX := preload("res://assets/environment/walls/wall_battlement.png")
const PILLAR_TEX := preload("res://assets/environment/walls/wall_level1.png")
const GOBLIN_TEX := preload("res://assets/enemies/goblins/$Goblin_1.png")
const UI_PANEL_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-transparent-border-010.png")
const UI_BTN_NORMAL_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-010.png")
const UI_BTN_HOVER_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-011.png")
const UI_BTN_PRESSED_TEX := preload("res://assets/ui/kenney_fantasy_ui_borders/panel-012.png")

const GAMEPLAY_GRASS_COLOR := Color(0.658824, 0.854902, 0.580392, 1.0)

@onready var audio_player: AudioStreamPlayer = $AudioPlayer

var current_phase := "splash_studio"
var phase_timer := 0.0

var splash_root: Control
var splash_layer: CanvasLayer
var menu_layer: Control
var main_panel: Control
var options_panel: Control
var black_overlay: ColorRect
var music_slider: HSlider
var title_label: Label
var tap_label: Label

var goblin_sprites: Array[Sprite2D] = []
var goblin_speeds: Array[float] = []


func _ready() -> void:
	audio_player.volume_db = -80.0
	_build_splash_screen()


func _vp() -> Vector2:
	return get_viewport_rect().size


func _process(delta: float) -> void:
	phase_timer += delta

	match current_phase:
		"splash_studio":
			if phase_timer > 3.5:
				_transition_to("splash_title")
		"splash_title":
			if phase_timer > 3.5:
				_transition_to("menu_fadein")
		"menu_fadein":
			if phase_timer > 1.8:
				_transition_to("menu")
		"menu":
			_update_goblins(delta)
			# Gentle panel bob
			if main_panel != null and is_instance_valid(main_panel):
				var base_y: float = main_panel.get_meta("base_y", main_panel.position.y)
				main_panel.position.y = base_y + sin(phase_timer * 1.2) * 2.0
			# Pulse early access label
			if tap_label != null and tap_label.visible:
				tap_label.modulate.a = 0.4 + abs(sin(phase_timer * 2.0)) * 0.6

	# Fade menu music in across splashes
	if audio_player.volume_db < linear_to_db(0.8):
		audio_player.volume_db = move_toward(audio_player.volume_db, linear_to_db(0.8), delta * 15.0)


func _transition_to(phase: String) -> void:
	current_phase = phase
	phase_timer = 0.0
	match phase:
		"splash_title":
			_show_title_splash()
		"menu_fadein":
			if splash_layer != null:
				splash_layer.queue_free()
				splash_layer = null
				splash_root = null
			_build_menu()
		"menu":
			pass


# ==========================================
# SPLASH SCREENS
# ==========================================

func _build_splash_screen() -> void:
	var vp := _vp()

	splash_layer = CanvasLayer.new()
	splash_layer.layer = 100
	add_child(splash_layer)

	# Explicit-size root so children can position against it
	splash_root = Control.new()
	splash_root.position = Vector2.ZERO
	splash_root.size = vp
	splash_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash_layer.add_child(splash_root)

	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = vp
	bg.color = Color(0.02, 0.015, 0.01, 1)
	splash_root.add_child(bg)

	var studio := Label.new()
	studio.text = "GxDev Studios"
	studio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	studio.position = Vector2(0.0, vp.y * 0.40)
	studio.size = Vector2(vp.x, 60.0)
	studio.add_theme_color_override("font_color", Color(0.85, 0.78, 0.58, 1))
	studio.add_theme_font_size_override("font_size", 36)
	studio.modulate.a = 0.0
	splash_root.add_child(studio)

	var presents := Label.new()
	presents.text = "presents"
	presents.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	presents.position = Vector2(0.0, vp.y * 0.53)
	presents.size = Vector2(vp.x, 28.0)
	presents.add_theme_color_override("font_color", Color(0.65, 0.6, 0.48, 0.6))
	presents.add_theme_font_size_override("font_size", 16)
	presents.modulate.a = 0.0
	splash_root.add_child(presents)

	var tween := create_tween()
	tween.tween_property(studio, "modulate:a", 1.0, 1.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(presents, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_OUT).set_delay(0.5)
	tween.tween_interval(1.2)
	tween.tween_property(studio, "modulate:a", 0.0, 0.8)
	tween.parallel().tween_property(presents, "modulate:a", 0.0, 0.6)


func _show_title_splash() -> void:
	if splash_root == null:
		_transition_to("menu_fadein")
		return

	var vp := _vp()
	splash_root.size = vp

	for child in splash_root.get_children():
		child.queue_free()

	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = vp
	bg.color = Color(0.02, 0.015, 0.01, 1)
	splash_root.add_child(bg)

	var line := ColorRect.new()
	line.size = Vector2(160.0, 2.0)
	line.position = Vector2((vp.x - 160.0) * 0.5, vp.y * 0.38)
	line.color = Color(0.78, 0.65, 0.35, 0.0)
	splash_root.add_child(line)

	var title := Label.new()
	title.text = "HORDEFALL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0.0, vp.y * 0.41)
	title.size = Vector2(vp.x, 80.0)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45, 1))
	title.add_theme_color_override("font_shadow_color", Color(0.6, 0.35, 0.1, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.add_theme_font_size_override("font_size", 64)
	title.modulate.a = 0.0
	splash_root.add_child(title)

	var tagline := Label.new()
	tagline.text = "The wall must hold."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.position = Vector2(0.0, vp.y * 0.56)
	tagline.size = Vector2(vp.x, 30.0)
	tagline.add_theme_color_override("font_color", Color(0.82, 0.76, 0.6, 0.8))
	tagline.add_theme_font_size_override("font_size", 18)
	tagline.modulate.a = 0.0
	splash_root.add_child(tagline)

	var tween := create_tween()
	tween.tween_property(line, "color:a", 0.6, 0.8)
	tween.parallel().tween_property(title, "modulate:a", 1.0, 1.0).set_delay(0.2)
	tween.parallel().tween_property(tagline, "modulate:a", 1.0, 1.2).set_delay(0.6)
	tween.tween_interval(1.0)
	tween.tween_property(title, "modulate:a", 0.0, 0.7)
	tween.parallel().tween_property(tagline, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(line, "color:a", 0.0, 0.5)


# ==========================================
# MAIN MENU
# ==========================================

func _build_menu() -> void:
	var vp := _vp()

	menu_layer = Control.new()
	menu_layer.position = Vector2.ZERO
	menu_layer.size = vp
	menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu_layer)

	_build_menu_background(vp)

	# Dark vignette (lighter so the scene reads closer to gameplay)
	var vignette := ColorRect.new()
	vignette.position = Vector2.ZERO
	vignette.size = vp
	vignette.color = Color(0.0, 0.0, 0.0, 0.2)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(vignette)

	# Main panel — centered with a tiny downward offset
	const PANEL_W := 400.0
	const PANEL_H := 460.0
	main_panel = _build_main_panel(PANEL_W, PANEL_H)
	main_panel.position = Vector2((vp.x - PANEL_W) * 0.5, (vp.y - PANEL_H) * 0.5 + 18.0)
	main_panel.size = Vector2(PANEL_W, PANEL_H)
	main_panel.z_index = 50
	main_panel.set_meta("base_y", main_panel.position.y)
	main_panel.modulate.a = 0.0
	menu_layer.add_child(main_panel)

	# Options panel — same center, hidden
	const OPT_W := 420.0
	const OPT_H := 360.0
	options_panel = _build_options_panel(OPT_W, OPT_H)
	options_panel.position = Vector2((vp.x - OPT_W) * 0.5, (vp.y - OPT_H) * 0.5 + 18.0)
	options_panel.size = Vector2(OPT_W, OPT_H)
	options_panel.z_index = 50
	options_panel.visible = false
	menu_layer.add_child(options_panel)

	# Full-screen black fade overlay
	black_overlay = ColorRect.new()
	black_overlay.position = Vector2.ZERO
	black_overlay.size = vp
	black_overlay.color = Color(0, 0, 0, 1)
	black_overlay.z_index = 60
	black_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(black_overlay)

	# Fade in: black → clear, panel fade in
	var tween := create_tween()
	tween.tween_property(black_overlay, "color:a", 0.0, 1.5).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_panel, "modulate:a", 1.0, 1.8).set_ease(Tween.EASE_OUT).set_delay(0.4)


func _build_menu_background(vp: Vector2) -> void:
	# Match level proportions/colors more closely
	var wall_top := vp.y * 0.522
	var wall_bottom := vp.y * 0.60
	var wall_center_y := (wall_top + wall_bottom) * 0.5

	# Top field area — match the gameplay scene's plain green fill
	var grass := ColorRect.new()
	grass.position = Vector2.ZERO
	grass.size = Vector2(vp.x, wall_bottom)
	grass.color = GAMEPLAY_GRASS_COLOR
	grass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(grass)

	# Path lane in the center (same visual idea as gameplay)
	var path := TextureRect.new()
	path.texture = DIRT_TEX
	path.position = Vector2(vp.x * 0.37, 0.0)
	path.size = Vector2(vp.x * 0.26, wall_bottom)
	path.stretch_mode = TextureRect.STRETCH_TILE
	path.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(path)

	# Lower support area + boundary strip
	var support_area := ColorRect.new()
	support_area.position = Vector2(0.0, wall_bottom)
	support_area.size = Vector2(vp.x, vp.y - wall_bottom)
	support_area.color = Color(0.52549, 0.431373, 0.247059, 0.9)
	support_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(support_area)

	var backyard_boundary := ColorRect.new()
	backyard_boundary.position = Vector2(0.0, vp.y * 0.933)
	backyard_boundary.size = Vector2(vp.x, vp.y * 0.067)
	backyard_boundary.color = Color(0.360784, 0.333333, 0.27451, 1)
	backyard_boundary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(backyard_boundary)

	# Wall color bands like the level scene
	var wall_band := ColorRect.new()
	wall_band.position = Vector2(0.0, wall_top)
	wall_band.size = Vector2(vp.x, wall_bottom - wall_top)
	wall_band.color = Color(0.388235, 0.352941, 0.294118, 1)
	wall_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(wall_band)

	var wall_highlight := ColorRect.new()
	wall_highlight.position = Vector2(0.0, wall_top)
	wall_highlight.size = Vector2(vp.x, (wall_bottom - wall_top) * 0.3)
	wall_highlight.color = Color(0.584314, 0.529412, 0.423529, 0.45)
	wall_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(wall_highlight)

	var wall_mid_shadow := ColorRect.new()
	wall_mid_shadow.position = Vector2(0.0, wall_top + (wall_bottom - wall_top) * 0.42)
	wall_mid_shadow.size = Vector2(vp.x, (wall_bottom - wall_top) * 0.28)
	wall_mid_shadow.color = Color(0, 0, 0, 0.12)
	wall_mid_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(wall_mid_shadow)

	var wall_front_shadow := ColorRect.new()
	wall_front_shadow.position = Vector2(0.0, wall_bottom)
	wall_front_shadow.size = Vector2(vp.x, vp.y * 0.029)
	wall_front_shadow.color = Color(0, 0, 0, 0.18)
	wall_front_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(wall_front_shadow)

	# Wall strip — alternating pillar/body textures used in gameplay
	var body_scale := 90.0 / 256.0
	var body_w := 338.0 * body_scale
	var pillar_scale := 100.0 / 206.0
	var pillar_w := 128.0 * pillar_scale
	var cursor_x := 0.0
	while cursor_x < vp.x + pillar_w:
		var p := Sprite2D.new()
		p.texture = PILLAR_TEX
		p.scale = Vector2.ONE * pillar_scale
		p.position = Vector2(cursor_x + pillar_w * 0.5, wall_center_y)
		p.z_index = 2
		menu_layer.add_child(p)
		cursor_x += pillar_w

		var b := Sprite2D.new()
		b.texture = WALL_TEX
		b.scale = Vector2.ONE * body_scale
		b.position = Vector2(cursor_x + body_w * 0.5, wall_center_y)
		b.z_index = 1
		menu_layer.add_child(b)
		cursor_x += body_w

	# Gate centered on the wall line
	var gate := Sprite2D.new()
	gate.texture = GATE_TEX
	gate.position = Vector2(vp.x * 0.5, wall_bottom - 2.0)
	gate.scale = Vector2(2.0, 2.0)
	gate.z_index = 4
	menu_layer.add_child(gate)

	# Trees and bushes placed similarly to level scene composition
	var tree_data := [
		{"p": Vector2(0.065, 0.11), "t": TREE_TEX},
		{"p": Vector2(0.174, 0.278), "t": TREE_TEX},
		{"p": Vector2(0.087, 0.5), "t": TREE_TEX},
		{"p": Vector2(0.868, 0.167), "t": TREE_TEX},
		{"p": Vector2(0.938, 0.444), "t": TREE_TEX},
		{"p": Vector2(0.894, 0.644), "t": TREE2_TEX},
		{"p": Vector2(0.122, 0.678), "t": TREE2_TEX},
	]
	for info in tree_data:
		var tree := Sprite2D.new()
		tree.texture = info["t"]
		tree.position = Vector2(vp.x * info["p"].x, vp.y * info["p"].y)
		tree.z_index = 0
		menu_layer.add_child(tree)

	var bush_positions := [
		Vector2(vp.x * 0.308, vp.y * 0.394),
		Vector2(vp.x * 0.677, vp.y * 0.372),
		Vector2(vp.x * 0.276, vp.y * 0.578),
		Vector2(vp.x * 0.729, vp.y * 0.578),
	]
	for bp in bush_positions:
		var bush := Sprite2D.new()
		bush.texture = BUSH_TEX
		bush.position = bp
		bush.scale = Vector2(1.35, 1.35)
		bush.z_index = 0
		menu_layer.add_child(bush)

	# Banners flanking gate
	for side in [-1.0, 1.0]:
		var banner := Sprite2D.new()
		banner.texture = BANNER_TEX
		banner.position = Vector2(vp.x * 0.5 + side * 126.0, wall_top - 20.0)
		banner.z_index = 5
		menu_layer.add_child(banner)

	# Marching goblins across the upper lane
	goblin_sprites.clear()
	goblin_speeds.clear()
	for gi in range(5):
		var gob := Sprite2D.new()
		gob.texture = GOBLIN_TEX
		gob.hframes = 3
		gob.vframes = 4
		gob.frame = gi % 3
		gob.scale = Vector2(1.2, 1.2)
		gob.z_index = 0
		gob.position = Vector2(
			randf_range(vp.x * 0.15, vp.x * 0.85),
			randf_range(vp.y * 0.08, vp.y * 0.42)
		)
		gob.modulate = Color(1, 1, 1, 0.72)
		menu_layer.add_child(gob)
		goblin_sprites.append(gob)
		goblin_speeds.append(randf_range(26.0, 54.0))


func _update_goblins(delta: float) -> void:
	var vp := _vp()
	for i in range(goblin_sprites.size()):
		if not is_instance_valid(goblin_sprites[i]):
			continue
		goblin_sprites[i].position.y += goblin_speeds[i] * delta
		# Cycle walk frames
		if fmod(phase_timer * 6.0 + float(i), 3.0) < 0.15:
			goblin_sprites[i].frame = (goblin_sprites[i].frame + 1) % 3
		# Reset above screen when past the wall line
		if goblin_sprites[i].position.y > vp.y * 0.53:
			goblin_sprites[i].position.y = randf_range(-40.0, -10.0)
			goblin_sprites[i].position.x = randf_range(vp.x * 0.15, vp.x * 0.85)
			goblin_speeds[i] = randf_range(26.0, 54.0)


# ==========================================
# MENU PANELS
# ==========================================

func _build_main_panel(w: float, h: float) -> Control:
	var panel := _create_dark_panel(w, h)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(30.0, 30.0)
	vbox.size = Vector2(w - 60.0, h - 60.0)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	title_label = Label.new()
	title_label.text = "HORDEFALL"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.52, 1))
	title_label.add_theme_color_override("font_shadow_color", Color(0.22, 0.14, 0.06, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	title_label.add_theme_font_size_override("font_size", 42)
	vbox.add_child(title_label)

	var subtitle := Label.new()
	subtitle.text = "Defend the wall. Hold the line."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.34, 0.24, 0.14, 0.96))
	subtitle.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.18))
	subtitle.add_theme_constant_override("shadow_offset_x", 1)
	subtitle.add_theme_constant_override("shadow_offset_y", 1)
	subtitle.add_theme_font_size_override("font_size", 14)
	vbox.add_child(subtitle)

	var accent := ColorRect.new()
	accent.custom_minimum_size = Vector2(0, 3)
	accent.color = Color(0.78, 0.65, 0.35, 0.7)
	vbox.add_child(accent)

	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 18)
	vbox.add_child(spacer1)

	var start_btn := _create_menu_button("Play", 24)
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)

	var options_btn := _create_menu_button("Options", 20)
	options_btn.pressed.connect(_on_options_pressed)
	vbox.add_child(options_btn)

	var exit_btn := _create_menu_button("Exit", 20)
	exit_btn.pressed.connect(_on_exit_pressed)
	vbox.add_child(exit_btn)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer2)

	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.color = Color(0.72, 0.67, 0.56, 0.2)
	vbox.add_child(div)

	tap_label = Label.new()
	tap_label.text = "- Early Access -"
	tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_label.add_theme_color_override("font_color", Color(0.38, 0.28, 0.16, 0.96))
	tap_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.16))
	tap_label.add_theme_constant_override("shadow_offset_x", 1)
	tap_label.add_theme_constant_override("shadow_offset_y", 1)
	tap_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(tap_label)

	var version := Label.new()
	version.text = "v0.1"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_color_override("font_color", Color(0.34, 0.25, 0.16, 0.82))
	version.add_theme_font_size_override("font_size", 11)
	vbox.add_child(version)

	return panel


func _build_options_panel(w: float, h: float) -> Control:
	var panel := _create_dark_panel(w, h)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(30.0, 30.0)
	vbox.size = Vector2(w - 60.0, h - 60.0)
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Options"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1, 0.86, 0.52, 1))
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var accent := ColorRect.new()
	accent.custom_minimum_size = Vector2(0, 3)
	accent.color = Color(0.78, 0.65, 0.35, 0.7)
	vbox.add_child(accent)

	var music_row := HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 12)
	vbox.add_child(music_row)

	var mlabel := Label.new()
	mlabel.text = "Music"
	mlabel.custom_minimum_size = Vector2(100, 0)
	mlabel.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	mlabel.add_theme_font_size_override("font_size", 17)
	music_row.add_child(mlabel)

	music_slider = HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.value = 1.0
	music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	music_slider.value_changed.connect(_on_music_volume_changed)
	music_row.add_child(music_slider)

	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.color = Color(0.72, 0.67, 0.56, 0.2)
	vbox.add_child(div)

	var fs := CheckButton.new()
	fs.text = "Fullscreen"
	fs.custom_minimum_size = Vector2(0, 44)
	fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.add_theme_stylebox_override("normal", _make_ui_style(UI_BTN_NORMAL_TEX, 10.0, Color(0.34, 0.27, 0.18, 1.0)))
	fs.add_theme_stylebox_override("hover", _make_ui_style(UI_BTN_HOVER_TEX, 10.0, Color(0.44, 0.35, 0.23, 1.0)))
	fs.add_theme_stylebox_override("pressed", _make_ui_style(UI_BTN_PRESSED_TEX, 10.0, Color(0.25, 0.2, 0.14, 1.0)))
	fs.add_theme_stylebox_override("focus", _make_ui_style(UI_BTN_HOVER_TEX, 10.0, Color(0.44, 0.35, 0.23, 1.0)))
	fs.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	fs.add_theme_font_size_override("font_size", 17)
	fs.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(fs)

	var div2 := ColorRect.new()
	div2.custom_minimum_size = Vector2(0, 1)
	div2.color = Color(0.72, 0.67, 0.56, 0.2)
	vbox.add_child(div2)

	var back_btn := _create_menu_button("Back", 20)
	back_btn.pressed.connect(_on_back_pressed)
	vbox.add_child(back_btn)

	return panel


# ==========================================
# UI HELPERS
# ==========================================

func _make_ui_style(texture: Texture2D, content_margin: float = 12.0, tint: Color = Color(1, 1, 1, 1)) -> StyleBoxTexture:
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


func _create_dark_panel(w: float, h: float) -> Control:
	var root := Panel.new()
	root.size = Vector2(w, h)
	root.custom_minimum_size = Vector2(w, h)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_theme_stylebox_override("panel", _make_ui_style(UI_PANEL_TEX, 14.0, Color(0.82, 0.7, 0.44, 1.0)))

	# Subtle dark backing so text keeps contrast.
	var backdrop := ColorRect.new()
	backdrop.position = Vector2(6.0, 6.0)
	backdrop.size = Vector2(w - 12.0, h - 12.0)
	backdrop.color = Color(0.09, 0.07, 0.05, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	backdrop.z_index = -1

	return root


func _create_menu_button(label_text: String, font_size: int) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0, 50)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_stylebox_override("normal", _make_ui_style(UI_BTN_NORMAL_TEX, 10.0, Color(0.34, 0.27, 0.18, 1.0)))
	btn.add_theme_stylebox_override("hover", _make_ui_style(UI_BTN_HOVER_TEX, 10.0, Color(0.44, 0.35, 0.23, 1.0)))
	btn.add_theme_stylebox_override("pressed", _make_ui_style(UI_BTN_PRESSED_TEX, 10.0, Color(0.25, 0.2, 0.14, 1.0)))
	btn.add_theme_stylebox_override("focus", _make_ui_style(UI_BTN_HOVER_TEX, 10.0, Color(0.44, 0.35, 0.23, 1.0)))
	btn.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.86, 0.52, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.78, 0.65, 0.35, 1))
	btn.add_theme_font_size_override("font_size", font_size)
	return btn


# ==========================================
# CALLBACKS
# ==========================================

func _on_start_pressed() -> void:
	if black_overlay == null:
		get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
		return
	black_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(black_overlay, "color:a", 1.0, 0.6)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn"))


func _on_options_pressed() -> void:
	main_panel.visible = false
	options_panel.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	options_panel.visible = false
	main_panel.visible = true


func _on_music_volume_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(max(value, 0.0001)))


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
