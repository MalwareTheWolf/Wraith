@tool
class_name MapNode
extends Control

# Scale used to convert world pixel size into map size.
@export var map_scale: float = 12.0

# Scene this node represents.
@export_file("*.tscn") var linked_scene: String = "" : set = set_linked_scene

# Display info.
@export var display_name: String = ""
@export var region_name: String = "wraith_woods"

# Visibility / labels.
@export var hide_until_discovered: bool = false
@export var show_label_in_game: bool = false

# Tool button.
@export_tool_button("Update") var update_node_action = update_node

# Auto-generated openings.
@export_group("Openings")
@export var openings_top: Array[float] = []
@export var openings_right: Array[float] = []
@export var openings_bottom: Array[float] = []
@export var openings_left: Array[float] = []

# Colors.
@export_group("Colors")
@export var default_fill_color: Color = Color("000000")
@export var default_border_color: Color = Color("ffffff")
@export var current_fill_color: Color = Color("5a1f72")
@export var current_border_color: Color = Color("ff7cff")

# Scene-derived data used for sizing and player marker positioning.
var scene_offset: Vector2 = Vector2.ZERO
var resolved_scene_path: String = ""

# Internal refs.
var label: Label
var transition_blocks: Control

# Current state.
var is_current_room: bool = false



#LIFECYCLE

func _ready() -> void:
	ensure_minimum_nodes()

	if Engine.is_editor_hint():
		if label:
			label.visible = true
		update_node()
		return

	refresh_node()



#SETUP

func ensure_minimum_nodes() -> void:
	if not has_node("Label"):
		var l: Label = Label.new()
		l.name = "Label"
		add_child(l)

	if not has_node("TransitionBlocks"):
		var t: Control = Control.new()
		t.name = "TransitionBlocks"
		add_child(t)

	label = get_node("Label") as Label
	transition_blocks = get_node("TransitionBlocks") as Control



#SETTERS

func set_linked_scene(value: String) -> void:
	if linked_scene == value:
		return

	linked_scene = value

	if Engine.is_editor_hint():
		update_node()



#PATH HELPERS

func get_scene_path() -> String:
	if linked_scene == "":
		return ""

	if linked_scene.begins_with("uid://"):
		var uid_id: int = ResourceUID.text_to_id(linked_scene)
		if uid_id != -1:
			var path: String = ResourceUID.get_id_path(uid_id)
			if path != "":
				return path

	return linked_scene


func get_scene_uid() -> String:
	return linked_scene



#REFRESH

# Refreshes visual state for runtime.
func refresh_node() -> void:
	resolved_scene_path = get_scene_path()

	var current_scene_path: String = ""
	if get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path

	var current_scene_uid: String = SceneManager.current_scene_uid

	is_current_room = false

	if linked_scene != "" and current_scene_uid != "" and linked_scene == current_scene_uid:
		is_current_room = true
	elif resolved_scene_path != "" and resolved_scene_path == current_scene_path:
		is_current_room = true

	if hide_until_discovered:
		var discovered: bool = false

		if linked_scene != "":
			discovered = SaveManager.is_area_discovered(linked_scene)

		if not discovered and resolved_scene_path != "":
			discovered = SaveManager.is_area_discovered(resolved_scene_path)

		visible = discovered
	else:
		visible = true

	if label:
		label.visible = show_label_in_game and visible
		update_node_label_text()

	create_transition_blocks()
	queue_redraw()



#NODE DATA BUILD

# Reads the linked level scene and rebuilds this map node from it.
func update_node() -> void:
	ensure_minimum_nodes()

	resolved_scene_path = get_scene_path()

	var new_size: Vector2 = Vector2(480, 270)
	var transitions: Array[LevelTransition] = []

	scene_offset = Vector2.ZERO

	if resolved_scene_path != "" and ResourceLoader.exists(resolved_scene_path):
		var packed_scene: PackedScene = ResourceLoader.load(resolved_scene_path) as PackedScene

		if packed_scene:
			var instance: Node = packed_scene.instantiate()

			if instance:
				update_node_label_from_scene(instance)

				var bounds: LevelBounds = find_level_bounds(instance)
				if bounds:
					new_size = Vector2(bounds.width, bounds.height)
					scene_offset = bounds.global_position

				find_level_transitions(instance, transitions)

				instance.queue_free()

	size = (new_size / map_scale).round()
	create_opening_data(transitions)

	if label:
		label.visible = Engine.is_editor_hint() or show_label_in_game
		update_node_label_text()

	create_transition_blocks()
	queue_redraw()



#SCENE SEARCH

# Finds the first LevelBounds anywhere in the scene tree.
func find_level_bounds(root: Node) -> LevelBounds:
	if root is LevelBounds:
		return root

	for child in root.get_children():
		var found: LevelBounds = find_level_bounds(child)
		if found:
			return found

	return null


# Collects all LevelTransition nodes anywhere in the scene tree.
func find_level_transitions(root: Node, results: Array[LevelTransition]) -> void:
	if root is LevelTransition:
		results.append(root)

	for child in root.get_children():
		find_level_transitions(child, results)



#LABELS

# Updates the display label from the linked scene.
func update_node_label_from_scene(scene: Node) -> void:
	if not label:
		return

	if display_name.strip_edges() != "":
		label.text = display_name
		return

	var t: String = scene.scene_file_path
	t = t.get_file().trim_suffix(".tscn")
	label.text = prettify_name(t)


# Updates the label text without needing a scene instance.
func update_node_label_text() -> void:
	if not label:
		return

	if display_name.strip_edges() != "":
		label.text = display_name
		return

	var scene_path: String = get_scene_path()

	if scene_path == "":
		label.text = "Unassigned"
		return

	label.text = prettify_name(scene_path.get_file().trim_suffix(".tscn"))



#OPENING DATA

# Builds opening positions from level transitions.
func create_opening_data(transitions: Array[LevelTransition]) -> void:
	openings_top.clear()
	openings_right.clear()
	openings_bottom.clear()
	openings_left.clear()

	for t in transitions:
		var local_pos: Vector2 = (t.global_position - scene_offset) / map_scale

		if t.location == LevelTransition.SIDE.LEFT:
			var offset_left: float = clampf(local_pos.y - 3.0, 2.0, size.y - 5.0)
			openings_left.append(offset_left)

		elif t.location == LevelTransition.SIDE.RIGHT:
			var offset_right: float = clampf(local_pos.y - 3.0, 2.0, size.y - 5.0)
			openings_right.append(offset_right)

		elif t.location == LevelTransition.SIDE.TOP:
			var offset_top: float = clampf(local_pos.x, 2.0, size.x - 5.0)
			openings_top.append(offset_top)

		elif t.location == LevelTransition.SIDE.BOTTOM:
			var offset_bottom: float = clampf(local_pos.x, 2.0, size.x - 5.0)
			openings_bottom.append(offset_bottom)



#DRAW

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)

	draw_rect(rect, get_fill_color(), true)
	draw_rect(rect, get_border_color(), false, 1.0)


func get_fill_color() -> Color:
	if is_current_room:
		return current_fill_color

	return default_fill_color


func get_border_color() -> Color:
	if is_current_room:
		return current_border_color

	return default_border_color



#OPENINGS DRAW

# Creates small blocks that visually cut openings into the room outline.
func create_transition_blocks() -> void:
	if not transition_blocks:
		return

	for c in transition_blocks.get_children():
		c.queue_free()

	var side_thickness: float = 1.0
	var opening_length: float = 3.0
	var block_color: Color = get_fill_color()

	for t in openings_left:
		var b_left: ColorRect = add_block(block_color)
		b_left.size = Vector2(side_thickness, opening_length)
		b_left.position = Vector2(0, t)

	for t in openings_right:
		var b_right: ColorRect = add_block(block_color)
		b_right.size = Vector2(side_thickness, opening_length)
		b_right.position = Vector2(size.x - side_thickness, t)

	for t in openings_top:
		var b_top: ColorRect = add_block(block_color)
		b_top.size = Vector2(opening_length, side_thickness)
		b_top.position = Vector2(t, 0)

	for t in openings_bottom:
		var b_bottom: ColorRect = add_block(block_color)
		b_bottom.size = Vector2(opening_length, side_thickness)
		b_bottom.position = Vector2(t, size.y - side_thickness)


func add_block(block_color: Color) -> ColorRect:
	var b: ColorRect = ColorRect.new()
	b.color = block_color
	transition_blocks.add_child(b)
	return b



#PLAYER MARKER

# Converts a world player position into a map-local position inside this room.
func get_player_marker_position(player_global_position: Vector2, marker_size: Vector2) -> Vector2:
	var local_pos: Vector2 = (player_global_position - scene_offset) / map_scale
	var map_pos: Vector2 = position + local_pos - (marker_size * 0.5)

	var padding: Vector2 = Vector2(2, 2)
	var min_pos: Vector2 = position + padding
	var max_pos: Vector2 = position + size - marker_size - padding

	map_pos.x = clampf(map_pos.x, min_pos.x, max_pos.x)
	map_pos.y = clampf(map_pos.y, min_pos.y, max_pos.y)

	return map_pos



#HELPERS

func prettify_name(value: String) -> String:
	var parts: PackedStringArray = value.replace("_", " ").split(" ")
	var result: Array[String] = []

	for part in parts:
		result.append(part.capitalize())

	return " ".join(result)
