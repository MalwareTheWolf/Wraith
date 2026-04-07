class_name MapPage
extends Control

# Main labels and map area.
@onready var region_label: Label = $RegionLabel
@onready var room_label: Label = $RoomLabel
@onready var map_panel: Control = $MapPanel
@onready var map_container: Control = $MapPanel/MapContainer
@onready var player_indicator: Control = $MapPanel/PlayerIndicator



#LIFECYCLE

func _ready() -> void:
	player_indicator.visible = false



#MAP REFRESH

# Refreshes all map room nodes and labels.
func refresh_page() -> void:

	player_indicator.visible = false

	var current_scene_path: String = get_tree().current_scene.scene_file_path
	var current_node: MapNode = null

	for child in map_container.get_children():
		if child is MapNode:
			var resolved_scene_path: String = child.get_scene_path()
			child.refresh_node()

			if resolved_scene_path == current_scene_path:
				current_node = child

	if current_node:
		room_label.text = current_node.display_name if current_node.display_name != "" else current_node.get_scene_path().get_file().trim_suffix(".tscn")
		region_label.text = format_region_name(current_node.region_name)
		move_player_indicator_to_room(current_node)
	else:
		room_label.text = "Unknown"
		region_label.text = ""



#INDICATOR

# Moves the player indicator to the exact center of the room node.
func move_player_indicator_to_room(room_node: MapNode) -> void:

	var center: Vector2 = room_node.position + (room_node.size * 0.5)
	var indicator_size: Vector2 = player_indicator.size

	if indicator_size == Vector2.ZERO:
		indicator_size = Vector2(8, 8)

	player_indicator.position = center - (indicator_size * 0.5)
	player_indicator.visible = true



#HELPERS

# Formats region name for display.
func format_region_name(value: String) -> String:

	if value == "":
		return ""

	return value.replace("_", " ").capitalize()
