## AudioManager.gd
## Autoload singleton — add to Project Settings > Autoload as "AudioManager"
## Manages BGM and SFX buses. Attach your audio files in _ready().

extends Node

# --- BGM players ---
var bgm_player   : AudioStreamPlayer
var bgm_player2  : AudioStreamPlayer   # for crossfade

# --- SFX players (use a pool for overlapping sounds) ---
const SFX_POOL_SIZE := 8
const CHECKPOINT_FADE_TIME := 1.5
const CHECKPOINT_VOLUME_DB := -12.0
var _sfx_pool : Array[AudioStreamPlayer] = []
var _sfx_idx  : int = 0
var _checkpoint_player: AudioStreamPlayer
var _checkpoint_near_count := 0
var _checkpoint_faded_players: Dictionary = {}
var _checkpoint_tween: Tween
var _background_tweens: Dictionary = {}

# --- Stream references (assign in Inspector or via load()) ---
## BGM
var bgm_dungeon  : AudioStream  # dark chiptune, looping
var bgm_merchant : AudioStream  # quirky, lighter
var bgm_boss     : AudioStream  # intense orchestral chiptune
var bgm_ending   : AudioStream  # warm resolution
const CHECKPOINT_BGM_PATH := "res://audio/bgm/The Dragonborn Comes - Instrumental.mp3"

## SFX — assign file paths below
var sfx_map: Dictionary = {
	"jump":          "res://audio/sfx/unit_jump.ogg",
	"shoot":         "res://audio/sfx/unit_shoot.ogg",
	"enemy_hit":     "res://audio/sfx/enemy_hit.ogg",
	"player_hit":    "res://sounds/hurt.wav",
	"key_collect":   "res://sounds/keys pickup.mp3",
	"chest_open":    "res://sounds/chest open.mp3",
	"success":       "res://sounds/success.mp3",
	"gem_collect":   "res://audio/sfx/gem_collect.ogg",
	"heart_collect": "res://audio/sfx/heart_collect.ogg",
	"staff_collect": "res://audio/sfx/staff_collect.ogg",
	"torch_lit":     "res://audio/sfx/torch_lit.ogg",
	"player_death":  "res://audio/sfx/brut-slow.mp3",
	"door_unlock":   "res://audio/sfx/door_unlock.ogg",
	"boss_roar":     "res://audio/sfx/boss_roar.ogg",
}
var _loaded_sfx: Dictionary = {}

# -----------------------------------------------------------------------
func _ready() -> void:
	_ensure_bgm_players()
	_setup_checkpoint_player()

	# Build SFX pool
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)
	# Pre-load SFX
	for key in sfx_map:
		if ResourceLoader.exists(sfx_map[key]):
			_loaded_sfx[key] = load(sfx_map[key])

# --- BGM ---
func _ensure_bgm_players() -> void:
	bgm_player = get_node_or_null("BGMPlayer") as AudioStreamPlayer
	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer"
		add_child(bgm_player)

	bgm_player2 = get_node_or_null("BGMPlayer2") as AudioStreamPlayer
	if bgm_player2 == null:
		bgm_player2 = AudioStreamPlayer.new()
		bgm_player2.name = "BGMPlayer2"
		add_child(bgm_player2)

func play_bgm(stream: AudioStream, fade_in: float = 0.5) -> void:
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.stream = stream
	bgm_player.volume_db = -80.0
	bgm_player.play()
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", 0.0, fade_in)

func stop_bgm(fade_out: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", -80.0, fade_out)
	tween.tween_callback(bgm_player.stop)

func play_dungeon_bgm()  -> void: play_bgm(bgm_dungeon)
func play_merchant_bgm() -> void: play_bgm(bgm_merchant)
func play_boss_bgm()     -> void: play_bgm(bgm_boss, 0.1)
func play_ending_bgm()   -> void: play_bgm(bgm_ending, 1.5)

func play_checkpoint_bgm(fade_time: float = CHECKPOINT_FADE_TIME) -> void:
	_checkpoint_near_count += 1
	if _checkpoint_near_count > 1:
		return

	_stop_tween(_checkpoint_tween)
	_fade_background_players(-80.0, fade_time)
	if _checkpoint_player.stream == null:
		return

	_checkpoint_player.volume_db = -80.0
	_checkpoint_player.play()
	_checkpoint_tween = create_tween()
	_checkpoint_tween.tween_property(_checkpoint_player, "volume_db", CHECKPOINT_VOLUME_DB, fade_time)

func stop_checkpoint_bgm(fade_time: float = CHECKPOINT_FADE_TIME) -> void:
	_checkpoint_near_count = max(_checkpoint_near_count - 1, 0)
	if _checkpoint_near_count > 0:
		return

	_stop_tween(_checkpoint_tween)
	if _checkpoint_player.playing:
		_checkpoint_tween = create_tween()
		_checkpoint_tween.tween_property(_checkpoint_player, "volume_db", -80.0, fade_time)
		_checkpoint_tween.tween_callback(_checkpoint_player.stop)

	_restore_background_players(fade_time)

func _setup_checkpoint_player() -> void:
	_checkpoint_player = AudioStreamPlayer.new()
	_checkpoint_player.name = "CheckpointBGMPlayer"
	_checkpoint_player.bus = "Master"
	add_child(_checkpoint_player)

	_checkpoint_player.stream = load(CHECKPOINT_BGM_PATH)
	if _checkpoint_player.stream != null:
		_checkpoint_player.stream.set("loop", true)
	else:
		push_warning("AudioManager: checkpoint BGM not found - " + CHECKPOINT_BGM_PATH)

func _fade_background_players(target_volume_db: float, fade_time: float) -> void:
	for player in _get_background_players():
		if not player.playing:
			continue
		if not _checkpoint_faded_players.has(player):
			_checkpoint_faded_players[player] = player.volume_db
		_stop_background_tween(player)
		var tween := create_tween()
		_background_tweens[player] = tween
		tween.tween_property(player, "volume_db", target_volume_db, fade_time)

func _restore_background_players(fade_time: float) -> void:
	for player in _checkpoint_faded_players.keys():
		if not is_instance_valid(player):
			continue
		_stop_background_tween(player)
		var tween := create_tween()
		_background_tweens[player] = tween
		tween.tween_property(player, "volume_db", _checkpoint_faded_players[player], fade_time)
	_checkpoint_faded_players.clear()

func _stop_background_tween(player: AudioStreamPlayer) -> void:
	if not _background_tweens.has(player):
		return
	var tween := _background_tweens[player] as Tween
	_stop_tween(tween)
	_background_tweens.erase(player)

func _stop_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()

func _get_background_players() -> Array[AudioStreamPlayer]:
	var players: Array[AudioStreamPlayer] = []
	for node in get_tree().root.find_children("*", "AudioStreamPlayer", true, false):
		var player := node as AudioStreamPlayer
		if player == null or player == _checkpoint_player or _sfx_pool.has(player):
			continue
		players.append(player)
	return players

# --- SFX ---
func play_sfx(sfx_name: String) -> void:
	if not _loaded_sfx.has(sfx_name):
		push_warning("AudioManager: SFX not found — " + sfx_name)
		return
	var player := _sfx_pool[_sfx_idx % SFX_POOL_SIZE]
	_sfx_idx += 1
	player.stream = _loaded_sfx[sfx_name]
	player.play()
