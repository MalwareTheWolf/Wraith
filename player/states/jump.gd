class_name PlayerStateJump
extends PlayerState

@export var jump_velocity: float = 450.0
@onready var jump_audio: AudioStreamPlayer2D = %JumpAudio

# --- What happens when the state is initialized ---
func init() -> void:
	pass

# --- What happens when we enter this state ---
func enter() -> void:
	# Play jump or hit dust depending on floor status
	if player.is_on_floor():
		VisualEffects.jump_dust(player.global_position)
	else:
		VisualEffects.hit_dust(player.global_position)
		
	player.animation_player.play("jump")  # Animation name
	player.animation_player.pause()
	
	do_jump()
	
	# Handle buffered jump if coming from fall but jump not pressed
	if player.previous_state == fall and not Input.is_action_pressed("jump"):
		await get_tree().physics_frame
		player.velocity.y *= 0.5
		player.change_state(fall)
	pass

# --- What happens when we exit this state ---
func exit() -> void:
	pass

# --- What happens when an input is pressed ---
func handle_input(event: InputEvent) -> PlayerState:
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
	pass

# --- What happens each process tick ---
func process(_delta: float) -> PlayerState:
	set_jump_frame()
	return next_state
	pass

# --- What happens each physics_process tick ---
func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		player.jump_count = 0  # Reset jump count on landing
		return idle
	elif player.velocity.y >= 0:
		return fall

	player.velocity.x = player.direction.x * player.air_velocity
	return next_state
	pass

# --- Handles the actual jump ---
func do_jump() -> void:
	# If the player has jumped once, allow double jump only if unlocked
	if player.jump_count > 0:
		if not player.double_jump:
			return
		elif player.jump_count > 1:
			return

	# Increment jump count and apply vertical velocity
	player.jump_count += 1
	player.velocity.y = -jump_velocity
	jump_audio.play()
	pass

# --- Sets animation frame based on jump progress ---
func set_jump_frame() -> void:
	var frame: float = remap(player.velocity.y, -jump_velocity, 0.0, 0.0, 0.5)
	frame = clamp(frame, 0.0, 1.0)
	player.animation_player.seek(frame, true)
	pass
