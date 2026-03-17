class_name PlayerStateIdle
extends PlayerState

func init() -> void:
	pass

func enter() -> void:
	if player.animation_player:
		player.animation_player.play("Idle")
	player.jump_count = 0
	player.dash_count = 0

	player.collision_stand.disabled = false
	player.collision_crouch.disabled = true
	player.da_stand.disabled = false
	player.da_crouch.disabled = true

func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> PlayerState:
	if _event.is_action_pressed("dash") and player.can_dash():
		return dash
	if _event.is_action_pressed("attack"):
		return attack
	if _event.is_action_pressed("jump"):
		return jump
	if _event.is_action_pressed("action") and player.can_morph():
		return ball
	return null

func process(_delta: float) -> PlayerState:
	if player.direction.x != 0:
		return run
	elif player.direction.y > 0.5:
		return crouch
	return null

func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		player.velocity.x = 0
	else:
		player.velocity.x = player.direction.x * player.air_velocity

	if not player.is_on_floor():
		return fall

	return next_state
