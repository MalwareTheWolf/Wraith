class_name MapPage
extends Control

# Main labels and map area.
@onready var region_label: Label = $RegionLabel
@onready var room_label: Label = $RoomLabel
@onready var map_panel: Control = $MapPanel
@onready var map_container: Control = $MapPanel/MapContainer
@onready var player_indicator: Control = $MapPanel/PlayerIndicator

# Manual adjustment for the indicator.
@export var indicator_offset: Vector2 = Vector2.ZERO



#LIFECYCLE

func _ready() -> void:
	player_indicator.visible = false



#MAP REFRESH

# Refreshes all map room nodes and labels.
func refresh_page() -> void:
	player_indicator.visible = false

	var current_scene_path: String = ""
	var current_scene_uid: String = ""
	var current_node: MapNode = null

	if get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path

	current_scene_uid = SceneManager.current_scene_uid

	for child in map_container.get_children():
		if child is MapNode:
			var room_node: MapNode = child as MapNode
			room_node.refresh_node()

			if room_node.linked_scene == current_scene_uid:
				current_node = room_node
			elif room_node.get_scene_path() == current_scene_path:
				current_node = room_node

	if current_node:
		room_label.text = get_room_display_name(current_node)
		region_label.text = format_region_name(current_node.region_name)
		move_player_indicator_to_room(current_node)
	else:
		room_label.text = "Unknown"
		region_label.text = ""



#INDICATOR

# Places the indicator at the player's real position inside the current room.
func move_player_indicator_to_room(room_node: MapNode) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("Player") as Node2D

	if player == null:
		player_indicator.visible = false
		return

	player_indicator.position = room_node.get_player_marker_position(
		player.global_position,
		player_indicator.size
	) + indicator_offset

	player_indicator.visible = true



#HELPERS

# Gets the display name for the current room.
func get_room_display_name(room_node: MapNode) -> String:
	if room_node.display_name.strip_edges() != "":
		return room_node.display_name

	var scene_path: String = room_node.get_scene_path()

	if scene_path == "":
		return "Unknown"

	return format_region_name(scene_path.get_file().trim_suffix(".tscn"))


# Formats region name for display.
func format_region_name(value: String) -> String:
	if value == "":
		return ""

	var parts: PackedStringArray = value.replace("_", " ").split(" ")
	var result: Array[String] = []

	for part in parts:
		result.append(part.capitalize())

	return " ".join(result)
