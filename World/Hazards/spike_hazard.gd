@icon("res://General/Icon/hazard.svg")
@tool
class_name SpikeHazard
extends Node2D
# Spike hazard that kills the player on contact. Size is adjustable per instance.

@export_range(8, 128, 4)
var width: int = 32:
	set(value):
		width = value
		apply_size()

@export_range(8, 128, 4)
var height: int = 32:
	set(value):
		height = value
		apply_size()

# Node references
@onready var area: Area2D = $SpikeArea2D
@onready var collision_shape: CollisionShape2D = $SpikeArea2D/SpikeCollisionShape2D

func _ready() -> void:
	apply_size()

	# Connect signal only if in-game
	if not Engine.is_editor_hint():
		var callable = Callable(self, "_on_body_entered")
		if not area.is_connected("body_entered", callable):
			area.body_entered.connect(callable)

func _on_body_entered(body: Node) -> void:
	# Only affect the player
	if body.is_in_group("Player") and body.has_method("die"):
		# Kill player immediately
		body.die("spike")
		# Optional: take damage instead of dying
		# body.hp -= 5

func apply_size() -> void:
	if not collision_shape:
		return
	if collision_shape.shape is RectangleShape2D:
		# Duplicate the shape to avoid sharing
		var rect = collision_shape.shape.duplicate()
		rect.extents = Vector2(width / 2, height / 2)
		collision_shape.shape = rect
