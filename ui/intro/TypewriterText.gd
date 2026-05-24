## TypewriterText.gd
## Attach this to a RichTextLabel used by the opening intro only.
## It reveals text one character at a time and emits a signal when finished.

extends RichTextLabel
class_name TypewriterText

signal finished_revealing

@export_range(5.0, 120.0, 1.0) var characters_per_second := 38.0

var _full_text := ""
var _is_revealing := false
var _elapsed := 0.0


func _ready() -> void:
	visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
	visible_characters = 0


func _process(delta: float) -> void:
	if not _is_revealing:
		return

	_elapsed += delta
	visible_characters = int(_elapsed * characters_per_second)

	if visible_characters >= _full_text.length():
		_finish_reveal()


func show_typewriter_text(next_text: String) -> void:
	_full_text = next_text
	text = next_text
	_elapsed = 0.0
	visible_characters = 0
	_is_revealing = true


func skip_to_end() -> void:
	if not _is_revealing:
		return

	visible_characters = _full_text.length()
	_finish_reveal()


func is_revealing() -> bool:
	return _is_revealing


func _finish_reveal() -> void:
	_is_revealing = false
	visible_characters = -1
	finished_revealing.emit()
