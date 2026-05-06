extends Node

# Handles saving, loading, and restoring player progress.


# CONSTANTS

const CONFIG_FILE_PATH = "user://settings.cfg"
const DEFAULT_SCENE_PATH: String = "uid://cnlg81cbb56ha"
const SLOTS: Array[String] = ["save_01", "save_02", "save_03"]


# RUNTIME DATA

var current_slot: int = 0
var save_data: Dictionary

var discovered_areas: Array = []
var persistent_data: Dictionary = {}


# INITIALIZATION

# Loads config and connects scene tracking.
func _ready() -> void:
	load_configuration()
	SceneManager.scene_entered.connect(_on_scene_entered)


# NEW GAME

# Creates a new save with all abilities unlocked.
func create_new_game_save(slot: int = 0) -> void:

	current_slot = slot

	discovered_areas.clear()
	persistent_data.clear()

	discovered_areas.append(DEFAULT_SCENE_PATH)

	save_data = {
		"scene_path": DEFAULT_SCENE_PATH,
		"x": 100.0,
		"y": -80.0,
		"hp": 20.0,
		"max_hp": 20.0,

		"run": true,
		"dash": true,
		"double_jump": true,
		"ground_slam": true,
		"morph": true,
		"power_up": true,

		"discovered_areas": discovered_areas,
		"persistent_data": persistent_data
	}

	write_to_save_file()
	load_game()


# SAVE GAME

# Saves player position, stats, and abilities.
func save_game() -> void:

	var player: Player = get_tree().get_first_node_in_group("Player")

	if player == null:
		return

	save_data = {
		"scene_path": SceneManager.current_scene_uid,
		"x": player.global_position.x,
		"y": player.global_position.y,
		"hp": player.hp,
		"max_hp": player.max_hp,

		"run": player.run,
		"dash": player.dash,
		"double_jump": player.double_jump,
		"ground_slam": player.ground_slam,
		"morph": player.morph,
		"power_up": player.power_up,

		"discovered_areas": discovered_areas,
		"persistent_data": persistent_data
	}

	write_to_save_file()


# LOAD GAME

# Loads saved scene and restores player state.
func load_game() -> void:

	if not FileAccess.file_exists(get_file_name()):
		return

	var save_file = FileAccess.open(get_file_name(), FileAccess.READ)
	save_data = JSON.parse_string(save_file.get_line())

	discovered_areas = save_data.get("discovered_areas", [])
	persistent_data = save_data.get("persistent_data", {})

	var scene_path: String = save_data.get("scene_path", DEFAULT_SCENE_PATH)

	SceneManager.transition_scene(scene_path, "", Vector2.ZERO, "up")
	await SceneManager.new_scene_ready

	setup_player()


# PLAYER RESTORE

# Applies saved values to player.
func setup_player() -> void:

	var player: Player = null

	while not player:
		player = get_tree().get_first_node_in_group("Player")
		await get_tree().process_frame

	player.max_hp = save_data.get("max_hp", 20)
	player.hp = save_data.get("hp", 20)

	player.run = true
	player.dash = true
	player.double_jump = true
	player.ground_slam = true
	player.morph = true
	player.power_up = true

	player.global_position = Vector2(
		save_data.get("x", 0),
		save_data.get("y", 0)
	)


# FILE HANDLING

# Returns save file path.
func get_file_name() -> String:
	return "user://" + SLOTS[current_slot] + ".sav"


# Writes save data to disk.
func write_to_save_file() -> void:

	var save_file = FileAccess.open(get_file_name(), FileAccess.WRITE)
	save_file.store_line(JSON.stringify(save_data))
	save_file.close()


# Checks if a save exists.
func save_file_exists(slot: int) -> bool:
	return FileAccess.file_exists("user://" + SLOTS[slot] + ".sav")


# DISCOVERY

# Tracks visited scenes.
func _on_scene_entered(scene_uid: String) -> void:

	if not discovered_areas.has(scene_uid):
		discovered_areas.append(scene_uid)


# FLAGS

# Checks if a persistent flag exists.
func has_flag(flag_id: String) -> bool:
	return persistent_data.get(flag_id, false)


# Sets a persistent flag.
func set_flag(flag_id: String, value: bool = true, save_after: bool = true) -> void:

	persistent_data[flag_id] = value

	if save_after:
		save_game()


# CONFIG

# Saves audio config.
func save_configuration() -> void:

	var config := ConfigFile.new()

	config.set_value("audio", "music", AudioServer.get_bus_volume_linear(2))
	config.set_value("audio", "sfx", AudioServer.get_bus_volume_linear(3))
	config.set_value("audio", "ui", AudioServer.get_bus_volume_linear(4))

	config.save(CONFIG_FILE_PATH)


# Loads audio config.
func load_configuration() -> void:

	var config := ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)

	if err != OK:
		AudioServer.set_bus_volume_linear(2, 0.8)
		AudioServer.set_bus_volume_linear(3, 1.0)
		AudioServer.set_bus_volume_linear(4, 1.0)
		save_configuration()
		return

	AudioServer.set_bus_volume_linear(2, config.get_value("audio", "music", 0.8))
	AudioServer.set_bus_volume_linear(3, config.get_value("audio", "sfx", 1.0))
	AudioServer.set_bus_volume_linear(4, config.get_value("audio", "ui", 1.0))
