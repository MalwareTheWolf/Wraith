@tool
class_name MapNode
extends Control

# Scene this node represents.
@export_file("*.tscn") var linked_scene: String = ""

# Display info.
@export var display_name: String = ""
@export var region_name: String = "wraith_woods"

@export var hide_until_discovered: bool = true
@export var show_label_in_game: bool = false

# Toggle auto-generation
@export var auto_generate_openings: bool = true

# Manual openings fallback
@export_group("Manual Openings")
@export var openings_top: Array[float] = []
@export var openings_right: Array[float] = []
@export var openings_bottom: Array[float] = []
@export var openings_left: Array[float] = []

# Colors
@export_group("Colors")
@export var default_fill_color: Color = Color("000000")
@export var default_border_color: Color = Color("ffffff")
@export var current_fill_color: Color = Color("5a1f72")
@export var current_border_color: Color = Color("ff7cff")

# Internal
var label: Label
var transition_blocks: Control

var room_fill_color: Color
var room_border_color: Color
var is_current_room: bool = false

const SCALE_FACTOR := 40.0
var indicator_offset := Vector2.ZERO



#READY

func _ready() -> void:
	ensure_minimum_nodes()

	if Engine.is_editor_hint():
		if label:
			label.visible = false
		update_from_scene()
		create_transition_blocks()
		queue_redraw()
		return

	refresh_node()



#SETUP

func ensure_minimum_nodes() -> void:

	if not has_node("Label"):
		var l := Label.new()
		l.name = "Label"
		add_child(l)

	if not has_node("TransitionBlocks"):
		var t := Control.new()
		t.name = "TransitionBlocks"
		add_child(t)

	label = get_node("Label") as Label
	transition_blocks = get_node("TransitionBlocks") as Control



#PATH HELPERS

# Returns a real res:// path even if linked_scene is stored as uid://
func get_scene_path() -> String:

	if linked_scene == "":
		return ""

	if linked_scene.begins_with("uid://"):
		var uid_id: int = ResourceUID.text_to_id(linked_scene)
		if uid_id != -1:
			var resolved_path: String = ResourceUID.get_id_path(uid_id)
			if resolved_path != "":
				return resolved_path

	return linked_scene



#SCENE READ

func update_from_scene() -> void:

	if not auto_generate_openings:
		return

	var scene_path: String = get_scene_path()
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return

	var transitions: Array = []
	var new_size: Vector2 = size

	var packed := load(scene_path) as PackedScene
	if packed == null:
		return

	var inst := packed.instantiate()
	if inst == null:
		return

	for c in inst.get_children():
		if c.get_class() == "LevelBounds":
			new_size = Vector2(c.width, c.height) / SCALE_FACTOR
			indicator_offset = c.position

		if c.get_class() == "LevelTransition":
			transitions.append(c)

	inst.queue_free()

	size = new_size.round()
	generate_openings_from_transitions(transitions)



#AUTO OPENINGS

func generate_openings_from_transitions(transitions: Array) -> void:

	openings_top.clear()
	openings_right.clear()
	openings_bottom.clear()
	openings_left.clear()

	for t in transitions:
		var pos: Vector2 = (t.position - indicator_offset) / SCALE_FACTOR

		match t.location:
			t.SIDE.LEFT:
				openings_left.append(pos.y)
			t.SIDE.RIGHT:
				openings_right.append(pos.y)
			t.SIDE.TOP:
				openings_top.append(pos.x)
			t.SIDE.BOTTOM:
				openings_bottom.append(pos.x)



#REFRESH

func refresh_node() -> void:

	update_from_scene()

	var current_scene := get_tree().current_scene.scene_file_path
	var scene_path: String = get_scene_path()
	is_current_room = (current_scene == scene_path)

	var discovered := SaveManager.is_area_discovered(scene_path)

	room_fill_color = default_fill_color
	room_border_color = default_border_color

	visible = not hide_until_discovered or discovered

	if label:
		label.visible = false

	create_transition_blocks()
	queue_redraw()



#DRAW

func _draw() -> void:

	var rect := Rect2(Vector2.ZERO, size)

	var fill := room_fill_color
	var border := room_border_color

	if is_current_room:
		fill = current_fill_color
		border = current_border_color

	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 1.0)



#OPENINGS DRAW

func create_transition_blocks() -> void:

	if not transition_blocks:
		return

	for c in transition_blocks.get_children():
		c.queue_free()

	for t in openings_left:
		var b := add_block()
		b.size = Vector2(2, 6)
		b.position = Vector2(-1, t - 3)

	for t in openings_right:
		var b := add_block()
		b.size = Vector2(2, 6)
		b.position = Vector2(size.x - 1, t - 3)

	for t in openings_top:
		var b := add_block()
		b.size = Vector2(6, 2)
		b.position = Vector2(t - 3, -1)

	for t in openings_bottom:
		var b := add_block()
		b.size = Vector2(6, 2)
		b.position = Vector2(t - 3, size.y - 1)



func add_block() -> ColorRect:
	var b := ColorRect.new()
	b.color = room_fill_color
	transition_blocks.add_child(b)
	return b
