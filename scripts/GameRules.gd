class_name GameRules
extends RefCounted

const WINNING_STEP: int = 56
const SAFE_CELLS: Array[int] = [0, 8, 13, 21, 26, 34, 39, 47]

# Plain integers: 0=RED, 1=GREEN, 2=YELLOW, 3=BLUE
const START_OFFSETS: Dictionary = {
	0: 0,
	1: 13,
	2: 26,
	3: 39
}

static func get_global_tile_index(player_id: int, step_count: int) -> int:
	if step_count < 0 or step_count > 50:
		return -1
	var offset: int = START_OFFSETS.get(player_id, 0)
	return (offset + step_count) % 52

static func is_safe_tile(global_pos: int) -> bool:
	return SAFE_CELLS.has(global_pos)

static func is_token_valid_for_roll(token: GameManager.TokenData, roll: int) -> bool:
	if token.state == GameManager.TokenState.IN_YARD:
		return roll == 6
	elif token.state in [GameManager.TokenState.ON_TRACK, GameManager.TokenState.HOME_RUN]:
		return (token.step_count + roll) <= WINNING_STEP
	return false

static func calculate_destination(token: GameManager.TokenData, roll: int) -> Dictionary:
	var from_step: int = token.step_count
	var to_step: int = from_step
	var new_state: GameManager.TokenState = token.state
	
	if token.state == GameManager.TokenState.IN_YARD:
		if roll == 6:
			to_step = 0
			new_state = GameManager.TokenState.ON_TRACK
	else:
		to_step = mini(from_step + roll, WINNING_STEP)
		if to_step > 50 and to_step < WINNING_STEP:
			new_state = GameManager.TokenState.HOME_RUN
		elif to_step == WINNING_STEP:
			new_state = GameManager.TokenState.FINISHED
			
	return {
		"from_step": from_step,
		"to_step": to_step,
		"new_state": new_state
	}

static func should_grant_bonus_turn(dice_roll: int, did_capture: bool, did_finish_token: bool) -> bool:
	return dice_roll == 6 or did_capture or did_finish_token

static func check_three_sixes(consecutive_sixes: int) -> bool:
	return consecutive_sixes >= 3
