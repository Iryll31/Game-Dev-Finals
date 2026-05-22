## GameManager.gd
## Autoload singleton — add to Project > Project Settings > Autoload as "GameManager"
## Tracks global state: lives, gems, staff pieces, current floor, checkpoints.

extends Node

signal lives_changed(new_lives: int)
signal gems_changed(new_gems: int)
signal staff_piece_collected(piece_index: int)
signal health_changed(new_hp: int, max_hp: int)
signal key_progress_changed(collected: int, total: int)
signal game_over
signal game_won

# --- Constants ---
const MAX_LIVES       : int = 3
const MAX_HEALTH      : int = 5
const STAFF_PIECES    : int = 4
const TOTAL_FLOORS    : int = 6  # 5 normal + 1 boss

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
var has_key        : bool = false
var collected_keys_by_scene: Dictionary = {}

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
	has_key         = false
	collected_keys_by_scene.clear()
	emit_signal("health_changed", health, MAX_HEALTH)
	emit_key_progress_changed()

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

# --- Staff Pieces (0-indexed: 0=Tip, 1=Orb, 2=Core, 3=Base) ---
func collect_staff_piece(index: int) -> void:
	if index < 0 or index >= STAFF_PIECES:
		return
	if not staff_collected[index]:
		staff_collected[index] = true
		emit_signal("staff_piece_collected", index)

func has_all_staff_pieces() -> bool:
	return staff_collected.all(func(p): return p == true)

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

func set_transition_spawn(pos: Vector2, scene_path: String) -> void:
	transition_spawn_pos = pos
	transition_spawn_scene_path = scene_path

func consume_transition_spawn(scene_path: String) -> Vector2:
	if transition_spawn_scene_path != scene_path:
		return Vector2.ZERO

	var spawn_pos := transition_spawn_pos
	transition_spawn_pos = Vector2.ZERO
	transition_spawn_scene_path = ""
	return spawn_pos

# --- Keys ---
func collect_key(scene_path: String = "") -> void:
	var key_scene_path := _resolve_scene_path(scene_path)
	if key_scene_path == "":
		return

	collected_keys_by_scene[key_scene_path] = true
	has_key = true
	emit_key_progress_changed(key_scene_path)

func has_key_for_scene(scene_path: String = "") -> bool:
	var key_scene_path := _resolve_scene_path(scene_path)
	if key_scene_path == "":
		return false

	return collected_keys_by_scene.get(key_scene_path, false)

func get_key_progress(scene_path: String = "") -> int:
	return 1 if has_key_for_scene(scene_path) else 0

func emit_key_progress_changed(scene_path: String = "") -> void:
	emit_signal("key_progress_changed", get_key_progress(scene_path), 1)

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
	# Restore health, lose a life, respawn at last checkpoint
	health = MAX_HEALTH
	emit_signal("health_changed", health, MAX_HEALTH)
	lose_life()
	# The Player node listens to "game_over" signal; if lives > 0, respawn.
