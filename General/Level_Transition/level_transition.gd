@icon("res://General/Icon/level_transition.svg")
@tool
class_name LevelTransition
extends Node2D

enum SIDE { LEFT, RIGHT, TOP, BOTTOM }

@export_range(2, 12, 1, "or_greater")
var size: int = 2:
	set(value):
		size = value
		apply_area_settings()

# Which side THIS door is on.
@export var location: SIDE = SIDE.LEFT:
	set(value):
		location = value
		apply_area_settings()

# Door number for this side.
# Leave at 0 if there is only one door on that side.
@export var door_id: int = 0

@export_file("*.tscn")
var target_level: String = ""

# Which side of the destination room to arrive at.
@export var target_side: SIDE = SIDE.LEFT

@onready var area_2d: Area2D = $Area2D

var is_transitioning: bool = false

const META_TRANSITION_LOCK := "scene_transition_locked"

const SIDE_ENTRY_OFFSET := 16.0
const TOP_ENTRY_OFFSET := 32.0
const BOTTOM_ENTRY_OFFSET := -6.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	SceneManager.new_scene_ready.connect(_on_new_scene_ready)
	SceneManager.load_scene_finished.connect(_on_load_scene_finished)

	if not area_2d.body_entered.is_connected(_on_body_entered):
		area_2d.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body == null:
		return

	if is_transitioning:
		return

	# Players and enemies are always allowed.
	if not body.is_in_group("Player") and not body.is_in_group("Enemies"):
		return

	if body.has_meta(META_TRANSITION_LOCK) and body.get_meta(META_TRANSITION_LOCK) == true:
		return

	if target_level.is_empty():
		push_warning("LevelTransition has no target_level set.")
		return

	# Let physics settle one frame for vertical checks.
	if location == SIDE.TOP or location == SIDE.BOTTOM:
		await get_tree().physics_frame

		if body == null or not is_instance_valid(body):
			return

	# Must be moving the correct way.
	if not _is_valid_entry_direction(body):
		return

	is_transitioning = true
	body.set_meta(META_TRANSITION_LOCK, true)

	var target_data := {
		"side": int(target_side),
		"door_id": door_id
	}

	SceneManager.transition_scene(
		target_level,
		target_data,
		get_parallel_offset(body),
		get_transition_direction(),
		body
	)


func _on_new_scene_ready(target_data: Variant, offset: Vector2, transition_body: Node2D) -> void:
	if typeof(target_data) != TYPE_DICTIONARY:
		return

	var wanted_side: int = int(target_data.get("side", -1))
	var wanted_door_id: int = int(target_data.get("door_id", -1))

	# Match destination by side + this door's own id.
	if location != wanted_side or door_id != wanted_door_id:
		return

	var body_to_move: Node2D = transition_body

	if body_to_move == null or not is_instance_valid(body_to_move):
		body_to_move = get_tree().get_first_node_in_group("Player") as Node2D

	var tries := 0
	while (body_to_move == null or not is_instance_valid(body_to_move)) and tries < 10:
		await get_tree().process_frame
		body_to_move = get_tree().get_first_node_in_group("Player") as Node2D
		tries += 1

	if body_to_move == null:
		push_warning("No valid body found for transition.")
		return

	var final_position := global_position + get_arrival_offset(offset)
	body_to_move.global_position = final_position


func _on_load_scene_finished() -> void:
	area_2d.monitoring = false

	await get_tree().physics_frame
	await get_tree().physics_frame

	area_2d.monitoring = true

	_unlock_transition_bodies()
	is_transitioning = false


func apply_area_settings() -> void:
	var a: Area2D = get_node_or_null("Area2D")
	if not a:
		return

	if location == SIDE.LEFT or location == SIDE.RIGHT:
		a.scale.y = size
		if location == SIDE.LEFT:
			a.scale.x = -1
		else:
			a.scale.x = 1
	else:
		a.scale.x = size
		if location == SIDE.TOP:
			a.scale.y = 1
		else:
			a.scale.y = -1


# For left/right doors, preserve Y.
# For top/bottom doors, preserve X.
func get_parallel_offset(body: Node2D) -> Vector2:
	var offset := Vector2.ZERO
	var body_pos := body.global_position

	if location == SIDE.LEFT or location == SIDE.RIGHT:
		offset.x = body_pos.y - global_position.y
	else:
		offset.x = body_pos.x - global_position.x

	return offset


# Destination side decides where the body appears.
func get_arrival_offset(offset: Vector2) -> Vector2:
	var result := Vector2.ZERO

	match location:
		SIDE.LEFT:
			result.x = SIDE_ENTRY_OFFSET
			result.y = offset.x

		SIDE.RIGHT:
			result.x = -SIDE_ENTRY_OFFSET
			result.y = offset.x

		SIDE.TOP:
			result.x = offset.x
			result.y = TOP_ENTRY_OFFSET

		SIDE.BOTTOM:
			result.x = offset.x
			result.y = BOTTOM_ENTRY_OFFSET

	return result


func get_transition_direction() -> String:
	match location:
		SIDE.LEFT:
			return "left"
		SIDE.RIGHT:
			return "right"
		SIDE.TOP:
			return "up"
		_:
			return "down"


func _is_valid_entry_direction(body: Node2D) -> bool:
	# Enemies are always allowed through.
	if body.is_in_group("Enemies"):
		return true

	if not body is CharacterBody2D:
		return true

	var mover := body as CharacterBody2D

	match location:
		SIDE.TOP:
			# Must be moving upward and not already bonking the ceiling.
			return mover.velocity.y < -10.0 and not mover.is_on_ceiling()

		SIDE.BOTTOM:
			# Must be falling downward.
			return mover.velocity.y > 10.0

		_:
			return true


func _unlock_transition_bodies() -> void:
	var player := get_tree().get_first_node_in_group("Player") as Node2D
	if player != null and player.has_meta(META_TRANSITION_LOCK):
		player.set_meta(META_TRANSITION_LOCK, false)

	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if enemy is Node2D and enemy.has_meta(META_TRANSITION_LOCK):
			(enemy as Node2D).set_meta(META_TRANSITION_LOCK, false)
