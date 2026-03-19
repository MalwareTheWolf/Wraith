@icon("uid://d2qa0x0tpfgll")
class_name AttackArea
extends Area2D

@export var damage : float = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	visible = false
	monitoring = false


func _on_body_entered(body: Node2D) -> void:
	if body is DamageableArea:
		_apply_damage(body)


func _on_area_entered(area: Area2D) -> void:
	if area is DamageableArea:
		_apply_damage(area)


func _apply_damage(target: DamageableArea) -> void:
	target.take_damage(self)

	var pos := global_position
	pos.x = target.global_position.x

	VisualEffects.hit_dust(pos)


func activate(duration: float = 0.1) -> void:
	set_active(true)
	await get_tree().create_timer(duration).timeout
	set_active(false)


func set_active(value: bool = true) -> void:
	monitoring = value
	visible = value


func flip(direction_x: float) -> void:
	scale.x = sign(direction_x) if direction_x != 0 else scale.x
