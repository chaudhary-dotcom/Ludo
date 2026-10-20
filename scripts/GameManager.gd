class_name GameManager
extends Node

enum PlayerColor { RED = 0, GREEN = 1, YELLOW = 2, BLUE = 3, ORANGE = 4, PURPLE = 5 }
enum TokenState { IN_YARD, ON_TRACK, HOME_RUN, FINISHED }

class TokenData:
	var id: int
	var player_id: int
	var state: TokenState = TokenState.IN_YARD
	var step_count: int = -1
	
	func _init(p_id: int, t_id: int):
		player_id = p_id
		id = t_id
		step_count = -1
		state = TokenState.IN_YARD

signal dice_rolled(player_id: int, value: int)
signal token_moved(token: TokenData, from_step: int, to_step: int)
signal token_captured(captured_token: TokenData)
signal turn_changed(new_player_id: int)
signal player_finished(player_id: int, rank: int)
signal game_fully_finished(rankings: Array[int])
signal three_sixes_penalty(player_id: int, penalized_token: TokenData)

var active_players: Array[int] = [
	PlayerColor.RED, PlayerColor.GREEN, PlayerColor.YELLOW, PlayerColor.BLUE
]

var rankings: Array[int] = []
var current_turn_idx: int = 0
var current_dice_roll: int = 0
var consecutive_sixes: int = 0
var waiting_for_move: bool = false
var is_moving: bool = false
var is_rolling: bool = false
var tokens: Dictionary = {}

var _auto_move_token: TokenData = null

func _ready() -> void:
	pass

func _init_game(custom_players: Array[int] = []) -> void:
	tokens.clear()
	rankings.clear()
	_auto_move_token = null
	
	if not custom_players.is_empty():
		active_players = custom_players.duplicate()
	else:
		active_players = [PlayerColor.RED, PlayerColor.GREEN, PlayerColor.YELLOW, PlayerColor.BLUE]
	
	for p_id in active_players:
		tokens[p_id] = []
		for t_id in range(4):
			tokens[p_id].append(TokenData.new(p_id, t_id))
		
	current_turn_idx = 0
	current_dice_roll = 0
	consecutive_sixes = 0
	waiting_for_move = false
	is_moving = false
	is_rolling = false

func get_current_player() -> int:
	if active_players.is_empty():
		return -1
	return active_players[current_turn_idx]

func get_tokens_at_tile(player_id: int, global_pos: int) -> Array[TokenData]:
	var list: Array[TokenData] = []
	if global_pos == -1 or not tokens.has(player_id):
		return list
	for t in tokens[player_id]:
		if t.state == TokenState.ON_TRACK and GameRules.get_global_tile_index(t.player_id, t.step_count) == global_pos:
			list.append(t)
	return list

func roll_dice() -> void:
	if waiting_for_move or is_moving or is_rolling or active_players.size() <= 1:
		return

	is_rolling = true
	_auto_move_token = null
	current_dice_roll = randi_range(1, 6)
	var current_player: int = get_current_player()
	emit_signal("dice_rolled", current_player, current_dice_roll)
	
	if current_dice_roll == 6:
		consecutive_sixes += 1
	else:
		consecutive_sixes = 0

	if GameRules.check_three_sixes(consecutive_sixes):
		consecutive_sixes = 0
		get_tree().create_timer(0.6).timeout.connect(func():
			_apply_three_sixes_penalty(current_player)
		)
		return
	
	var valid_tokens = get_valid_tokens_for_current_turn()
	if valid_tokens.is_empty():
		get_tree().create_timer(0.6).timeout.connect(func():
			is_rolling = false
			_next_turn()
		)
		return

	is_rolling = false
	waiting_for_move = true

	# Auto-move with explicit reference check so it can't double-trigger
	if valid_tokens.size() == 1:
		var single_token = valid_tokens[0]
		_auto_move_token = single_token
		get_tree().create_timer(0.4).timeout.connect(func():
			if waiting_for_move and not is_moving and _auto_move_token == single_token:
				move_token(single_token)
		)

func _apply_three_sixes_penalty(player_id: int) -> void:
	var furthest_token: TokenData = null
	var max_step: int = -1
	for token in tokens[player_id]:
		if token.state in [TokenState.ON_TRACK, TokenState.HOME_RUN]:
			if token.step_count > max_step:
				max_step = token.step_count
				furthest_token = token
				
	if furthest_token != null:
		furthest_token.step_count = -1
		furthest_token.state = TokenState.IN_YARD
		emit_signal("token_captured", furthest_token)
		emit_signal("three_sixes_penalty", player_id, furthest_token)
		
	is_rolling = false
	waiting_for_move = false
	_next_turn()

func get_valid_tokens_for_current_turn() -> Array[TokenData]:
	var current_player: int = get_current_player()
	var valid: Array[TokenData] = []
	if not tokens.has(current_player):
		return valid
	for token in tokens[current_player]:
		if GameRules.is_token_valid_for_roll(token, current_dice_roll):
			valid.append(token)
	return valid

func move_token(token: TokenData) -> void:
	if not waiting_for_move or is_moving or token.player_id != get_current_player():
		return
		
	var valid_tokens = get_valid_tokens_for_current_turn()
	if not valid_tokens.has(token):
		return
		
	# Consume the move
	_auto_move_token = null
	waiting_for_move = false
	is_moving = true
	
	var result = GameRules.calculate_destination(token, current_dice_roll)
	token.step_count = result["to_step"]
	token.state = result["new_state"]
	emit_signal("token_moved", token, result["from_step"], result["to_step"])

func on_token_animation_finished(token: TokenData) -> void:
	var captured: bool = _check_capture(token)
	var finished_now: bool = (token.state == TokenState.FINISHED)
	is_moving = false
	
	if _has_player_finished(token.player_id):
		rankings.append(token.player_id)
		emit_signal("player_finished", token.player_id, rankings.size())
		
		var finished_idx = active_players.find(token.player_id)
		if finished_idx != -1:
			active_players.remove_at(finished_idx)
			
		if active_players.size() == 1:
			rankings.append(active_players[0])
			emit_signal("player_finished", active_players[0], rankings.size())
			active_players.clear()
			emit_signal("game_fully_finished", rankings)
			return
		else:
			if current_turn_idx >= active_players.size():
				current_turn_idx = 0
			consecutive_sixes = 0
			emit_signal("turn_changed", get_current_player())
			return

	if GameRules.should_grant_bonus_turn(current_dice_roll, captured, finished_now):
		waiting_for_move = false
		emit_signal("turn_changed", get_current_player())
	else:
		_next_turn()

func _check_capture(attacker: TokenData) -> bool:
	var global_pos: int = GameRules.get_global_tile_index(attacker.player_id, attacker.step_count)
	# Never capture on safe tiles or in home path
	if global_pos == -1 or GameRules.is_safe_tile(global_pos):
		return false
		
	var did_capture: bool = false
	var attacker_count: int = get_tokens_at_tile(attacker.player_id, global_pos).size()
	
	for p_id in active_players:
		if p_id == attacker.player_id:
			continue
		var opp_tokens: Array[TokenData] = get_tokens_at_tile(p_id, global_pos)
		if opp_tokens.is_empty():
			continue
		
		# Standard capture rule: single opponent is killed, or block beaten by block
		if opp_tokens.size() == 1 or (opp_tokens.size() >= 2 and attacker_count >= 2):
			for opp_token in opp_tokens:
				opp_token.step_count = -1
				opp_token.state = TokenState.IN_YARD
				did_capture = true
				emit_signal("token_captured", opp_token)
			
	return did_capture

func _has_player_finished(player_id: int) -> bool:
	if not tokens.has(player_id):
		return false
	for token in tokens[player_id]:
		if token.state != TokenState.FINISHED:
			return false
	return true

func _next_turn() -> void:
	_auto_move_token = null
	waiting_for_move = false
	is_moving = false
	is_rolling = false
	consecutive_sixes = 0
	if active_players.is_empty():
		return
	current_turn_idx = (current_turn_idx + 1) % active_players.size()
	emit_signal("turn_changed", get_current_player())
