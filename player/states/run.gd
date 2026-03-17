class_name PlayerStateRun extends PlayerState

# What happens when this state is initialized?
func init() -> void:
	pass

# What happens when we enter this state?
func enter() -> void:
	if player.animation_player:
		player.animation_player.play("Run")  # Capitalized to match naming convention

# What happens when we exit this state?
func exit() -> void:
	pass

# What happens when an input is pressed?
func handle_input(_event : InputEvent) -> PlayerState:
	# Dash input is commented out in original; leave as-is unless you want it active
	# if _event.is_action_pressed("dash") and player.can_dash():
	#     return dash
	if _event.is_action_pressed("attack"):
		return attack
	if _event.is_action_pressed("jump"):
		return jump
	# Morph input is commented out in original; leave as-is
	# if _event.is_action_pressed("action") and player.can_morph():
	#     return ball
	return next_state

# What happens each process tick in this state?
func process(_delta: float) -> PlayerState:
	if player.direction.x == 0:
		return idle
	elif player.direction.y > 0.5:
		return crouch
	return next_state

# What happens each physics_process tick in this state?
func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		# Ground movement
		player.velocity.x = player.direction.x * player.move_speed
	else:
		# Air movement uses air_velocity directly
		player.velocity.x = player.direction.x * player.air_velocity
	
	if not player.is_on_floor():
		return fall
	return next_state
