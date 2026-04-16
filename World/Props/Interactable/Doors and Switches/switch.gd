@icon("res://General/Icon/switch.svg")
class_name Switch extends Node2D

signal activated

var is_open: bool = false
var player_inside: bool = false

@export_category("Locking")
@export var required_enemy: EnemyKnight
@export var locked_hint: String = "Defeat the enemy first"

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D


func _ready() -> void:
	if SaveManager.persistent_data.get_or_add(unique_name(), "closed") == "open":
		set_open()
	else:
		area_2d.body_entered.connect(_on_player_entered)
		area_2d.body_exited.connect(_on_player_exited)


func _process(_delta: float) -> void:
	if player_inside and not is_open:
		_update_hint()


func _on_player_entered(_n: Node2D) -> void:
	player_inside = true
	_update_hint()

	if not Messages.player_interacted.is_connected(_on_player_interacted):
		Messages.player_interacted.connect(_on_player_interacted)


func _on_player_exited(_n: Node2D) -> void:
	player_inside = false
	Messages.input_hint_changed.emit("")

	if Messages.player_interacted.is_connected(_on_player_interacted):
		Messages.player_interacted.disconnect(_on_player_interacted)


func _on_player_interacted(_player: Player) -> void:
	if not player_inside:
		return

	if _is_locked():
		_update_hint()
		return

	SaveManager.persistent_data[unique_name()] = "open"
	activated.emit()
	set_open()


func _update_hint() -> void:
	if not player_inside:
		Messages.input_hint_changed.emit("")
		return

	if _is_locked():
		Messages.input_hint_changed.emit(locked_hint)
	else:
		Messages.input_hint_changed.emit("interact")


func set_open() -> void:
	is_open = true
	sprite_2d.flip_h = true
	sprite_2d.modulate = Color.GRAY
	area_2d.queue_free()


func _is_locked() -> bool:
	if required_enemy == null:
		return false

	if not is_instance_valid(required_enemy):
		return false

	return not required_enemy.dead


func unique_name() -> String:
	var u_name: String = ResourceUID.path_to_uid(owner.scene_file_path)
	u_name += "/" + get_parent().name + "/" + name
	return u_name
