extends Node

# Handles saving, loading, and restoring player progress.
# Supports multiple save slots, abilities, discovered areas, and config.


#CONSTANTS

# Path for configuration settings file.
const CONFIG_FILE_PATH = "user://settings.cfg"

# Default scene loaded for new games.
const DEFAULT_SCENE_PATH: String = "res://World/00_Void/01.tscn"

# Available save slots.
const SLOTS: Array[String] = ["save_01", "save_02", "save_03"]



#RUNTIME DATA

# Currently selected save slot index.
var current_slot: int = 0

# Dictionary storing all save data.
var save_data: Dictionary

# List of discovered scene IDs.
var discovered_areas: Array = []

# Persistent data for world objects.
var persistent_data: Dictionary = {}



#LIFECYCLE

func _ready() -> void:

	# Load config and track scene changes.
	load_configuration()
	SceneManager.scene_entered.connect(_on_scene_entered)

	set_process_input(true)



#DEBUG INPUT

func _input(event: InputEvent) -> void:

	# Debug shortcuts for saving/loading and slot selection.
	if OS.is_debug_build() and event is InputEventKey and event.pressed:

		match event.keycode:

			KEY_F5:
				save_game()

			KEY_F7:
				load_game()

			KEY_1:
				current_slot = 0
				print("Current slot:", current_slot)

			KEY_2:
				current_slot = 1
				print("Current slot:", current_slot)

			KEY_3:
				current_slot = 2
				print("Current slot:", current_slot)



#NEW GAME

# Creates a new save file with default values.
func create_new_game_save(slot: int = 0) -> void:

	current_slot = slot

	discovered_areas.clear()
	persistent_data.clear()

	# Start with default scene discovered.
	discovered_areas.append(DEFAULT_SCENE_PATH)

	# Initialize save data.
	save_data = {
		"scene_path": DEFAULT_SCENE_PATH,
		"x": 100.0,
		"y": -80.0,
		"hp": 20.0,
		"max_hp": 20.0,
		"dash": false,
		"double_jump": false,
		"lightning": false,
		"Chain_lightning": false,
		"dark_blast": false,
		"heavy_attack": false,
		"power_up": false,
		"ground_slam": false,
		"morph": false,
		"spell2": false,
		"spell3": false,
		"spell4": false,
		"spell5": false,
		"spell6": false,
		"spell7": false,
		"spell8": false,
		"discovered_areas": discovered_areas,
		"persistent_data": persistent_data
	}

	write_to_save_file()

	# Immediately load new save.
	load_game()

	print("Created new game save at slot:", current_slot)



#SAVE / LOAD

# Saves current player and world state.
func save_game() -> void:

	var player: Player = get_tree().get_first_node_in_group("Player")

	if player == null:
		print("No player found")
		return

	# Collect player data.
	save_data = {
		"scene_path": SceneManager.current_scene_uid,
		"x": player.global_position.x,
		"y": player.global_position.y,
		"hp": player.hp,
		"max_hp": player.max_hp,
		"dash": player.dash,
		"double_jump": player.double_jump,
		"lightning": player.lightning,
		"Chain_lightning": player.Chain_lightning,
		"dark_blast": player.dark_blast,
		"heavy_attack": player.heavy_attack,
		"power_up": player.power_up,
		"ground_slam": player.ground_slam,
		"morph": player.morph,
		"spell2": player.spell2,
		"spell3": player.spell3,
		"spell4": player.spell4,
		"spell5": player.spell5,
		"spell6": player.spell6,
		"spell7": player.spell7,
		"spell8": player.spell8,
		"discovered_areas": discovered_areas,
		"persistent_data": persistent_data
	}

	write_to_save_file()

	print("Game saved to slot:", current_slot)



# Loads save file and restores state.
func load_game() -> void:

	if not FileAccess.file_exists(get_file_name()):
		print("No save file found at slot:", current_slot)
		return

	var save_file = FileAccess.open(get_file_name(), FileAccess.READ)

	save_data = JSON.parse_string(save_file.get_line())

	# Restore world data.
	discovered_areas = save_data.get("discovered_areas", [])
	persistent_data = save_data.get("persistent_data", {})

	var scene_path: String = save_data.get("scene_path", DEFAULT_SCENE_PATH)

	# Load scene and wait until ready.
	SceneManager.transition_scene(scene_path, "", Vector2.ZERO, "up")
	await SceneManager.new_scene_ready

	setup_player()



#PLAYER RESTORE

# Applies saved data to player after scene loads.
func setup_player() -> void:

	var player: Player = null

	# Wait until player exists.
	while not player:
		player = get_tree().get_first_node_in_group("Player")
		await get_tree().process_frame

	# Restore stats and abilities.
	player.max_hp = save_data.get("max_hp", 20)
	player.hp = save_data.get("hp", 20)
	player.run = save_data.get("run", false)
	player.dash = save_data.get("dash", false)
	player.double_jump = save_data.get("double_jump", false)
	player.ground_slam = save_data.get("ground_slam", false)
	player.morph = save_data.get("morph", false)

	player.lightning = save_data.get("lightning", false)
	player.Chain_lightning = save_data.get("Chain_lightning", false)
	player.dark_blast = save_data.get("dark_blast", false)
	player.heavy_attack = save_data.get("heavy_attack", false)
	player.power_up = save_data.get("power_up", false)

	player.spell2 = save_data.get("spell2", false)
	player.spell3 = save_data.get("spell3", false)
	player.spell4 = save_data.get("spell4", false)
	player.spell5 = save_data.get("spell5", false)
	player.spell6 = save_data.get("spell6", false)
	player.spell7 = save_data.get("spell7", false)
	player.spell8 = save_data.get("spell8", false)

	# Restore position.
	player.global_position = Vector2(
		save_data.get("x", 0),
		save_data.get("y", 0)
	)

	print("Player restored at:", player.global_position)



#FILE HANDLING

# Returns file path for current slot.
func get_file_name() -> String:
	return "user://" + SLOTS[current_slot] + ".sav"


# Writes save data to disk.
func write_to_save_file() -> void:

	var save_file = FileAccess.open(get_file_name(), FileAccess.WRITE)

	save_file.store_line(JSON.stringify(save_data))
	save_file.close()


# Checks if a save file exists.
func save_file_exists(slot: int) -> bool:
	return FileAccess.file_exists("user://" + SLOTS[slot] + ".sav")



#DISCOVERED AREAS

# Tracks newly entered scenes.
func _on_scene_entered(scene_uid: String) -> void:

	if not discovered_areas.has(scene_uid):
		discovered_areas.append(scene_uid)


# Checks if a scene has been discovered.
func is_area_discovered(scene_uid: String) -> bool:
	return discovered_areas.has(scene_uid)



#CONFIGURATION

# Saves audio settings.
func save_configuration() -> void:

	var config := ConfigFile.new()

	config.set_value("audio", "music", AudioServer.get_bus_volume_linear(2))
	config.set_value("audio", "sfx", AudioServer.get_bus_volume_linear(3))
	config.set_value("audio", "ui", AudioServer.get_bus_volume_linear(4))

	config.save(CONFIG_FILE_PATH)


# Loads audio settings or sets defaults.
func load_configuration() -> void:

	var config := ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)

	# Use defaults if config missing.
	if err != OK:

		AudioServer.set_bus_volume_linear(2, 0.8)
		AudioServer.set_bus_volume_linear(3, 1.0)
		AudioServer.set_bus_volume_linear(4, 1.0)

		save_configuration()
		return

	# Apply saved values.
	AudioServer.set_bus_volume_linear(2, config.get_value("audio", "music", 0.8))
	AudioServer.set_bus_volume_linear(3, config.get_value("audio", "sfx", 1.0))
	AudioServer.set_bus_volume_linear(4, config.get_value("audio", "ui", 1.0))
