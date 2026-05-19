## AudioManager.gd
## Autoload singleton — add to Project Settings > Autoload as "AudioManager"
## Manages BGM and SFX buses. Attach your audio files in _ready().

extends Node

# --- BGM players ---
@onready var bgm_player   : AudioStreamPlayer = $BGMPlayer
@onready var bgm_player2  : AudioStreamPlayer = $BGMPlayer2   # for crossfade

# --- SFX players (use a pool for overlapping sounds) ---
const SFX_POOL_SIZE := 8
var _sfx_pool : Array[AudioStreamPlayer] = []
var _sfx_idx  : int = 0

# --- Stream references (assign in Inspector or via load()) ---
## BGM
var bgm_dungeon  : AudioStream  # dark chiptune, looping
var bgm_merchant : AudioStream  # quirky, lighter
var bgm_boss     : AudioStream  # intense orchestral chiptune
var bgm_ending   : AudioStream  # warm resolution

## SFX — assign file paths below
var sfx_map: Dictionary = {
	"jump":          "res://audio/sfx/unit_jump.ogg",
	"shoot":         "res://audio/sfx/unit_shoot.ogg",
	"enemy_hit":     "res://audio/sfx/enemy_hit.ogg",
	"player_hit":    "res://audio/sfx/player_hit.ogg",
	"key_collect":   "res://audio/sfx/key_collect.ogg",
	"gem_collect":   "res://audio/sfx/gem_collect.ogg",
	"heart_collect": "res://audio/sfx/heart_collect.ogg",
	"staff_collect": "res://audio/sfx/staff_collect.ogg",
	"torch_lit":     "res://audio/sfx/torch_lit.ogg",
	"player_death":  "res://audio/sfx/player_death.ogg",
	"door_unlock":   "res://audio/sfx/door_unlock.ogg",
	"boss_roar":     "res://audio/sfx/boss_roar.ogg",
}
var _loaded_sfx: Dictionary = {}

# -----------------------------------------------------------------------
func _ready() -> void:
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

# --- SFX ---
func play_sfx(sfx_name: String) -> void:
	if not _loaded_sfx.has(sfx_name):
		push_warning("AudioManager: SFX not found — " + sfx_name)
		return
	var player := _sfx_pool[_sfx_idx % SFX_POOL_SIZE]
	_sfx_idx += 1
	player.stream = _loaded_sfx[sfx_name]
	player.play()
