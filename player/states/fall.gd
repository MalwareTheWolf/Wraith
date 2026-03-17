class_name PlayerStateFall
extends PlayerState

@export var fall_gravity_multiplier : float = 1.165
@export var coyote_time : float = 0.125
@export var jump_buffer_time : float = 0.2

var coyote_timer : float = 0
var buffer_timer : float = 0

@onready var land_audio: AudioStreamPlayer2D = %LandAudio

# What happens when this state is initialized?
func init() -> void:
	pass

# What happens when we enter the state
func enter() -> void:
	player.animation_player.play("Jump")  # Capitalized
	player.gravity_multiplier = fall_gravity_multiplier

	if player.jump_count == 0:
		player.jump_count = 1

	var prev : PlayerState = player.previous_state
	if prev == jump or prev == attack or prev == dash:
		coyote_timer = 0
	elif prev == crouch:
		coyote_timer = 0
		player.jump_count = 1
	else:
		coyote_timer = coyote_time

# What happens when we exit the state
func exit() -> void:
	player.gravity_multiplier = 1.0
	buffer_timer = 0

# What happens when an input is pressed
func handle_input(_event : InputEvent) -> PlayerState:
	if _event.is_action_pressed("dash") and player.can_dash():
		return dash
	if _event.is_action_pressed("attack"):
		if player.ground_slam and Input.is_action_pressed("down"):
			return ground_slam
		return attack
	if _event.is_action_pressed("jump"):
		if coyote_timer > 0:
			player.jump_count = 0
			return jump
		elif player.jump_count <= 1 and player.double_jump:
			return jump
		else:
			buffer_timer = jump_buffer_time
	if _event.is_action_pressed("action") and player.can_morph():
		return ball
	return next_state

# What happens each process tick in this state
func process(_delta: float) -> PlayerState:
	coyote_timer -= _delta
	buffer_timer -= _delta
	set_jump_frame()
	return next_state

# What happens each physics_process tick in this state
func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		VisualEffects.land_dust(player.global_position)
		land_audio.play()
		if buffer_timer > 0:
			player.jump_count = 0
			return jump
		return idle

	# Horizontal movement in air uses air_velocity
	player.velocity.x = player.direction.x * player.air_velocity
	player.velocity.y += player.gravity * _delta * player.gravity_multiplier
	player.velocity.y = clamp(player.velocity.y, -1000.0, player.max_fall_speed)
	return next_state

# Updates jump/fall animation frame based on vertical velocity
func set_jump_frame() -> void:
	var frame : float = remap(player.velocity.y, 0.0, player.max_fall_speed, 0.5, 1.0)
	frame = clamp(frame, 0.0, 1.0)
	player.animation_player.seek(frame, true)
