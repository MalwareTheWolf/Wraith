class_name Player
extends CharacterBody2D
# Main player controller.
# Handles movement, gravity, state machine logic, and respawning.



const DEBUG_JUMP_INDICATOR = preload("uid://b37qe6ik3s8if")
# Small visual marker used for debugging jump positions.

#region /// player stats
var hp : float = 20
var max_hp : float = 20
var dash : bool = false
var double_jump : bool = false
var lightning : bool = false
var Chain_lightning : bool = false
var dark_blast : bool = false
var heavy_attack : bool = false
var power_up : bool = false
var ground_slam : bool = false
var morph : bool = false
var spell2 : bool = false
var spell3 : bool = false
var spell4 : bool = false
var spell5 : bool = false
var spell6 : bool = false
var spell7 : bool = false
var spell8 : bool = false
#endregion

#        NODE REFERENCES

@onready var sprite: Sprite2D = $Sprite2D
# Main player sprite used for flipping direction.

@onready var collision_stand: CollisionShape2D = $CollisionStand
# Collision used when the player is standing.

@onready var collision_crouch: CollisionShape2D = $CollisionCrouch
# Collision used when the player is crouching.

@onready var one_way_shape_cast: ShapeCast2D = $OneWayShapeCast
# Used to detect one-way platforms.

@onready var animation_player: AnimationPlayer = $AnimationPlayer
# Handles playing character animations.



#        EXPORT SETTINGS

@export var move_speed: float = 150
# Ground movement speed.

@export var air_velocity: float = 250.0
# Horizontal velocity allowed while airborne.

@export var respawn_position: Vector2
# Position the player returns to when dying.

@export var max_fall_speed: float = 600
# Maximum downward velocity allowed.



#        STATE MACHINE VARIABLES

var states: Array[PlayerState]
# List of all player states (Idle, Run, Jump, etc).

var current_state: PlayerState:
	get: return states.front()
# Current active state.

var previous_state: PlayerState:
	get: return states[1]
# Previous state (used for transitions).



#        STANDARD VARIABLES

var direction: Vector2 = Vector2.ZERO
# Input direction from player controls.

var gravity: float = 980
# Base gravity applied every physics frame.

var gravity_multiplier: float = 1.0
# Allows states to modify gravity strength.



#        INITIALIZATION

func _ready() -> void:

	# Add player to global group so transitions can find it.
	add_to_group("Player")

	# If a persistent player already exists, delete this one.
	# The persistent player is the one parented under the tree root.
	var players := get_tree().get_nodes_in_group("Player")

	if players.size() > 1:

		var keep: Node2D = null

		for p in players:
			if p is Node2D and p.get_parent() == get_tree().root:
				keep = p
				break

		if keep == null:
			keep = players[0]

		if self != keep:
			queue_free()
			return

	# Make sure the kept player persists between scenes.
	if get_parent() != get_tree().root:
		call_deferred("reparent", get_tree().root)

	# Initialize state machine and states.
	initialize_states()

	# Store spawn position if one hasn't been set.
	if respawn_position == Vector2.ZERO:
		respawn_position = global_position

	pass



#        INPUT HANDLING

func _unhandled_input(event: InputEvent) -> void:

	# Allow current state to process input.
	change_state(current_state.handle_input(event))

	pass



#        FRAME UPDATE

func _process(_delta: float) -> void:

	# Update movement direction from player input.
	update_direction()

	# Allow current state to run frame logic.
	change_state(current_state.process(_delta))

	pass



#        PHYSICS UPDATE

func _physics_process(_delta: float) -> void:

	# Apply gravity.
	velocity.y += gravity * _delta * gravity_multiplier

	# Clamp falling speed to prevent extreme velocity.
	velocity.y = clampf(velocity.y, -1000.0, max_fall_speed)

	# Apply movement using built-in character motion.
	move_and_slide()

	# Allow current state to process physics logic.
	change_state(current_state.physics_process(_delta))

	pass



#        STATE MACHINE SETUP

func initialize_states() -> void:

	states = []

	# Gather all PlayerState nodes from the States container.
	for c in $States.get_children():
		if c is PlayerState:
			states.append(c)
			c.player = self
		pass

	# Stop if no states exist.
	if states.size() == 0:
		return

	# Initialize each state.
	for state in states:
		state.init()

	# Start with the first state.
	change_state(current_state)

	current_state.enter()

	pass



#        STATE TRANSITIONS

func change_state(new_state: PlayerState) -> void:

	# Ignore invalid transitions.
	if new_state == null:
		return
	elif new_state == current_state:
		return

	# Exit the current state.
	if current_state:
		current_state.exit()

	# Move new state to the front of the list.
	states.push_front(new_state)

	# Enter the new state.
	current_state.enter()

	# Limit history to 3 states.
	states.resize(3)

	# Debug label showing current state.
	$Label.text = current_state.name

	pass



#        INPUT DIRECTION

func update_direction() -> void:

	var prev_direction: Vector2 = direction

	# Get input axes from input map.
	var x_axis = Input.get_axis("left", "right")
	var y_axis = Input.get_axis("up", "down")

	direction = Vector2(x_axis, y_axis)

	# Flip sprite based on horizontal movement.
	if prev_direction.x != direction.x:
		if direction.x < 0:
			sprite.flip_h = true
		if direction.x > 0:
			sprite.flip_h = false

	pass



#        DEBUG TOOLS

func add_debug_indicator(color: Color = Color.RED) -> void:

	# Spawn a temporary visual marker.
	var d: Node2D = DEBUG_JUMP_INDICATOR.instantiate()

	get_tree().root.add_child(d)

	d.global_position = global_position
	d.modulate = color

	# Remove marker after 3 seconds.
	await get_tree().create_timer(3.0).timeout

	d.queue_free()

	pass



#        DEATH / RESPAWN

func die(reason: String = "unknown") -> void:

	print("Player died by %s" % reason)

	# Reset player position.
	global_position = respawn_position

	# Reset velocity.
	velocity = Vector2.ZERO

	# Reset movement direction.
	direction = Vector2.ZERO

	# Reset current state.
	if current_state:
		current_state.exit()
		current_state.enter()

	pass
