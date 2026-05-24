extends CanvasLayer
class_name KeyObtainedPopup

const FONT_NORMAL: Font = preload("res://fonts/PixelOperator8.ttf")
const FONT_BOLD: Font = preload("res://fonts/PixelOperator8-Bold.ttf")
const FADE_DURATION: float = 0.25
const DISPLAY_SECONDS: float = 2.5

var _content: Control


static func show_popup() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var popup := KeyObtainedPopup.new()
	tree.root.add_child(popup)


func _ready() -> void:
	layer = 100
	_content = Control.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_build_ui(_content)
	_content.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_content, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_interval(maxf(DISPLAY_SECONDS - FADE_DURATION * 2.0, 0.35))
	tween.tween_property(_content, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(queue_free)


func _build_ui(parent: Control) -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.5)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.scroll_active = false
	rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rich.custom_minimum_size = Vector2(440, 0)
	rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rich.add_theme_font_override("normal_font", FONT_NORMAL)
	rich.add_theme_font_override("bold_font", FONT_BOLD)
	rich.add_theme_font_override("italics_font", FONT_NORMAL)
	rich.add_theme_font_override("bold_italics_font", FONT_BOLD)
	rich.text = (
		"[center]"
		+ "[font_size=26][b]Key obtained[/b][/font_size]\n"
		+ "[font_size=17][i]The door will open.[/i][/font_size]\n"
		+ "[font_size=15]Find the exit and descend deeper.[/font_size]"
		+ "[/center]"
	)
	margin.add_child(rich)
