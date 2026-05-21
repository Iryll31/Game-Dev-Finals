extends CanvasLayer

@onready var pause_menu: Control = %PauseMenu
@onready var transition_overlay: Control = %TransitionOverlay
@onready var transition_label: Label = %TransitionLabel
@onready var transition_hint: Label = %TransitionHint
@onready var locked_notice: PanelContainer = %LockedNotice

var is_paused := false
var _locked_notice_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.restart_requested.connect(_restart_floor)
	pause_menu.quit_requested.connect(_quit_game)
	_apply_phase4_theme()
	transition_overlay.hide()
	locked_notice.hide()
	GameManager.floor_exit_locked.connect(_show_locked_notice)
	GameManager.floor_transition_started.connect(_show_floor_transition)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		if is_paused:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

func _pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	pause_menu.open()

func _resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	pause_menu.close()

func _restart_floor() -> void:
	get_tree().paused = false
	GameManager.health = GameManager.MAX_HEALTH
	GameManager.health_changed.emit(GameManager.health, GameManager.MAX_HEALTH)
	get_tree().reload_current_scene()

func _quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()

func _show_floor_transition(floor_number: int) -> void:
	transition_label.text = "DESCENDING TO FLOOR %d" % floor_number
	transition_hint.text = "Loading next chamber..."
	transition_overlay.modulate.a = 0.0
	transition_overlay.show()
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.22)

func _show_locked_notice() -> void:
	locked_notice.modulate.a = 0.0
	locked_notice.show()
	if _locked_notice_tween:
		_locked_notice_tween.kill()
	_locked_notice_tween = create_tween()
	_locked_notice_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_locked_notice_tween.tween_property(locked_notice, "modulate:a", 1.0, 0.16)
	_locked_notice_tween.tween_interval(1.35)
	_locked_notice_tween.tween_property(locked_notice, "modulate:a", 0.0, 0.25)
	_locked_notice_tween.tween_callback(locked_notice.hide)

func _apply_phase4_theme() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.026, 0.032, 0.043, 0.96)
	panel_style.border_color = Color(0.08, 0.72, 0.76, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.content_margin_left = 16
	panel_style.content_margin_top = 10
	panel_style.content_margin_right = 16
	panel_style.content_margin_bottom = 10
	locked_notice.add_theme_stylebox_override("panel", panel_style)
	transition_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.28))
	transition_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	transition_label.add_theme_constant_override("shadow_offset_x", 2)
	transition_label.add_theme_constant_override("shadow_offset_y", 2)
	transition_hint.add_theme_color_override("font_color", Color(0.72, 0.91, 0.9))
