class_name PlayerStateCrouch extends PlayerState 

@export var deceleration_rate : float = 10

var original_sprite_position : Vector2


#initialize
func init() -> void: 
	original_sprite_position = player.sprite.position


#what happens when entering the state 
func enter() -> void: 
	player.animation_player.play("Crouch")
	player.collision_stand.disabled = true
	player.collision_crouch.disabled = false
	
	# Move sprite down 5 pixels from original position
	#player.sprite.position = original_sprite_position + Vector2(0, 13)


#what happens when exiting the state 
func exit() -> void: 
	
	player.collision_stand.disabled = false
	player.collision_crouch.disabled = true
	
	# Reset sprite position
	#player.sprite.position = original_sprite_position


#what happens when an input is pressed 
func handle_input( _event : InputEvent ) -> PlayerState:
	#Handle input
	if _event.is_action_pressed("jump"):
		player.one_way_shape_cast.force_shapecast_update()
		if player.one_way_shape_cast.is_colliding():
			player.position.y += 4
			return fall
		return jump
	return next_state
  

#what happens each process tick in this state 
func process( _delta: float) -> PlayerState: 
	if player.direction.y <= 0.5:
		return idle
	return next_state 


#what happens each process tick in this state 
func physics_process( _delta: float) -> PlayerState: 
	player.velocity.x -= player.velocity.x * deceleration_rate * _delta
	if player.is_on_floor() == false:
		return fall
	return next_state 
