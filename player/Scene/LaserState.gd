@icon("res://player/states/state.svg")
class_name PlayerStateLaser
extends PlayerState

# Continuous Dark Laser channel state.
# Keeps laser active while input is held.


#TUNABLES

@export var laser_move_speed: float = 40.0
# Reduced movement speed while channeling.



#LIFECYCLE

func init() -> void:
	pass


func enter() -> void:
	print("ENTER LASER")


func exit() -> void:
	print("EXIT LASER")



#INPUT

func handle_input(event: InputEvent) -> PlayerState:
	if event.is_action_pressed("jump") and player.is_on_floor():
		return jump

	if event.is_action_pressed("dash") and player.can_dash():
		return dash

	return null



#PROCESS

func process(_delta: float) -> PlayerState:
	var cast_held := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	# Stop channel if released.
	if not cast_held:
		print("LASER RELEASED")
		if not player.is_on_floor():
			return fall
		elif player.direction.x != 0:
			return walk
		else:
			return idle

	# Falling can still override.
	if not player.is_on_floor():
		return fall

	return null



#PHYSICS

func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		player.velocity.x = player.direction.x * laser_move_speed
	else:
		player.velocity.x = player.direction.x * player.air_velocity

	return null
