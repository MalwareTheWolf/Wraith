class_name PlayerStateJump
extends PlayerState

@export var jump_velocity : float = 450.0

@onready var jump_audio: AudioStreamPlayer2D = %JumpAudio

# What happens when this state is initialized?
func init() -> void:
	pass

# What happens when we enter this state?
func enter() -> void:
	if player.is_on_floor():
		VisualEffects.jump_dust(player.global_position)
	else:
		VisualEffects.hit_dust(player.global_position)

	player.animation_player.play("Jump")  # Capitalized

	do_jump()

# What happens when we exit this state?
func exit() -> void:
	pass

# What happens when an input is pressed?
func handle_input(event : InputEvent) -> PlayerState:
	if event.is_action_pressed("dash") and player.can_dash():
		return dash
	if event.is_action_pressed("attack"):
		if player.ground_slam and Input.is_action_pressed("down"):
			return ground_slam
		return attack
	if event.is_action_released("jump"):
		return fall
	if event.is_action_pressed("action") and player.can_morph():
		return ball
	return next_state

# What happens each process tick in this state?
func process(_delta: float) -> PlayerState:
	set_jump_frame()
	return next_state

# What happens each physics_process tick in this state?
func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		return idle
	elif player.velocity.y >= 0:
		return fall

	# Horizontal movement in air uses air_velocity
	player.velocity.x = player.direction.x * player.air_velocity
	return next_state

func do_jump() -> void:
	if player.jump_count > 0:
		if not player.double_jump:
			return
		elif player.jump_count > 1:
			return
	player.jump_count += 1
	player.velocity.y = -jump_velocity
	jump_audio.play()

# Updates jump animation frame based on vertical velocity
func set_jump_frame() -> void:
	var frame : float = remap(player.velocity.y, -jump_velocity, 0.0, 0.0, 0.5)
	frame = clamp(frame, 0.0, 1.0)
	player.animation_player.seek(frame, true)
