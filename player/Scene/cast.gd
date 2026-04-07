@icon("res://player/states/state.svg")
class_name PlayerStateCast
extends PlayerState

@export var cast_move_speed: float = 80.0

func init() -> void:
	pass

func enter() -> void:
	if player.animation_player:
		player.animation_player.play("Cast")

func exit() -> void:
	pass

func handle_input(event: InputEvent) -> PlayerState:
	if event.is_action_pressed("jump") and player.is_on_floor():
		return jump

	if event.is_action_pressed("dash") and player.can_dash():
		return dash

	return null

func process(_delta: float) -> PlayerState:
	if not Input.is_action_pressed("laser"):
		if not player.is_on_floor():
			return fall
		elif player.direction.x != 0:
			return walk
		else:
			return idle

	if not player.is_on_floor():
		return fall

	return null

func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		player.velocity.x = player.direction.x * cast_move_speed
	else:
		player.velocity.x = player.direction.x * player.air_velocity

	if not player.is_on_floor() and not Input.is_action_pressed("laser"):
		return fall

	return null
