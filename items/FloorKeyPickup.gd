@tool
extends Area2D

var _font := ThemeDB.fallback_font

func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _draw() -> void:
	var gold := Color(1.0, 0.78, 0.28)
	var edge := Color(1.0, 0.93, 0.62)
	draw_circle(Vector2(-8, 0), 9.0, Color(0.08, 0.52, 0.58, 0.2))
	draw_circle(Vector2(-8, 0), 7.0, gold)
	draw_circle(Vector2(-8, 0), 3.0, Color(0.03, 0.035, 0.045))
	draw_rect(Rect2(Vector2(-1, -3), Vector2(31, 6)), gold, true)
	draw_rect(Rect2(Vector2(18, 2), Vector2(5, 11)), gold, true)
	draw_rect(Rect2(Vector2(27, 2), Vector2(5, 11)), gold, true)
	draw_arc(Vector2(-8, 0), 8.0, 0.0, TAU, 20, edge, 1.5)
	draw_string(_font, Vector2(-25, 31), "FLOOR KEY", HORIZONTAL_ALIGNMENT_CENTER, 58.0, 10, Color(0.8, 0.95, 0.93))

func _on_body_entered(body: Node2D) -> void:
	if not _is_player(body):
		return
	GameManager.collect_floor_key()
	queue_free()

func _is_player(body: Node2D) -> bool:
	return body.name == "Player" or (body.has_method("take_damage") and body.has_method("respawn"))
