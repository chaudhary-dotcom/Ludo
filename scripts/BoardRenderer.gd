class_name BoardRenderer
extends Node2D

const CELL_SIZE: int = 40
const BOARD_SIZE: int = 15

var board_offset: Vector2 = Vector2(276, 24)
var rank_badges: Dictionary = {}

func _ready() -> void:
	z_index = 0
	show()
	queue_redraw()

func set_rank_badge(player_id: int, rank: int) -> void:
	rank_badges[player_id] = rank
	queue_redraw()

func clear_rank_badges() -> void:
	rank_badges.clear()
	queue_redraw()

static func get_player_color(p_id: int) -> Color:
	match p_id:
		0: return Color(0.92, 0.24, 0.24) # RED
		1: return Color(0.2, 0.78, 0.32)  # GREEN
		2: return Color(0.96, 0.78, 0.16) # YELLOW
		3: return Color(0.22, 0.54, 0.94) # BLUE
		4: return Color(1.0, 0.5, 0.14)   # ORANGE
		5: return Color(0.68, 0.3, 0.92)  # PURPLE
	return Color.WHITE

func _draw() -> void:
	# Canvas Background
	draw_rect(Rect2(0, 0, 1152, 648), Color(0.08, 0.12, 0.22))
	
	var b_origin = board_offset
	draw_rect(Rect2(b_origin, Vector2(BOARD_SIZE * CELL_SIZE, BOARD_SIZE * CELL_SIZE)), Color(0.94, 0.94, 0.96))
	
	# Four Corner Yards
	draw_rect(Rect2(b_origin, Vector2(6 * CELL_SIZE, 6 * CELL_SIZE)), get_player_color(0)) # Red
	draw_rect(Rect2(b_origin + Vector2(9 * CELL_SIZE, 0), Vector2(6 * CELL_SIZE, 6 * CELL_SIZE)), get_player_color(1)) # Green
	draw_rect(Rect2(b_origin + Vector2(9 * CELL_SIZE, 9 * CELL_SIZE), Vector2(6 * CELL_SIZE, 6 * CELL_SIZE)), get_player_color(2)) # Yellow
	draw_rect(Rect2(b_origin + Vector2(0, 9 * CELL_SIZE), Vector2(6 * CELL_SIZE, 6 * CELL_SIZE)), get_player_color(3)) # Blue
	
	# Yard inner white rectangles
	draw_rect(Rect2(b_origin + Vector2(CELL_SIZE, CELL_SIZE), Vector2(4 * CELL_SIZE, 4 * CELL_SIZE)), Color.WHITE)
	draw_rect(Rect2(b_origin + Vector2(10 * CELL_SIZE, CELL_SIZE), Vector2(4 * CELL_SIZE, 4 * CELL_SIZE)), Color.WHITE)
	draw_rect(Rect2(b_origin + Vector2(10 * CELL_SIZE, 10 * CELL_SIZE), Vector2(4 * CELL_SIZE, 4 * CELL_SIZE)), Color.WHITE)
	draw_rect(Rect2(b_origin + Vector2(CELL_SIZE, 10 * CELL_SIZE), Vector2(4 * CELL_SIZE, 4 * CELL_SIZE)), Color.WHITE)

	# Home Yard Token Slots
	for p_id in BoardCoordinates.YARD_SLOTS:
		var slot_color: Color = get_player_color(p_id)
		for slot_cell in BoardCoordinates.YARD_SLOTS[p_id]:
			var center_px = b_origin + Vector2((slot_cell.x + 0.5) * CELL_SIZE, (slot_cell.y + 0.5) * CELL_SIZE)
			draw_circle(center_px, CELL_SIZE * 0.44, slot_color)
			draw_circle(center_px, CELL_SIZE * 0.30, Color(1, 1, 1, 0.45))

	# Common Outer Track
	for cell in BoardCoordinates.COMMON_TRACK:
		var rect = Rect2(b_origin.x + cell.x * CELL_SIZE, b_origin.y + cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		draw_rect(rect, Color.WHITE)
		draw_rect(rect, Color(0.35, 0.35, 0.35), false, 1.0)
	
	# Color Home Paths
	for p_id in BoardCoordinates.HOME_PATHS:
		var col: Color = get_player_color(p_id)
		for cell in BoardCoordinates.HOME_PATHS[p_id]:
			var rect = Rect2(b_origin.x + cell.x * CELL_SIZE, b_origin.y + cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			draw_rect(rect, col)
			draw_rect(rect, Color(0.35, 0.35, 0.35), false, 1.0)

	# Starting Tiles
	for p_id in GameRules.START_OFFSETS:
		var start_idx: int = GameRules.START_OFFSETS[p_id]
		var cell: Vector2i = BoardCoordinates.COMMON_TRACK[start_idx]
		var rect = Rect2(b_origin.x + cell.x * CELL_SIZE, b_origin.y + cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		draw_rect(rect, get_player_color(p_id))
		draw_rect(rect, Color(0.35, 0.35, 0.35), false, 1.0)

	# Star Safe Places
	for safe_idx in GameRules.SAFE_CELLS:
		var cell: Vector2i = BoardCoordinates.COMMON_TRACK[safe_idx]
		var star_center = b_origin + Vector2((cell.x + 0.5) * CELL_SIZE, (cell.y + 0.5) * CELL_SIZE)
		var is_start_tile: bool = (safe_idx in GameRules.START_OFFSETS.values())
		var star_color: Color = Color.WHITE if is_start_tile else Color(0.3, 0.3, 0.3, 0.8)
		_draw_star(star_center, 11.5, 5.2, star_color)

	# Center Goal Triangles
	var c_tl = b_origin + Vector2(6 * CELL_SIZE, 6 * CELL_SIZE)
	var c_tr = b_origin + Vector2(9 * CELL_SIZE, 6 * CELL_SIZE)
	var c_br = b_origin + Vector2(9 * CELL_SIZE, 9 * CELL_SIZE)
	var c_bl = b_origin + Vector2(6 * CELL_SIZE, 9 * CELL_SIZE)
	var board_mid = b_origin + Vector2(7.5 * CELL_SIZE, 7.5 * CELL_SIZE)
	
	draw_colored_polygon(PackedVector2Array([c_tl, c_bl, board_mid]), get_player_color(0)) # Red
	draw_colored_polygon(PackedVector2Array([c_tl, c_tr, board_mid]), get_player_color(1)) # Green
	draw_colored_polygon(PackedVector2Array([c_tr, c_br, board_mid]), get_player_color(2)) # Yellow
	draw_colored_polygon(PackedVector2Array([c_bl, c_br, board_mid]), get_player_color(3)) # Blue

	draw_line(c_tl, c_br, Color(0.35, 0.35, 0.35), 1.5)
	draw_line(c_tr, c_bl, Color(0.35, 0.35, 0.35), 1.5)

	# Winner Rank Badges
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 28
	var triangle_text_positions: Dictionary = {
		0: b_origin + Vector2(6.8 * CELL_SIZE, 7.7 * CELL_SIZE),
		1: b_origin + Vector2(7.5 * CELL_SIZE, 7.0 * CELL_SIZE),
		2: b_origin + Vector2(8.2 * CELL_SIZE, 7.7 * CELL_SIZE),
		3: b_origin + Vector2(7.5 * CELL_SIZE, 8.4 * CELL_SIZE)
	}

	for p_id in rank_badges:
		var rank_num: int = rank_badges[p_id]
		var text: String = str(rank_num)
		var center_pos: Vector2 = triangle_text_positions[p_id]
		draw_circle(center_pos + Vector2(0, -font_size * 0.32), 15.0, Color(0, 0, 0, 0.5))
		draw_circle(center_pos + Vector2(0, -font_size * 0.32), 13.0, Color.WHITE)
		draw_string(font, center_pos + Vector2(-font_size * 0.22, 0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.1, 0.12, 0.18))

func _draw_star(center_pt: Vector2, outer_radius: float, inner_radius: float, color: Color) -> void:
	var points = PackedVector2Array()
	var angle: float = -PI / 2.0
	var step: float = PI / 5.0
	for i in range(10):
		var r = outer_radius if (i % 2 == 0) else inner_radius
		points.append(center_pt + Vector2(cos(angle), sin(angle)) * r)
		angle += step
	draw_colored_polygon(points, color)
