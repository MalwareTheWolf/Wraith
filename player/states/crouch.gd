class_name PlayerStateCrouch extends PlayerState

func init() -> void:
	pass

func enter() -> void:
	player.animation_player.play("Crouch") 

	if player.collision_stand:
		player.collision_stand.disabled = true
	if player.collision_crouch:
		player.collision_crouch.disabled = false
	if player.da_stand:
		player.da_stand.disabled = true
	if player.da_crouch:
		player.da_crouch.disabled = false

func exit() -> void:
	if player.collision_stand:
		player.collision_stand.set_deferred("disabled", false)
	if player.collision_crouch:
		player.collision_crouch.set_deferred("disabled", true)
	if player.da_stand:
		player.da_stand.set_deferred("disabled", false)
	if player.da_crouch:
		player.da_crouch.set_deferred("disabled", true)

func handle_input(_event : InputEvent) -> PlayerState:
	if _event.is_action_pressed("dash") and player.can_dash():
		return dash
	if _event.is_action_pressed("attack"):
		return attack
	if _event.is_action_pressed("jump") and player.one_way_platform_shape_cast:
		player.one_way_platform_shape_cast.force_shapecast_update()
		if player.one_way_platform_shape_cast.is_colliding():
			player.position.y += 4
			return fall
		return jump
	if _event.is_action_pressed("action") and player.can_morph():
		return ball
	return next_state

func process(_delta: float) -> PlayerState:
	if player.direction.y <= 0.5:
		return idle
	return next_state

func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		player.velocity.x = player.direction.x * player.move_speed
	else:
		player.velocity.x = player.direction.x * player.air_velocity
	if not player.is_on_floor():
		return fall
	return next_state
