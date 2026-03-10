@tool
extends Node2D
class_name WaterSpring
# Individual vertical spring used to simulate a water surface point.
# Each spring moves independently but is influenced by neighbors.

@onready var area_2d: Area2D = %Area2D
# Area used to detect bodies entering the water at this spring's position.

@export_range(0.001, 0.02)
var motion_factor: float = 0.005
# Multiplier that converts body movement speed into splash force.



#        SPRING STATE

# Current vertical velocity of the spring.
var velocity = 0

# Total force currently applied to the spring.
var force = 0

# Current vertical height (Y position).
var height = 0

# The spring's equilibrium (resting) height.
var target_height = 0

# Index of this spring inside the water system.
var index = 0


# Emitted when something splashes into this spring.
signal splash



#          LIFECYCLE

func _ready() -> void:
	# Connect collision detection for splash interaction.
	area_2d.body_entered.connect(_on_area_2d_body_entered)



#        PHYSICS UPDATE

# Applies Hooke's Law to simulate spring motion.
# Hooke's Law: F = -k * x
# k = spring stiffness
# x = displacement from equilibrium
func water_update(spring_constant, dampening):

	# Update current height from position.
	height = position.y

	# Displacement from resting height.
	var x = height - target_height

	# Damping force (reduces oscillation over time).
	var loss = -dampening * velocity

	# Total force = spring force + damping force.
	force = -spring_constant * x + loss

	# Apply force to velocity.
	velocity += force

	# Apply velocity to position.
	position.y += velocity



#        INITIALIZATION

func initialize(x_position, id):

	# Set baseline values when spring is created.
	height = position.y
	target_height = position.y
	velocity = 0

	# Position spring horizontally.
	position.x = x_position

	# Store index for splash communication.
	index = id



#        SPLASH DETECTION

func _on_area_2d_body_entered(body: Object) -> void:

	# Only react to physics characters.
	if body is CharacterBody2D:

		var character_body = body as CharacterBody2D

		# Splash strength is based on impact speed.
		# Faster impact = stronger wave.
		var speed = -character_body.velocity.length() * motion_factor

		# Notify parent water system.
		splash.emit(index, speed)
