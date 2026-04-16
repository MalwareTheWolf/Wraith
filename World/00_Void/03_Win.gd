extends Node2D

@export var win_pickup: Node2D

var won: bool = false


func _ready() -> void:
	if win_pickup == null:
		print("No win_pickup assigned")
		return

	var breakable: Breakable = win_pickup.get_node_or_null("Breakable")
	if breakable == null:
		print("No Breakable found under WinPickup")
		return

	breakable.destroyed.connect(_on_win_breakable_destroyed)
	print("Connected win breakable inside: ", win_pickup.name)


func _on_win_breakable_destroyed() -> void:
	print("WIN BREAKABLE DESTROYED SIGNAL FIRED")

	if won:
		return

	won = true

	win_pickup.visible = false
	Messages.win_triggered.emit()
