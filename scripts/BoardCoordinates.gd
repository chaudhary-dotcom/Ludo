class_name BoardCoordinates
extends RefCounted

const COMMON_TRACK: Array[Vector2i] = [
	Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6),
	Vector2i(6, 5), Vector2i(6, 4), Vector2i(6, 3), Vector2i(6, 2), Vector2i(6, 1), Vector2i(6, 0),
	Vector2i(7, 0), Vector2i(8, 0),
	Vector2i(8, 1), Vector2i(8, 2), Vector2i(8, 3), Vector2i(8, 4), Vector2i(8, 5),
	Vector2i(9, 6), Vector2i(10, 6), Vector2i(11, 6), Vector2i(12, 6), Vector2i(13, 6), Vector2i(14, 6),
	Vector2i(14, 7), Vector2i(14, 8),
	Vector2i(13, 8), Vector2i(12, 8), Vector2i(11, 8), Vector2i(10, 8), Vector2i(9, 8),
	Vector2i(8, 9), Vector2i(8, 10), Vector2i(8, 11), Vector2i(8, 12), Vector2i(8, 13), Vector2i(8, 14),
	Vector2i(7, 14), Vector2i(6, 14),
	Vector2i(6, 13), Vector2i(6, 12), Vector2i(6, 11), Vector2i(6, 10), Vector2i(6, 9),
	Vector2i(5, 8), Vector2i(4, 8), Vector2i(3, 8), Vector2i(2, 8), Vector2i(1, 8), Vector2i(0, 8),
	Vector2i(0, 7), Vector2i(0, 6)
]

# 0=RED, 1=GREEN, 2=YELLOW, 3=BLUE
const HOME_PATHS: Dictionary = {
	0: [Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7)],
	1: [Vector2i(7, 1), Vector2i(7, 2), Vector2i(7, 3), Vector2i(7, 4), Vector2i(7, 5)],
	2: [Vector2i(13, 7), Vector2i(12, 7), Vector2i(11, 7), Vector2i(10, 7), Vector2i(9, 7)],
	3: [Vector2i(7, 13), Vector2i(7, 12), Vector2i(7, 11), Vector2i(7, 10), Vector2i(7, 9)]
}

const YARD_SLOTS: Dictionary = {
	0: [Vector2i(2, 2), Vector2i(3, 2), Vector2i(2, 3), Vector2i(3, 3)],
	1: [Vector2i(11, 2), Vector2i(12, 2), Vector2i(11, 3), Vector2i(12, 3)],
	2: [Vector2i(11, 11), Vector2i(12, 11), Vector2i(11, 12), Vector2i(12, 12)],
	3: [Vector2i(2, 11), Vector2i(3, 11), Vector2i(2, 12), Vector2i(3, 12)]
}

const CENTER_FINISH: Dictionary = {
	0: Vector2i(6, 7),
	1: Vector2i(7, 6),
	2: Vector2i(8, 7),
	3: Vector2i(7, 8)
}

static func get_grid_pos(player_id: int, token_id: int, step_count: int) -> Vector2i:
	if step_count < 0:
		if YARD_SLOTS.has(player_id) and token_id >= 0 and token_id < YARD_SLOTS[player_id].size():
			return YARD_SLOTS[player_id][token_id]
		return Vector2i.ZERO
	elif step_count <= 50:
		var offset: int = GameRules.START_OFFSETS.get(player_id, 0)
		var global_idx: int = (offset + step_count) % COMMON_TRACK.size()
		return COMMON_TRACK[global_idx]
	elif step_count >= 51 and step_count <= 55:
		var home_idx: int = clampi(step_count - 51, 0, HOME_PATHS[player_id].size() - 1)
		return HOME_PATHS[player_id][home_idx]
	else:
		if CENTER_FINISH.has(player_id):
			return CENTER_FINISH[player_id]
		return Vector2i(7, 7)
