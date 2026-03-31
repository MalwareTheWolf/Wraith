@tool
class_name Laser
extends RayCast2D

@export var max_length: float = 1400.0
@export var cast_line_width: float = 4.0      # width when casting
@export var sight_line_width: float = 1.0     # thin laser sight
@export var cast_speed: float = 5.0           # width growth per second
@export var is_casting: bool = false

@onready var line_2d: Line2D = $Line2D

var current_width: float = 0.0

func _ready() -> void:
	if not line_2d:
		push_error("Laser Line2D node not found! Add a Line2D child named 'Line2D'.")
		return
	line_2d.visible = true
	line_2d.width = sight_line_width
	line_2d.default_color = Color.WHITE
	current_width = sight_line_width
	enabled = true  # Make sure RayCast2D is active

func _physics_process(delta: float) -> void:
	if not line_2d:
		return

	var mouse_dir = (get_global_mouse_position() - global_position).normalized()
	var laser_end = mouse_dir * max_length

	# Update RayCast2D target along mouse direction
	target_position = mouse_dir * max_length
	force_raycast_update()

	if is_casting:
		current_width = move_toward(current_width, cast_line_width, cast_speed * delta)
		if is_colliding() and get_collider() != get_parent():
			laser_end = to_local(get_collision_point())
			line_2d.default_color = Color.RED  # Casting hits target
		else:
			line_2d.default_color = Color.RED
	else:
		current_width = sight_line_width
		if is_colliding() and get_collider() != get_parent():
			laser_end = to_local(get_collision_point())
			line_2d.default_color = Color.RED  # Sight hits target
		else:
			line_2d.default_color = Color.WHITE

	line_2d.width = current_width
	line_2d.points = [Vector2.ZERO, laser_end]
