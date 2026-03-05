extends CanvasLayer

signal load_scene_started
signal new_scene_ready(target_name: String, offset: Vector2)
signal load_scene_finished


func _ready() -> void:
	# wait one frame so the tree is fully alive
	await get_tree().process_frame
	load_scene_finished.emit()
	pass


func transition_scene(new_scene: String, target_area: String, player_offset: Vector2, dir: String) -> void:
	load_scene_started.emit()

	# get out of the physics callback first
	await get_tree().process_frame

	# change scene safely
	get_tree().change_scene_to_file (new_scene)

	# wait until the new scene is actually active
	await get_tree().scene_changed

	# wait one more frame so the new scene nodes exist
	await get_tree().process_frame

	# tell the target transition to place the player
	new_scene_ready.emit(target_area, player_offset)

	load_scene_finished.emit()
	pass
