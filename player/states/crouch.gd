class_name PlayerStateCrouch
extends PlayerState

@export var deceleration_rate: float = 10

func enter() -> void:
	if not player:
		return

	if player.animation_player:
		player.animation_player.play("Crouch")

	# toggling hitboxes
	if player.collision_stand:
		player.collision_stand.disabled = true
	if player.collision_crouch:
		player.collision_crouch.disabled = false
	if player.da_stand:
		player.da_stand.disabled = true
	if player.da_crouch:
		player.da_crouch.disabled = false


func exit() -> void:
	if not player:
		return

	if player.collision_stand:
		player.collision_stand.set_deferred("disabled", false)
	if player.collision_crouch:
		player.collision_crouch.set_deferred("disabled", true)
	if player.da_stand:
		player.da_stand.set_deferred("disabled", false)
	if player.da_crouch:
		player.da_crouch.set_deferred("disabled", true)


func handle_input(event: InputEvent) -> PlayerState:
	if not player:
		return null

	if event.is_action_pressed("dash") and player.can_dash():
		return dash

	if event.is_action_pressed("attack"):
		return attack

	if event.is_action_pressed("jump"):
		if player.one_way_shape_cast:
			player.one_way_shape_cast.force_shapecast_update()
			if player.one_way_shape_cast.is_colliding():
				player.position.y += 4
				return fall
		return jump

	if event.is_action_pressed("action") and player.can_morph():
		return ball

	return next_state


func process(_delta: float) -> PlayerState:
	if not player:
		return null

	if player.direction.y <= 0.5:
		return idle

	return next_state


func physics_process(delta: float) -> PlayerState:
	if not player:
		return null

	player.velocity.x -= player.velocity.x * deceleration_rate * delta

	if not player.is_on_floor():
		return fall

	return next_state
