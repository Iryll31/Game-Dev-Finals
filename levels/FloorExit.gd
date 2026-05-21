@tool
extends Area2D

@export var locked_text := "Find the floor key"

var _font := ThemeDB.fallback_font
var _is_open := false

func _ready() -> void:
	if not Engine.is_editor_hint():
		_is_open = GameManager.has_key
		body_entered.connect(_on_body_entered)
		GameManager.key_changed.connect(_on_key_changed)
	queue_redraw()

func _draw() -> void:
	var stone := Color(0.07, 0.082, 0.105)
	var edge := Color(0.22, 0.24, 0.39)
	var teal := Color(0.08, 0.78, 0.82)
	var ember := Color(1.0, 0.57, 0.16)
	var gold := Color(1.0, 0.78, 0.28)
	draw_rect(Rect2(Vector2(-25, -48), Vector2(50, 96)), stone, true)
	draw_rect(Rect2(Vector2(-25, -48), Vector2(50, 96)), edge, false, 3.0)
	draw_arc(Vector2(0, -24), 23.0, PI, TAU, 24, edge, 3.0)
	draw_rect(Rect2(Vector2(-16, -35), Vector2(32, 77)), Color(0.018, 0.022, 0.03), true)
	var rune_color := teal if _is_open else ember
	draw_circle(Vector2(0, -2), 8.0, rune_color)
	draw_circle(Vector2(0, -2), 14.0, Color(rune_color.r, rune_color.g, rune_color.b, 0.18))
	if _is_open:
		draw_line(Vector2(-9, 20), Vector2(9, 20), gold, 2.0)
		draw_string(_font, Vector2(-26, 65), "EXIT OPEN", HORIZONTAL_ALIGNMENT_CENTER, 52.0, 10, Color(0.78, 1.0, 0.95))
	else:
		draw_line(Vector2(-9, -2), Vector2(9, -2), gold, 2.0)
		draw_line(Vector2(0, -11), Vector2(0, 7), gold, 2.0)
		draw_string(_font, Vector2(-36, 65), locked_text, HORIZONTAL_ALIGNMENT_CENTER, 72.0, 10, Color(1.0, 0.78, 0.45))

func _on_body_entered(body: Node2D) -> void:
	if not _is_player(body):
		return
	await GameManager.request_floor_exit()

func _on_key_changed(has_key: bool) -> void:
	_is_open = has_key
	queue_redraw()

func _is_player(body: Node2D) -> bool:
	return body.name == "Player" or (body.has_method("take_damage") and body.has_method("respawn"))
