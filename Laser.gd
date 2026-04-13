@tool
class_name Laser
extends RayCast2D

# Continuous laser beam.
# Handles aiming, beam visuals, collision probing, channel damage, and beam hitbox alignment.


#TUNABLES

@export var max_length: float = 1400.0
@export var cast_line_width: float = 4.0
@export var sight_line_width: float = 1.0
@export var cast_speed: float = 30.0

@export var is_casting: bool = false
@export var is_channeling: bool = false

@export var damage_interval: float = 0.15

@export var sight_color: Color = Color.WHITE
@export var cast_color: Color = Color(0.74, 0.0, 0.018, 1.0)
@export var hit_color: Color = Color(0.983, 0.0, 0.0, 1.0)

@export var hitbox_width: float = 6.0
# Thickness of the beam hitbox.


#NODE REFERENCES

@onready var line_2d: Line2D = $Line2D
@onready var attack_area: AttackArea = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var collision_particles: GPUParticles2D = $CollisionParticles2D


#RUNTIME

var current_width: float = 0.0
var damage_timer: float = 0.0
var was_hitting_last_frame: bool = false



#LIFECYCLE

func _ready() -> void:
	if not line_2d:
		push_error("Laser Line2D node not found! Add a Line2D child named 'Line2D'.")
		return

	line_2d.visible = true
	line_2d.width = sight_line_width
	line_2d.default_color = sight_color
	current_width = sight_line_width
	enabled = true

	if attack_area:
		attack_area.monitoring = false
		attack_area.visible = false

	if attack_collision:
		attack_collision.disabled = true

	if collision_particles:
		collision_particles.emitting = false



#PHYSICS

func _physics_process(delta: float) -> void:
	if not line_2d:
		return

	var local_mouse: Vector2 = to_local(get_global_mouse_position())
	var laser_end: Vector2 = local_mouse.normalized() * max_length

	target_position = laser_end
	force_raycast_update()

	if is_colliding() and get_collider() != get_parent():
		laser_end = to_local(get_collision_point())

	update_visuals(delta, laser_end)
	update_beam_hitbox(laser_end)
	update_collision_particles(laser_end)
	update_damage(delta)



#VISUALS

func update_visuals(delta: float, laser_end: Vector2) -> void:
	if is_casting:
		current_width = move_toward(current_width, cast_line_width, cast_speed * delta)

		if is_colliding() and get_collider() != get_parent():
			line_2d.default_color = hit_color
		else:
			line_2d.default_color = cast_color
	else:
		current_width = sight_line_width

		if is_colliding() and get_collider() != get_parent():
			line_2d.default_color = hit_color
		else:
			line_2d.default_color = sight_color

	line_2d.width = current_width
	line_2d.points = [Vector2.ZERO, laser_end]



#HITBOX

func update_beam_hitbox(laser_end: Vector2) -> void:
	if not attack_area or not attack_collision:
		return

	if not attack_collision.shape is RectangleShape2D:
		return

	var rect: RectangleShape2D = attack_collision.shape as RectangleShape2D
	var beam_length: float = laser_end.length()

	# Reset transforms so editor doesn't fight script
	attack_area.position = laser_end * 0.5
	attack_area.rotation = laser_end.angle()
	attack_area.scale = Vector2.ONE

	attack_collision.position = Vector2.ZERO
	attack_collision.rotation = 0.0
	attack_collision.scale = Vector2.ONE

	# Set size: X = length, Y = your width
	rect.size = Vector2(max(beam_length, 1.0), hitbox_width)

	# Enable during cast
	if is_casting:
		attack_area.monitoring = true
		attack_area.visible = true
		attack_collision.disabled = false
	else:
		attack_area.monitoring = false
		attack_area.visible = false
		attack_collision.disabled = true



#DAMAGE

func update_damage(delta: float) -> void:
	if not is_casting:
		damage_timer = 0.0
		return

	if not is_colliding():
		damage_timer = 0.0
		return

	var target := get_hit_damageable()
	if target == null:
		damage_timer = 0.0
		return

	damage_timer -= delta

	if damage_timer <= 0.0:
		damage_timer = damage_interval
		target.take_damage(attack_area)



func get_hit_damageable() -> DamageableArea:
	var collider := get_collider()

	if collider is DamageableArea:
		return collider

	if collider and collider.get_parent() is DamageableArea:
		return collider.get_parent()

	return null



#PARTICLES

func update_collision_particles(laser_end: Vector2) -> void:
	if not collision_particles:
		return

	var hit_now := is_casting and is_colliding() and get_collider() != get_parent()

	# Always at beam end
	collision_particles.global_position = to_global(laser_end)

	if hit_now:
		if not was_hitting_last_frame:
			collision_particles.restart()
		collision_particles.emitting = true
	else:
		collision_particles.emitting = false

	was_hitting_last_frame = hit_now
