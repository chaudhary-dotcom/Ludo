class_name ModeSelectUI
extends CanvasLayer

signal match_configured(player_count: int, selected_colors: Array[int], selected_sound_pack: int)

const COLOR_NAMES: Dictionary = {
	0: "Red",
	1: "Green",
	2: "Yellow",
	3: "Blue"
}

const COLOR_PALETTE: Dictionary = {
	0: Color(0.92, 0.24, 0.24),
	1: Color(0.2, 0.78, 0.32),
	2: Color(0.96, 0.78, 0.16),
	3: Color(0.22, 0.54, 0.94)
}

var current_count: int = 4
var chosen_colors: Array[int] = [0, 1, 2, 3]
var selected_sound_pack: int = 0 # 0 = DEFAULT, 1 = MEME_2026

var count_buttons: Array[Button] = []
var color_buttons: Dictionary = {}
var sound_pack_button: Button
var start_button: Button

func _ready() -> void:
	layer = 120

	# Backdrop
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.07, 0.14, 0.88)
	add_child(bg)

	# Centered Dialog Panel
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(520, 470)
	panel.size = Vector2(520, 470)
	panel.position = Vector2(316, 89)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.28, 0.98)
	style.set_corner_radius_all(16)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.85, 0.72, 0.2)
	style.shadow_size = 12
	style.shadow_color = Color(0, 0, 0, 0.6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# Title
	var title = Label.new()
	title.text = "SELECT PLAYERS & COLORS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 18)
	title.size = Vector2(520, 36)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.88, 0.4))
	panel.add_child(title)

	# 1. Player Count Label & Row (2P, 3P, 4P)
	var count_label = Label.new()
	count_label.text = "Number of Players:"
	count_label.position = Vector2(36, 62)
	count_label.size = Vector2(448, 24)
	count_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(count_label)

	var count_row = HBoxContainer.new()
	count_row.position = Vector2(36, 90)
	count_row.size = Vector2(448, 40)
	count_row.add_theme_constant_override("separation", 14)
	panel.add_child(count_row)

	for n in [2, 3, 4]:
		var btn = Button.new()
		btn.text = "%dP" % n
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): _on_count_selected(n))
		count_row.add_child(btn)
		count_buttons.append(btn)

	# 2. Player Colors Label & Grid
	var color_label = Label.new()
	color_label.text = "Selected Player Colors:"
	color_label.position = Vector2(36, 142)
	color_label.size = Vector2(448, 24)
	color_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(color_label)

	var color_grid = GridContainer.new()
	color_grid.columns = 2
	color_grid.position = Vector2(36, 170)
	color_grid.size = Vector2(448, 100)
	color_grid.add_theme_constant_override("h_separation", 16)
	color_grid.add_theme_constant_override("v_separation", 10)
	panel.add_child(color_grid)

	for cid in range(4):
		var cbtn = Button.new()
		cbtn.text = COLOR_NAMES[cid]
		cbtn.custom_minimum_size = Vector2(216, 40)
		cbtn.toggle_mode = true
		cbtn.pressed.connect(func(): _on_color_toggled(cid))
		color_grid.add_child(cbtn)
		color_buttons[cid] = cbtn

	# 3. Sound Mode Selection
	var sound_label = Label.new()
	sound_label.text = "Audio Sound Pack:"
	sound_label.position = Vector2(36, 282)
	sound_label.size = Vector2(448, 24)
	sound_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(sound_label)

	sound_pack_button = Button.new()
	sound_pack_button.position = Vector2(36, 310)
	sound_pack_button.size = Vector2(448, 38)
	sound_pack_button.pressed.connect(_on_sound_pack_toggled)
	panel.add_child(sound_pack_button)
	_update_sound_pack_button()

	# 4. Start Match Button
	start_button = Button.new()
	start_button.text = "START MATCH"
	start_button.position = Vector2(135, 385)
	start_button.size = Vector2(250, 48)
	start_button.add_theme_font_size_override("font_size", 18)
	start_button.pressed.connect(_on_start_pressed)
	panel.add_child(start_button)

	_on_count_selected(4)

func _on_sound_pack_toggled() -> void:
	selected_sound_pack = 1 if selected_sound_pack == 0 else 0
	_update_sound_pack_button()

func _update_sound_pack_button() -> void:
	if selected_sound_pack == 1:
		sound_pack_button.text = "SFX Mode: 2026 Memes 🔥"
		sound_pack_button.modulate = Color(1.3, 1.0, 0.4)
	else:
		sound_pack_button.text = "SFX Mode: Default 🔔"
		sound_pack_button.modulate = Color.WHITE

func _on_count_selected(count: int) -> void:
	current_count = count
	match count:
		2: chosen_colors = [0, 2] # Red and Yellow (opposite corners)
		3: chosen_colors = [0, 1, 2]
		4: chosen_colors = [0, 1, 2, 3]
	_refresh_ui_state()

func _on_color_toggled(color_id: int) -> void:
	if chosen_colors.has(color_id):
		if chosen_colors.size() > 1:
			chosen_colors.erase(color_id)
	else:
		if chosen_colors.size() < current_count:
			chosen_colors.append(color_id)
		else:
			chosen_colors.pop_front()
			chosen_colors.append(color_id)
	_refresh_ui_state()

func _refresh_ui_state() -> void:
	for i in range(count_buttons.size()):
		var n = i + 2
		var btn = count_buttons[i]
		btn.modulate = Color(1.3, 1.3, 1.0) if (n == current_count) else Color(0.7, 0.7, 0.7)

	for cid in color_buttons:
		var cbtn: Button = color_buttons[cid]
		var is_selected = chosen_colors.has(cid)
		cbtn.button_pressed = is_selected

		var base_col: Color = COLOR_PALETTE[cid]
		var sb = StyleBoxFlat.new()
		sb.bg_color = base_col if is_selected else base_col.darkened(0.6)
		sb.set_corner_radius_all(6)
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 3
		sb.border_color = Color.WHITE if is_selected else Color(0.35, 0.35, 0.35)
		cbtn.add_theme_stylebox_override("normal", sb)
		cbtn.add_theme_stylebox_override("pressed", sb)
		cbtn.add_theme_stylebox_override("hover", sb)

	start_button.disabled = (chosen_colors.size() != current_count)

func _on_start_pressed() -> void:
	match_configured.emit(current_count, chosen_colors, selected_sound_pack)
	queue_free()
