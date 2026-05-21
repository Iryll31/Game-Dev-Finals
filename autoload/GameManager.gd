## GameManager.gd
## Autoload singleton — add to Project > Project Settings > Autoload as "GameManager"
## Tracks global state: lives, gems, staff pieces, current floor, checkpoints.

extends Node

signal lives_changed(new_lives: int)
signal gems_changed(new_gems: int)
signal staff_piece_collected(piece_index: int)
signal key_changed(has_key: bool)
signal floor_exit_locked
signal floor_transition_started(floor_number: int)
signal health_changed(new_hp: int, max_hp: int)
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
var has_key        : bool = false
var is_transitioning: bool = false

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
	has_key         = false
	is_transitioning = false
	emit_signal("key_changed", has_key)

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

func collect_floor_key() -> void:
	if has_key:
		return
	has_key = true
	emit_signal("key_changed", has_key)

# --- Checkpoint ---
func set_checkpoint(pos: Vector2) -> void:
	checkpoint_pos = pos

# --- Floor Transition ---
func next_floor() -> void:
	current_floor += 1
	has_key = false
	emit_signal("key_changed", has_key)
	if current_floor > TOTAL_FLOORS:
		emit_signal("game_won")
		return
	var scene_path := FLOOR_SCENES[current_floor - 1]
	get_tree().change_scene_to_file(scene_path)

func go_to_floor(floor_num: int) -> void:
	current_floor = floor_num
	has_key = false
	emit_signal("key_changed", has_key)
	var scene_path := FLOOR_SCENES[clamp(floor_num - 1, 0, FLOOR_SCENES.size() - 1)]
	get_tree().change_scene_to_file(scene_path)

func can_exit_floor() -> bool:
	return has_key

func request_floor_exit() -> bool:
	if is_transitioning:
		return false
	if not can_exit_floor():
		emit_signal("floor_exit_locked")
		return false
	is_transitioning = true
	emit_signal("floor_transition_started", current_floor + 1)
	await get_tree().create_timer(0.85).timeout
	is_transitioning = false
	next_floor()
	return true

# --- Internal ---
func _on_player_died() -> void:
	# Restore health, lose a life, respawn at last checkpoint
	health = MAX_HEALTH
	emit_signal("health_changed", health, MAX_HEALTH)
	lose_life()
	# The Player node listens to "game_over" signal; if lives > 0, respawn.
