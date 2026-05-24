## GameManager.gd
## Autoload singleton — add to Project > Project Settings > Autoload as "GameManager"
## Tracks global state: lives, gems, staff pieces, current floor, checkpoints.

extends Node

signal lives_changed(new_lives: int)
signal gems_changed(new_gems: int)
signal staff_piece_collected(piece_index: int)
signal staff_progress_changed(collected: int, total: int)
signal health_changed(new_hp: int, max_hp: int)
signal key_progress_changed(collected: int, total: int)
signal game_over
signal game_won

# --- Constants ---
const MAX_LIVES       : int = 3
const MAX_HEALTH      : int = 5
const STAFF_PIECES    : int = 4
const TOTAL_FLOORS    : int = 6  # 5 normal + 1 boss

const STAGE_STAFF_PIECE_BY_SCENE: Dictionary = {
	"res://scenes/Stage 2.tscn": 0,
	"res://scenes/Scene 3.tscn": 1,
	"res://scenes/Scene 4.tscn": 2,
	"res://scenes/Scene 6.tscn": 3,
}

const SCENE_KEY_TOTALS: Dictionary = {
	"res://scenes/Stage 1.tscn": 1,
	"res://scenes/Stage 2.tscn": 1,
	"res://scenes/Scene 3.tscn": 1,
	"res://scenes/Scene 4.tscn": 3,
}

const STAGE_DEFAULT_ENTRY_SPAWNS: Dictionary = {
	"res://scenes/Stage 1.tscn": Vector2(55, -32),
	"res://scenes/Stage 2.tscn": Vector2(68, -6),
	"res://scenes/Scene 3.tscn": Vector2(69, 143),
	"res://scenes/Scene 4.tscn": Vector2(73, 21),
	"res://scenes/Scene 5.tscn": Vector2(64, 937),
}

const SCENE_4_KEY_UNLOCK_INFO: Dictionary = {
	0: {"key_name": "Key 1", "door_name": "Door 2"},
	1: {"key_name": "Key 2", "door_name": "Door 3"},
	2: {"key_name": "Key 3", "door_name": "the Exit Door"},
}

# --- State ---
var lives          : int = MAX_LIVES
var gems           : int = 0
var health         : int = MAX_HEALTH
var staff_collected: Array[bool] = [false, false, false, false]
var current_floor  : int = 1
var checkpoint_pos : Vector2 = Vector2.ZERO
var checkpoint_scene_path : String = ""
var transition_spawn_pos : Vector2 = Vector2.ZERO
var transition_spawn_scene_path : String = ""
var stage_entry_spawns: Dictionary = {}
var death_respawn_pos : Vector2 = Vector2.ZERO
var death_respawn_scene_path : String = ""
var has_key        : bool = false
var collected_keys_by_scene: Dictionary = {}
var is_game_over   : bool = false

# --- Floor scene paths (set these to your actual scene file paths) ---
const FLOOR_SCENES: Array[String] = [
	"res://levels/floor_1.tscn",
	"res://levels/floor_2.tscn",
	"res://levels/floor_3.tscn",
	"res://levels/floor_4.tscn",
	"res://levels/floor_5.tscn",
	"res://levels/floor_boss.tscn",
]

# -----------------------------------------------------------------------
func _ready() -> void:
	reset_run()

func reset_run() -> void:
	lives           = MAX_LIVES
	gems            = 0
	health          = MAX_HEALTH
	staff_collected = [false, false, false, false]
	current_floor   = 1
	checkpoint_pos  = Vector2.ZERO
	checkpoint_scene_path = ""
	transition_spawn_pos = Vector2.ZERO
	transition_spawn_scene_path = ""
	stage_entry_spawns.clear()
	death_respawn_pos = Vector2.ZERO
	death_respawn_scene_path = ""
	has_key         = false
	collected_keys_by_scene.clear()
	is_game_over    = false
	emit_signal("health_changed", health, MAX_HEALTH)
	emit_key_progress_changed()
	emit_staff_progress_changed()

# --- Lives ---
func add_life(amount: int = 1) -> void:
	lives = min(lives + amount, 9)
	emit_signal("lives_changed", lives)

func lose_life() -> void:
	lives -= 1
	emit_signal("lives_changed", lives)
	if lives <= 0:
		emit_signal("game_over")

# --- Gems ---
func add_gems(amount: int) -> void:
	gems += amount
	emit_signal("gems_changed", gems)

func spend_gems(amount: int) -> bool:
	if gems >= amount:
		gems -= amount
		emit_signal("gems_changed", gems)
		return true
	return false

# --- Health ---
func take_damage(amount: int = 1) -> void:
	if is_game_over:
		return
	health = max(health - amount, 0)
	emit_signal("health_changed", health, MAX_HEALTH)
	if health <= 0:
		_on_player_died()

func heal(amount: int = 1) -> void:
	# Healing a full heart = +1 life if already at max health
	if health >= MAX_HEALTH:
		add_life(1)
	else:
		health = min(health + amount, MAX_HEALTH)
		emit_signal("health_changed", health, MAX_HEALTH)

func restore_full_health() -> void:
	health = MAX_HEALTH
	emit_signal("health_changed", health, MAX_HEALTH)

func is_at_full_health() -> bool:
	return health >= MAX_HEALTH

# --- Staff Pieces (0-indexed: piece 1 = index 0, etc.) ---
func collect_staff_piece(index: int) -> void:
	if index < 0 or index >= STAFF_PIECES:
		return
	if not staff_collected[index]:
		staff_collected[index] = true
		emit_signal("staff_piece_collected", index)
	emit_staff_progress_changed()

func has_staff_piece_collected(piece_index: int) -> bool:
	if piece_index < 0 or piece_index >= STAFF_PIECES:
		return false
	return staff_collected[piece_index]

func get_staff_piece_index_for_scene(scene_path: String = "") -> int:
	var resolved_path := _resolve_scene_path(scene_path)
	return STAGE_STAFF_PIECE_BY_SCENE.get(resolved_path, -1)

func has_staff_piece_for_scene(scene_path: String = "") -> bool:
	var piece_index := get_staff_piece_index_for_scene(scene_path)
	if piece_index < 0:
		return true
	return has_staff_piece_collected(piece_index)

func has_all_staff_pieces() -> bool:
	return staff_collected.all(func(p): return p == true)

func get_staff_collected_count() -> int:
	var count := 0
	for collected in staff_collected:
		if collected:
			count += 1
	return count

func emit_staff_progress_changed() -> void:
	emit_signal("staff_progress_changed", get_staff_collected_count(), STAFF_PIECES)

# --- Checkpoint ---
func set_checkpoint(pos: Vector2, scene_path: String = "") -> void:
	checkpoint_pos = pos
	checkpoint_scene_path = scene_path
	if checkpoint_scene_path == "" and get_tree().current_scene != null:
		checkpoint_scene_path = get_tree().current_scene.scene_file_path

func has_checkpoint() -> bool:
	return checkpoint_pos != Vector2.ZERO and checkpoint_scene_path != ""

func has_checkpoint_for_scene(scene_path: String) -> bool:
	return has_checkpoint() and checkpoint_scene_path == scene_path

func has_checkpoint_for_current_scene() -> bool:
	if get_tree().current_scene == null:
		return false

	return has_checkpoint_for_scene(get_tree().current_scene.scene_file_path)

func set_stage_entry_spawn(pos: Vector2, scene_path: String) -> void:
	var resolved_path := scene_path
	if resolved_path == "" and get_tree().current_scene != null:
		resolved_path = get_tree().current_scene.scene_file_path
	if resolved_path == "":
		return
	stage_entry_spawns[resolved_path] = pos

func has_stage_entry_spawn(scene_path: String = "") -> bool:
	var resolved_path := _resolve_scene_path(scene_path)
	return stage_entry_spawns.has(resolved_path)

func get_stage_entry_spawn(scene_path: String = "") -> Vector2:
	var resolved_path := _resolve_scene_path(scene_path)
	return stage_entry_spawns.get(resolved_path, Vector2.ZERO)

func register_stage_entry_spawn(pos: Vector2, scene_path: String = "") -> void:
	var resolved_path := _resolve_scene_path(scene_path)
	if resolved_path == "":
		return
	if not stage_entry_spawns.has(resolved_path):
		stage_entry_spawns[resolved_path] = pos

func get_trap_respawn_position(scene_path: String = "") -> Vector2:
	var resolved_path := _resolve_scene_path(scene_path)
	if has_checkpoint_for_scene(resolved_path):
		return checkpoint_pos
	if has_stage_entry_spawn(resolved_path):
		return get_stage_entry_spawn(resolved_path)
	if STAGE_DEFAULT_ENTRY_SPAWNS.has(resolved_path):
		return STAGE_DEFAULT_ENTRY_SPAWNS[resolved_path]
	return Vector2.ZERO

func prepare_death_respawn(scene_path: String = "") -> void:
	var resolved_path := _resolve_scene_path(scene_path)
	death_respawn_scene_path = resolved_path
	if has_checkpoint_for_scene(resolved_path):
		death_respawn_pos = checkpoint_pos
	elif has_stage_entry_spawn(resolved_path):
		death_respawn_pos = get_stage_entry_spawn(resolved_path)
	else:
		death_respawn_pos = Vector2.ZERO

func consume_death_respawn(scene_path: String = "") -> Vector2:
	var resolved_path := _resolve_scene_path(scene_path)
	if death_respawn_scene_path != resolved_path:
		return Vector2.ZERO

	var spawn_pos := death_respawn_pos
	death_respawn_pos = Vector2.ZERO
	death_respawn_scene_path = ""
	return spawn_pos

func set_transition_spawn(pos: Vector2, scene_path: String) -> void:
	transition_spawn_pos = pos
	transition_spawn_scene_path = scene_path

func consume_transition_spawn(scene_path: String) -> Vector2:
	if transition_spawn_scene_path != scene_path:
		return Vector2.ZERO

	var spawn_pos := transition_spawn_pos
	transition_spawn_pos = Vector2.ZERO
	transition_spawn_scene_path = ""
	if spawn_pos != Vector2.ZERO:
		stage_entry_spawns[scene_path] = spawn_pos
	return spawn_pos

# --- Keys ---
func collect_key(scene_path: String = "", key_id: int = 0) -> void:
	var key_scene_path := _resolve_scene_path(scene_path)
	if key_scene_path == "":
		return

	if not collected_keys_by_scene.has(key_scene_path):
		collected_keys_by_scene[key_scene_path] = []
	var collected: Array = collected_keys_by_scene[key_scene_path]
	if key_id in collected:
		return

	collected.append(key_id)
	has_key = true
	emit_key_progress_changed(key_scene_path)

func is_key_collected(key_id: int, scene_path: String = "") -> bool:
	var key_scene_path := _resolve_scene_path(scene_path)
	if key_scene_path == "":
		return false

	var stored = collected_keys_by_scene.get(key_scene_path, [])
	if stored is bool:
		return stored
	if stored is Array:
		return key_id in stored
	return false

func get_key_count_for_scene(scene_path: String = "") -> int:
	var key_scene_path := _resolve_scene_path(scene_path)
	if key_scene_path == "":
		return 0

	var stored = collected_keys_by_scene.get(key_scene_path, [])
	if stored is bool:
		return 1 if stored else 0
	if stored is Array:
		return stored.size()
	return 0

func has_key_for_scene(scene_path: String = "") -> bool:
	return get_key_count_for_scene(scene_path) >= 1

func has_minimum_keys_for_scene(min_count: int, scene_path: String = "") -> bool:
	return get_key_count_for_scene(scene_path) >= min_count

func get_key_total_for_scene(scene_path: String = "") -> int:
	var key_scene_path := _resolve_scene_path(scene_path)
	if key_scene_path == "":
		return 0
	return SCENE_KEY_TOTALS.get(key_scene_path, 0)

func get_key_unlock_info(key_id: int, scene_path: String = "") -> Dictionary:
	var key_scene_path := _resolve_scene_path(scene_path)
	if key_scene_path == "res://scenes/Scene 4.tscn" and SCENE_4_KEY_UNLOCK_INFO.has(key_id):
		return SCENE_4_KEY_UNLOCK_INFO[key_id]
	return {}

func get_key_progress(scene_path: String = "") -> int:
	return get_key_count_for_scene(scene_path)

func emit_key_progress_changed(scene_path: String = "") -> void:
	var key_scene_path := _resolve_scene_path(scene_path)
	emit_signal(
		"key_progress_changed",
		get_key_count_for_scene(key_scene_path),
		get_key_total_for_scene(key_scene_path)
	)

func _resolve_scene_path(scene_path: String = "") -> String:
	if scene_path != "":
		return scene_path
	if get_tree().current_scene != null:
		return get_tree().current_scene.scene_file_path
	return ""

# --- Floor Transition ---
func next_floor() -> void:
	current_floor += 1
	has_key = false
	if current_floor > TOTAL_FLOORS:
		emit_signal("game_won")
		return
	var scene_path := FLOOR_SCENES[current_floor - 1]
	get_tree().change_scene_to_file(scene_path)

func go_to_floor(floor_num: int) -> void:
	current_floor = floor_num
	has_key = false
	var scene_path := FLOOR_SCENES[clamp(floor_num - 1, 0, FLOOR_SCENES.size() - 1)]
	get_tree().change_scene_to_file(scene_path)

# --- Internal ---
func _on_player_died() -> void:
	if is_game_over:
		return
	is_game_over = true
	emit_signal("game_over")
