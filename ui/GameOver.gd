extends Control

@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton
@onready var panel: PanelContainer = $Panel
@onready var title: Label = $Panel/VBox/Title
@onready var message: Label = $Panel/VBox/Message
@onready var background: ColorRect = $Background
@onready var glow: ColorRect = $Glow

func _ready() -> void:
	get_tree().paused = false
	_apply_dungeon_theme()
	restart_button.pressed.connect(_restart_run)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	restart_button.grab_focus()

func _restart_run() -> void:
	GameManager.reset_run()
	if GameManager.FLOOR_SCENES.is_empty():
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(GameManager.FLOOR_SCENES[0])

func _apply_dungeon_theme() -> void:
	background.color = Color(0.008, 0.01, 0.014, 1.0)
	glow.color = Color(0.0, 0.52, 0.56, 0.16)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	title.add_theme_color_override("font_color", Color(1.0, 0.58, 0.18))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	message.add_theme_color_override("font_color", Color(0.73, 0.91, 0.9))
	for button in [restart_button, quit_button]:
		_style_button(button)

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.026, 0.032, 0.043, 0.97)
	style.border_color = Color(0.21, 0.23, 0.38, 1.0)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	style.shadow_size = 12
	style.content_margin_left = 26
	style.content_margin_top = 24
	style.content_margin_right = 26
	style.content_margin_bottom = 24
	return style

func _style_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(250, 40)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.82, 0.95, 0.94))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.84, 0.4))
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.84, 0.4))
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.065, 0.078, 0.105, 0.98), Color(0.18, 0.2, 0.32, 1.0)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.085, 0.115, 0.14, 1.0), Color(0.08, 0.72, 0.76, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.035, 0.045, 0.06, 1.0), Color(1.0, 0.62, 0.18, 1.0)))
	button.add_theme_stylebox_override("focus", _make_button_style(Color(0.08, 0.105, 0.13, 0.75), Color(1.0, 0.62, 0.18, 1.0)))

func _make_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 12
	style.content_margin_top = 7
	style.content_margin_right = 12
	style.content_margin_bottom = 7
	return style
