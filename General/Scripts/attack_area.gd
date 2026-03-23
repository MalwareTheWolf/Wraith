@icon("uid://d2qa0x0tpfgll")
class_name AttackArea
extends Area2D

# Hitbox used to deal damage to DamageableArea objects.
# Can be activated for short durations during attacks.


#TUNABLES

# Amount of damage dealt on hit.
@export var damage: float = 1



#LIFECYCLE

func _ready() -> void:

	# Detect both bodies and areas for flexibility.
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Start disabled.
	visible = false
	monitoring = false



#COLLISION

# Triggered when a physics body enters.
func _on_body_entered(body: Node2D) -> void:

	if body is DamageableArea:
		_apply_damage(body)


# Triggered when another area enters.
func _on_area_entered(area: Area2D) -> void:

	if area is DamageableArea:
		_apply_damage(area)



#DAMAGE

# Applies damage to the target and spawns hit effect.
func _apply_damage(target: DamageableArea) -> void:

	target.take_damage(self)

	# Align effect horizontally with target.
	var pos := global_position
	pos.x = target.global_position.x

	VisualEffects.hit_dust(pos)



#ACTIVATION

# Enables hitbox for a short duration.
func activate(duration: float = 0.1) -> void:

	set_active(true)
	await get_tree().create_timer(duration).timeout
	set_active(false)


# Toggles hitbox state.
func set_active(value: bool = true) -> void:

	monitoring = value
	visible = value



#ORIENTATION

# Flips hitbox based on facing direction.
func flip(direction_x: float) -> void:

	scale.x = sign(direction_x) if direction_x != 0 else scale.x
