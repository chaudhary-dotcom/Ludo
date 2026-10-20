class_name PlayerCardUI
extends Panel

var player_id: int
var player_color: Color
var dice_pocket_panel: Panel
var progress_bar: ProgressBar
var percent_label: Label
var rank_label: Label

func setup(p_id: int, p_name: String, p_flag: String, p_color: Color, screen_pos: Vector2, dice_on_right: bool) -> void:
	player_id = p_id
	player_color = p_color
	position = screen_pos
	custom_minimum_size = Vector2(232, 140)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.16, 0.32, 0.95)
	style.set_corner_radius_all(14)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.85, 0.72, 0.2)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 6
	add_theme_stylebox_override("panel", style)
	
	# Avatar
	var avatar_panel = Panel.new()
	avatar_panel.size = Vector2(84, 84)
	avatar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var av_style = StyleBoxFlat.new()
	av_style.bg_color = Color(0.88, 0.9, 0.95)
	av_style.set_corner_radius_all(10)
	av_style.border_width_left = 2
	av_style.border_width_top = 2
	av_style.border_width_right = 2
	av_style.border_width_bottom = 2
	av_style.border_color = p_color
	avatar_panel.add_theme_stylebox_override("panel", av_style)
	
	var av_lbl = Label.new()
	av_lbl.text = p_flag
	av_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av_lbl.size = avatar_panel.size
	av_lbl.add_theme_font_size_override("font_size", 34)
	av_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_panel.add_child(av_lbl)
	
	# Dice Pocket
	dice_pocket_panel = Panel.new()
	dice_pocket_panel.size = Vector2(84, 84)
	dice_pocket_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = Color(0.92, 0.88, 0.9, 0.35)
	slot_style.set_corner_radius_all(10)
	slot_style.border_width_left = 2
	slot_style.border_width_top = 2
	slot_style.border_width_right = 2
	slot_style.border_width_bottom = 2
	slot_style.border_color = Color(0.8, 0.75, 0.3, 0.7)
	dice_pocket_panel.add_theme_stylebox_override("panel", slot_style)
	
	if dice_on_right:
		avatar_panel.position = Vector2(16, 16)
		dice_pocket_panel.position = Vector2(132, 16)
	else:
		dice_pocket_panel.position = Vector2(16, 16)
		avatar_panel.position = Vector2(132, 16)
		
	add_child(avatar_panel)
	add_child(dice_pocket_panel)
	
	# Team Progress Bar (full width at bottom)
	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(16, 108)
	progress_bar.size = Vector2(200, 18)
	progress_bar.max_value = 224 # 56 steps * 4 tokens
	progress_bar.value = 0
	progress_bar.show_percentage = false
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.06, 0.08, 0.16, 0.85)
	pb_bg.set_corner_radius_all(6)
	progress_bar.add_theme_stylebox_override("background", pb_bg)
	
	var pb_fill = StyleBoxFlat.new()
	pb_fill.bg_color = p_color
	pb_fill.set_corner_radius_all(6)
	progress_bar.add_theme_stylebox_override("fill", pb_fill)
	add_child(progress_bar)
	
	# Centered Percentage Label
	percent_label = Label.new()
	percent_label.position = progress_bar.position
	percent_label.size = progress_bar.size
	percent_label.text = "0%"
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	percent_label.add_theme_font_size_override("font_size", 14)
	percent_label.add_theme_color_override("font_color", Color.WHITE)
	percent_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	percent_label.add_theme_constant_override("shadow_offset_x", 1)
	percent_label.add_theme_constant_override("shadow_offset_y", 1)
	percent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(percent_label)

func get_dice_dock_position() -> Vector2:
	return position + dice_pocket_panel.position + Vector2(2, 2)

func set_active_turn(is_active: bool) -> void:
	var style: StyleBoxFlat = get_theme_stylebox("panel")
	if is_active:
		style.border_color = Color.WHITE
		style.border_width_left = 4
		style.border_width_top = 4
		style.border_width_right = 4
		style.border_width_bottom = 4
	else:
		style.border_color = Color(0.85, 0.72, 0.2)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3

func update_progress(total_steps: int) -> void:
	if progress_bar:
		progress_bar.value = total_steps
	if percent_label:
		var pct: int = int(round((float(total_steps) / 224.0) * 100.0))
		percent_label.text = "%d%%" % pct
