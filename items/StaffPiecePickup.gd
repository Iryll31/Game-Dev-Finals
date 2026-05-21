@tool
extends Area2D

@export_range(0, 3) var piece_index: int = 0
@export var label_names: Array[String] = ["TIP", "ORB", "CORE", "BASE"]

var _font := ThemeDB.fallback_font

func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	var gold := Color(1.0, 0.78, 0.28)
	var ember := Color(1.0, 0.54, 0.14)
	var teal := Color(0.08, 0.78, 0.82)
	var shadow := Color(0.0, 0.0, 0.0, 0.55)
	draw_circle(Vector2.ZERO, 20.0, Color(0.08, 0.52, 0.58, 0.18))
	draw_rect(Rect2(Vector2(-12, -9), Vector2(24, 18)), shadow, true)
	draw_rect(Rect2(Vector2(-10, -11), Vector2(20, 20)), gold, true)
	draw_rect(Rect2(Vector2(-10, -11), Vector2(20, 20)), Color(1.0, 0.93, 0.62), false, 2.0)
	match piece_index:
		0:
			draw_polygon(PackedVector2Array([Vector2(0, -17), Vector2(9, 7), Vector2(-9, 7)]), PackedColorArray([ember, gold, gold]))
		1:
			draw_circle(Vector2.ZERO, 7.0, teal)
			draw_circle(Vector2.ZERO, 3.0, Color(0.75, 1.0, 0.94))
		2:
			draw_line(Vector2(-8, -7), Vector2(8, 7), ember, 3.0)
			draw_line(Vector2(-8, 7), Vector2(8, -7), ember, 3.0)
		_:
			draw_rect(Rect2(Vector2(-5, -16), Vector2(10, 28)), ember, true)
			draw_rect(Rect2(Vector2(-11, 8), Vector2(22, 7)), gold, true)
	var label := label_names[piece_index] if piece_index < label_names.size() else "PIECE"
	draw_string(_font, Vector2(-18, 34), label, HORIZONTAL_ALIGNMENT_CENTER, 36.0, 10, Color(0.8, 0.95, 0.93))

func _on_body_entered(body: Node2D) -> void:
	if not _is_player(body):
		return
	GameManager.collect_staff_piece(piece_index)
	queue_free()

func _is_player(body: Node2D) -> bool:
	return body.name == "Player" or (body.has_method("take_damage") and body.has_method("respawn"))
