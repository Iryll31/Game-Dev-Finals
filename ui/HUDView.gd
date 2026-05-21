extends Control

const MAX_HEALTH := 5
const MAX_STAFF_PIECES := 4

var health := MAX_HEALTH
var max_health := MAX_HEALTH
var lives := 3
var gems := 0
var has_key := false
var staff_pieces: Array[bool] = [false, false, false, false]

var _title_font := ThemeDB.fallback_font
var _font_size := 18
var _small_font_size := 13
var _stone_dark := Color(0.025, 0.032, 0.041, 0.9)
var _stone_mid := Color(0.07, 0.082, 0.105, 0.96)
var _stone_edge := Color(0.185, 0.205, 0.32, 0.92)
var _rune_teal := Color(0.08, 0.78, 0.82, 0.9)
var _ember := Color(1.0, 0.57, 0.16, 0.95)
var _gold := Color(1.0, 0.78, 0.28, 0.98)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_connect_game_manager()
	_sync_from_game_manager()
	queue_redraw()

func _draw() -> void:
	var panel := Rect2(Vector2(18, 16), Vector2(386, 90))
	_draw_panel(panel)
	_draw_health(Vector2(34, 31))
	_draw_lives(Vector2(34, 72))
	_draw_gems(Vector2(172, 72))
	_draw_key_status(Vector2(266, 72))
	_draw_staff_tracker(Vector2(526, 18))

func _connect_game_manager() -> void:
	if not is_instance_valid(GameManager):
		return
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.gems_changed.connect(_on_gems_changed)
	GameManager.staff_piece_collected.connect(_on_staff_piece_collected)
	GameManager.key_changed.connect(_on_key_changed)

func _sync_from_game_manager() -> void:
	if not is_instance_valid(GameManager):
		return
	health = GameManager.health
	max_health = GameManager.MAX_HEALTH
	lives = GameManager.lives
	gems = GameManager.gems
	has_key = GameManager.has_key
	staff_pieces = GameManager.staff_collected.duplicate()

func _draw_panel(rect: Rect2) -> void:
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.35), true)
	var inner := rect.grow(-4)
	draw_rect(inner, _stone_dark, true)
	_draw_stone_blocks(inner)
	draw_rect(rect, _stone_edge, false, 2.0)
	draw_rect(inner, Color(0.015, 0.018, 0.028, 0.75), false, 1.0)
	draw_line(rect.position + Vector2(3, rect.size.y - 3), rect.position + rect.size - Vector2(3, 3), _rune_teal, 1.0)
	draw_line(rect.position + Vector2(3, 3), rect.position + Vector2(rect.size.x - 3, 3), Color(0.39, 0.34, 0.62, 0.65), 1.0)
	_draw_corner_rivets(rect)

func _draw_stone_blocks(rect: Rect2) -> void:
	var block := Vector2(32, 17)
	var y := rect.position.y
	var row := 0
	while y < rect.end.y:
		var x := rect.position.x + (16 if row % 2 == 1 else 0)
		while x < rect.end.x:
			var stone := Rect2(Vector2(x, y), block).intersection(rect)
			draw_rect(stone, _stone_mid, true)
			draw_rect(stone, Color(0.012, 0.015, 0.02, 0.7), false, 1.0)
			x += block.x
		y += block.y
		row += 1

func _draw_corner_rivets(rect: Rect2) -> void:
	var points := [
		rect.position + Vector2(7, 7),
		rect.position + Vector2(rect.size.x - 7, 7),
		rect.position + Vector2(7, rect.size.y - 7),
		rect.position + rect.size - Vector2(7, 7),
	]
	for point in points:
		draw_circle(point, 2.2, _rune_teal)
		draw_circle(point, 4.5, Color(0.08, 0.52, 0.58, 0.22))

func _draw_health(origin: Vector2) -> void:
	_draw_torch(origin + Vector2(8, 9), health > 0)
	draw_string(_title_font, origin + Vector2(23, 14), "VITAL FLAME", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _small_font_size, Color(0.82, 0.94, 0.96))
	var segment_size := Vector2(31, 15)
	for i in max_health:
		var x := origin.x + 118 + i * (segment_size.x + 5)
		var rect := Rect2(Vector2(x, origin.y), segment_size)
		var filled := i < health
		var fill_color := _ember if filled else Color(0.11, 0.105, 0.13, 0.9)
		draw_rect(rect, fill_color, true)
		draw_rect(rect, Color(0.93, 0.82, 0.48, 0.86) if filled else Color(0.33, 0.34, 0.42, 0.95), false, 1.5)
		if filled:
			draw_rect(Rect2(rect.position + Vector2(3, 3), Vector2(rect.size.x - 6, 3)), Color(1, 0.93, 0.66, 0.38), true)

func _draw_lives(origin: Vector2) -> void:
	draw_string(_title_font, origin + Vector2(0, 14), "LIFE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _small_font_size, Color(0.86, 0.94, 0.95))
	for i in lives:
		_draw_heart(origin + Vector2(54 + i * 22, 2), _ember)

func _draw_gems(origin: Vector2) -> void:
	_draw_gem(origin + Vector2(8, 8), _rune_teal)
	draw_string(_title_font, origin + Vector2(29, 14), str(gems).pad_zeros(2), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, Color(0.82, 0.98, 0.96))

func _draw_key_status(origin: Vector2) -> void:
	var key_color := _gold if has_key else Color(0.25, 0.25, 0.3)
	var edge_color := Color(1.0, 0.91, 0.58) if has_key else Color(0.42, 0.43, 0.52)
	draw_circle(origin + Vector2(8, 7), 6.0, key_color)
	draw_circle(origin + Vector2(8, 7), 3.0, _stone_mid)
	draw_rect(Rect2(origin + Vector2(13, 5), Vector2(22, 4)), key_color, true)
	draw_rect(Rect2(origin + Vector2(28, 9), Vector2(4, 7)), key_color, true)
	draw_rect(Rect2(origin + Vector2(35, 9), Vector2(4, 7)), key_color, true)
	draw_arc(origin + Vector2(8, 7), 6.5, 0.0, TAU, 20, edge_color, 1.4)
	draw_string(_title_font, origin + Vector2(45, 14), "KEY" if has_key else "LOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _small_font_size, edge_color)

func _draw_staff_tracker(origin: Vector2) -> void:
	var panel := Rect2(origin, Vector2(238, 48))
	_draw_panel(panel)
	draw_string(_title_font, origin + Vector2(16, 29), "STAFF", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _small_font_size, Color(1.0, 0.88, 0.48))
	for i in MAX_STAFF_PIECES:
		var piece_origin := origin + Vector2(86 + i * 34, 15)
		var filled := i < staff_pieces.size() and staff_pieces[i]
		_draw_staff_piece(piece_origin, filled)

func _draw_heart(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, 5),
		center + Vector2(-10, -4),
		center + Vector2(-5, -11),
		center + Vector2(0, -7),
		center + Vector2(5, -11),
		center + Vector2(10, -4),
	])
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color(1.0, 0.86, 0.52), 1.5)

func _draw_gem(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -10),
		center + Vector2(9, 0),
		center + Vector2(0, 12),
		center + Vector2(-9, 0),
	])
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0.74, 1.0, 0.96), 1.3)

func _draw_staff_piece(origin: Vector2, filled: bool) -> void:
	var fill := _gold if filled else Color(0.115, 0.108, 0.13)
	var edge := Color(1.0, 0.93, 0.66) if filled else Color(0.36, 0.38, 0.52)
	draw_rect(Rect2(origin, Vector2(22, 18)), fill, true)
	draw_rect(Rect2(origin, Vector2(22, 18)), edge, false, 1.5)
	draw_line(origin + Vector2(4, 14), origin + Vector2(18, 4), edge, 2.0)

func _draw_torch(origin: Vector2, lit: bool) -> void:
	draw_rect(Rect2(origin + Vector2(-2, 8), Vector2(4, 11)), Color(0.28, 0.19, 0.13), true)
	draw_line(origin + Vector2(-5, 9), origin + Vector2(5, 9), Color(0.47, 0.34, 0.22), 2.0)
	if lit:
		var flame := PackedVector2Array([
			origin + Vector2(0, -8),
			origin + Vector2(6, 3),
			origin + Vector2(0, 10),
			origin + Vector2(-6, 3),
		])
		draw_colored_polygon(flame, _ember)
		draw_colored_polygon(PackedVector2Array([
			origin + Vector2(0, -4),
			origin + Vector2(3, 3),
			origin + Vector2(0, 7),
			origin + Vector2(-3, 3),
		]), _gold)

func _on_health_changed(new_hp: int, new_max_hp: int) -> void:
	health = new_hp
	max_health = new_max_hp
	queue_redraw()

func _on_lives_changed(new_lives: int) -> void:
	lives = new_lives
	queue_redraw()

func _on_gems_changed(new_gems: int) -> void:
	gems = new_gems
	queue_redraw()

func _on_key_changed(new_has_key: bool) -> void:
	has_key = new_has_key
	queue_redraw()

func _on_staff_piece_collected(piece_index: int) -> void:
	if piece_index >= 0 and piece_index < staff_pieces.size():
		staff_pieces[piece_index] = true
	queue_redraw()
