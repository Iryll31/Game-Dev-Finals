extends Area2D

@onready var timer: Timer = $Timer

const NON_FATAL_INVINCIBILITY: float = 0.65
const FATAL_RESPAWN_DELAY: float = 0.35

const INSTANT_TRAP_RESPAWN_SCENES: Array[String] = [
	"res://scenes/Stage 1.tscn",
	"res://scenes/Stage 2.tscn",
]

const INSTANT_TRAP_NAMES_BY_SCENE: Dictionary = {
	"res://scenes/Scene 3.tscn": ["SpikeTrap", "SpikeTrap9", "SpikeTrap10"],
	"res://scenes/Scene 4.tscn": ["SpikeTrap", "SpikeTrap2"],
	"res://scenes/Scene 5.tscn": ["SpikeTrap", "SpikeTrap2", "SpikeTrap3", "SpikeTrap7"],
}

## Prevents overlapping spikes from applying damage in the same frame.
static var _global_trap_active := false

var _is_fatal_sequence := false
var _trapped_player: CharacterBody2D


func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	var player := body as CharacterBody2D
	if player.has_method("is_trap_invincible") and player.call("is_trap_invincible"):
		return

	if _global_trap_active:
		return

	var scene_path := _get_scene_path()
	if _uses_instant_trap_respawn(scene_path):
		_start_forced_trap_respawn(player, scene_path)
		return

	var health_before := GameManager.health
	if health_before <= 1:
		_start_fatal_trap(player)
	else:
		_apply_non_fatal_trap(player)


func _uses_instant_trap_respawn(scene_path: String) -> bool:
	if scene_path in INSTANT_TRAP_RESPAWN_SCENES:
		return true
	if INSTANT_TRAP_NAMES_BY_SCENE.has(scene_path):
		return _get_trap_marker_name() in INSTANT_TRAP_NAMES_BY_SCENE[scene_path]
	return false


func _get_trap_marker_name() -> String:
	var trap_node: Node = self
	var scene := get_tree().current_scene
	if scene == null:
		return name
	while trap_node.get_parent() != null and trap_node.get_parent() != scene:
		trap_node = trap_node.get_parent()
	return trap_node.name


func _apply_non_fatal_trap(player: CharacterBody2D) -> void:
	_global_trap_active = true
	_damage_player(player)
	if player.has_method("grant_trap_invincibility"):
		player.call("grant_trap_invincibility", NON_FATAL_INVINCIBILITY)
	get_tree().create_timer(NON_FATAL_INVINCIBILITY).timeout.connect(_release_global_trap_lock)


func _start_forced_trap_respawn(player: CharacterBody2D, _scene_path: String) -> void:
	_start_fatal_trap(player, true)


func _start_fatal_trap(player: CharacterBody2D, apply_damage := true) -> void:
	if _is_fatal_sequence:
		return

	_global_trap_active = true
	_is_fatal_sequence = true
	_trapped_player = player
	set_deferred("monitoring", false)

	if apply_damage:
		_damage_player(player)
		if GameManager.is_game_over:
			_is_fatal_sequence = false
			_release_global_trap_lock()
			return
	elif player.has_method("play_death_feedback"):
		player.call("play_death_feedback")
	else:
		AudioManager.play_sfx("player_death")

	timer.wait_time = FATAL_RESPAWN_DELAY
	timer.start()


func _on_timer_timeout() -> void:
	if not _is_fatal_sequence:
		return

	_is_fatal_sequence = false
	var current_scene := get_tree().current_scene
	if current_scene == null:
		_release_global_trap_lock()
		set_deferred("monitoring", true)
		return

	var scene_path := current_scene.scene_file_path
	var player := _get_valid_player()
	_respawn_player_after_trap(player, scene_path)


func _respawn_player_after_trap(player: CharacterBody2D, scene_path: String) -> void:
	var respawn_pos := GameManager.get_trap_respawn_position(scene_path)
	if player != null and respawn_pos != Vector2.ZERO:
		_teleport_player_to_position(player, respawn_pos)
		if player.has_method("grant_trap_invincibility"):
			player.call("grant_trap_invincibility", 1.2)
		_release_global_trap_lock()
		set_deferred("monitoring", true)
		return

	GameManager.prepare_death_respawn(scene_path)
	_global_trap_active = false
	get_tree().reload_current_scene()


func _damage_player(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1)
		return

	GameManager.take_damage(1)
	AudioManager.play_sfx("player_hit")


func _teleport_player_to_position(player: CharacterBody2D, pos: Vector2) -> void:
	player.global_position = pos
	player.velocity = Vector2.ZERO
	if player.has_method("_snap_camera_to_player"):
		player.call("_snap_camera_to_player")
		player.call_deferred("_snap_camera_to_player")


func _get_valid_player() -> CharacterBody2D:
	if is_instance_valid(_trapped_player):
		return _trapped_player

	var scene := get_tree().current_scene
	if scene == null:
		return null

	var player := scene.get_node_or_null("Player")
	if player is CharacterBody2D:
		return player
	return null


func _get_scene_path() -> String:
	if get_tree().current_scene != null:
		return get_tree().current_scene.scene_file_path
	return ""


static func _release_global_trap_lock() -> void:
	_global_trap_active = false
