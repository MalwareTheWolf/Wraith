extends Node

# SAVE MANAGER
# Handles:
# - Saving/loading game data
# - Persistent flags
# - Player setup
# - Area discovery
# - Audio settings


# FILE PATHS

const CONFIG_FILE_PATH = "user://settings.cfg"

const DEFAULT_SCENE_PATH: String = "uid://cnlg81cbb56ha"

const SLOTS: Array[String] = [
	"save_01",
	"save_02",
	"save_03"
]


# SAVE STATE

var current_slot: int = 0

var save_data: Dictionary = {}

var discovered_areas: Array = []

var persistent_data: Dictionary = {}


# READY

func _ready() -> void:
	load_configuration()

	SceneManager.scene_entered.connect(_on_scene_entered)


# NEW GAME

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

		# PLAYER ABILITIES
		"run": true,
		"dash": true,
		"double_jump": true,
		"power_up": true,
		"ground_slam": true,
		"morph": true,

		# WORLD DATA
		"discovered_areas": discovered_areas,
		"persistent_data": persistent_data
	}

	write_to_save_file()

	load_game()


# SAVE GAME

func save_game() -> void:
	var player: Player = get_tree().get_first_node_in_group("Player")

	if player == null:
		return

	save_data = {
		# SCENE
		"scene_path": SceneManager.current_scene_uid,

		# PLAYER POSITION
		"x": player.global_position.x,
		"y": player.global_position.y,

		# PLAYER STATS
		"hp": player.hp,
		"max_hp": player.max_hp,

		# PLAYER ABILITIES
		"run": player.run,
		"dash": player.dash,
		"double_jump": player.double_jump,
		"power_up": player.power_up,
		"ground_slam": player.ground_slam,
		"morph": player.morph,

		# WORLD DATA
		"discovered_areas": discovered_areas,
		"persistent_data": persistent_data
	}

	write_to_save_file()


# LOAD GAME

func load_game() -> void:
	if not FileAccess.file_exists(get_file_name()):
		return

	var save_file = FileAccess.open(get_file_name(), FileAccess.READ)

	save_data = JSON.parse_string(save_file.get_line())

	discovered_areas = save_data.get("discovered_areas", [])

	persistent_data = save_data.get("persistent_data", {})

	var scene_path: String = save_data.get(
		"scene_path",
		DEFAULT_SCENE_PATH
	)

	SceneManager.transition_scene(
		scene_path,
		"",
		Vector2.ZERO,
		"up"
	)

	await SceneManager.new_scene_ready

	setup_player()


# PLAYER SETUP

func setup_player() -> void:
	var player: Player = null

	while not player:
		player = get_tree().get_first_node_in_group("Player")

		await get_tree().process_frame

	# PLAYER STATS

	player.max_hp = save_data.get("max_hp", 20)

	player.hp = save_data.get("hp", 20)

	# PLAYER ABILITIES

	player.run = save_data.get("run", true)

	player.dash = save_data.get("dash", true)

	player.double_jump = save_data.get("double_jump", true)

	player.power_up = save_data.get("power_up", true)

	player.ground_slam = save_data.get("ground_slam", true)

	player.morph = save_data.get("morph", true)

	# PLAYER POSITION

	player.global_position = Vector2(
		save_data.get("x", 0),
		save_data.get("y", 0)
	)


# SAVE FILE NAME

func get_file_name() -> String:
	return "user://" + SLOTS[current_slot] + ".sav"


# WRITE SAVE FILE

func write_to_save_file() -> void:
	var save_file = FileAccess.open(
		get_file_name(),
		FileAccess.WRITE
	)

	save_file.store_line(JSON.stringify(save_data))

	save_file.close()


# SAVE FILE EXISTS

func save_file_exists(slot: int) -> bool:
	return FileAccess.file_exists(
		"user://" + SLOTS[slot] + ".sav"
	)


# AREA DISCOVERY

func _on_scene_entered(scene_uid: String) -> void:
	if not discovered_areas.has(scene_uid):
		discovered_areas.append(scene_uid)


func is_area_discovered(scene_uid: String) -> bool:
	return discovered_areas.has(scene_uid)


# PERSISTENT FLAGS

func has_flag(flag_id: String) -> bool:
	if flag_id.strip_edges() == "":
		return false

	return persistent_data.get(flag_id, false)


func set_flag(
	flag_id: String,
	value: bool = true,
	save_after: bool = true
) -> void:

	if flag_id.strip_edges() == "":
		return

	persistent_data[flag_id] = value

	if save_after:
		save_game()


# AUDIO SETTINGS

func save_configuration() -> void:
	var config := ConfigFile.new()

	config.set_value(
		"audio",
		"music",
		AudioServer.get_bus_volume_linear(2)
	)

	config.set_value(
		"audio",
		"sfx",
		AudioServer.get_bus_volume_linear(3)
	)

	config.set_value(
		"audio",
		"ui",
		AudioServer.get_bus_volume_linear(4)
	)

	config.save(CONFIG_FILE_PATH)


func load_configuration() -> void:
	var config := ConfigFile.new()

	var err = config.load(CONFIG_FILE_PATH)

	# DEFAULT SETTINGS

	if err != OK:
		AudioServer.set_bus_volume_linear(2, 0.8)

		AudioServer.set_bus_volume_linear(3, 1.0)

		AudioServer.set_bus_volume_linear(4, 1.0)

		save_configuration()

		return

	# LOAD SAVED SETTINGS

	AudioServer.set_bus_volume_linear(
		2,
		config.get_value("audio", "music", 0.8)
	)

	AudioServer.set_bus_volume_linear(
		3,
		config.get_value("audio", "sfx", 1.0)
	)

	AudioServer.set_bus_volume_linear(
		4,
		config.get_value("audio", "ui", 1.0)
	)
