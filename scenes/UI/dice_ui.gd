extends Control

signal roll_requested

var current_value: int = 1
var target_value: int = 1
var is_rolling: bool = false
var roll_enabled: bool = true
var current_player_id: int = 0
var current_color: Color = Color(0.92, 0.24, 0.24)

var dice_btn: Button

func _ready() -> void:
	custom_minimum_size = Vector2(80, 80)
	size = Vector2(80, 80)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	dice_btn = Button.new()
	dice_btn.custom_minimum_size = Vector2(80, 80)
	dice_btn.size = Vector2(80, 80)
	dice_btn.flat = true
	dice_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	dice_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	dice_btn.draw.connect(_draw_dice)
	dice_btn.pressed.connect(_on_dice_pressed)
	add_child(dice_btn)

func _on_dice_pressed() -> void:
	if not roll_enabled or is_rolling:
		return

	is_rolling = true
	set_roll_enabled(false)

	# 1. Visual tumble animation
	var roll_tween: Tween = create_tween().set_parallel(false)
	for i in range(6):
		roll_tween.tween_callback(func():
			current_value = randi_range(1, 6)
			dice_btn.rotation = deg_to_rad(randf_range(-12.0, 12.0))
			dice_btn.position = Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
			dice_btn.queue_redraw()
		)
		roll_tween.tween_interval(0.04)
		
	# 2. When tumble finishes, snap to the actual target_value from GameManager
	roll_tween.tween_callback(func():
		dice_btn.rotation = 0.0
		dice_btn.position = Vector2.ZERO
		current_value = target_value
		is_rolling = false
		dice_btn.queue_redraw()
	)

	# 3. Request roll from GameManager (which will call show_dice_result)
	roll_requested.emit()

func show_dice_result(value: int) -> void:
	target_value = value
	# If we are not currently playing a tumble animation, update immediately
	if not is_rolling:
		current_value = value
		if dice_btn:
			dice_btn.queue_redraw()

func move_to_card_slot(target_global_pos: Vector2, p_id: int, p_color: Color) -> void:
	current_player_id = p_id
	current_color = p_color
	is_rolling = false
	roll_enabled = true
	
	var move_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "global_position", target_global_pos, 0.25)
	
	if dice_btn:
		dice_btn.queue_redraw()

func set_roll_enabled(enabled: bool) -> void:
	roll_enabled = enabled
	if enabled:
		is_rolling = false
	if dice_btn:
		dice_btn.queue_redraw()

func _draw_dice() -> void:
	var s = dice_btn.size
	var rect = Rect2(Vector2.ZERO, s)
	
	# Drop Shadow
	dice_btn.draw_rect(rect.grow(-2), Color(0, 0, 0, 0.45), true)
	
	# Colored 3D Dice Face
	dice_btn.draw_rect(rect, current_color, true)
	dice_btn.draw_rect(rect, Color(1, 1, 1, 0.9), false, 2.5)
	
	# Pips
	var r = s.x * 0.095
	var dot_color = Color.WHITE
	var center = s * 0.5
	var l = s.x * 0.25
	var ri = s.x * 0.75
	var t = s.y * 0.25
	var b = s.y * 0.75

	match current_value:
		1:
			dice_btn.draw_circle(center, r * 1.4, dot_color)
		2:
			dice_btn.draw_circle(Vector2(l, t), r, dot_color)
			dice_btn.draw_circle(Vector2(ri, b), r, dot_color)
		3:
			dice_btn.draw_circle(center, r, dot_color)
			dice_btn.draw_circle(Vector2(l, t), r, dot_color)
			dice_btn.draw_circle(Vector2(ri, b), r, dot_color)
		4:
			dice_btn.draw_circle(Vector2(l, t), r, dot_color)
			dice_btn.draw_circle(Vector2(ri, t), r, dot_color)
			dice_btn.draw_circle(Vector2(l, b), r, dot_color)
			dice_btn.draw_circle(Vector2(ri, b), r, dot_color)
		5:
			dice_btn.draw_circle(center, r, dot_color)
			dice_btn.draw_circle(Vector2(l, t), r, dot_color)
			dice_btn.draw_circle(Vector2(ri, t), r, dot_color)
			dice_btn.draw_circle(Vector2(l, b), r, dot_color)
			dice_btn.draw_circle(Vector2(ri, b), r, dot_color)
		6:
			dice_btn.draw_circle(Vector2(l, t), r, dot_color)
			dice_btn.draw_circle(Vector2(ri, t), r, dot_color)
			dice_btn.draw_circle(Vector2(l, center.y), r, dot_color)
			dice_btn.draw_circle(Vector2(ri, center.y), r, dot_color)
			dice_btn.draw_circle(Vector2(l, b), r, dot_color)
			dice_btn.draw_circle(Vector2(ri, b), r, dot_color)
