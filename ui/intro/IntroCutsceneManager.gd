## IntroCutsceneManager.gd
## Attach this to the root Control node of IntroUI.tscn.
## This is a lightweight opening cutscene controller, not a gameplay dialogue system.

extends Control

const MAIN_GAME_SCENE := "res://scenes/Stage 1.tscn"
const INTRO_BGM_PATH := "res://audio/bgm/intro/dungeon_theme_BGM.mp3"
const INTRO_VOICE_PATH := "res://audio/voice/intro/VoiceOver.mp3"

@export var fade_duration := 1.0
@export var final_hold_time := 2.0

@onready var story_label = %StoryLabel
@onready var continue_button: Button = %ContinueButton
@onready var bgm_player: AudioStreamPlayer = %IntroBGMPlayer
@onready var voice_player: AudioStreamPlayer = %IntroVoicePlayer
@onready var fade_overlay: ColorRect = %FadeOverlay
@onready var final_hold_timer: Timer = %FinalHoldTimer

var _intro_cues: Array[Dictionary] = [
	{"time": 0.0, "text": "Long ago, deep beneath the surface, there existed a magical dungeon kingdom powered by glowing crystals and eternal blue flames."},
	{"time": 8.0, "text": "For centuries, the great wizard Aldric protected the dungeon and kept the ancient darkness sealed away."},
	{"time": 14.0, "text": "But peace did not last."},
	{"time": 16.0, "text": "The inhabitants of this dungeon came without warning. They took Aldric's magical staff and scattered its pieces across the dungeon floors."},
	{"time": 25.0, "text": "Without the wizard's full power, corruption spread throughout the kingdom."},
	{"time": 30.0, "text": "The peaceful Hollows became twisted monsters."},
	{"time": 33.0, "text": "The crystals dimmed."},
	{"time": 35.0, "text": "And darkness consumed the dungeon floor by floor."},
	{"time": 39.0, "text": "In the highest forgotten chamber, a small guardian machine suddenly awakened."},
	{"time": 44.0, "text": "Its name was UNIT."},
	{"time": 46.0, "text": "Created long ago by Aldric himself, UNIT was built for one purpose:"},
	{"time": 50.0, "text": "Find the staff pieces."},
	{"time": 51.0, "text": "Restore the dungeon."},
	{"time": 52.0, "text": "Save the kingdom."}
]

var _dialogue_index := 0
var _intro_is_finishing := false


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	final_hold_timer.timeout.connect(_finish_intro)
	voice_player.finished.connect(_on_voice_finished)

	_load_intro_audio()
	_start_intro()


func _process(_delta: float) -> void:
	if _intro_is_finishing or not voice_player.playing:
		return

	_sync_dialogue_to_voice_time(voice_player.get_playback_position())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_on_continue_pressed()


func _load_intro_audio() -> void:
	bgm_player.stream = _load_audio_stream(INTRO_BGM_PATH)
	if bgm_player.stream == null:
		push_warning("Intro BGM is missing or has not been imported by Godot: " + INTRO_BGM_PATH)

	voice_player.stream = _load_audio_stream(INTRO_VOICE_PATH)
	if voice_player.stream == null:
		push_warning("Intro voice is missing, unsupported, or has not been imported by Godot: " + INTRO_VOICE_PATH)


func _load_audio_stream(path: String) -> AudioStream:
	# ResourceLoader needs valid Godot import metadata. This check prevents loader
	# errors when the source file exists but still needs importing or re-exporting.
	if not FileAccess.file_exists(path):
		return null
	if not FileAccess.file_exists(path + ".import"):
		return null

	var import_file := FileAccess.open(path + ".import", FileAccess.READ)
	if import_file == null:
		return null
	var import_text := import_file.get_as_text()
	if import_text.contains("valid=false"):
		return null
	if not ResourceLoader.exists(path):
		return null

	var stream := load(path) as AudioStream
	return stream


func _start_intro() -> void:
	fade_overlay.modulate.a = 1.0
	_dialogue_index = 0
	_intro_is_finishing = false
	continue_button.disabled = false
	continue_button.text = "Continue"
	_show_dialogue_at_index(_dialogue_index, false)

	if bgm_player.stream != null:
		bgm_player.play()

	if voice_player.stream != null:
		voice_player.play()

	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, fade_duration)


func _sync_dialogue_to_voice_time(playback_position: float) -> void:
	var cue_index := _get_cue_index_for_time(playback_position)
	if cue_index != _dialogue_index:
		_show_dialogue_at_index(cue_index, true)


func _get_cue_index_for_time(playback_position: float) -> int:
	var cue_index := 0
	for i in _intro_cues.size():
		if playback_position >= float(_intro_cues[i]["time"]):
			cue_index = i
		else:
			break
	return cue_index


func _show_dialogue_at_index(index: int, instant: bool) -> void:
	if index >= _intro_cues.size():
		_finish_intro()
		return

	_dialogue_index = index
	var dialogue_text := String(_intro_cues[_dialogue_index]["text"])
	if instant:
		# Timestamp jumps must update text immediately so voice, text, and index stay locked.
		story_label.text = dialogue_text
		story_label.visible_characters = -1
	else:
		story_label.show_typewriter_text(dialogue_text)


func _on_continue_pressed() -> void:
	if _intro_is_finishing:
		return

	var next_index := _dialogue_index + 1
	if next_index >= _intro_cues.size():
		_finish_intro()
		return

	_show_dialogue_at_index(next_index, true)
	if voice_player.stream != null:
		voice_player.play(float(_intro_cues[next_index]["time"]))


func _on_voice_finished() -> void:
	if _intro_is_finishing:
		return

	if final_hold_timer.is_stopped():
		final_hold_timer.start(final_hold_time)


func _finish_intro() -> void:
	if _intro_is_finishing:
		return

	_intro_is_finishing = true
	continue_button.disabled = true
	continue_button.text = "Loading"

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_overlay, "modulate:a", 1.0, fade_duration)
	tween.tween_property(bgm_player, "volume_db", -40.0, fade_duration)
	tween.tween_property(voice_player, "volume_db", -40.0, fade_duration)
	tween.set_parallel(false)
	tween.tween_callback(_load_gameplay_scene)


func _load_gameplay_scene() -> void:
	bgm_player.stop()
	voice_player.stop()
	get_tree().change_scene_to_file(MAIN_GAME_SCENE)
