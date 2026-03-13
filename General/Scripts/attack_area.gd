@icon( "res://General/Icon/attack_area.svg" )
class_name AttackArea extends Area2D

@export var damage : float = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect( _on_body_entered )
	area_entered.connect( _on_body_entered )
	visible = false
	monitorable = false
	monitoring = false
	pass


func _on_body_entered( body : Node2D ) -> void:
	if body is DamagableArea:
		body.take_damage( self )
		pass
	pass

func activate( duration : float = 0.1) -> void:
	set_active()
	await get_tree().create_timer( duration ).timeout
	pass


func set_active( value : bool = true) -> void:
	visible = value
	monitoring = value
	pass


func flip( direction_x : float ) -> void:
	if direction_x> 0:
		scale.x =1
	elif direction_x < 0:
		scale.x = -1
