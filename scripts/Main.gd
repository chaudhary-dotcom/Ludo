extends Node2D

const CELL_SIZE: int = 40

@onready var game_manager: GameManager = $GameManager
@onready var dice_ui = $DiceUI

var board_renderer: BoardRenderer
var player_cards: Dictionary = {}
var token_visuals: Dictionary = {}
var board_offset: Vector2 = Vector2(276, 24)
var sound_toggle_btn: Button

func _ready() -> void:
	# 1. Attach Audio Engine Singleton
	if not has_node("AudioManager"):
		var audio_mgr = AudioManager.new()
		audio_mgr.name = "AudioManager"
		add_child(audio_mgr)

	# 2. Attach Board Renderer
	board_renderer = BoardRenderer.new()
	board_renderer.name = "BoardRenderer"
	board_renderer.board_offset = board_offset
	add_child(board_renderer)
	move_child(board_renderer, 0)

	# 3. Connect State Machine Signals
	game_manager.dice_rolled.connect(_on_dice_rolled)
	game_manager.token_moved.connect(_on_token_moved)
	game_manager.token_captured.connect(_on_token_captured)
	game_manager.turn_changed.connect(_on_turn_changed)
	game_manager.player_finished.connect(_on_player_finished)
	game_manager.game_fully_finished.connect(_on_game_fully_finished)
	game_manager.three_sixes_penalty.connect(_on_three_sixes_penalty)

	# 4. Hide Dice until mode and colors are chosen
	if dice_ui:
		dice_ui.top_level = true
		dice_ui.z_index = 100
		dice_ui.visible = false
		if not dice_ui.roll_requested.is_connected(_on_dice_clicked_single):
			dice_ui.roll_requested.connect(_on_dice_clicked_single)

	# 5. Open Player Mode Selection UI Modal
	var mode_select = ModeSelectUI.new()
	mode_select.name = "ModeSelectUI"
	mode_select.match_configured.connect(_start_match)
	add_child(mode_select)

	# 6. Top In-Game Audio Mode Switch Button
	sound_toggle_btn = Button.new()
	sound_toggle_btn.name = "SoundModeToggle"
	sound_toggle_btn.custom_minimum_size = Vector2(160, 32)
	sound_toggle_btn.position = Vector2(496, 10)
	sound_toggle_btn.z_index = 110

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.18, 0.28, 0.9)
	btn_style.set_corner_radius_all(8)
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.85, 0.72, 0.2)
	sound_toggle_btn.add_theme_stylebox_override("normal", btn_style)
	sound_toggle_btn.add_theme_stylebox_override("hover", btn_style)
	sound_toggle_btn.add_theme_stylebox_override("pressed", btn_style)

	_update_sound_button_label()

	sound_toggle_btn.pressed.connect(func():
		if AudioManager.instance:
			AudioManager.instance.toggle_sound_pack()
			_update_sound_button_label()
	)
	add_child(sound_toggle_btn)

func _on_dice_clicked_single() -> void:
	if AudioManager.instance:
		AudioManager.instance.play_dice_roll()
	game_manager.roll_dice()

func _update_sound_button_label() -> void:
	if not sound_toggle_btn:
		return
	if AudioManager.instance and AudioManager.instance.current_pack == AudioManager.SoundPack.MEME_2026:
		sound_toggle_btn.text = "SFX: 2026 Memes 🔥"
		sound_toggle_btn.modulate = Color(1.3, 1.0, 0.4)
	else:
		sound_toggle_btn.text = "SFX: Default 🔔"
		sound_toggle_btn.modulate = Color.WHITE

func _start_match(player_count: int, selected_colors: Array[int], selected_sound_pack: int = 0) -> void:
	# Clean up previous round's UI cards and tokens
	for c in player_cards.values():
		c.queue_free()
	player_cards.clear()
	for t in token_visuals.values():
		t.queue_free()
	token_visuals.clear()

	# Board layout positioning
	board_offset = Vector2(276, 24)
	board_renderer.board_offset = board_offset

	# Initialize GameManager
	game_manager._init_game(selected_colors)

	# Spawn UI and pawns
	_create_player_cards(selected_colors)
	_create_token_visuals()
	_refresh_all_token_positions()

	# Dock dice for the starting player but lock until intro completes
	if dice_ui:
		dice_ui.visible = true
		_route_dice_to_player(game_manager.get_current_player())
		dice_ui.set_roll_enabled(false)

	board_renderer.queue_redraw()

	# Configure sound pack, play intro, and unlock dice ONLY when finished
	if AudioManager.instance:
		AudioManager.instance.set_sound_pack(selected_sound_pack as AudioManager.SoundPack)
		_update_sound_button_label()
		AudioManager.instance.play_intro(func():
			if dice_ui:
				dice_ui.set_roll_enabled(true)
		)
	else:
		if dice_ui:
			dice_ui.set_roll_enabled(true)

func _create_player_cards(active_colors: Array[int]) -> void:
	var card_config = {
		0: { "pos": Vector2(24, 24), "name": "Red", "flag": "🔴", "dice_on_right": true },
		1: { "pos": Vector2(896, 24), "name": "Green", "flag": "🟢", "dice_on_right": false },
		3: { "pos": Vector2(24, 484), "name": "Blue", "flag": "🔵", "dice_on_right": true },
		2: { "pos": Vector2(896, 484), "name": "Yellow", "flag": "🟡", "dice_on_right": false }
	}

	for p_id in active_colors:
		if card_config.has(p_id):
			var cfg = card_config[p_id]
			var card = PlayerCardUI.new()
			card.setup(p_id, cfg["name"], cfg["flag"], BoardRenderer.get_player_color(p_id), cfg["pos"], cfg["dice_on_right"])
			add_child(card)
			player_cards[p_id] = card

func _route_dice_to_player(player_id: int) -> void:
	if not dice_ui or not player_cards.has(player_id):
		return
	var card: PlayerCardUI = player_cards[player_id]
	var target_pos: Vector2 = card.get_dice_dock_position()
	var p_color: Color = BoardRenderer.get_player_color(player_id)

	dice_ui.move_to_card_slot(target_pos, player_id, p_color)

	for p in player_cards:
		player_cards[p].set_active_turn(p == player_id)

func _create_token_visuals() -> void:
	for p_id in game_manager.active_players:
		if not game_manager.tokens.has(p_id):
			continue
		for token_data in game_manager.tokens[p_id]:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(30, 30)
			btn.text = ""

			var style = StyleBoxFlat.new()
			style.bg_color = BoardRenderer.get_player_color(p_id)
			style.set_corner_radius_all(15)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
			style.border_color = Color(1.0, 1.0, 1.0, 0.95)
			style.shadow_color = Color(0, 0, 0, 0.45)
			style.shadow_size = 4
			style.shadow_offset = Vector2(0, 2)

			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)

			# Inner gloss
			var inner_disc = Control.new()
			inner_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner_disc.draw.connect(func():
				var center = Vector2(15, 15)
				inner_disc.draw_circle(center, 9.0, Color(0, 0, 0, 0.18))
				inner_disc.draw_circle(center + Vector2(-1.5, -1.5), 5.5, Color(1, 1, 1, 0.65))
				inner_disc.draw_circle(center, 4.0, Color(1, 1, 1, 0.9))
			)
			btn.add_child(inner_disc)

			# Circular Progress Ring & Percentage
			var tracker_overlay = Control.new()
			tracker_overlay.name = "PerformanceTracker"
			tracker_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tracker_overlay.draw.connect(func():
				if token_data.step_count <= 0 or token_data.step_count >= 56:
					return
				var center = Vector2(15, 15)
				var radius = 13.5
				var progress_ratio: float = clampf(float(token_data.step_count) / 56.0, 0.0, 1.0)
				var pct: int = int(round(progress_ratio * 100.0))

				tracker_overlay.draw_arc(center, radius, -PI / 2.0, -PI / 2.0 + TAU, 24, Color(0, 0, 0, 0.35), 2.2, true)
				var arc_end = -PI / 2.0 + (TAU * progress_ratio)
				var ring_col = Color(0.2, 1.0, 0.5, 0.95) if progress_ratio >= 0.75 else Color(1.0, 0.9, 0.2, 0.95)
				tracker_overlay.draw_arc(center, radius, -PI / 2.0, arc_end, 24, ring_col, 2.5, true)

				var font = ThemeDB.fallback_font
				var text = "%d%%" % pct
				tracker_overlay.draw_string(font, center + Vector2(-9, 3), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color.WHITE)
			)
			btn.add_child(tracker_overlay)

			add_child(btn)
			token_visuals[token_data] = btn
			btn.pressed.connect(func(): _on_token_clicked(token_data))

func _get_all_tokens_at_grid(target_grid: Vector2i) -> Array[GameManager.TokenData]:
	var list: Array[GameManager.TokenData] = []
	for p_id in game_manager.active_players:
		if not game_manager.tokens.has(p_id): continue
		for t in game_manager.tokens[p_id]:
			if t.step_count >= 0:
				if BoardCoordinates.get_grid_pos(t.player_id, t.id, t.step_count) == target_grid:
					list.append(t)
	return list

func _refresh_all_token_positions() -> void:
	var cell_groups: Dictionary = {}
	for p in game_manager.active_players:
		if not game_manager.tokens.has(p): continue
		for t in game_manager.tokens[p]:
			if t.step_count < 0:
				var yard_grid = BoardCoordinates.get_grid_pos(t.player_id, t.id, t.step_count)
				if token_visuals.has(t):
					var btn: Button = token_visuals[t]
					btn.scale = Vector2.ONE
					btn.position = board_offset + Vector2(yard_grid * CELL_SIZE) + Vector2(5, 5)
			else:
				var g = BoardCoordinates.get_grid_pos(t.player_id, t.id, t.step_count)
				if not cell_groups.has(g):
					cell_groups[g] = []
				cell_groups[g].append(t)

	for grid_pos in cell_groups:
		var group: Array = cell_groups[grid_pos]
		var count: int = group.size()
		var base_top_left = board_offset + Vector2(grid_pos * CELL_SIZE)
		if count == 1:
			var btn: Button = token_visuals[group[0]]
			btn.scale = Vector2.ONE
			btn.position = base_top_left + Vector2(5, 5)
		elif count == 2:
			var offsets = [Vector2(2, 8), Vector2(20, 8)]
			for i in range(2):
				var btn: Button = token_visuals[group[i]]
				btn.scale = Vector2(0.72, 0.72)
				btn.position = base_top_left + offsets[i]
		else:
			var offsets = [Vector2(2, 2), Vector2(20, 2), Vector2(2, 20), Vector2(20, 20)]
			for i in range(mini(count, 4)):
				var btn: Button = token_visuals[group[i]]
				btn.scale = Vector2(0.65, 0.65)
				btn.position = base_top_left + offsets[i]

func _get_token_position_vector(token: GameManager.TokenData) -> Vector2:
	var grid_pos = BoardCoordinates.get_grid_pos(token.player_id, token.id, token.step_count)
	if token.step_count < 0:
		return board_offset + Vector2(grid_pos * CELL_SIZE) + Vector2(5, 5)

	var tokens_here = _get_all_tokens_at_grid(grid_pos)
	var idx = tokens_here.find(token)
	var base_top_left = board_offset + Vector2(grid_pos * CELL_SIZE)
	if tokens_here.size() <= 1 or idx == -1:
		return base_top_left + Vector2(5, 5)
	elif tokens_here.size() == 2:
		var offsets = [Vector2(2, 8), Vector2(20, 8)]
		return base_top_left + offsets[idx % 2]
	else:
		var offsets = [Vector2(2, 2), Vector2(20, 2), Vector2(2, 20), Vector2(20, 20)]
		return base_top_left + offsets[idx % 4]

func _on_token_clicked(token_data: GameManager.TokenData) -> void:
	if not game_manager.waiting_for_move or game_manager.is_moving:
		return
	var valids = game_manager.get_valid_tokens_for_current_turn()
	if valids.has(token_data):
		_clear_token_highlights()
		game_manager.move_token(token_data)
		return
	var clicked_grid = BoardCoordinates.get_grid_pos(token_data.player_id, token_data.id, token_data.step_count)
	for valid_token in valids:
		if BoardCoordinates.get_grid_pos(valid_token.player_id, valid_token.id, valid_token.step_count) == clicked_grid:
			_clear_token_highlights()
			game_manager.move_token(valid_token)
			return

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if dice_ui and dice_ui.roll_enabled and not dice_ui.is_rolling:
			dice_ui._on_dice_pressed()

func _on_dice_rolled(_player_id: int, value: int) -> void:
	if dice_ui:
		dice_ui.show_dice_result(value)

	# Bonus fanfare audio cue only on actual 6
	if value == 6 and AudioManager.instance:
		AudioManager.instance.play_dice_six()

	_highlight_valid_tokens()

func _highlight_valid_tokens() -> void:
	_clear_token_highlights()
	for token in game_manager.get_valid_tokens_for_current_turn():
		var btn: Button = token_visuals[token]
		btn.z_index = 10
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.pivot_offset = btn.size * 0.5
		var tween = create_tween().set_loops()
		tween.tween_property(btn, "scale", Vector2(1.22, 1.22), 0.25).set_trans(Tween.TRANS_SINE)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_SINE)
		btn.set_meta("pulse_tween", tween)

func _clear_token_highlights() -> void:
	for btn in token_visuals.values():
		btn.z_index = 0
		if btn.has_meta("pulse_tween"):
			var tween: Tween = btn.get_meta("pulse_tween")
			if tween and tween.is_valid():
				tween.kill()
			btn.remove_meta("pulse_tween")
		btn.scale = Vector2.ONE

func _on_token_moved(token: GameManager.TokenData, from_step: int, to_step: int) -> void:
	_clear_token_highlights()
	var btn: Button = token_visuals[token]
	btn.z_index = 15
	btn.scale = Vector2.ONE

	var update_trackers = func():
		var tracker = btn.get_node_or_null("PerformanceTracker")
		if tracker:
			tracker.queue_redraw()
		_update_player_performance_bars()

	# Leaving Yard / Coming out from home
	if from_step == -1:
		var dest = _get_token_position_vector(token)
		var t_spawn = create_tween()
		t_spawn.tween_property(btn, "position", dest, 0.2)
		t_spawn.finished.connect(func():
			btn.z_index = 0
			_refresh_all_token_positions()
			update_trackers.call()

			if AudioManager.instance:
				AudioManager.instance.play_token_spawn()

			game_manager.on_token_animation_finished(token)
		)
		return

	if from_step >= to_step:
		btn.z_index = 0
		_refresh_all_token_positions()
		update_trackers.call()
		game_manager.on_token_animation_finished(token)
		return

	# Step movement with steady pace (0.16s per tile)
	var t_move = create_tween()
	for step in range(from_step + 1, to_step + 1):
		var grid_pos = BoardCoordinates.get_grid_pos(token.player_id, token.id, step)
		var px = board_offset + Vector2(grid_pos * CELL_SIZE) + Vector2(5, 5)
		t_move.tween_callback(func():
			if AudioManager.instance:
				AudioManager.instance.play_token_step()
		)
		t_move.tween_property(btn, "position", px, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	t_move.finished.connect(func():
		btn.z_index = 0
		_refresh_all_token_positions()
		update_trackers.call()

		if token.step_count == 56:
			if AudioManager.instance:
				AudioManager.instance.play_token_finished()
		else:
			var global_tile = GameRules.get_global_tile_index(token.player_id, token.step_count)
			if GameRules.is_safe_tile(global_tile) and AudioManager.instance:
				AudioManager.instance.play_safe_place()

		game_manager.on_token_animation_finished(token)
	)

func _on_token_captured(token: GameManager.TokenData) -> void:
	if AudioManager.instance:
		AudioManager.instance.play_token_capture()

	var btn: Button = token_visuals[token]
	var dest = _get_token_position_vector(token)
	var tween = create_tween()
	tween.tween_property(btn, "position", dest, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		_refresh_all_token_positions()
		var tracker = btn.get_node_or_null("PerformanceTracker")
		if tracker:
			tracker.queue_redraw()
		_update_player_performance_bars()
	)

func _on_turn_changed(new_player_id: int) -> void:
	_clear_token_highlights()
	_route_dice_to_player(new_player_id)
	if dice_ui:
		dice_ui.set_roll_enabled(true)

func _on_player_finished(player_id: int, rank: int) -> void:
	if board_renderer:
		board_renderer.set_rank_badge(player_id, rank)
	if AudioManager.instance:
		AudioManager.instance.play_player_win_fanfare()

func _on_three_sixes_penalty(_player_id: int, _penalized_token: GameManager.TokenData) -> void:
	pass

func _on_game_fully_finished(_final_rankings: Array[int]) -> void:
	_clear_token_highlights()
	if dice_ui:
		dice_ui.set_roll_enabled(false)
	if AudioManager.instance:
		AudioManager.instance.play_game_over()

func _update_player_performance_bars() -> void:
	for p_id in player_cards:
		var card: PlayerCardUI = player_cards[p_id]
		if game_manager.tokens.has(p_id):
			var total_steps: int = 0
			for t in game_manager.tokens[p_id]:
				if t.step_count > 0:
					total_steps += t.step_count
			card.update_progress(total_steps)
