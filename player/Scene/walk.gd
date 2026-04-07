@icon("res://player/states/state.svg")
class_name PlayerStateWalk
extends PlayerState

func init() -> void:
	pass

func enter() -> void:
	if player.animation_player:
		player.animation_player.play("Walk")

func exit() -> void:
	pass

func handle_input(event: InputEvent) -> PlayerState:
	if event.is_action_pressed("dash") and player.can_dash():
		return dash

	if event.is_action_pressed("attack"):
		return attack

	if event.is_action_pressed("jump"):
		return jump

	if event.is_action_pressed("action") and player.can_morph():
		return ball

	if event.is_action_pressed("laser"):
		return cast

	return null

func process(_delta: float) -> PlayerState:
	if not player.is_on_floor():
		return fall

	if player.direction.x == 0.0:
		return idle

	if player.direction.y > 0.5:
		return crouch

	if player.run and player.wants_to_run:
		return run

	return null

func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		player.velocity.x = player.direction.x * player.walk_speed
	else:
		player.velocity.x = player.direction.x * player.air_velocity

	if not player.is_on_floor():
		return fall

	return null
