extends Control

signal resume_requested
signal restart_requested
signal quit_requested

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton
@onready var panel: PanelContainer = $Panel
@onready var title: Label = $Panel/VBox/Title
@onready var directive: Label = $Panel/VBox/Directive

func _ready() -> void:
	hide()
	_apply_dungeon_theme()
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	quit_button.pressed.connect(func() -> void: quit_requested.emit())

func open() -> void:
	show()
	resume_button.grab_focus()

func close() -> void:
	hide()

func _apply_dungeon_theme() -> void:
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.37))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	directive.add_theme_color_override("font_color", Color(0.72, 0.91, 0.9))
	for button in [resume_button, restart_button, quit_button]:
		_style_button(button)

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.028, 0.034, 0.045, 0.96)
	style.border_color = Color(0.22, 0.24, 0.39, 1.0)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 10
	style.content_margin_left = 24
	style.content_margin_top = 22
	style.content_margin_right = 24
	style.content_margin_bottom = 22
	return style

func _style_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(238, 38)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.82, 0.95, 0.94))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 0.42))
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.86, 0.42))
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
