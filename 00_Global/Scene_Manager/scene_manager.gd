extends CanvasLayer

signal load_scene_started
signal new_scene_ready(target_name: String, offset: Vector2)
signal load_scene_finished
signal scene_entered(uid: String)

var current_scene_uid: String = ""

func _ready() -> void:
	await get_tree().process_frame

	if get_tree().current_scene:
		current_scene_uid = get_tree().current_scene.scene_file_path

	load_scene_finished.emit()


func transition_scene(new_scene: String, target_area: String, player_offset: Vector2, _dir: String) -> void:
	load_scene_started.emit()
	await get_tree().process_frame

	var err := get_tree().change_scene_to_file(new_scene)
	if err != OK:
		push_error("Failed to change scene: %s | err=%s" % [new_scene, err])
		return

	current_scene_uid = new_scene
	scene_entered.emit(current_scene_uid)

	await get_tree().scene_changed
	await get_tree().process_frame

	new_scene_ready.emit(target_area, player_offset)
	load_scene_finished.emit()
