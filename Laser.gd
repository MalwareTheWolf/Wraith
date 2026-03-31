@tool
class_name Laser
extends RayCast2D

@export var max_length: float = 1400.0
@export var cast_line_width: float = 4.0      # final thickness when casting
@export var sight_line_width: float = 1.0     # thin laser sight
@export var cast_speed: float = 5.0           # width growth per second
@export var is_casting: bool = false

@onready var line_2d: Line2D = $Line2D

# Internal width used for smooth growth
var current_width: float = 0.0

func _ready() -> void:
	if not line_2d:
		push_error("Laser Line2D node not found! Add a Line2D child named 'Line2D'.")
		return
	line_2d.visible = true
	line_2d.width = sight_line_width
	line_2d.default_color = Color.RED
	current_width = sight_line_width

func _physics_process(delta: float) -> void:
	if not line_2d:
		return

	# Direction from laser origin to mouse
	var mouse_dir = (get_global_mouse_position() - global_position).normalized()
	var laser_end = mouse_dir * max_length

	if is_casting:
		# Smoothly grow width to cast_line_width
		current_width = move_toward(current_width, cast_line_width, cast_speed * delta)

		# Update RayCast2D for collision detection
		target_position = mouse_dir * max_length
		force_raycast_update()

		if is_colliding() and get_collider() != get_parent():
			# Only consider collision if it's NOT the player itself
			laser_end = to_local(get_collision_point())
			line_2d.default_color = Color.WHITE  # hitting something targetable
		else:
			line_2d.default_color = Color.RED

	else:
		# Laser sight: thin, always red, ignore collisions
		current_width = sight_line_width
		line_2d.default_color = Color.RED

	# Apply width and points
	line_2d.width = current_width
	line_2d.points = [Vector2.ZERO, laser_end]

	# Update RayCast2D direction (physics)
	target_position = mouse_dir * max_length
